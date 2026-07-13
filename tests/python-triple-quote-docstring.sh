#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample="$tmpdir/sample.py"
output="$tmpdir/output.txt"
stderr="$tmpdir/stderr.txt"

cat >"$sample" <<'EOF'
#!/usr/bin/env python
def foo():
    """This is a
    docstring."""
    return 1
EOF

# Regression test for the python.nanorc triple-quoted-string rule: the
# start=/end= regex embeds literal double quotes, which must be
# backslash-escaped to parse as a multiline rule at all. Previously this
# fell through to the single-line tokeniser and produced a rule fragment
# that blew up with "Unmatched ( in regex" as soon as any python file was
# processed, regardless of whether it contained a docstring.
"$repo_dir/nano-colour" "$sample" "$repo_dir/examples" >"$output" 2>"$stderr"

if [ -s "$stderr" ]; then
    echo "Unexpected output on stderr:" >&2
    cat "$stderr" >&2
    exit 1
fi

perl -e '
    use strict;
    use warnings;

    my ($output_file) = @ARGV;
    open(my $fh, q{<}, $output_file) or die "Cannot open $output_file: $!";
    my @lines = <$fh>;
    close($fh);

    die "Expected 5 output lines\n" unless @lines == 5;

    my $brightgreen = "\e[1;32m";

    die "Docstring opening line was not coloured brightgreen\n"
        unless $lines[2] =~ /\Q$brightgreen\E"""This is a/;

    die "Docstring closing line was not coloured brightgreen\n"
        unless $lines[3] =~ /\Q$brightgreen\E\s*docstring\."""/;

    die "Code after the docstring was wrongly still coloured as a string\n"
        if $lines[4] =~ /\Q$brightgreen\E/;

    die "Code after the docstring lost its keyword colouring\n"
        unless $lines[4] =~ /return/;
' "$output"
