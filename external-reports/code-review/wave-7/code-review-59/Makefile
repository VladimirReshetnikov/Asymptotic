.PHONY: test pdf clean

test:
	python code/run_independent.py

pdf:
	cd article && pdflatex -interaction=nonstopmode -halt-on-error review.tex
	cd article && pdflatex -interaction=nonstopmode -halt-on-error review.tex

clean:
	rm -f article/review.aux article/review.log article/review.out article/review.toc
