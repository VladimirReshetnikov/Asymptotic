# Native Wolfram observations

These are manually transcribed connector observations, not an upstream CI log.
The exact successful package inputs are in the three `*_connector_input.wl`
files next to this record. The source selected in each successful package run
was the root standalone at commit
`efa1aeec4845a9c35e140963a0333d0c9ec33b05`.

Runtime returned by the service:

```
15.0.0 for Linux x86 (64-bit) (May 6, 2026)
```

## N01: baseline public operations

`Import[..., "Text"]` returned a string of length 692380. That string was
loaded with `Get[StringToStream[src]]`. The following are selected fields of
the returned objects, not reconstructed predictions.

| Object | Kind | Scale | Expression | Remainder |
|---|---|---|---|---|
| `s` | Forward | not selected | `1` | `PowerLogRemainder[x,2,0]` |
| `t` | Derived | PowerLog | `0` | `PowerLogRemainder[x,-2,0]` |
| `Sin[t]` | Derived | Composite | `0` | `PowerLogRemainder[x,-2,0]` |
| `Cos[t]` | Derived | Composite | `1` | `PowerLogRemainder[x,-2,0]` |

The seed retained `a^2 == -1` and `x > 0`. The amplified object and its
trigonometric results retained nine copies of each predicate. The full
mathematical witness and a proof that both trigonometric errors are not
`O(x^-2)` are in the article.

## N02: baseline public self-addition

The raw returned result was:

```wl
{692380, {{{0,1,3,1,3}, {1,1,10,3,10}, {2,1,28,9,28},
           {3,1,82,27,82}, {4,1,244,81,244}, {5,1,730,243,730}}}}
```

Each row is `{depth, blockCount, assumptionLeafCount,
assumptionOccurrenceCount, domainLeafCount}`. The extra braces are the
actual `Reap` structure used in the executed input. The initial source was
`a x` with `a > 0`; each update was the public `SeriesAdd[s,s]`.

## In-memory candidate changes

Three exact anchors matched the complete retrieved standalone once each.
The edits are the same replacements stored in `patches/edits.json`.
After applying them to the string and loading the modified string, the raw
selected result was:

```wl
{{1,1,1}, {Failure,Failure},
 {"UnprovedRealRemainder","UnprovedRealRemainder"},
 {{{0,1,1,True}, {1,1,1,True}, {2,1,1,True},
   {3,1,1,True}, {4,1,1,True}, {5,1,1,True}}},
 GeneralizedSeries, GeneralizedSeries, GeneralizedSeries,
 0, PowerLogRemainder[x,-2,0]}
```

Here the first list gives anchor counts; the next two lists describe the
sine/cosine refusals. Each four-entry row is `{depth, assumptionOccurrences,
domainOccurrences, Normal[result] === 2^depth a x}`. The last three heads
are, respectively, sine and cosine of the real `1/(1-x)` expansion and
`Abs[t]`. The last two entries are the expression and remainder of `Abs[t]`.
No checkout or remote repository was modified.

## E01: independent Wolfram reference

The exact successful, fully qualified input is in `lerch_connector_input.wl`.
This tests the reference algorithm, not AsymptoticAnalysis's Lerch backend.
For q in `{0,1/2,9/10,1}`, s in `{1,2}`, a in `{1,100}`, and K in
`{0,1,4,8}`, all 64 combinations satisfied the exact endpoint ordering,
width identity, and universal width bound. Returned output:

```wl
{"15.0.0 for Linux x86 (64-bit) (May 6, 2026)", 64, True,
 <|"Lower" -> 447047/645120, "Upper" -> 447187/645120,
   "Width" -> 1/4608, "PartialSum" -> 148969/215040,
   "DifferenceCoefficient" -> 1/9, "Order" -> 8,
   "Parameters" -> {1,1,1}, "Arithmetic" -> "Exact rational arithmetic",
   "Theorem" -> "PositiveEulerDifferences"|>,
 22679550475318225809/7679474155727325039983857353312740000,
 Failure}
```

The large rational is the width for q=9/10, s=2, a=100, K=8. The final
`Failure` is the rejection of an approximate `0.5` input. The supplied WL
package wraps this arithmetic in its own context; its file loader and the
64-case file-based wrapper were not separately executed through the connector.

## Excluded attempts and limits

Some service calls failed with network/502 errors. Direct `Get` from a URL
also produced incomplete-download syntax errors on separate attempts; those
runs were discarded. Complete-text imports followed by `StringToStream`
succeeded for the observations above. An earlier reference call parsed
unqualified names before `BeginPackage`, leaving undefined Global symbols;
it was corrected with fully qualified names and is not a package finding.

The service is stateless between calls. No Mathics kernel, full upstream
suite, file-based WLT suite, installed candidate build, or elapsed-time
benchmark was run. The CLI observation wrapper and WLT acceptance file are
provided for reproduction, not represented as successfully executed suites.
