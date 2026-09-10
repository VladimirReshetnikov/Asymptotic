# Complete coverage requirements and current status

AsymptoticAnalysis has three explicit project requirements. **All three remain
open.** Current implementations and focused passing examples are milestones;
they do not reduce the required scope or establish completeness.

| Requirement | Complete target | Current implementation and evidence | Detailed register |
| --- | --- | --- | --- |
| Wolfram expansion coverage | Completely subsume `Series`, `Asymptotic`, and `DiscreteAsymptotic`: correctly and successfully handle every input handled successfully by any of them. The output representation may differ. | Explicit `Series`/`Asymptotic` delegation, the held alias, compatible-backend search, and selected automatic routes exist. There is no implemented `DiscreteAsymptotic` backend. Known input, option, order, and evaluation differences remain. | [Native compatibility and deviations](NATIVE_COMPATIBILITY.md) · [Native result contracts](NATIVE_RESULT_CONTRACTS.md) |
| Mathics compatibility | Complete package compatibility with Mathics3 in addition to the official Wolfram kernel, preserving the public operations and their mathematical contracts. | Interpreter-specific adapters and portable checks cover selected loading, algebra, forward/inverse, special-function, refinement, and certificate cases. Full feature and parameter coverage is not established. | [Mathics compatibility and remaining work](../Mathics/COMPATIBILITY.md) · [Evaluator notes](../MATHICS-NOTES.md) |
| Vendored article coverage | Successfully compute **all asymptotics developed in the articles under `vendor/proveit/docs`**, explicitly including q-analogs, their inverses, and combinatorial sequences. | Existing expansion engines supply relevant machinery. No complete mapping from article statements to implemented public requests and acceptance evidence has been established. The initial family inventory identifies the integration and mathematical obligations. | [Vendored asymptotics matrix](VENDORED_ASYMPTOTICS.md) · [Pinned article catalog](../../vendor/proveit/README.md) |

The three requirements overlap. An article algorithm is still subject to the
Mathics compatibility goal, and supporting a built-in on Wolfram does not
establish the corresponding Mathics behavior. An integer sequence's discrete
limit also needs its integer-domain semantics; a continuous interpolant and
its inverse must be identified separately.

## What successful coverage means

For the native-input requirement, record the complete request: source,
specification, options, assumptions, domain, and order. Compare the package
against the successful built-in result using mathematical equivalence and
the requested precision contract. An unresolved call, `Failure`, silently
weakened order, or unjustified remainder does not count as success. Different
storage and display forms are allowed. Current real-domain or routing guards
remain necessary correctness protections while their coverage gaps are
repaired; documenting them does not exempt those inputs from the target.

For Mathics, track each public operation and scale through loading, evaluation,
result construction, arithmetic, refinement, and applicable checking APIs.
Record modular and standalone behavior and use independent exact or analytic
oracles where available. A matching finite sample is evidence for those cases,
not universal interpreter equivalence. Runtime differences and unavailable
built-ins belong in the compatibility worklist until the required package
behavior is supplied.

For the vendored articles, identify the precise statement and its limit
regime before implementing it. Preserve parameter restrictions, branch or
interpolation choices, scale ordering, requested coefficient depth, and
remainder meaning. An all-orders theorem requires a method for arbitrary
requested finite order within its stated hypotheses; copying a few displayed
coefficients does not implement that theorem. Fixed-parameter, double-scaling,
endpoint, and central-limit results need separate acceptance cases.

The source articles distinguish proved, conditional, formal, conjectural,
and withdrawn statements. Preserve those distinctions. A conditional result
needs its hypotheses; a formal calculation must be labeled formal; an open
or withdrawn analytic claim requires mathematical resolution before it can
support a guaranteed analytic result. These obligations remain visible in
the article worklist rather than becoming unsupported correctness claims.

## Recording progress

For each implementation milestone, record:

1. The covered built-in request family, public package operation, or pinned
   article statement, including its domain and parameter regime.
2. The canonical source entry point, supported order/scale contract, and
   public example that computes the result.
3. The oracle or derivation, focused executable checks, tested runtimes,
   source hashes, and actual outcome.
4. Remaining input, mathematical, precision, resource, or portability gaps.

Use the [validation workflow](../../validation/README.md) for source-bound
evidence and the [implementation register](CODE_REVIEW_STATUS.md) for specific
reviewed repairs. Article/PDF freshness, local-link checks, and successful
document rendering establish artifact quality; they do not establish that
the mathematical algorithms are implemented or that these goals are complete.

The initial source audit behind this register used Asymptotic commit
`a4e1a3e3b09324f45b181843645eabbfa84abcdd` and the vendored ProveIt revision
recorded in its [manifest](../../vendor/proveit/manifest.json). Update the
detailed registers with each relevant code or corpus change.
