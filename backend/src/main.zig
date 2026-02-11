const std = @import("std");
const mustache = @import("mustache");
const zzz = @import("zzz");
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
    }, .{});
    defer router.deinit(allocator);

    // Create socket - using TCP instead of Unix for easier testing
    var socket = try Socket.init(.{ .tcp = .{ .host = "127.0.0.1", .port = 43280 } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(256);

    std.debug.print("Server listening on http://127.0.0.1:43280\n", .{});
    std.debug.print("Routes:\n", .{});
    std.debug.print("  - http://127.0.0.1:43280/      (Mustache HTML page)\n", .{});
    std.debug.print("  - http://127.0.0.1:43280/api   (JSON API)\n", .{});
    std.debug.print("  - http://127.0.0.1:43280/health (Health check)\n", .{});

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
