#!/usr/bin/env bash
# Usage: tests/run_tests.sh [--asan] [case-name ...]
#   no case names  -> run every case in tests/cases, plus "errors"
#   case "errors"  -> check the error handling (exit codes)
cd "$(dirname "$0")/.." || exit 1
BIN=./build/hedgehog
if [[ "$1" == "--asan" ]]; then
    BIN=./build/hedgehog_asan
    export ASAN_OPTIONS=detect_leaks=1 UBSAN_OPTIONS=halt_on_error=1
    shift
fi
cases=("$@")
if [[ ${#cases[@]} -eq 0 ]]; then
    for d in tests/cases/*/; do cases+=("$(basename "$d")"); done
    cases+=(errors)
fi
expect_error() {   # description, then the arguments
    local desc="$1"; shift
    local out
    out=$(timeout 10 "$BIN" "$@" 2>/dev/null)
    local rc=$?
    if [[ $rc -ne 1 ]]; then echo "  $desc: expected exit code 1, got $rc"; ok=0;
    elif [[ -n "$out" ]]; then echo "  $desc: error messages must go to stderr, not stdout"; ok=0; fi
}
fail=0
for c in "${cases[@]}"; do
    ok=1
    if [[ "$c" == errors ]]; then
        expect_error "no arguments"
        expect_error "two arguments" tests/cases/03_small/world.txt x
        expect_error "missing file" /nonexistent
        for f in tests/bad/*.txt; do
            expect_error "bad world $(basename "$f")" "$f"
        done
    else
        d="tests/cases/$c"
        [[ -d "$d" ]] || { echo "unknown case $c"; exit 2; }
        timeout 10 "$BIN" "$d/world.txt" > build/out_$c.txt 2> build/err_$c.txt
        rc=$?
        if [[ $rc -eq 124 ]]; then echo "  timeout (more than 10 seconds) - try a faster algorithm"; ok=0
        elif [[ $rc -ne 0 ]]; then echo "  exit code $rc (expected 0)"; sed 's/^/    /' build/err_$c.txt | head -20; ok=0
        elif ! python3 tests/check_path.py "$d/world.txt" build/out_$c.txt "$d/expected_cost"; then ok=0
        fi
    fi
    if [[ $ok -eq 1 ]]; then echo "PASS $c"; else echo "FAIL $c"; fail=1; fi
done
exit $fail
