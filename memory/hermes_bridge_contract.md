# Hermes Bridge Contract v1.1.1

## 호출 명령

cd ~/hermes-coding-room && python3 scripts/hermes_bridge_json.py "{TASK}" "{TEST_CMD}"

## 결과 파일

~/hermes-coding-room/memory/latest_result_compact.json

## 상태

- ok: true = 성공
- ok: false = 실패, timeout, interrupted
- ok: null = running

## 원칙

latest_result_compact.json은 항상 현재 실행 상태를 반영해야 한다.
Hermes는 이 JSON 기준으로만 사용자에게 보고한다.
이전 성공 결과를 근거로 보고하지 않는다.
