# Hermes Coding Room Server + Local Tmux Bridge 성공 로그

작성일: 2026-06-26

## 1. 성공한 구조 요약

현재 Hermes Coding Room은 두 가지 실행 구조를 갖는다.

### 1) Server Coding Room

```text
Telegram
↓
my_hermes_agent_bot
↓
/opt/data/hermes-coding-room
↓
Hermes Bridge
↓
Codex / Claude / Test Runner
↓
Telegram 보고

