#!/usr/bin/env python3
import json
import os
import subprocess
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

ROOT = Path.home() / "hermes-coding-room"
LOG_DIR = ROOT / "logs"
MEMORY_DIR = ROOT / "memory"
JOBS_DIR = ROOT / "jobs"
JOBS_RUNNING_DIR = JOBS_DIR / "running"
JOBS_DONE_DIR = JOBS_DIR / "done"
JOBS_FAILED_DIR = JOBS_DIR / "failed"

LOG_DIR.mkdir(parents=True, exist_ok=True)
MEMORY_DIR.mkdir(parents=True, exist_ok=True)
JOBS_RUNNING_DIR.mkdir(parents=True, exist_ok=True)
JOBS_DONE_DIR.mkdir(parents=True, exist_ok=True)
JOBS_FAILED_DIR.mkdir(parents=True, exist_ok=True)

WORKER_LOG = LOG_DIR / "local_worker.log"
LATEST_JSON = MEMORY_DIR / "latest_result_compact.json"
LOCK_FILE = MEMORY_DIR / "local_worker.lock"

BLOCKED_PATTERNS = [
    "rm -rf",
    "sudo ",
    "shutdown",
    "reboot",
    "mkfs",
    ":(){",
    "chmod -R 777 /",
    "chown -R",
    "curl ",
    "wget ",
    "| sh",
    "| bash",
    "dd if=",
    "> /dev/sd",
]

HOST = "127.0.0.1"
PORT = 8787
LOCAL_HERMES_TOKEN = os.environ.get("LOCAL_HERMES_TOKEN", "")


def write_log(message: str):
    ts = time.strftime("%Y-%m-%d %H:%M:%S")
    with WORKER_LOG.open("a", encoding="utf-8") as f:
        f.write(f"[{ts}] {message}\n")


def find_blocked_pattern(value: str):
    lowered = value.lower()
    for pattern in BLOCKED_PATTERNS:
        if pattern.lower() in lowered:
            return pattern
    return None


def make_job_id(task: str) -> str:
    ts = time.strftime("%Y%m%d_%H%M%S")
    safe = "".join(ch if ch.isalnum() else "_" for ch in task[:40]).strip("_")
    if not safe:
        safe = "task"
    return f"job_{ts}_{safe[:40]}"


def json_response(handler, status_code: int, payload: dict):
    body = json.dumps(payload, ensure_ascii=False, indent=2).encode("utf-8")
    handler.send_response(status_code)
    handler.send_header("Content-Type", "application/json; charset=utf-8")
    handler.send_header("Content-Length", str(len(body)))
    handler.end_headers()
    handler.wfile.write(body)


class HermesWorkerHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            json_response(self, 200, {
                "ok": True,
                "message": "Local Hermes Worker is running",
                "root": str(ROOT),
                "latest_json_exists": LATEST_JSON.exists(),
                "busy": LOCK_FILE.exists(),
            })
            return

        if self.path == "/latest":
            if LATEST_JSON.exists():
                try:
                    payload = json.loads(LATEST_JSON.read_text(encoding="utf-8"))
                except Exception as e:
                    payload = {"ok": False, "error": f"failed to read latest json: {e}"}
                json_response(self, 200, payload)
            else:
                json_response(self, 404, {"ok": False, "error": "latest_result_compact.json not found"})
            return

        if self.path.startswith("/jobs"):
            jobs = []
            for status, directory in [
                ("running", JOBS_RUNNING_DIR),
                ("done", JOBS_DONE_DIR),
                ("failed", JOBS_FAILED_DIR),
            ]:
                for file in sorted(directory.glob("*.json"), key=lambda p: p.stat().st_mtime, reverse=True)[:20]:
                    try:
                        item = json.loads(file.read_text(encoding="utf-8"))
                        item.setdefault("status", status)
                        item.setdefault("file", str(file.relative_to(ROOT)))
                        jobs.append(item)
                    except Exception as e:
                        jobs.append({
                            "status": status,
                            "file": str(file.relative_to(ROOT)),
                            "error": f"failed to read job file: {e}",
                        })

            jobs = sorted(
                jobs,
                key=lambda item: item.get("finished_at") or item.get("created_at") or "",
                reverse=True
            )[:30]

            json_response(self, 200, {
                "ok": True,
                "count": len(jobs),
                "jobs": jobs,
            })
            return

        json_response(self, 404, {"ok": False, "error": "not found"})

    def do_POST(self):
        if LOCAL_HERMES_TOKEN:
            incoming_token = self.headers.get("X-Hermes-Token", "")
            if incoming_token != LOCAL_HERMES_TOKEN:
                json_response(self, 401, {"ok": False, "error": "unauthorized"})
                return

        if self.path != "/run-task":
            json_response(self, 404, {"ok": False, "error": "not found"})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(length).decode("utf-8")
            data = json.loads(raw) if raw.strip() else {}
        except Exception as e:
            json_response(self, 400, {"ok": False, "error": f"invalid json: {e}"})
            return

        task = str(data.get("task", "")).strip()
        test_cmd = str(data.get("test_cmd", "")).strip()

        if not task:
            json_response(self, 400, {"ok": False, "error": "task is required"})
            return

        blocked_in_task = find_blocked_pattern(task)
        blocked_in_test_cmd = find_blocked_pattern(test_cmd)

        if blocked_in_task or blocked_in_test_cmd:
            blocked = blocked_in_task or blocked_in_test_cmd
            write_log(f"BLOCKED dangerous pattern: {blocked}")
            json_response(self, 400, {
                "ok": False,
                "error": "blocked dangerous command",
                "blocked_pattern": blocked,
                "message": "위험할 수 있는 명령 패턴이 감지되어 작업을 실행하지 않았습니다."
            })
            return

        if LOCK_FILE.exists():
            json_response(self, 409, {
                "ok": False,
                "error": "worker busy",
                "message": "현재 Local Hermes Worker가 다른 작업을 실행 중입니다."
            })
            return

        if not test_cmd:
            test_cmd = "python3 -m py_compile workspace/*.py"

        job_id = make_job_id(task)
        running_job_file = JOBS_RUNNING_DIR / f"{job_id}.json"
        done_job_file = JOBS_DONE_DIR / f"{job_id}.json"
        failed_job_file = JOBS_FAILED_DIR / f"{job_id}.json"

        running_job_file.write_text(json.dumps({
            "job_id": job_id,
            "status": "running",
            "task": task,
            "test_cmd": test_cmd,
            "created_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        }, ensure_ascii=False, indent=2), encoding="utf-8")

        write_log("=" * 80)
        write_log(f"Received task job_id={job_id}")
        write_log(f"TASK: {task}")
        write_log(f"TEST_CMD: {test_cmd}")

        cmd = [
            "python3",
            str(ROOT / "scripts" / "hermes_bridge_json.py"),
            task,
            test_cmd,
        ]

        env = os.environ.copy()
        env["PYTHONUNBUFFERED"] = "1"

        started = time.time()
        LOCK_FILE.write_text(str(started), encoding="utf-8")

        try:
            proc = subprocess.run(
                cmd,
                cwd=str(ROOT),
                env=env,
                text=True,
                capture_output=True,
                timeout=900,
            )

            duration = round(time.time() - started, 2)
            write_log(f"bridge exit_code={proc.returncode}, duration={duration}s")
            write_log("STDOUT TAIL:")
            write_log(proc.stdout[-4000:])
            write_log("STDERR TAIL:")
            write_log(proc.stderr[-4000:])

            latest = {}
            if LATEST_JSON.exists():
                try:
                    latest = json.loads(LATEST_JSON.read_text(encoding="utf-8"))
                except Exception as e:
                    latest = {"ok": False, "error": f"failed to parse latest json: {e}"}

            response_payload = {
                "ok": proc.returncode == 0,
                "job_id": job_id,
                "exit_code": proc.returncode,
                "duration_sec": duration,
                "latest": latest,
                "stdout_tail": proc.stdout[-2000:],
                "stderr_tail": proc.stderr[-2000:],
            }

            final_job_payload = {
                "job_id": job_id,
                "status": "done" if proc.returncode == 0 else "failed",
                "task": task,
                "test_cmd": test_cmd,
                "duration_sec": duration,
                "exit_code": proc.returncode,
                "latest": latest,
                "finished_at": time.strftime("%Y-%m-%d %H:%M:%S"),
            }

            target_file = done_job_file if proc.returncode == 0 else failed_job_file
            target_file.write_text(json.dumps(final_job_payload, ensure_ascii=False, indent=2), encoding="utf-8")
            try:
                if running_job_file.exists():
                    running_job_file.unlink()
            except Exception as e:
                write_log(f"ERROR: failed to remove running job file: {e}")

            json_response(self, 200, response_payload)

        except subprocess.TimeoutExpired:
            write_log("ERROR: bridge timeout")
            payload = {
                "job_id": job_id,
                "status": "failed",
                "task": task,
                "test_cmd": test_cmd,
                "error": "bridge timeout",
                "finished_at": time.strftime("%Y-%m-%d %H:%M:%S"),
            }
            failed_job_file.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
            try:
                if running_job_file.exists():
                    running_job_file.unlink()
            except Exception as e:
                write_log(f"ERROR: failed to remove running job file: {e}")
            json_response(self, 504, {
                "ok": False,
                "job_id": job_id,
                "error": "bridge timeout",
            })
        except Exception as e:
            write_log(f"ERROR: {e}")
            try:
                payload = {
                    "job_id": job_id,
                    "status": "failed",
                    "task": task,
                    "test_cmd": test_cmd,
                    "error": str(e),
                    "finished_at": time.strftime("%Y-%m-%d %H:%M:%S"),
                }
                failed_job_file.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")
                if running_job_file.exists():
                    running_job_file.unlink()
            except Exception as inner:
                write_log(f"ERROR: failed to write failed job file: {inner}")
            json_response(self, 500, {
                "ok": False,
                "job_id": job_id,
                "error": str(e),
            })
        finally:
            try:
                if LOCK_FILE.exists():
                    LOCK_FILE.unlink()
            except Exception as e:
                write_log(f"ERROR: failed to remove lock file: {e}")

    def log_message(self, format, *args):
        write_log(f"HTTP {self.address_string()} {format % args}")


def main():
    write_log(f"Starting Local Hermes Worker on http://{HOST}:{PORT}")
    write_log(f"ROOT={ROOT}")
    server = HTTPServer((HOST, PORT), HermesWorkerHandler)
    print(f"Local Hermes Worker running: http://{HOST}:{PORT}")
    print(f"Root: {ROOT}")
    server.serve_forever()


if __name__ == "__main__":
    main()
