PYTHON ?= python3
LATEXMK ?= latexmk

.PHONY: all test evidence clean
all: article.pdf

article.pdf: article.tex references.tex
	$(LATEXMK) -pdf -interaction=nonstopmode -halt-on-error article.tex

test:
	$(PYTHON) -m unittest discover -s code -p 'test_*.py' -v

evidence:
	$(PYTHON) code/generate_evidence.py

clean:
	$(LATEXMK) -c article.tex
