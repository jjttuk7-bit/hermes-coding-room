# Telegram Local Tmux Coding Room Summary Template

Hermes shell에서 Local Tmux Coding Room으로 작업을 보낼 때는 JSON 파일을 만든 뒤 curl --data-binary 방식으로 전송한다.

응답 전체를 그대로 출력하지 말고, response.summary만 읽어서 아래 형식으로 요약한다.

## 보고 형식

Local Tmux Coding Room 작업 결과

- 성공 여부: <summary.ok>
- 결과: <summary.result>
- job_id: <summary.job_id>
- 종료 코드: <summary.exit_code>
- 소요 시간: <summary.duration_sec>초
- 검증 명령: <summary.test_cmd>
- 검증 출력: <summary.test_output>
- 메시지: <summary.message>

## 주의

- X-Hermes-Token 값은 절대 출력하지 않는다.
- latest 전체 JSON을 Telegram에 길게 붙이지 않는다.
- stdout_tail/stderr_tail은 실패 분석이 필요할 때만 짧게 요약한다.
- 성공 시에는 summary만 보고한다.
