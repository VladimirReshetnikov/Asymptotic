"""Vendor selected ProveIt articles from an immutable Git revision.

Selection JSON contains repository_url, commit, optional docs_root, and articles.
The local checkout is an execution argument (--source-root), not attribution.
Each article contains a docs-relative tex, optional pdf, and optional extra_files;
other article metadata is retained verbatim. Top-level extra_files are also
docs-relative. Literal TeX dependencies are collected without executing TeX.

  python validation/vendor_proveit_articles.py vendor selection.json
  python validation/vendor_proveit_articles.py check
  python validation/vendor_proveit_articles.py check --source-root C:/ProveIt

The scanner understands literal input/include, graphics/graphicspath, bibliography,
and local package/class references. It conservatively scans conditional branches.
Macro-generated paths and import packages need explicit extra_files and review.
Unresolved required dependencies fail preflight unless --allow-unresolved is used.
Existing destination files with different bytes are never overwritten.
"""

from __future__ import annotations

import argparse
from bisect import bisect_right
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import posixpath
import re
import subprocess
import sys
from typing import Any
from urllib.parse import quote

from proveit_build_patches import prepare_patches


WORKSPACE = Path(__file__).resolve().parents[1]
DEFAULT_DESTINATION = WORKSPACE / "vendor" / "proveit"
DEFAULT_DOCS = "Analysis/FabiusFunction/docs"
REPOSITORY_URL = "https://github.com/VladimirReshetnikov/ProveIt"
MANIFEST_NAME = "manifest.json"
VERBATIM = {"verbatim", "Verbatim", "lstlisting", "minted", "comment", "filecontents", "filecontents*"}
RESOURCE_COMMANDS = {"input", "include", "includegraphics", "bibliography", "addbibresource",
                     "bibliographystyle", "usepackage", "RequirePackage", "documentclass", "LoadClass",
                     "lstinputlisting", "verbatiminput", "VerbatimInput", "includepdf"}
GRAPHICS_EXTENSIONS = (".pdf", ".png", ".jpg", ".jpeg", ".eps", ".mps")
TEX_DISTRIBUTION_EXTENSIONS = {".sty", ".cls", ".def", ".fd", ".cfg", ".clo", ".bst"}
DISCLAIMER = ("Sources and existing PDFs are preserved as independent upstream snapshots. "
              "No source/PDF synchronization, successful rebuild, or mathematical verification is asserted.")


class VendorError(RuntimeError):
    pass


def sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def io_path(path: Path) -> Path:
    """Use Windows extended paths without storing platform prefixes in manifests."""
    if os.name != "nt":
        return path
    name = str(path.absolute())
    if name.startswith("\\\\?\\"):
        return Path(name)
    return Path("\\\\?\\UNC\\" + name[2:] if name.startswith("\\\\") else "\\\\?\\" + name)


def relative_name(value: str) -> str:
    if not isinstance(value, str) or not value or "\x00" in value:
        raise VendorError(f"Invalid relative path: {value!r}")
    value = value.replace("\\", "/")
    path = PurePosixPath(value)
    if path.is_absolute() or any(part in {"..", "."} for part in path.parts) or ":" in value:
        raise VendorError(f"Path must be relative and stay within its root: {value!r}")
    return str(path)


def destination_file(root: Path, relative: str) -> Path:
    result = root / relative_name(relative)
    current = result
    while True:
        if io_path(current).is_symlink():
            raise VendorError(f"Refusing destination symlink: {current}")
        if current == root or current.parent == current:
            break
        current = current.parent
    return io_path(result)


class Source:
    def __init__(self, root: Path, commit: str, docs: str):
        self.root, self.docs = root.resolve(), relative_name(docs)
        if not re.fullmatch(r"[0-9a-fA-F]{40}|[0-9a-fA-F]{64}", commit):
            raise VendorError("commit must be a full immutable Git object ID")
        resolved = self.git("rev-parse", "--verify", commit + "^{commit}").decode().strip()
        if resolved.lower() != commit.lower():
            raise VendorError("The selected object is not the exact requested commit")
        self.commit = resolved
        self.entries: dict[str, tuple[str, str]] = {}
        for record in self.git("ls-tree", "-r", "-z", "--full-tree", self.commit).split(b"\0"):
            if not record:
                continue
            header, name = record.split(b"\t", 1)
            mode, kind, oid = header.decode("ascii").split()
            if kind == "blob":
                self.entries[name.decode("utf-8")] = (mode, oid)
        self.cache: dict[str, bytes] = {}

    def git(self, *arguments: str) -> bytes:
        environment = dict(os.environ, GIT_OPTIONAL_LOCKS="0")
        result = subprocess.run(["git", "-C", str(self.root), *arguments],
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                                env=environment, check=False)
        if result.returncode:
            raise VendorError(f"Read-only Git command failed: {' '.join(arguments)}\n"
                              + result.stderr.decode("utf-8", errors="replace"))
        return result.stdout

    def state(self) -> dict[str, str]:
        return {"head": self.git("rev-parse", "HEAD").decode().strip(),
                "docs_status_porcelain": self.git("status", "--porcelain=v1", "--untracked-files=all",
                                                   "--", self.docs).decode("utf-8", errors="replace")}

    def blob(self, path: str) -> bytes:
        if path not in self.entries:
            raise VendorError(f"File is absent from pinned Git tree: {path}")
        mode, oid = self.entries[path]
        if mode not in {"100644", "100755"}:
            raise VendorError(f"Refusing nonregular source blob {path} (mode {mode})")
        if path not in self.cache:
            value = self.git("cat-file", "blob", oid)
            digest = hashlib.sha1 if len(oid) == 40 else hashlib.sha256
            if digest(b"blob " + str(len(value)).encode() + b"\0" + value).hexdigest() != oid:
                raise VendorError(f"Git blob integrity mismatch: {path}")
            self.cache[path] = value
        return self.cache[path]

    def working_tree_record(self, path: str, raw: bytes) -> dict[str, Any]:
        local = io_path(self.root / path)
        if local.is_symlink():
            raise VendorError(f"Refusing source working-tree symlink: {path}")
        if not local.exists():
            return {"present": False}
        value = local.read_bytes()
        same, eol_same = value == raw, value.replace(b"\r\n", b"\n") == raw.replace(b"\r\n", b"\n")
        if not eol_same:
            raise VendorError(f"Source working-tree bytes differ substantively from the pinned blob: {path}")
        return {"present": True, "sha256": sha256(value), "size": len(value), "mtime_ns": local.stat().st_mtime_ns,
                "matches_git_blob": same, "difference": "none" if same else "CRLF/LF only"}


def mask_tex(text: str) -> str:
    """Mask comments, verbatim environments, and inline verb without shifting offsets."""
    output = list(text)
    position = 0
    control = re.compile(r"\\([A-Za-z@]+|.)")
    environment = re.compile(r"\s*\{([^{}]+)\}")
    while position < len(text):
        end = None
        if text[position] == "%":
            end = text.find("\n", position)
            if end < 0:
                end = len(text)
        elif text[position] == "\\":
            token = control.match(text, position)
            if token:
                command = token.group(1)
                after = token.end()
                if command == "verb":
                    if after < len(text) and text[after] == "*":
                        after += 1
                    if after < len(text):
                        close = text.find(text[after], after + 1)
                        end = len(text) if close < 0 else close + 1
                elif command == "begin":
                    match = environment.match(text, after)
                    if match and match.group(1) in VERBATIM:
                        marker = "\\end{" + match.group(1) + "}"
                        close = text.find(marker, match.end())
                        end = len(text) if close < 0 else close + len(marker)
                if end is None:
                    position = after
                    continue
        if end is not None:
            output[position:end] = ["\n" if character == "\n" else " " for character in text[position:end]]
            position = end
        else:
            position += 1
    return "".join(output)


def group_at(text: str, position: int, opening: str = "{", closing: str = "}") -> tuple[str | None, int]:
    while position < len(text) and text[position].isspace():
        position += 1
    if position >= len(text) or text[position] != opening:
        return None, position
    start, depth = position + 1, 1
    position += 1
    while position < len(text):
        character = text[position]
        if character == "\\":
            position += 2
            continue
        if character == opening:
            depth += 1
        elif character == closing:
            depth -= 1
            if not depth:
                return text[start:position], position + 1
        position += 1
    return None, position


def argument_at(text: str, position: int) -> tuple[str | None, int]:
    while position < len(text) and (text[position].isspace() or text[position] == "*"):
        position += 1
    while position < len(text) and text[position] == "[":
        _, position = group_at(text, position, "[", "]")
        while position < len(text) and text[position].isspace():
            position += 1
    return group_at(text, position)


class Collector:
    def __init__(self, source: Source):
        self.source = source
        self.files: dict[str, dict[str, Any]] = {}
        self.references: list[dict[str, Any]] = []
        self.issues: list[dict[str, Any]] = []
        self.active: set[tuple[str, str]] = set()

    def add(self, path: str, article: str, role: str) -> None:
        if PurePosixPath(path).name.lower() == "agents.md":
            raise VendorError(f"AGENTS.md is excluded from vendoring: {path}")
        if path.startswith(self.source.docs + "/archive/"):
            raise VendorError(f"Archived source is excluded from vendoring: {path}")
        self.source.blob(path)
        item = self.files.setdefault(path, {"articles": set(), "roles": set(), "article_roles": {}})
        item["articles"].add(article)
        item["roles"].add(role)
        item["article_roles"].setdefault(article, set()).add(role)

    def resolve(self, name: str, current: str, root: str, extensions: tuple[str, ...],
                graphics: list[str] | None = None) -> list[str]:
        names = [name] if PurePosixPath(name).suffix else [name, *(name + ext for ext in extensions)]
        directories = [root]
        if graphics is not None:
            directories += [posixpath.normpath(posixpath.join(root, item)) for item in graphics]
        directories.append(posixpath.dirname(current))
        found = []
        for directory in dict.fromkeys(directories):
            for candidate in names:
                path = posixpath.normpath(posixpath.join(directory, candidate))
                if path.startswith(self.source.docs + "/") and path in self.source.entries and path not in found:
                    found.append(path)
        return found

    def dependency(self, command: str, name: str | None, current: str, root: str,
                   graphics: list[str], article: str, line: int) -> None:
        reference: dict[str, Any] = {"article": article, "from": current, "line": line,
                                     "command": command, "requested": name}
        optional = command == "InputIfFileExists"
        package = command in {"usepackage", "RequirePackage", "documentclass", "LoadClass", "bibliographystyle"}
        if name is None or re.search(r"[\\#{}$~]|\A/|\A[A-Za-z]:", name):
            reference.update(status="dynamic_or_nonlocal", severity="error")
            self.issues.append(reference)
            return
        name = name.strip().strip('"')
        extension = {"bibliography": (".bib",), "addbibresource": (".bib",),
                     "bibliographystyle": (".bst",), "usepackage": (".sty",),
                     "RequirePackage": (".sty",), "documentclass": (".cls",), "LoadClass": (".cls",)}
        extensions = GRAPHICS_EXTENSIONS if command == "includegraphics" else (".pdf",) if command == "includepdf" else extension.get(command, (".tex",))
        found = self.resolve(name, current, root, extensions, graphics if command == "includegraphics" else None)
        if not found:
            external = package and "/" not in name
            reference.update(status="external_tex_distribution" if external else "optional_missing" if optional else "unresolved_literal",
                             severity="info" if external or optional else "error")
            (self.references if external else self.issues).append(reference)
            return
        if len(found) > 1:
            self.issues.append(dict(reference, status="multiple_candidates", severity="warning", candidates=found,
                                    resolution="Preserve every candidate; the first follows root/graphicspath search order."))
        reference.update(status="resolved", targets=found)
        self.references.append(reference)
        for path in found:
            self.add(path, article, command)
            if command in {"input", "include", "InputIfFileExists", "usepackage", "RequirePackage", "documentclass", "LoadClass"}:
                self.scan(path, root, graphics, article)

    def scan(self, path: str, root: str, graphics: list[str], article: str) -> None:
        key = path, article
        if key in self.active:
            self.issues.append({"article": article, "from": path, "status": "recursive_input", "severity": "warning"})
            return
        self.active.add(key)
        try:
            raw = self.source.blob(path)
            try:
                text = raw.decode("utf-8-sig")
            except UnicodeDecodeError:
                text = raw.decode("latin-1")
                self.issues.append({"article": article, "from": path, "status": "non_utf8_tex", "severity": "warning"})
            text = mask_tex(text)
            newlines = [match.start() for match in re.finditer("\n", text)]
            position = 0
            skipped: list[tuple[int, int]] = []
            token = re.compile(r"\\([A-Za-z@]+|.)")
            while match := token.search(text, position):
                inactive = next((end for start, end in skipped if start <= match.start() < end), None)
                if inactive is not None:
                    position = inactive
                    continue
                command, position = match.group(1), match.end()
                line = bisect_right(newlines, match.start()) + 1
                if command == "IfFileExists":
                    value, after = argument_at(text, position)
                    positive, positive_end = group_at(text, after)
                    negative, negative_end = group_at(text, positive_end)
                    if value is None or positive is None or negative is None or re.search(r"[\\#{}$~]|\A/|\A[A-Za-z]:", value):
                        self.issues.append({"article": article, "from": path, "line": line,
                                            "command": command, "status": "dynamic_file_condition",
                                            "severity": "error", "requested": value})
                        continue
                    name = value.strip()
                    found = self.resolve(name, path, root, (".tex",))
                    external = "/" not in name and PurePosixPath(name).suffix.lower() in TEX_DISTRIBUTION_EXTENSIONS
                    if found:
                        skipped.append((positive_end, negative_end))
                        for dependency in found:
                            self.add(dependency, article, "file_condition_probe")
                        self.references.append({"article": article, "from": path, "line": line,
                                                "command": command, "requested": value,
                                                "status": "local_file_condition_present", "targets": found})
                    elif external:
                        self.references.append({"article": article, "from": path, "line": line,
                                                "command": command, "requested": value,
                                                "status": "external_tex_distribution_condition",
                                                "resolution": "Scan both branches; installed TeX files are outside the pinned source tree."})
                    else:
                        skipped.append((after, positive_end))
                        self.issues.append({"article": article, "from": path, "line": line,
                                            "command": command, "requested": value,
                                            "status": "optional_missing", "severity": "info",
                                            "resolution": "Use the explicit absent-file branch; no missing asset was generated."})
                    position = after
                elif command == "graphicspath":
                    value, position = argument_at(text, position)
                    paths, cursor = [], 0
                    if value is not None:
                        while cursor < len(value):
                            item, cursor = group_at(value, cursor)
                            if item is None:
                                break
                            paths.append(item)
                    if not paths or any(re.search(r"[\\#{}$~]", item) for item in paths):
                        self.issues.append({"article": article, "from": path, "line": line,
                                            "status": "dynamic_graphicspath", "severity": "error", "requested": value})
                    else:
                        graphics[:] = paths
                elif command in RESOURCE_COMMANDS or command == "InputIfFileExists":
                    value, after = argument_at(text, position)
                    if value is None and command == "input":
                        bare = re.match(r"\s*([^\s{}\\]+)", text[position:])
                        if bare:
                            value, after = bare.group(1), position + bare.end()
                    position = after
                    names = value.split(",") if value and command in {"usepackage", "RequirePackage", "bibliography"} else [value]
                    for name in names:
                        self.dependency(command, name, path, root, graphics, article, line)
                elif command == "inputminted":
                    _, position = argument_at(text, position)
                    value, position = group_at(text, position)
                    self.dependency("lstinputlisting", value, path, root, graphics, article, line)
                elif command in {"import", "subimport", "inputfrom", "subinputfrom", "includefrom", "subincludefrom"}:
                    self.issues.append({"article": article, "from": path, "line": line,
                                        "status": "unsupported_import_command", "severity": "error", "command": command})
        finally:
            self.active.remove(key)

    def provenance_files(self, tex: str, article: str) -> None:
        package = posixpath.dirname(tex)
        ancestors = {package}
        current = package
        while current != self.source.docs and current.startswith(self.source.docs + "/"):
            current = posixpath.dirname(current)
            ancestors.add(current)
        for path in self.source.entries:
            if path.startswith(self.source.docs + "/archive/"):
                continue
            name = PurePosixPath(path).name.lower()
            if not (name in {"readme", "readme.md", "readme.txt", "readme.rst"} or name.startswith("corpus_audit")):
                continue
            if (package != self.source.docs and path.startswith(package + "/")) or posixpath.dirname(path) in ancestors:
                self.add(path, article, "upstream_provenance")


def build_receipts(manifest: dict[str, Any], destination: Path) -> dict[str, Any]:
    """Validate documented PDF replacements, preserving original manifest records."""
    path = destination_file(destination, "builds.json")
    if not path.exists():
        return {}
    builds = json.loads(path.read_bytes())
    if builds.get("schema_version") != 1 or not isinstance(builds.get("regenerated_pdfs"), dict):
        raise VendorError("builds.json must contain schema_version:1 and a regenerated_pdfs mapping")
    originals = {item["destination"]: item for item in manifest["files"]}
    articles: dict[str, list[dict[str, Any]]] = {}
    for article in manifest["articles"]:
        articles.setdefault(article["destination_pdf"], []).append(article)
    for relative, receipt in builds["regenerated_pdfs"].items():
        relative_name(relative)
        if relative not in articles or not relative.lower().endswith(".pdf"):
            raise VendorError(f"Build receipt names an unselected PDF: {relative}")
        for article in articles[relative]:
            expected_patches = prepare_patches(article, lambda name: destination_file(destination, name).read_bytes())[1]
            if receipt.get("source_patches", {}) != expected_patches:
                raise VendorError(f"Rebuilt PDF's source patch specification changed: {relative}")
        original = originals.get(relative)
        expected_original = original["sha256"] if original else None
        if "original_upstream_sha256" not in receipt or receipt["original_upstream_sha256"] != expected_original:
            raise VendorError(f"Build receipt lost original upstream PDF provenance: {relative}")
        source_inputs = receipt.get("source_inputs")
        if not isinstance(source_inputs, dict) or not source_inputs:
            raise VendorError(f"Build receipt needs hashed source_inputs: {relative}")
        required = {item for article in articles[relative] for item in article["dependencies"]}
        if missing := required - source_inputs.keys():
            raise VendorError(f"Build receipt omits compile dependencies for {relative}: {sorted(missing)}")
        for name, digest in source_inputs.items():
            item = destination_file(destination, name)
            if not item.is_file() or sha256(item.read_bytes()) != digest:
                raise VendorError(f"A rebuilt PDF's recorded source input changed: {name}")
        if not isinstance(receipt.get("tool_versions"), dict) or not receipt["tool_versions"]:
            raise VendorError(f"Build receipt needs tool_versions: {relative}")
        pdf_check = receipt.get("pdf_check")
        if (receipt.get("status") != "three passes and basic PDF validation succeeded" or
                not isinstance(pdf_check, dict) or type(pdf_check.get("page_count")) is not int or
                pdf_check["page_count"] < 1 or not isinstance(pdf_check.get("validator"), str) or
                not pdf_check["validator"].strip()):
            raise VendorError(f"Build receipt needs a successful PDF inspection with a positive page count: {relative}")
        logs = receipt.get("pass_logs")
        if (not isinstance(logs, list) or len(logs) != 3 or
                not all(isinstance(item, dict) for item in logs) or len({item["path"] for item in logs}) != 3):
            raise VendorError(f"Build receipt needs three distinct hashed pass_logs: {relative}")
        for number, log in enumerate(logs, 1):
            if (type(log.get("pass")) is not int or log["pass"] != number or
                    type(log.get("returncode")) is not int or log["returncode"] != 0 or
                    log.get("timed_out") is not False):
                raise VendorError(f"Build receipt needs successful, ordered passes 1, 2, and 3: {relative}")
            item = destination_file(destination, log["path"])
            if not item.is_file() or sha256(item.read_bytes()) != log["sha256"]:
                raise VendorError(f"A rebuilt PDF's pass log changed: {log['path']}")
        pdf = destination_file(destination, relative)
        if not pdf.is_file() or sha256(pdf.read_bytes()) != receipt.get("sha256"):
            raise VendorError(f"Rebuilt PDF changed or is missing: {relative}")
    return builds["regenerated_pdfs"]


def check_files(manifest: dict[str, Any], destination: Path, source: Source | None = None,
                receipts: dict[str, Any] | None = None) -> int:
    receipts = receipts or {}
    paths = set()
    for item in manifest["files"]:
        relative = relative_name(item["destination"])
        if relative in paths:
            raise VendorError(f"Duplicate destination in manifest: {relative}")
        paths.add(relative)
        path = destination_file(destination, relative)
        if not path.is_file():
            raise VendorError(f"Missing vendored file: {path}")
        data = path.read_bytes()
        receipt = receipts.get(relative)
        if receipt is not None:
            if sha256(data) != receipt["sha256"]:
                raise VendorError(f"Rebuilt PDF changed: {path}")
        elif sha256(data) != item["sha256"] or len(data) != item["size"]:
            raise VendorError(f"Vendored file changed: {path}")
        if item["sha256"] != item["git_blob_sha256"]:
            raise VendorError(f"Manifest copied/blob hashes disagree: {relative}")
        if receipt is None:
            digest = hashlib.sha1 if len(item["git_blob"]) == 40 else hashlib.sha256
            if digest(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest() != item["git_blob"]:
                raise VendorError(f"Vendored bytes disagree with the recorded Git object: {relative}")
        if source is not None:
            original = source.blob(item["source_path"])
            if source.entries[item["source_path"]][1] != item["git_blob"] or sha256(original) != item["sha256"] or (receipt is None and original != data):
                raise VendorError(f"Vendored file does not match the pinned source revision: {path}")
    return len(paths)


def vendor(selection_path: Path, destination: Path, allow_unresolved: bool, dry_run: bool = False,
           source_root: Path | None = None) -> dict[str, Any]:
    selection_bytes = selection_path.read_bytes()
    selection = json.loads(selection_bytes)
    source = Source(source_root or Path("C:/ProveIt"), selection["commit"], selection.get("docs_root", DEFAULT_DOCS))
    remote = source.git("remote", "get-url", "origin").decode().strip().rstrip("/").removesuffix(".git")
    if remote != REPOSITORY_URL or selection.get("repository_url", REPOSITORY_URL) != REPOSITORY_URL:
        raise VendorError("The source origin must match the online ProveIt repository attribution")
    def online(path: str, kind: str = "blob") -> str:
        return f"{REPOSITORY_URL}/{kind}/{source.commit}/" + quote(path, safe="/")
    before = source.state()
    if before["head"] != source.commit:
        raise VendorError("Source HEAD must equal the selected immutable commit before vendoring")
    if before["docs_status_porcelain"]:
        raise VendorError("Source docs must be clean before vendoring: " + before["docs_status_porcelain"])
    manifest_path = destination_file(destination, MANIFEST_NAME)
    receipts, originals = {}, {}
    if manifest_path.exists():
        old_manifest = json.loads(manifest_path.read_bytes())
        provenance = old_manifest["source_repository"]
        if provenance["commit"] != source.commit or provenance["docs_root"] != source.docs:
            raise VendorError("An existing vendor manifest must describe the same pinned source snapshot")
        receipts = build_receipts(old_manifest, destination)
        check_files(old_manifest, destination, source, receipts)
        originals = {item["destination"]: item for item in old_manifest["files"]}
    elif destination_file(destination, "builds.json").exists():
        raise VendorError("Build receipts require the original upstream vendor manifest")
    collector = Collector(source)
    articles = []
    for article in selection["articles"]:
        relative = relative_name(article["tex"])
        tex = source.docs + "/" + relative
        pdf_name = article.get("pdf", str(PurePosixPath(relative).with_suffix(".pdf")))
        pdf = None if pdf_name is None else source.docs + "/" + relative_name(pdf_name)
        collector.add(tex, relative, "article_source")
        if pdf is not None:
            collector.add(pdf, relative, "article_pdf_snapshot")
        collector.scan(tex, posixpath.dirname(tex), [], relative)
        collector.provenance_files(tex, relative)
        for extra in article.get("extra_files", []):
            collector.add(source.docs + "/" + relative_name(extra), relative, "explicit_companion")
        articles.append({"selection": article, "source_tex": tex, "source_pdf": pdf,
                         "source_tex_url": online(tex), "source_pdf_url": online(pdf) if pdf else None,
                         "destination_tex": "docs/" + relative,
                         "destination_pdf": "docs/" + (relative_name(pdf_name) if pdf_name is not None else str(PurePosixPath(relative).with_suffix(".pdf"))),
                         "upstream_pdf_status": "present" if pdf else "missing_by_selection"})
    if not articles:
        raise VendorError("Select at least one article")
    for extra in selection.get("extra_files", []):
        collector.add(source.docs + "/" + relative_name(extra), "shared", "explicit_companion")
    collector.add("LICENSE", "shared", "upstream_license")
    errors = [issue for issue in collector.issues if issue["severity"] == "error"]
    if errors and not allow_unresolved:
        raise VendorError("Unresolved dependencies; supply extra files and review with --allow-unresolved if intentional:\n"
                          + json.dumps(errors, ensure_ascii=False, indent=2))
    files, long_paths = [], []
    for path, roles in sorted(collector.files.items()):
        data = source.blob(path)
        if len(data) >= 100 * 1024 * 1024:
            raise VendorError(f"File reaches GitHub's 100 MiB per-file limit: {path} ({len(data)} bytes)")
        relative = "LICENSE" if path == "LICENSE" else "docs/" + path[len(source.docs) + 1:]
        target = destination_file(destination, relative)
        if target.exists() and (not target.is_file() or target.read_bytes() != data):
            original = originals.get(relative)
            if (relative not in receipts or original is None or original["source_path"] != path or
                    original["sha256"] != sha256(data)):
                raise VendorError(f"Refusing to overwrite changed destination bytes: {target}")
        if len(str(destination / relative)) >= 240:
            long_paths.append({"destination": relative, "absolute_characters": len(str(destination / relative)),
                               "classification": "Windows long-path handling required or near legacy limit"})
        files.append({"source_path": path, "destination": relative, "git_blob": source.entries[path][1],
                      "source_url": online(path),
                      "git_mode": source.entries[path][0], "sha256": sha256(data), "git_blob_sha256": sha256(data),
                      "size": len(data), "working_tree": source.working_tree_record(path, data),
                      "articles": sorted(roles["articles"]), "roles": sorted(roles["roles"]),
                      "article_roles": {name: sorted(values) for name, values in sorted(roles["article_roles"].items())}})
    for article in articles:
        identifier = article["selection"]["tex"]
        dependencies = [item for item in files if relative_name(identifier) in item["articles"] and
                        set(item["article_roles"][relative_name(identifier)]) - {"upstream_provenance", "article_pdf_snapshot"}]
        article["dependencies"] = [item["destination"] for item in dependencies]
        def latest(paths: list[str]) -> dict[str, str] | None:
            if not paths:
                return None
            record = source.git("log", "-1", "--format=%H%x00%cI", source.commit, "--", *paths).decode().strip()
            if not record:
                return None
            commit, date = record.split("\0", 1)
            return {"commit": commit, "committer_date": date}
        article["source_latest_change"] = latest([item["source_path"] for item in dependencies])
        article["pdf_latest_change"] = latest([article["source_pdf"]] if article["source_pdf"] else [])
        mtimes = [item["working_tree"].get("mtime_ns") for item in dependencies]
        article["source_mtime_complete"] = bool(mtimes) and all(value is not None for value in mtimes)
        article["source_latest_mtime_ns"] = max((value for value in mtimes if value is not None), default=None)
        article["pdf_mtime_ns"] = next((item["working_tree"].get("mtime_ns") for item in files
                                         if item["source_path"] == article["source_pdf"]), None)
    after = source.state()
    if after != before:
        raise VendorError("Source HEAD or docs status changed during the vendoring audit")
    manifest = {"schema_version": 1, "source_repository": {"url": REPOSITORY_URL, "commit": source.commit,
                 "commit_url": f"{REPOSITORY_URL}/commit/{source.commit}", "docs_url": online(source.docs, "tree"),
                 "docs_root": source.docs, "state_before": before, "state_after": after},
                "selection_sha256": sha256(selection_bytes), "selection": selection, "articles": articles,
                "files": files, "dependency_references": collector.references, "dependency_issues": collector.issues,
                "dependency_closure_complete": not errors, "long_paths": long_paths,
                "disclaimers": [DISCLAIMER, *selection.get("disclaimers", [])],
                "scanner_scope": "Literal TeX references, comments/verbatim masked, literal local IfFileExists guards resolved against the pinned tree. "
                                 "Other conditional branches are scanned conservatively. "
                                 "No macro expansion, TeX execution, or external TeX distribution vendoring."}
    summary = {"articles": len(articles), "files": len(files), "dependency_issues": len(collector.issues),
               "dependency_closure_complete": not errors, "long_paths": len(long_paths),
               "missing_upstream_pdfs": sum(article["source_pdf"] is None for article in articles),
               "total_bytes": sum(item["size"] for item in files), "largest_file_bytes": max(item["size"] for item in files),
               "manifest": str(destination / MANIFEST_NAME)}
    if receipts:
        receipts = build_receipts(manifest, destination)
    if dry_run:
        return dict(summary, dry_run=True, issues=collector.issues)
    for item in files:
        target = destination_file(destination, item["destination"])
        if not target.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            with target.open("xb") as stream:
                stream.write(source.blob(item["source_path"]))
    if source.state() != before:
        raise VendorError("Source HEAD or docs status changed during copying; destination files require review")
    encoded = (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8")
    temporary = destination_file(destination, MANIFEST_NAME + ".tmp")
    with temporary.open("xb") as stream:
        stream.write(encoded)
    temporary.replace(manifest_path)
    check_files(manifest, destination, source, receipts)
    return summary


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    create = commands.add_parser("vendor", help="Audit and copy pinned Git blobs")
    create.add_argument("selection", type=Path)
    create.add_argument("--source-root", type=Path, default=Path("C:/ProveIt"), help="Local checkout used only to read the online repository's pinned Git objects")
    create.add_argument("--destination", type=Path, default=DEFAULT_DESTINATION)
    create.add_argument("--allow-unresolved", action="store_true")
    create.add_argument("--dry-run", action="store_true", help="Audit without writing destination files")
    check = commands.add_parser("check", help="Validate copied bytes, optionally against the source Git repository")
    check.add_argument("--manifest", type=Path, default=DEFAULT_DESTINATION / MANIFEST_NAME)
    check.add_argument("--source-root", type=Path)
    args = parser.parse_args()
    if args.command == "vendor":
        destination = args.destination.absolute()
        if not destination.resolve().is_relative_to(WORKSPACE):
            raise VendorError("Destination must remain inside the current workspace")
        result = vendor(args.selection, destination, args.allow_unresolved, args.dry_run, args.source_root)
    else:
        manifest_path = args.manifest.absolute()
        manifest = json.loads(io_path(manifest_path).read_bytes())
        source = None
        if args.source_root is not None:
            provenance = manifest["source_repository"]
            source = Source(args.source_root, provenance["commit"], provenance["docs_root"])
        receipts = build_receipts(manifest, manifest_path.parent)
        pending = [article["destination_pdf"] for article in manifest["articles"] if
                   article["source_pdf"] is None and article["destination_pdf"] not in receipts]
        result = {"verified_files": check_files(manifest, manifest_path.parent, source, receipts),
                  "pinned_source_verified": source is not None,
                  "dependency_closure_complete": manifest["dependency_closure_complete"],
                  "verified_rebuilt_pdfs": len(receipts), "pending_pdfs": pending, "pdf_artifacts_complete": not pending}
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    try:
        main()
    except (VendorError, OSError, ValueError, KeyError, TypeError) as error:
        print(f"Vendoring audit failed: {error}", file=sys.stderr)
        raise SystemExit(1)
