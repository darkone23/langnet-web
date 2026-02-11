const std = @import("std");
const mustache = @import("mustache");
const zzz = @import("zzz");
const zuckdb = @import("zuckdb");
const http = zzz.HTTP;

const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.auto);
const Runtime = tardy.Runtime;
const Socket = tardy.Socket;

const Server = http.Server;
const Router = http.Router;
const Context = http.Context;
const Route = http.Route;
const Respond = http.Respond;

pub const std_options: std.Options = .{ .log_level = .err };

/// HTML template with mustache syntax
const page_template =
    \\<!DOCTYPE html>
    \\<html>
    \\<head>
    \\    <title>{{title}}</title>
    \\</head>
    \\<body>
    \\    <h1>{{heading}}</h1>
    \\    <p>{{message}}</p>
    \\    <h2>Features:</h2>
    \\    <ul>
    \\    {{#features}}
    \\        <li>{{name}}</li>
    \\    {{/features}}
    \\    </ul>
    \\    <p><em>Server time: {{timestamp}}</em></p>
    \\</body>
    \\</html>
;

/// Root handler - renders a mustache template
fn root_handler(ctx: *const Context, _: void) !Respond {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Prepare template data
    const timestamp = try std.fmt.allocPrint(allocator, "{}", .{std.time.timestamp()});
    defer allocator.free(timestamp);

    const data = .{
        .title = "Zig HTTP Server with Mustache",
        .heading = "Welcome to zzz + mustache",
        .message = "This page is rendered using mustache templates!",
        .features = .{
            .{ .name = "HTTP server with zzz" },
            .{ .name = "Template rendering with mustache" },
            .{ .name = "Async runtime with tardy" },
            .{ .name = "Zero-copy where possible" },
        },
        .timestamp = timestamp,
    };

    // Render the template
    const html = mustache.allocRenderText(allocator, page_template, data) catch |err| {
        return ctx.response.apply(.{
            .status = .@"Internal Server Error",
            .mime = http.Mime.TEXT,
            .body = try std.fmt.allocPrint(ctx.allocator, "Template error: {s}", .{@errorName(err)}),
        });
    };
    defer allocator.free(html);

    // Copy to ctx allocator for response
    const body = try ctx.allocator.dupe(u8, html);
    errdefer ctx.allocator.free(body);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = body,
    });
}

/// API handler - returns JSON response
fn api_handler(ctx: *const Context, _: void) !Respond {
    // Build JSON string manually - simple and reliable
    const json = try std.fmt.allocPrint(ctx.allocator, "{{\n  \"status\": \"ok\",\n  \"message\": \"API is working\",\n  \"version\": \"0.1.0\"\n}}", .{});
    errdefer ctx.allocator.free(json);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.JSON,
        .body = json,
    });
}

/// Simple text handler
fn health_handler(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.TEXT,
        .body = "OK - zzz + mustache server is running",
    });
}

/// Database demo handler - shows zuckdb integration
fn db_handler(ctx: *const Context, _: void) !Respond {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize database
    const db = zuckdb.DB.init(allocator, "/tmp/demo.duck", .{}) catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "DB init error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{
            .status = .@"Internal Server Error",
            .mime = http.Mime.TEXT,
            .body = msg,
        });
    };
    defer db.deinit();

    var conn = db.conn() catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Connection error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{
            .status = .@"Internal Server Error",
            .mime = http.Mime.TEXT,
            .body = msg,
        });
    };
    defer conn.deinit();

    // Create table
    _ = conn.exec(
        "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT, created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP)",
        .{},
    ) catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Create table error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{
            .status = .@"Internal Server Error",
            .mime = http.Mime.TEXT,
            .body = msg,
        });
    };

    // Insert demo data
    _ = conn.exec("INSERT OR REPLACE INTO users (id, name) VALUES (1, 'Alice'), (2, 'Bob'), (3, 'Carol')", .{}) catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Insert error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{
            .status = .@"Internal Server Error",
            .mime = http.Mime.TEXT,
            .body = msg,
        });
    };

    // Query data
    var rows = conn.query("SELECT id, name, created_at FROM users ORDER BY id", .{}) catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Query error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{
            .status = .@"Internal Server Error",
            .mime = http.Mime.TEXT,
            .body = msg,
        });
    };
    defer rows.deinit();

    // Build JSON response (Zig 0.15: ArrayList is unmanaged, init with .{})
    var json: std.ArrayList(u8) = .{};
    defer json.deinit(allocator);

    try json.appendSlice(allocator, "{\"status\": \"ok\", \"users\": [");

    var first = true;
    while (rows.next() catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Row iteration error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{
            .status = .@"Internal Server Error",
            .mime = http.Mime.TEXT,
            .body = msg,
        });
    }) |row| {
        if (!first) try json.appendSlice(allocator, ", ");
        first = false;

        const id = row.get(i32, 0);
        const name = row.get([]const u8, 1);

        const writer = json.writer(allocator);
        try std.fmt.format(writer, "{{\"id\": {d}, \"name\": \"{s}\"}}", .{ id, name });
    }

    try json.appendSlice(allocator, "]}");

    const body = try ctx.allocator.dupe(u8, json.items);
    errdefer ctx.allocator.free(body);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.JSON,
        .body = body,
    });
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Initialize tardy runtime
    var t = try Tardy.init(allocator, .{ .threading = .auto });
    defer t.deinit();

    // Setup router with our handlers
    var router = try Router.init(allocator, &.{
        Route.init("/").get({}, root_handler).layer(),
        Route.init("/api").get({}, api_handler).layer(),
        Route.init("/health").get({}, health_handler).layer(),
        Route.init("/db").get({}, db_handler).layer(),
    }, .{});
    defer router.deinit(allocator);

    // Create socket - using TCP instead of Unix for easier testing
    var socket = try Socket.init(.{ .tcp = .{ .host = "127.0.0.1", .port = 43280 } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(256);

    std.debug.print("Server listening on http://127.0.0.1:43280\n", .{});
    std.debug.print("Routes:\n", .{});
    std.debug.print("  - http://127.0.0.1:43280/       (Mustache HTML page)\n", .{});
    std.debug.print("  - http://127.0.0.1:43280/api    (JSON API)\n", .{});
    std.debug.print("  - http://127.0.0.1:43280/health (Health check)\n", .{});
    std.debug.print("  - http://127.0.0.1:43280/db     (DuckDB + zuckdb demo)\n", .{});

    const EntryParams = struct {
        router: *const Router,
        socket: Socket,
    };

    try t.entry(
        EntryParams{ .router = &router, .socket = socket },
        struct {
            fn entry(rt: *Runtime, p: EntryParams) !void {
                var server = Server.init(.{});
                try server.serve(rt, p.router, p.socket);
            }
        }.entry,
    );
}
