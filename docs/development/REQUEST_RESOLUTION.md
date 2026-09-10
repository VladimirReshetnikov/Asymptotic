# Request resolution workplan

This plan addresses **W3-01, W3-02, W3-03 and W3-15** in the
[wave-3 intake](WAVE_3_INTAKE.md). The current source checkpoint is `a76c0b5`.
The observations below are **source inspection only**; the proposed changes and
characterization matrix have **not been run against this checkpoint**.
Supplied reviewer executions remain historical evidence tied to their own
snapshots. This document does not claim these items are implemented or closed.

The affected code is [NativeCompatibility.wl](../../src/Kernel/NativeCompatibility.wl),
the public entry and assumption boundary in
[AsymptoticAnalysis.wl](../../src/Kernel/AsymptoticAnalysis.wl), and replay in
[SeriesOperations.wl](../../src/Kernel/SeriesOperations.wl). Preserve the existing
[native result contracts](NATIVE_RESULT_CONTRACTS.md) while changing request interpretation.

## Findings and current mechanisms

| Item | Supplied findings | Current mechanism |
| --- | --- | --- |
| W3-01 | [19 N01](../../external-reports/code-review/wave-3/code-review-19/article/audit.tex), [20 N01](../../external-reports/code-review/wave-3/code-review-20/article/asymptotic-incremental-review.tex), [21 N01](../../external-reports/code-review/wave-3/code-review-21/article/audit.tex), [23 N02](../../external-reports/code-review/wave-3/code-review-23/article/asymptotic-current-audit.tex), [24 N01](../../external-reports/code-review/wave-3/code-review-24/article/audit.tex), [25 N03](../../external-reports/code-review/wave-3/code-review-25/article/article.tex), [26 N1](../../external-reports/code-review/wave-3/code-review-26/article/asymptotic_native_boundary_audit.tex), [27 N01](../../external-reports/code-review/wave-3/code-review-27/article/asymptotic-audit.tex) | `expansionDispatch` substitutes `Automatic` for an omitted selector; the alias discards its entry identity; rule-form routing inspects explicit goal presence before the configured value. |
| W3-02 | 19 N02/N03; 20 N02; 21 N03; 24 N02; 25 N05; 26 N2/N3; 27 N02 | Computed keys bypass preparation, key spellings are compared structurally, and `nativeSpecificationQ` derives positional roles from option-name membership. |
| W3-03 | 20 N03; 21 N02; 27 N03 | `automaticProtectedQ` recursively protects every `Function`, including consumed identity functions and functions inside algebraic `Root` representations. |
| W3-15 | 27 N04 | Recursive consumers repeatedly call `nativeOptionTreeQ` on descendants already validated by their parents. |

Report 27's selector-only observations were 14, 44, 152 and 560 predicate visits
at depths 4, 8, 16 and 32, matching `d (d + 3)/2`. These are reviewer measurements,
not current whole-call timings or a claim that this work dominates typical expansions.

## Proposed request record

Retain one private record shared by routing, forwarding, protection, metadata and
diagnostics. Keep original syntax separate from prepared values:

```wl
<|"EntrySymbol" -> AsymptoticExpansion,
  "OriginalArguments" -> HoldComplete[...],
  "HeldSource" -> HoldComplete[...],
  "SourceState" -> "Original",             (* later: Prepared *)
  "SourceRole" -> ...,
  "Specifications" -> {...},               (* ordered, individually held *)
  "OptionOccurrences" -> {...},            (* ordered; retain duplicates *)
  "ExplicitOptionNames" -> {...},
  "Defaults" -> {...},                     (* held snapshot *)
  "ResolvedValues" -> <||>,                (* only values already consumed *)
  "Backend" -> ...,
  "BackendOrigin" -> ...,
  "ProtectedObligations" -> {...},
  "UnclassifiedArguments" -> {...}|>
```

Each option occurrence should retain its original rule, resolved identity,
position, origin and rule kind. Keep the record request-local, including during
retry. Do not introduce a global cache indexed only by syntax.

## Roles, identity and evaluation

1. Capture the public entry, original held arguments and applicable assumption
   context. Preserve the existing neutral context for package proofs.
2. Classify container structure without evaluating keys or values. Annotate each
   node once as a rule, an option container, a specification candidate or data.
3. Assign positional roles before normalizing option identity. The first required
   rule specification may use `Method` as its variable; a later `Method` rule may
   be an option. Preserve ordered successive native specifications.
4. In admitted option subtrees, resolve each computed key once. A resolved symbol
   maps to `SymbolName`; a string remains verbatim. Do not use `ToExpression` or
   strip context-looking substrings from arbitrary strings. Unknown names stay unknown.
5. Collect selectors, other options and cleaned forwarding syntax from those same
   annotations. Do not rescan raw syntax independently to infer metadata.
6. Resolve a selected value once when its route needs it, then reuse that value.
   Keep delayed values held during key classification and metadata construction.

[OptionValue](https://reference.wolfram.com/language/ref/OptionValue.html) documents
symbol/string name equivalence, context-independent symbol-name comparison,
first applicable default precedence, and held value retrieval. Its four-argument
held form is a candidate mechanism to characterize before adopting it here.

Do not discard duplicate rules during structural classification. Immediate rule
RHS expressions can have native evaluation effects even when a later option lookup
does not choose them. Unused delayed duplicates must remain unevaluated where the
applicable protocol does not consume them. Literal explicit native calls should
retain their direct delegation behavior; automatic retries must reuse consumed
source, specification and common-option values. Computed-container preparation
already has a distinct evaluation-order contract and must not be advertised as
emulating every direct native program's side-effect order.

Use two bounded structural passes: classification, then emission of admitted
options and forwarding syntax. Do not evaluate keys in a data list merely because
it contains a rule. Measure structural visits separately from reconstruction cost,
user-program cost and whole-call time before claiming linear performance.

## Default ownership: recommendation and alternatives

**Proposed policy:** independently configurable public entries with one shared
implementation. Pass the actual entry symbol through held preparation. Both heads
initially have the same defaults, and each honors its own `SetOptions`; this makes
the two existing published option tables operational. Document that ownership.

A **single-owner synonym** is also coherent: configure `AsymptoticExpansion`, and
make the alias's configuration surface accurately reflect that ownership. Merely
appending an alias backend default solves only one key and leaves its other
published defaults ambiguous. Alias ownership remains a decision to settle before
implementation; this plan does not declare either policy implemented.

Resolve `Backend` from the first explicit occurrence or the owning entry's current
default. Resolve the effective `SeriesTermGoal` before choosing package block
counting versus native leading-order routing. Track explicit and default origin
separately: materializing every default as an explicit rule would manufacture
direction/budget restrictions and native-only routing on ordinary requests.

For configured native-only options, comparing held current defaults with held
initialization defaults is a possible compatibility policy: only changed rules
become `Configured` overrides, while untouched native omissions retain native
defaults. This cannot recover a `SetOptions` assignment that reasserted the initial
value. Decide and document that limitation before extending the narrow backend
and common-option repair into a complete configured-native-profile claim.

## Internal replay and callable protection

`SeriesRefine` replays inverse expressions and forward sources through the public
`AsymptoticExpansion` entry without an explicit backend or term goal. Honoring
configured defaults could therefore change an existing analytic result's contract
or cap a refinement unexpectedly. In the narrow repair, pin those calls to
`"Backend" -> "Package"` and `SeriesTermGoal -> Automatic`, retaining their explicit
stored assumptions, direction and branch settings. They already request a cutoff.
Exact-source composition already pins the package backend.

If configured native-only profiles are added, use a private analytic replay entry
or an explicit internal default policy so those profiles cannot affect stored
recipes. A backend selector alone does not provide that broader insulation.

For W3-03, remove only recursive `Function` protection and recognize top-level
`Function`/`forwardCallable` in original and prepared source. Preserve existing
deep inverse, conditional, series and remainder protection, together with explicit
direction, branch and resource obligations. Reuse prepared source values. A source
program that returns an unapplied function on a native-only-option route needs
separate characterization; applied-identity tests do not establish that case.

## Bounded implementation and characterization

Sequence: characterize the boundaries below; implement the shared role/identity
parser and traversal repair; add default ownership with replay insulation; then
land the narrow callable-role change. Preserve native order and package exclusive
cutoff semantics throughout. Sparse native storage, outcome classification,
conditional-source policy and discrete backends are separate wave-3 work items.

| Characterization | Concrete cases and observations to record |
| --- | --- |
| Backend defaults | Configure each backend on each public head; compare omitted and explicit selection, invalid defaults, explicit overrides, duplicate precedence and delayed-default counters. Restore both option tables after every case. |
| Configured goals | Set `SeriesTermGoal -> 4`, then expand `Exp[x]` with `x -> 0`; also characterize `Automatic`, `0` and delayed configured goals against explicit calls. |
| Replay insulation | Construct an analytic result, change backend/goal defaults, then refine and replay derived operations. Check kind, coefficients, cutoff, remainder and stored assumptions. |
| Key preparation | `(keyCalls++; "Backend") :> (valueCalls++; "Series")`; stored key aliases; nested containers; unused delayed duplicates; rules inside source and option-value data. |
| Option identity | Symbol, string and another-context symbols for `Assumptions`, `Analytic`, `SeriesTermGoal` and `Backend`; check result, routing, metadata, application and counters. |
| Positional roles | `Asymptotic[Sin[Method], Method -> 0]`; a later genuine `Method -> Automatic`; successive list specifications; unknown symbolic/string suffix options. |
| Native grammar limits | Direct native calls with successive rule specifications, options before specifications and mixed `Sequence` forms. Do not guess their roles from option-name membership. |
| Source role | Named/slot applied identities around `Exp[I x]`, source counters, genuine callables, `Root[1 + # + #^4 &, 1]`, and the protected inverse/condition/direction/budget controls. |
| Traversal | Depths 4/8/16/32/64 and wide option lists; count visits independently of native computation and check that data-list keys/values are not executed by classification. |

The documented successive [Series](https://reference.wolfram.com/language/ref/Series.html)
form uses list specifications. Broader forms require the direct native probes above.
For strict package mode, a rule after the complete coordinate specification must
be an admitted option or produce a structured refusal. Explicit native delegation
must preserve broader native syntax without inventing specification metadata.
