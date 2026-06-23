#!/usr/bin/env python3

from __future__ import annotations

import html
import os
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
SITE_TITLE = os.environ.get("SITE_TITLE", "math")


def posix(path: Path) -> str:
    return path.as_posix()


def write_file(path: Path, body: str) -> None:
    path.write_text(body, encoding="utf-8")


def html_document(title: str, body: str) -> str:
    return f"""<!doctype html>
<html lang="ja">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{html.escape(title)}</title>
  <style>
    body {{ font-family: system-ui, sans-serif; line-height: 1.6; margin: 2rem; }}
    ul {{ padding-left: 1.5rem; }}
    iframe {{ border: 1px solid #ddd; height: 85vh; width: 100%; }}
  </style>
</head>
<body>
{body}
</body>
</html>
"""


def discover_pdfs() -> list[Path]:
    pdfs: list[Path] = []
    for path in REPO_ROOT.rglob("main.pdf"):
        rel = path.relative_to(REPO_ROOT)
        parts = rel.parts
        if parts[0] in {".git", ".github", "_my_style"}:
            continue
        if "fig" in parts:
            continue
        pdfs.append(rel)
    return sorted(pdfs)


def generate_project_index(pdf: Path) -> None:
    project_dir = REPO_ROOT / pdf.parent
    title = posix(pdf.parent)
    pdf_name = pdf.name
    body = f"""
  <h1>{html.escape(title)}</h1>
  <p><a href="{html.escape(pdf_name)}">PDFを直接開く</a></p>
  <iframe src="{html.escape(pdf_name)}" title="{html.escape(title)}"></iframe>
"""
    write_file(project_dir / "index.html", html_document(title, body))


def generate_root_index(pdfs: list[Path]) -> None:
    if pdfs:
        items = "\n".join(
            f'    <li><a href="{html.escape(posix(pdf.parent / "index.html"))}">{html.escape(posix(pdf.parent))}</a> '
            f'(<a href="{html.escape(posix(pdf))}">PDF</a>)</li>'
            for pdf in pdfs
        )
    else:
        items = "    <li>PDFはまだ生成されていません。</li>"

    body = f"""
  <h1>{html.escape(SITE_TITLE)}</h1>
  <ul>
{items}
  </ul>
"""
    write_file(REPO_ROOT / "index.html", html_document(SITE_TITLE, body))


def main() -> None:
    pdfs = discover_pdfs()
    for pdf in pdfs:
        generate_project_index(pdf)
    generate_root_index(pdfs)
    print(f"Generated index pages for {len(pdfs)} PDF(s).")


if __name__ == "__main__":
    main()
