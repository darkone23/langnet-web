const std = @import("std");

/// ---------------------------------------------------------------------------
/// unix_run_literate.zig
///
/// A tiny zzz HTTP server bound to a UNIX domain socket (/tmp/zzz.sock).
///
/// Routes:
///   GET /      -> returns a small HTML string (baseline sanity check)
///   GET /run   -> runs: bash -lc "sleep 1; echo hello from bash"
///                and returns stdout as text/plain
///
/// Why this example matters:
///   - Subprocess execution is easy to accidentally make "blocking".
///   - zzz is built around tardy (async runtime). If you block runtime threads,
///     throughput/latency can degrade under load.
///
/// This file shows TWO ways to implement /run:
///   (A) Minimal & simple: run subprocess directly in handler (blocking)
///   (B) Safer shape: offload subprocess to an OS thread (still waits, but
///       avoids blocking the runtime worker that is driving network I/O).
///
/// Pick A for quick demos; pick B if you care about not stalling runtime work.
/// For production, you'd likely want a *bounded* blocking thread pool.
/// ---------------------------------------------------------------------------
const zzz = @import("zzz");
const http = zzz.HTTP;

/// tardy is the runtime underneath zzz. In their examples they alias these:
const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.auto);
const Runtime = tardy.Runtime;
const Socket = tardy.Socket;

/// zzz HTTP types
const Server = http.Server;
const Router = http.Router;
const Context = http.Context;
const Route = http.Route;
const Respond = http.Respond;

/// Keep the demo quiet by default.
pub const std_options: std.Options = .{ .log_level = .err };

/// ---------------------------------------------------------------------------
/// Route: GET /
///
/// A simple handler to prove the server is reachable.
/// ---------------------------------------------------------------------------
fn root_handler(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = "This is an HTTP benchmark (with /run).",
    });
}

/// ---------------------------------------------------------------------------
/// Route: GET /run
///
/// We’ll present *one* implementation in-use (B), and keep the minimal version
/// (A) commented out below. Flip between them depending on what you want to
/// demonstrate.
///
/// Handler signature matches your examples:
///   fn(ctx: *const Context, _: void) !Respond
/// ---------------------------------------------------------------------------
fn run_handler(ctx: *const Context, _: void) !Respond {
    // ----------------------------
    // Option B (recommended shape):
    // Offload blocking subprocess work to a dedicated OS thread.
    //
    // The HTTP request still waits for the command to finish, *but* the async
    // runtime thread that accepted the connection is not stuck in a blocking
    // read/wait syscall the whole time.
    // ----------------------------

    const out = try run_bash_sleep_echo_off_thread(ctx.allocator);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.TEXT,
        .body = out,
    });

    // ----------------------------
    // Option A (minimal, blocking):
    // ----------------------------
    // const out = try run_bash_sleep_echo(ctx.allocator);
    // return ctx.response.apply(.{
    //     .status = .OK,
    //     .mime = http.Mime.TEXT,
    //     .body = out,
    // });
}

/// ---------------------------------------------------------------------------
/// The core subprocess function (blocking).
///
/// This is the simplest "run a child and capture stdout" approach using
/// std.process.Child:
///   - spawn child with stdout/stderr piped
///   - read stdout fully into memory
///   - read stderr fully into memory
///   - wait for exit status
///
/// It returns allocated stdout on success, or an allocated error message.
///
/// IMPORTANT: This function uses blocking reads and a blocking wait.
/// That’s fine in a dedicated thread or if you accept blocking in your handler.
/// ---------------------------------------------------------------------------
fn run_bash_sleep_echo(alloc: std.mem.Allocator) ![]u8 {
    // We call the shell so we can easily express "sleep 1; echo ...".
    // In real services, consider avoiding a shell when you can.
    var child = std.process.Child.init(&.{
        "bash",
        "-lc",
        "sleep 1; echo hello from bash",
    }, alloc);

    // We want to capture stdout + stderr in memory.
    child.stdout_behavior = .Pipe;
    child.stderr_behavior = .Pipe;

    try child.spawn();

    // Read all of stdout and stderr.
    // Cap at 1 MiB each to avoid unbounded memory growth in this demo.
    const stdout_bytes = try child.stdout.?.reader().readAllAlloc(alloc, 1024 * 1024);
    errdefer alloc.free(stdout_bytes);

    const stderr_bytes = try child.stderr.?.reader().readAllAlloc(alloc, 1024 * 1024);
    defer alloc.free(stderr_bytes);

    // Wait for the process to exit (blocking).
    const term = try child.wait();

    // Translate termination into a nice response.
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                // The command failed. Return stderr (and the exit code) as body.
                alloc.free(stdout_bytes);
                return std.fmt.allocPrint(
                    alloc,
                    "exit={d}\nstderr:\n{s}\n",
                    .{ code, stderr_bytes },
                );
            }
        },
        else => {
            // Signals / other abnormal terminations.
            alloc.free(stdout_bytes);
            return std.fmt.allocPrint(alloc, "terminated: {any}\n", .{term});
        },
    }

    // Success: return stdout.
    return stdout_bytes;
}

/// ---------------------------------------------------------------------------
/// Off-thread wrapper around run_bash_sleep_echo.
///
/// This is the smallest step toward "don’t block runtime threads".
///
/// How it works:
///   - spawn one OS thread
///   - that thread runs the blocking subprocess function
///   - join the thread (so the request still waits)
///
/// A more scalable approach would:
///   - use a bounded thread pool
///   - queue subprocess jobs into it
///   - apply concurrency limits
///
/// Still: this illustrates the principle cleanly.
/// ---------------------------------------------------------------------------
fn run_bash_sleep_echo_off_thread(alloc: std.mem.Allocator) ![]u8 {
    const Result = struct {
        bytes: ?[]u8 = null,
        err: ?anyerror = null,
    };

    var result: Result = .{};

    const WorkerArgs = struct {
        alloc: std.mem.Allocator,
        out: *Result,
    };

    // We can’t `try` inside a void thread entry, so we store errors in `result`.
    var th = try std.Thread.spawn(.{}, struct {
        fn worker(p: WorkerArgs) void {
            p.out.bytes = run_bash_sleep_echo(p.alloc) catch |e| {
                p.out.err = e;
                return;
            };
        }
    }.worker, .{WorkerArgs{ .alloc = alloc, .out = &result }});

    // Wait for the subprocess thread to finish.
    th.join();

    // Propagate error if any.
    if (result.err) |e| return e;

    // Return bytes from the worker.
    return result.bytes.?;
}

/// ---------------------------------------------------------------------------
/// main()
///
/// This matches the structure of your unix.zig benchmark:
///   - init allocator
///   - init tardy runtime (threading = .auto)
///   - init router with routes
///   - bind UNIX socket
///   - t.entry(...) which ultimately calls server.serve(...)
///
/// The server listens on /tmp/zzz.sock (UNIX domain socket).
/// ---------------------------------------------------------------------------
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Threading .auto matches your unix.zig benchmark example.
    var t = try Tardy.init(allocator, .{ .threading = .auto });
    defer t.deinit();

    // Router: include baseline root and our /run route.
    var router = try Router.init(allocator, &.{
        Route.init("/").get({}, root_handler).layer(),
        Route.init("/run").get({}, run_handler).layer(),
    }, .{});
    defer router.deinit(allocator);

    // zzz benchmark uses a UNIX socket at /tmp/zzz.sock.
    // Remove the old socket file on exit.
    var socket = try Socket.init(.{ .unix = "/tmp/zzz.sock" });
    defer std.fs.deleteFileAbsolute("/tmp/zzz.sock") catch unreachable;
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(256);

    const EntryParams = struct {
        router: *const Router,
        socket: Socket,
    };

    try t.entry(
        EntryParams{ .router = &router, .socket = socket },
        struct {
            fn entry(rt: *Runtime, p: EntryParams) !void {
                var server = Server.init(.{});
                try server.serve(rt, p.router, .{ .normal = p.socket });
            }
        }.entry,
    );
}
