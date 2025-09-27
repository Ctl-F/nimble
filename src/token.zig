const std = @import("std");

pub const TokenError = enum {
    None,
    UnclosedStringLiteral,
    UnexpectedCharacter,
    InvalidEscapeCharacter,
    UnclosedCharLiteral,
    InvalidCharLiteral,
};

pub const TokenType = union(enum) {
    NONE_TOKEN,
    EOF,
    ERR: TokenError,
    // keywords (alphabetical)
    And,
    Break,
    Catch,
    Const,
    Continue,
    Do,
    Else,
    Enum,
    Error,
    False,
    Fn,
    For,
    If,
    Import,
    Inline,
    Null,
    OrElse,
    Or,
    Struct,
    True,
    Try,
    Undefined,
    Union,
    Unreachable,
    Var,
    While,

    // immediates
    Comment,
    Identifier,
    ImmediateInteger,
    ImmediateFloat,
    ImmediateString,
    ImmediateChar,

    // operators (grouped lexicographically by chars)
    Amp,
    Asterisk,
    MulEquals,
    BackSlash,
    Colon,
    Comma,
    Dot,
    Slice,
    Equals,
    EqualsEquals,
    Exclam,
    NotEquals,
    ForwardSlash,
    DivEquals,
    GreaterThan,
    GreaterThanOrEquals,
    RShift,
    RShiftEquals,
    Hat,
    LBrace,
    LBracket,
    LessThan,
    LessThanOrEquals,
    LShift,
    LShiftEquals,
    LParenth,
    Minus,
    MinusEquals,
    Percent,
    ModEquals,
    Pipe,
    Plus,
    PlusEquals,
    Question,
    RBrace,
    RBracket,
    RParenth,
    Semicolon,
    Tilde,
};

pub const TokenInfo = struct {
    slice: []const u8,
};

pub const Token = struct {
    type: TokenType,
    info: TokenInfo,
};

pub const TokenizerError = error{
    InvalidTokenInStream,
};

pub const Tokenizer = struct {
    original_string: []const u8,
    view: []const u8,
    filename: []const u8,
    last_newline: usize,

    pub fn init(view: []const u8, file: []const u8) @This() {
        return .{
            .original_string = view,
            .view = view,
            .filename = file,
            .last_newline = 0,
        };
    }

    pub fn next(this: *@This()) ?Token {
        if (this.view.len == 0) return null;

        this.skip_whitespace();

        if (this.parse_keyword()) |kw| {
            return kw;
        }

        if (this.parse_operator()) |op| {
            return op;
        }

        if (this.parse_immediate()) |imm| {
            return imm;
        }

        return Token{ .type = .{ .ERR = .UnexpectedCharacter }, .info = .{ .slice = &.{} } };
    }

    fn skip_whitespace(this: *@This()) void {
        const whitespace = " \n\r\t";

        var index: usize = 0;
        while (this.view.len > 0) : (index += 1) {
            if (std.mem.indexOf(u8, whitespace, this.view[index]) == null) {
                break;
            }

            if (this.view[index] == '\n') {
                this.last_newline = @as(usize, @intFromPtr(this.view.ptr)) - @as(usize, @intFromPtr(this.original_string.ptr));
            }
        }
        this.view = this.view[index..];
    }

    const ResultPair = struct { expect: []const u8, result: TokenType };
    fn parse_keyword(this: *@This()) ?Token {
        const Keywords = [_]ResultPair{
            .{ .expect = "and", .result = .And },
            .{ .expect = "break", .result = .Break },
            .{ .expect = "catch", .result = .Catch },
            .{ .expect = "const", .result = .Const },
            .{ .expect = "continue", .result = .Continue },
            .{ .expect = "do", .result = .Do },
            .{ .expect = "else", .result = .Else },
            .{ .expect = "enum", .result = .Enum },
            .{ .expect = "error", .result = .Error },
            .{ .expect = "false", .result = .False },
            .{ .expect = "fn", .result = .Fn },
            .{ .expect = "for", .result = .For },
            .{ .expect = "if", .result = .If },
            .{ .expect = "import", .result = .Import },
            .{ .expect = "inline", .result = .Inline },
            .{ .expect = "null", .result = .Null },
            .{ .expect = "orelse", .result = .OrElse },
            .{ .expect = "or", .result = .Or },
            .{ .expect = "struct", .result = .Struct },
            .{ .expect = "true", .result = .True },
            .{ .expect = "try", .result = .Try },
            .{ .expect = "undefined", .result = .Undefined },
            .{ .expect = "union", .result = .Union },
            .{ .expect = "unreachable", .result = .Unreachable },
            .{ .expect = "var", .result = .Var },
            .{ .expect = "while", .result = .While },
        };

        inline for (Keywords) |kw| {
            if (this.match(kw)) |tok| return tok;
        }

        return null;
    }
    inline fn match(this: *@This(), pair: ResultPair) ?Token {
        if (this.view.len < pair.expect.len) return null;

        const len = pair.expect.len;
        if (std.mem.eql(u8, pair.expect, this.view[0..len])) {
            defer this.column += len;
            return Token{
                .type = pair.result,
                .info = .{
                    .slice = this.view[0..len],
                },
            };
        }
        return null;
    }

    fn parse_operator(this: *@This()) ?Token {
        const Operators = [_]ResultPair{
            .{ .expect = "&", .result = .Amp },
            .{ .expect = "*=", .result = .MulEquals },
            .{ .expect = "*", .result = .Asterisk },
            .{ .expect = "\\", .result = .BackSlash },
            .{ .expect = ":", .result = .Colon },
            .{ .expect = ",", .result = .Comma },
            .{ .expect = "..", .result = .Slice },
            .{ .expect = ".", .result = .Dot },
            .{ .expect = "==", .result = .EqualsEquals },
            .{ .expect = "=", .result = .Equals },
            .{ .expect = "!=", .result = .NotEquals },
            .{ .expect = "!", .result = .Exclam },
            .{ .expect = "/=", .result = .DivEquals },
            .{ .expect = "/", .result = .ForwardSlash },
            .{ .expect = ">=", .result = .GreaterThanOrEquals },
            .{ .expect = ">>=", .result = .RShiftEquals },
            .{ .expect = ">>", .result = .RShift },
            .{ .expect = ">", .result = .GreaterThan },
            .{ .expect = "<=", .result = .LessThanOrEquals },
            .{ .expect = "<<=", .result = .LShiftEquals },
            .{ .expect = "<<", .result = .LShift },
            .{ .expect = "<", .result = .LessThan },
            .{ .expect = "^", .result = .Hat },
            .{ .expect = "[", .result = .LBrace },
            .{ .expect = "{", .result = .LBracket },
            .{ .expect = "(", .result = .LParenth },
            .{ .expect = "]", .result = .RBrace },
            .{ .expect = "}", .result = .RBracket },
            .{ .expect = ")", .result = .RParenth },
            .{ .expect = "-=", .result = .MinusEquals },
            .{ .expect = "-", .result = .Minus },
            .{ .expect = "%=", .result = .ModEquals },
            .{ .expect = "%", .result = .Percent },
            .{ .expect = "|", .result = .Pipe },
            .{ .expect = "+=", .result = .PlusEquals },
            .{ .expect = "+", .result = .Plus },
            .{ .expect = "?", .result = .Question },
            .{ .expect = ";", .result = .Semicolon },
            .{ .expect = "~", .result = .Tilde },
        };

        inline for (Operators) |op| {
            if (this.match(op)) |tok| return tok;
        }

        return null;
    }

    inline fn expect(this: *@This(), constant: []const u8) bool {
        if (this.view.len < constant.len) return false;
        return std.mem.eql(u8, constant, this.view[0..constant.len]);
    }

    fn parse_comment(this: *@This()) ?Token {
        if (!this.expect("//")) return null;

        var index: usize = 2;
        while (index < this.view.len) : (index += 1) {
            if (this.view[index] == '\n') break;
        }

        defer this.view = this.view[index + 1 ..];
        defer this.line += 1;
        defer this.column = 0;

        return Token{
            .type = .Comment,
            .info = .{
                .slice = this.view[0 .. index + 1],
            },
        };
    }

    const Range = struct { min: u8, max: u8 };

    fn parse_identifier(this: *@This()) ?Token {
        const IdentifierRanges = [_]Range{
            .{ .min = 'a', .max = 'z' },
            .{ .min = '_', .max = '_' },
            .{ .min = '0', .max = '9' },
        };
        var validRanges = IdentifierRanges[0..1];
        var index: usize = 0;

        while (index < this.view.len) : (index += 1) {
            for (validRanges) |range| {
                if (range.min <= this.view[index] and this.view[index] <= range.max) {
                    break;
                }
            } else {
                // we haven't found any range that the character fits into so we exit
                break;
            }
            validRanges = &IdentifierRanges;
        }

        if (index == 0) return null;

        defer this.column += index;
        return Token{
            .info = .{
                .slice = this.view[0..index],
            },
            .type = .Identifier,
        };
    }

    fn imm_result_hex(this: *@This(), end: usize) ?Token {
        return Token{
            .info = .{
                .slice = this.view[0..end],
            },
            .type = .ImmediateInteger,
        };
    }
    fn imm_result_bin(this: *@This(), end: usize) ?Token {
        return Token{
            .info = .{
                .slice = this.view[0..end],
            },
            .type = .ImmediateInteger,
        };
    }
    // will return float or int depending on if view[0..end] has a decimal
    fn imm_result_dec(this: *@This(), end: usize) ?Token {
        const slice = this.view[0..end];
        if (std.mem.indexOfScalar(u8, slice, '.')) {
            return Token{
                .info = .{
                    .slice = slice,
                },
                .type = .ImmediateFloat,
            };
        }
        return Token{
            .info = .{
                .slice = slice,
            },
            .type = .ImmediateInteger,
        };
    }

    fn parse_number(this: *@This()) ?Token {
        const NumberType = struct {
            prefix: []const u8,
            allowed: []Range,
            allows_decimal: bool,
            result: fn (this: *Tokenizer, end: usize) ?Token,
        };

        const NumberFormats = [_]NumberType{
            .{
                .prefix = "0x",
                .allowed = &.{
                    Range{ .min = '0', .max = '9' },
                    Range{ .min = 'A', .max = 'F' },
                    Range{ .min = 'a', .max = 'f' },
                },
                .allows_decimal = false,
                .result = imm_result_hex,
            },
            .{
                .prefix = "0X",
                .allowed = &.{
                    Range{ .min = '0', .max = '9' },
                    Range{ .min = 'A', .max = 'F' },
                    Range{ .min = 'a', .max = 'f' },
                },
                .allows_decimal = false,
                .result = imm_result_hex,
            },
            .{
                .prefix = "0b",
                .allowed = &.{
                    Range{ .min = '0', .max = '1' },
                },
                .allows_decimal = false,
                .result = imm_result_bin,
            },
            .{
                .prefix = "0B",
                .allowed = &.{
                    Range{ .min = '0', .max = '1' },
                },
                .allows_decimal = false,
                .result = imm_result_bin,
            },
            .{
                .prefix = "",
                .allowed = &.{
                    Range{ .min = '0', .max = '9' },
                },
                .allows_decimal = true,
                .result = imm_result_dec,
            },
        };

        for (NumberFormats) |fmt| {
            if ((fmt.prefix.len > 0 and this.view.len > fmt.prefix.len and !std.mem.eql(u8, fmt.prefix, this.view[0..fmt.prefix.len]))) {
                continue;
            }
            var start: usize = fmt.prefix.len;
            var has_decimal: bool = false;
            while (start < this.view.len) : (start += 1) {
                if (this.view[start] == '.') {
                    if (fmt.allows_decimal and !has_decimal) {
                        has_decimal = true;
                        continue;
                    }
                    break;
                }

                for (fmt.allowed) |range| {
                    if (range.min <= this.view[start] and this.view[start] <= range.max) {
                        break;
                    }
                } else {
                    break;
                }
            }
            if (start == fmt.prefix.len) {
                continue;
            }

            if (fmt.result(this, start)) |token| {
                return token;
            }
            return null;
        }

        return null;
    }
    const AllowedEscapeCharacters = [_]u8{ 'n', 't', 'r', '\'', '"', '\\', '\n', '0' };
    const EscapeCharacter = '\\';

    fn parse_string(this: *@This()) ?Token {
        const terminalCharacter = '"';

        if (this.view[0] != terminalCharacter) return null;

        var index: usize = 1;

        const errtype: TokenError = ErrorBlock: {
            while (index < this.view.len) : (index += 1) {
                if (this.view[index] == terminalCharacter) {
                    break;
                }

                if (this.view[index] == EscapeCharacter) {
                    index += 1;
                    if (index >= this.view.len) break :ErrorBlock .UnclosedStringLiteral;
                    if (!std.mem.indexOfScalar(u8, AllowedEscapeCharacters, this.view[index])) {
                        break :ErrorBlock .InvalidEscapeCharacter;
                    }

                    if (this.view[index] == '\n') {
                        this.last_newline = (@as(usize, @intFromPtr(this.view.ptr)) + index) - @as(usize, @intFromPtr(this.original_string.ptr));
                    }

                    continue;
                }

                if (this.view[index] == '\n') {
                    break :ErrorBlock .UnclosedStringLiteral;
                }
            } else {
                break :ErrorBlock .UnclosedStringLiteral;
            }

            std.debug.assert(this.view[0] == terminalCharacter and this.view[index] == terminalCharacter);
            index += 1;

            return Token{
                .info = .{
                    .slice = this.view[0..index],
                },
                .type = .ImmediateString,
            };
        };

        return Token{
            .info = .{ .slice = this.view },
            .type = .{ .ERR = errtype },
        };
    }
    fn parse_char(this: *@This()) ?Token {
        const terminalCharacter = '\'';

        if (this.view[0] != terminalCharacter) return null;

        var index: usize = 1;
        var count: usize = 0;
        const errtype: TokenError = ErrorBlock: {
            while (index < this.view.len) : (index += 1) {
                if (this.view[index] == terminalCharacter) {
                    break;
                }
                if (count > 1) {
                    break :ErrorBlock .InvalidCharLiteral;
                }

                if (this.view[index] == EscapeCharacter) {
                    index += 1;
                    if (index >= this.view.len) break :ErrorBlock .UnclosedCharLiteral;
                    if (!std.mem.indexOfScalar(u8, AllowedEscapeCharacters, this.view[index])) {
                        break :ErrorBlock .InvalidEscapeCharacter;
                    }

                    if (this.view[index] == '\n') {
                        this.last_newline = (@as(usize, @intFromPtr(this.view.ptr)) + index) - @as(usize, @intFromPtr(this.original_string.ptr));
                    }

                    count += 1;

                    continue;
                }

                if (this.view[index] == '\n') {
                    break :ErrorBlock .UnclosedCharLiteral;
                }
                count += 1;
            } else {
                break :ErrorBlock .UnclosedCharLiteral;
            }

            std.debug.assert(this.view[0] == terminalCharacter and this.view[index] == terminalCharacter);
            index += 1;

            return Token{
                .info = .{ .slice = this.view[0..index] },
                .type = .ImmediateChar,
            };
        };

        return Token{
            .info = .{ .slice = this.view },
            .type = .{ .ERR = errtype },
        };
    }

    inline fn parse_immediate(this: *@This()) ?Token {
        if (this.parse_comment()) |tok| return tok;
        if (this.parse_identifier()) |tok| return tok;
        if (this.parse_number()) |tok| return tok;
        if (this.parse_string()) |tok| return tok;
        if (this.parse_char()) |tok| return tok;
        return null;
    }

    pub fn calculate_line(this: Tokenizer) usize {
        var line: usize = 1;
        var offset: usize = this.last_newline;

        while (offset > 0) : (offset -= 1) {
            if (this.view[offset] == '\n') {
                line += 1;
            }
        }

        return line;
    }
};
