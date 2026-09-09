#!/usr/bin/env sh
set -eu
cd "$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)/article"
latexmk -pdf -interaction=nonstopmode -halt-on-error audit.tex
