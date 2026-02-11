const std = @import("std");
const mustache = @import("mustache");

const log = std.log.scoped(.template_cache);

pub const Template = struct {
    allocator: std.mem.Allocator,
    parsed: mustache.Template,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Template {
        const parse_result = try mustache.parseText(allocator, source, .{}, .{ .copy_strings = true });
        return switch (parse_result) {
            .success => |tpl| Template{
                .allocator = allocator,
                .parsed = tpl,
            },
            .parse_error => |detail| {
                log.err(
                    "Mustache parse error {s} at line {d}, col {d}",
                    .{ @errorName(detail.parse_error), detail.lin, detail.col },
                );
                return error.TemplateParseError;
            },
        };
    }

    pub fn deinit(self: *Template) void {
        self.parsed.deinit(self.allocator);
    }

    pub fn render(self: *const Template, data: anytype) ![]const u8 {
        return mustache.allocRender(self.allocator, self.parsed, data);
    }

    pub fn renderWithPartials(self: *const Template, partials: anytype, data: anytype) ![]const u8 {
        return mustache.allocRenderPartials(self.allocator, self.parsed, partials, data);
    }
};

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

    fn openFile(path: []const u8) !std.fs.File {
        return if (std.fs.path.isAbsolute(path))
            try std.fs.openFileAbsolute(path, .{})
        else
            try std.fs.cwd().openFile(path, .{});
    }

    pub fn load(self: *TemplateCache, path: []const u8) ![]u8 {
        const file = try openFile(path);
        defer file.close();

        const end_pos = try file.getEndPos();
        const size = std.math.cast(usize, end_pos) orelse return error.FileTooLarge;
        var content = try self.allocator.alloc(u8, size);
        const read = try file.readAll(content);
        return content[0..read];
    }

    pub fn getOrLoad(self: *TemplateCache, path: []const u8) !*Template {
        if (self.templates.getPtr(path)) |tpl_ptr| return tpl_ptr;

        const source = try self.load(path);
        defer self.allocator.free(source);

        const tpl = try Template.init(self.allocator, source);
        const path_copy = try self.allocator.dupe(u8, path);
        try self.templates.put(path_copy, tpl);

        return self.templates.getPtr(path_copy).?;
    }

    pub fn renderTemplate(self: *TemplateCache, path: []const u8, data: anytype) ![]const u8 {
        const tpl = try self.getOrLoad(path);
        return tpl.render(data);
    }

    pub fn renderTemplateWithPartials(self: *TemplateCache, path: []const u8, partials_map: anytype, data: anytype) ![]const u8 {
        const tpl = try self.getOrLoad(path);
        return tpl.renderWithPartials(partials_map, data);
    }

    pub fn buildPartialsMap(self: *TemplateCache, partial_paths: []const []const u8) !std.StringHashMap(mustache.Template) {
        var map = std.StringHashMap(mustache.Template).init(self.allocator);

        for (partial_paths) |path| {
            const tpl = try self.getOrLoad(path);
            const basename = std.fs.path.basename(path);
            const name = if (std.mem.lastIndexOfScalar(u8, basename, '.')) |dot|
                basename[0..dot]
            else
                basename;
            const name_copy = try self.allocator.dupe(u8, name);
            try map.put(name_copy, tpl.parsed);
        }

        return map;
    }
};
