#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
BRIDGE_SH = ROOT / "scripts" / "hermes_bridge.sh"

MEMORY_DIR = ROOT / "memory"
RESULT_JSON_FILE = MEMORY_DIR / "latest_result.json"
COMPACT_JSON_FILE = MEMORY_DIR / "latest_result_compact.json"
SUMMARY_FILE = MEMORY_DIR / "latest_summary.md"


def tail_text(value: str | None, limit: int = 4000) -> str:
    if not value:
        return ""
    return value[-limit:]


def write_json(path: Path, payload: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def write_state(payload: dict[str, Any]) -> None:
    write_json(COMPACT_JSON_FILE, payload)

    full_payload = dict(payload)
    full_payload.setdefault("compact_json_file", str(COMPACT_JSON_FILE))
    full_payload.setdefault("result_json_file", str(RESULT_JSON_FILE))
    write_json(RESULT_JSON_FILE, full_payload)


def parse_bridge_vars(stdout: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in stdout.splitlines():
        line = line.strip()
        if not line.startswith("HERMES_"):
            continue
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        result[key.strip()] = value.strip()
    return result


def extract_exit_code(text: str) -> int | None:
    matches = re.findall(r"exit_code\s*=\s*(-?\d+)", text)
    if not matches:
        return None
    try:
        return int(matches[-1])
    except ValueError:
        return None


def clean_test_output(text: str) -> str:
    lines: list[str] = []

    for raw in text.splitlines():
        line = raw.rstrip()

        if not line.strip():
            continue
        if line.startswith("실행 명령:"):
            continue
        if set(line.strip()) <= {"-"}:
            continue
        if line.strip().startswith("exit_code="):
            continue

        lines.append(line)

    if not lines:
        return ""

    return "\n".join(lines).strip()


def read_test_result(run_dir_value: str | None) -> tuple[str, int | None]:
    if not run_dir_value:
        return "", None

    run_dir = Path(run_dir_value)
    if not run_dir.is_absolute():
        run_dir = ROOT / run_dir

    if not run_dir.exists():
        return "", None

    test_logs = sorted(run_dir.glob("test_attempt_*.log"))
    if not test_logs:
        test_logs = sorted(run_dir.glob("*test*.log"))

    if not test_logs:
        return "", None

    latest_log = test_logs[-1]
    text = latest_log.read_text(encoding="utf-8", errors="replace")
    return clean_test_output(text), extract_exit_code(text)


def build_success_or_failure_payload(
    *,
    task: str,
    test_cmd: str,
    proc: subprocess.CompletedProcess[str],
) -> dict[str, Any]:
    stdout = proc.stdout or ""
    stderr = proc.stderr or ""
    vars_ = parse_bridge_vars(stdout)

    run_dir = vars_.get("HERMES_RUN_DIR")
    report = vars_.get("HERMES_REPORT")
    summary_file = vars_.get("HERMES_SUMMARY_FILE")
    result_text = vars_.get("HERMES_RESULT", "")

    test_output, test_exit_code = read_test_result(run_dir)

    if test_exit_code is None:
        exit_code = proc.returncode
    else:
        exit_code = test_exit_code

    ok = proc.returncode == 0 and exit_code == 0

    compact: dict[str, Any] = {
        "ok": ok,
        "result": "성공" if ok else "실패",
        "task": task,
        "test_cmd": test_cmd,
        "test_output": test_output,
        "exit_code": exit_code,
        "run_dir": run_dir,
        "report": report,
        "summary_file": str(SUMMARY_FILE if SUMMARY_FILE.exists() else summary_file or ""),
        "result_json_file": str(RESULT_JSON_FILE),
        "compact_json_file": str(COMPACT_JSON_FILE),
        "bridge_stdout_tail": "" if ok else tail_text(stdout, 1200),
        "bridge_stderr_tail": "" if ok else tail_text(stderr, 1200),
        "message": (
            f"작업이 성공했습니다. 검증 명령이 정상 종료되었고 출력은 {test_output}입니다."
            if ok
            else "작업이 실패했습니다. latest_result.json 또는 final_report.md를 확인해야 합니다."
        ),
    }

    if result_text and result_text not in {"성공", "실패"}:
        compact["bridge_result"] = result_text

    return compact


def main() -> int:
    if len(sys.argv) < 3:
        print(
            "Usage: python3 scripts/hermes_bridge_json.py '<task>' '<test_cmd>'",
            file=sys.stderr,
        )
        return 2

    task = sys.argv[1]
    test_cmd = sys.argv[2]

    running_payload = {
        "ok": None,
        "result": "running",
        "task": task,
        "test_cmd": test_cmd,
        "test_output": "",
        "exit_code": None,
        "message": "작업을 실행 중입니다.",
    }
    write_state(running_payload)

    try:
        proc = subprocess.run(
            ["bash", str(BRIDGE_SH), task, test_cmd],
            cwd=str(ROOT),
            text=True,
            capture_output=True,
            timeout=120,
        )

        payload = build_success_or_failure_payload(
            task=task,
            test_cmd=test_cmd,
            proc=proc,
        )
        write_state(payload)
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 0 if payload.get("ok") is True else 1

    except subprocess.TimeoutExpired as exc:
        payload = {
            "ok": False,
            "result": "timeout",
            "task": task,
            "test_cmd": test_cmd,
            "test_output": "",
            "exit_code": None,
            "error": "bridge subprocess timeout",
            "bridge_stdout_tail": tail_text(exc.stdout if isinstance(exc.stdout, str) else ""),
            "bridge_stderr_tail": tail_text(exc.stderr if isinstance(exc.stderr, str) else ""),
            "message": "작업 시간이 초과되었습니다.",
        }
        write_state(payload)
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 124

    except KeyboardInterrupt:
        payload = {
            "ok": False,
            "result": "interrupted",
            "task": task,
            "test_cmd": test_cmd,
            "test_output": "",
            "exit_code": None,
            "error": "KeyboardInterrupt",
            "message": "작업이 사용자 중단으로 완료되지 않았습니다.",
        }
        write_state(payload)
        print(json.dumps(payload, ensure_ascii=False, indent=2))
        return 130


if __name__ == "__main__":
    raise SystemExit(main())
