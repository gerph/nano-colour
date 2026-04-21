# RISC OS nano-colour

This repository provides a Perl-based syntax highlighter that leverages `nanorc` configuration files to provide ANSI-colored output in the terminal.

## Purpose

The primary tool in this repository is `nano-colour`. It was designed to bring `nano`-style syntax highlighting to the command line, allowing you to view highlighted source code directly in your terminal or pipe it to other tools.

## Features

- **Syntax Auto-discovery**: Automatically selects the correct highlighting rules based on the file extension.
- **Support for `nanorc` Syntax**: Parses standard `nanorc` files, supporting:
  - Single-line regex rules (`color`, `icolor`).
  - Multi-line rules (`start="..." end="..."`).
  - Foreground and background color combinations.
  - `bright` color modifiers.
- **Flexible Input**:
  - Highlights files by name.
  - Supports reading from `STDIN` (when syntax is specified).
- **Customizable Syntax Path**: Uses the `NANOCOLOUR_DIR` environment variable to locate highlighting definitions.

## Installation

The `nano-colour` script is a standalone Perl script. Ensure you have Perl installed on your system.

```bash
# Add the script to your path or run it directly
chmod +x nano-colour
```

## Usage

### Basic Usage
To highlight a file, provide the filename and the directory containing `.nanorc` files:

```bash
./nano-colour myfile.pl examples/
```

### Using Environment Variables
You can set `NANOCOLOUR_DIR` to avoid passing the directory every time:

```bash
export NANOCOLOUR_DIR=$(pwd)/examples
./nano-colour myfile.pl
```

### Specifying Syntax Manually
Use the `-s` or `--syntax` option to force a specific highlighting scheme:

```bash
./nano-colour -s perl myfile.txt
```

### Highlighting from STDIN
When a syntax is forced, `nano-colour` can read from standard input:

```bash
cat myfile.pl | ./nano-colour -s perl
```

## Examples

The `examples/` directory contains a variety of `nanorc` definitions for popular formats, including:
- Bash, C, HTML, JavaScript, JSON, Lua, Makefile, Markdown, Perl, Python, XML, YAML, and even `nanorc` itself.

## License

This project is licensed under the MIT License.
