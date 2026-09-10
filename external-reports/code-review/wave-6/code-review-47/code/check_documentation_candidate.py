"""Check the documentation split without executing the package test suite.

Checks the deterministic guide build, mathematical cross-references and
separation, maintained Markdown links, and preserved engineering files. Requires
Pandoc. Native examples and PDF rendering are separate commands.
"""

from __future__ import annotations

import json
from pathlib import Path
import re
import subprocess

from build_user_guide import ROOT, build
from documentation_links import check_local_links, maintained_pages
from documentation_text import check_text_encoding
from documentation_audit_guards import require, strip_tex_comments


def check() -> dict:
    pages = maintained_pages(ROOT)
    text_paths = pages + list((ROOT / "docs" / "article").rglob("*.tex"))
    for extension in ("*.html", "*.css"):
        text_paths += list((ROOT / "src" / "Documentation").glob(extension))
    encoding = check_text_encoding(text_paths)
    guide = build(check=True)
    master = ROOT / "docs" / "article" / "asymptotic-inverse.tex"
    text = master.read_text(encoding="utf-8")
    chapters = [master.parent / (name + ".tex") for name in re.findall(r"\\input\{([^}]+)\}", strip_tex_comments(text))]
    text += "\n" + "\n".join(path.read_text(encoding="utf-8") for path in chapters)
    active_text = strip_tex_comments(text)
    labels = re.findall(r"\\label\{([^}]+)\}", active_text)
    references = re.findall(r"\\(?:ref|eqref|pageref)\{([^}]+)\}", active_text)
    bibliography = re.findall(r"\\bibitem\{([^}]+)\}", active_text)
    citations = [key.strip() for group in re.findall(r"\\cite(?:\[[^]]*\])?\{([^}]+)\}", active_text)
                 for key in group.split(",")]
    require(len(labels) == len(set(labels)), "Duplicate mathematical labels")
    require(not set(references) - set(labels), "Missing mathematical references")
    require(not set(citations) - set(bibliography), "Missing bibliography entries")
    require(not re.search(r"\\wl\{|lstlisting|AsymptoticExpansion|PowerLogSeries|GeneralizedSeries|\.wl\b|sec:package|sec:reports", text), "Software content in the mathematical article")
    links = check_local_links(pages)
    # Keys are paths in the pinned historical commit, not the live docs/article
    # layout. Preserve them when current documentation is relocated.
    archived = {f"article/sections/{name}": f"docs/development/article-notes/{name}"
                for name in ("13-package.tex", "14-reports.tex", "26-generated-validation.tex", "29-integration.tex")}
    archived.update({f"article/implementation-plan.{ext}": f"docs/development/implementation-plan.{ext}"
                     for ext in ("tex", "pdf")})
    for original, moved in archived.items():
        before = subprocess.run(["git", "show", f"2a3d75a:{original}"], cwd=ROOT,
                                capture_output=True, check=True).stdout
        after = (ROOT / moved).read_bytes()
        if Path(moved).suffix == ".tex":
            before, after = (data.replace(b"\r\n", b"\n") for data in (before, after))
        require(before == after, f"Archived document changed: {moved}")
    result = {"Guide": guide, "MathematicalChapters": len(chapters),
              "MathematicalLabels": len(labels), "MathematicalReferences": len(references),
              "BibliographyEntries": len(bibliography), "MissingReferences": 0,
              "MissingCitations": 0, "DocumentationLinks": links,
              "TextEncoding": encoding,
              "PreservedEngineeringFiles": len(archived),
              "FullPackageSuiteRun": False}
    print(json.dumps(result, indent=2))
    return result


if __name__ == "__main__":
    check()
