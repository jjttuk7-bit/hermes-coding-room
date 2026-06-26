#!/usr/bin/env bash

TASK="$1"
TEST_CMD="$2"

if [ -z "$TASK" ]; then
  echo "HERMES_RESULT=실패"
  echo "HERMES_ERROR=작업 요청이 없습니다."
  echo "사용법: ./scripts/hermes_bridge.sh \"작업 요청\" \"검증 명령\""
  exit 1
fi

if [ -z "$TEST_CMD" ]; then
  TEST_CMD="ls -la workspace"
fi

cd ~/hermes-coding-room || exit 1

./scripts/hermes_code_task.sh "$TASK" "$TEST_CMD"

SUMMARY_FILE="memory/latest_summary.md"
LATEST_RUN="memory/latest_run.md"

if [ ! -f "$LATEST_RUN" ]; then
  echo "HERMES_RESULT=실패"
  echo "HERMES_ERROR=memory/latest_run.md 파일이 없습니다."
  exit 1
fi

RESULT=$(grep "^- 결과:" "$LATEST_RUN" | sed 's/- 결과: //')
RUN_DIR=$(grep "^- 실행 폴더:" "$LATEST_RUN" | sed 's/- 실행 폴더: //')
REPORT=$(grep "^- 리포트:" "$LATEST_RUN" | sed 's/- 리포트: //')

echo ""
echo "========================================"
echo "HERMES_BRIDGE_OUTPUT"
echo "========================================"
echo "HERMES_RESULT=$RESULT"
echo "HERMES_SUMMARY_FILE=$SUMMARY_FILE"
echo "HERMES_REPORT=$REPORT"
echo "HERMES_RUN_DIR=$RUN_DIR"
echo ""

if [ -f "$SUMMARY_FILE" ]; then
  echo "HERMES_SUMMARY_BEGIN"
  cat "$SUMMARY_FILE"
  echo "HERMES_SUMMARY_END"
else
  echo "HERMES_ERROR=summary 파일이 없습니다."
fi
