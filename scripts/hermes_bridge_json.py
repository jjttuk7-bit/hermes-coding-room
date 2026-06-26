#!/usr/bin/env python3
import json
import subprocess
import sys
from pathlib import Path

BASE_DIR = Path.home() / "hermes-coding-room"
SUMMARY_FILE = BASE_DIR / "memory" / "latest_summary.md"
LATEST_RUN_FILE = BASE_DIR / "memory" / "latest_run.md"
RESULT_JSON_FILE = BASE_DIR / "memory" / "latest_result.json"
COMPACT_JSON_FILE = BASE_DIR / "memory" / "latest_result_compact.json"


def read_text(path: Path) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")


def extract_line_value(text: str, prefix: str) -> str:
    for line in text.splitlines():
        if line.startswith(prefix):
            return line.replace(prefix, "", 1).strip()
    return ""

def extract_test_output(summary: str) -> tuple[str, int | None]:
    lines = summary.splitlines()
    output_lines = []
    in_test = False
    exit_code = None

    for line in lines:
        stripped = line.strip()

        if stripped.startswith("실행 명령:"):
            in_test = True
            continue

        if stripped.startswith("exit_code="):
            try:
                exit_code = int(stripped.replace("exit_code=", "").strip())
            except ValueError:
                exit_code = None
            in_test = False
            continue

        if in_test:
            if stripped and not stripped.startswith("-") and not stripped.startswith("```"):
                output_lines.append(stripped)

    return "\n".join(output_lines).strip(), exit_code


def main() -> int:
    if len(sys.argv) < 2:
        result = {
            "ok": False,
            "result": "실패",
            "error": "작업 요청이 없습니다.",
            "usage": 'python3 scripts/hermes_bridge_json.py "작업 요청" "검증 명령"',
        }
        print(json.dumps(result, ensure_ascii=False, indent=2))
        return 1

    task = sys.argv[1]
    test_cmd = sys.argv[2] if len(sys.argv) >= 3 else "ls -la workspace"

    bridge = BASE_DIR / "scripts" / "hermes_bridge.sh"

    proc = subprocess.run(
        [str(bridge), task, test_cmd],
        cwd=str(BASE_DIR),
        text=True,
        capture_output=True,
        timeout=900,
    )

    latest_run = read_text(LATEST_RUN_FILE)
    summary = read_text(SUMMARY_FILE)
    test_output, parsed_exit_code = extract_test_output(summary)

    result_value = extract_line_value(latest_run, "- 결과:")
    run_dir = extract_line_value(latest_run, "- 실행 폴더:")
    report = extract_line_value(latest_run, "- 리포트:")
    saved_task = extract_line_value(latest_run, "- 요청:")
    saved_test_cmd = extract_line_value(latest_run, "- 검증 명령:")

    ok = result_value == "성공" and proc.returncode == 0

    payload = {
        "ok": ok,
        "result": result_value or "알 수 없음",
        "task": saved_task or task,
        "test_cmd": saved_test_cmd or test_cmd,
        "summary_file": str(SUMMARY_FILE),
        "latest_run_file": str(LATEST_RUN_FILE),
        "result_json_file": str(RESULT_JSON_FILE),
        "compact_json_file": str(COMPACT_JSON_FILE),
        "run_dir": run_dir,
        "report": report,
        "summary": summary,
        "bridge_returncode": proc.returncode,
        "bridge_stdout_tail": "\n".join(proc.stdout.splitlines()[-80:]),
        "bridge_stderr_tail": "\n".join(proc.stderr.splitlines()[-40:]),
    }

    compact_payload = {
        "ok": ok,
        "result": result_value or "알 수 없음",
        "task": saved_task or task,
        "test_cmd": saved_test_cmd or test_cmd,
        "test_output": test_output,
        "exit_code": parsed_exit_code,
        "run_dir": run_dir,
        "report": report,
        "summary_file": str(SUMMARY_FILE),
        "result_json_file": str(RESULT_JSON_FILE),
        "compact_json_file": str(COMPACT_JSON_FILE),
        "message": (
            f"작업이 성공했습니다. 검증 명령이 정상 종료되었고 출력은 {test_output}입니다."
            if ok else
            "작업이 실패했습니다. latest_result.json 또는 final_report.md를 확인해야 합니다."
        ),
    }

    RESULT_JSON_FILE.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    COMPACT_JSON_FILE.write_text(
        json.dumps(compact_payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )

    print(json.dumps(compact_payload, ensure_ascii=False, indent=2))
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
