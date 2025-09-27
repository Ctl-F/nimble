const tokenizer = @import("token.zig");
const std = @import("std");

const testing = std.testing;
test "Tokenizer_Tokenize_Keyword" {
    try test_tokenize(false, "if else while for inline false true", &tokenizer.TokenType{
        .If, .Else, .While, .For, .Inline, .False, .True,
    });
}

test "Tokenizer_Tokenize_Integer" {
    try test_tokenize(false, "100 200 300 1 0", &tokenizer.TokenType{
        .ImmediateInteger, .ImmediateInteger, .ImmediateInteger, .ImmediateInteger, .ImmediateInteger,
    });
}

test "Tokenizer_Tokenize_Hex" {
    try test_tokenize(false, "0xDEADBEEF 0xFAFB", &tokenizer.TokenType{
        .ImmediateInteger, .ImmediateInteger,
    });
}

test "Tokenizer_Tokenize_Binary" {
    try test_tokenize(false, "0b110110110 0b001001001", &tokenizer.TokenType{
        .ImmediateInteger, .ImmediateInteger,
    });
}

test "Tokenizer_Tokenize_Float" {
    try test_tokenize(false, "100.0 3.14 .1234", &tokenizer.TokenType{
        .ImmediateFloat, .immediateFloat, .immediateFloat,
    });
}

test "Tokenizer_Tokenize_String" {
    try test_tokenize(false, "\"Hello\\n\\tWorld\"", &tokenizer.TokenType{.ImmediateString});
}

test "Tokenizer_Tokenize_MultiString" {
    try test_tokenize(false, "\"Hello \\\nWorld\"", &tokenizer.TokenType{.ImmediateString});
}

test "Tokenizer_Tokenize_UnclosedString" {
    try test_tokenize(true, "\"Hello World", .UnclosedStringLiteral);
}

test "Tokenizer_Tokenize_Char" {
    try test_tokenize(false, "'A' '\\0' '\\n'", &.{ .ImmediateChar, .ImmediateChar, .ImmediateChar });
}

test "Tokenizer_Tokenize_MultiChar" {
    try test_tokenize(false, "'\\\n'", &.{.ImmediateChar});
}

test "Tokenizer_Tokenize_UnclosedChar" {
    try test_tokenize(true, "'a", .UnclosedCharLiteral);
}

test "Tokenizer_Tokenize_InvalidEscape" {
    try test_tokenize(true, "\"Hello \\z\"", .InvalidEscapeCharacter);
}

test "Tokenizer_Tokenize_LongChar" {
    try test_tokenize(true, "'abc'", .InvalidCharLiteral);
}

test "Tokenizer_Tokenize_Operator" {
    try test_tokenize(false, "+ - >> << >= ~", &tokenizer.TokenType{ .Plus, .Minus, .RShift, .LShift, .GreaterThanOrEquals, .Tilde });
}

test "Tokenizer_Tokenize_Expression" {
    try test_tokenize(false, "x = 100 + foo(bar, baz, 10);", &tokenizer.TokenType{
        .Identifier,
        .Equals,
        .ImmediateInteger,
        .Add,
        .Identifier,
        .LParenth,
        .Identifier,
        .Comma,
        .Identifier,
        .Comma,
        .ImmediateInteger,
        .RParenth,
        .Semicolon,
    });
}

test "Tokenizer_Tokenize_Empty" {
    var _tokenizer = tokenizer.Tokenizer.init("", "testing");
    try std.testing.expectEqual(_tokenizer.next().?.type, .EOF);
}

test "Tokenizer_Tokenize_Whitespace" {
    var _tokenizer = tokenizer.Tokenizer.init("     \n        \n  \t     \n \n\n", "testing");
    try std.testing.expectEqual(_tokenizer.next().?.type, .EOF);
    try std.testing.expectEqual(_tokenizer.calculate_line(), 6);
}

test "Tokenizer_Tokenize_Comment" {
    try test_tokenize(false, "//Hello world", &.{.Comment});
}

fn test_tokenize(comptime expect_error: bool, input: []const u8, expected: if (expect_error) tokenizer.TokenError else []const tokenizer.TokenType) !void {
    var _tokenizer = tokenizer.Tokenizer.init(input, "testing");
    var expected_offset: usize = 0;

    while (_tokenizer.next()) |token| : (expected_offset += 1) {
        if (token.type == .EOF) break;
        if (expect_error) {
            switch (token.type) {
                .ERR => |e| {
                    if (e != expected) {
                        return error.UnexpectedErrorReturned;
                    }
                },
                else => return error.ExpectedErrorToken,
            }
        } else {
            if (token.type != expected[expected_offset]) {
                return error.UnexpectedTokenType;
            }
        }
    }
}
