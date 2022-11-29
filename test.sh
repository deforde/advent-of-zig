#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(realpath ${0%/*})
cd $SCRIPT_DIR

find src -name "problem_*.zig" | awk '{printf("%s:\n", $0); system("zig test "$0); printf("\n")}'
