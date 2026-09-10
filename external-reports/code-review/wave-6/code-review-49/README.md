# AsymptoticAnalysis incremental contract audit

Reviewed revision: `8cee870994f506b501bae3ea6bd4a3a7edb895c1`  
Repository: https://github.com/VladimirReshetnikov/Asymptotic  
Review date: 10 September 2026

Start with **article.pdf**. Editable source is **article.tex**.

## What the bundle establishes

**N1** is a source-level Mathics condition-protection gap with a supplied,
unexecuted public characterization request. It is NOT labelled a reproduced
native wrong-result bug.

**E1** is a proved positive-parameter signed Lerch enclosure. Its independent
Python exact-rational implementation passed 576 grid cases against independently
bounded defining-series sums, plus the other checks in seven test groups.

**E2** is an all-orders derivative theorem for the existing admitted affine Zeta
Dirichlet provider. It explains how to strengthen its conservative automatic
contract; it does not claim arbitrary Big-O expressions may be differentiated.

The older review register and wave intake/index records were used to exclude
existing findings. `evidence/novelty_crosswalk.md` describes the nearest earlier
categories and the scope of the comparison. The original bytes of every retained
and retired report were not read line by line.

## Executed versus unexecuted

Executed here:

```sh
python tests/test_reference.py
```

This uses only the Python standard library. The implementation rejects float
inputs; use `fractions.Fraction`. Running the tests regenerates the grid JSON.
The packaged log describes the review's own run. A subsequent run may have a
different duration and Python version.

Not executed here: the Wolfram Language translation, its 108-case reference
checks, and the AsymptoticAnalysis package probes. No native Wolfram or Mathics
kernel was available, and the attempted connected Wolfram evaluation failed.
Do not describe the Python results as package test results.

For the WL reference, evaluate in a kernel after replacing the paths:

```wl
Get["/absolute/path/to/code/LerchEnclosure.wl"];
Get["/absolute/path/to/tests/ReferenceWL.wl"];
```

For N1/E2 package characterization, first load the PINNED repository in a fresh
kernel session and then evaluate:

```wl
Get["/absolute/path/to/tests/IncrementalAudit.wl"];
AsymptoticAudit`AsymptoticAuditResults
```

The file prints raw records. In N1, inspect conditions and result kind; a
conservative refusal is not a wrong result. E2 includes the default-contract
call and a call using the existing explicit derivative-contract option.
The probes do not download, modify, install or monkey-patch the package.

## Exact Lerch example

From the extracted directory:

```python
import sys
from fractions import Fraction
sys.path.insert(0, "code")
from lerch_enclosure import lerch_enclosure

result = lerch_enclosure(Fraction(1, 2), 2, 100, 3)
print(result.lower, result.upper)  # exact rational endpoints
```

The parameter `order=3` means that Taylor indices 0, 1 and 2 are retained;
3 is the first omitted index. The theorem permits real s>0, but the exact-rational
implementation deliberately requires s to be a positive integer, z and a to be
rational, 0<=z<1, a>0, and 0<=order<=64. A narrow interval around the true value
does not mean the retained polynomial's truncation error has changed order.
No convergence as order tends to infinity at fixed a is asserted.

## Files

`code/` contains independent reference implementations, not a fork of repository
code. `tests/` contains the executed Python suite and unexecuted WL probes.
`evidence/` contains the actual Python log, full grid, exact sample endpoints,
source/evidence manifest and novelty crosswalk.

## Rebuilding the article

```sh
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

The PDF was compiled and visually inspected. No repository changes were made.
The archive contains no checksum files or font files. Git revision identifiers
in the article and manifest identify the reviewed source snapshot.
