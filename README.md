# advent-of-zig
Advent of code: https://adventofcode.com.

To build and run all solutions and examples:
```
zig build test
```

To build and run all solutions only, in `ReleaseFast` mode, and time the execution thereof:
```
rm -rf zig-cache && \
zig test --test-no-exec --test-filter part -O ReleaseFast src/main.zig && \
find zig-cache -name test | \
awk '{print $NF}' | \
xargs time -f "%E"
```

To time the individual execution durations of all parts, for all problems, in `ReleaseFast` mode, run the `profile.sh` script provided:
```
./profile.sh
```
It will print each problem part in descending order of execution duration for your convenience ;).
