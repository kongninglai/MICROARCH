#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG="${1:-}"

ROOT="$HOME/MICROARCH/project/hvl/"
RESULTS="$HOME/MICROARCH/project/scripts/regression/sim_results.txt"
TMP_RESULTS="$(mktemp -d)"

MAX_JOBS=100

: > "$RESULTS"
./clean_sim.sh

pids=()

wait_for_slot() {
  while (( $(jobs -rp | wc -l) >= MAX_JOBS )); do
    sleep 0.1
  done
}

run_one_sim() {
  leaf_dir="$1"
  tb_name=$(basename "$leaf_dir")
  simdir="$leaf_dir/sim"
  out="$TMP_RESULTS/$tb_name.result"

  echo "[$tb_name] Running..."
  (
    mkdir -p "$simdir"
    cd "$simdir"

    find . -mindepth 1 -delete

    if ! vcs -full64 -v2005 -debug_all -f ../master* > build.log 2>&1; then
      printf "%-30s COMPILE_ERROR\n" "$tb_name" > "$out"
      echo "Compile failed in $tb_name"
      exit 0
    fi

    if ! ./simv > sim.log 2>&1; then
      printf "%-30s SIM_ERROR\n" "$tb_name" > "$out"
      echo "Simulation failed in $tb_name"
      exit 0
    fi

    failures=$(grep -Eo 'FAILURES *= *[0-9]+' sim.log | awk '{print $NF}')
    successes=$(grep -Eo 'SUCCESSES *= *[0-9]+' sim.log | awk '{print $NF}')

    failures=${failures:-999}
    successes=${successes:-0}

    if grep -qF "Timing violation" sim.log; then
        failures=$((failures + 1))
    fi

    printf "%-30s FAILURES=%-6s SUCCESSES=%-6s\n" \
      "$tb_name" "$failures" "$successes" > "$out"

    echo "Done"
  ) 2>&1 | sed "s/^/[$tb_name] /"
}

export -f run_one_sim
export TMP_RESULTS

while read -r leaf_dir; do
  wait_for_slot
  run_one_sim "$leaf_dir" &
  pids+=($!)
done < <(
  find "$ROOT" -type d -links 2 -not -empty
)

for pid in "${pids[@]}"; do
  wait "$pid"
done

cat "$TMP_RESULTS"/* >> "$RESULTS"
rm -rf "$TMP_RESULTS"

if [[ -n "$COMMIT_MSG" ]]; then
  if grep -qE 'FAILURES=[^0]|COMPILE_ERROR|SIM_ERROR' "$RESULTS"; then
    echo "Not committing: some tests failed"
    exit 1
  fi

  echo "All tests passed — committing and pushing"
  git add "$HOME/MICROARCH/"
  git commit -m "$COMMIT_MSG"
  git push
else
  if grep -qE 'FAILURES=[^0]|COMPILE_ERROR|SIM_ERROR' "$RESULTS"; then
    echo "Some tests failed"
    exit 1
  fi
  echo "All tests passed"
fi
