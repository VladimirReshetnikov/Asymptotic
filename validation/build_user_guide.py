"""Build the standalone guide/reference and check their links and API anchors.

Requires Pandoc on PATH; uses only the Python standard library.
Run from any directory: python validation/build_user_guide.py
Use --check to verify the committed HTML against a fresh deterministic build.
"""

from __future__ import annotations

import argparse
from collections import Counter
from html.parser import HTMLParser
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit


ROOT = Path(__file__).resolve().parents[1]
DOCS = ROOT / "src" / "Documentation"
PAGES = {"UserGuide": "AsymptoticAnalysis User Guide",
         "ResultReference": "AsymptoticAnalysis Result Properties"}


class Document(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids: list[str] = []
        self.links: list[str] = []

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if values.get("id"):
            self.ids.append(values["id"])
        if tag == "a" and values.get("href"):
            self.links.append(values["href"])


def render(name: str, title: str) -> str:
    command = ["pandoc", f"{name}.md", "--from=gfm", "--to=html5",
               "--standalone", "--section-divs", "--toc", "--toc-depth=2",
               "--embed-resources", "--css=UserGuide.css",
               f"--metadata=pagetitle:{title}",
               "--metadata=lang:en"]
    rendered = subprocess.run(command, cwd=DOCS, check=True, capture_output=True,
                              encoding="utf-8").stdout.replace("\r\n", "\n")
    rendered = rendered.replace("</head>", '<link rel="icon" href="data:,">\n</head>')
    # Keep Markdown sources navigable on GitHub while the generated pair links
    # to readable HTML siblings, including their exact section fragments.
    for sibling in PAGES:
        rendered = re.sub(r'(href=")' + re.escape(sibling) + r'\.md(?=[#?\"])',
                          rf'\g<1>{sibling}.html', rendered)
    return rendered


def build(check: bool = False) -> dict:
    rendered = {name: render(name, title) for name, title in PAGES.items()}
    documents = {}
    for name, html in rendered.items():
        document = Document()
        document.feed(html)
        documents[name] = document
    errors = []
    for name, document in documents.items():
        errors.extend(f"{name}: duplicate anchor: {anchor}"
                      for anchor, count in Counter(document.ids).items() if count > 1)
        for href in document.links:
            url = urlsplit(href)
            if url.scheme or url.netloc:
                continue
            path = unquote(url.path)
            destination = document if not path else None
            for sibling in documents:
                if path == f"{sibling}.html":
                    destination = documents[sibling]
                    break
            if destination is not None:
                if url.fragment and unquote(url.fragment) not in destination.ids:
                    errors.append(f"{name}: missing anchor: {href}")
            elif not (DOCS / path).exists():
                errors.append(f"{name}: missing local destination: {href}")
    kernel = "\n".join(path.read_text(encoding="utf-8") for path in
                       sorted((ROOT / "src" / "Kernel").rglob("*.wl")))
    public = sorted(set(re.findall(r"^(?:AsymptoticAnalysis`)?([A-Za-z][A-Za-z0-9]*)::usage\s*=", kernel, re.M)))
    for symbol in public:
        if documents["UserGuide"].ids.count(symbol) != 1:
            errors.append(f"Public symbol needs one reference anchor: {symbol}")
    if errors:
        raise SystemExit("\n".join(errors))
    for name, html in rendered.items():
        target = DOCS / f"{name}.html"
        if check:
            if not target.exists() or target.read_text(encoding="utf-8") != html:
                errors.append(f"{name}.html differs from its Markdown/CSS sources; rebuild it.")
        else:
            target.write_text(html, encoding="utf-8", newline="\n")
    if errors:
        raise SystemExit("\n".join(errors))
    guide = documents["UserGuide"]
    result = {"PublicSymbols": len(public), "Anchors": len(guide.ids),
              "Links": len(guide.links), "BrokenLocalLinks": 0,
              "DuplicateAnchors": 0, "GeneratedHTMLMatchesSources": True}
    result["ReferenceDocuments"] = {
        f"{name}.html": {"Anchors": len(doc.ids), "Links": len(doc.links)}
        for name, doc in documents.items() if name != "UserGuide"}
    print(result)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
