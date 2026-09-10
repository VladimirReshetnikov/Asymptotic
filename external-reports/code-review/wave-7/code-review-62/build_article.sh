#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")/article"
pdflatex -interaction=nonstopmode -halt-on-error audit.tex
pdflatex -interaction=nonstopmode -halt-on-error audit.tex
pdflatex -interaction=nonstopmode -halt-on-error audit.tex
