# Agent Guide: nano-colour

This repository provides `nano-colour`, a Perl-based utility that applies syntax highlighting to text files based on `nanorc` definition files. It is designed to bring `nano`-style terminal coloring to the command line and pipelines.

## Core Component: `nano-colour`

The script `nano-colour` is the central tool. It operates by:
1.  **Scanning Syntax Definitions**: It reads `.nanorc` and `nanorc` files from a specified directory (or `$NANOCOLOUR_DIR`).
2.  **Auto-discovery**: It selects the appropriate syntax by checking the target file's:
    -   **Full relative path** against `syntax` regex patterns.
    -   **First line** (shebang or header) against `header` regex patterns.
3.  **Parsing Rules**: It extracts `color` and `icolor` rules, supporting both single-line regexes and multi-line blocks (`start="..." end="..."`).
4.  **Applying Highlighting**: It processes input line-by-line, applying ANSI escape codes to the terminal output.

### Usage
```bash
./nano-colour [options] <file> [nanorc_dir]
```
- `-s, --syntax <name>`: Force a specific syntax definition.
- `--supported`: Check if the file is supported (returns the syntax name and exit code 0 if found).
- `<file>`: The path to the file to highlight (use `-` for STDIN).
- `[nanorc_dir]`: Directory containing `.nanorc` files.

## Nanorc Syntax Highlighting Format

Highlighting is defined in files matching `*.nanorc` or named `nanorc`. The format follows the standard `nano` editor syntax:

### Identification Commands
- `syntax "name" ["fileregex" ...]`: Defines a syntax group. The `fileregex` is matched against the path of the file being processed.
- `header "regex" ...`: Fallback identification if no filename matches. Matched against the first line of the file.
- `comment "string"`: Defines the comment prefix (e.g., `"#"` or `"/*|*/"`).

### Coloring Commands
- `color [bright]fgcolor[,bgcolor] "regex" ...`: Highlights matches with the specified ANSI colors.
- `icolor [bright]fgcolor[,bgcolor] "regex" ...`: Case-insensitive version of `color`.
- `color ... start="start_re" end="end_re"`: Highlights multi-line blocks starting from `start_re` until `end_re`.

### Supported Colors
`black`, `red`, `green`, `yellow`, `blue`, `magenta`, `cyan`, `white`.
The `bright` prefix (e.g., `brightred`) is supported for foreground colors.

## Implementation Notes for Agents
- **Regex Dialect**: `nano-colour` converts standard `nanorc` word boundaries (`\<` and `\>`) to Perl word boundaries (`\b`) during parsing.
- **Rule Precedence**: Rules are applied in the order they appear in the `nanorc` file. Later rules can overwrite the coloring of earlier rules on the same characters.
- **Directory Matching**: The `syntax` regex matches against the path provided to `nano-colour`. Ensure regexes like `(^|/)cmhg/` are handled by providing relative paths.
- **Header Matching**: The tool only reads the first line of the file for `header` detection.
