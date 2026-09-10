"""Execute N03's parent-path counterexample with the exact upstream checker."""
from pathlib import Path
import json
import sys
import tempfile

BASE = Path(__file__).resolve().parents[1]
sys.path[:0] = [str(BASE / "fixtures"), str(BASE / "code")]
from documentation_links_upstream import check_local_links
from portable_links import check_portable_links

with tempfile.TemporaryDirectory() as tmp:
    workspace = Path(tmp)
    root = workspace / "repo"
    docs = root / "docs"
    docs.mkdir(parents=True)
    page = docs / "Guide.md"
    page.write_text("[outside](../../outside.md#outside)\n", encoding="utf-8")
    outside = workspace / "outside.md"
    outside.write_text("# Outside\n", encoding="utf-8")
    results = {"fixture": "repo/docs/Guide.md -> ../../outside.md#outside",
               "upstream_with_outside_file": check_local_links([page])}
    try:
        check_portable_links(root, [page])
    except AssertionError as exc:
        results["candidate_with_outside_file"] = str(exc).replace(str(workspace), "WORKSPACE")
    outside.unlink()
    try:
        check_local_links([page])
    except AssertionError as exc:
        results["upstream_after_outside_file_deleted"] = str(exc).replace(str(workspace), "WORKSPACE")
    print(json.dumps(results, indent=2))
