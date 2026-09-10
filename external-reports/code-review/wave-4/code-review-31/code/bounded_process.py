"""POSIX prototype: bound a child process's time AND diagnostic bytes.

An output cap is a failure boundary, not silent successful truncation. This
prototype uses a new process group; it is not a security sandbox and does
not promise to contain deliberately daemonized or externally launched work.
Windows needs a separate tested job-object/process-tree implementation.
"""
from __future__ import annotations
import os
import selectors
import signal
import subprocess
import time
from collections.abc import Mapping, Sequence
from pathlib import Path
from runner_fixes import finite_positive_seconds


def bounded_run(command: Sequence[str], *, timeout: float = 30,
                max_output_bytes: int = 1048576,
                cwd: str | Path | None = None,
                env: Mapping[str, str] | None = None) -> dict:
    timeout = finite_positive_seconds(timeout)
    if os.name != "posix":
        raise NotImplementedError("This candidate process runner is POSIX-only")
    if not command or isinstance(command, (str, bytes)):
        raise ValueError("command must be a nonempty sequence, not shell text")
    if not isinstance(max_output_bytes, int) or isinstance(max_output_bytes, bool) or max_output_bytes < 1:
        raise ValueError("max_output_bytes must be a positive integer")
    started = time.monotonic()
    try:
        process = subprocess.Popen(list(command), cwd=cwd, env=env,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, start_new_session=True)
    except OSError as exc:
        return dict(Outcome="LaunchError", ExitCode=None, Output=str(exc),
                    ObservedOutputBytes=0, CapturedBytes=0, Truncated=False,
                    ElapsedSeconds=time.monotonic()-started)
    captured = bytearray(); observed = 0; outcome = None
    deadline = started + timeout

    def stop() -> None:
        try: os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError: pass
        if process.poll() is None: process.kill()

    assert process.stdout is not None
    try:
        os.set_blocking(process.stdout.fileno(), False)
        with selectors.DefaultSelector() as selector:
            selector.register(process.stdout, selectors.EVENT_READ)
            stream_open = True
            while stream_open or process.poll() is None:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    outcome = "Timeout"; stop(); break
                events = selector.select(min(remaining, .1))
                for key, _ in events:
                    chunk = os.read(key.fd, 65536)
                    if not chunk:
                        selector.unregister(key.fileobj); stream_open = False
                        continue
                    observed += len(chunk)
                    available = max_output_bytes-len(captured)
                    captured.extend(chunk[:available])
                    if len(chunk) > available:
                        outcome = "OutputLimit"; stop(); break
                if outcome is not None: break
        process.wait(timeout=5)
    except BaseException:
        stop(); process.wait(timeout=5)
        raise
    finally:
        process.stdout.close()
    if outcome is None: outcome = "Exited" if process.returncode == 0 else "ExitError"
    return dict(Outcome=outcome, ExitCode=process.returncode,
                Output=bytes(captured).decode("utf-8", errors="replace"),
                ObservedOutputBytes=observed, CapturedBytes=len(captured),
                Truncated=observed > len(captured), ElapsedSeconds=time.monotonic()-started)
