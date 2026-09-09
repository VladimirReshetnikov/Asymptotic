"""Check a standalone build in fresh native kernels, without the full suite.

By default test isolated local and HTTP files, modular entry points, Needs,
reloads, and a failed HTTP fetch. --url tests a published artifact instead.
"""

from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import threading
from urllib.request import urlopen

from build_standalone import ROOT, TARGET, build


def check(url: str | None, output: Path) -> dict:
    artifact = build(check=True)
    tracked = [TARGET, ROOT / "validation/build_standalone.py",
               ROOT / "validation/CheckStandalone.wl", Path(__file__).resolve()]

    def fingerprints():
        return {str(p.relative_to(ROOT)).replace("\\", "/"):
                hashlib.sha256(p.read_bytes()).hexdigest() for p in tracked}

    tested_sources = fingerprints()

    def remote_fingerprint():
        if not url:
            return None
        with urlopen(url, timeout=60) as response:
            data = response.read()
        digest = hashlib.sha256(data).hexdigest()
        if data != TARGET.read_bytes():
            raise RuntimeError(f"Published artifact differs from the tested local build: {digest}")
        return digest

    remote_before = remote_fingerprint()
    results: list[dict] = []
    with tempfile.TemporaryDirectory(prefix="asymptotic isolated loading ") as temporary:
        work = Path(temporary)
        serving = work / "only the standalone file"
        serving.mkdir()
        isolated = serving / TARGET.name
        shutil.copyfile(TARGET, isolated)
        requests: list[str] = []

        class Handler(SimpleHTTPRequestHandler):
            def do_GET(self):
                requests.append(self.path)
                super().do_GET()

            def log_message(self, *_):
                pass

        server = ThreadingHTTPServer(("127.0.0.1", 0), partial(Handler, directory=str(serving)))
        worker = threading.Thread(target=server.serve_forever, daemon=True)
        worker.start()
        origin = f"http://127.0.0.1:{server.server_port}"
        cases = [("published", "Get", url, "")] if url else [
            ("isolated-local", "Get", str(isolated), ""),
            ("isolated-http", "Get", origin + "/AsymptoticInverse.wl", ""),
            ("modular", "Get", str(ROOT / "AsymptoticInverse/Kernel/AsymptoticInverse.wl"), ""),
            ("modular-init", "Get", str(ROOT / "AsymptoticInverse/Kernel/init.m"), ""),
            ("needs", "Needs", str(isolated), str(serving)),
            ("missing-http", "Missing", origin + "/missing.wl", ""),
        ]
        try:
            for name, mode, source, search_path in cases:
                print(f"Checking {name}: {source}", flush=True)
                report = work / f"{name}.json"
                env = dict(os.environ, ASYMPTOTIC_LOAD_SOURCE=source,
                           ASYMPTOTIC_LOAD_MODE=mode, ASYMPTOTIC_LOAD_RESULT=str(report),
                           ASYMPTOTIC_LOAD_PATH=search_path)
                for key in list(env):
                    if key.upper() in {"WOLFRAMINIT", "MATHKERNELINIT"}:
                        del env[key]
                run = subprocess.run(["wolfram.exe", "-noinit", "-script", str(ROOT / "validation/CheckStandalone.wl")],
                                     cwd=work, env=env, capture_output=True, text=True,
                                     encoding="utf-8", errors="replace", timeout=180)
                print(run.stdout.strip(), flush=True)
                if not report.exists():
                    raise RuntimeError(f"{name} did not produce a report: {run.stdout}\n{run.stderr}")
                result = json.loads(report.read_text(encoding="utf-8"))
                result.update(Case=name, ExitCode=run.returncode)
                # Replace ephemeral fixture paths in the durable evidence.
                result["Source"] = url if url else name
                results.append(result)
                if run.returncode or result["Failed"]:
                    raise RuntimeError(f"{name} failed: {json.dumps(result)}")
        finally:
            server.shutdown()
            server.server_close()
            worker.join()
        if not url:
            if requests != ["/AsymptoticInverse.wl", "/AsymptoticInverse.wl", "/missing.wl"]:
                raise RuntimeError(f"Unexpected HTTP fixture requests: {requests}")
        fixture_files = sorted(p.name for p in serving.iterdir())
        if fixture_files != [TARGET.name] or isolated.read_bytes() != TARGET.read_bytes():
            raise RuntimeError("The isolated single-file fixture changed during validation")
    remote_after = remote_fingerprint()
    if fingerprints() != tested_sources:
        raise RuntimeError("Tested source files changed during validation")
    result = {"Artifact": artifact, "FullPackageSuiteRun": False,
              "KernelInitializationDisabled": True, "InitializationEnvironmentCleared": True,
              "PackageAbsentBeforeEachLoad": True, "TestedSourcesSHA256": tested_sources,
              "SourcesUnchangedDuringRun": True,
              "RemoteSHA256Before": remote_before, "RemoteSHA256After": remote_after,
              "FreshKernelRuns": len(results), "Results": results,
              "Succeeded": sum(r["Succeeded"] for r in results),
              "Failed": sum(r["Failed"] for r in results),
              "HTTPFixtureRequests": requests,
              "IsolatedFixtureFiles": fixture_files,
              "HTTPFixtureHasNoCompanionFiles": True if not url else None}
    output.write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Passed {result['Succeeded']} checks in {len(results)} fresh kernels; report: {output}")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--url")
    parser.add_argument("--output", type=Path, default=ROOT / "validation/standalone-loading-tests.json")
    args = parser.parse_args()
    check(args.url, args.output)
