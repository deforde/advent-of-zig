#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(realpath ${0%/*})
cd $SCRIPT_DIR

touch problems/problem_$1.txt
touch problems/example_$1.txt
cp src/template src/problem_$1.zig
sed -i "17s/example_01/example_$1/" src/problem_$1.zig
NLINES=$(wc -l src/main.zig)
sed -i "21s/.*/    _ = @import(\"problem_$1.zig\");\n}/" src/main.zig
