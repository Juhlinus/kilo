const std = @import("std");
const c = @cImport({
    @cInclude("ctype.h");
    @cInclude("errno.h");
    @cInclude("stdio.h");
    @cInclude("stdlib.h");
    @cInclude("termios.h");
    @cInclude("unistd.h");
});

var orig_termios: c.termios = undefined;

pub fn enableRawMode() void {
    if (c.tcgetattr(c.STDIN_FILENO, &orig_termios) == -1) die("tcgetattr");
    _ = c.atexit(disableRawMode);

    var raw: c.termios = orig_termios;
    raw.c_iflag &= ~(@as(u16, c.ICRNL) | @as(u16, c.IXON) | @as(u16, c.BRKINT) | @as(u16, c.ISTRIP));
    raw.c_oflag &= ~(@as(u16, c.OPOST));
    raw.c_cflag |= ~(@as(u16, c.CS8));
    raw.c_lflag &= ~(@as(u16, c.ECHO) | @as(u16, c.ICANON) | @as(u16, c.IEXTEN) | @as(u16, c.ISIG));
    raw.c_cc[c.VMIN] = 0;
    raw.c_cc[c.VTIME] = 1;

    if (c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &raw) == 1) die("tcsetattr");
}

pub fn disableRawMode() callconv(.C) void {
    if (c.tcsetattr(c.STDIN_FILENO, c.TCSAFLUSH, &orig_termios) == -1) die("tsetattr");
}

pub fn die(string: [*c]const u8) void {
    c.perror(string);
    c.exit(1);
}

pub fn main() anyerror!void {
    enableRawMode();

    var char: u8 = undefined;

    const stdin = std.io.getStdIn().reader();

    while (true) {
        char = stdin.readByte() catch undefined;
        if (char == 'q') break;
        if (char == -1 and c.errno != c.EAGAIN) die("read");
        if (c.iscntrl(char) == 1) std.debug.print("{}", .{char});
        std.debug.print("c = {}\n\r", .{char});
    }

    std.debug.print("\n", .{});
}
