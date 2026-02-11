const std = @import("std");

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

    pub fn getIndexPath(self: *const Config, allocator: std.mem.Allocator) ![]const u8 {
        return std.fs.path.join(allocator, &.{ self.frontend_dist_path, "index.html" });
    }

    pub fn getViteSvgPath(self: *const Config, allocator: std.mem.Allocator) ![]const u8 {
        return std.fs.path.join(allocator, &.{ self.frontend_dist_path, "vite.svg" });
    }

    pub fn getAssetsPath(self: *const Config, allocator: std.mem.Allocator) ![]const u8 {
        return std.fs.path.join(allocator, &.{ self.frontend_dist_path, "assets" });
    }
};
