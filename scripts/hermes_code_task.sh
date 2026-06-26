#!/usr/bin/env bash

TASK="$1"
TEST_CMD="$2"

if [ -z "$TASK" ]; then
  echo "사용법: ./scripts/hermes_code_task.sh \"작업 요청\" \"검증 명령\""
  exit 1
fi

if [ -z "$TEST_CMD" ]; then
  TEST_CMD="ls -la workspace"
fi

mkdir -p memory logs

./scripts/orchestrate.sh "$TASK" "$TEST_CMD"

LATEST_REPORT=$(grep "^- 리포트:" memory/latest_run.md | sed 's/- 리포트: //')
LATEST_RUN_DIR=$(grep "^- 실행 폴더:" memory/latest_run.md | sed 's/- 실행 폴더: //')
LATEST_RESULT=$(grep "^- 결과:" memory/latest_run.md | sed 's/- 결과: //')
LATEST_TASK=$(grep "^- 요청:" memory/latest_run.md | sed 's/- 요청: //')
LATEST_TEST_CMD=$(grep "^- 검증 명령:" memory/latest_run.md | sed 's/- 검증 명령: //')

SUMMARY="memory/latest_summary.md"

{
  echo "# Hermes Code Task Summary"
  echo ""
  echo "## 결과"
  echo "$LATEST_RESULT"
  echo ""
  echo "## 요청"
  echo "$LATEST_TASK"
  echo ""
  echo "## 검증 명령"
  echo '```bash'
  echo "$LATEST_TEST_CMD"
  echo '```'
  echo ""
  echo "## 테스트 결과"
  echo '```text'
  if [ -f logs/test.log ]; then
    cat logs/test.log
  else
    echo "logs/test.log 없음"
  fi
  echo '```'
  echo ""
  echo "## 실행 폴더"
  echo "$LATEST_RUN_DIR"
  echo ""
  echo "## 최종 리포트"
  echo "$LATEST_REPORT"
  echo ""
  echo "## Hermes 보고용 한 줄 요약"
  if [ "$LATEST_RESULT" = "성공" ]; then
    echo "작업이 성공했습니다. 검증 명령이 정상 종료되었고 결과는 logs/test.log에 기록되었습니다."
  else
    echo "작업이 실패했습니다. 실패 원인은 final_report.md와 logs/test.log를 확인해야 합니다."
  fi
} > "$SUMMARY"

echo ""
echo "========================================"
echo "Hermes Code Task Summary"
echo "========================================"
echo "결과: $LATEST_RESULT"
echo "실행 폴더: $LATEST_RUN_DIR"
echo "리포트: $LATEST_REPORT"
echo "요약 파일: $SUMMARY"
echo ""

cat "$SUMMARY"
