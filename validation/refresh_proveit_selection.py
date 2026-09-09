"""Preview or apply a conservative metadata-only ProveIt source repin.

An explicit full --commit and --source-root are required. The source HEAD must
equal that commit and its docs must be clean both before and after preparation.
Dry-run is the default; --apply writes only selection.json and the two reading
lists. No source, vendored document, manifest, or build receipt is modified.
Authored provenance uses commit-pinned GitHub URLs; --source-root is only the
local execution checkout and is not recorded as provenance.

Evidence text is never rewritten. Unique exact matches may move; repeated text
needs a unique unchanged context from the previous vendored source. Missing,
changed, or ambiguous evidence prevents every metadata write.
"""

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from copy import deepcopy
from difflib import SequenceMatcher
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import sys
import tempfile
from typing import Any
from urllib.parse import quote

sys.dont_write_bytecode = True
from vendor_proveit_articles import (
    DEFAULT_DESTINATION, Source, VendorError, io_path, mask_tex, relative_name,
)


METADATA = ("selection.json", "q-reading-list.json", "combinatorial-reading-list.json")
REPOSITORY_URL = "https://github.com/VladimirReshetnikov/ProveIt"
DRAFTS = "semi-formalized-research-frontiers/drafts/"
ATLAS = DRAFTS + "thue-morse/Thue_Morse_Atlas_and_Frontiers/Thue_Morse_Atlas_and_Frontiers.tex"
DIAGONAL_ROOTS = {
    DRAFTS + "thue-morse/" + directory + "/thue_morse_diagonal_polynomials.tex"
    for directory in (
        "thue_morse_diagonal_polynomials", "thue_morse_diagonal_polynomials-2",
        "thue_morse_diagonal_polynomials_article_and_code",
    )
}
Q_MASTER = DRAFTS + "exponents-and-q-series/q_pochhammer_q_binomial_monograph/q_pochhammer_q_binomial_monograph.tex"
ATLAS_NOTE = ("The consolidated diagonal-polynomial material is retained in Part III of this atlas; "
              "the three former standalone report roots were deleted upstream.")


class RefreshError(RuntimeError):
    def __init__(self, message: str, **details: Any):
        super().__init__(message)
        self.details = details


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def encoded(value: Any) -> bytes:
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode("utf-8")


def checked_commit(value: str) -> str:
    if not isinstance(value, str) or not re.fullmatch(r"[0-9a-fA-F]{40}|[0-9a-fA-F]{64}", value):
        raise RefreshError("An explicit full immutable commit ID is required", commit=value)
    return value.lower()


def source_url(commit: str, docs: str) -> str:
    return REPOSITORY_URL + "/tree/" + checked_commit(commit) + "/" + quote(relative_name(docs), safe="/")


def clean_state(source: Source) -> dict[str, str]:
    state = source.state()
    if state.get("head", "").lower() != source.commit.lower():
        raise RefreshError("Source HEAD does not equal the requested pin", pin=source.commit, state=state)
    if state.get("docs_status_porcelain") != "":
        raise RefreshError("Source docs must be clean before metadata can be refreshed", state=state)
    return state


class LineMap:
    """Locate exact line sequences, using unchanged context only if needed."""

    def __init__(self, old: str, new: str):
        self.old, self.new = old.splitlines(), new.splitlines()
        self.positions: dict[str, list[int]] = defaultdict(list)
        for index, line in enumerate(self.new):
            self.positions[line].append(index)
        self.blocks = None

    def occurrences(self, expected: list[str], limit: int | None = None) -> list[int]:
        result = []
        for start in self.positions.get(expected[0], []):
            if start + len(expected) <= len(self.new) and self.new[start + len(expected) - 1] == expected[-1] and self.new[start:start + len(expected)] == expected:
                result.append(start)
                if limit is not None and len(result) >= limit:
                    break
        return result

    def locate(self, line: int, text: str) -> tuple[int, str]:
        if type(line) is not int or line < 1 or not isinstance(text, str) or not text:
            raise RefreshError("Evidence requires a positive line number and nonempty exact text")
        expected = text.split("\n")
        start, end = line - 1, line - 1 + len(expected)
        if self.old[start:end] != expected:
            raise RefreshError("Evidence does not match the previous source at its recorded line", line=line,
                               expected=text, actual="\n".join(self.old[start:end]))
        if self.old == self.new:
            return line, "unchanged-file"
        matches = self.occurrences(expected)
        if not matches:
            raise RefreshError("Evidence text changed or disappeared upstream; manual review is required", line=line, source=text)
        if len(matches) == 1:
            return matches[0] + 1, "unique-exact-text"
        if self.blocks is None:
            # Frequent blank lines are excluded as seeds, then extended normally.
            # A chosen block alone is insufficient: its full context must be unique.
            self.blocks = SequenceMatcher(None, self.old, self.new, autojunk=True).get_matching_blocks()
        for block in self.blocks:
            if block.a <= start and end <= block.a + block.size:
                context = self.old[block.a:block.a + block.size]
                if self.occurrences(context, limit=2) == [block.b]:
                    result = block.b + start - block.a
                    if result in matches:
                        return result + 1, "unique-unchanged-context"
        raise RefreshError("Evidence has multiple exact matches without unique unchanged context", line=line,
                           candidate_lines=[position + 1 for position in matches], source=text)


class Refresh:
    def __init__(self, vendor_root: Path, source_root: Path, commit: str):
        self.vendor_root = vendor_root.resolve()
        self.source_root = source_root.resolve()
        if self.vendor_root.is_relative_to(self.source_root):
            raise RefreshError("Metadata destination must remain outside the upstream source repository")
        self.commit = checked_commit(commit)
        self.original_bytes: dict[str, bytes] = {}
        self.documents: dict[str, dict[str, Any]] = {}
        for name in METADATA:
            raw = io_path(self.vendor_root / name).read_bytes()
            value = json.loads(raw.decode("utf-8"))
            if not isinstance(value, dict):
                raise RefreshError("Metadata must be a JSON object", file=name)
            self.original_bytes[name], self.documents[name] = raw, value
        self.selection = self.documents["selection.json"]
        self.old_commit = checked_commit(self.selection.get("commit"))
        for name, document in self.documents.items():
            for key in ("commit", "source_commit"):
                if key in document and checked_commit(document[key]) != self.old_commit:
                    raise RefreshError("Metadata source pins disagree", file=name, field=key, value=document[key])
            if "initial_audit_commit" in document:
                checked_commit(document["initial_audit_commit"])
        self.docs_name = relative_name(self.selection["docs_root"])
        self.source = Source(self.source_root, self.commit, self.docs_name)
        self.before = clean_state(self.source)
        self.previous_source = None
        self.current_text: dict[str, str] = {}
        self.maps: dict[str, LineMap] = {}
        self.methods: Counter[str] = Counter()
        self.line_changes: list[dict[str, Any]] = []
        self.errors: list[dict[str, Any]] = []
        self.prepared = False

    def exists(self, relative: str) -> bool:
        entry = self.source.entries.get(self.docs_name + "/" + relative_name(relative))
        if entry is not None and entry[0] not in {"100644", "100755"}:
            raise RefreshError("Referenced upstream path is not a regular file", path=relative, mode=entry[0])
        return entry is not None

    def text(self, relative: str) -> str:
        relative = relative_name(relative)
        if relative not in self.current_text:
            if not self.exists(relative):
                raise RefreshError("Referenced source is absent from the new pin", path=relative)
            self.current_text[relative] = self.source.blob(self.docs_name + "/" + relative).decode("utf-8")
        return self.current_text[relative]

    def line_map(self, relative: str) -> LineMap:
        relative = relative_name(relative)
        if relative not in self.maps:
            previous = io_path(self.vendor_root / "docs" / relative)
            if previous.is_file():
                old = previous.read_text(encoding="utf-8")
            else:
                # Excluded roots are deliberately not vendored. Recover their
                # previous exact text from the prior immutable metadata pin.
                if self.previous_source is None:
                    self.previous_source = Source(self.source_root, self.old_commit, self.docs_name)
                old = self.previous_source.blob(self.docs_name + "/" + relative).decode("utf-8")
            self.maps[relative] = LineMap(old, self.text(relative))
        return self.maps[relative]

    def anchor(self, entry: dict[str, Any], document: str, pointer: str) -> None:
        path = relative_name(entry.get("path"))
        fields = [field for field in ("source", "source_excerpt") if field in entry]
        if not fields:
            raise RefreshError("Evidence has no exact source text", path=path)
        results = [self.line_map(path).locate(entry.get("line"), entry[field]) for field in fields]
        if len({line for line, _ in results}) != 1:
            raise RefreshError("Evidence source and source_excerpt map to different locations", path=path)
        line, method = results[0]
        self.methods[method] += 1
        if line != entry["line"]:
            self.line_changes.append({"document": document, "pointer": pointer, "path": path,
                                      "old_line": entry["line"], "new_line": line, "method": method})
            entry["line"] = line

    def walk_evidence(self, value: Any, document: str, pointer: str = "") -> None:
        if isinstance(value, dict):
            for key, child in value.items():
                where = pointer + "/" + key
                if key == "evidence":
                    if not isinstance(child, list):
                        self.errors.append({"document": document, "pointer": where, "message": "evidence must be a list"})
                        continue
                    for index, entry in enumerate(child):
                        location = where + "/" + str(index)
                        try:
                            if not isinstance(entry, dict):
                                raise RefreshError("Evidence entry must be an object")
                            self.anchor(entry, document, location)
                        except (RefreshError, VendorError) as exc:
                            self.errors.append({"document": document, "pointer": location, "message": str(exc),
                                                **getattr(exc, "details", {})})
                else:
                    self.walk_evidence(child, document, where)
        elif isinstance(value, list):
            for index, child in enumerate(value):
                self.walk_evidence(child, document, pointer + "/" + str(index))

    def q_inputs(self) -> None:
        name = "q-reading-list.json"
        for index, entry in enumerate(self.documents[name].get("qMonographDirectInputs", [])):
            try:
                mapping = self.line_map(Q_MASTER)
                previous = entry["masterLine"]
                if type(previous) is not int or not 1 <= previous <= len(mapping.old):
                    raise RefreshError("Invalid recorded q-monograph input line")
                literal = mapping.old[previous - 1]
                if "\\input{" + entry["input"] + "}" not in literal:
                    raise RefreshError("Recorded q-monograph input does not match its previous source line")
                line, method = mapping.locate(previous, literal)
                if not self.exists(entry["resolvedPath"]):
                    raise RefreshError("A recorded q-monograph input is absent upstream", path=entry["resolvedPath"])
                self.methods[method] += 1
                if line != previous:
                    self.line_changes.append({"document": name, "pointer": f"/qMonographDirectInputs/{index}/masterLine",
                                              "path": Q_MASTER, "old_line": previous, "new_line": line, "method": method})
                    entry["masterLine"] = line
                entry["exists"] = True
            except (RefreshError, VendorError, KeyError, TypeError) as exc:
                self.errors.append({"document": name, "pointer": f"/qMonographDirectInputs/{index}",
                                    "message": str(exc), **getattr(exc, "details", {})})

    def inventory(self, selected: list[dict[str, Any]], excluded: list[dict[str, Any]]) -> int:
        expected = [relative_name(item["tex"]) for item in selected] + [relative_name(item["path"]) for item in excluded]
        if len({name.casefold() for name in expected}) != len(expected):
            raise RefreshError("Selected and excluded root inventory has duplicate or overlapping paths")
        actual = set()
        prefix = self.docs_name + "/"
        for name in self.source.entries:
            if name.startswith(prefix) and name.endswith(".tex"):
                relative = name[len(prefix):]
                if re.search(r"\\documentclass\b", mask_tex(self.text(relative))):
                    actual.add(relative)
        if actual != set(expected):
            raise RefreshError("Pinned document roots differ from the retained reviewed inventory; a new selection review is required",
                               unreviewed_roots=sorted(actual - set(expected)), missing_document_roots=sorted(set(expected) - actual))
        return len(actual)

    def prepare(self) -> dict[str, Any]:
        articles = self.selection["articles"]
        excluded = deepcopy(self.selection["excluded_articles"])
        if not isinstance(articles, list) or not articles or not isinstance(excluded, list):
            raise RefreshError("Selection requires nonempty articles and an excluded_articles list")
        removed = [article for article in articles if not self.exists(article["tex"])]
        retained = [article for article in articles if self.exists(article["tex"])]
        self.selection["articles"] = retained
        removed_paths = sorted(relative_name(article["tex"]) for article in removed)
        consolidated = sorted(set(removed_paths) & DIAGONAL_ROOTS)
        if consolidated:
            atlas = next((article for article in retained if article["tex"] == ATLAS), None)
            if atlas is None or any(PurePosixPath(path).parent.name not in self.text(ATLAS) for path in consolidated):
                raise RefreshError("The expected atlas consolidation is not documented by the retained source", removed=consolidated)
            if ATLAS_NOTE not in atlas["reason"]:
                atlas["reason"] += " " + ATLAS_NOTE
        pdf_changes = []
        for article in retained:
            pdf = article.get("pdf")
            if pdf is None:
                candidate = str(PurePosixPath(article["tex"]).with_suffix(".pdf"))
                if self.exists(candidate):
                    article["pdf"] = candidate
                    pdf_changes.append({"tex": article["tex"], "old_pdf": None, "new_pdf": candidate})
            elif not self.exists(pdf):
                raise RefreshError("A previously selected PDF disappeared while its source remains", tex=article["tex"], pdf=pdf)
        count = self.inventory(retained, excluded)
        companions = sum(article.get("role") == "reference-companion" for article in retained)
        scope = self.selection["scope"]
        scope.update(reviewed_document_roots=count, selected_articles=len(retained) - companions,
                     reference_companions=companions)
        if any(relative_name(a["tex"]).casefold().startswith("archive/") for a in retained):
            raise RefreshError("An archived root remains selected")
        for name, document in self.documents.items():
            self.walk_evidence(document, name)
        self.q_inputs()
        # Exclusions must not be repurposed as a historical-deletion ledger.
        if self.selection["excluded_articles"] != excluded:
            self.errors.append({"document": "selection.json", "message": "Excluded-root evidence changed; review it separately before refreshing this selection"})
        if self.errors:
            raise RefreshError("Evidence refresh failed; no metadata files were written", errors=self.errors)
        current_url = source_url(self.commit, self.docs_name)
        for name, document in self.documents.items():
            previous_commit = document.get("source_commit", document.get("commit", self.old_commit))
            document.setdefault("initial_audit_commit", previous_commit)
            if "commit" in document:
                document["commit"] = self.commit
            if name != "selection.json" or "source_commit" in document:
                document["source_commit"] = self.commit
            document.pop("source_root", None)
            document.pop("sourceRoot", None)
            document["repository_url"] = REPOSITORY_URL
            document["source_url"] = current_url
            document["initial_audit_url"] = source_url(document["initial_audit_commit"], self.docs_name)
        if self.old_commit != self.commit:
            self.selection["source_refresh"] = {
                "previous_commit": self.old_commit, "commit": self.commit,
                "removed_selected_roots": removed_paths,
                "consolidations": [{"sources": consolidated, "into": ATLAS, "note": ATLAS_NOTE}] if consolidated else [],
                "policy": "Existing reviewed scope retained. Deleted selected roots were retired, not added to exclusions. Evidence text was preserved and its source lines reanchored exactly.",
            }
        after = clean_state(self.source)
        if after != self.before:
            raise RefreshError("Source state changed during metadata preparation", before=self.before, after=after)
        files = [{"path": name, "changed": encoded(document) != self.original_bytes[name],
                  "before_sha256": digest(self.original_bytes[name]), "after_sha256": digest(encoded(document))}
                 for name, document in self.documents.items()]
        self.prepared = True
        return {"ok": True, "repository_url": REPOSITORY_URL, "source_url": current_url,
                "previous_commit": self.old_commit,
                "commit": self.commit, "initial_audit_commit": self.selection["initial_audit_commit"],
                "initial_audit_url": self.selection["initial_audit_url"],
                "removed_selected_roots": removed_paths, "consolidated_into_atlas": consolidated,
                "excluded_roots_unchanged": True, "counts": {key: scope[key] for key in
                    ("reviewed_document_roots", "selected_articles", "reference_companions")},
                "newly_available_pdfs": pdf_changes, "evidence_methods": dict(self.methods),
                "evidence_line_changes": self.line_changes, "metadata_files": files,
                "source_state": after}

    def apply(self) -> list[str]:
        """Stage all JSON bytes before replacing any, rejecting concurrent edits."""
        if not self.prepared:
            raise RefreshError("Metadata must pass complete preparation before apply")
        if clean_state(self.source) != self.before:
            raise RefreshError("Source state changed before metadata write")
        for name, raw in self.original_bytes.items():
            if io_path(self.vendor_root / name).read_bytes() != raw:
                raise RefreshError("Metadata changed during preparation; refusing to overwrite it", file=name)
        staged: dict[str, Path] = {}
        replaced = []
        try:
            for name, document in self.documents.items():
                content = encoded(document)
                if content == self.original_bytes[name]:
                    continue
                with tempfile.NamedTemporaryFile(dir=io_path(self.vendor_root), prefix=name + ".refresh-", suffix=".tmp", delete=False) as stream:
                    staged[name] = Path(stream.name)
                    stream.write(content)
            for name, raw in self.original_bytes.items():
                if io_path(self.vendor_root / name).read_bytes() != raw:
                    raise RefreshError("Metadata changed before replacement; refusing to overwrite it", file=name)
            if clean_state(self.source) != self.before:
                raise RefreshError("Source state changed before metadata replacement")
            for name, temporary in staged.items():
                os.replace(temporary, io_path(self.vendor_root / name))
                replaced.append(name)
        except OSError:
            for name in replaced:
                io_path(self.vendor_root / name).write_bytes(self.original_bytes[name])
            raise
        finally:
            for temporary in staged.values():
                if temporary.exists():
                    temporary.unlink()
        return replaced


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--commit", required=True, help="Full immutable upstream commit ID")
    parser.add_argument("--source-root", required=True, type=Path, help="Original ProveIt repository root")
    parser.add_argument("--vendor-root", type=Path, default=DEFAULT_DESTINATION)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument("--dry-run", action="store_true", help="Preview only (the default)")
    mode.add_argument("--apply", action="store_true", help="Write only the three metadata JSON files after all checks pass")
    args = parser.parse_args()
    try:
        refresh = Refresh(args.vendor_root, args.source_root, args.commit)
        report = refresh.prepare()
        report["applied"] = bool(args.apply)
        report["written_files"] = refresh.apply() if args.apply else []
        report["dry_run"] = not args.apply
    except (RefreshError, VendorError, OSError, ValueError, TypeError, KeyError, AttributeError) as exc:
        report = {"ok": False, "applied": False, "message": str(exc), **getattr(exc, "details", {})}
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["ok"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
