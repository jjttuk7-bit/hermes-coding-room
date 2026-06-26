# Hermes Coding Room

이 폴더는 Hermes Agent가 Claude Code와 Codex를 tmux 기반으로 오케스트레이션하기 위한 실험 작업실이다.

## 목적

Hermes는 상위 오케스트레이터 역할을 한다.
Claude Code는 코드베이스 분석, 설계 검토, 리팩터링 방향 제안, 최종 리뷰를 담당한다.
Codex는 구현, 파일 수정, 테스트 코드 작성, 빠른 패치를 담당한다.
Test Runner는 실행, 빌드, 테스트, 로그 확인을 담당한다.

## 기본 역할 분담

- PANE 0: Hermes Orchestrator
- PANE 1: Claude Code
- PANE 2: Codex
- PANE 3: Test Runner

## 운영 규칙

1. Claude Code는 기본적으로 분석과 리뷰를 담당한다.
2. Codex는 구현과 수정 작업을 담당한다.
3. 테스트는 Test Runner pane에서 실행한다.
4. 두 에이전트가 동시에 같은 파일을 수정하지 않는다.
5. 최종 push나 배포는 사람의 승인 후 진행한다.

## 폴더 구조

- logs: Claude, Codex, Test Runner의 출력 로그 저장
- prompts: 반복 사용할 프롬프트 저장
- scripts: tmux pane 제어 스크립트 저장
- workspace: 실제 코드 실험 공간

## 이 작업실의 한 문장 정의

Hermes Coding Room은 Hermes가 Claude Code와 Codex를 각각 설계자와 구현자로 호출하고, 테스트와 리뷰까지 조율하는 tmux 기반 멀티 코딩 에이전트 작업실이다.

## 현재 운영 상태 메모

현재 Codex 구현은 tmux 대화형 pane이 아니라 `codex exec --skip-git-repo-check --sandbox workspace-write` 방식으로 수행한다.

greet2.py, greet3.py, greet4.py 실패는 과거 tmux 대화형 Codex 호출 방식의 실패 이력이다. 현재 기준으로는 greet_test.py, greet5.py, greet6.py, greet7.py, greet8.py 생성 및 실행이 성공했으므로 Codex exec 방식은 정상 작동 중이다.

Claude Code는 절대 파일을 생성하거나 수정하지 않고, 설계·리뷰·실패 분석만 담당한다. 실제 구현은 Codex exec가 담당한다.
