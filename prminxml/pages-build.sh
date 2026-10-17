#!/bin/bash
##
# Build an indexed PRM-in-XML manual set in several styles, plus a landing page.
#
# Usage: prminxml-pages-build.sh <index.xml> <site-dir> [<title> [<description>]]
#
# Each style is built into <site-dir>/<style>/html/ and <site-dir>/index.html
# lists them, with a description of each. Run from the repository root with
# riscos-prminxml installed (eg via gerph/riscos-prminxml-action with
# `version: default` and a trivial `files:`, or a local install).
#
# The source index.xml is not changed; a rewritten copy is written beside it
# (so that its relative `input` directory still works) and removed afterwards.

set -e
set -o pipefail

index="$1"
site="$2"
title="${3:-Documentation}"
description="${4:-}"

if [[ -z "$index" || -z "$site" ]] ; then
    echo "Syntax: $0 <index.xml> <site-dir> [<title> [<description>]]" >&2
    exit 1
fi

mkdir -p "$site"
site="$(cd "$site" && pwd -P)"
indexdir="$(cd "$(dirname "$index")" && pwd -P)"
indexname="$(basename "$index")"
tmpindex="$indexdir/.pages-$indexname"
trap 'rm -f "$tmpindex"' EXIT

input="$(xmllint --xpath 'string(/index/dirs/@input)' "$index")"
input="${input:-.}"

extra="large-bullets page-a4"
index_extra="no-edge-index index-no-descriptions-in-print index-include-indexed-header-label"

# name | page-format | css variants | description shown on the landing page
styles=(
  "prm-modern|html5|prm prm-modern body-notosans heading-saira webfont-notosans webfont-saira $extra|Modern style: the PRM layout with contemporary typefaces."
  "prm|html5|prm body-fraunces heading-raleway webfont-fraunces webfont-raleway $extra|RISC OS 3 PRM style: the familiar Programmer's Reference Manual appearance."
  "prm-ro2|html5|prm prm-ro2 body-fraunces heading-raleway webfont-fraunces webfont-raleway $extra|RISC OS 2 PRM style: the earlier, plainer Programmer's Reference Manual appearance."
  "regular|html5|$extra|Simple style for browsers: a plain, readable layout."
  "unstyled|html|$extra|Unstyled: no CSS, for tools and accessibility testing."
)

rows=""
for entry in "${styles[@]}" ; do
    IFS='|' read -r name format variants desc <<< "$entry"
    echo "- Building $name"
    out="$site/$name"
    mkdir -p "$out/logs" "$out/html" "$out/index" "$out/help" "$out/header" "$out/tmp"

    perl -0pe '
        s{<dirs\b[^>]*/>}{<dirs output="'"$out"'/html" index="'"$out"'/index" help="'"$out"'/help" header="'"$out"'/header" input="'"$input"'" temp="'"$out"'/tmp"/>}s;
        s{page-format=(["\x27])[^"\x27]*\1}{page-format="'"$format"'"}g;
        s{page-css-variant=(["\x27])[^"\x27]*\1}{page-css-variant="'"$variants"'"}g;
        s{index-css-variant=(["\x27])[^"\x27]*\1}{index-css-variant="'"$variants $index_extra"'"}g;
    ' "$index" > "$tmpindex"

    ( cd "$indexdir" && riscos-prminxml -f index -L "$out/logs" "$(basename "$tmpindex")" )
    rm -rf "$out/tmp"
    rows+="<li><a href=\"$name/html/index.html\">${desc%%:*}</a>: ${desc#*: }</li>"$'\n'
done

cat > "$site/index.html" <<EOF
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$title</title>
<style>
body { font-family: serif; max-width: 40em; margin: 2em auto; padding: 0 1em; line-height: 1.5; }
h1 { font-family: sans-serif; }
li { margin-bottom: 0.5em; }
</style>
</head>
<body>
<h1>$title</h1>
<p>$description</p>
<p>The documentation is available in the following forms:</p>
<ul>
$rows</ul>
</body>
</html>
EOF
