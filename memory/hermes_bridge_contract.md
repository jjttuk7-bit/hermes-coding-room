# Hermes Coding Room Bridge Contract

## 목적

Hermes Coding Room은 Hermes Agent가 로컬 WSL 환경에서 Claude Code, Codex exec, Test Runner를 조합해 코딩 작업을 수행하도록 만든 로컬 멀티 코딩 에이전트 엔진이다.

## Hermes 호출 명령

cd ~/hermes-coding-room && ./scripts/hermes_bridge.sh "{작업 요청}" "{검증 명령}"

## 입력

- 작업 요청: 만들거나 수정할 코드 작업
- 검증 명령: 작업 성공 여부를 확인하는 명령

예:

cd ~/hermes-coding-room && ./scripts/hermes_bridge.sh "workspace/sales_calc.py 파일을 만들어줘. 상품 가격과 수량을 받아 총액을 출력하게 해줘." "python3 workspace/sales_calc.py 15000 3"

## 출력

hermes_bridge.sh는 마지막에 다음 값을 출력한다.

HERMES_RESULT=성공 또는 실패
HERMES_SUMMARY_FILE=memory/latest_summary.md
HERMES_REPORT=logs/runs/<timestamp>/final_report.md
HERMES_RUN_DIR=logs/runs/<timestamp>

## Hermes가 읽을 파일

우선 읽을 파일:

memory/latest_summary.md

필요 시 읽을 파일:

memory/latest_run.md
logs/runs/<timestamp>/final_report.md

## 역할 분담

- Hermes Agent: 사용자 요청 해석, 작업 요청/검증 명령 생성, 결과 보고
- Claude Code: 설계, 리뷰, 실패 분석
- Codex exec: 실제 파일 생성, 구현, 수정
- Test Runner: 검증 명령 실행
- memory: 최신 요약과 작업 이력 저장
- logs/runs: 작업별 상세 로그 저장

## 안전 규칙

1. 사용자 승인 없이 git push, 배포, 파일 삭제, 시스템 설정 변경을 하지 않는다.
2. 기본 작업 범위는 ~/hermes-coding-room/workspace 안이다.
3. 위험한 명령은 실행하지 않는다.
4. 실패 시 무한 반복하지 않는다.
5. 보고는 latest_summary.md와 final_report.md를 근거로 한다.
