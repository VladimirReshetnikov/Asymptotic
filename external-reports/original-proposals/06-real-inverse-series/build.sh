#!/bin/sh
# Rebuild the PDF, preserving the relative package and table paths.
set -eu
cd "$(dirname "$0")/article"
for pass in 1 2 3; do
  pdflatex -interaction=nonstopmode -halt-on-error real-inverse-series.tex
done
