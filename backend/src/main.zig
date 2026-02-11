const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.auto);
const Runtime = tardy.Runtime;
const Socket = tardy.Socket;
const Dir = tardy.Dir;

const Server = http.Server;
const Router = http.Router;

const config = @import("config.zig");
const template_mod = @import("template.zig");
const routes_mod = @import("routes.zig");

pub const std_options: std.Options = .{ .log_level = .err };

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    var cfg = try config.Config.init(allocator);
    defer cfg.deinit();

    var cache = template_mod.TemplateCache.init(allocator);
    defer cache.deinit();

    var t = try Tardy.init(allocator, .{ .threading = .auto });
    defer t.deinit();

    const assets_path = try cfg.getAssetsPath(allocator);
    defer allocator.free(assets_path);

    const static_dir = try std.fs.cwd().openDir(assets_path, .{});

    routes_mod.initGlobals(&cfg, &cache);

    var router = try routes_mod.createRouter(allocator, Dir.from_std(static_dir));
    defer router.deinit(allocator);

    var socket = try Socket.init(.{ .tcp = .{ .host = cfg.host, .port = cfg.port } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(256);

    std.debug.print("Server listening on http://{s}:{d}\n", .{ cfg.host, cfg.port });
    std.debug.print("Routes:\n", .{});
    std.debug.print("  - http://{s}:{d}/       (Frontend index.html)\n", .{ cfg.host, cfg.port });
    std.debug.print("  - http://{s}:{d}/vite.svg (Frontend icon)\n", .{ cfg.host, cfg.port });
    std.debug.print("  - http://{s}:{d}/assets/*  (Frontend static assets)\n", .{ cfg.host, cfg.port });
    std.debug.print("  - http://{s}:{d}/api/hello GET/POST\n", .{ cfg.host, cfg.port });
    std.debug.print("  - http://{s}:{d}/api/hello-htmx (HTMX partial)\n", .{ cfg.host, cfg.port });
    std.debug.print("  - http://{s}:{d}/api/health (Health check)\n", .{ cfg.host, cfg.port });
    std.debug.print("  - http://{s}:{d}/api/duckdb-example (DuckDB demo)\n", .{ cfg.host, cfg.port });

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
