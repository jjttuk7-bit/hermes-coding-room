# Hermes Coding Room

Hermes Coding Room은 WSL과 tmux 기반으로 만든 로컬 멀티 코딩 에이전트 작업실입니다.

Hermes Agent가 Claude Code, Codex exec, Test Runner를 로컬 코딩 팀처럼 호출할 수 있게 만드는 것이 목적입니다.

## 개념 구조

Hermes Agent
↓
Hermes Bridge
↓
Claude Code / Codex exec / Test Runner
↓
logs + memory
↓
compact JSON result

## 역할

- Hermes Agent: 상위 오케스트레이터
- Hermes Bridge: Hermes Agent와 로컬 코딩 엔진을 연결하는 호출 인터페이스
- Claude Code: 설계, 리뷰, 실패 분석
- Codex exec: 실제 구현, 파일 생성, 파일 수정
- Test Runner: 실행 및 검증
- memory: 최신 요약, 작업 이력, compact JSON 결과 저장
- logs/runs: 작업별 상세 로그 저장
- workspace: 실제 생성되는 코드 파일 저장 공간

## 주요 실행 명령

Hermes Agent 또는 사용자는 다음 명령으로 로컬 코딩 작업을 실행할 수 있습니다.

cd ~/hermes-coding-room && python3 scripts/hermes_bridge_json.py "{작업 요청}" "{검증 명령}"

예시:

cd ~/hermes-coding-room && python3 scripts/hermes_bridge_json.py "workspace/profit_calc.py 파일을 만들어줘. 매출과 비용을 명령행 인자로 받아 이익을 출력하게 해줘." "python3 workspace/profit_calc.py 100000 65000"

## 결과 파일

Hermes Agent는 아래 파일을 읽으면 됩니다.

~/hermes-coding-room/memory/latest_result_compact.json

예시 결과:

{
  "ok": true,
  "result": "성공",
  "test_output": "35000",
  "exit_code": 0,
  "message": "작업이 성공했습니다."
}

## 현재 상태

- v1.0 로컬 엔진 완성
- GitHub 백업 완료
- Hermes Bridge 준비 완료
- compact JSON 결과 생성 완료
- 다음 단계: 실제 Hermes Agent 환경과 연결

## 구성 요소

### scripts

- ask_claude.sh: Claude Code에게 설계와 리뷰를 요청합니다.
- ask_codex.sh: Codex exec를 통해 실제 구현을 수행합니다.
- run_test.sh: 검증 명령을 실행하고 exit_code를 기록합니다.
- orchestrate.sh: Claude, Codex, Test Runner를 순서대로 호출합니다.
- hermes_code_task.sh: Hermes가 읽기 쉬운 요약 파일을 생성합니다.
- hermes_bridge.sh: 표준 텍스트 출력 브리지입니다.
- hermes_bridge_json.py: Hermes가 읽기 쉬운 JSON 결과를 생성합니다.
- build_context.sh: 이전 작업 기억을 모아 context snapshot을 만듭니다.

### memory

- project_state.md: 현재 프로젝트 상태
- task_history.md: 작업 이력
- latest_run.md: 최신 실행 정보
- latest_summary.md: 최신 Markdown 요약
- latest_result.json: 전체 JSON 결과
- latest_result_compact.json: Hermes가 읽을 compact JSON 결과
- hermes_bridge_contract.md: Hermes 연결 계약서

### logs

- logs/runs/<timestamp>/final_report.md: 작업별 최종 리포트
- logs/runs/<timestamp>/test_attempt_0.log: 테스트 실행 로그
- logs/runs/<timestamp>/codex_implement.log: Codex 구현 로그
- logs/runs/<timestamp>/claude_plan.log: Claude 설계 로그

## 최종 목표

Hermes Coding Room의 최종 목표는 Hermes Agent가 사용자의 코딩 요청을 받아, 로컬 WSL 환경에서 실제 코드를 생성하고, 테스트하고, 결과를 요약해 다시 사용자에게 보고하는 것입니다.
