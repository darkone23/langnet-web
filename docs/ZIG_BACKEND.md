# Zig Backend Guide

This guide covers developing the Zig backend for the langnet-web project, including Zig 0.15.x (post-writergate) patterns and the zzz HTTP framework.

## Overview

The backend is a **Zig web server** using:
- **Zig 0.15.x**: Modern, type-safe, systems programming language
- **zzz HTTP framework**: Async HTTP server with Tardy runtime
- **Mustache**: Server-side template engine
- **DuckDB (via zuckdb)**: Embedded analytics database

**Philosophy:** Explicit over clever, typed data at edges, boring infrastructure.

## Project Structure

```
backend/
├── src/
│   ├── main.zig           # Application entry point
│   ├── routes.zig         # API route definitions
│   ├── config.zig         # Configuration management
│   ├── template.zig       # Template cache and rendering
│   └── root.zig           # Module exports
├── templates/             # Mustache templates (HTMX partials)
│   ├── main_content.html  # Main page content
│   └── hello_htmx.html    # HTMX partial template
├── public/                # Static assets (optional)
├── build.zig              # Zig build configuration
├── build.zig.zon          # Zig dependencies
└── justfile               # Backend commands
```

## Zig 0.15.x Key Patterns

### The Writergate Changes

Zig 0.15.x introduced major I/O interface changes known as "writergate":

**Key Concept:** Forget old std.io APIs. Use this pattern:

```zig
var buffer: [4096]u8 = undefined;
const file_writer: std.fs.File.Writer = file.writer(&buffer);
const writer: *std.Io.Writer = &file_writer.interface;

try writer.writeAll("data");
try writer.flush();
```

**Critical Points:**
1. Get `.interface` pointer before using I/O methods
2. Use `*std.Io.Writer` and `*std.Io.Reader`
3. Call `writeX()` / `streamX()` methods
4. Choose buffered or unbuffered based on use case

See `docs/ZIG_0.15_NOTES.md` for complete migration guide.

### Writing to Stdout

```zig
pub fn demoStdout() !void {
    var buffer: [4096]u8 = undefined;
    const output_writer = std.fs.File.Writer = std.fs.File.stdout().writer(&buffer);
    
    // IMPORTANT: capture an interface pointer
    const writer: *std.Io.Writer = &output_writer.interface;
    
    try writer.writeAll("Hello world\n");
    try writer.flush();
}
```

### Reading from Stdin

```zig
pub fn demoStdin(allocator: std.mem.Allocator) !void {
    var buffer: [4096]u8 = undefined;
    const input_reader = std.fs.File.Reader = std.fs.File.stdin().reader(&buffer);
    
    // IMPORTANT: capture an interface pointer
    const reader: *std.Io.Reader = &input_reader.interface;
    
    const limit = 1024;
    var write_buffer: [1024]u8 = undefined;
    var writer_fixed = std.Io.Writer.fixed(&write_buffer);
    const len = try reader.streamDelimiterLimit(&writer_fixed, '\n', .limited(limit));
    std.debug.print("Read: {d}:{s}\n", .{ len, writer_fixed.buffered() });
}
```

### Formatted Writing

```zig
pub fn printf(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
    var buffer: [4096]u8 = undefined;
    const stdout_writer = std.fs.File.Writer = std.fs.File.stdout().writer(&buffer);
    const writer: *std.Io.Writer = &stdout_writer.interface;
    
    const msg = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(msg);
    
    try writer.writeAll(msg);
    try writer.flush();
}
```

## HTTP Server (zzz)

### Server Initialization

**File:** `backend/src/main.zig`

```zig
const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const tardy = zzz.tardy;
const Tardy = tardy.Tardy(.auto);
const Runtime = tardy.Runtime;
const Socket = tardy.Socket;

const Server = http.Server;
const Router = http.Router;

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

    routes_mod.initGlobals(&cfg, &cache);
    var router = try routes_mod.createRouter(allocator, getAssetsDir(allocator, cfg));
    defer router.deinit(allocator);

    var socket = try Socket.init(.{ .tcp = .{ .host = cfg.host, .port = cfg.port } });
    defer socket.close_blocking();
    try socket.bind();
    try socket.listen(256);

    std.debug.print("Server listening on http://{s}:{d}\n", .{ cfg.host, cfg.port });

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
```

### Route Definition

**File:** `backend/src/routes.zig`

```zig
const std = @import("std");
const zzz = @import("zzz");
const http = zzz.HTTP;

const Context = http.Context;
const Router = http.Router;
const Route = http.Route;
const Respond = http.Respond;

// Route handler
fn myEndpoint(ctx: *const Context, _: void) !Respond {
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.JSON,
        .body = "{\"message\":\"Hello from Zig!\"}",
    });
}

// Add to router
Route.init("/api/hello").get({}, myEndpoint).layer(),
```

### Common HTTP Methods

```zig
// GET request
Route.init("/api/data").get({}, getData).layer(),

// POST request
Route.init("/api/submit").post({}, submitData).layer(),

// Multiple methods
Route.init("/api/resource")
    .get({}, getResource)
    .post({}, createResource)
    .layer(),
```

## Template Rendering

### Template Cache

**File:** `backend/src/template.zig`

```zig
const std = @import("std");
const mustache = @import("mustache");

pub const TemplateCache = struct {
    allocator: std.mem.Allocator,
    templates: std.StringHashMap(Template),

    pub fn init(allocator: std.mem.Allocator) TemplateCache {
        return TemplateCache{
            .allocator = allocator,
            .templates = std.StringHashMap(Template).init(allocator),
        };
    }

    pub fn deinit(self: *TemplateCache) void {
        var iter = self.templates.iterator();
        while (iter.next()) |entry| {
            entry.value_ptr.deinit();
            self.allocator.free(entry.key_ptr.*);
        }
        self.templates.deinit();
    }

    pub fn renderTemplate(self: *TemplateCache, path: []const u8, data: anytype) ![]const u8 {
        const tpl = try self.getOrLoad(path);
        return tpl.render(data);
    }
};
```

### Mustache Template

**File:** `backend/templates/example.html`

```html
<div class="card bg-base-100 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">{{title}}</h2>
    <p class="text-base">{{content}}</p>
    {{#items}}
    <ul>
      {{#.}}
      <li>{{.}}</li>
      {{/.}}
    </ul>
    {{/items}}
  </div>
</div>
```

### Template in Route Handler

```zig
fn apiHtmx(ctx: *const Context, _: void) !Respond {
    const globals = try expectGlobals();
    const template_path = try std.fs.path.join(ctx.allocator, &.{ 
        globals.cfg.templates_path, 
        "example.html" 
    });
    defer ctx.allocator.free(template_path);

    const rendered = try globals.cache.renderTemplate(template_path, .{
        .title = "Hello World",
        .content = "This is a dynamic message",
        .items = &[_]const u8{ "Item 1", "Item 2", "Item 3" },
    });
    defer globals.cache.allocator.free(rendered);

    const body = try ctx.allocator.dupe(u8, rendered);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = body,
    });
}
```

## Configuration

### Config Struct

**File:** `backend/src/config.zig`

```zig
pub const Config = struct {
    allocator: std.mem.Allocator,
    host: []const u8,
    port: u16,
    frontend_dist_path: []const u8,
    templates_path: []const u8,
    db_path: []const u8,

    pub fn init(allocator: std.mem.Allocator) !Config {
        const host = try getEnv(allocator, "HOST", "0.0.0.0");
        const port_str = try getEnv(allocator, "PORT", "43210");
        defer allocator.free(port_str);
        const port = std.fmt.parseInt(u16, port_str, 10) catch 43210;

        const frontend_dist = try getEnv(allocator, "FRONTEND_DIST", "../frontend/dist");
        const templates = try getEnv(allocator, "TEMPLATES_DIR", "templates");
        const db = try getEnv(allocator, "DB_PATH", "/tmp/app.duck");

        return Config{
            .allocator = allocator,
            .host = host,
            .port = port,
            .frontend_dist_path = frontend_dist,
            .templates_path = templates,
            .db_path = db,
        };
    }

    pub fn deinit(self: *Config) void {
        self.allocator.free(self.host);
        self.allocator.free(self.frontend_dist_path);
        self.allocator.free(self.templates_path);
        self.allocator.free(self.db_path);
    }

    fn getEnv(allocator: std.mem.Allocator, key: []const u8, default: []const u8) ![]const u8 {
        if (std.posix.getenv(key)) |value| {
            return allocator.dupe(u8, value);
        }
        return allocator.dupe(u8, default);
    }
};
```

### Using Config

```zig
fn main() !void {
    var cfg = try config.Config.init(allocator);
    defer cfg.deinit();

    std.debug.print("Server listening on http://{s}:{d}\n", .{ cfg.host, cfg.port });
}
```

## Database (DuckDB)

### Using DuckDB

**File:** `backend/src/routes.zig`

```zig
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

    // Create table
    _ = conn.exec(
        "CREATE TABLE IF NOT EXISTS users (id INTEGER PRIMARY KEY, name TEXT)",
        .{},
    ) catch |err| {
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = "Table creation error" });
    };

    // Insert data
    _ = conn.exec("INSERT INTO users (id, name) VALUES (1,'Alice'), (2,'Bob'), (3,'Carol')", .{}) catch {};

    // Query data
    var rows = conn.query("SELECT id, name FROM users ORDER BY id", .{}) catch |err| {
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = "Query error" });
    };
    defer rows.deinit();

    // Build JSON response
    var json = std.ArrayListUnmanaged(u8).init(ctx.allocator);
    try json.appendSlice(ctx.allocator, "{\"status\":\"ok\",\"users\":[");
    
    var first = true;
    while (rows.next() catch |err| {
        return ctx.response.apply(.{ .status = .@"Internal Server Error", .mime = http.Mime.JSON, .body = "Row iteration error" });
    }) |row| {
        if (!first) try json.appendSlice(ctx.allocator, ",");
        first = false;

        const id = row.get(i32, 0);
        const name = row.get([]const u8, 1);

        try std.fmt.format(json.writer(ctx.allocator), "  {{\"id\":{d},\"name\":\"{s}\"}}", .{ id, name });
    }

    try json.appendSlice(ctx.allocator, "]}");
    const body = try json.toOwnedSlice(ctx.allocator);

    return ctx.response.apply(.{ .status = .OK, .mime = http.Mime.JSON, .body = body });
}
```

## Error Handling

### Error Response Helper

```zig
fn errorResponse(ctx: *const Context, status: http.Status, message: []const u8) !Respond {
    const json = try std.fmt.allocPrint(ctx.allocator,
        "{{\"error\":\"{s}\"}}", .{message});
    defer ctx.allocator.free(json);

    return ctx.response.apply(.{
        .status = status,
        .mime = http.Mime.JSON,
        .body = json,
    });
}

// Usage
const body = try readFile(ctx, path);
defer ctx.allocator.free(body);

if (body.len == 0) {
    return try errorResponse(ctx, .@"Not Found", "Resource not found");
}
```

### Request Validation

```zig
fn validateRequestBody(ctx: *const Context, comptime T: type, max_size: usize) !T {
    const raw_body = ctx.request.body orelse return error.MissingBody;
    
    if (raw_body.len > max_size) {
        return error.BodyTooLarge;
    }
    
    // Parse and validate body
    // ...
}

// Usage
fn apiSubmit(ctx: *const Context, _: void) !Respond {
    const data = validateRequestBody(ctx, Data, 1024) catch |err| {
        return try errorResponse(ctx, .@"Bad Request", @errorName(err));
    };
    
    // Process data...
}
```

## Build and Run

### Building

```bash
cd backend
zig build

# Or
just build

# Or with release mode
zig build -Drelease-fast
```

### Running Development Server

```bash
cd backend
zig run

# Or
just dev

# Or with justfile
just run-server
```

### Running Tests

```bash
cd backend
zig build test

# Or
just test
```

## Best Practices

### Resource Management

```zig
// Good
var gpa = std.heap.GeneralPurposeAllocator(.{ .thread_safe = true }){};
const allocator = gpa.allocator();
defer _ = gpa.deinit();

var file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();

var data = try file.readToEndAlloc(allocator, 1024);
defer allocator.free(data);
```

### Error Handling

```zig
// Good
fn myFunction() !void {
    const result = try mightFail();
    // Use result
}

fn myFunction2() !void {
    mightFail() catch |err| {
        // Handle error
        std.debug.print("Error: {}\n", .{@errorName(err)});
    };
}
```

### Type Safety

```zig
// Good
const User = struct {
    id: u32,
    name: []const u8,
};

fn processUser(user: User) void {
    std.debug.print("User: {d}: {s}\n", .{ user.id, user.name});
}

// Avoid
fn processUser(id: u32, name: []const u8) void {
    std.debug.print("User: {d}: {s}\n", .{ id, name });
}
```

### Code Organization

```zig
// Good: Separate concerns
const config_mod = @import("config.zig");
const template_mod = @import("template.zig");
const routes_mod = @import("routes.zig");

// Use clear module structure
```

## Common Patterns

### Serving Static Files

```zig
// In routes.zig
fn serveIndex(ctx: *const Context, _: void) !Respond {
    const globals = try expectGlobals();
    const index_path = try globals.cfg.getIndexPath(ctx.allocator);
    defer ctx.allocator.free(index_path);

    const body = try readFile(ctx, index_path);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = body,
    });
}
```

### API Response Patterns

```zig
// JSON response
fn jsonResponse(ctx: *const Context, data: anytype) !Respond {
    const json = try std.fmt.allocPrint(ctx.allocator,
        "{{\"status\":\"ok\",\"data\":{s}}", .{data});
    defer ctx.allocator.free(json);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.JSON,
        .body = json,
    });
}

// HTML response (for HTMX)
fn htmlResponse(ctx: *const Context, html: []const u8) !Respond {
    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.HTML,
        .body = html,
    });
}
```

## Performance

### Async I/O

The Tardy runtime provides efficient async I/O:

```zig
// zzz and Tardy are designed for high concurrency
var t = try Tardy.init(allocator, .{ .threading = .auto });

// Multiple requests handled concurrently
```

### Template Caching

In-memory template cache reduces file I/O:

```zig
pub const TemplateCache = struct {
    templates: std.StringHashMap(Template),

    pub fn getOrLoad(self: *TemplateCache, path: []const u8) !*Template {
        // Load from cache if available
        if (self.templates.get(path)) |tpl| {
            return tpl;
        }
        // Otherwise load from disk
        return try self.loadAndCache(path);
    }
};
```

### Memory Management

Zig's allocator system provides explicit control:

```zig
// Good: Small allocations for temporary data
const buffer: [1024]u8 = undefined;

// Avoid: Large allocations for things that could be streamed
const huge_data = try allocator.alloc(u8, 1_000_000);
defer allocator.free(huge_data);
```

## Testing

### Writing Tests

```zig
const std = @import("std");

test "route returns correct JSON" {
    const allocator = std.testing.allocator;
    
    const response = try myRouteHandler(&allocator, .{});
    defer allocator.free(response.body);

    try std.testing.expectEqual(http.Mime.JSON, response.mime);
    try std.testing.expectStringContains("Hello", response.body);
}

test "template renders correctly" {
    const allocator = std.testing.allocator;
    
    const rendered = try myTemplate(&allocator, .{
        .message = "Test",
    });
    defer allocator.free(rendered);

    try std.testing.expectStringContains("Test", rendered);
}
```

### Running Tests

```bash
cd backend
zig test

# Or specific test file
zig test routes_test.zig
```

## Deployment

### Production Build

```bash
cd backend
zig build -Drelease-fast

# Binary output to: zig-out/bin/backend
cp zig-out/bin/backend /usr/local/bin/
```

### Running in Production

```bash
# Set environment variables
export HOST=0.0.0.0
export PORT=43210
export FRONTEND_DIST=/var/www/app
export TEMPLATES_DIR=/etc/langnet-web/templates
export DB_PATH=/var/lib/langnet-web/app.duck

# Run server
langnet-web
```

### Reverse Proxy (Caddy)

```
example.com {
    reverse_proxy localhost:43210
}
```

## Troubleshooting

### Build Errors

**Error: "missing allocator"**
```zig
// Fix: Pass allocator to all collections
const list = std.ArrayList(Item).init(allocator);
try list.append(allocator, item);
```

**Error: "ambiguous format string"**
```zig
// Fix: Use {f} or {any}
std.debug.print("{f}", .{value});
// Or
std.debug.print("{any}", .{value});
```

### Runtime Errors

**Error: "Address already in use"**
```bash
# Fix: Check what's using the port
lsof -i :43210
# Or use different port
PORT=43211 zig run
```

**Error: "Template not found"**
```zig
// Fix: Check template path and file existence
const template_path = try std.fs.path.join(allocator, &.{ templates_dir, "template.html" });

// Ensure template exists
if (!std.fs.cwd().access(template_path, .{})) {
    return error.TemplateNotFound;
}
```

## References

- [Zig Documentation](https://ziglang.org/documentation/master/)
- [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)
- [zzz HTTP Framework](https://github.com/tardy-org/zzz)
- [mustache-zig](https://github.com/batiati/mustache-zig)
- [DuckDB Documentation](https://duckdb.org/docs/)
- [Zig 0.15.x Migration Guide](./ZIG_0.15_NOTES.md)
