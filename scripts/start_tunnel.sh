#!/usr/bin/env bash
set -e

ROOT="$HOME/hermes-coding-room"
cd "$ROOT"

mkdir -p logs memory

if ! command -v cloudflared >/dev/null 2>&1; then
  echo "cloudflared가 설치되어 있지 않습니다."
  echo "먼저 아래 명령으로 설치하세요:"
  echo "cd ~"
  echo "curl -L --output cloudflared.deb https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb"
  echo "sudo dpkg -i cloudflared.deb"
  exit 1
fi

echo "Cloudflare Quick Tunnel을 시작합니다."
echo "Local Worker URL: http://127.0.0.1:8787"
echo
echo "아래에 출력되는 https://xxxxx.trycloudflare.com 주소를 복사하세요."
echo "이 터미널을 끄면 터널도 닫힙니다."
echo

cloudflared tunnel --url http://127.0.0.1:8787 2>&1 | tee logs/cloudflared_tunnel.log
