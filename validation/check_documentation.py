"""Check the documentation split without executing the package test suite.

Checks the deterministic guide build, mathematical cross-references and
separation, landing-page links, and preserved engineering files. Requires
Pandoc. Native examples and PDF rendering are separate commands.
"""

from __future__ import annotations

import json
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit

from build_user_guide import ROOT, build


def check() -> dict:
    guide = build(check=True)
    master = ROOT / "article" / "asymptotic-inverse.tex"
    text = master.read_text(encoding="utf-8")
    chapters = [master.parent / (name + ".tex") for name in re.findall(r"\\input\{([^}]+)\}", text)]
    text += "\n" + "\n".join(path.read_text(encoding="utf-8") for path in chapters)
    labels = re.findall(r"\\label\{([^}]+)\}", text)
    references = re.findall(r"\\(?:ref|eqref|pageref)\{([^}]+)\}", text)
    bibliography = re.findall(r"\\bibitem\{([^}]+)\}", text)
    citations = [key.strip() for group in re.findall(r"\\cite(?:\[[^]]*\])?\{([^}]+)\}", text)
                 for key in group.split(",")]
    assert len(labels) == len(set(labels)), "Duplicate mathematical labels"
    assert not set(references) - set(labels), "Missing mathematical references"
    assert not set(citations) - set(bibliography), "Missing bibliography entries"
    assert not re.search(r"\\wl\{|lstlisting|AsymptoticExpansion|PowerLogSeries|GeneralizedSeries|\.wl\b|sec:package|sec:reports", text), "Software content in the mathematical article"
    routes = [ROOT / "README.md", ROOT / "AsymptoticInverse/README.md",
              ROOT / "article/README.md", ROOT / "AsymptoticInverse/Documentation/README.md",
              ROOT / "docs/development/README.md", ROOT / "docs/development/article-notes/README.md"]
    local_links = 0
    for path in routes:
        for href in re.findall(r"\[[^]\n]+\]\(([^)]+)\)", path.read_text(encoding="utf-8")):
            url = urlsplit(href)
            if url.scheme or url.netloc or not url.path:
                continue
            destination = path.parent / unquote(url.path)
            assert destination.exists(), f"Missing destination from {path}: {href}"
            if url.fragment and destination.suffix == ".md":
                target_text = destination.read_text(encoding="utf-8")
                headings = re.findall(r"^#+ (.+)$", target_text, re.M)
                anchors = {re.sub(r"[^\w\s-]", "", title.lower()).replace(" ", "-") for title in headings}
                anchors.update(re.findall(r'<a id="([^"]+)"', target_text))
                assert unquote(url.fragment) in anchors, f"Missing heading from {path}: {href}"
            local_links += 1
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
        assert before == after, f"Archived document changed: {moved}"
    result = {"Guide": guide, "MathematicalChapters": len(chapters),
              "MathematicalLabels": len(labels), "MathematicalReferences": len(references),
              "BibliographyEntries": len(bibliography), "MissingReferences": 0,
              "MissingCitations": 0, "LandingPageLocalLinks": local_links,
              "PreservedEngineeringFiles": len(archived),
              "FullPackageSuiteRun": False}
    print(json.dumps(result, indent=2))
    return result


if __name__ == "__main__":
    check()
