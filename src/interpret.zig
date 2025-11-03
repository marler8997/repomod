pub fn go(text: []const u8) union(enum) {
    unexpected_token: struct {
        expected: [:0]const u8,
        token: Token,
    },
} {
    std.log.err("TODO: interpret module source '{f}'", .{std.zig.fmtString(text)});
    var offset: usize = 0;
    while (true) {
        const token = lex(text, offset);
        offset = token.loc.end;
        switch (token.tag) {
            .keyword_set => {
                @panic("todo: implement set");
            },
            .keyword_fn => @panic("todo: implement fn"),
            else => return .{ .unexpected_token = .{
                .expected = "set or fn",
                .token = token,
            } },
        }
    }
}

const Token = struct {
    tag: Tag,
    loc: Loc,

    pub const Tag = enum {
        invalid,
        // invalid_periodasterisks,
        identifier,
        string_literal,
        // multiline_string_literal_line,
        // char_literal,
        eof,
        builtin,
        // bang,
        // pipe,
        // pipe_pipe,
        // pipe_equal,
        // equal,
        // equal_equal,
        // equal_angle_bracket_right,
        // bang_equal,
        l_paren,
        r_paren,
        // semicolon,
        // percent,
        // percent_equal,
        l_brace,
        r_brace,
        l_bracket,
        r_bracket,
        period,
        // period_asterisk,
        // ellipsis2,
        // ellipsis3,
        // caret,
        // caret_equal,
        // plus,
        // plus_plus,
        // plus_equal,
        // plus_percent,
        // plus_percent_equal,
        // plus_pipe,
        // plus_pipe_equal,
        // minus,
        // minus_equal,
        // minus_percent,
        // minus_percent_equal,
        // minus_pipe,
        // minus_pipe_equal,
        // asterisk,
        // asterisk_equal,
        // asterisk_asterisk,
        // asterisk_percent,
        // asterisk_percent_equal,
        // asterisk_pipe,
        // asterisk_pipe_equal,
        // arrow,
        // colon,
        // slash,
        // slash_equal,
        comma,
        // ampersand,
        // ampersand_equal,
        // question_mark,
        // angle_bracket_left,
        // angle_bracket_left_equal,
        // angle_bracket_angle_bracket_left,
        // angle_bracket_angle_bracket_left_equal,
        // angle_bracket_angle_bracket_left_pipe,
        // angle_bracket_angle_bracket_left_pipe_equal,
        // angle_bracket_right,
        // angle_bracket_right_equal,
        // angle_bracket_angle_bracket_right,
        // angle_bracket_angle_bracket_right_equal,
        // tilde,
        // number_literal,
        // doc_comment,
        // container_doc_comment,
        keyword_fn,
        keyword_set,
    };
    pub const Loc = struct {
        start: usize,
        end: usize,
    };

    pub const keywords = std.StaticStringMap(Tag).initComptime(.{
        // .{ "and", .keyword_and },
        // .{ "break", .keyword_break },
        // .{ "catch", .keyword_catch },
        // .{ "const", .keyword_const },
        // .{ "continue", .keyword_continue },
        // .{ "defer", .keyword_defer },
        // .{ "else", .keyword_else },
        // .{ "enum", .keyword_enum },
        // .{ "errdefer", .keyword_errdefer },
        // .{ "error", .keyword_error },
        // .{ "export", .keyword_export },
        // .{ "extern", .keyword_extern },
        .{ "fn", .keyword_fn },
        // .{ "for", .keyword_for },
        // .{ "if", .keyword_if },
        // .{ "inline", .keyword_inline },
        // .{ "noalias", .keyword_noalias },
        // .{ "noinline", .keyword_noinline },
        // .{ "nosuspend", .keyword_nosuspend },
        // .{ "opaque", .keyword_opaque },
        // .{ "or", .keyword_or },
        // .{ "orelse", .keyword_orelse },
        // .{ "packed", .keyword_packed },
        // .{ "pub", .keyword_pub },
        // .{ "resume", .keyword_resume },
        // .{ "return", .keyword_return },
        // .{ "linksection", .keyword_linksection },
        .{ "set", .keyword_set },
        // .{ "struct", .keyword_struct },
        // .{ "suspend", .keyword_suspend },
        // .{ "switch", .keyword_switch },
        // .{ "test", .keyword_test },
        // .{ "threadlocal", .keyword_threadlocal },
        // .{ "try", .keyword_try },
        // .{ "union", .keyword_union },
        // .{ "unreachable", .keyword_unreachable },
        // .{ "var", .keyword_var },
        // .{ "volatile", .keyword_volatile },
        // .{ "while", .keyword_while },
    });
    pub fn getKeyword(bytes: []const u8) ?Tag {
        return keywords.get(bytes);
    }
};
fn lex(text: []const u8, lex_start: usize) Token {
    const State = union(enum) {
        start,
        identifier: usize,
        saw_at_sign: usize,
        builtin: usize,
        string_literal: usize,
    };

    var index = lex_start;
    var state: State = .start;

    while (true) {
        if (index >= text.len) return switch (state) {
            .start => .{
                .tag = .eof,
                .loc = .{ .start = index, .end = index },
            },
            .identifier => |start| .{
                .tag = .identifier,
                .loc = .{ .start = start, .end = index },
            },
            .builtin => |start| .{
                .tag = .builtin,
                .loc = .{ .start = start, .end = index },
            },
            .saw_at_sign, .string_literal => |start| .{
                .tag = .invalid,
                .loc = .{ .start = start, .end = index },
            },
        };
        switch (state) {
            .start => {
                // index += 1;
                switch (text[index]) {
                    ' ', '\n', '\t', '\r' => index += 1,
                    '"' => {
                        state = .{ .string_literal = index };
                        index += 1;
                    },
                    'a'...'z', 'A'...'Z', '_' => {
                        state = .{ .identifier = index };
                        index += 1;
                    },
                    '@' => {
                        state = .{ .saw_at_sign = index };
                        index += 1;
                    },
                    // '=' => continue :state .equal,
                    // '!' => continue :state .bang,
                    // '|' => continue :state .pipe,
                    '(' => return .{ .tag = .l_paren, .loc = .{ .start = index, .end = index + 1 } },
                    ')' => return .{ .tag = .r_paren, .loc = .{ .start = index, .end = index + 1 } },
                    '[' => return .{ .tag = .l_bracket, .loc = .{ .start = index, .end = index + 1 } },
                    ']' => return .{ .tag = .r_bracket, .loc = .{ .start = index, .end = index + 1 } },
                    // ';' => {
                    //     result.tag = .semicolon;
                    //     self.index += 1;
                    // },
                    ',' => return .{ .tag = .comma, .loc = .{ .start = index, .end = index + 1 } },
                    // '?' => {
                    //     result.tag = .question_mark;
                    //     self.index += 1;
                    // },
                    // ':' => {
                    //     result.tag = .colon;
                    //     self.index += 1;
                    // },
                    // '%' => continue :state .percent,
                    // '*' => continue :state .asterisk,
                    // '+' => continue :state .plus,
                    // '<' => continue :state .angle_bracket_left,
                    // '>' => continue :state .angle_bracket_right,
                    // '^' => continue :state .caret,
                    // '\\' => {
                    //     result.tag = .multiline_string_literal_line;
                    //     continue :state .backslash;
                    // },
                    '{' => return .{ .tag = .l_brace, .loc = .{ .start = index, .end = index + 1 } },
                    '}' => return .{ .tag = .r_brace, .loc = .{ .start = index, .end = index + 1 } },
                    // '~' => {
                    //     result.tag = .tilde;
                    //     self.index += 1;
                    // },
                    '.' => return .{ .tag = .period, .loc = .{ .start = index, .end = index + 1 } },
                    // '-' => continue :state .minus,
                    // '/' => continue :state .slash,
                    // '&' => continue :state .ampersand,
                    // '0'...'9' => {
                    //     result.tag = .number_literal;
                    //     self.index += 1;
                    //     continue :state .int;
                    // },
                    else => return .{
                        .tag = .invalid,
                        .loc = .{ .start = index, .end = index + 1 },
                    },
                }
            },
            .identifier => |start| {
                switch (text[index]) {
                    'a'...'z', 'A'...'Z', '_', '0'...'9' => index += 1,
                    else => {
                        const string = text[start..index];
                        return .{
                            .tag = Token.getKeyword(string) orelse .identifier,
                            .loc = .{ .start = start, .end = index },
                        };
                    },
                }
            },
            .saw_at_sign => |start| {
                switch (text[index]) {
                    '"' => {
                        @panic("todo");
                        // result.tag = .identifier;
                        // continue :state .string_literal;
                    },
                    'a'...'z', 'A'...'Z', '_' => {
                        state = .{ .builtin = start };
                        index += 1;
                    },
                    else => return .{
                        .tag = .invalid,
                        .loc = .{ .start = start, .end = index },
                    },
                }
            },
            .builtin => |start| switch (text[index]) {
                'a'...'z', 'A'...'Z', '_', '0'...'9' => index += 1,
                else => return .{
                    .tag = .builtin,
                    .loc = .{ .start = start, .end = index },
                },
            },
            .string_literal => |start| {
                switch (text[index]) {
                    '"' => return .{
                        .tag = .string_literal,
                        .loc = .{ .start = start, .end = index + 1 },
                    },
                    '\n' => return .{
                        .tag = .invalid,
                        .loc = .{ .start = start, .end = index },
                    },
                    else => index += 1,
                    // '\\' => continue :state .string_literal_backslash,
                    // '"' => self.index += 1,
                    // 0x01...0x09, 0x0b...0x1f, 0x7f => {
                    //     continue :state .invalid;
                    // },
                    // else => continue :state .string_literal,
                }
            },
        }
    }

    // state: switch (State.start) {
    //     .start => switch (self.buffer[self.index]) {
    //         0 => {
    //             if (self.index == self.buffer.len) {
    //                 return .{
    //                     .tag = .eof,
    //                     .loc = .{
    //                         .start = self.index,
    //                         .end = self.index,
    //                     },
    //                 };
    //             } else {
    //                 continue :state .invalid;
    //             }
    //         },
    //         ' ', '\n', '\t', '\r' => {
    //             self.index += 1;
    //             result.loc.start = self.index;
    //             continue :state .start;
    //         },
    //         '"' => {
    //             result.tag = .string_literal;
    //             continue :state .string_literal;
    //         },
    //         '\'' => {
    //             result.tag = .char_literal;
    //             continue :state .char_literal;
    //         },
    //         'a'...'z', 'A'...'Z', '_' => {
    //             result.tag = .identifier;
    //             continue :state .identifier;
    //         },
    //         '@' => continue :state .saw_at_sign,
    //         '=' => continue :state .equal,
    //         '!' => continue :state .bang,
    //         '|' => continue :state .pipe,
    //         '(' => {
    //             result.tag = .l_paren;
    //             self.index += 1;
    //         },
    //         ')' => {
    //             result.tag = .r_paren;
    //             self.index += 1;
    //         },
    //         '[' => {
    //             result.tag = .l_bracket;
    //             self.index += 1;
    //         },
    //         ']' => {
    //             result.tag = .r_bracket;
    //             self.index += 1;
    //         },
    //         ';' => {
    //             result.tag = .semicolon;
    //             self.index += 1;
    //         },
    //         ',' => {
    //             result.tag = .comma;
    //             self.index += 1;
    //         },
    //         '?' => {
    //             result.tag = .question_mark;
    //             self.index += 1;
    //         },
    //         ':' => {
    //             result.tag = .colon;
    //             self.index += 1;
    //         },
    //         '%' => continue :state .percent,
    //         '*' => continue :state .asterisk,
    //         '+' => continue :state .plus,
    //         '<' => continue :state .angle_bracket_left,
    //         '>' => continue :state .angle_bracket_right,
    //         '^' => continue :state .caret,
    //         '\\' => {
    //             result.tag = .multiline_string_literal_line;
    //             continue :state .backslash;
    //         },
    //         '{' => {
    //             result.tag = .l_brace;
    //             self.index += 1;
    //         },
    //         '}' => {
    //             result.tag = .r_brace;
    //             self.index += 1;
    //         },
    //         '~' => {
    //             result.tag = .tilde;
    //             self.index += 1;
    //         },
    //         '.' => continue :state .period,
    //         '-' => continue :state .minus,
    //         '/' => continue :state .slash,
    //         '&' => continue :state .ampersand,
    //         '0'...'9' => {
    //             result.tag = .number_literal;
    //             self.index += 1;
    //             continue :state .int;
    //         },
    //         else => continue :state .invalid,
    //     },

    //     .expect_newline => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => {
    //                 if (self.index == self.buffer.len) {
    //                     result.tag = .invalid;
    //                 } else {
    //                     continue :state .invalid;
    //                 }
    //             },
    //             '\n' => {
    //                 self.index += 1;
    //                 result.loc.start = self.index;
    //                 continue :state .start;
    //             },
    //             else => continue :state .invalid,
    //         }
    //     },

    //     .invalid => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => if (self.index == self.buffer.len) {
    //                 result.tag = .invalid;
    //             } else {
    //                 continue :state .invalid;
    //             },
    //             '\n' => result.tag = .invalid,
    //             else => continue :state .invalid,
    //         }
    //     },

    //     .saw_at_sign => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0, '\n' => result.tag = .invalid,
    //             '"' => {
    //                 result.tag = .identifier;
    //                 continue :state .string_literal;
    //             },
    //             'a'...'z', 'A'...'Z', '_' => {
    //                 result.tag = .builtin;
    //                 continue :state .builtin;
    //             },
    //             else => continue :state .invalid,
    //         }
    //     },

    //     .ampersand => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .ampersand_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .ampersand,
    //         }
    //     },

    //     .asterisk => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .asterisk_equal;
    //                 self.index += 1;
    //             },
    //             '*' => {
    //                 result.tag = .asterisk_asterisk;
    //                 self.index += 1;
    //             },
    //             '%' => continue :state .asterisk_percent,
    //             '|' => continue :state .asterisk_pipe,
    //             else => result.tag = .asterisk,
    //         }
    //     },

    //     .asterisk_percent => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .asterisk_percent_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .asterisk_percent,
    //         }
    //     },

    //     .asterisk_pipe => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .asterisk_pipe_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .asterisk_pipe,
    //         }
    //     },

    //     .percent => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .percent_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .percent,
    //         }
    //     },

    //     .plus => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .plus_equal;
    //                 self.index += 1;
    //             },
    //             '+' => {
    //                 result.tag = .plus_plus;
    //                 self.index += 1;
    //             },
    //             '%' => continue :state .plus_percent,
    //             '|' => continue :state .plus_pipe,
    //             else => result.tag = .plus,
    //         }
    //     },

    //     .plus_percent => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .plus_percent_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .plus_percent,
    //         }
    //     },

    //     .plus_pipe => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .plus_pipe_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .plus_pipe,
    //         }
    //     },

    //     .caret => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .caret_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .caret,
    //         }
    //     },

    //     .identifier => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :state .identifier,
    //             else => {
    //                 const ident = self.buffer[result.loc.start..self.index];
    //                 if (Token.getKeyword(ident)) |tag| {
    //                     result.tag = tag;
    //                 }
    //             },
    //         }
    //     },
    //     .builtin => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             'a'...'z', 'A'...'Z', '_', '0'...'9' => continue :state .builtin,
    //             else => {},
    //         }
    //     },
    //     .backslash => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => result.tag = .invalid,
    //             '\\' => continue :state .multiline_string_literal_line,
    //             '\n' => result.tag = .invalid,
    //             else => continue :state .invalid,
    //         }
    //     },
    //     .string_literal => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => {
    //                 if (self.index != self.buffer.len) {
    //                     continue :state .invalid;
    //                 } else {
    //                     result.tag = .invalid;
    //                 }
    //             },
    //             '\n' => result.tag = .invalid,
    //             '\\' => continue :state .string_literal_backslash,
    //             '"' => self.index += 1,
    //             0x01...0x09, 0x0b...0x1f, 0x7f => {
    //                 continue :state .invalid;
    //             },
    //             else => continue :state .string_literal,
    //         }
    //     },

    //     .string_literal_backslash => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0, '\n' => result.tag = .invalid,
    //             else => continue :state .string_literal,
    //         }
    //     },

    //     .char_literal => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => {
    //                 if (self.index != self.buffer.len) {
    //                     continue :state .invalid;
    //                 } else {
    //                     result.tag = .invalid;
    //                 }
    //             },
    //             '\n' => result.tag = .invalid,
    //             '\\' => continue :state .char_literal_backslash,
    //             '\'' => self.index += 1,
    //             0x01...0x09, 0x0b...0x1f, 0x7f => {
    //                 continue :state .invalid;
    //             },
    //             else => continue :state .char_literal,
    //         }
    //     },

    //     .char_literal_backslash => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => {
    //                 if (self.index != self.buffer.len) {
    //                     continue :state .invalid;
    //                 } else {
    //                     result.tag = .invalid;
    //                 }
    //             },
    //             '\n' => result.tag = .invalid,
    //             0x01...0x09, 0x0b...0x1f, 0x7f => {
    //                 continue :state .invalid;
    //             },
    //             else => continue :state .char_literal,
    //         }
    //     },

    //     .multiline_string_literal_line => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => if (self.index != self.buffer.len) {
    //                 continue :state .invalid;
    //             },
    //             '\n' => {},
    //             '\r' => if (self.buffer[self.index + 1] != '\n') {
    //                 continue :state .invalid;
    //             },
    //             0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => continue :state .invalid,
    //             else => continue :state .multiline_string_literal_line,
    //         }
    //     },

    //     .bang => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .bang_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .bang,
    //         }
    //     },

    //     .pipe => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .pipe_equal;
    //                 self.index += 1;
    //             },
    //             '|' => {
    //                 result.tag = .pipe_pipe;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .pipe,
    //         }
    //     },

    //     .equal => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .equal_equal;
    //                 self.index += 1;
    //             },
    //             '>' => {
    //                 result.tag = .equal_angle_bracket_right;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .equal,
    //         }
    //     },

    //     .minus => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '>' => {
    //                 result.tag = .arrow;
    //                 self.index += 1;
    //             },
    //             '=' => {
    //                 result.tag = .minus_equal;
    //                 self.index += 1;
    //             },
    //             '%' => continue :state .minus_percent,
    //             '|' => continue :state .minus_pipe,
    //             else => result.tag = .minus,
    //         }
    //     },

    //     .minus_percent => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .minus_percent_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .minus_percent,
    //         }
    //     },
    //     .minus_pipe => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .minus_pipe_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .minus_pipe,
    //         }
    //     },

    //     .angle_bracket_left => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '<' => continue :state .angle_bracket_angle_bracket_left,
    //             '=' => {
    //                 result.tag = .angle_bracket_left_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .angle_bracket_left,
    //         }
    //     },

    //     .angle_bracket_angle_bracket_left => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .angle_bracket_angle_bracket_left_equal;
    //                 self.index += 1;
    //             },
    //             '|' => continue :state .angle_bracket_angle_bracket_left_pipe,
    //             else => result.tag = .angle_bracket_angle_bracket_left,
    //         }
    //     },

    //     .angle_bracket_angle_bracket_left_pipe => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .angle_bracket_angle_bracket_left_pipe_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .angle_bracket_angle_bracket_left_pipe,
    //         }
    //     },

    //     .angle_bracket_right => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '>' => continue :state .angle_bracket_angle_bracket_right,
    //             '=' => {
    //                 result.tag = .angle_bracket_right_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .angle_bracket_right,
    //         }
    //     },

    //     .angle_bracket_angle_bracket_right => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '=' => {
    //                 result.tag = .angle_bracket_angle_bracket_right_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .angle_bracket_angle_bracket_right,
    //         }
    //     },

    //     .period => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '.' => continue :state .period_2,
    //             '*' => continue :state .period_asterisk,
    //             else => result.tag = .period,
    //         }
    //     },

    //     .period_2 => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '.' => {
    //                 result.tag = .ellipsis3;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .ellipsis2,
    //         }
    //     },

    //     .period_asterisk => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '*' => result.tag = .invalid_periodasterisks,
    //             else => result.tag = .period_asterisk,
    //         }
    //     },

    //     .slash => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '/' => continue :state .line_comment_start,
    //             '=' => {
    //                 result.tag = .slash_equal;
    //                 self.index += 1;
    //             },
    //             else => result.tag = .slash,
    //         }
    //     },
    //     .line_comment_start => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => {
    //                 if (self.index != self.buffer.len) {
    //                     continue :state .invalid;
    //                 } else return .{
    //                     .tag = .eof,
    //                     .loc = .{
    //                         .start = self.index,
    //                         .end = self.index,
    //                     },
    //                 };
    //             },
    //             '!' => {
    //                 result.tag = .container_doc_comment;
    //                 continue :state .doc_comment;
    //             },
    //             '\n' => {
    //                 self.index += 1;
    //                 result.loc.start = self.index;
    //                 continue :state .start;
    //             },
    //             '/' => continue :state .doc_comment_start,
    //             '\r' => continue :state .expect_newline,
    //             0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
    //                 continue :state .invalid;
    //             },
    //             else => continue :state .line_comment,
    //         }
    //     },
    //     .doc_comment_start => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0, '\n' => result.tag = .doc_comment,
    //             '\r' => {
    //                 if (self.buffer[self.index + 1] == '\n') {
    //                     result.tag = .doc_comment;
    //                 } else {
    //                     continue :state .invalid;
    //                 }
    //             },
    //             '/' => continue :state .line_comment,
    //             0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
    //                 continue :state .invalid;
    //             },
    //             else => {
    //                 result.tag = .doc_comment;
    //                 continue :state .doc_comment;
    //             },
    //         }
    //     },
    //     .line_comment => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0 => {
    //                 if (self.index != self.buffer.len) {
    //                     continue :state .invalid;
    //                 } else return .{
    //                     .tag = .eof,
    //                     .loc = .{
    //                         .start = self.index,
    //                         .end = self.index,
    //                     },
    //                 };
    //             },
    //             '\n' => {
    //                 self.index += 1;
    //                 result.loc.start = self.index;
    //                 continue :state .start;
    //             },
    //             '\r' => continue :state .expect_newline,
    //             0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
    //                 continue :state .invalid;
    //             },
    //             else => continue :state .line_comment,
    //         }
    //     },
    //     .doc_comment => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             0, '\n' => {},
    //             '\r' => if (self.buffer[self.index + 1] != '\n') {
    //                 continue :state .invalid;
    //             },
    //             0x01...0x09, 0x0b...0x0c, 0x0e...0x1f, 0x7f => {
    //                 continue :state .invalid;
    //             },
    //             else => continue :state .doc_comment,
    //         }
    //     },
    //     .int => switch (self.buffer[self.index]) {
    //         '.' => continue :state .int_period,
    //         '_', 'a'...'d', 'f'...'o', 'q'...'z', 'A'...'D', 'F'...'O', 'Q'...'Z', '0'...'9' => {
    //             self.index += 1;
    //             continue :state .int;
    //         },
    //         'e', 'E', 'p', 'P' => {
    //             continue :state .int_exponent;
    //         },
    //         else => {},
    //     },
    //     .int_exponent => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '-', '+' => {
    //                 self.index += 1;
    //                 continue :state .float;
    //             },
    //             else => continue :state .int,
    //         }
    //     },
    //     .int_period => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '_', 'a'...'d', 'f'...'o', 'q'...'z', 'A'...'D', 'F'...'O', 'Q'...'Z', '0'...'9' => {
    //                 self.index += 1;
    //                 continue :state .float;
    //             },
    //             'e', 'E', 'p', 'P' => {
    //                 continue :state .float_exponent;
    //             },
    //             else => self.index -= 1,
    //         }
    //     },
    //     .float => switch (self.buffer[self.index]) {
    //         '_', 'a'...'d', 'f'...'o', 'q'...'z', 'A'...'D', 'F'...'O', 'Q'...'Z', '0'...'9' => {
    //             self.index += 1;
    //             continue :state .float;
    //         },
    //         'e', 'E', 'p', 'P' => {
    //             continue :state .float_exponent;
    //         },
    //         else => {},
    //     },
    //     .float_exponent => {
    //         self.index += 1;
    //         switch (self.buffer[self.index]) {
    //             '-', '+' => {
    //                 self.index += 1;
    //                 continue :state .float;
    //             },
    //             else => continue :state .float,
    //         }
    //     },
    // }

    // result.loc.end = self.index;
    // return result;
}

const TestToken = struct {
    tag: Token.Tag,
    str: []const u8,
};
fn testLex(text: []const u8, expected_tokens: []const TestToken) !void {
    var expected_index: usize = 0;
    var text_offset: usize = 0;
    while (true) : (expected_index += 1) {
        const token = lex(text, text_offset);
        // const token_str = text[token.loc.start..token.loc.end];
        // std.debug.print("  [{}] '{s}' {}\n", .{ expected_index, token_str, token });
        if (expected_index == expected_tokens.len) {
            try std.testing.expectEqual(.eof, token.tag);
            // if (token.tag != .eof) {
            //     std.debug.print("expected no more tokens but got {t} '{s}'\n", .{ token.tag, token_str });
            //     return error.TextExpectedEqual;
            // }
            break;
        }
        const expected = expected_tokens[expected_index];
        // if (expected.tag != token.tag or !std.mem.eql(u8, expected.str, token_str)) {
        //     std.debug.print(
        //         "expected token {t} '{s}' but got {t} '{s}'\n",
        //         .{ expected.tag, expected.str, token.tag, token_str },
        //     );
        //     return error.TextExpectedEqual;
        // }
        try std.testing.expectEqual(expected.tag, token.tag);
        try std.testing.expectEqualSlices(u8, expected.str, text[token.loc.start..token.loc.end]);
        text_offset = token.loc.end;
    }
}

test "lex" {
    try testLex("", &.{});
    try testLex("hello\n", &.{
        .{ .tag = .identifier, .str = "hello" },
    });
    try testLex(
        \\set cs @LoadAssembly("Assembly-CSharp")
        \\
        \\fn void ExecuteSprintCommand(bool fromServer, string[] args) {
        \\    print("test")
        \\}
        \\
        \\set cmd cs.DebugCommandHandler.ChatCommand(
        \\    "sprint",
        \\    ExecuteSprintCommand,
        \\    null,
        \\    false,
        \\)
        \\
    , &.{
        .{ .tag = .keyword_set, .str = "set" },
        .{ .tag = .identifier, .str = "cs" },
        .{ .tag = .builtin, .str = "@LoadAssembly" },
        .{ .tag = .l_paren, .str = "(" },
        .{ .tag = .string_literal, .str = "\"Assembly-CSharp\"" },
        .{ .tag = .r_paren, .str = ")" },
        .{ .tag = .keyword_fn, .str = "fn" },
        .{ .tag = .identifier, .str = "void" },
        .{ .tag = .identifier, .str = "ExecuteSprintCommand" },
        .{ .tag = .l_paren, .str = "(" },
        .{ .tag = .identifier, .str = "bool" },
        .{ .tag = .identifier, .str = "fromServer" },
        .{ .tag = .comma, .str = "," },
        .{ .tag = .identifier, .str = "string" },
        .{ .tag = .l_bracket, .str = "[" },
        .{ .tag = .r_bracket, .str = "]" },
        .{ .tag = .identifier, .str = "args" },
        .{ .tag = .r_paren, .str = ")" },
        .{ .tag = .l_brace, .str = "{" },
        .{ .tag = .identifier, .str = "print" },
        .{ .tag = .l_paren, .str = "(" },
        .{ .tag = .string_literal, .str = "\"test\"" },
        .{ .tag = .r_paren, .str = ")" },
        .{ .tag = .r_brace, .str = "}" },
        .{ .tag = .keyword_set, .str = "set" },
        .{ .tag = .identifier, .str = "cmd" },
        .{ .tag = .identifier, .str = "cs" },
        .{ .tag = .period, .str = "." },
        .{ .tag = .identifier, .str = "DebugCommandHandler" },
        .{ .tag = .period, .str = "." },
        .{ .tag = .identifier, .str = "ChatCommand" },
        .{ .tag = .l_paren, .str = "(" },
        .{ .tag = .string_literal, .str = "\"sprint\"" },
        .{ .tag = .comma, .str = "," },
        .{ .tag = .identifier, .str = "ExecuteSprintCommand" },
        .{ .tag = .comma, .str = "," },
        .{ .tag = .identifier, .str = "null" },
        .{ .tag = .comma, .str = "," },
        .{ .tag = .identifier, .str = "false" },
        .{ .tag = .comma, .str = "," },
        .{ .tag = .r_paren, .str = ")" },
    });
}

const std = @import("std");
