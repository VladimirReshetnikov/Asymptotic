"""Render an article with Poppler and record reproducible layout diagnostics.

The contact sheets support visual review; geometry checks do not replace it.
Usage: python validation/inspect_pdf.py article/asymptotic-inverse.pdf TEMP_DIR
"""

from __future__ import annotations

import hashlib
import json
from pathlib import Path
import shutil
import subprocess
import sys

from PIL import Image, ImageDraw
import pdfplumber


def inspect(pdf: Path, output: Path) -> dict:
    output.mkdir(parents=True, exist_ok=True)
    renderer = shutil.which("pdftoppm")
    if not renderer:
        raise SystemExit("pdftoppm is required for visual review")
    subprocess.run(
        [renderer, "-r", "100", "-png", str(pdf), str(output / "page")],
        check=True,
        capture_output=True,
        text=True,
    )
    diagnostics = []
    with pdfplumber.open(pdf) as document:
        for number, page in enumerate(document.pages, 1):
            chars = page.chars
            outside = [
                c for c in chars
                if c["text"].strip()
                and (c["x0"] < -1 or c["x1"] > page.width + 1
                     or c["top"] < -1 or c["bottom"] > page.height + 1)
            ]
            diagnostics.append({
                "Page": number,
                "Width": page.width,
                "Height": page.height,
                "Characters": len(chars),
                "TextOutsidePage": len(outside),
            })
    pages = sorted(output.glob("page-*.png"), key=lambda p: int(p.stem.split("-")[-1]))
    if len(pages) != len(diagnostics):
        raise SystemExit("Rendered page count does not match PDF page count")
    sheets = []
    for start in range(0, len(pages), 6):
        batch = pages[start:start + 6]
        sheet = Image.new("RGB", (1500, 2 * 750), "#dadada")
        draw = ImageDraw.Draw(sheet)
        for index, page in enumerate(batch):
            with Image.open(page) as source:
                thumbnail = source.convert("RGB")
                thumbnail.thumbnail((480, 710))
                left = (index % 3) * 500 + (500 - thumbnail.width) // 2
                top = (index // 3) * 750 + 28
                sheet.paste(thumbnail, (left, top))
                draw.text(((index % 3) * 500 + 15, (index // 3) * 750 + 8),
                          f"Page {start + index + 1}", fill="black")
        target = output / f"contact-{start // 6 + 1:02}.png"
        sheet.save(target)
        sheets.append(target.name)
    result = {
        "PDF": pdf.name,
        "SHA256": hashlib.sha256(pdf.read_bytes()).hexdigest(),
        "Renderer": Path(renderer).name,
        "DPI": 100,
        "PageCount": len(diagnostics),
        "RenderedPages": len(pages),
        "Pages": diagnostics,
        "ContactSheets": sheets,
        "VisualReview": "Contact sheets and selected full pages require human or model inspection.",
    }
    (output / "layout-diagnostics.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


if __name__ == "__main__":
    result = inspect(Path(sys.argv[1]).resolve(), Path(sys.argv[2]).resolve())
    print(json.dumps({k: result[k] for k in ("PageCount", "RenderedPages", "SHA256")}, indent=2))
