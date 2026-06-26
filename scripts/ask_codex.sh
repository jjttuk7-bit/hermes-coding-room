#!/usr/bin/env bash

PROMPT="$1"

if [ -z "$PROMPT" ]; then
  echo "사용법: ./scripts/ask_codex.sh \"작업 내용\""
  exit 1
fi

mkdir -p logs prompts workspace

export PATH="/home/jeff/.hermes/node/bin:$PATH"
cd ~/hermes-coding-room || exit 1

PROMPT_FILE="prompts/codex_task.txt"
LOG_FILE="logs/codex.log"

cat > "$PROMPT_FILE" <<PROMPT_EOF
$PROMPT

중요:
- 실제 파일을 생성하거나 수정해야 한다.
- 설명만 하지 말고 요청된 파일이 workspace 안에 존재하도록 만들어라.
- 작업이 끝나면 어떤 파일을 만들었는지 짧게 보고하라.
PROMPT_EOF

cat "$PROMPT_FILE" | codex exec --skip-git-repo-check --sandbox workspace-write > "$LOG_FILE" 2>&1

echo "Codex 응답을 logs/codex.log 에 저장했습니다."
