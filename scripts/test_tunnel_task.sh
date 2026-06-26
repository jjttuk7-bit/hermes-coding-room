#!/usr/bin/env bash
set -e

ROOT="$HOME/hermes-coding-room"
cd "$ROOT"

if [ -f "$ROOT/secrets/local_hermes.env" ]; then
  set -a
  . "$ROOT/secrets/local_hermes.env"
  set +a
fi

TOKEN="${LOCAL_HERMES_TOKEN:-}"
if [ -z "$TOKEN" ]; then
  echo "LOCAL_HERMES_TOKEN이 설정되어 있지 않습니다."
  echo "secrets/local_hermes.env 파일을 확인하세요."
  exit 1
fi

if [ ! -f memory/current_tunnel_url.txt ]; then
  echo "memory/current_tunnel_url.txt 파일이 없습니다."
  echo "터널 URL을 먼저 저장하세요."
  exit 1
fi

URL="$(cat memory/current_tunnel_url.txt | tr -d '[:space:]')"

cat > /tmp/hermes_local_task.json <<'JSON'
{
  "task": "workspace/tunnel_script_check.py 파일을 만들고 print(\"tunnel script check ok\")를 출력하게 해줘.",
  "test_cmd": "python3 workspace/tunnel_script_check.py"
}
JSON

curl -X POST "$URL/run-task" \
  -H "Content-Type: application/json" \
  -H "X-Hermes-Token: $TOKEN" \
  --data-binary @/tmp/hermes_local_task.json
