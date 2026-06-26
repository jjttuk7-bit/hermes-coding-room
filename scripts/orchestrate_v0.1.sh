#!/usr/bin/env bash

TASK="$1"

if [ -z "$TASK" ]; then
  echo "사용법: ./scripts/orchestrate.sh \"작업 요청\""
  exit 1
fi

echo "========================================"
echo "Hermes Coding Room Orchestrator v0.1"
echo "========================================"
echo ""
echo "요청:"
echo "$TASK"
echo ""

mkdir -p logs prompts workspace

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT="logs/final_report_$TIMESTAMP.md"

echo "# Hermes Coding Room 실행 리포트" > "$REPORT"
echo "" >> "$REPORT"
echo "## 사용자 요청" >> "$REPORT"
echo "" >> "$REPORT"
echo "$TASK" >> "$REPORT"
echo "" >> "$REPORT"

echo "1단계: Claude에게 설계/검토 요청 중..."
./scripts/ask_claude.sh "다음 작업을 수행하기 위한 구현 계획을 짧고 명확하게 제안해줘: $TASK"

echo "" >> "$REPORT"
echo "## Claude 설계/검토 로그" >> "$REPORT"
echo '```text' >> "$REPORT"
cat logs/claude.log >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "2단계: Codex에게 구현 요청 중..."
./scripts/ask_codex.sh "Claude의 설계 방향을 참고해서 다음 작업을 실제로 구현해줘: $TASK"

echo "" >> "$REPORT"
echo "## Codex 구현 로그" >> "$REPORT"
echo '```text' >> "$REPORT"
cat logs/codex.log >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "3단계: 기본 검증 실행 중..."
./scripts/run_test.sh "ls -la workspace"

echo "" >> "$REPORT"
echo "## Test Runner 로그" >> "$REPORT"
echo '```text' >> "$REPORT"
cat logs/test.log >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "4단계: Claude 최종 리뷰 요청 중..."
./scripts/ask_claude.sh "현재 workspace 폴더와 logs 내용을 기준으로, 방금 작업 결과를 리뷰하고 다음 개선점을 알려줘."

echo "" >> "$REPORT"
echo "## Claude 최종 리뷰" >> "$REPORT"
echo '```text' >> "$REPORT"
cat logs/claude.log >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "완료했습니다."
echo "최종 리포트: $REPORT"
