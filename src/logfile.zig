pub const global = struct {
    pub var write_log_mutex: Mutex = .{};

    const get_log = struct {
        var mutex: Mutex = .{};
        var cached: ?std.fs.File = null;
    };

    pub fn get() struct { std.fs.File, ?OpenLogError } {
        get_log.mutex.lock();
        defer get_log.mutex.unlock();
        if (get_log.cached) |file| return .{ file, null };
        get_log.cached, const err = openLog();
        return .{ get_log.cached.?, err };
    }

    const Name = union(enum) {
        success: []const u16,
        err: NameError,
    };
    const name = struct {
        var mutex: Mutex = .{};
        var cached: ?Name = null;
    };
    pub fn getName() Name {
        name.mutex.lock();
        defer name.mutex.unlock();
        if (name.cached == null) {
            name.cached = if (getname.fromExe(getImagePathName() orelse win32.L(""))) |string|
                .{ .success = string }
            else |err|
                .{ .err = .{ .get_name_error = err } };
        }
        return name.cached.?;
    }
};

pub const NameError = struct {
    get_name_error: getname.Error,
    pub fn format(err: *const NameError, writer: *std.Io.Writer) error{WriteFailed}!void {
        if (builtin.os.tag == .windows) {
            const image_path_name = getImagePathName() orelse win32.L("");
            try writer.print(
                "failed to extract name from PEB image name '{f}' ({s})",
                .{
                    std.unicode.fmtUtf16Le(image_path_name),
                    @as([]const u8, switch (err.get_name_error) {
                        error.Empty => "its empty",
                        error.EndsInSeparator => "it ends with a file separator",
                        error.JustDotExe => "cant be just '.exe'",
                    }),
                },
            );
        }
    }
};

const log_dir_path = if (builtin.os.tag == .windows) "C:\\mutiny" else "/tmp";
const log_file_path = if (builtin.os.tag == .windows) "C:\\mutiny\\log" else "/tmp/mutinylog";

fn openLog() struct { std.fs.File, ?OpenLogError } {
    var first_attempt = true;
    while (true) : (first_attempt = false) {
        const handle = win32.CreateFileW(
            win32.L(log_file_path),
            .{ .FILE_APPEND_DATA = 1 }, // all writes append to end of file
            .{ .READ = 1 },
            null,
            .OPEN_ALWAYS,
            .{ .FILE_ATTRIBUTE_NORMAL = 1 },
            null,
        );
        if (handle != win32.INVALID_HANDLE_VALUE) return .{ .{ .handle = handle }, null };
        const err = win32.GetLastError();
        if (!first_attempt) return .{ std.fs.File.stderr(), .{ .open_error = err } };
        switch (win32.GetLastError()) {
            .ERROR_PATH_NOT_FOUND => {
                if (0 == win32.CreateDirectoryW(win32.L(log_dir_path), null)) return .{
                    std.fs.File.stderr(),
                    .{ .mkdir_error = win32.GetLastError() },
                };
            },
            else => return .{ std.fs.File.stderr(), .{ .open_error = err } },
        }
    }
}

const OpenFileError = if (builtin.os.tag == .windows) win32.WIN32_ERROR else std.fs.File.OpenError;
const MkdirError = if (builtin.os.tag == .windows) win32.WIN32_ERROR else std.fs.Dir.MakeError;

pub const OpenLogError = union(enum) {
    open_error: OpenFileError,
    mkdir_error: MkdirError,
    pub fn format(err: *const OpenLogError, writer: *std.Io.Writer) error{WriteFailed}!void {
        switch (err.*) {
            .open_error => |e| try writer.print("open log file '{s}' failed, error={f}", .{ log_file_path, e }),
            .mkdir_error => |e| try writer.print("mkdir '{s}' for log file, error={f}", .{ log_dir_path, e }),
        }
    }
};

pub fn writeLogPrefix(writer: *std.Io.Writer) error{WriteFailed}!void {
    // const name: []const u16 = blk: {
    //     const p = getImagePathName() orelse break :blk win32.L("?");
    //     break :blk getBasename(p);
    // };
    var time: win32.SYSTEMTIME = undefined;
    win32.GetSystemTime(&time);
    const name: []const u16 = switch (global.getName()) {
        .success => |s| s,
        .err => win32.L("?"),
    };
    try writer.print(
        "{:0>2}:{:0>2}:{:0>2}.{:0>3}|{}|{}|{f}|",
        .{
            time.wHour,
            time.wMinute,
            time.wSecond,
            time.wMilliseconds,
            win32.GetCurrentProcessId(),
            win32.GetCurrentThreadId(),
            std.unicode.fmtUtf16Le(name),
        },
    );
}

fn getImagePathName() ?[]const u16 {
    const str = &std.os.windows.peb().ProcessParameters.ImagePathName;
    if (str.Buffer) |buffer|
        return buffer[0..@divTrunc(str.Length, 2)];
    return null;
}

const builtin = @import("builtin");
const std = @import("std");
const win32 = @import("win32").everything;
const getname = @import("getname.zig");
const Mutex = @import("Mutex.zig");
