#!/usr/bin/env sh
set -eu
cd "$(dirname "$0")"
pdflatex -interaction=nonstopmode -halt-on-error audit.tex
pdflatex -interaction=nonstopmode -halt-on-error audit.tex
pdflatex -interaction=nonstopmode -halt-on-error audit.tex
printf '%s\n' 'Built audit.pdf. Native package code has not been executed by this build.'
