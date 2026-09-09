"""Apply explicit, hash-pinned TeX repairs in a build mirror, never to vendor blobs."""
from __future__ import annotations

import hashlib
import json


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def prepare_patches(article: dict, read_file) -> tuple[dict[str, bytes], dict]:
    """Return effective source bytes and reproducible evidence for one article.

    read_file accepts a vendor-relative path and returns bytes. Every replacement
    must match once in an explicitly declared, unchanged upstream TeX input.
    Other articles' patch edits do not invalidate this article's build receipt.
    """
    try:
        config = json.loads(read_file("build-patches.json"))
    except FileNotFoundError:
        return {}, {}
    if config.get("schema_version") != 1 or not isinstance(config.get("articles"), dict):
        raise ValueError("Unsupported build-patches.json schema")
    specification = config["articles"].get(article["destination_pdf"], [])
    if not specification:
        return {}, {}
    effective, files = {}, []
    for entry in specification:
        name = entry["path"]
        if name not in article["dependencies"] or not name.endswith(".tex") or name in effective:
            raise ValueError(f"Patch must name a unique declared TeX dependency: {name}")
        original = read_file(name)
        if digest(original) != entry["source_sha256"]:
            raise ValueError(f"Patch upstream source hash mismatch: {name}")
        text = original.decode("utf-8")
        for replacement in entry["replacements"]:
            old, new = replacement["old"], replacement["new"]
            if not old or text.count(old) != 1 or not replacement.get("reason") or old == new:
                raise ValueError(f"Patch must have a rationale and one exact changing match: {name}")
            text = text.replace(old, new, 1)
        effective[name] = text.encode("utf-8")
        files.append({"path": name, "upstream_sha256": digest(original),
                      "effective_sha256": digest(effective[name]),
                      "replacement_count": len(entry["replacements"])})
    canonical = json.dumps(specification, sort_keys=True, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    return effective, {"specification_path": "build-patches.json", "specification_sha256": digest(canonical),
                       "files": files, "application": "Only the temporary build mirror is patched; vendored Git blobs remain unchanged."}
