.PHONY: pdf test clean
pdf:
	cd article && latexmk -pdf -interaction=nonstopmode -halt-on-error article.tex

test:
	python code/run_review.py

clean:
	cd article && latexmk -c article.tex
