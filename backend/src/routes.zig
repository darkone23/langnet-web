const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const tardy = zzz.tardy;
const Dir = tardy.Dir;

const config_mod = @import("config.zig");
const template_mod = @import("template.zig");
const zuckdb = @import("zuckdb");

const Context = http.Context;
const Router = http.Router;
const Route = http.Route;
const Respond = http.Respond;
const FsDir = http.FsDir;

var global_cfg: ?*config_mod.Config = null;
var global_cache: ?*template_mod.TemplateCache = null;

pub fn initGlobals(cfg: *config_mod.Config, cache: *template_mod.TemplateCache) void {
    global_cfg = cfg;
    global_cache = cache;
}

fn expectGlobals() !struct {
    cfg: *config_mod.Config,
    cache: *template_mod.TemplateCache,
} {
    const cfg = global_cfg orelse return error.MissingGlobals;
    const cache = global_cache orelse return error.MissingGlobals;
    return .{ .cfg = cfg, .cache = cache };
}

fn readFile(ctx: *const Context, path: []const u8) ![]u8 {
    const file = if (std.fs.path.isAbsolute(path))
        try std.fs.openFileAbsolute(path, .{})
    else
        try std.fs.cwd().openFile(path, .{});
    defer file.close();

    const end_pos = try file.getEndPos();
    const size = std.math.cast(usize, end_pos) orelse return error.FileTooLarge;
    var buffer = try ctx.allocator.alloc(u8, size);
    const bytes_read = try file.readAll(buffer);
    return buffer[0..bytes_read];
}

fn serveIndex(ctx: *const Context, _: void) !Respond {
    const globals = try expectGlobals();
    const index_path = try globals.cfg.getIndexPath(ctx.allocator);
    defer ctx.allocator.free(index_path);

    const body = try readFile(ctx, index_path);

    return ctx.response.apply(.{ .status = .OK, .mime = http.Mime.HTML, .body = body });
}

fn serveViteSvg(ctx: *const Context, _: void) !Respond {
    const globals = try expectGlobals();
    const svg_path = try globals.cfg.getViteSvgPath(ctx.allocator);
    defer ctx.allocator.free(svg_path);

    const body = try readFile(ctx, svg_path);

    return ctx.response.apply(.{ .status = .OK, .mime = http.Mime.SVG, .body = body });
}

fn apiHelloGet(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.JSON,
        .body = "{\"message\":\"Hello from Zig API!\"}",
    });
}

fn apiHelloPost(ctx: *const Context, _: void) !Respond {
    const raw_body = ctx.request.body orelse "world";
    const trimmed = std.mem.trim(u8, raw_body, " \r\n\t");
    const name = if (trimmed.len == 0) "world" else trimmed;

    const message = try std.fmt.allocPrint(ctx.allocator, "{{\"message\":\"Hello, {s}!\"}}", .{name});

    return ctx.response.apply(.{ .status = .OK, .mime = http.Mime.JSON, .body = message });
}

fn apiHelloHtmx(ctx: *const Context, _: void) !Respond {
    const globals = try expectGlobals();
    const template_path = try std.fs.path.join(ctx.allocator, &.{ globals.cfg.templates_path, "hello_htmx.html" });
    defer ctx.allocator.free(template_path);

    const rendered = try globals.cache.renderTemplate(template_path, .{ .message = "Hello from HTMX + Mustache!" });
    defer globals.cache.allocator.free(rendered);

    const body = try ctx.allocator.dupe(u8, rendered);

    return ctx.response.apply(.{ .status = .OK, .mime = http.Mime.HTML, .body = body });
}

fn apiMainContent(ctx: *const Context, _: void) !Respond {
    const globals = try expectGlobals();
    const template_path = try std.fs.path.join(ctx.allocator, &.{ globals.cfg.templates_path, "main_content.html" });
    defer ctx.allocator.free(template_path);

    const rendered = try globals.cache.renderTemplate(template_path, .{});
    defer globals.cache.allocator.free(rendered);

    const body = try ctx.allocator.dupe(u8, rendered);
    return ctx.response.apply(.{ .status = .OK, .mime = http.Mime.HTML, .body = body });
}

fn apiHealth(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.JSON,
        .body = "{\"status\":\"ok\"}",
    });
}

fn apiDuckdbExample(ctx: *const Context, _: void) !Respond {
    const globals = try expectGlobals();

    var db = zuckdb.DB.init(ctx.allocator, globals.cfg.db_path, .{}) catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "DB init error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = msg });
    };
    defer db.deinit();

    var conn = db.conn() catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Connection error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = msg });
    };
    defer conn.deinit();

    _ = conn.exec(
        "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)",
        .{},
    ) catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Create table error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = msg });
    };

    _ = conn.exec("DELETE FROM users", .{}) catch {};
    _ = conn.exec("INSERT INTO users (id, name) VALUES (1,'Alice'), (2,'Bob'), (3,'Carol')", .{}) catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Insert error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = msg });
    };

    var rows = conn.query("SELECT id, name FROM users ORDER BY id", .{}) catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Query error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = msg });
    };
    defer rows.deinit();

    var json = std.ArrayListUnmanaged(u8){};
    try json.appendSlice(ctx.allocator, "{\"status\":\"ok\",\"users\":[");

    var first = true;
    while (rows.next() catch |err| {
        const msg = try std.fmt.allocPrint(ctx.allocator, "Row iteration error: {s}", .{@errorName(err)});
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = msg });
    }) |row| {
        if (!first) try json.appendSlice(ctx.allocator, ",");
        first = false;

        const id = row.get(i32, 0);
        const name = row.get([]const u8, 1);

        try std.fmt.format(json.writer(ctx.allocator), "{{\"id\":{d},\"name\":\"{s}\"}}", .{ id, name });
    }

    try json.appendSlice(ctx.allocator, "]}");
    const body = try json.toOwnedSlice(ctx.allocator);

    return ctx.response.apply(.{ .status = .OK, .mime = http.Mime.JSON, .body = body });
}

pub fn createRouter(allocator: std.mem.Allocator, assets_dir: Dir) !Router {
    // Ensure globals are set before building the router.
    _ = try expectGlobals();

    return try Router.init(allocator, &.{
        Route.init("/").get({}, serveIndex).layer(),
        Route.init("/vite.svg").get({}, serveViteSvg).layer(),
        Route.init("/api/hello").get({}, apiHelloGet).post({}, apiHelloPost).layer(),
        Route.init("/api/hello-htmx").get({}, apiHelloHtmx).layer(),
        Route.init("/api/main-content").get({}, apiMainContent).layer(),
        Route.init("/api/health").get({}, apiHealth).layer(),
        Route.init("/api/duckdb-example").get({}, apiDuckdbExample).layer(),
        FsDir.serve("/assets", assets_dir),
    }, .{});
}
