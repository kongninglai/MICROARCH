#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/MICROARCH/project/hvl/local-lib/"

pids=()

remove_one_sim() {
  simdir="$1"
  tb_name=$(basename "$(dirname "$simdir")")
  echo "[$tb_name] Removing sim directory..."
  (
    rm -rf "$simdir"
    echo "Done"
  ) 2>&1 | sed "s/^/[$tb_name] /"
}

export -f remove_one_sim

# Find all sim/ directories under ROOT and remove them in parallel
while read -r simdir; do
  remove_one_sim "$simdir" &
  pids+=($!)
done < <(find "$ROOT" -type d -name sim)

# Wait for all jobs to finish
for pid in "${pids[@]}"; do
  wait "$pid"
done
