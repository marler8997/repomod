pub const Error = error{ Empty, EndsInSeparator, JustDotExe };
pub fn fromExe(exe: []const u16) Error![]const u16 {
    if (exe.len == 0) return error.Empty;
    const basename_start = blk: {
        var i: usize = exe.len;
        while (i > 0) : (i -= 1) switch (exe[i - 1]) {
            '/', '\\' => break :blk i,
            else => {},
        };
        break :blk i;
    };
    if (basename_start == exe.len) return error.EndsInSeparator;
    const basename = exe[basename_start..];
    const name = if (std.mem.endsWith(u16, basename, win32.L(".exe"))) basename[0 .. basename.len - 4] else basename;
    if (name.len == 0) return error.JustDotExe;
    return name;
}

const std = @import("std");
const win32 = @import("win32").everything;
