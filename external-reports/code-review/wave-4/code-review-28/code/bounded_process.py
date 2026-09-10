"""POSIX reference process supervisor with finite time and transcript budgets.

It terminates only the process group it creates. This is not a Windows
replacement for the repository's existing taskkill-based implementation.
"""
from __future__ import annotations
import argparse
from dataclasses import dataclass
import math
import os
import signal
import subprocess
import threading
import time
from typing import Mapping, Sequence


def positive_finite_timeout(value: str | float) -> float:
    try:
        result = float(value)
    except (TypeError, ValueError) as exc:
        raise argparse.ArgumentTypeError("timeout must be a finite positive number") from exc
    if not math.isfinite(result) or result <= 0:
        raise argparse.ArgumentTypeError("timeout must be a finite positive number")
    return result


@dataclass(frozen=True)
class ProcessResult:
    outcome: str
    returncode: int | None
    output: str
    retained_bytes: int
    observed_bytes: int
    elapsed_seconds: float


def run_bounded(command: Sequence[str], *, timeout: float,
                max_output_bytes: int = 1048576, cwd: str | None = None,
                env: Mapping[str, str] | None = None) -> ProcessResult:
    timeout = positive_finite_timeout(timeout)
    if os.name != "posix":
        raise NotImplementedError("This supervisor is POSIX-only; use a Windows Job Object port")
    if not command or not all(isinstance(x, str) for x in command):
        raise ValueError("Pass a nonempty argument vector; no shell is used")
    if not isinstance(max_output_bytes, int) or max_output_bytes < 1:
        raise ValueError("max_output_bytes must be positive")
    started = time.monotonic()
    try:
        process = subprocess.Popen(list(command), cwd=cwd, env=env,
            stdout=subprocess.PIPE, stderr=subprocess.STDOUT, start_new_session=True)
    except OSError as exc:
        return ProcessResult("LaunchError", None, str(exc), 0, 0, time.monotonic()-started)
    saved = bytearray()
    count = [0]
    overflow = threading.Event()

    def consume() -> None:
        assert process.stdout is not None
        try:
            while True:
                chunk = process.stdout.read(8192)
                if not chunk:
                    return
                count[0] += len(chunk)
                room = max_output_bytes-len(saved)
                if room > 0:
                    saved.extend(chunk[:room])
                if count[0] > max_output_bytes:
                    overflow.set()
        finally:
            process.stdout.close()

    def stop_group() -> None:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass

    reader = threading.Thread(target=consume, daemon=True)
    reader.start()
    outcome = "Completed"
    try:
        while process.poll() is None:
            if overflow.is_set():
                outcome = "OutputLimit"
                stop_group()
                break
            if time.monotonic()-started >= timeout:
                outcome = "Timeout"
                stop_group()
                break
            time.sleep(min(0.01, timeout/10))
        process.wait(timeout=2)
        # A child may hold the inherited pipe open after its parent exits.
        reader.join(timeout=min(0.2, timeout))
        if reader.is_alive():
            if outcome == "Completed":
                outcome = "PipeHeldOpen"
            stop_group()
            reader.join(timeout=2)
        if reader.is_alive():
            raise RuntimeError("Reader did not stop after owned process-group termination")
        if overflow.is_set() and outcome == "Completed":
            outcome = "OutputLimit"
    except BaseException:
        stop_group()
        process.wait(timeout=2)
        reader.join(timeout=2)
        raise
    return ProcessResult(outcome, process.returncode, bytes(saved).decode("utf-8", "replace"),
                         len(saved), count[0], time.monotonic()-started)
