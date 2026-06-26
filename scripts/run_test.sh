#!/usr/bin/env bash

CMD="$1"

if [ -z "$CMD" ]; then
  echo "사용법: ./scripts/run_test.sh \"실행할 명령\""
  exit 1
fi

mkdir -p logs

echo "실행 명령: $CMD" > logs/test.log
echo "----------------------------------------" >> logs/test.log

bash -lc "$CMD" >> logs/test.log 2>&1
STATUS=$?

echo "----------------------------------------" >> logs/test.log
echo "exit_code=$STATUS" >> logs/test.log

# Test Runner pane에도 결과를 보여준다.
tmux send-keys -t hermes-coding:0.3 C-c 2>/dev/null
tmux send-keys -t hermes-coding:0.3 'cd ~/hermes-coding-room' C-m 2>/dev/null
tmux send-keys -t hermes-coding:0.3 'cat logs/test.log' C-m 2>/dev/null

echo "Test Runner 결과를 logs/test.log 에 저장했습니다."
exit $STATUS
