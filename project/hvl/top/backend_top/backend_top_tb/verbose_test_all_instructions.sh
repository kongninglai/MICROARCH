#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TESTCASES_DIR="/home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/testcases"
PROGRAM_TXT="/home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/program.txt"
RESULTS_DIR="/home/ecelrc/students/aak3265/MICROARCH/project/scripts/regression"
RESULTS_FILE="$RESULTS_DIR/regression_results.txt"

mkdir -p "$RESULTS_DIR"

PASS=0
FAIL=0

echo "Regression run: $(date)" > "$RESULTS_FILE"
echo "========================================" >> "$RESULTS_FILE"

# Find all .txt files recursively under testcases
while IFS= read -r -d '' testfile; do
    testname="${testfile#$TESTCASES_DIR/}"

    cp "$testfile" "$PROGRAM_TXT"

    cd "$SCRIPT_DIR"

    # 🔥 SHOW + CAPTURE OUTPUT
    output=$(bash execute_test_case.sh 2>&1 | tee /dev/stderr)

    if echo "$output" | grep -q "PASS: RESULTS MATCH"; then
        echo "PASS: $testname" >> "$RESULTS_FILE"
        PASS=$((PASS + 1))
    else
        echo "FAIL: $testname" >> "$RESULTS_FILE"
        FAIL=$((FAIL + 1))
    fi
done < <(find "$TESTCASES_DIR" -name "*.txt" -print0 | sort -z)

echo "========================================" >> "$RESULTS_FILE"
echo "Total: $((PASS + FAIL))  PASSED: $PASS  FAILED: $FAIL" >> "$RESULTS_FILE"

echo ""
cat "$RESULTS_FILE"