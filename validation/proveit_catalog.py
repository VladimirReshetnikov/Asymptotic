"""Write the vendored-article catalog from reviewed selections and build receipts."""
from __future__ import annotations

import json
from pathlib import Path
from urllib.parse import quote

from build_proveit_pdfs import plan_article


ROOT = Path(__file__).resolve().parents[1] / "vendor" / "proveit"


def read(name: str, default=None):
    path = ROOT / name
    return json.loads(path.read_text(encoding="utf-8")) if path.exists() else default


def link(label: str, path: str, line: int | None = None) -> str:
    target = quote(path, safe="/") + (f"#L{line}" if line else "")
    return f"[{label.replace('|', '/').replace('[', '(').replace(']', ')')}]({target})"


def evidence_links(entries: list[dict]) -> str:
    return ", ".join(link(f"{Path(e['path']).name}:{e['line']}",
                          "docs/" + e["path"], e["line"]) for e in entries)


def reading_section(name: str, heading: str) -> list[str]:
    data = read(name)
    if data is None:
        return []
    entries = data["readingOrder"] if isinstance(data, dict) else data
    lines = [f"## {heading}", ""]
    for index, entry in enumerate(entries, 1):
        lines += [f"{index}. **{entry['title']}**. {entry.get('scopeAndStatus', entry.get('reason', ''))}",
                  f"   {evidence_links(entry.get('evidence', []))}", ""]
    return lines


def main() -> None:
    selection = read("selection.json")
    build_data = read("builds.json", {"regenerated_pdfs": {}})
    builds = build_data["regenerated_pdfs"]
    manifest = read("manifest.json")
    originals = {item["destination"]: item for item in manifest["files"]}
    plans = {article["destination_tex"]: plan_article(article, ROOT, build_data, originals, False)
             for article in manifest["articles"]}
    articles = selection["articles"]
    commit = selection["commit"]
    revision = f"https://github.com/VladimirReshetnikov/ProveIt/tree/{commit}/{selection['docs_root']}"
    lines = ["# ProveIt articles on asymptotic expansions and inverses", "",
             f"This collection vendors **{selection['scope']['selected_articles']} articles and "
             f"{selection['scope']['reference_companions']} reference companions** from "
             f"[VladimirReshetnikov/ProveIt at `{commit}`]({revision}). "
             "The source directory is `Analysis/FabiusFunction/docs/`. "
             "Compilation and layout repairs found during "
             "this audit were made upstream, with regenerated PDFs committed there before the final vendor refresh.", "",
             "The selection covers ordinary and all-orders asymptotics, logarithmic and exponential "
             "transseries, asymptotic inversion, q-analogs, combinatorial sequence interpolations, "
             "saddle expansions, and exact terminating correction hierarchies. "
             "Archived articles under `docs/archive/` are excluded. "
             "The mathematical claims and their stated proof status remain those of the upstream authors; "
             "inclusion and PDF compilation are not independent mathematical verification.", "",
             "## Provenance and reproducibility", "",
             "- [Selection and source-line evidence](selection.json) records the decision for every "
             "standalone TeX root in the inventory, including exclusions.",
             "- [File manifest](manifest.json) records the immutable upstream commit, Git blob IDs, "
             "copied-file SHA-256 hashes, dependency closure, source checkout state, and path diagnostics.",
             "- [PDF build receipts](builds.json) distinguish regenerated PDFs from upstream snapshots "
             "and record input hashes, tool versions, commands, logs, and validation details.",
             "- [Upstream refresh evidence](upstream-builds.json) records the PDF builds and source "
             "repairs published to ProveIt before this snapshot was copied.",
             "- [Upstream license](LICENSE) is retained. Sources, figures, bibliographies, and provenance "
             "notes preserve their original relative paths.", "",
             "The initial audit found PDFs that predated their TeX sources and one article without "
             "a PDF. Those artifacts were rebuilt from current TeX. The final manifest records the "
             "repaired, published upstream snapshot; refresh evidence preserves the earlier build "
             "inputs, exact repairs, logs, and output hashes.", "",
             "```powershell",
             "python validation/vendor_proveit_articles.py check",
             "python validation/vendor_proveit_articles.py check --source-root C:/ProveIt",
             "python validation/build_proveit_pdfs.py --list",
             "python validation/build_proveit_pdfs.py",
             "python validation/proveit_catalog.py",
             "```", "",
             "Run these commands from the Asymptotic repository root. "
             "PDF builds are serial and use three LaTeX passes. "
             "They use a short temporary mirror to avoid Windows path-length limitations; "
             "Git on Windows should have `core.longpaths=true` for the preserved source hierarchy.", ""]
    pending = sum(plan["action"] == "build" for plan in plans.values())
    preserved = sum(plan["action"] == "preserve-upstream" for plan in plans.values())
    lines += [f"Current audit: **{len(builds)} regenerated PDFs**, **{preserved} current upstream PDFs**, "
              f"and **{pending} PDFs requiring a build**. Freshness checks use both the pinned Git history "
              "and the source checkout's recorded modification times for the full compile dependency closure. "
              "A build receipt is accepted only while its PDF, inputs, and all three pass logs retain "
              "their recorded hashes.", ""]
    lines += reading_section("q-reading-list.json", "q-analogs and inverse q-functions")
    lines += reading_section("combinatorial-reading-list.json", "Combinatorial sequences and interpolated inverses")
    lines += ["## Complete article catalog", "",
              "| Article | TeX | PDF | Coverage and status |", "| --- | --- | --- | --- |"]
    for article in articles:
        tex = article["tex"]
        pdf = article.get("pdf") or str(Path(tex).with_suffix(".pdf")).replace("\\", "/")
        receipt = builds.get("docs/" + pdf)
        action = plans["docs/" + tex]["action"]
        status = (f"Fresh build verified ({receipt['pdf_check']['page_count']} pages)" if action == "skip"
                  else "Upstream PDF current by recorded source dates" if action == "preserve-upstream"
                  else "Fresh PDF build pending")
        title = article["title"].replace("|", "/")
        reason = article["reason"].replace("|", "/")
        if article["role"] == "reference-companion":
            reason = "Reference companion. " + reason
        lines.append(f"| {title} | {link('Source', 'docs/' + tex)} | "
                     f"{link('PDF', 'docs/' + pdf)} | {reason} {status}. |")
    lines += ["", "## Selection boundaries", "",
              f"All {selection['scope']['reviewed_document_roots']} standalone TeX roots in the final source inventory were reviewed. "
              "The selection excludes 32 archived roots at the user's direction and seven external-paper "
              "roots whose content concerns exact identities, arithmetic, construction, or asymptotic "
              "bounds without substantive expansion treatment. Included chapter fragments belong to "
              "their parent articles and are not counted again. The selection file preserves each "
              "exclusion rationale.", "",
              "The reading lists distinguish fixed-q, q-to-one, coalescing and cyclotomic regimes; "
              "formal inverses from analytic inverse theorems; and proved, conditional, conjectural, "
              "or withdrawn expansion claims. In particular, a Bell-polynomial coefficient formula "
              "is not automatically an asymptotic inverse interpolation of the Bell-number sequence.", ""]
    (ROOT / "README.md").write_text("\n".join(lines), encoding="utf-8", newline="\n")
    print(f"Catalog: {len(articles)} roots; {len(builds)} regenerated PDF receipts")


if __name__ == "__main__":
    main()
