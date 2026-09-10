"""Regenerate stale vendored ProveIt PDFs, serially and without changing TeX.

  python validation/build_proveit_pdfs.py --list
  python validation/build_proveit_pdfs.py --article q_pochhammer
  python validation/build_proveit_pdfs.py --all-stale
  python validation/build_proveit_pdfs.py --all

Staleness uses both pinned Git change dates and recorded upstream working-tree
mtimes; copying files into the vendor directory does not affect that decision.
Each build uses a fresh short temporary mirror, exactly three pdflatex passes,
and a PDF structure check before replacing the vendored PDF. No BibTeX, index
builder, shell escape, source-repository write, or mathematical repair is run.
builds.json checkpoints successful artifacts and failed attempts for recovery.
Recorded warnings and PDF checks do not constitute visual or mathematical QA.
"""

from __future__ import annotations

import argparse
from datetime import datetime, timezone
import hashlib
import importlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time
from typing import Any
import uuid

from vendor_proveit_articles import (
    DEFAULT_DESTINATION, VendorError, destination_file, io_path, relative_name,
)
from proveit_build_patches import prepare_patches


class BuildError(RuntimeError):
    pass


def now() -> str:
    return datetime.now(timezone.utc).isoformat()


def digest(path: Path) -> str:
    with io_path(path).open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def write_json(path: Path, value: Any) -> None:
    target = io_path(path)
    target.parent.mkdir(parents=True, exist_ok=True)
    temporary = target.with_name(target.name + "." + uuid.uuid4().hex[:8] + ".tmp")
    temporary.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    temporary.replace(target)


def update_builds(root: Path, builds: dict[str, Any], mutate: Any) -> dict[str, Any]:
    """Apply one change to builds.json as a fresh-read merge under a lock.

    Two builders launched independently each hold their own snapshot of the
    ledger; writing a snapshot back atomically still discards the other
    builder's entries. The ledger is therefore re-read under an exclusive lock
    file, the change is applied to the fresh copy, and that copy is written;
    the caller's dictionary is updated to the written state (wave-5 report
    44 T04). A stale lock left by an interrupted builder is reported, not
    removed.
    """
    path = destination_file(root, "builds.json")
    lock = path.with_name(path.name + ".lock")
    deadline = time.monotonic() + 60
    while True:
        try:
            handle = os.open(lock, os.O_CREAT | os.O_EXCL | os.O_WRONLY)
            break
        except FileExistsError:
            if time.monotonic() > deadline:
                raise BuildError(f"Timed out waiting for {lock}; remove it only if no builder is running")
            time.sleep(0.2)
    try:
        os.write(handle, str(os.getpid()).encode("ascii"))
        os.close(handle)
        fresh = read_builds(root)
        mutate(fresh)
        write_json(path, fresh)
        builds.clear()
        builds.update(fresh)
        return builds
    finally:
        try:
            lock.unlink()
        except FileNotFoundError:
            pass


def read_builds(root: Path) -> dict[str, Any]:
    path = destination_file(root, "builds.json")
    data = json.loads(path.read_bytes()) if path.exists() else {"schema_version": 1, "regenerated_pdfs": {}}
    if data.get("schema_version") != 1 or not isinstance(data.get("regenerated_pdfs"), dict):
        raise BuildError("Unsupported builds.json schema")
    return data


def source_inputs(article: dict[str, Any], root: Path) -> dict[str, str]:
    names = set(article["dependencies"])
    names.add(article["destination_tex"])
    result = {}
    for name in sorted(names):
        path = destination_file(root, name)
        if not path.is_file():
            raise BuildError(f"Missing compile dependency: {name}")
        result[name] = digest(path)
    return result


def receipt_matches(receipt: Any, inputs: dict[str, str], root: Path, pdf: str,
                    original_hash: str | None) -> bool:
    if not isinstance(receipt, dict) or "original_upstream_sha256" not in receipt or receipt["original_upstream_sha256"] != original_hash:
        return False
    recorded = receipt.get("source_inputs", {})
    if not isinstance(recorded, dict) or any(recorded.get(k) != v for k, v in inputs.items()):
        return False
    logs = receipt.get("pass_logs", [])
    if not isinstance(logs, list) or len(logs) != 3 or not isinstance(receipt.get("tool_versions"), dict) or not receipt["tool_versions"]:
        return False
    for number, entry in enumerate(logs, 1):
        if not isinstance(entry, dict) or type(entry.get("pass")) is not int or entry["pass"] != number:
            return False
        if type(entry.get("returncode")) is not int or entry["returncode"] != 0 or entry.get("timed_out") is not False:
            return False
    pdf_check = receipt.get("pdf_check")
    if not isinstance(pdf_check, dict) or type(pdf_check.get("page_count")) is not int or pdf_check["page_count"] <= 0:
        return False
    if not isinstance(pdf_check.get("validator"), str) or not pdf_check["validator"].strip():
        return False
    if receipt.get("status") != "three passes and basic PDF validation succeeded":
        return False
    try:
        if len({entry["path"] for entry in logs}) != 3:
            return False
        checked = [*recorded.items(), *((entry["path"], entry["sha256"]) for entry in logs),
                   (pdf, receipt["sha256"])]
        return all(digest(destination_file(root, name)) == value for name, value in checked)
    except (OSError, KeyError, TypeError, VendorError):
        return False


def change_date(record: Any) -> datetime | None:
    try:
        value = datetime.fromisoformat(record["committer_date"].replace("Z", "+00:00"))
        return value if value.tzinfo else None
    except (TypeError, KeyError, ValueError, AttributeError):
        return None


def upstream_mtimes(inputs: dict[str, str], pdf: str,
                    originals: dict[str, Any]) -> dict[str, Any]:
    def recorded(name: str) -> int | None:
        record = originals.get(name, {}).get("working_tree", {})
        value = record.get("mtime_ns")
        return value if record.get("present") is True and type(value) is int and value >= 0 else None

    times = {name: recorded(name) for name in inputs}
    known = {name: value for name, value in times.items() if value is not None}
    latest = max(known.values(), default=None)
    return {"source_latest_mtime_ns": latest, "pdf_mtime_ns": recorded(pdf),
            "newest_inputs": [name for name, value in known.items() if value == latest],
            "missing_input_mtimes": [name for name, value in times.items() if value is None]}


def plan_article(article: dict[str, Any], root: Path, builds: dict[str, Any],
                 originals: dict[str, Any], force: bool) -> dict[str, Any]:
    pdf = article["destination_pdf"]
    original = originals.get(pdf, {}).get("sha256")
    inputs = source_inputs(article, root)
    receipt = builds["regenerated_pdfs"].get(pdf)
    _, patches = prepare_patches(article, lambda name: destination_file(root, name).read_bytes())
    matches = (receipt_matches(receipt, inputs, root, pdf, original)
               and receipt.get("source_patches", {}) == patches)
    reasons = []
    if force:
        reasons.append("explicit --all force")
    elif matches:
        return {"tex": article["destination_tex"], "pdf": pdf, "action": "skip",
                "reasons": ["current PDF, compile inputs, and three pass logs match the build receipt"]}
    if patches and not matches:
        reasons.append("declared compile-mirror source repairs lack a matching current build receipt")
    pdf_path = destination_file(root, pdf)
    if not pdf_path.is_file():
        reasons.append("PDF missing")
    elif receipt is not None and not matches:
        reasons.append("existing build receipt does not match the current PDF, inputs, or pass logs")
    elif original is None or digest(pdf_path) != original:
        reasons.append("current PDF has no matching upstream snapshot or verified build receipt")
    source_date, pdf_date = change_date(article.get("source_latest_change")), change_date(article.get("pdf_latest_change"))
    if source_date is None or pdf_date is None:
        reasons.append("Git compile-input/PDF change dates are unavailable; rebuild conservatively")
    elif source_date > pdf_date:
        reasons.append("latest Git change to compile dependencies is newer than the upstream PDF")
    mtimes = upstream_mtimes(inputs, pdf, originals)
    if mtimes["missing_input_mtimes"] or mtimes["pdf_mtime_ns"] is None:
        reasons.append("upstream working-tree compile-input/PDF mtimes are unavailable; rebuild conservatively")
    if mtimes["source_latest_mtime_ns"] is not None and mtimes["pdf_mtime_ns"] is not None and mtimes["source_latest_mtime_ns"] > mtimes["pdf_mtime_ns"]:
        reasons.append("newest upstream working-tree compile-input mtime is newer than the upstream PDF")
    return {"tex": article["destination_tex"], "pdf": pdf,
            "action": "build" if reasons else "preserve-upstream",
            "reasons": reasons or ["upstream PDF bytes match; neither Git changes nor upstream compile-input mtimes are newer"],
            "source_latest_change": article.get("source_latest_change"),
            "pdf_latest_change": article.get("pdf_latest_change"),
            "upstream_working_tree_mtimes": mtimes}


def run_capture(command: list[str], *, cwd: Path | None = None, timeout: int = 60,
                env: dict[str, str] | None = None) -> subprocess.CompletedProcess[bytes]:
    return subprocess.run(command, cwd=cwd, env=env, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, timeout=timeout, check=False)


def resolve_tools(pdflatex: str) -> tuple[str, dict[str, Any], Any]:
    executable = shutil.which(pdflatex)
    if executable is None:
        raise BuildError(f"pdflatex executable not found: {pdflatex}")
    result = run_capture([executable, "--version"])
    if result.returncode:
        raise BuildError("pdflatex --version failed")
    versions = {"pdflatex": result.stdout.decode("utf-8", errors="replace").strip(),
                "python": sys.version}
    try:
        reader = importlib.import_module("pypdf")
        versions["pypdf"] = reader.__version__
    except ImportError:
        reader = None
        for tool in ("pdfinfo", "pdffonts"):
            executable_tool = shutil.which(tool)
            if executable_tool is None:
                raise BuildError("Basic PDF validation needs pypdf or both Poppler pdfinfo and pdffonts")
            output = run_capture([executable_tool, "-v"])
            if output.returncode:
                raise BuildError(f"{tool} -v failed")
            versions[tool] = output.stdout.decode("utf-8", errors="replace").strip()
    return executable, versions, reader


def inspect_pdf(path: Path, reader: Any) -> dict[str, Any]:
    data = path.read_bytes()
    if not data.startswith(b"%PDF-") or b"%%EOF" not in data[-1024:]:
        raise BuildError("Generated output is not a complete PDF")
    if reader is not None:
        pdf = reader.PdfReader(path, strict=True)
        if pdf.is_encrypted or not len(pdf.pages):
            raise BuildError("Generated PDF is encrypted or has no pages")
        fonts, visited = set(), set()

        def collect_fonts(resources: Any) -> None:
            resources = resources.get_object() if hasattr(resources, "get_object") else resources
            if not resources or id(resources) in visited:
                return
            visited.add(id(resources))
            page_fonts = resources.get("/Font", {})
            page_fonts = page_fonts.get_object() if hasattr(page_fonts, "get_object") else page_fonts
            for reference in page_fonts.values():
                font = reference.get_object()
                fonts.add((str(font.get("/BaseFont", "unnamed")), str(font.get("/Subtype", "unknown"))))
            objects = resources.get("/XObject", {})
            objects = objects.get_object() if hasattr(objects, "get_object") else objects
            for reference in objects.values():
                collect_fonts(reference.get_object().get("/Resources", {}))

        for page in pdf.pages:
            if page.mediabox.width <= 0 or page.mediabox.height <= 0:
                raise BuildError("Generated PDF has an invalid page box")
            collect_fonts(page.get("/Resources", {}))
        return {"validator": "pypdf strict reader; all page boxes and page/form font resources inspected",
                "page_count": len(pdf.pages), "fonts": [{"name": a, "subtype": b} for a, b in sorted(fonts)],
                "size": len(data), "visual_review": "not performed by this build runner"}
    info = run_capture([shutil.which("pdfinfo"), str(path)])
    fonts = run_capture([shutil.which("pdffonts"), str(path)])
    page_match = re.search(rb"^Pages:\s*(\d+)\s*$", info.stdout, re.MULTILINE)
    if info.returncode or fonts.returncode or page_match is None or int(page_match[1]) < 1:
        raise BuildError("Poppler PDF validation failed")
    return {"validator": "Poppler pdfinfo and pdffonts", "page_count": int(page_match[1]),
            "pdfinfo": info.stdout.decode("utf-8", errors="replace"),
            "fonts": fonts.stdout.decode("utf-8", errors="replace"), "size": len(data),
            "visual_review": "not performed by this build runner"}


def warnings(log: str) -> dict[str, int]:
    def undefined(kind: str) -> int:
        return len(re.findall(r"(?:LaTeX|Package \S+) Warning:\s+" + kind +
                              r"\b(?:(?!\n\s*\n| Warning:).)*?\bundefined\b", log, re.DOTALL))

    return {
        "undefined_references": undefined("Reference"),
        "undefined_citations": undefined("Citation"),
        "undefined_reference_summary": len(re.findall(r"There were undefined references", log)),
        "undefined_citation_summary": len(re.findall(r"There were undefined citations", log)),
        "overfull_boxes": len(re.findall(r"Overfull \\[hv]box", log)),
        "underfull_boxes": len(re.findall(r"Underfull \\[hv]box", log)),
        "rerun_requests": len(re.findall(r"Rerun to get|Please rerun|Please \(re\)run", log, re.IGNORECASE)),
        "missing_characters": len(re.findall(r"Missing character:", log)),
        "warnings": len(re.findall(r"(?:LaTeX|Package \S+|Class \S+|pdfTeX) Warning", log)),
    }


def merge_pass_recorders(recorders: list[dict[str, Any]]) -> dict[str, Any]:
    """Union of per-pass recorder observations, with the per-pass records kept."""
    if not recorders:
        raise BuildError("No pdflatex pass produced a recorder observation")
    vendored = sorted({name for record in recorders for name in record["vendored_inputs"]})
    runtime: dict[str, str] = {}
    for record in recorders:
        for item in record["runtime_inputs"]:
            if runtime.setdefault(item["path"], item["sha256"]) != item["sha256"]:
                raise BuildError(f"Runtime input changed between passes: {item['path']}")
    return {"vendored_inputs": vendored,
            "runtime_inputs": [{"path": name, "sha256": runtime[name]} for name in sorted(runtime)],
            "pass_recorders": recorders}


def recorder_inputs(path: Path, mirror: Path, cwd: Path) -> dict[str, Any]:
    """Record actual TeX inputs separately from the conservative manifest closure."""
    local, runtime = set(), set()
    if not path.is_file():
        raise BuildError("pdflatex did not produce the required recorder file")
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.startswith("INPUT "):
            continue
        item = Path(line[6:].strip('"'))
        item = (item if item.is_absolute() else cwd / item).resolve()
        if not item.is_file():
            continue
        if item.is_relative_to(mirror / "docs"):
            local.add(item.relative_to(mirror).as_posix())
        elif not item.is_relative_to(mirror):
            runtime.add(str(item))
    return {"vendored_inputs": sorted(local),
            "runtime_inputs": [{"path": name, "sha256": digest(Path(name))} for name in sorted(runtime)]}


def build_one(article: dict[str, Any], plan: dict[str, Any], root: Path, manifest: dict[str, Any],
              builds: dict[str, Any], originals: dict[str, Any], options: argparse.Namespace,
              tools: tuple[str, dict[str, Any], Any]) -> None:
    executable, versions, reader = tools
    pdf_name = article["destination_pdf"]
    inputs = source_inputs(article, root)
    patched_bytes, patches = prepare_patches(article, lambda name: destination_file(root, name).read_bytes())
    attempt_id = uuid.uuid4().hex[:12]
    log_prefix = "build-logs/" + hashlib.sha256(pdf_name.encode()).hexdigest()[:12] + "-" + attempt_id
    logs_dir = destination_file(root, log_prefix)
    logs_dir.mkdir(parents=True, exist_ok=False)
    temp_base = options.temp_root.absolute()
    temp_base.mkdir(parents=True, exist_ok=True)
    mirror = Path(tempfile.mkdtemp(prefix="pv-", dir=temp_base)).resolve()
    attempt: dict[str, Any] = {"tex": article["destination_tex"], "pdf": pdf_name,
        "started_at": now(), "reasons": plan["reasons"], "source_inputs": inputs,
        "source_patches": patches,
        "source_commit": manifest["source_repository"]["commit"], "mirror": str(mirror),
        "tool_versions": versions, "commands": [], "pass_logs": []}
    succeeded = False
    try:
        for name, expected in inputs.items():
            original = originals.get(name)
            allowed_hash = builds["regenerated_pdfs"].get(name, {}).get("sha256", original and original["sha256"])
            if expected != allowed_hash:
                raise BuildError(f"Compile dependency differs from its upstream snapshot/build receipt: {name}")
            target = io_path(mirror / relative_name(name))
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(destination_file(root, name), target)
            if digest(target) != expected:
                raise BuildError(f"Mirror input hash mismatch: {name}")
        for name, data in patched_bytes.items():
            io_path(mirror / name).write_bytes(data)
        tex = mirror / article["destination_tex"]
        output = mirror / "out"
        output.mkdir()
        environment = dict(os.environ, TEXMFOUTPUT=str(output), openout_any="p")
        command = [executable, "-no-shell-escape", "-interaction=nonstopmode", "-halt-on-error",
                   "-file-line-error", "-recorder", "-output-directory=" + str(output), tex.name]
        pass_recorders: list[dict[str, Any]] = []
        for number in range(1, 4):
            print(json.dumps({"article": pdf_name, "pass": number, "status": "running"}), flush=True)
            source_log = output / (tex.stem + ".log")
            source_log.unlink(missing_ok=True)
            started = time.monotonic()
            timed_out = False
            try:
                result = run_capture(command, cwd=tex.parent, timeout=options.timeout, env=environment)
                console, returncode = result.stdout, result.returncode
            except subprocess.TimeoutExpired as error:
                console, returncode, timed_out = error.stdout or b"", None, True
            console_name = f"{log_prefix}/pass-{number}.stdout.txt"
            destination_file(root, console_name).write_bytes(console)
            log_bytes = source_log.read_bytes() if source_log.is_file() else b""
            log_name = f"{log_prefix}/pass-{number}.log"
            destination_file(root, log_name).write_bytes(log_bytes)
            pass_record = {"path": log_name, "sha256": digest(destination_file(root, log_name)),
                "console_path": console_name, "console_sha256": digest(destination_file(root, console_name)),
                "pass": number, "returncode": returncode, "timed_out": timed_out,
                "elapsed_seconds": round(time.monotonic() - started, 3),
                "warning_counts": warnings(log_bytes.decode("utf-8", errors="replace"))}
            attempt["commands"].append({"argv": command, "cwd": str(tex.parent),
                                       "environment_overrides": {"TEXMFOUTPUT": str(output), "openout_any": "p"}})
            attempt["pass_logs"].append(pass_record)
            write_json(logs_dir / "attempt.json", attempt)
            if timed_out or returncode != 0 or not log_bytes:
                raise BuildError(f"pdflatex pass {number} {'timed out' if timed_out else 'failed'}; see {console_name}")
            # Each pass overwrites the recorder file, and an input read only
            # by an earlier pass (a stale .aux, a table generated once) would
            # be lost by reading the last file alone; capture every pass and
            # keep the union for provenance (wave-5 report 44 T03).
            pass_recorders.append({"pass": number, **recorder_inputs(output / (tex.stem + ".fls"), mirror, tex.parent)})
        generated = output / (tex.stem + ".pdf")
        pdf_check = inspect_pdf(generated, reader)
        recorder = merge_pass_recorders(pass_recorders)
        if unexpected := set(recorder["vendored_inputs"]) - inputs.keys():
            raise BuildError(f"Recorder found inputs outside the declared compile closure: {sorted(unexpected)}")
        if source_inputs(article, root) != inputs:
            raise BuildError("Vendored compile inputs changed during the build")
        if prepare_patches(article, lambda name: destination_file(root, name).read_bytes())[1] != patches:
            raise BuildError("Article build patches changed during the build")
        receipt = {**attempt, "completed_at": now(), "sha256": digest(generated),
            "original_upstream_sha256": originals.get(pdf_name, {}).get("sha256"),
            "pdf_check": pdf_check, "recorder": recorder,
            "warning_counts": attempt["pass_logs"][-1]["warning_counts"],
            "status": "three passes and basic PDF validation succeeded"}
        target = destination_file(root, pdf_name)
        target.parent.mkdir(parents=True, exist_ok=True)
        staged = target.with_name(target.name + "." + attempt_id + ".tmp")
        shutil.copyfile(generated, staged)
        if digest(staged) != receipt["sha256"]:
            raise BuildError("Staged PDF hash does not match the validated output")
        staged.replace(target)

        def record_success(ledger: dict[str, Any]) -> None:
            ledger["regenerated_pdfs"][pdf_name] = receipt
            ledger.setdefault("failed_builds", {}).pop(pdf_name, None)

        update_builds(root, builds, record_success)
        write_json(logs_dir / "attempt.json", receipt)
        succeeded = True
        print(json.dumps({"article": pdf_name, "status": "rebuilt", "sha256": receipt["sha256"],
                          "pages": pdf_check["page_count"], "warnings": receipt["warning_counts"]}), flush=True)
    except BaseException as error:
        attempt.update(failed_at=now(), status="failed", error=str(error))
        write_json(logs_dir / "attempt.json", attempt)
        update_builds(root, builds, lambda ledger: ledger.setdefault("failed_builds", {}).__setitem__(pdf_name, attempt))
        raise
    finally:
        # Only the newly allocated, resolved child of the explicit temporary root
        # may be removed. Failed mirrors remain available for diagnosis/recovery.
        if succeeded and not options.keep_temp and mirror.parent == temp_base.resolve() and mirror.name.startswith("pv-"):
            shutil.rmtree(io_path(mirror))


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_DESTINATION / "manifest.json")
    parser.add_argument("--list", action="store_true", help="Print the plan without tools, builds, or writes")
    parser.add_argument("--article", action="append", default=[], help="Select a TeX path or case-insensitive path/title substring; repeatable")
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--all-stale", action="store_true", help="Build missing/stale/unverified PDFs (default)")
    mode.add_argument("--all", action="store_true", help="Force three passes even for a current receipt")
    parser.add_argument("--pdflatex", default="pdflatex")
    parser.add_argument("--temp-root", type=Path, default=Path("C:/Temp") if os.name == "nt" else Path(tempfile.gettempdir()))
    parser.add_argument("--timeout", type=int, default=600, help="Seconds allowed for each pdflatex pass")
    parser.add_argument("--keep-temp", action="store_true", help="Also preserve successful temporary mirrors")
    args = parser.parse_args()
    if args.timeout <= 0:
        raise BuildError("--timeout must be positive")
    manifest_path = args.manifest.absolute()
    root = manifest_path.parent.resolve()
    manifest = json.loads(io_path(manifest_path).read_bytes())
    if manifest.get("schema_version") != 1:
        raise BuildError("Unsupported vendor manifest schema")
    source_root = manifest["source_repository"].get("root")
    if source_root and (root.is_relative_to(Path(source_root).resolve()) or args.temp_root.resolve().is_relative_to(Path(source_root).resolve())):
        raise BuildError("The vendor/build roots must be outside the read-only source repository")
    originals = {item["destination"]: item for item in manifest["files"]}
    articles = manifest["articles"]
    chosen = []
    for query in args.article:
        query = query.replace("\\", "/").casefold()
        matches = [a for a in articles if query in (a["destination_tex"] + " " + str(a.get("selection", {}).get("title", ""))).casefold()]
        if not matches:
            raise BuildError(f"No selected article matches: {query}")
        chosen.extend(matches)
    selected = {a["destination_pdf"]: a for a in (chosen if args.article else articles)}
    builds = read_builds(root)
    plans = [plan_article(a, root, builds, originals, args.all) for a in selected.values()]
    print(json.dumps({"manifest": str(manifest_path), "force": args.all, "articles": plans,
                      "build_count": sum(p["action"] == "build" for p in plans)}, ensure_ascii=False, indent=2), flush=True)
    if args.list or not any(p["action"] == "build" for p in plans):
        return 0
    tools = resolve_tools(args.pdflatex)
    for article in selected.values():
        plan = plan_article(article, root, builds, originals, args.all)
        if plan["action"] == "build":
            build_one(article, plan, root, manifest, builds, originals, args, tools)
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (BuildError, VendorError, OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print(f"PDF build failed: {error}", file=sys.stderr)
        raise SystemExit(1)
