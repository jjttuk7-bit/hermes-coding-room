#!/usr/bin/env bash

TASK="$1"
TEST_CMD="$2"

if [ -z "$TASK" ]; then
  echo "사용법: ./scripts/orchestrate.sh \"작업 요청\" \"검증 명령\""
  echo "예시: ./scripts/orchestrate.sh \"workspace/greet.py를 만들어줘\" \"python3 workspace/greet.py Jeff\""
  exit 1
fi

if [ -z "$TEST_CMD" ]; then
  TEST_CMD="ls -la workspace"
fi

echo "========================================"
echo "Hermes Coding Room Orchestrator v0.2"
echo "========================================"
echo ""
echo "요청:"
echo "$TASK"
echo ""
echo "검증 명령:"
echo "$TEST_CMD"
echo ""

mkdir -p logs prompts workspace

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT="logs/final_report_$TIMESTAMP.md"

echo "# Hermes Coding Room 실행 리포트" > "$REPORT"
echo "" >> "$REPORT"
echo "## 사용자 요청" >> "$REPORT"
echo "$TASK" >> "$REPORT"
echo "" >> "$REPORT"
echo "## 검증 명령" >> "$REPORT"
echo '```bash' >> "$REPORT"
echo "$TEST_CMD" >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "1단계: Claude에게 구현 계획 요청 중..."
./scripts/ask_claude.sh "너는 설계자/리뷰어 역할이다. 절대 파일을 생성하거나 수정하지 마라. 실제 구현은 Codex가 담당한다. 다음 작업을 수행하기 위한 구현 계획과 검증 기준만 짧고 명확하게 제안해줘. 반드시 어떤 파일을 만들거나 수정해야 하는지도 텍스트로만 설명해줘: $TASK"

echo "## Claude 설계/검토 로그" >> "$REPORT"
echo '```text' >> "$REPORT"
cat logs/claude.log >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "2단계: Codex에게 구현 요청 중..."
./scripts/ask_codex.sh "다음 작업을 실제 파일로 구현해줘. 반드시 요청된 파일이 존재하도록 만들어줘. 작업 요청: $TASK"

echo "## Codex 구현 로그" >> "$REPORT"
echo '```text' >> "$REPORT"
cat logs/codex.log >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

echo "3단계: Test Runner로 검증 실행 중..."
./scripts/run_test.sh "$TEST_CMD"

echo "## Test Runner 로그" >> "$REPORT"
echo '```text' >> "$REPORT"
cat logs/test.log >> "$REPORT"
echo '```' >> "$REPORT"
echo "" >> "$REPORT"

if grep -qi "No such file\|can't open file\|command not found\|Error\|Traceback\|failed" logs/test.log; then
  echo "검증 결과: 실패 가능성 있음"
  echo "## 검증 판정" >> "$REPORT"
  echo "실패 가능성 있음. Test Runner 로그에 오류 패턴이 발견되었습니다." >> "$REPORT"
  echo "" >> "$REPORT"

  echo "4단계: Claude에게 실패 원인 리뷰 요청 중..."
  ./scripts/ask_claude.sh "너는 실패 분석 리뷰어 역할이다. 절대 파일을 생성하거나 수정하지 마라. 다음 테스트 로그를 보고 실패 원인과 Codex에게 전달할 수정 방향만 텍스트로 알려줘: $(cat logs/test.log)"

  echo "## Claude 실패 리뷰" >> "$REPORT"
  echo '```text' >> "$REPORT"
  cat logs/claude.log >> "$REPORT"
  echo '```' >> "$REPORT"
else
  echo "검증 결과: 성공 가능성 높음"
  echo "## 검증 판정" >> "$REPORT"
  echo "성공 가능성 높음. Test Runner 로그에서 주요 오류 패턴이 발견되지 않았습니다." >> "$REPORT"
  echo "" >> "$REPORT"

  echo "4단계: Claude 최종 리뷰 요청 중..."
  ./scripts/ask_claude.sh "너는 리뷰어 역할이다. 절대 파일을 생성하거나 수정하지 마라. 현재 workspace와 테스트 결과를 기준으로 방금 작업을 최종 리뷰하고 개선점만 텍스트로 알려줘."

  echo "## Claude 최종 리뷰" >> "$REPORT"
  echo '```text' >> "$REPORT"
  cat logs/claude.log >> "$REPORT"
  echo '```' >> "$REPORT"
fi

echo ""
echo "완료했습니다."
echo "최종 리포트: $REPORT"
