#!/usr/bin/env bash

TASK="$1"
TEST_CMD="$2"

if [ -z "$TASK" ]; then
  echo "사용법: ./scripts/orchestrate.sh \"작업 요청\" \"검증 명령\""
  exit 1
fi

if [ -z "$TEST_CMD" ]; then
  TEST_CMD="ls -la workspace"
fi

mkdir -p logs prompts workspace memory logs/runs

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RUN_DIR="logs/runs/$TIMESTAMP"
mkdir -p "$RUN_DIR"

REPORT="$RUN_DIR/final_report.md"

echo "$TASK" > "$RUN_DIR/task.txt"
echo "$TEST_CMD" > "$RUN_DIR/test_command.txt"

echo "========================================"
echo "Hermes Coding Room Orchestrator v0.4"
echo "========================================"
echo ""
echo "Run Dir: $RUN_DIR"
echo ""
echo "요청:"
echo "$TASK"
echo ""
echo "검증 명령:"
echo "$TEST_CMD"
echo ""

{
  echo "# Hermes Coding Room 실행 리포트"
  echo ""
  echo "- 시간: $TIMESTAMP"
  echo "- 실행 폴더: $RUN_DIR"
  echo ""
  echo "## 사용자 요청"
  echo "$TASK"
  echo ""
  echo "## 검증 명령"
  echo '```bash'
  echo "$TEST_CMD"
  echo '```'
  echo ""
} > "$REPORT"

echo "1단계: Claude에게 구현 계획 요청 중..."
./scripts/ask_claude.sh "너는 설계자/리뷰어 역할이다. 절대 파일을 생성하거나 수정하지 마라. 실제 구현은 Codex가 담당한다. 다음 작업의 구현 계획과 검증 기준만 짧고 명확하게 제안해줘: $TASK"

cp logs/claude.log "$RUN_DIR/claude_plan.log"

{
  echo "## Claude 구현 계획"
  echo '```text'
  cat "$RUN_DIR/claude_plan.log"
  echo '```'
  echo ""
} >> "$REPORT"

echo "2단계: Codex에게 구현 요청 중..."
./scripts/ask_codex.sh "다음 작업을 실제 파일로 구현해줘. 설명만 하지 말고 반드시 요청된 파일을 생성하거나 수정해. 작업 요청: $TASK"

cp logs/codex.log "$RUN_DIR/codex_implement.log"

{
  echo "## Codex 1차 구현 로그"
  echo '```text'
  cat "$RUN_DIR/codex_implement.log"
  echo '```'
  echo ""
} >> "$REPORT"

MAX_RETRY=2
ATTEMPT=0
SUCCESS=0

while [ $ATTEMPT -le $MAX_RETRY ]; do
  echo "3단계: Test Runner 검증 실행 중... attempt=$ATTEMPT"
  ./scripts/run_test.sh "$TEST_CMD"
  TEST_STATUS=$?

  cp logs/test.log "$RUN_DIR/test_attempt_$ATTEMPT.log"

  {
    echo "## Test Runner 로그 attempt=$ATTEMPT"
    echo '```text'
    cat "$RUN_DIR/test_attempt_$ATTEMPT.log"
    echo '```'
    echo ""
  } >> "$REPORT"

  if [ $TEST_STATUS -eq 0 ]; then
    SUCCESS=1
    echo "검증 결과: 성공"
    break
  fi

  if [ $ATTEMPT -eq $MAX_RETRY ]; then
    echo "검증 결과: 최종 실패"
    break
  fi

  echo "검증 실패. Codex에게 수정 요청 중..."
  ./scripts/ask_codex.sh "테스트가 실패했다. 아래 테스트 로그를 보고 문제를 수정해줘. 반드시 실제 파일을 수정하고 같은 검증 명령이 성공하게 만들어라.

작업 요청:
$TASK

검증 명령:
$TEST_CMD

테스트 로그:
$(cat logs/test.log)"

  NEXT_ATTEMPT=$((ATTEMPT + 1))
  cp logs/codex.log "$RUN_DIR/codex_fix_attempt_$NEXT_ATTEMPT.log"

  {
    echo "## Codex 수정 로그 attempt=$NEXT_ATTEMPT"
    echo '```text'
    cat "$RUN_DIR/codex_fix_attempt_$NEXT_ATTEMPT.log"
    echo '```'
    echo ""
  } >> "$REPORT"

  ATTEMPT=$((ATTEMPT + 1))
done

if [ $SUCCESS -eq 1 ]; then
  echo "4단계: Claude 최종 리뷰 요청 중..."
  ./scripts/ask_claude.sh "너는 리뷰어 역할이다. 절대 파일을 생성하거나 수정하지 마라. 현재 작업은 테스트에 성공했다. workspace와 테스트 결과를 기준으로 최종 리뷰와 개선점만 텍스트로 알려줘."

  cp logs/claude.log "$RUN_DIR/claude_final_review.log"

  {
    echo "## 최종 판정"
    echo "성공"
    echo ""
    echo "## Claude 최종 리뷰"
    echo '```text'
    cat "$RUN_DIR/claude_final_review.log"
    echo '```'
    echo ""
  } >> "$REPORT"

  RESULT="성공"
else
  echo "4단계: Claude 실패 분석 요청 중..."
  ./scripts/ask_claude.sh "너는 실패 분석 리뷰어 역할이다. 절대 파일을 생성하거나 수정하지 마라. 아래 테스트 로그와 Codex 로그를 보고 실패 원인과 다음 수정 방향만 알려줘.

테스트 로그:
$(cat logs/test.log)

Codex 로그:
$(cat logs/codex.log)"

  cp logs/claude.log "$RUN_DIR/claude_failure_review.log"

  {
    echo "## 최종 판정"
    echo "실패"
    echo ""
    echo "## Claude 실패 분석"
    echo '```text'
    cat "$RUN_DIR/claude_failure_review.log"
    echo '```'
    echo ""
  } >> "$REPORT"

  RESULT="실패"
fi

cp "$REPORT" "logs/final_report_$TIMESTAMP.md"

{
  echo ""
  echo "## 작업 이력"
  echo "- 시간: $TIMESTAMP"
  echo "- 요청: $TASK"
  echo "- 검증 명령: $TEST_CMD"
  echo "- 결과: $RESULT"
  echo "- 실행 폴더: $RUN_DIR"
  echo "- 리포트: $REPORT"
} >> memory/task_history.md

cat > memory/latest_run.md <<LATEST
# Latest Hermes Coding Room Run

- 시간: $TIMESTAMP
- 요청: $TASK
- 검증 명령: $TEST_CMD
- 결과: $RESULT
- 실행 폴더: $RUN_DIR
- 리포트: $REPORT
LATEST

echo ""
echo "완료했습니다."
echo "결과: $RESULT"
echo "실행 폴더: $RUN_DIR"
echo "최종 리포트: $REPORT"
