# Asymptotic: incremental audit and uniform Lerch prototype

**Article:** `article/article.pdf` and editable `article/article.tex`.
**Reviewed revision:** `efa1aeec4845a9c35e140963a0333d0c9ec33b05`.

The report presents one new reproduced signed-frontier defect in the reflected
Erfc adapter, one reproduced unsupported Lerch transition regime, and an
additive prototype for that regime with a proved signed analytic remainder
bound. G01 and E01 are the gap and its proposed solution, not two independent
bugs. The article also records the source areas inspected without adding an
unsubstantiated new issue. It does not reissue the accumulated review backlog.

## Contents

- `article/`: TeX, PDF, and generated numerical-table inputs.
- `patches/erfc-frontier.patch`: minimal canonical-source patch.
- `code/prepare_erfc_patch.py`: checks one exact source anchor and emits a diff;
  it does not modify a checkout or certify its revision.
- `code/uniform_lerch.py`, `code/UniformLerch.wl`: independent additive prototypes.
- `code/test_review.py`, `code/make_tables.py`: independent tests and table regeneration.
- `code/ReviewProbes.wlt`: proposed integration tests, not executed as a full file.
- `evidence/`: native observation transcriptions, exact example data, numerical
  tables, novelty crosswalk, environment and independent-test output.

## Actual validation

Twelve independent Python test methods passed, including 96 numerical
signed-bound subcases. These are NOT upstream package tests. The native service
reported Wolfram Language 15.0.0. It reproduced the Erfc defect, verified the
one-case in-memory patch, reproduced the unsupported Lerch input, and checked
an equivalent fully qualified prototype coefficient routine. No Mathics run,
full upstream suite, local modular run, or regenerated standalone run was done.

The distributed WL prototype uses conservative language constructs, but its
file-level load and behavior in Mathics still require verification. Floating-
point evaluation of the prototype is explicitly NOT an outward-rounded interval
certificate. The theorem bounds exact mathematical expressions.

## Run independent checks

```sh
python -m pip install -r code/requirements.txt
python code/test_review.py
python code/make_tables.py
python code/uniform_lerch.py --lambda 1 --s 2 --order 2 --a 10 --dps 80
```

## Prepare the canonical-source patch

```sh
python code/prepare_erfc_patch.py /path/to/Asymptotic > erfc-frontier.patch
```

Review and apply the diff through the normal repository workflow. Then use the
repository's standalone builder and existing native/Mathics runners. Do not
edit only the generated standalone. The native test in this review changed a
fetched standalone in memory solely to validate the small mechanism.

Load packages in separate expressions before evaluating the proposed probes,
or use a streaming `.wl` file and fully qualified public names. The `.wlt` file
expects AsymptoticAnalysis and `code/UniformLerch.wl` to have been loaded first.

## Build the article

From `article/`, using a TeX Live installation with `newpx`, `microtype`,
`listings`, `xurl`, and the standard AMS/table packages:

```sh
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
pdflatex -interaction=nonstopmode -halt-on-error article.tex
```

The archive intentionally contains no checksum files and no font files.
Upstream source is linked rather than bundled, apart from minimal patch context.
