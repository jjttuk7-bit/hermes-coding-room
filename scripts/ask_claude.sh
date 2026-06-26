#!/usr/bin/env bash

SESSION="hermes-coding"
PANE="$SESSION:0.1"
PROMPT="$1"

if [ -z "$PROMPT" ]; then
  echo "사용법: ./scripts/ask_claude.sh \"질문 내용\""
  exit 1
fi

tmux send-keys -t "$PANE" 'export PATH="/home/jeff/.hermes/node/bin:$PATH"' C-m
tmux send-keys -t "$PANE" "claude -p \"$PROMPT\"" C-m

sleep 8

tmux capture-pane -t "$PANE" -p -S -500 > logs/claude.log

echo "Claude 응답을 logs/claude.log 에 저장했습니다."
