#!/usr/bin/env sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
cp "$ROOT/article/asymptotic-review.tex" "$TMP/"
cd "$TMP"
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-review.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-review.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-review.tex
cp asymptotic-review.pdf "$ROOT/article/asymptotic-review.pdf"
printf '\nBuilt %s\n' "$ROOT/article/asymptotic-review.pdf"
