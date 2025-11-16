const Sentinel = enum { no_sentinel, yes_sentinel };

pub const Encoding = enum {
    utf8,
    wtf16,
    pub fn Char(encoding: Encoding) type {
        return switch (encoding) {
            .utf8 => u8,
            .wtf16 => u16,
        };
    }
};

pub fn StringPart(comptime encoding: Encoding) type {
    return union(enum) {
        static: []const encoding.Char(),
        runtime_value: struct { name: [:0]const u8, type: type },
        runtime_utf8: struct { name: [:0]const u8, max_len: usize, max_wtf16: ?usize = null },
        runtime_wtf16: struct { name: [:0]const u8, max_len: usize, max_utf8: ?usize = null },
    };
}

fn maxLen(comptime encoding: Encoding, Type: type) usize {
    switch (@typeInfo(Type)) {
        .int => |info| {
            if (info.bits == 8 and info.signedness == .unsigned) return 3;
            if (info.bits == 16 and info.signedness == .unsigned) return 6;
            if (info.bits == 32 and info.signedness == .unsigned) return 10;
            if (info.bits == 32 and info.signedness == .signed) return 11;
            if (info.bits == 64 and info.signedness == .unsigned) return 20;
        },
        .@"enum" => |info| {
            var max_name: usize = 0;
            for (info.fields) |field| {
                const name_len = switch (encoding) {
                    .utf8 => field.name.len,
                    .wtf16 => std.unicode.wtf8ToWtf16LeStringLiteral(field.name).len,
                };
                max_name = @max(max_name, name_len);
            }
            return max_name;
        },
        else => {},
    }
    @compileError("todo: implement maxLen for type " ++ @typeName(Type));
}

fn FmtArg(comptime Type: type) type {
    switch (@typeInfo(Type)) {
        .int => return Type,
        .@"enum" => return [:0]const u8,
        else => {},
    }
    @compileError("todo: implement FmtArg for type " ++ @typeName(Type));
}
fn fmtArg(comptime Type: type, value: Type) FmtArg(Type) {
    switch (@typeInfo(Type)) {
        .int => return value,
        .@"enum" => return @tagName(value),
        else => {},
    }
    @compileError("todo: implement fmtArg for type " ++ @typeName(Type));
}
fn fmtSpec(comptime Type: type) [:0]const u8 {
    return switch (@typeInfo(Type)) {
        .@"enum" => return "{s}",
        else => "{}",
    };
}

pub fn MaxString(comptime encoding: Encoding, sentinel: Sentinel, comptime parts: []const StringPart(encoding)) type {
    var struct_fields: [parts.len]std.builtin.Type.StructField = undefined;
    var field_count: usize = 0;
    inline for (parts) |part| {
        const maybe_field: ?std.builtin.Type.StructField = switch (part) {
            .static => null,
            .runtime_value => |d| .{
                .name = d.name,
                .type = d.type,
                .default_value_ptr = null,
                .is_comptime = false,
                .alignment = @alignOf(d.type),
            },
            .runtime_utf8 => |d| .{
                .name = d.name,
                .type = []const u8,
                .default_value_ptr = null,
                .is_comptime = false,
                .alignment = @alignOf([]const u8),
            },
            .runtime_wtf16 => |d| .{
                .name = d.name,
                .type = []const u16,
                .default_value_ptr = null,
                .is_comptime = false,
                .alignment = @alignOf([]const u16),
            },
        };
        if (maybe_field) |field| {
            struct_fields[field_count] = field;
            field_count += 1;
        }
    }
    const FormatArgs = @Type(std.builtin.Type{
        .@"struct" = .{
            .layout = .auto,
            .fields = struct_fields[0..field_count],
            .decls = &.{},
            .is_tuple = false,
        },
    });

    return struct {
        pub const max_len = blk: {
            var len: usize = 0;
            for (parts) |part| {
                len += switch (part) {
                    .static => |s| s.len,
                    .runtime_value => |d| maxLen(encoding, d.type),
                    .runtime_utf8 => |d| switch (encoding) {
                        .utf8 => d.max_len,
                        .wtf16 => @panic("todo"),
                    },
                    .runtime_wtf16 => |d| switch (encoding) {
                        .utf8 => @panic("todo"),
                        .wtf16 => d.max_len,
                    },
                };
            }
            break :blk len;
        };

        pub const Formatted = BoundedString(encoding, sentinel, max_len);

        pub fn format(args: FormatArgs) Formatted {
            var result: BoundedString(encoding, sentinel, max_len) = .{
                .buffer = undefined,
                .len = 0,
            };

            var max_possible_len: usize = 0;
            inline for (parts) |part| {
                switch (part) {
                    .static => |s| {
                        @memcpy(result.buffer[result.len..][0..s.len], s);
                        result.len += s.len;
                        max_possible_len += s.len;
                    },
                    .runtime_value => |d| {
                        const dst = result.buffer[result.len..];
                        const max_value_len = comptime maxLen(encoding, d.type);
                        std.debug.assert(dst.len >= max_value_len);
                        switch (encoding) {
                            .utf8 => {
                                const len = (std.fmt.bufPrint(dst, fmtSpec(d.type), .{fmtArg(d.type, @field(args, d.name))}) catch unreachable).len;
                                std.debug.assert(len <= max_value_len);
                                result.len += len;
                            },
                            .wtf16 => {
                                // TODO: we'll need more len if the formatted value contains
                                //       utf8 chars that need more than 1 byte
                                var buf: [max_value_len]u8 = undefined;
                                const len = (std.fmt.bufPrint(&buf, fmtSpec(d.type), .{fmtArg(d.type, @field(args, d.name))}) catch unreachable).len;
                                std.debug.assert(len <= max_value_len);
                                const wtf16_len = std.unicode.wtf8ToWtf16Le(dst, buf[0..len]) catch unreachable;
                                // for now we'll assume all formatted values are made up of 1-byte utf8 chars
                                std.debug.assert(wtf16_len == len);
                                result.len += len;
                            },
                        }
                        max_possible_len += max_value_len;
                    },
                    .runtime_utf8 => |d| switch (encoding) {
                        .utf8 => {
                            const s = @field(args, d.name);
                            std.debug.assert(s.len <= d.max_len);
                            @memcpy(result.buffer[result.len..][0..s.len], s);
                            result.len += s.len;
                            max_possible_len += d.max_len;
                        },
                        .wtf16 => @panic("todo"),
                    },
                    .runtime_wtf16 => |d| switch (encoding) {
                        .utf8 => @panic("todo"),
                        .wtf16 => {
                            const s = @field(args, d.name);
                            std.debug.assert(s.len <= d.max_len);
                            @memcpy(result.buffer[result.len..][0..s.len], s);
                            result.len += s.len;
                            max_possible_len += d.max_len;
                        },
                    },
                }
            }
            std.debug.assert(max_possible_len == max_len);
            switch (sentinel) {
                .no_sentinel => return result,
                .yes_sentinel => {
                    result.buffer[result.len] = 0;
                    return result;
                },
            }
            return result;
        }
    };
}

pub fn BoundedString(comptime encoding: Encoding, comptime sentinel: Sentinel, comptime capacity: usize) type {
    return struct {
        const total_capacity = capacity + switch (sentinel) {
            .no_sentinel => 0,
            .yes_sentinel => 1,
        };
        buffer: [total_capacity]encoding.Char(),
        len: usize,

        const Self = @This();
        pub fn slice(self: *const Self) switch (sentinel) {
            .no_sentinel => []const encoding.Char(),
            .yes_sentinel => [:0]const encoding.Char(),
        } {
            return switch (sentinel) {
                .no_sentinel => self.buffer[0..self.len],
                .yes_sentinel => self.buffer[0..self.len :0],
            };
        }

        pub fn mutableSlice(self: *Self) switch (sentinel) {
            .no_sentinel => []encoding.Char(),
            .yes_sentinel => [:0]encoding.Char(),
        } {
            return switch (sentinel) {
                .no_sentinel => self.buffer[0..self.len],
                .yes_sentinel => self.buffer[0..self.len :0],
            };
        }

        pub fn format(
            self: Self,
            comptime fmt: []const u8,
            options: std.fmt.FormatOptions,
            writer: anytype,
        ) !void {
            _ = fmt;
            _ = options;
            switch (encoding) {
                .utf8 => try writer.writeAll(self.slice()),
                .wtf16 => try writer.print("{}", .{std.unicode.fmtUtf16Le(self.slice())}),
            }
        }
    };
}

const builtin = @import("builtin");
const std = @import("std");
const win32 = @import("win32").everything;

const ValuePerEnum = @import("valueperenum.zig").ValuePerEnum;
