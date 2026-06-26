# Hermes Coding Room Project State

## 현재 상태

Hermes Coding Room은 tmux 기반 멀티 코딩 에이전트 작업실이다.

- Claude Code: 설계 / 리뷰 / 실패 분석 담당
- Codex exec: 실제 파일 생성 / 구현 담당
- Test Runner: 실행 / 검증 담당
- orchestrate.sh v0.2: 작업 요청 + 검증 명령을 받아 전체 루프 실행

## 현재 정상 작동 확인

- workspace/hello_codex.py 실행 성공
- workspace/greet.py 실행 성공
- workspace/greet_test.py 실행 성공
- workspace/greet5.py 실행 성공
- workspace/greet6.py 실행 성공
- workspace/greet7.py 실행 성공
- workspace/greet8.py 실행 성공

## 이전 실패 이력

- greet2.py, greet3.py, greet4.py는 생성되지 않아 실패했다.
- 원인은 초기 Codex tmux 대화형 호출 방식이 실제 파일 생성을 안정적으로 완료하지 못했기 때문이다.
- 이후 ask_codex.sh를 codex exec 방식으로 변경하면서 문제가 해결되었다.

## 현재 Codex 실행 방식

Codex는 tmux pane 대화형이 아니라 다음 방식으로 실행한다.

codex exec --skip-git-repo-check --sandbox workspace-write

## 다음 개선 목표

- 실패 시 Codex에게 test.log를 전달해 자동 재수정하는 orchestrate.sh v0.3 만들기
- 작업별 로그를 latest와 runs 디렉터리로 분리하기
- memory/task_history.md에 작업 이력 누적하기
