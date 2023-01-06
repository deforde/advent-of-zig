#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR=$(realpath ${0%/*})
cd $SCRIPT_DIR

PROBLEM_SRCS=$(find src -name "problem_*" | sort -r)

rm -rf profile.txt

for PROBLEM_SRC in $PROBLEM_SRCS; do
    printf "%s\n" $PROBLEM_SRC &>> profile.txt

    printf "%s\n" part1 &>> profile.txt
    rm -rf zig-cache
    zig test --test-no-exec --test-filter part1 -O ReleaseFast $PROBLEM_SRC
    find zig-cache -name test | \
    awk '{print $NF}' | \
    xargs time -f "%E" &>> profile.txt

    printf "%s\n" part2 &>> profile.txt
    rm -rf zig-cache
    zig test --test-no-exec --test-filter part2 -O ReleaseFast $PROBLEM_SRC
    find zig-cache -name test | \
    awk '{print $NF}' | \
    xargs time -f "%E" &>> profile.txt
done

awk '/src\/problem_/ { split($0, a, "_"); split(a[2], a, "."); problem = "problem " + a[1]; } /^part/ { part = $0; } /^[0-9]:/ { print problem " " part " " $0; }' profile.txt | sort -r -k3
rm profile.txt
