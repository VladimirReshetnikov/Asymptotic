"""Run the retrieved checker/candidate against a controlled repository fixture.

Only the checker is the actual upstream program. Pandoc/guide, link, encoding,
and historical-git providers are explicit deterministic stubs. Nothing here is
a result for the live repository or a claim about its existing documentation.
"""
from __future__ import annotations
import argparse
from contextlib import redirect_stdout
import importlib.util
import io
import json
from pathlib import Path
import sys
import tempfile
import types

BASE = Path(__file__).resolve().parents[1]
HISTORICAL = b"historical fixture bytes\n"
PREAMBLE = "\\documentclass{article}\n\\begin{document}\n"
ENDING = "\n\\end{document}\n"
BODIES = {
    "valid": r"\section{Control}\label{present} See \ref{present}.",
    "duplicate_labels": r"\section{A}\label{dup}\section{B}\label{dup}",
    "missing_reference": r"See \ref{absent}.",
    "missing_citation": r"See \cite{absent}.",
    "software_content": "AsymptoticExpansion",
    "archive_changed": "A valid mathematical document.",
    "archive_crlf": "A valid mathematical document.",
    "comment_mask_reference": "See \\ref{ghost}.\n% \\label{ghost}\n",
    "comment_mask_citation": "See \\cite{ghost}.\n% \\bibitem{ghost}\n",
    "comment_duplicate": "\\section{Control}\\label{present}\n% \\label{present}\nSee \\ref{present}.",
    "comment_input": "% \\input{does-not-exist}\nA valid document.",
    "software_comment": "% AsymptoticExpansion\nA valid document.",
    "valid_child": r"\input{sections/control}",
    "comment_mask_child_reference": r"\input{sections/ghost}",
}
ARCHIVED = [f"docs/development/article-notes/{name}" for name in (
    "13-package.tex", "14-reports.tex", "26-generated-validation.tex", "29-integration.tex")]
ARCHIVED += [f"docs/development/implementation-plan.{ext}" for ext in ("tex", "pdf")]

def prepare(root: Path, case: str) -> None:
    article = root / "docs/article"
    article.mkdir(parents=True)
    (article / "asymptotic-inverse.tex").write_text(PREAMBLE + BODIES[case] + ENDING, encoding="utf-8")
    (article / "sections").mkdir()
    (article / "sections/control.tex").write_text(r"\section{Child}\label{child} See \ref{child}.", encoding="utf-8")
    (article / "sections/ghost.tex").write_text("See \\ref{ghost}.\n% \\label{ghost}\n", encoding="utf-8")
    for name in ARCHIVED:
        path = root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        data = HISTORICAL
        if case == "archive_crlf" and path.suffix == ".tex":
            data = data.replace(b"\n", b"\r\n")
        if case == "archive_changed" and path.suffix == ".pdf":
            data = b"changed archive fixture bytes\n"
        path.write_bytes(data)

def run(source: Path, case: str) -> dict:
    with tempfile.TemporaryDirectory(prefix="asymptotic-doc-fixture-") as directory:
        root = Path(directory)
        prepare(root, case)
        guide = types.ModuleType("build_user_guide")
        guide.ROOT = root
        guide.build = lambda **kwargs: {"Fixture": True, "check": kwargs.get("check")}
        links = types.ModuleType("documentation_links")
        links.maintained_pages = lambda _: []
        links.check_local_links = lambda _: {"Fixture": True}
        encoding = types.ModuleType("documentation_text")
        encoding.check_text_encoding = lambda _: {"Fixture": True}
        sys.modules.update(build_user_guide=guide, documentation_links=links, documentation_text=encoding)
        sys.path.insert(0, str(BASE / "code"))
        spec = importlib.util.spec_from_file_location("_checker_under_review", source)
        if spec is None or spec.loader is None:
            raise RuntimeError("Cannot load checker")
        checker = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(checker)
        def git_stub(command, **kwargs):
            if command[:2] != ["git", "show"] or not command[2].startswith("2a3d75a:"):
                raise RuntimeError("Unexpected subprocess in fixture")
            return types.SimpleNamespace(stdout=HISTORICAL)
        checker.subprocess = types.SimpleNamespace(run=git_stub)
        captured = io.StringIO()
        record = {"case": case, "python_optimization": sys.flags.optimize,
                  "source": "upstream" if source.parent.name == "upstream" else "candidate",
                  "evidence": "Actual checker with deterministic dependency fixtures"}
        try:
            with redirect_stdout(captured):
                receipt = checker.check()
        except Exception as exc:
            record.update(outcome="rejected", exception=type(exc).__name__,
                          message=str(exc).replace(str(root), "<fixture-root>"))
        else:
            record.update(outcome="accepted", receipt=receipt)
        return record

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    parser.add_argument("case", choices=sorted(BODIES))
    args = parser.parse_args()
    record = run(args.source.resolve(), args.case)
    print(json.dumps(record, sort_keys=True))
    raise SystemExit(0 if record["outcome"] == "accepted" else 1)

if __name__ == "__main__":
    main()
