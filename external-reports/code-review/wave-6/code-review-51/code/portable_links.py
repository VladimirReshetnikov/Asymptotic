"""Candidate checkout-contained documentation link check.

Uses the exact upstream Pandoc parser in fixtures/. No network access. This is
an opt-in portability policy, not a sandbox against concurrent filesystem edits.
Run: python code/portable_links.py /path/to/Asymptotic
"""
from __future__ import annotations

import argparse
from functools import lru_cache
import json
import os
from pathlib import Path
import re
import sys
from urllib.parse import unquote, urlsplit

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "fixtures"))
from documentation_links_upstream import Anchors, maintained_pages, markdown_targets


class NonportableLink(ValueError):
    """A local documentation path violates the selected checkout policy."""


def check_portable_links(root: Path, pages: list[Path]) -> dict[str, int]:
    """Check exact path spelling, containment, symlinks, existence and fragments.

    Site-root-relative URLs need an explicit publication policy and are rejected.
    HTTP(S), protocol-relative and other external links are outside this check.
    file: URLs and Windows drive paths are local-machine dependencies: rejected.
    All symlink components are rejected, including in-root symlinks, deliberately.
    The caller should supply a stable clean checkout when testing publication.
    """
    root = root.resolve(strict=True)
    errors: list[str] = []
    local_count = fragment_count = 0

    @lru_cache(maxsize=None)
    def names(parent: Path) -> frozenset[str]:
        return frozenset(child.name for child in parent.iterdir())

    def checked_path(candidate: Path) -> Path:
        lexical = Path(os.path.abspath(candidate))
        try:
            parts = lexical.relative_to(root).parts
        except ValueError as exc:
            raise NonportableLink("destination escapes the checkout") from exc
        current = root
        for component in parts:
            if component not in names(current):
                raise NonportableLink(f"missing or differently cased component: {component}")
            current = current / component
            if current.is_symlink():
                raise NonportableLink("symlink components require an explicit publication policy")
        resolved = current.resolve(strict=True)
        if not resolved.is_relative_to(root):
            raise NonportableLink("resolved destination escapes the checkout")
        return resolved

    @lru_cache(maxsize=None)
    def parsed_markdown(path: Path) -> tuple[set[str], list[str]]:
        return markdown_targets(path.read_text(encoding="utf-8"))

    @lru_cache(maxsize=None)
    def anchors(path: Path) -> set[str]:
        if path.suffix.lower() == ".md":
            return parsed_markdown(path)[0]
        parser = Anchors()
        parser.feed(path.read_text(encoding="utf-8"))
        return parser.ids

    for page in pages:
        try:
            source = checked_path(page)
            hrefs = parsed_markdown(source)[1]
        except (OSError, UnicodeError, ValueError) as exc:
            errors.append(f"Invalid source {page}: {exc}")
            continue
        for href in hrefs:
            try:
                if re.match(r"^[A-Za-z]:", href):
                    raise NonportableLink("Windows drive path is not a repository URL")
                url = urlsplit(href)
                if url.scheme.lower() == "file":
                    raise NonportableLink("file: URL depends on the local machine")
                if url.scheme or url.netloc:
                    continue
                local_count += 1
                decoded = unquote(url.path)
                if "\\" in decoded or "\0" in decoded or re.match(r"^[A-Za-z]:", decoded):
                    raise NonportableLink("nonportable local path syntax")
                if decoded.startswith("/"):
                    raise NonportableLink("root-relative URL needs a configured publication root")
                destination = checked_path(source.parent / decoded if decoded else source)
                if url.fragment and destination.suffix.lower() in {".md", ".html"}:
                    fragment_count += 1
                    if unquote(url.fragment) not in anchors(destination):
                        raise NonportableLink("missing fragment")
            except (OSError, UnicodeError, ValueError) as exc:
                errors.append(f"Nonportable link from {page}: {href}: {exc}")
    if errors:
        raise AssertionError("\n".join(errors))
    return {"MaintainedMarkdownPages": len(pages), "LocalLinks": local_count,
            "LocalFragments": fragment_count, "BrokenLocalLinks": 0}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("root", type=Path)
    args = parser.parse_args()
    try:
        root = args.root.resolve(strict=True)
        print(json.dumps(check_portable_links(root, maintained_pages(root)), indent=2))
    except (AssertionError, OSError, ValueError) as exc:
        print(exc, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
