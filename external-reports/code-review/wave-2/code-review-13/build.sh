#!/bin/sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/article"
if command -v latexmk >/dev/null 2>&1; then
  latexmk -pdf -interaction=nonstopmode -halt-on-error asymptotic-incremental-audit.tex
else
  pdflatex -interaction=nonstopmode -halt-on-error asymptotic-incremental-audit.tex
  pdflatex -interaction=nonstopmode -halt-on-error asymptotic-incremental-audit.tex
  pdflatex -interaction=nonstopmode -halt-on-error asymptotic-incremental-audit.tex
fi
