#!/bin/bash

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTCASES_DIR="/home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/testcases"
PROGRAM_TXT="/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/program.txt"
RESULTS_DIR="/home/ecelrc/students/aak3265/MICROARCH/project/scripts/regression"
RESULTS_FILE="$RESULTS_DIR/regression_results.txt"
LOG_DIR="$RESULTS_DIR/test_logs"
LOCK_FILE="$RESULTS_DIR/.test_all_instructions.lock"
PER_TEST_TIMEOUT_SEC="${PER_TEST_TIMEOUT_SEC:-0}"

mkdir -p "$RESULTS_DIR"
mkdir -p "$LOG_DIR"

if ! [[ "$PER_TEST_TIMEOUT_SEC" =~ ^[0-9]+$ ]]; then
    echo "PER_TEST_TIMEOUT_SEC must be a non-negative integer, got: $PER_TEST_TIMEOUT_SEC" >&2
    exit 1
fi

exec 9>"$LOCK_FILE"
if ! flock -n 9; then
    echo "Another test_all_instructions.sh run is already active." >&2
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

IPC_SUM="0"
IPC_COUNT=0

echo "Regression run: $(date)" > "$RESULTS_FILE"
echo "========================================" >> "$RESULTS_FILE"
echo "Total tests: $TOTAL_TESTS" >> "$RESULTS_FILE"
if [[ "$PER_TEST_TIMEOUT_SEC" -gt 0 ]]; then
    echo "Per-test timeout: ${PER_TEST_TIMEOUT_SEC}s" >> "$RESULTS_FILE"
fi
echo "" >> "$RESULTS_FILE"

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
        timeout "$PER_TEST_TIMEOUT_SEC" bash execute_test_case.sh > "$testlog" 2>&1 || rc=$?
    else
        bash execute_test_case.sh > "$testlog" 2>&1 || rc=$?
    fi

    # Extract IPC from log.
    # Expected line: IPC              = 0.123456
    ipc="$(awk '
        /^IPC[[:space:]]*=/ {
            print $3
        }
    ' "$testlog" | tail -n 1)"

    if [[ -z "$ipc" ]]; then
        ipc="N/A"
    else
        IPC_SUM="$(awk -v a="$IPC_SUM" -v b="$ipc" 'BEGIN { printf "%.12f", a + b }')"
        IPC_COUNT=$((IPC_COUNT + 1))
    fi

    if [[ "$rc" -eq 0 ]] && grep -q "PASS: RESULTS MATCH" "$testlog"; then
        echo "PASS: $testname  IPC=$ipc" >> "$RESULTS_FILE"
        echo "[$INDEX/$TOTAL_TESTS] PASS  IPC=$ipc"
        PASS=$((PASS + 1))
    else
        if [[ "$rc" -eq 124 ]]; then
            echo "FAIL: $testname (TIMEOUT ${PER_TEST_TIMEOUT_SEC}s)  IPC=$ipc" >> "$RESULTS_FILE"
            echo "[$INDEX/$TOTAL_TESTS] FAIL (timeout)  IPC=$ipc"
        elif [[ "$rc" -ne 0 ]]; then
            echo "FAIL: $testname (RC=$rc)  IPC=$ipc" >> "$RESULTS_FILE"
            echo "[$INDEX/$TOTAL_TESTS] FAIL (rc=$rc)  IPC=$ipc"
        else
            echo "FAIL: $testname  IPC=$ipc" >> "$RESULTS_FILE"
            echo "[$INDEX/$TOTAL_TESTS] FAIL  IPC=$ipc"
        fi
        echo "  log: $testlog"
        FAIL=$((FAIL + 1))
    fi
done

if [[ "$IPC_COUNT" -gt 0 ]]; then
    AVG_IPC="$(awk -v sum="$IPC_SUM" -v cnt="$IPC_COUNT" 'BEGIN { printf "%.6f", sum / cnt }')"
else
    AVG_IPC="N/A"
fi

echo "========================================" >> "$RESULTS_FILE"
echo "Total: $((PASS + FAIL))  PASSED: $PASS  FAILED: $FAIL" >> "$RESULTS_FILE"
echo "Average IPC over $IPC_COUNT tests: $AVG_IPC" >> "$RESULTS_FILE"

echo ""
cat "$RESULTS_FILE"