#!/bin/sh
# Compile without leaving auxiliary files in the deliverable directory.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
command -v pdflatex >/dev/null 2>&1 || {
    echo "pdfLaTeX is required." >&2
    exit 2
}
BUILD=$(mktemp -d "${TMPDIR:-/tmp}/asymptotic-audit.XXXXXX")
trap 'rm -rf "$BUILD"' EXIT HUP INT TERM
cd "$ROOT/article"
for pass in 1 2 3; do
    if ! pdflatex -interaction=nonstopmode -halt-on-error \
        -output-directory="$BUILD" audit.tex >"$BUILD/console.log" 2>&1; then
        cat "$BUILD/console.log" >&2
        exit 1
    fi
done
cp "$BUILD/audit.pdf" "$ROOT/article/audit.pdf"
printf '%s\n' "Built $ROOT/article/audit.pdf"
