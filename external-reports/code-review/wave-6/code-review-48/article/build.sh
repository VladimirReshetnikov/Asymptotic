#!/bin/sh
set -eu
cd "$(dirname "$0")"
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-differential-audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-differential-audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic-differential-audit.tex
