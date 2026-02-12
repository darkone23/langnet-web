# Zig 0.15.x Post-Writergate Notes

This document provides information about Zig 0.15.x and post-writergate standard library changes relevant to this project, with real-world migration roadblocks and solutions.

## Overview

This project uses Zig 0.15.x, which includes "writergate" and other major changes to Zig's standard library.

**What is Writergate?**
The writergate was a major refactoring of Zig's standard library focused on **I/O Reader/Writer interfaces**:

1. **Moved to Concrete I/O Interfaces**: Deprecated generic `std.io.Reader` and `std.io.Writer` in favor of non-generic `std.Io.Reader` and `std.Io.Writer` with buffer in the interface (not implementation)
2. **Improved Performance**: Buffer in the interface enables optimizer-friendly hot paths; concrete types remove generic poisoning
3. **Precise Error Handling**: Defined specific error sets for each function instead of passing errors through
4. **New I/O Concepts**: Added vectors, splatting, direct file-to-file transfer, and peek functionality

**Key Insight:** While the old interface was generic and forced all functions to use `anytype`, the new interface is **concrete**—removing temptation to make APIs operate directly on networking streams, file handles, or memory buffers.

## Real-World Migration Roadblocks

Based on experience migrating a CLI tool ("safe-curl") to Zig 0.15.x, here are the specific roadblocks encountered and how to fix them.

### Roadblock 1: ArrayList Requires Allocator Everywhere

**The Change:** Zig 0.15 replaced `std.ArrayList` with `std.array_list.Managed` as default. The "managed" variant now requires passing an allocator to every method call.

**What Broke:**
```zig
const Finding = struct {
    severity: Severity,
    message: []const u8,
    line_num: usize,
};

const AnalysisResult = struct {
    findings: std.ArrayList(Finding),

    fn init(allocator: std.mem.Allocator) AnalysisResult {
        return .{
            .findings = std.ArrayList(Finding).init(allocator),
        };
    }

    fn addFinding(self: *AnalysisResult, finding: Finding) !void {
        try self.findings.append(finding);  // ERROR: missing allocator
    }
};
```

**Error:**
```
error: expected 2 arguments, found 1
```

**The Fix - Option 1 (Store Allocator):**
```zig
const AnalysisResult = struct {
    findings: std.ArrayList(Finding),
    allocator: std.mem.Allocator,  // Store allocator

    fn init(allocator: std.mem.Allocator) AnalysisResult {
        return .{
            .findings = std.ArrayList(Finding).init(allocator),
            .allocator = allocator,
        };
    }

    fn addFinding(self: *AnalysisResult, finding: Finding) !void {
        try self.findings.append(self.allocator, finding);  // Pass allocator
    }

    fn deinit(self: *AnalysisResult) void {
        self.findings.deinit(self.allocator);  // Pass here too
    }
};
```

**The Fix - Option 2 (Use Unmanaged Variant - More Idiomatic):**
```zig
const AnalysisResult = struct {
    findings: std.ArrayListUnmanaged(Finding),

    fn init() AnalysisResult {
        return .{
            .findings = .{},  // Empty initialization
        };
    }

    fn addFinding(self: *AnalysisResult, allocator: std.mem.Allocator, finding: Finding) !void {
        try self.findings.append(allocator, finding);
    }

    fn deinit(self: *AnalysisResult, allocator: std.mem.Allocator) void {
        self.findings.deinit(allocator);
    }
};
```

**Why This Change?**
The Zig team explains that storing the allocator in a struct adds complexity. With the unmanaged variant as default, you get:
- Simpler method signatures
- Static initialization support (`.{} `)`)
- Explicit allocator lifetime management

**Trade-off:** You pass an allocator everywhere, but your data structures are cleaner.

### Roadblock 2: Empty Struct Initialization `{}`

**The Change:** Zig 0.15 introduced a shorthand for empty struct initialization.

**What This Enables:**
Before, initializing an empty ArrayList required:
```zig
var findings = std.ArrayList(Finding).init(allocator);
```

Now you can use struct field inference:
```zig
const AnalysisResult = struct {
    findings: std.ArrayList(Finding),

    fn init(allocator: std.mem.Allocator) AnalysisResult {
        return .{
            .findings = .{},  // Compiler infers std.ArrayList(Finding).init(allocator)
            .allocator = allocator,
        };
    }
};
```

**When It Works:** Field type is clear from context
```zig
var list: std.ArrayList(Item) = .{};  // Works - type inferred from struct
```

**When It Breaks:** Compiler can't infer type
```zig
var list = .{};  // Error: cannot infer type
```

This syntax can be confusing because `.{} ` looks like an empty struct literal, but it actually calls the appropriate `init` function based on the field type.

### Roadblock 3: Process API Breaking Changes

**The Change:** `std.process.Child.run()` return type changed significantly.

**What Broke:**
```zig
fn fetchFromUrl(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "curl", "-fsSL", url },
    });
    defer allocator.free(result.stderr);

    // This line broke
    if (result.term.Exited != 0) {
        allocator.free(result.stdout);
        return error.HttpRequestFailed;
    }

    return result.stdout;
}
```

**Error:**
```
error: no field named 'Exited' in union 'std.process.Child.Term'
```

**The Fix:**
The `term` field changed from having an `Exited` field to being a tagged union:

```zig
fn fetchFromUrl(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "curl", "-fsSL", url },
    });
    defer allocator.free(result.stderr);

    // Check union variant properly
    switch (result.term) {
        .Exited => |code| {
            if (code != 0) {
                allocator.free(result.stdout);
                return error.HttpRequestFailed;
            }
        },
        else => {
            allocator.free(result.stdout);
            return error.ProcessFailed;
        },
    }

    return result.stdout;
}
```

This is more explicit about handling different termination types (signal, unknown, etc.).

### Roadblock 4: HTTP Client Instability

**The Problem:** Zig's `std.http.Client` is still evolving rapidly between versions.

**What Was Tried:**
```zig
fn fetchFromUrl(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(url);
    var server_header_buffer: [16384]u8 = undefined;

    var req = try client.open(.GET, uri, .{
        .server_header_buffer = &server_header_buffer,
    });
    defer req.deinit();

    try req.send();
    try req.wait();

    // ... read response
}
```

**Errors:**
- API mismatches between documentation and actual implementation
- Buffer size requirements unclear
- Response reading patterns changed between minor versions

**The Workaround:**
The Zig 0.15 release notes acknowledge: "HTTP client/server completely reworked to depend only on I/O streams, not networking directly."

This instability meant falling back to shelling out:

```zig
fn fetchFromUrl(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    // Use curl as a fallback since Zig HTTP client API is too unstable
    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ "curl", "-fsSL", url },
    });
    defer allocator.free(result.stderr);

    switch (result.term) {
        .Exited => |code| {
            if (code != 0) {
                allocator.free(result.stdout);
                return error.HttpRequestFailed;
            }
        },
        else => {
            allocator.free(result.stdout);
            return error.ProcessFailed;
        },
    }

    return result.stdout;
}
```

Not ideal for a "zero dependency" tool, but pragmatic given API churn.

**Recommendation:** This project currently uses zzz HTTP framework (not `std.http.Client`), which provides stable HTTP APIs. If you need HTTP client functionality, consider using zzz or a stable third-party library.

### Roadblock 5: Reader/Writer Overhaul ("Writergate")

**The Change:** Zig 0.15 completely redesigned `std.io.Reader` and `std.io.Writer` interfaces.

**What Changed:**
**Before (0.14):**
```zig
const stdout = std.io.getStdOut().writer();
try stdout.print("Hello {s}\n", .{"world"});
```

**After (0.15):**
```zig
const stdout = std.fs.File.stdout();
try stdout.writeAll("Hello world\n");

// For formatted output, you need a buffer
var stdout_buffer: [4096]u8 = undefined;
var stdout_writer = stdout.writer(&stdout_buffer);
try stdout_writer.print("Hello {s}\n", .{"world"});
try stdout_writer.flush();
```

**Why This Matters:**
The old API wrapped streams in multiple layers of abstraction. The new API:
- Builds buffering directly into reader/writer
- Supports zero-copy operations (file-to-file transfers)
- Provides precise error sets
- Enables vector I/O and advanced operations

**Helper Function Approach:**
```zig
fn printf(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
    const stdout = std.fs.File.stdout();
    const msg = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(msg);
    try stdout.writeAll(msg);
}
```

This allocates for the formatted string, but keeps call sites clean:

```zig
try printf(allocator, "{s}[{s}]{s} {s}\n", .{
    color_code,
    severity_name,
    Color.NC,
    finding.message
});
```

### Roadblock 6: Undefined Behavior Rules Tightened

**The Change:** Zig 0.15 standardizes when undefined is allowed.

**From Release Notes:**
"Only operators which can never trigger Illegal Behavior permit undefined as an operand."

**What This Means:**
```zig
// This now errors at compile time
const x: i32 = undefined;
const y = x + 1;  // Error: undefined used in arithmetic
```

**Safe Uses of Undefined:**
```zig
var buffer: [256]u8 = undefined;  // OK: just reserves space
const ptr: *u8 = undefined;  // OK: pointers can be undefined
```

This catches bugs earlier but requires more explicit initialization.

**Practical Impact:**
In code, you couldn't do:
```zig
var line_num: usize = undefined;
while (condition) : (line_num += 1) {  // Error
    // ...
}
```

Had to initialize explicitly:
```zig
var line_num: usize = 1;
while (condition) : (line_num += 1) {
    // ...
}
```

## Performance Data (from Writergate Benchmarks)

The writergate changes provide significant performance improvements:

| Benchmark | Wall Time | Peak RSS | CPU Cycles | Instructions |
|------------|-------------|-----------|-------------|---------------|
| **Building Self-Hosted Compiler** |
| vs Master | -14.6% | +10.8% | -9.6% | -7.8% |
| **Building Hello World (ReleaseFast)** |
| vs Master | -22.4% | -0.8% | -21.5% | -23.3% |
| **Building Hello World (Debug)** |
| vs Master | -6.3% | -0.1% | -18.5% | -18.2% |

**Key Insights:**
- **ReleaseFast**: Significant wall time improvements (up to 22% faster)
- **Debug**: Reduced CPU cycles and instructions
- **Cache Performance**: Better cache hit rates (14-22% fewer cache misses)
- **Binary Size**: Small reduction (2-4% smaller)

**After (Post-Writergate - Zig 0.15.x):**
```zig
// New concrete I/O interface with buffer in interface
const reader = file.deprecatedReader(); // Deprecated, use adaptToNewApi()
const writer = file.deprecatedWriter(); // Deprecated, use adaptToNewApi()

// New std.Io.Reader and std.Io.Writer are concrete
// You provide the buffer, implementation decides minimum size
var buffer: [1024]u8 = undefined;
const stdout_writer = std.fs.File.stdout().writer(&buffer);
const stdout = &stdout_writer.interface;

try stdout.print("...", .{...});
try stdout.flush();
```

**Important Changes:**
- `std.fs.File.reader()` → `std.fs.File.deprecatedReader()`
- `std.fs.File.writer()` → `std.fs.File.deprecatedWriter()`
- `std.io.GenericReader` → `std.io.Reader`
- `std.io.GenericWriter` → `std.io.Writer`
- `std.io.AnyReader` → `std.io.Reader`
- `std.io.AnyWriter` → `std.io.Writer`

**Migration Helper:**
```zig
fn foo(old_writer: anytype) !void {
    var adapter = old_writer.adaptToNewApi();
    const w: *std.io.Writer = &adapter.new_interface;
    try w.print("{s}", .{"example"});
}
```

### Format String Breaking Changes

**Before:**
```zig
// Format method took format string and options
pub fn format(
    this: @This(),
    comptime format_string: []const u8,
    options: std.fmt.FormatOptions,
    writer: anytype,
) !void { ... }

std.debug.print("{}", .{std.zig.fmtId("example")});
```

**After (Zig 0.15.x):**
```zig
// Format method no longer takes format string or options
pub fn format(this: @This(), writer: *std.io.Writer) std.io.Writer.Error!void { ... }

// Must use {f} to call format methods
std.debug.print("{f}", .{std.zig.fmtId("example")});

// Or use {any} to skip format
std.debug.print("{any}", .{std.zig.fmtId("example")});
```

**Motivation for {f} requirement:**
- Prevents bugs when adding/removing format methods from structs
- Introducing a format method now causes compile errors at all `{}` sites
- Removing a format method no longer silently changes behavior

### Formatted Printing Changes

**Removed Functionality:**
- `std.debug.print()` no longer deals with Unicode alignment (ASCII/bytes only)
- Previous Unicode handling was not fully Unicode-aware

**Migration:**
```zig
// Must use buffering for stdout/stderr
var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
const stdout = &stdout_writer.interface;

try stdout.print("...", .{...});
try stdout.flush();
```

**Renamed Formatting Functions:**
- `std.fmt.fmtSliceEscapeLower` → `std.ascii.hexEscape`
- `std.fmt.fmtSliceEscapeUpper` → `std.ascii.hexEscape`
- `std.zig.fmtEscapes` → `std.zig.fmtString`
- `std.fmt.fmtSliceHexLower` → `{x}` format specifier
- `std.fmt.fmtSliceHexUpper` → `{X}` format specifier
- `std.fmt.fmtIntSizeDec` → `{B}` format specifier
- `std.fmt.fmtIntSizeBin` → `{Bi}` format specifier
- `std.fmt.fmtDuration` → `{D}` format specifier
- `std.fmt.fmtDurationSigned` → `{D}` format specifier

**New Format Specifiers:**
- `{t}` - Shorthand for `@tagName()` and `@errorName()`
- `{d}` - Integer printing with custom types (calls `formatNumber` method)
- `{b64}` - Output string as standard base64

**New Type:**
- `std.fmt.Formatter` → `std.fmt.Alt` (for alternative formatting)

### New I/O Concepts

**1. Vectors:**
```zig
// Efficiently write multiple values
try writer.writeAll(&[_]u8{ 'a', 'b', 'c' });
```

**2. Splatting:**
Logical "memset" operation through I/O pipelines without memory copying:
```zig
// O(M) operation instead of O(M*N)
// M = number of streams, N = number of repeated bytes
try writer.writeByteNTimes(0, 1024); // Efficient zero-fill
```

**3. Direct File-to-File Transfer:**
```zig
// Use fd-to-fd syscalls when supported (e.g., sendfile)
try std.fs.copyFile(source_path, dest_path, .{});
```

**4. Peek Functionality:**
Buffer-aware API for convenience:
```zig
// Peek at data without consuming it
const peeked = try reader.peek(buffer[0..]);
```

## The Key Pattern: `.interface` Pointer

**Important:** Forget old std.io APIs. The new pattern is:

1. Get writer/reader from file/std
2. **Get `.interface` pointer**
3. Use `*std.Io.Writer` and `*std.Io.Reader`
4. Call `writeX()` / `streamX()` methods
5. Choose buffered or unbuffered based on use case

### Writing to Stdout

```zig
pub fn demoStdout() !void {
    // buffered or unbuffered, buffer when doing many small writes
    const buffered = true;
    var buffer: [4096]u8 = undefined;
    const write_buffer = if (buffered) &buffer else &.{};

    var output_writer: std.fs.File.Writer = std.fs.File.stdout().writer(write_buffer);

    // IMPORTANT: capture an interface pointer
    const writer: *std.Io.Writer = &output_writer.interface;

    try writer.writeAll("Hello world\n");
    try writer.flush();
}
```

### Reading from Stdin

```zig
pub fn demoStdin(allocator: std.mem.Allocator, useFixed: bool) !void {
    // buffered or unbuffered, buffer when doing many small reads
    const buffered = true;
    var buffer: [4096]u8 = undefined;
    const read_buffer = if (buffered) &buffer else &.{};

    var input_reader: std.fs.File.Reader = std.fs.File.stdin().reader(read_buffer);

    // IMPORTANT: capture an interface pointer
    const reader: *std.Io.Reader = &input_reader.interface;

    const limit = 1024;
    if (useFixed) {
        // must be large enough for read to succeed
        var write_buffer: [1024]u8 = undefined;
        var writer_fixed = std.Io.Writer.fixed(&write_buffer);
        const len = try reader.streamDelimiterLimit(&writer_fixed, '\n', .limited(limit));
        std.debug.print("Read fixed: {d}:{s}\n", .{ len, writer_fixed.buffered() });
    } else {
        var writer_alloc = std.Io.Writer.Allocating.init(allocator);
        defer writer_alloc.deinit();
        const writer = &writer_alloc.writer;
        const len = try reader.streamDelimiterLimit(writer, '\n', .limited(limit));
        std.debug.print("Read alloc: {d}:{s}\n", .{ len, writer_alloc.written() });
    }
}
```

### Writing to File

```zig
pub fn writeToFile(allocator: std.mem.Allocator, path: []const u8, content: []const u8) !void {
    const file = try std.fs.cwd().createFile(path, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var file_writer: std.fs.File.Writer = file.writer(&buffer);

    // Get interface pointer
    const writer: *std.Io.Writer = &file_writer.interface;

    try writer.writeAll(content);
    try writer.flush();
}
```

### Reading from File

```zig
pub fn readFromFile(allocator: std.mem.Allocator, path: []const u8) ![]const u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();

    var buffer: [4096]u8 = undefined;
    var file_reader: std.fs.File.Reader = file.reader(&buffer);

    // Get interface pointer
    const reader: *std.Io.Reader = &file_reader.interface;

    // Read entire file
    return reader.readAllAlloc(allocator, std.math.maxInt(usize));
}
```

### Formatted Writing

```zig
pub fn printf(allocator: std.mem.Allocator, comptime fmt: []const u8, args: anytype) !void {
    var buffer: [4096]u8 = undefined;
    var stdout_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&buffer);

    // Get interface pointer
    const writer: *std.Io.Writer = &stdout_writer.interface;

    const msg = try std.fmt.allocPrint(allocator, fmt, args);
    defer allocator.free(msg);

    try writer.writeAll(msg);
    try writer.flush();
}
```

### Common `std.Io.Writer` Methods

```zig
const writer: *std.Io.Writer = &output_writer.interface;

// Write bytes
try writer.write("Hello");

// Write all bytes
try writer.writeAll("Hello World\n");

// Write byte N times (splatting - O(M) instead of O(M*N))
try writer.writeByteNTimes(0, 1024);

// Print formatted string (requires {f} format specifier)
try writer.print("Hello {s}\n", .{"world"});
```

### Common `std.Io.Reader` Methods

```zig
const reader: *std.Io.Reader = &input_reader.interface;

// Read bytes
const byte = try reader.readByte();

// Read N bytes
var buf: [1024]u8 = undefined;
const n = try reader.read(&buf);

// Read all bytes (with allocator)
const content = try reader.readAllAlloc(allocator, std.math.maxInt(usize));

// Stream until delimiter (to writer)
const len = try reader.streamDelimiterLimit(writer, '\n', .unlimited);

// Read until delimiter (with allocator)
const line = try reader.readUntilDelimiterAlloc(allocator, '\n', std.math.maxInt(usize));

// Peek at buffer without consuming
const peeked = try reader.peek(buf[0..]);
```

### HTTP Routing (zzz)

Using zzz HTTP framework (designed for Zig 0.15.x):

```zig
const Router = http.Router;
const Route = http.Route;

// Create router
var router = try Router.init(allocator, &routes, .{});

// Define route
Route.init("/api/hello").get({}, apiHelloGet).layer();
```

### Error Handling

```zig
// Standard error return
fn myHandler(ctx: *const Context, _: void) !Respond {
    const data = try someOperation(ctx.allocator);
    defer ctx.allocator.free(data);

    return ctx.response.apply(.{
        .status = .OK,
        .mime = http.Mime.JSON,
        .body = data,
    });
}
```

### Resource Management

```zig
// Always use defer for cleanup
fn processFile(allocator: std.mem.Allocator) !void {
    const file = try std.fs.cwd().openFile("data.txt", .{});
    defer file.close();  // Auto-close when function returns

    const data = try file.readToEndAlloc(allocator, 1024);
    defer allocator.free(data);  // Auto-free when function returns

    // Process data...
}
```

## Performance Data (from Writergate Benchmarks)

The writergate changes provide significant performance improvements:

| Benchmark | Wall Time | Peak RSS | CPU Cycles | Instructions |
|------------|-------------|-----------|-------------|---------------|
| **Building Self-Hosted Compiler** |
| vs Master | -14.6% | +10.8% | -9.6% | -7.8% |
| **Building Music Player Project** |
| vs Master | +12.4% | +0.3% | +12.5% | +6.8% |
| **Building Hello World (ReleaseFast)** |
| vs Master | -22.4% | -0.8% | -21.5% | -23.3% |
| **Building Hello World (Debug)** |
| vs Master | -6.3% | -0.1% | -18.5% | -18.2% |

**Key Insights:**
- **ReleaseFast**: Significant wall time improvements (up to 22% faster)
- **Debug**: Reduced CPU cycles and instructions
- **Cache Performance**: Better cache hit rates (14-22% fewer cache misses)
- **Binary Size**: Small reduction (2-4% smaller)

**Note:** Some benchmarks show increased peak RSS (memory usage) in certain scenarios, but overall performance is improved.

## Best Practices for Zig 0.15.x

### 1. Use New I/O Interfaces

```zig
// Use std.Io.Reader and std.Io.Writer (concrete)
const file = try std.fs.cwd().openFile("data.txt", .{});
defer file.close();

var buffer: [1024]u8 = undefined;
const reader = file.reader(&buffer);
const writer = file.writer(&buffer);

// Always flush writers
try writer.writeAll("data");
try writer.flush();
```

### 2. Use {f} for Format Methods

```zig
// Format methods now require explicit {f}
pub fn format(foo: Foo, writer: *std.io.Writer) std.io.Writer.Error!void { ... }

// Call with {f}
std.debug.print("{f}", .{foo_instance});

// Or skip formatting with {any}
std.debug.print("{any}", .{foo_instance});
```

### 3. Leverage Buffer in Interface

```zig
// You provide the buffer, implementation decides minimum size
var buffer: [4096]u8 = undefined;
const stdout_writer = std.fs.File.stdout().writer(&buffer);
const stdout = &stdout_writer.interface;

try stdout.print("Hello, World!\n", .{});
try stdout.flush();
```

### 4. Use Precise Error Sets

```zig
// Define specific, actionable errors
const IOError = error{
    FileNotFound,
    PermissionDenied,
    InvalidFormat,
};

fn readFile(path: []const u8) ![]const u8 {
    // Return specific errors, not anyerror
}

// Handle specific errors
const content = readFile("data.txt") catch |err| switch (err) {
    error.FileNotFound => return default_content,
    else => return err,
};
```

### 5. Use New I/O Concepts

```zig
// Splatting for efficient writes
try writer.writeByteNTimes(0, 1024); // Efficient zero-fill

// Direct file operations (uses syscalls when available)
try std.fs.copyFile("source.txt", "dest.txt", .{});

// Read until delimiter (more efficient than manual loops)
const line = try reader.readUntilDelimiterAlloc(allocator, '\n', 1024);
defer allocator.free(line);
```

### 6. Follow Error Union Conventions

```zig
// Use !T for error unions
fn returnsError() !void { }
fn returnsValue() ![]const u8 { }

// Handle errors with try
const value = try returnsError();

// Handle errors with catch
const value = returnsError() catch |err| {
    // Handle error
    return default_value;
};
```

### 7. Consistent Resource Management

```zig
// Always pair allocations with free
const data = try allocator.alloc(u8, size);
defer allocator.free(data);

// Always close resources
const file = try std.fs.cwd().openFile(path, .{});
defer file.close();

// Always flush writers
try writer.writeAll("data");
try writer.flush();
```

## Migration from Older Zig Versions

If you're coming from Zig 0.14.x or earlier:

### 1. Enable Reference Tracing

```bash
# Turn on reference tracing to find format string breakage
zig build -freference-trace
```

### 2. Forget Old I/O APIs, Use New Pattern

**Old (Forget This):**
```zig
const reader = file.reader();
const writer = file.writer();
try writer.print("{}", .{value});
```

**New (Use This Pattern):**
```zig
var buffer: [4096]u8 = undefined;
const output_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&buffer);
const writer: *std.Io.Writer = &output_writer.interface;

try writer.writeAll("Hello world\n");
try writer.flush();
```

### 3. Fix Format String Calls

**Old (Breaking):**
```zig
std.debug.print("{}", .{foo_instance});
```

**New:**
```zig
// Use {f} for format methods, {any} to skip
std.debug.print("{f}", .{foo_instance});
// Or
std.debug.print("{any}", .{foo_instance});
```

### 4. Update Function Names

**Old → New:**
- `std.fmt.fmtSliceEscapeLower` → `std.ascii.hexEscape`
- `std.zig.fmtEscapes` → `std.zig.fmtString`
- `std.fmt.fmtIntSizeDec` → `{B}` format specifier
- `std.fmt.fmtIntSizeBin` → `{Bi}` format specifier
- `std.fmt.fmtDuration` → `{D}` format specifier

### 5. Update ArrayList Usage

**Old:**
```zig
const findings = std.ArrayList(Finding).init(allocator);
try findings.append(finding);
```

**New (Unmanaged - More Idiomatic):**
```zig
const AnalysisResult = struct {
    findings: std.ArrayListUnmanaged(Finding),

    fn init() AnalysisResult {
        return .{
            .findings = .{},  // Empty initialization
        };
    }

    fn addFinding(self: *AnalysisResult, allocator: std.mem.Allocator, finding: Finding) !void {
        try self.findings.append(allocator, finding);
    }
};
```

**Or New (Store Allocator - Familiar Pattern):**
```zig
const AnalysisResult = struct {
    findings: std.ArrayList(Finding),
    allocator: std.mem.Allocator,

    fn init(allocator: std.mem.Allocator) AnalysisResult {
        return .{
            .findings = std.ArrayList(Finding).init(allocator),
            .allocator = allocator,
        };
    }

    fn addFinding(self: *AnalysisResult, finding: Finding) !void {
        try self.findings.append(self.allocator, finding);
    }
};
```

### 6. Update Process Child API

**Old:**
```zig
if (result.term.Exited != 0) {
    return error.Failed;
}
```

**New:**
```zig
switch (result.term) {
    .Exited => |code| {
        if (code != 0) {
            return error.Failed;
        }
    },
    else => return error.ProcessFailed,
}
```

### 7. Initialize Variables Explicitly

**Old (No Longer Allowed):**
```zig
var line_num: usize = undefined;
while (condition) : (line_num += 1) {  // ERROR
}
```

**New:**
```zig
var line_num: usize = 1;
while (condition) : (line_num += 1) {
}
```

### 2. Update I/O Code

```zig
// Old: Generic Reader/Writer
const reader = file.reader();
const writer = file.writer();

// New: Use adaptToNewApi() for migration
var adapter = old_reader.adaptToNewApi();
const r: *std.io.Reader = &adapter.new_interface;
```

### 3. Fix Format String Calls

```zig
// Old: {} calls format method
std.debug.print("{}", .{foo_instance});

// New: Use {f} for format methods, {any} to skip
std.debug.print("{f}", .{foo_instance});
```

### 4. Update Function Names

```zig
// Old format functions
const escaped = std.fmt.fmtSliceEscapeLower(data);

// New: Use format specifiers or renamed functions
const escaped = std.ascii.hexEscape(data);
// Or use: "{x}", .{data}
```

### 5. Update File Operations

```zig
// Old: reader() and writer()
const reader = file.reader();
const writer = file.writer();

// New: Use deprecatedReader() temporarily, migrate to new APIs
const reader = file.deprecatedReader();
const writer = file.deprecatedWriter();
```

### 6. Check for Deprecated APIs

Use the migration helper for old streams:
```zig
fn migrate(old_stream: anytype) !void {
    var adapter = old_stream.adaptToNewApi();
    const new_stream: *std.io.Writer = &adapter.new_interface;
    // Use new_stream...
}
```

## Resources

### Official Documentation

- [Zig 0.15.0 Release Notes](https://ziglang.org/download/0.15.0/release-notes.html)
- [Zig Standard Library Docs](https://ziglang.org/documentation/master/std/)
- [Zig Language Reference](https://ziglang.org/documentation/master/)

### Framework Documentation

- [zzz HTTP Framework](https://github.com/tardy-org/zzz)
- [mustache-zig](https://github.com/batiati/mustache-zig)
- [zuckdb](https://github.com/mitchellh/zuckdb) (if available)

### Community Resources

- [Zig Community Discord](https://ziglang.org/discord)
- [Zig subreddit](https://reddit.com/r/zig)
- [Zig Awesome List](https://github.com/ziglang/awesome-zig)

## Troubleshooting

### Build Errors Related to Writergate

If you see errors about deprecated std modules or APIs:

1. **Check Zig version:**
   ```bash
   zig version
   ```
   Should be `0.15.0` or later

2. **Update devenv:**
   ```bash
   devenv shell
   ```
   This ensures correct version is active

3. **Clear Zig cache:**
   ```bash
   rm -rf backend/.zig-cache
   ```

4. **Rebuild:**
   ```bash
   cd backend
   zig build
   ```

### Common Writergate Errors and Fixes

#### Error: "expected type '*std.io.Writer', found 'std.fs.File.Writer'"

**Cause:** Trying to pass file writer directly instead of `.interface` pointer

**Fix:**
```zig
// Wrong
try someFunction(file.writer());

// Correct
const file_writer: std.fs.File.Writer = file.writer(&buffer);
const writer: *std.Io.Writer = &file_writer.interface;
try someFunction(writer);
```

#### Error: "no field named 'Exited' in union 'std.process.Child.Term'"

**Cause:** Using old process API structure

**Fix:**
```zig
// Wrong
if (result.term.Exited != 0) { }

// Correct
switch (result.term) {
    .Exited => |code| {
        if (code != 0) { }
    },
    else => { },
}
```

#### Error: "ambiguous format string; specify {f} to call format method"

**Cause:** Not using `{f}` format specifier for custom format methods

**Fix:**
```zig
// Wrong
std.debug.print("{}", .{myTypeInstance});

// Correct - use {f}
std.debug.print("{f}", .{myTypeInstance});

// Or skip formatting - use {any}
std.debug.print("{any}", .{myTypeInstance});
```

#### Error: "missing allocator in ArrayList method call"

**Cause:** Using old `std.ArrayList(T)` pattern without storing allocator

**Fix:**
```zig
// Option 1: Store allocator in struct
const Result = struct {
    list: std.ArrayList(Item),
    allocator: std.mem.Allocator,
};

fn init(alloc: std.mem.Allocator) Result {
    return .{
        .list = std.ArrayList(Item).init(alloc),
        .allocator = alloc,
    };
}

fn add(self: *Result, item: Item) !void {
    try self.list.append(self.allocator, item);  // Pass allocator
}

// Option 2: Use unmanaged variant
const Result = struct {
    list: std.ArrayListUnmanaged(Item),
};

fn init() Result {
    return .{
        .list = .{},
    };
}

fn add(self: *Result, allocator: std.mem.Allocator, item: Item) !void {
    try self.list.append(allocator, item);  // Pass allocator
}
```

#### Error: "undefined used in arithmetic"

**Cause:** Zig 0.15 tightened undefined behavior rules

**Fix:**
```zig
// Wrong
var line_num: usize = undefined;
while (condition) : (line_num += 1) {  // ERROR
}

// Correct
var line_num: usize = 1;
while (condition) : (line_num += 1) {
}
```

### Async Runtime Issues

If async code isn't working correctly:

1. **Verify Tardy runtime is initialized:**
   ```zig
   var t = try Tardy.init(allocator, .{ .threading = .auto });
   defer t.deinit();
   ```

2. **Check async operations use runtime:**
   ```zig
   fn asyncOperation(rt: *Runtime) !void {
       const result = try someAsyncCall(rt);
   }
   ```

3. **Ensure proper error handling:** Use `!` syntax correctly

### HTTP/Network Issues

If HTTP operations fail:

1. **Check std.http API usage** - Use zzz framework instead (it's stable for 0.15.x)
2. **Ensure proper resource cleanup:** Use `defer` consistently
3. **Verify allocator is correctly passed** to all operations

### I/O Buffer Issues

If reading/writing operations fail:

1. **Ensure buffer is large enough** for operations
2. **Check `.interface` pointer pattern:** `const writer: *std.Io.Writer = &file_writer.interface;`
3. **Flush writers after writes:** `try writer.flush();`
4. **Use correct read/write methods:** `writeAll()`, `streamDelimiter()`, etc.

### Format/Printing Issues

If formatted output doesn't work:

1. **Use `{f}` for format methods:** `print("{f}", .{value})`
2. **Use `{any}` to skip formatting:** `print("{any}", .{value})`
3. **Allocate buffer for stdout/stderr:**
   ```zig
   var buffer: [4096]u8 = undefined;
   var stdout_writer: std.fs.File.Writer = std.fs.File.stdout().writer(&buffer);
   const stdout: *std.Io.Writer = &stdout_writer.interface;
   try stdout.print("...", .{...});
   try stdout.flush();
   ```
4. Check error handling for HTTP operations

## Summary

Zig 0.15.x with writergate provides:

✅ Better I/O performance (up to 22% faster in release builds)
✅ Concrete I/O interfaces with `.interface` pointer pattern
✅ Precise error sets with actionable meaning
✅ New I/O concepts: splatting, peek, direct file-to-file
✅ Better undefined behavior detection (catches bugs earlier)

### The One Pattern to Remember

**Forget old std.io APIs. Use this pattern:**

```zig
var buffer: [4096]u8 = undefined;
const file_writer: std.fs.File.Writer = file.writer(&buffer);
const writer: *std.Io.Writer = &file_writer.interface;

try writer.writeAll("data");
try writer.flush();
```

### Key Takeaways

1. **Always get `.interface` pointer** before using I/O methods
2. **Use buffered I/O** for many small writes/reads (performance)
3. **Pass allocator explicitly** to ArrayList methods (or use unmanaged variant)
4. **Use `{f}` format specifier** for custom format methods
5. **Handle process termination** with switch on tagged union
6. **Initialize variables** explicitly (no undefined in arithmetic)

### When to Use zzz HTTP Framework

Instead of `std.http.Client` (still evolving rapidly), this project uses:

- **zzz HTTP framework**: Stable, designed for 0.15.x
- **Tardy runtime**: Efficient async model
- **Clean routing API**: Easy to define and manage routes

### Performance vs. Trade-offs

**Better:**
- Wall time: Up to 22% faster (ReleaseFast)
- CPU cycles: Up to 18% reduction
- Instructions: Up to 23% reduction
- Cache performance: Fewer misses

**Trade-offs:**
- Peak RSS: Slightly higher in some benchmarks (+10%)
- API: More explicit (pass allocator everywhere)
- Complexity: New patterns to learn

**Verdict:** The performance and correctness improvements outweigh the learning curve.

---

**Last Updated:** 2026-02-12
**Zig Version:** 0.15.0
**Writergate Status:** Production-ready (included in 0.15.0)
**Key Pattern:** `.interface` pointer with `writeX()` / `streamX()` methods
