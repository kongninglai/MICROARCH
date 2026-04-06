#!/bin/bash
# sim_run.sh — compile + run fetch_decode_top_tb, capture all output
#
# Usage:
#   ./sim_run.sh           — run existing simv (fast; no recompile)
#   ./sim_run.sh --compile  — recompile with VCS, then run
#
# Output:
#   sim/console.log  — full VCS + simulation stdout/stderr
#   sim/fetch_decode_top_tb.log — per-check structured log (written by TB)
#
# Return code:
#   0  if simulation printed 0 FAILURES
#   1  otherwise (compile error, runtime error, or test failures)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SIM_DIR="$SCRIPT_DIR/sim"
MASTER="$SCRIPT_DIR/master_fetch_decode_top_tb"
SIMV="$SIM_DIR/simv"
CONSOLE_LOG="$SIM_DIR/console.log"

VCS=/usr/local/packages/synopsys_2022/vcs/T-2022.06/bin/vcs
VCS_FLAGS="-full64 -v2005 -debug_all"

# ----------------------------------------------------------------
# 1. Compile (only if --compile flag is given)
# ----------------------------------------------------------------
if [[ "${1:-}" == "--compile" ]]; then
    echo "=== Compiling fetch_decode_top_tb ==="
    cd "$SIM_DIR"
    $VCS $VCS_FLAGS -f "$MASTER" -o simv 2>&1 | tee compile.log
    if [[ ! -x "$SIMV" ]]; then
        echo "ERROR: compilation failed — simv not produced" >&2
        exit 1
    fi
    echo "=== Compile OK ==="
fi

if [[ ! -x "$SIMV" ]]; then
    echo "ERROR: $SIMV not found. Run with --compile first." >&2
    exit 1
fi

# ----------------------------------------------------------------
# 2. Run simulation, capture output
# ----------------------------------------------------------------
echo "=== Running simulation ==="
cd "$SIM_DIR"
"$SIMV" 2>&1 | tee "$CONSOLE_LOG"
SIM_EXIT=${PIPESTATUS[0]}

# ----------------------------------------------------------------
# 3. Parse result summary from console output
# ----------------------------------------------------------------
echo ""
echo "=== Result Summary ==="
FAILURES=$(grep -oP "FAILURES = \K[0-9]+" "$CONSOLE_LOG" | tail -1 || echo "?")
SUCCESSES=$(grep -oP "SUCCESSES = \K[0-9]+" "$CONSOLE_LOG" | tail -1 || echo "?")
TIMEOUTS=$(grep -c "\[TIMEOUT\]" "$CONSOLE_LOG" || true)
MISMATCHES=$(grep -c "\[MISMATCH\]" "$CONSOLE_LOG" || true)

echo "  Failures  : $FAILURES"
echo "  Successes : $SUCCESSES"
echo "  Timeouts  : $TIMEOUTS"
echo "  Mismatches: $MISMATCHES"
echo ""
echo "Console log : $CONSOLE_LOG"
echo "Checker log : $SIM_DIR/fetch_decode_top_tb.log"

# ----------------------------------------------------------------
# 4. Exit 0 only if zero failures
# ----------------------------------------------------------------
if [[ "$FAILURES" == "0" ]]; then
    echo "STATUS: PASS"
    exit 0
else
    echo "STATUS: FAIL"
    exit 1
fi
