# VIMW - Vim but Worse

This is an implementation of a simple text editor in MATLAB, with each character loaded on the screen from a sprite sheet.

The basic navigation is inspired by VIM, and includes two main editing modes: `Normal` and `Insert`.

## Normal Mode

Normal mode is the default mode when the application starts.

`i` - enter insert mode
`I` - move cursor to start of the line an enter insert mode
`a` - enter insert mode to the right of the current char
`A` - enter insert mode at the end of the current line
`o` - create a new line below and enter insert mode on it
`O` - create a new line above and enter insert mode on it
`x` - delete the character under the cursor
`^` - jump to the start of the line
`$` - jump to the end of the line
`gg` - jump to the first line
`13gg` - jump to the 13th line (any number can replace 13)
`G` - jump to the last line
`dd` - delete the current line
`13dd` - delete 13 lines (any number can replace 13)
`h` - move cursor left
`j` - move cursor down
`k` - move cursor up
`l` - move cursor right
(arrow keys may also be used for movement)

`:` - open a command prompt for the later commands

## Insert Mode

Insert mode is the mode used for typing.

`esc` - return to normal mode
`tab` - inserts spaces til 4-byte boundary

## Commands

`:w filename` - writes to a file, sets filename
`:w` - writes to set file, if set
`:vi/:vim/:vimw filename` - opens a file, sets filename
`:q` - quit
`:wq` - write to set file, if set, and quit
`:set layout=random` - randomizes keyboard layout
`:set layout=rot13` - sets keyboard to rot13
`:set layout=default` - sets keyboard layout to default
