"""Discover maintained Markdown and validate local links with Pandoc's GFM parser.

Imported report bodies and vendored research retain their original references;
their maintained catalog pages are checked instead. No network requests are made.
"""

from __future__ import annotations

from functools import lru_cache
from html.parser import HTMLParser
import json
from pathlib import Path
import subprocess
from urllib.parse import unquote, urlsplit


class Anchors(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids: set[str] = set()
        self.links: list[str] = []

    def handle_starttag(self, tag, attrs):
        values = dict(attrs)
        if values.get("id"):
            self.ids.add(values["id"])
        if tag == "a" and values.get("name"):
            self.ids.add(values["name"])
        if tag == "a" and values.get("href"):
            self.links.append(values["href"])
        if tag == "img" and values.get("src"):
            self.links.append(values["src"])


def maintained_pages(root: Path) -> list[Path]:
    """Include new contract notes automatically without rewriting source archives."""
    pages = {root / "README.md"}
    for directory in ("src", "docs", "validation"):
        pages.update((root / directory).rglob("*.md"))
    # Saved Stack Exchange texts are source snapshots; their index is maintained.
    snapshots = root / "docs" / "mathematica.stackexchange.com"
    pages = {p for p in pages if snapshots not in p.parents or p == snapshots / "README.md"}
    pages.update(root / name for name in (
        "external-reports/README.md", "external-reports/original-proposals/README.md",
        "external-reports/original-proposals/COMPARISON.md",
        "external-reports/code-review/README.md", "vendor/README.md", "vendor/proveit/README.md"))
    pages.update((root / "external-reports" / "code-review").glob("wave-*/README.md"))
    # Retirement tombstones beside a wave index are maintained pages; the
    # supplied package directories next to them remain source archives.
    pages.update((root / "external-reports" / "code-review").glob("wave-*/code-review-*.md"))
    return sorted(pages)


def markdown_targets(source: str) -> tuple[set[str], list[str]]:
    """Parse headings, raw HTML anchors, inline/reference links, and images.

    Pandoc handles balanced parentheses, fenced code, duplicate heading suffixes,
    and GFM punctuation rules consistently with the guide builder.
    """
    result = subprocess.run(["pandoc", "--from=gfm", "--to=json"], input=source,
                            capture_output=True, encoding="utf-8", check=True)
    anchors: set[str] = set()
    links: list[str] = []
    html = Anchors()

    def visit(node):
        if isinstance(node, dict):
            kind, content = node.get("t"), node.get("c")
            if kind == "Header":
                anchors.add(content[1][0])
            elif kind in ("Link", "Image"):
                links.append(content[-1][0])
            elif kind in ("RawBlock", "RawInline") and content[0] == "html":
                html.feed(content[1])
            for value in node.values():
                visit(value)
        elif isinstance(node, list):
            for value in node:
                visit(value)

    visit(json.loads(result.stdout))
    return anchors | html.ids, links + html.links


def check_local_links(pages: list[Path], root: Path | None = None) -> dict:
    """Validate local links; every destination must stay inside ``root``.

    Existence alone is not acceptance: a relative link that climbs out of the
    checkout can resolve to a file that happens to exist on the maintainer's
    host and is absent for every other reader (wave-6 report 51 N03). Symbolic
    links are followed before the containment test, ``file:`` links and
    Windows drive paths are rejected as unportable. When no root is given, the
    common parent of the pages is used.
    """
    errors: list[str] = []
    local_links = 0
    fragments = 0
    if root is None:
        resolved = [page.resolve() for page in pages]
        root = Path(*_common_prefix([page.parent.parts for page in resolved])) if resolved else Path.cwd()
    root = root.resolve()

    @lru_cache(maxsize=None)
    def markdown(path):
        return markdown_targets(path.read_text(encoding="utf-8"))

    @lru_cache(maxsize=None)
    def anchors(path):
        if path.suffix.lower() == ".md":
            return markdown(path)[0]
        parser = Anchors()
        parser.feed(path.read_text(encoding="utf-8"))
        return parser.ids

    for path in pages:
        path = path.resolve()
        for href in markdown(path)[1]:
            url = urlsplit(href)
            if url.scheme == "file" or (len(url.scheme) == 1 and url.scheme.isalpha()):
                local_links += 1
                errors.append(f"Unportable local destination from {path}: {href}")
                continue
            if url.scheme or url.netloc:
                continue
            destination = (path.parent / unquote(url.path)).resolve() if url.path else path
            local_links += 1
            if not _inside(destination, root):
                errors.append(f"Destination escapes the checkout from {path}: {href}")
            elif not destination.exists():
                errors.append(f"Missing destination from {path}: {href}")
            elif url.fragment and destination.suffix.lower() in (".md", ".html"):
                fragments += 1
                if unquote(url.fragment) not in anchors(destination):
                    errors.append(f"Missing anchor from {path}: {href}")
    if errors:
        raise AssertionError("\n".join(errors))
    return {"MaintainedMarkdownPages": len(pages), "LocalLinks": local_links,
            "LocalFragments": fragments, "BrokenLocalLinks": 0}


def _inside(path: Path, root: Path) -> bool:
    try:
        path.relative_to(root)
    except ValueError:
        return False
    return True


def _common_prefix(parts: list[tuple[str, ...]]) -> tuple[str, ...]:
    prefix = parts[0]
    for other in parts[1:]:
        length = 0
        while length < min(len(prefix), len(other)) and prefix[length] == other[length]:
            length += 1
        prefix = prefix[:length]
    return prefix
