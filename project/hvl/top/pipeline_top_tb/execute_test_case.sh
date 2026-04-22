#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULTS_SCRIPT="$SCRIPT_DIR/results_script.txt"
RESULTS_CMP="$SCRIPT_DIR/results_cmp.txt"
DIFF_OUTPUT="$SCRIPT_DIR/diff_output.txt"
SIM_LOG="$SCRIPT_DIR/sim/simv_run.log"

/usr/bin/python3.11 /home/ecelrc/students/aak3265/MICROARCH/project/scripts/readmemh/readmemh.py
/usr/bin/python3.11 /home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/gen_test_cases.py
/usr/bin/python3.11 /home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/gen_eip_idx_map.py
/usr/bin/python3.11 /home/ecelrc/students/aak3265/MICROARCH/project/scripts/verification/main.py > "$RESULTS_SCRIPT"

rm -f "$RESULTS_CMP" "$DIFF_OUTPUT" "$SIM_LOG"

sim_rc=0
(
    cd "$SCRIPT_DIR/sim"
    ./simv > "$SIM_LOG" 2>&1
) || sim_rc=$?

if [[ "$sim_rc" -ne 0 ]]; then
    echo "FAIL: simv exited with rc=$sim_rc"
    echo "See simulator log: $SIM_LOG"
    exit "$sim_rc"
fi

if grep -q "Timing violation" "$SIM_LOG"; then
    echo "FAIL: Timing violation detected in simulation log"
    echo "See simulator log: $SIM_LOG"
    grep -n "Timing violation" "$SIM_LOG" || true
    exit 4
fi

if [[ ! -f "$RESULTS_CMP" ]]; then
    echo "FAIL: results_cmp.txt was not created by simv"
    echo "See simulator log: $SIM_LOG"
    grep -n "Failed to open results_cmp|TB TIMEOUT|AUTO_CHECKER|Error:" "$SIM_LOG" || true
    exit 2
fi

if [[ ! -s "$RESULTS_CMP" ]]; then
    echo "FAIL: results_cmp.txt is empty"
    echo "See simulator log: $SIM_LOG"
    grep -n "Failed to open results_cmp|TB TIMEOUT|AUTO_CHECKER|Error:" "$SIM_LOG" || true
    exit 3
fi

if diff "$RESULTS_SCRIPT" "$RESULTS_CMP" > "$DIFF_OUTPUT"; then
    echo ""
    echo "PASS: RESULTS MATCH"
    echo ""
else
    echo "FAIL: RESULTS MISMATCH"
    echo "Diff written to: $DIFF_OUTPUT"
    if grep -q "TB TIMEOUT" "$SIM_LOG"; then
        echo "NOTE: Simulator hit TB timeout; results_cmp is truncated."
        grep -n "TB TIMEOUT|run_cycles|accepted_cnt|stalled_cnt" "$SIM_LOG" || true
    fi
    # Keep terminal output manageable while preserving the full diff on disk.
    sed -n '1,200p' "$DIFF_OUTPUT"
fi