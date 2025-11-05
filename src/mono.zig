pub const Domain = opaque {};
pub const Thread = opaque {};
pub const Assembly = opaque {};
pub const AssemblyName = opaque {};
pub const Image = opaque {};
pub const Class = opaque {};

pub const Callback = fn (data: *anyopaque, user_data: ?*anyopaque) callconv(.c) void;

pub const Funcs = struct {
    get_root_domain: *const fn () callconv(.c) ?*Domain,
    thread_attach: *const fn (?*Domain) callconv(.c) ?*Thread,
    // domain_assembly_open: *const fn (*Domain, [*:0]const u8) callconv(.c) ?*Assembly,

    assembly_foreach: *const fn (func: *const Callback, user_data: ?*anyopaque) callconv(.c) void,
    assembly_get_name: *const fn (*Assembly) callconv(.c) ?*AssemblyName,
    assembly_get_image: *const fn (*Assembly) callconv(.c) ?*Image,
    assembly_name_get_name: *const fn (*AssemblyName) callconv(.c) ?[*:0]const u8,

    class_from_name: *const fn (*Image, namespace: [*:0]const u8, name: [*:0]const u8) ?*Class,
    pub fn init(proc_ref: *[:0]const u8, mod: win32.HINSTANCE) error{ProcNotFound}!Funcs {
        return .{
            .get_root_domain = try monoload.get(mod, .get_root_domain, proc_ref),
            .thread_attach = try monoload.get(mod, .thread_attach, proc_ref),
            // .domain_assembly_open = try monoload.get(mod, .domain_assembly_open, proc_ref),
            .assembly_foreach = try monoload.get(mod, .assembly_foreach, proc_ref),
            .assembly_get_name = try monoload.get(mod, .assembly_get_name, proc_ref),
            .assembly_get_image = try monoload.get(mod, .assembly_get_image, proc_ref),
            .assembly_name_get_name = try monoload.get(mod, .assembly_name_get_name, proc_ref),
            .class_from_name = try monoload.get(mod, .class_from_name, proc_ref),
        };
    }
};

const win32 = @import("win32").everything;
const monoload = @import("monoload.zig").template(Funcs);
