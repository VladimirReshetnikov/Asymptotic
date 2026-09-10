"""Build the standalone user guide and check its local links and API anchors.

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


def build(check: bool = False) -> dict:
    command = ["pandoc", "UserGuide.md", "--from=gfm", "--to=html5",
               "--standalone", "--section-divs", "--toc", "--toc-depth=2",
               "--embed-resources", "--css=UserGuide.css",
               "--metadata=pagetitle:AsymptoticAnalysis User Guide",
               "--metadata=lang:en"]
    rendered = subprocess.run(command, cwd=DOCS, check=True, capture_output=True,
                              encoding="utf-8").stdout.replace("\r\n", "\n")
    rendered = rendered.replace("</head>", '<link rel="icon" href="data:,">\n</head>')
    document = Document()
    document.feed(rendered)
    duplicate_ids = [name for name, count in Counter(document.ids).items() if count > 1]
    errors = [f"Duplicate anchor: {name}" for name in duplicate_ids]
    for href in document.links:
        url = urlsplit(href)
        if url.scheme or url.netloc:
            continue
        if not url.path:
            if url.fragment and unquote(url.fragment) not in document.ids:
                errors.append(f"Missing anchor: {href}")
        elif not (DOCS / unquote(url.path)).exists():
            errors.append(f"Missing local destination: {href}")
    kernel = "\n".join(path.read_text(encoding="utf-8") for path in
                       sorted((ROOT / "src" / "Kernel").rglob("*.wl")))
    public = sorted(set(re.findall(r"^(?:AsymptoticAnalysis`)?([A-Za-z][A-Za-z0-9]*)::usage\s*=", kernel, re.M)))
    for symbol in public:
        if document.ids.count(symbol) != 1:
            errors.append(f"Public symbol needs one reference anchor: {symbol}")
    if errors:
        raise SystemExit("\n".join(errors))
    target = DOCS / "UserGuide.html"
    if check:
        if target.read_text(encoding="utf-8") != rendered:
            raise SystemExit("UserGuide.html differs from its Markdown/CSS sources; rebuild it.")
    else:
        target.write_text(rendered, encoding="utf-8", newline="\n")
    result = {"PublicSymbols": len(public), "Anchors": len(document.ids),
              "Links": len(document.links), "BrokenLocalLinks": 0,
              "DuplicateAnchors": 0, "GeneratedHTMLMatchesSources": True}
    print(result)
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true")
    build(parser.parse_args().check)
