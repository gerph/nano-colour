#!/bin/sh
set -eu

repo_dir=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

perl -c "$repo_dir/nano-colour"

for test_script in "$repo_dir"/tests/*.sh; do
    [ "$test_script" = "$repo_dir/tests/run.sh" ] && continue
    "$test_script"
done
