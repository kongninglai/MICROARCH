#!/bin/bash

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTCASES_DIR="/home/ecelrc/students/var2427/MICROARCH/project/scripts/verification/testcases"
PROGRAM_TXT="/home/ecelrc/students/var2427/MICROARCH/project/scripts/readmemh/program.txt"
RESULTS_DIR="/home/ecelrc/students/var2427/MICROARCH/project/scripts/regression"
RESULTS_FILE="$RESULTS_DIR/regression_results_auto.txt"
LOG_DIR="$RESULTS_DIR/test_logs_auto"
LOCK_FILE="$RESULTS_DIR/.test_all_instructions_auto.lock"
PER_TEST_TIMEOUT_SEC="${PER_TEST_TIMEOUT_SEC:-0}"
SIM_BIN="$SCRIPT_DIR/sim/simv_auto"

mkdir -p "$RESULTS_DIR"
mkdir -p "$LOG_DIR"

if ! [[ "$PER_TEST_TIMEOUT_SEC" =~ ^[0-9]+$ ]]; then
    echo "PER_TEST_TIMEOUT_SEC must be a non-negative integer, got: $PER_TEST_TIMEOUT_SEC" >&2
    exit 1
fi

if [[ ! -x "$SIM_BIN" ]]; then
    echo "Missing simulator binary: $SIM_BIN" >&2
    echo "Build it first from $SCRIPT_DIR/sim using:" >&2
    echo "  /usr/local/packages/synopsys_2022/vcs/T-2022.06/bin/vcs -full64 -v2005 -debug_all -f ../master_pipeline_top_tb -o simv_auto" >&2
    exit 2
fi

# Prevent parallel runs from clobbering shared artifacts (program.txt/results files).
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another test_all_instructions_auto.sh run is already active." >&2
    echo "Stop the existing run or wait for it to finish, then try again." >&2
    exit 1
fi

mapfile -d '' TESTFILES < <(find "$TESTCASES_DIR" -name "*.txt" -print0 | sort -z)
TOTAL_TESTS="${#TESTFILES[@]}"

if [[ "$TOTAL_TESTS" -eq 0 ]]; then
    echo "No testcase files found under $TESTCASES_DIR" >&2
    exit 1
fi

PASS=0
FAIL=0
INDEX=0

echo "Regression run: $(date)" > "$RESULTS_FILE"
echo "========================================" >> "$RESULTS_FILE"
echo "Total tests: $TOTAL_TESTS" >> "$RESULTS_FILE"
if [[ "$PER_TEST_TIMEOUT_SEC" -gt 0 ]]; then
    echo "Per-test timeout: ${PER_TEST_TIMEOUT_SEC}s" >> "$RESULTS_FILE"
fi

echo "Running $TOTAL_TESTS tests from $TESTCASES_DIR"
if [[ "$PER_TEST_TIMEOUT_SEC" -gt 0 ]]; then
    echo "Per-test timeout enabled: ${PER_TEST_TIMEOUT_SEC}s"
fi

for testfile in "${TESTFILES[@]}"; do
    INDEX=$((INDEX + 1))
    testname="${testfile#$TESTCASES_DIR/}"
    safename="${testname//\//_}"
    safename="${safename// /_}"
    testlog="$LOG_DIR/${INDEX}_$safename.log"

    echo "[$INDEX/$TOTAL_TESTS] Running $testname"

    cp "$testfile" "$PROGRAM_TXT"

    cd "$SCRIPT_DIR"
    rc=0
    if [[ "$PER_TEST_TIMEOUT_SEC" -gt 0 ]]; then
        timeout "$PER_TEST_TIMEOUT_SEC" bash execute_test_case_auto.sh > "$testlog" 2>&1 || rc=$?
    else
        bash execute_test_case_auto.sh > "$testlog" 2>&1 || rc=$?
    fi

    if [[ "$rc" -eq 0 ]] && grep -q "PASS: RESULTS MATCH" "$testlog"; then
        echo "PASS: $testname" >> "$RESULTS_FILE"
        echo "[$INDEX/$TOTAL_TESTS] PASS"
        PASS=$((PASS + 1))
    else
        if [[ "$rc" -eq 124 ]]; then
            echo "FAIL: $testname (TIMEOUT ${PER_TEST_TIMEOUT_SEC}s)" >> "$RESULTS_FILE"
            echo "[$INDEX/$TOTAL_TESTS] FAIL (timeout)"
        elif [[ "$rc" -ne 0 ]]; then
            echo "FAIL: $testname (RC=$rc)" >> "$RESULTS_FILE"
            echo "[$INDEX/$TOTAL_TESTS] FAIL (rc=$rc)"
        else
            echo "FAIL: $testname" >> "$RESULTS_FILE"
            echo "[$INDEX/$TOTAL_TESTS] FAIL"
        fi
        echo "  log: $testlog"
        FAIL=$((FAIL + 1))
    fi
done

echo "========================================" >> "$RESULTS_FILE"
echo "Total: $((PASS + FAIL))  PASSED: $PASS  FAILED: $FAIL" >> "$RESULTS_FILE"

echo ""
cat "$RESULTS_FILE"
