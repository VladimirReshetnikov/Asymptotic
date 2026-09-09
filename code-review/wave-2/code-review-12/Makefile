.PHONY: pdf check clean
pdf:
	cd article && latexmk -pdf -interaction=nonstopmode -halt-on-error asymptotic_incremental_audit.tex
check:
	cd code && python -m unittest test_independent -v
clean:
	cd article && latexmk -c asymptotic_incremental_audit.tex
