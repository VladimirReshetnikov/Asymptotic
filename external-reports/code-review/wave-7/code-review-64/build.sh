#!/usr/bin/env sh
set -eu
root=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
cp "$root/article/article.tex" "$tmp/article.tex"
(cd "$tmp" && pdflatex -interaction=nonstopmode -halt-on-error article.tex >/dev/null && pdflatex -interaction=nonstopmode -halt-on-error article.tex >/dev/null && pdflatex -interaction=nonstopmode -halt-on-error article.tex >/dev/null)
cp "$tmp/article.pdf" "$root/article/article.pdf"
printf '%s\n' "Built article/article.pdf"
