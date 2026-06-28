#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

sample="$tmpdir/sample.c"
output="$tmpdir/output.txt"
html_output="$tmpdir/output.html"
svg_output="$tmpdir/output.svg"

cat >"$sample" <<'EOF'
/*
for if NULL
*/ if (value == NULL) return;
EOF

"$repo_dir/nano-colour" "$sample" "$repo_dir/examples" >"$output"
"$repo_dir/nano-colour" --html "$sample" "$repo_dir/examples" >"$html_output"
"$repo_dir/nano-colour" --svg "$sample" "$repo_dir/examples" >"$svg_output"

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

perl -e '
    use strict;
    use warnings;

    my ($html_file) = @ARGV;
    open(my $fh, q{<}, $html_file) or die "Cannot open $html_file: $!";
    local $/;
    my $html = <$fh>;
    close($fh);

    die "Missing HTML wrapper class\n"
        unless $html =~ /<div class='\''nanocolour nanocolour-c-file'\''>/;

    die "Missing foreground class declaration\n"
        unless $html =~ /\.nanocolour-fg-green \{/;

    die "Missing classed comment span\n"
        unless $html =~ /<span class='\''nanocolour-fg-green'\''>for if NULL<\/span>/;
' "$html_output"

perl -e '
    use strict;
    use warnings;

    my ($svg_file) = @ARGV;
    open(my $fh, q{<}, $svg_file) or die "Cannot open $svg_file: $!";
    local $/;
    my $svg = <$fh>;
    close($fh);

    die "Missing SVG root class\n"
        unless $svg =~ /<svg[^>]*class='\''nanocolour nanocolour-c-file'\''/;

    die "Missing SVG text class\n"
        unless $svg =~ /<tspan class='\''nanocolour-fg-green'\''>for if NULL<\/tspan>/;
' "$svg_output"
