#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/MICROARCH/project/hvl/"

pids=()

remove_one_sim() {
  simdir="$1"
  tb_name=$(basename "$(dirname "$simdir")")
  # echo "[$tb_name] Removing sim directory..."
  (
    rm -rf "$simdir"
    # echo "Done"
  ) 2>&1 | sed "s/^/[$tb_name] /"
}

export -f remove_one_sim

# Remove all sim/ directories in parallel
while read -r simdir; do
  remove_one_sim "$simdir" &
  pids+=($!)
done < <(find "$ROOT" -type d -name sim)

# Wait for all jobs
for pid in "${pids[@]}"; do
  wait "$pid"
done

echo "Cleaning up empty directories..."
find "$ROOT" -depth -type d -empty -exec rmdir {} +

echo "Cleanup complete"