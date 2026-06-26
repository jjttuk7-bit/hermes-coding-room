#!/usr/bin/env bash
set -e

SESSION="hermes-local"
ROOT="$HOME/hermes-coding-room"
TOKEN="${LOCAL_HERMES_TOKEN:-jeff-local-hermes-001}"

cd "$ROOT"

mkdir -p logs memory workspace

tmux kill-session -t "$SESSION" 2>/dev/null || true

tmux new-session -d -s "$SESSION" -n local-room

tmux send-keys -t "$SESSION":0.0 "clear; echo 'PANE 0: Local Hermes Worker'; cd '$ROOT'; export LOCAL_HERMES_TOKEN='$TOKEN'; python3 scripts/local_hermes_worker.py" C-m

tmux split-window -h -t "$SESSION":0.0
tmux send-keys -t "$SESSION":0.1 "clear; echo 'PANE 1: Local Worker Log'; cd '$ROOT'; touch logs/local_worker.log; tail -f logs/local_worker.log" C-m

tmux split-window -v -t "$SESSION":0.1
tmux send-keys -t "$SESSION":0.2 "clear; echo 'PANE 2: Codex Log'; cd '$ROOT'; touch logs/codex.log; tail -f logs/codex.log" C-m

tmux select-pane -t "$SESSION":0.0
tmux split-window -v -t "$SESSION":0.0
tmux send-keys -t "$SESSION":0.3 "clear; echo 'PANE 3: Latest Result Watch'; cd '$ROOT'; while true; do clear; echo 'memory/latest_result_compact.json'; echo '================================'; if [ -f memory/latest_result_compact.json ]; then cat memory/latest_result_compact.json; else echo 'not found'; fi; sleep 3; done" C-m

tmux select-layout -t "$SESSION":0 tiled
tmux attach -t "$SESSION"
