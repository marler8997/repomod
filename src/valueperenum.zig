pub fn ValuePerEnum(comptime EnumType: type, comptime T: type) type {
    const enum_fields = @typeInfo(EnumType).@"enum".fields;
    var struct_fields: [enum_fields.len]std.builtin.Type.StructField = undefined;
    for (enum_fields, &struct_fields) |enum_field, *struct_field| {
        struct_field.* = .{
            .name = enum_field.name,
            .type = T,
            .default_value_ptr = null,
            .is_comptime = false,
            .alignment = @alignOf(T),
        };
    }
    return @Type(std.builtin.Type{
        .@"struct" = .{
            .layout = .auto,
            .fields = &struct_fields,
            .decls = &.{},
            .is_tuple = false,
        },
    });
}

const std = @import("std");
