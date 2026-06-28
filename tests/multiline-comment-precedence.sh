#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample="$tmpdir/sample.c"
output="$tmpdir/output.txt"

cat >"$sample" <<'EOF'
/*
for if NULL
*/ if (value == NULL) return;
EOF

"$repo_dir/nano-colour" "$sample" "$repo_dir/examples" >"$output"

perl -e '
    use strict;
    use warnings;

    my ($output_file) = @ARGV;
    open(my $fh, q{<}, $output_file) or die "Cannot open $output_file: $!";
    my @lines = <$fh>;
    close($fh);

    die "Expected 3 output lines\n" unless @lines == 3;

    my $green = "\e[32m";
    my $magenta = "\e[35m";
    my $yellow = "\e[33m";

    die "Continued comment line was recoloured\n"
        unless $lines[1] =~ /^\e\[0m\Q$green\Efor if NULL\e\[0m\n$/;

    die "Comment end was not green\n"
        unless $lines[2] =~ /^\e\[0m\Q$green\E\*\/\e\[0m /;

    die "Code after comment end was not recoloured\n"
        unless $lines[2] =~ /\Q$magenta\Eif/ && $lines[2] =~ /\Q$yellow\ENULL/;
' "$output"
