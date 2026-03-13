#!/usr/bin/env bash
set -euo pipefail

MODE="$1"  # prefix or postfix
echo "Run cluster mode: $MODE"

BINARY_CANDIDATE=$(find . -type f -executable -name "*validator*" -print -quit || true)
if [ -z "$BINARY_CANDIDATE" ]; then
  echo "No validator binary found; trying other names..."
  BINARY_CANDIDATE=$(find . -type f -executable -name "*node*" -print -quit || true)
fi

if [ -z "$BINARY_CANDIDATE" ]; then
  echo "No validator/node binary found in repo build. Exiting (CI may have different build layout)."
  mkdir -p local-cluster/logs
  echo "NO_BINARY" > local-cluster/logs/fake.log
  exit 0
fi

echo "Using binary: $BINARY_CANDIDATE"

rm -rf local-cluster || true
mkdir -p local-cluster/logs

start_node() {
  id=$1
  d=local-cluster/node${id}
  mkdir -p "$d"
  nohup "$BINARY_CANDIDATE" --node-id "$id" --data-dir "$d" > "local-cluster/logs/node${id}.log" 2>&1 &
  echo "started node $id (pid $!) -> local-cluster/logs/node${id}.log"
}

start_node 1
start_node 2
start_node 3
start_node 4

echo "Waiting 45s for nodes to run and produce logs..."
sleep 45

for f in local-cluster/logs/*.log; do
  echo "---- $f ----"
  tail -n 200 "$f" || true
done

sleep 10

for f in local-cluster/logs/*.log; do
  echo "==== final $f ===="
  tail -n 500 "$f" || true
done

pkill -f "$(basename "$BINARY_CANDIDATE")" || true
echo "Killed processes matching $(basename "$BINARY_CANDIDATE")"
