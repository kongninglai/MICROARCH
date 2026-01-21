#!/usr/bin/env bash
set -euo pipefail

COMMIT_MSG="${1:-}"

ROOT="$HOME/MICROARCH/project/hvl/local-lib/"
RESULTS="$HOME/MICROARCH/project/scripts/regression/sim_results.txt"
TMP_RESULTS="$(mktemp -d)"

: > "$RESULTS"

pids=()

run_one_sim() {
  simdir="$1"
  tb_name=$(basename "$(dirname "$simdir")")
  out="$TMP_RESULTS/$tb_name.result"
  echo "[$tb_name] Running..."
  (
    cd "$simdir"

    find . -mindepth 1 -delete

    vcs -full64 -v2005 -debug_all -f ../master* > build.log 2>&1
    ./simv > sim.log 2>&1

    failures=$(grep -Eo 'FAILURES *= *[0-9]+' sim.log | awk '{print $NF}')
    successes=$(grep -Eo 'SUCCESSES *= *[0-9]+' sim.log | awk '{print $NF}')

    failures=${failures:-999}
    successes=${successes:-0}

    printf "%-30s FAILURES=%-6s SUCCESSES=%-6s\n" \
      "$tb_name" "$failures" "$successes" > "$out"
    
    echo "Done"
  ) 2>&1 | sed "s/^/[$tb_name] /"
}

export -f run_one_sim
export TMP_RESULTS

while read -r simdir; do
  run_one_sim "$simdir" &
  pids+=($!)
done < <(find "$ROOT" -type d -name sim)

for pid in "${pids[@]}"; do
  wait "$pid"
done

cat "$TMP_RESULTS"/* >> "$RESULTS"
rm -rf "$TMP_RESULTS"

if [[ -n "$COMMIT_MSG" ]]; then
  if grep -q 'FAILURES=[^0]' "$RESULTS"; then
    echo "Not committing: some tests failed"
    exit 1
  fi

  echo "All tests passed — committing and pushing"
  git add "$HOME/MICROARCH/"
  git commit -m "$COMMIT_MSG"
  git push
else
  if grep -q 'FAILURES=[^0]' "$RESULTS"; then
    echo "Some tests failed"
    exit 1
  fi
  echo "All tests passed"
fi
