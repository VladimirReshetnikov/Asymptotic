#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/article"
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_native_boundary_audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_native_boundary_audit.tex
pdflatex -interaction=nonstopmode -halt-on-error asymptotic_native_boundary_audit.tex
