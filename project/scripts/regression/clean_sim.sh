#!/usr/bin/env bash
set -euo pipefail

ROOT="$HOME/MICROARCH/project/hvl/local-lib/"

pids=()

clean_one_sim() {
  simdir="$1"
  tb_name=$(basename "$(dirname "$simdir")")
  echo "[$tb_name] Cleaning..."
  (
    cd "$simdir"
    find . -mindepth 1 -delete
    echo "Done"
  ) 2>&1 | sed "s/^/[$tb_name] /"
}

export -f clean_one_sim

while read -r simdir; do
  clean_one_sim "$simdir" &
  pids+=($!)
done < <(find "$ROOT" -type d -name sim)

for pid in "${pids[@]}"; do
  wait "$pid"
done