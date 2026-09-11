# GeneralizedSeries result properties

Use this reference when inspecting an expansion, comparing result families,
or writing code that consumes their metadata. The [user guide](UserGuide.md#GeneralizedSeries)
provides worked examples; this page describes the property dispatch and
constructor layouts inspected at commit
`41ac72d52f654465e2ce62e081326df70e5f4d26`. This is a source audit, not a new
Wolfram or Mathics execution record. Complete native-input and Mathics
coverage remain the goals recorded in the [coverage register](../../docs/development/COVERAGE_TARGETS.md).

## Read an object

Successful expansion objects have the form `GeneralizedSeries[association]`.
The association is family-specific: **there is no universal list of populated
properties**. Inspect the actual object before relying on a field.

```wolfram
s = AsymptoticExpansion[Sin[x], {x, 0, 5}, "Backend" -> "Package"];
s["Properties"]
Table[{key, s[key]}, {key, {"Kind", "Scale", "Variable", "Remainder"}}]
Normal[s]
```

| Expression | Implemented behavior |
| --- | --- |
| `s["Properties"]` | Returns the stored association's keys. This accessor is implemented separately and is not itself normally a stored key. |
| `s["name"]` | Looks up that exact, case-sensitive string. An absent key returns `Missing["KeyAbsent", "name"]`; it does not raise a property-specific `Failure`. |
| `Normal[s]` | Returns the stored `"Expression"`. It does not return the remainder or validate an error bound. |
| `s[value]`, when `NumericQ[value]` is true | Substitutes into the stored expression using `"Variable"`. This is finite-expression evaluation for analytic objects, not an inverse solve or interval certificate. It does not check `"TargetDomain"`. Native objects additionally require one recognized symbolic variable. |
| `InputForm[s]` | Exposes the object and its association rather than the usual mathematical display. |

A symbol such as `s[Scale]` is not a string-property lookup. A missing key
and a present key containing `Missing[...]` are different: use
`MemberQ[s["Properties"], "Scale"]` to distinguish them. Nested associations
are values, not additional top-level properties; inspect a contract with,
for example, `s["MajorantContract"]` before looking up its own keys.

StandardForm and TraditionalForm normally display the analytic expression
and its remainder without the object head. Native objects display
`"NativeResult"`. The display retains an interpretation of the original
object; changing displayed coefficients is not an operation that updates
branch or precision metadata. Mathics/front-end box behavior can differ;
inspect `Normal`, explicit properties, and InputForm when comparing runtimes.

Source: [object access, evaluation, and formatting](../Kernel/AsymptoticAnalysis.wl),
[native numerical application](../Kernel/NativeCompatibility.wl), and
[Mathics formatting adapters](../Kernel/MathicsFormatting.wl).

## Identify the result family

`"Kind"` describes the constructor/result role; `"Scale"` describes the
representation. They are not always equal. In particular, an ordinary
forward object has **no stored `"Scale"` key**, and an imported
special-function result can have `"Kind" -> "Forward"` with a
`"PowerLog"`, `"Factored"`, or `"Composite"` scale.

| Kind | Scale | What to inspect next |
| --- | --- | --- |
| `"Forward"` | Absent for the ordinary constructor; `"PowerLog"`, `"Factored"`, or `"Composite"` on specialized paths | [Ordinary and factored forward results](#ordinary-and-factored-forward-results), then any special-function metadata. |
| `"Inverse"` | `"PowerLog"` | [Ordinary inverse results](#ordinary-inverse-results). |
| `"Inverse"` | `"Logarithmic"` | [Lambert logarithmic results](#lambert-logarithmic-results). |
| `"Inverse"` | `"Transformed"` | [Coordinate transformations](#coordinate-transformations). |
| `"LogarithmicInverse"` | `"ReciprocalLogUnit"`, `"LeadingLogMonomial"`, or `"GeneralizedLogarithmicCoefficients"` | [Finite logarithmic hierarchies](#finite-logarithmic-hierarchies). |
| `"Derived"` | `"PowerLog"`, `"Factored"`, or `"ReciprocalLogCalculus"` | [Ordered arithmetic results](#ordered-arithmetic-results). |
| `"Derived"` | `"Composite"` | [Composite results](#composite-results). Specialized forward paths can also use this scale with kind `"Forward"`. |
| `"CoreInverse"` | `"ExactCorePerturbation"` | [Exact-core marker expansions](#exact-core-marker-expansions). |
| `"ExponentialCoreInverse"` | `"ExactExponentialCoreSectors"` | [Exact exponential-core sectors](#exact-exponential-core-sectors). |
| `"FlatInverse"` or `"FlatDerived"` | `"FiniteFlatSectors"` | [Finite flat sectors](#finite-flat-sectors). |
| `"FourierInverse"` | `"FourierPolynomialCoefficients"` | [Fourier coefficient results](#fourier-coefficient-results). |
| `"GammaInverse"` or `"BarnesGInverse"` | The same string as the kind | [Gamma and Barnes inverse results](#gamma-and-barnes-inverse-results). |
| `"SpecialInverse"` | `"SpecialFunction"` | [Explicit special inverse adapters](#explicit-special-inverse-adapters). |
| `"Native"` | `"Native"` | [Native results](#native-results). These do not carry a package analytic remainder. |

The mathematical coordinate is not determined by the scale name alone.
For example, a Zeta Dirichlet expansion can use an ordered power-log
representation in `Exp[-SourceArgument]`. Read `"TermConvention"` and the
coordinate properties of the actual result.

## Frequently used properties

The first four rows are shared by the inspected constructor families. The
remaining rows describe commonly encountered fields whose availability
depends on the family and construction path.

| Property | Meaning and availability |
| --- | --- |
| `"Kind"` | Result role from the family table. |
| `"Expression"` | The value returned by `Normal`. Analytic constructors store the retained finite expression; native constructors store `Normal[NativeResult]` as computed during construction. The latter can be nonfinite or unresolved. |
| `"Remainder"` | The analytic error descriptor, possibly zero or a sum of scaled descriptors. Native results store `Missing["NativeContract"]`. |
| `"Variable"`, `"Assumptions"` | Expression variable and retained assumptions. Native `"Variable"` can be missing, and native `"Assumptions"` is `Missing["NativeContract"]`; its ambient context is stored separately. |
| `"Scale"` | Representation identifier, when stored. Its absence on an ordinary forward result is expected. |
| `"Terms"`, `"Blocks"`, `"TermConvention"` | Human-facing terms, internal coefficient blocks, and their interpretation. Their shapes and exponent conventions differ by family. Some families have no `"Blocks"`; Composite and Native results have no common term table. |
| `"RemainderVariable"`, `"RemainderPower"`, `"RemainderLogDegree"` | Coordinate and order of a single power-log error component, where supplied. Prefactors, inverse logarithms, and separate sector errors can also be needed. These fields are not a universal replacement for `"Remainder"`. |
| `"RemainderScaleExpression"` | An ordinary expression describing the asymptotic error scale. It generally has an unspecified constant and threshold; it is not by itself an explicit numerical upper bound. It is absent from an ordinary forward object and from a newly constructed ordinary inverse. |
| `"FrontierTerm"` | A computed first omitted contribution where available. It can be zero or `Missing[...]`. A zero coefficient alone does not prove the entire omitted tail vanishes. |
| `"Cutoff"`, `"RequestedCutoff"`, `"Truncation"` | Family-specific cutoff/request metadata. A cutoff may be an exponent, a different coordinate's exponent, or an explicit `Missing` value. Some families use `"MarkerDepth"` or `"SectorDepth"` instead. Names do not impose one cross-family convention. |
| `"RequestedTermGoal"`, `"ReturnedTermCount"` | Stored goal and actual retained block count on supporting paths. They are not populated universally. Special-function carrier counts can aggregate separate per-carrier selections. |
| `"Function"`, `"Variables"` | Retained source and, on many inverse results, `{sourceVariable, targetVariable}`. Arithmetic results generally use a recipe or representation instead of a single source function. |
| `"ExpansionPoint"`, `"Direction"`, `"Limit"` | Forward results record the expansion variable's endpoint and approach. Ordinary inverse results record the **source** endpoint/approach and the **target** limit separately. Ordered arithmetic can omit these top-level fields. |
| `"Model"` (`"ModelOffset"`, `"TargetLimit"`, `"Limit"`, `"LeadingCoefficient"`, `"LeadingPower"`, `"Gaps"`, `"Polynomials"`) | The normalized forward model retained by an ordinary inverse and returned by `PowerLogModel`. `"ModelOffset"`, also returned as the legacy `"Limit"`, is the baseline extracted by normalization and is `0` for a pole; `"TargetLimit"` is the analytic limit on the admitted approach, a signed infinity for a pole with a proved leading sign, or `Missing["Unresolved", "LeadingSign"]`. |
| `InverseExpansionCoefficient` fields `"LocalCoefficient"`, `"SourceOrientation"`, `"ObservableCoefficient"`, `"AdditiveOffset"`, `"ContributionExpression"`, `"ObservableMeaning"` | On a result object, the chart needed to read a normalized local coefficient as part of the represented observable: the orientation sign of the source chart, the coefficient multiplied by `SourceOrientation^Power`, the finite endpoint added once for power one, and the contribution in the target variable. `"Coefficient"` and `"Meaning"` keep the local reading. |
| `"SourceDomain"`, `"TargetDomain"`, `"Branch"` | Retained domain conditions and branch description where supplied. A target coordinate condition is not automatically a global injectivity theorem. Their absence is not a declaration that every input value is allowed. |
| `"Method"`, `"RequestedMethod"` | Selected algorithm and requested method when recorded. Specialized constructors may record an internal algorithm name different from the requested method. |
| `"RemainderDerivativeOrder"` | Available derivative-order information where supplied. Zero does not authorize differentiating an arbitrary unknown error; infinity can represent support for every fixed derivative order, not a bound uniform in the order. Flat operations also use their separate analytic provenance. |
| `"SeriesData"` | Optional native dense view of an analytic result, often a `Missing` value. Native backend objects instead have `"NativeResult"` and do not store this key. See [missing values](#missing-values-and-unavailable-views). |

### Exactness fields are different contracts

| Field | What it does and does not establish |
| --- | --- |
| `"Exact"` | Where analytic constructors supply it, indicates that their returned remainder is zero under the retained contract. Many inverse constructors do not supply this key at all. Native results supply `Missing["NotEstablished"]`. |
| `"ExactModel"` | Family-specific information about the forward/core model. An exact source model can still have an infinite inverse expansion and a nonzero truncation remainder. This is not a replacement for `"Exact"`. |
| `"ExactInverse"` | Exact-core marker and exponential-core constructors use this to record whether their final remainder is zero. It is not the same property as `"ExactInverseExpression"`. |
| `"ExactInverseExpression"`, `"ExactObservableExpression"` | A retained exact expression on supporting branches, or a family-specific `Missing` reason. Its availability does not mean the separately returned asymptotic truncation has zero remainder. |
| `"ExactTerminationCertificate"` | Additional symbolic-composition evidence where exact termination was established; it can also be absent or `None`. |
| `"ExactSourceEqualityVerified"` | Special-function import evidence comparing the source with the constructed native expression before the final retained truncation. Consult the final remainder; this flag alone does not remove it. |
| `"MajorantContract"`, `"ConvergenceContract"`, `"ForwardRemainderContract"`, `"AnalyticRemainderContract"` | Structured statements with family-specific scope. A nested `"NumericCertificate" -> False` explicitly distinguishes an asymptotic or analytic-existence contract from a numerical enclosure. |

Use the [checking APIs](UserGuide.md#InverseResidual) for residual, numerical,
and interval evidence. Their returned associations are separate objects;
their fields are not automatically properties of the input `GeneralizedSeries`.

## Ordinary and factored forward results

Source: [ordinary forward construction](../Kernel/AsymptoticAnalysis.wl),
[factored Gamma/logarithmic construction](../Kernel/GammaForward.wl), and
[Barnes](../Kernel/BarnesForward.wl) and
[elementary exponential](../Kernel/ExponentialForward.wl) adapters.

| Properties | Interpretation |
| --- | --- |
| `"Terms"` | Ordinary forward pairs `{beta, coefficient}` contribute `w^beta coefficient`, with logarithms already substituted in the coefficient. `w` is the recorded local/remainder coordinate. |
| `"Blocks"`, `"LogVariable"`, `"LocalVariable"` | Internal rows and formal logarithmic/local symbols before the displayed coordinate substitution. Do not read a block exponent as an exponent of the original variable at infinity. |
| `"Precision"` | The source jet's `{power, logDegree}` precision. Truncation can introduce an earlier omitted term, so this pair need not equal the returned remainder's order. |
| `"Prefactor"`, `"Offset"`, `"SeriesRepresentation"`, `"SeriesRecipe"` | Factored forward results inherit ordered-arithmetic storage: the correction series is inside the prefactor and added to the offset. The ordinary constructor does not populate these fields. |
| `"LogarithmicExpansion"`, `"LogarithmicFunction"`, `"ExpansionNature"` | Retained logarithmic model, its source, and expansion classification on the factored logarithmic path. |
| `"GammaFactors"`, `"GammaExpression"`, `"GammaPower"` | Gamma-product normalization metadata when that adapter supplied it. `"GammaPower"` can be `Missing["NotSingleGamma"]`. |
| `"BarnesFactors"`, `"BarnesExpression"` | Barnes-product normalization metadata. This forward path also retains any `"GammaFactors"`; it does not add the inverse family's `"BarnesPower"` field. |
| `"NormalizedExpression"`, `"Transformation"`, `"AsymptoticReference"` | Optional source normalization and provenance metadata. Their presence depends on which transformation ran. |

## Ordinary inverse results

Source: [inverse construction](../Kernel/AsymptoticAnalysis.wl) and
[retained-state refinement](../Kernel/RefinementState.wl).

| Properties | Interpretation |
| --- | --- |
| `"LeadingCoefficient"`, `"LeadingPower"`, `"Uniformizer"` | Leading forward model and its inverse coordinate. For target displacement `v`, coefficient `a`, and source power `p`, the uniformizer is `(v/a)^(1/p)` on the selected real branch. |
| `"Terms"`, `"Blocks"`, `"LogVariable"` | Terms contain powers of `v/a` and substituted coefficients; blocks retain normalized source-weight corrections. The final expression also reconstructs the source endpoint and side. Follow `"TermConvention"`, especially for negative source powers or nonunit observables. |
| `"Power"` | Selected inverse observable, with source-coordinate conventions described in the guide. It is not the retained cutoff. |
| `"Model"`, `"ForwardExpansion"` | The parsed inverse coefficient model and the finite forward expression used by it. A forward result having `"Terms"` does not imply it has this inverse model. |
| `"LocalVariable"`, `"LocalSubstitution"`, `"Variables"` | Local source symbol, reconstruction rule, and source/target variables. |
| `"InputRemainder"`, `"DeclaredInputRemainder"` | Effective forward-model precision and the caller's declared input remainder. This uncertainty can cap the output cutoff even when more inverse coefficients could be generated formally. |
| `"ExactModel"`, `"ExactTerminationCertificate"` | Model exactness and separate inverse-termination evidence. A newly constructed ordinary inverse has no `"Exact"` key. |
| `"ComputationState"` | Retained internal coefficient/enumeration state. Treat it as implementation provenance, not as a portable serialized API schema. |

## Lambert logarithmic results

Source: [LambertInverse.wl](../Kernel/LambertInverse.wl).

| Properties | Interpretation |
| --- | --- |
| `"Prefactor"`, `"LogarithmicVariable"`, `"Terms"`, `"Cutoff"` | Each pair contributes `Prefactor t^n C`, where `t` is the positive logarithmic coordinate. The cutoff is exclusive in the bracket exponent; finite source reconstruction can add an endpoint. |
| `"LambertBranch"`, `"LambertArgument"`, `"LambertSign"`, `"LambertLogMagnitude"` | Selected real Lambert branch and normalization data. |
| `"LeadingCore"`, `"LeadingCoreOnly"`, `"BeyondLogarithmicOrders"` | Leading solvable model, whether additional source terms remain, and those omitted higher-source-power terms. The latter are not silently asserted to be zero. |
| `"CoreInverseExpression"`, `"CoreObservableExpression"`, `"ExactInverseExpression"`, `"ExactObservableExpression"` | Exact core formulas versus exact full-source formulas; a missing closed form is represented by `Missing["NoClosedFormInverse"]`. |
| `"LambertSeedExpression"`, `"CoreParameters"`, `"LambertCoreType"` | Seed and classified core data for further checking/reconstruction. |
| `"LambertCorrectionBlocks"`, `"LambertUnitPower"`, `"LambertResidualCutoff"`, `"LambertResidualCoefficients"` | Normalized unit and residual-calculation metadata. These are internal-coordinate quantities, not an additional independent remainder theorem. |
| `"LambertPolynomialLog"`, `"LambertLocalObservablePower"`, `"LambertLogDegree"`, `"LambertScaleFactor"` | Polynomial-logarithmic core flag, local observable power, and normalization parameters used by the residual calculation. |
| `"RemainderExplanation"`, `"TargetDomainMeaning"` | Scope of logarithmic truncation and target-domain conditions. |
| `"Model"`, `"SeriesData"` | Both store `Missing["LogarithmicScale"]`; the ordinary inverse coefficient-model/native-view contracts do not apply. |

## Finite logarithmic hierarchies

Source: [LogarithmicScales.wl](../Kernel/LogarithmicScales.wl).

| Properties | Interpretation and family boundary |
| --- | --- |
| `"LogarithmicLevels"`, `"SourceLogarithmicLevels"` | Number of represented logarithmic levels and, for logarithmic-unit constructors, their source-coordinate expressions. |
| `"Prefactor"`, `"Offset"`, `"LogarithmicVariable"`, `"FormalVariable"` | Unit-constructor coordinates for `"ReciprocalLogUnit"` and `"LeadingLogMonomial"`. Their exponent cutoff applies in the normalized logarithmic unit. |
| `"CoefficientLevelSubstitutions"`, `"LeadingLocalApproximation"` | Substitutions and leading approximation for unit construction. |
| `"LogarithmicEquationData"`, `"LogarithmicUnitPolynomial"`, `"LogarithmicObservablePolynomial"` | Retained normalized equation and finite implicit/observable polynomial calculations for the unit paths. |
| `"CoefficientLevels"`, `"CoefficientLevelValues"`, `"NormalizedSourceWeightCutoff"` | Generalized-logarithmic coefficient symbols, their target values, and the source-weight cutoff. This family uses a target-power cutoff, not the unit family's cutoff convention. |
| `"PowerGaps"`, `"NormalizedCoefficients"`, `"CoefficientDegreeBounds"`, `"IndexRegion"` | Generalized-logarithmic multi-index model and its finite coefficient/boundary data. |
| `"BeyondLogarithmicOrders"`, `"BeyondLogarithmicRemainderScale"` | Higher-source-power contributions on the unit paths and their separately retained bound scale. |
| `"SeriesRepresentation"` | A usable ordered representation for `"ReciprocalLogUnit"`; `Missing["NestedLogarithmicCoefficients"]` for the leading-log unit path. The generalized coefficient constructor does not ordinarily supply it. |
| `"TermGoalReached"`, `"TermSelection"`, `"TermGoalConstructionCalls"` | Additional metadata only when a term-goal search ran. Exact termination can produce fewer blocks than requested, with separate termination evidence. |

## Ordered arithmetic results

Source: [SeriesOperations.wl](../Kernel/SeriesOperations.wl) and
[ReciprocalLogOperations.wl](../Kernel/ReciprocalLogOperations.wl).

| Properties | Interpretation |
| --- | --- |
| `"Offset"`, `"Prefactor"`, `"Terms"`, `"RemainderVariable"` | The expression is the offset plus the prefactor times the ordered correction series. The remainder includes the absolute prefactor. |
| `"SeriesRepresentation"` | Nested representation containing the positive scale coordinate, formal logarithm, coefficient jet, assumptions, domain, and precision data needed by arithmetic. |
| `"SeriesRecipe"` | Retained operation recipe and operands, used when supported refinement needs to replay the construction. |
| `"ObservableCondition"` | Present when `SeriesObservable` peeled an outer `ConditionalExpression` and proved its condition on the input germ before an exact logarithm, exponential or power route computed the carrier; refinement replays the conditional observable. |
| `"ReciprocalLogRepresentation"`, `"AnalyticRemainderContract"`, `"InputDomains"` | Additional reciprocal-logarithmic arithmetic data and the holomorphic-unit derivative contract. These belong to `"ReciprocalLogCalculus"`, not every logarithmic result. |

An arithmetic result need not retain a constructor's `"Function"`,
`"ExpansionPoint"`, `"Direction"`, or inverse `"Model"` as top-level
properties. Use its representation and recipe for the supported operations;
do not fill missing metadata by copying it from an unrelated operand.

## Composite results

Source: [SeriesEnvelopeArithmetic.wl](../Kernel/SeriesEnvelopeArithmetic.wl).

| Properties | Interpretation |
| --- | --- |
| `"Expression"`, `"Remainder"`, `"RemainderScaleExpression"` | Retained finite expression, sum of separate error descriptors, and corresponding asymptotic envelope. Unknown errors do not cancel merely because finite expressions cancel. |
| `"SeriesApproach"` | Nested target variable, endpoint, and direction data for the common approach. |
| `"CompositeRecipe"` | Retained construction/operation provenance. |
| `"MajorantContract"` | Composite asymptotic-envelope statement; not a numerical enclosure. |
| `"SeriesData"` | `Missing["CompositeErrorScales"]`. |

The generic Composite constructor does **not** store `"Terms"`, `"Blocks"`,
`"Cutoff"`, `"RemainderPower"`, `"RemainderLogDegree"`, or
`"RemainderVariable"`. There is no single exponent ordering for its different
error scales. A specialized forward wrapper can add metadata such as
`"NativeSectors"` without creating a universal Composite term table.

## Exact-core marker expansions

Source: [CorePerturbation.wl](../Kernel/CorePerturbation.wl).

| Properties | Interpretation |
| --- | --- |
| `"Core"`, `"Perturbation"`, `"CoreInverse"`, `"CoreLocalInverse"` | Exact chosen core, its perturbation, and source/local core inverses. |
| `"CoreCertificate"`, `"CoreModel"` | Core identity/branch evidence and parsed core model. |
| `"ObservableExpression"`, `"ObservableConvention"`, `"CoreObservableExpression"`, `"LocalObservableExpression"`, `"LocalObservablePower"` | Selected source observable and its local/core versions. |
| `"Terms"`, `"MarkerTerms"`, `"LocalMarkerTerms"`, `"MarkerDepth"` | Complete perturbation-marker coefficients through the inclusive depth. These are not exponent-sorted power-log blocks. |
| `"FirstOmittedMarkerTerm"`, `"FirstOmittedMarkerDegree"` | Next marker contribution and its degree; the majorant governs the complete tail even if this contribution vanishes. |
| `"TruncationRemainderPair"`, `"InputRemainderPair"`, `"MajorantContract"` | Separate truncation/input precision and the full-tail existence bound. |
| `"ExactInverse"`, `"Cutoff"`, `"SeriesData"` | Final zero-remainder indicator; `Missing["MarkerDepth"]`; and `Missing["ExactCoreMarkerScale"]`, respectively. |

## Exact exponential-core sectors

Source: [ExponentialCorePerturbation.wl](../Kernel/ExponentialCorePerturbation.wl).

| Properties | Interpretation |
| --- | --- |
| `"CoreInverse"`, `"CoreLocalInverse"`, `"CoreParameters"`, `"CoreCertificate"` | Exact growing exponential core and its normalized inverse data. |
| `"SourceShift"`, `"SourceCoordinate"`, `"LocalVariable"`, `"LocalSubstitution"` | Shifted source chart and reconstruction. |
| `"ExactExponentialScale"`, `"SectorVariable"`, `"SectorVariableIdentity"` | Exponential small parameter and its exact expression through the retained core inverse. |
| `"Terms"`, `"Sectors"`, `"LocalSectorCoefficients"`, `"SectorDepth"`, `"FirstOmittedSector"` | Exact zero core term and positive sectors through inclusive depth, plus the first omitted sector. Positive terms contribute their coefficient times `SectorVariable` to the sector degree. |
| `"SectorRemainder"`, `"SectorRemainderScale"`, `"InputRemainderTerm"`, `"InputRemainderScale"`, `"InputRemainderContract"` | Separate model-sector and transported unknown-input errors. More model sectors need not reduce an input-error floor. |
| `"ExactInverse"`, `"Truncation"`, `"SeriesData"` | Final zero-remainder indicator; `"ExponentialSectorDepth"`; and `Missing["ExactExponentialCoreScale"]`. This constructor has no ordinary `"Cutoff"` key. |

## Finite flat sectors

Source: [FlatSectors.wl](../Kernel/FlatSectors.wl) and
[FlatSectorOperations.wl](../Kernel/FlatSectorOperations.wl).

| Properties | Interpretation |
| --- | --- |
| `"CoreInverseCoordinate"`, `"FlatScale"`, `"ZeroSector"` | Exact monomial core coordinate, exponential small parameter, and exact sector-zero expression. |
| `"Terms"`, `"Sectors"`, `"SectorDepth"` | Sector terms with inclusive degree cutoff. `"Terms"` includes sector zero; `"Sectors"` contains retained nonzero positive-sector coefficients. |
| `"FirstOmittedSector"` | Supplied by the inverse constructor. Derived flat arithmetic instead retains separate inner and sector errors. |
| `"InnerCutoff"`, `"InnerRemainders"`, `"RetainedCoefficientPrecision"`, `"SectorRemainder"`, `"SectorTailGrade"` | Derived arithmetic metadata: exclusive inner power cutoff, each positive sector's coefficient error, the complete omitted-sector error, and the least exponential sector at which that error was established before weakening to sector `N + 1`; `Infinity` for an exact result. |
| `"FlatAnalyticRemainder"`, `"RemainderDerivativeOrder"` | Specialized derivative provenance used by flat operations. |
| `"FlatRepresentation"`, `"FlatRecipe"` | Derived arithmetic state and recipe; absent from the original inverse constructor. |
| `"SeriesData"` | The inverse stores `Missing["IndependentFlatSectorTruncation"]`; derived arithmetic stores `Missing["IndependentFlatSectorTruncations"]`. Both deliberately decline a single native view. |

Neither constructor supplies a universal single `"RemainderPower"` for the
whole flat result. Read the complete `"Remainder"` or its scale expression.

## Fourier coefficient results

Source: [FourierCoefficients.wl](../Kernel/FourierCoefficients.wl).

| Properties | Interpretation |
| --- | --- |
| `"Terms"`, `"Blocks"`, `"FourierFrequencies"` | Displayed target-power terms, internal source-weight blocks with finite Fourier-polynomial modes, and retained exact frequencies. |
| `"MaxFrequencies"` | Admission/resource budget, not a claim that additional frequencies were approximated away. |
| `"CoefficientEnvelopes"`, `"CoefficientDegreeBounds"` | Absolute coefficient envelopes and logarithmic degree bounds used to control oscillatory errors. Zeros of an oscillatory factor are not an error scale. |
| `"LogVariable"`, `"LogarithmicValue"`, `"Uniformizer"` | Formal logarithm, its target substitution, and inverse uniformizer. |
| `"PowerGaps"`, `"NormalizedCoefficients"`, `"IndexRegion"`, `"NormalizedSourceWeightCutoff"` | Finite inverse coefficient model and source-weight selection data. |
| `"ConvergenceContract"`, `"InputRemainder"`, `"ExactModel"` | Finite analytic-lift contract and separate supplied-source precision. |
| `"SeriesData"` | `Missing["FourierCoefficientScale"]`. |

## Gamma and Barnes inverse results

Source: [GammaInverse.wl](../Kernel/GammaInverse.wl),
[BarnesInverse.wl](../Kernel/BarnesInverse.wl), and
[GammaInverseOperations.wl](../Kernel/GammaInverseOperations.wl).

| Properties | Interpretation |
| --- | --- |
| `"CoreInverse"`, `"CoreLogExpression"`, `"CoreArgumentOffset"`, `"RootSeedExpression"` | Retained Lambert core, its logarithmic coefficient coordinate, the Barnes/Gamma argument shift, and the reconstructed source seed. Gamma uses `Log[CoreInverse]`; Barnes uses `Log[CoreInverse] - 1`. |
| `"Terms"`, `"Blocks"`, `"CoefficientVariable"`, `"CoefficientSubstitution"` | Each `{beta, C}` contributes `CoreInverse^(-beta) C` after the stored coefficient substitution. `C` is a complete polynomial in the formal inverse-logarithmic coefficient variable; do not truncate that polynomial as a separate term count. |
| `"CoefficientFrontier"`, `"FrontierTerm"` | First omitted coefficient block and its target expression. |
| `"RemainderInverseLogPower"` | Inverse-logarithmic power multiplying the inverse-core remainder. It supplements `"RemainderPower"`; `"RemainderLogDegree" -> 0` does not mean the error has no inverse-log factor. |
| `"Cutoff"`, `"RequestedCutoff"` | On construction, `"RequestedCutoff"` preserves the incoming cutoff, including `Automatic`; `"Cutoff"` records the retained boundary chosen for a term goal or the explicit cutoff. An operation result records the cutoff it actually transports: when a request exceeds the precision the operands carry, `"Cutoff"` is the achieved value and `"RequestedCutoff"` the request. |
| `"SourceScale"`, `"SourceOffset"`, `"TargetScale"`, `"TargetOffset"`, `"TargetCoordinateExpression"` | Retained affine transformations and normalized target equation. |
| `"GammaFamily"`, `"GammaPower"` or `"BarnesFamily"`, `"BarnesPower"` | The selected function family and forward-function power. These are different from the inverse observable `"Power"`. Only the applicable family pair is stored. |
| `"ModelTerms"`, `"ForwardRemainderContract"`, `"ExactTransformedFunction"` | Finite Stirling/Barnes forward-model scope and original logarithmic equation. `"Exact"` and `"ExactModel"` are false in these constructors. |
| `"GammaInverseOperation"`, `"BarnesGInverseOperation"` | Optional power-operation provenance, including inherited and effective precision. Only the applicable operation key is added. |
| `"SeriesData"` | `Missing["PolynomialInverseLogCoefficients"]`. |

## Coordinate transformations

Source: [CoordinateInverse.wl](../Kernel/CoordinateInverse.wl) and
[SourceCoordinates.wl](../Kernel/SourceCoordinates.wl).

| Properties | Interpretation |
| --- | --- |
| `"CoordinateKind"` | `"TargetLog"`, `"SourceExp"`, or `"SourceLog"` on the inspected paths. |
| `"CoordinateSeries"`, `"CoordinateSubstitution"`, `"TargetCoordinateExpression"` | Underlying series and the exact target substitution. Consult that series' term/cutoff convention for target-log transformations. |
| `"TransformedFunction"`, `"Transformations"` | Transformed forward source and recorded coordinate maps. |
| `"ReconstructedSeries"` | Source-coordinate paths retain the series after reconstruction separately from the chart inverse. |
| `"SourceCoordinateVariable"`, `"SourceCoordinateEndpoint"`, `"SourceCoordinateDirection"`, `"SourceCoordinateExpression"`, `"SourceTransformExpression"` | Source-chart data on `"SourceExp"` and `"SourceLog"` paths. |
| `"ObservableToCoordinateVariable"`, `"ObservableToCoordinateExpression"` | Reverse map used to interpret the reconstructed source observable in its chart. |
| `"ExactSourceCertificate"` | Optional source identity/composition evidence on a certified chart path. |

These wrappers retain and transform underlying metadata. The same key can
describe the underlying chart rather than an ordinary target-power series;
do not reconstruct a transformed result from `"Terms"` without its
`"TermConvention"` and coordinate data.

## Explicit special inverse adapters

Source: [SpecialFunctionAdapters.wl](../Kernel/SpecialFunctionAdapters.wl).
These are distinct from the ordered Gamma/Barnes inverse families above.

| Properties | Interpretation and availability |
| --- | --- |
| `"Adapter"` | `"Erfc"`, `"Gamma"`, `"LogGamma"`, `"LambertThreshold"`, or `"QuadraticThreshold"`. |
| `"CoordinateSeries"`, `"CoordinateSubstitution"`, `"TargetCoordinateExpression"` | Underlying inverse calculation and target normalization; further properties are inherited from that calculation. |
| `"ForwardModel"`, `"TransformedFunction"`, `"ExactTransformedFunction"`, `"ModelTerms"` | Finite model versus original transformed equation on the Erfc and Gamma/LogGamma paths. |
| `"ForwardRemainderBound"`, `"ForwardDerivativeRemainderBound"`, `"ForwardBoundConditions"`, `"ForwardRemainderContract"` | Explicit forward-model bounds where that adapter supplies them. Gamma bounds apply to the transformed LogGamma equation, not directly to Gamma values. |
| `"TransformedDerivativeLowerBound"`, `"OriginalDerivativeLowerBound"`, `"DerivativeLowerBoundScope"` | Gamma/LogGamma adapters: the Stirling lower bound `Log[x] - 1/(2 x) - 1/(12 x^2)` for the derivative of `LogGamma` in the transformed equation, the bound for the absolute derivative of the stored original `offset + scale f[x]` (scaled, and multiplied by `Gamma[x]` for the Gamma family) on the source branch `x > 2`, and the sentences naming each scope. |
| `"PositiveTailExpression"`, `"SourceSign"`, `"NormalizedTailPolynomial"`, `"NormalizedTailRemainderBound"`, `"NormalizedTailDerivativeRemainderBound"` | Erfc tail normalization and its error information. |
| `"PhaseRemainderBound"`, `"PhaseDerivativeRemainderBound"`, `"PhaseBoundConditions"` | Erfc logarithmic-phase bounds and their additional positivity condition. |
| `"AccuracyFloor"`, `"AdapterCutoffMeaning"`, `"SwitchingContract"` | Model-limited attainable order and adapter scope when supplied. This `"AccuracyFloor"` is model metadata, not a completed numerical certificate. |
| `"ThresholdBranch"`, `"ThresholdTarget"`, `"ThresholdUniformizer"`, `"ExactInverseExpression"`, `"ExactForwardModel"` | Threshold-adapter branch, target, ramified coordinate, and exact-source information. The quadratic branch field uses `Missing["QuadraticSourceDirection"]`; source `"Direction"` selects that branch. |

## Forward special-function metadata

These properties augment the forward/ordered/Composite result appropriate
to the actual expansion. A property name containing `Native` does **not**
make an analytic result a `"Native"`-kind result.

| Properties | Interpretation |
| --- | --- |
| `"NativeSectors"`, `"NativeSeriesOrder"`, `"NativeSeriesBackend"` | Analytic special-function import's exact carriers, amplitude blocks, working native order, and backend description. This path separately justifies the imported error. |
| `"RealDomainProof"`, `"NormalizedExpression"`, `"ExactSourceEqualityVerified"`, `"AsymptoticReferences"` | Real-domain admission, normalization, exact-source comparison, and references recorded by special-function import. A finite-point ordinary shortcut need not populate every import field. |
| `"SpecialFunctionFamily"`, `"SpecialFunctionBackend"`, `"SourceArgument"`, `"ParameterScope"` | Zeta/Lerch family, construction method, limiting argument, and fixed-parameter scope. |
| `"AffineCoefficients"`, `"SpecialFunctionAtom"` | Present only when an affine combination `alpha atom + beta` of one Zeta/Lerch atom was expanded: the fixed exact coefficients `{alpha, beta}` and the atom itself. Retained coefficients, `"FrontierTerm"` and the absolute bound are scaled by `alpha`; the signed `"RemainderLowerBound"` is kept only for positive `alpha` with no constant charged to the bound. |
| `"TargetOffset"` | Finite target value `y0` subtracted in the ordinary residual normalization `(f(g(y)) - y0)/(a z^p) - 1`; `0` at an infinite target. |
| `"LocalRoot"`, `"LocalApproximation"`, `"LocalReferenceObservable"`, `"ObservablePower"`, `"SourceOffset"`, `"SourceSide"`, `"LocalCoordinate"` | Ordinary numerical-check values in the local source coordinate `x = SourceOffset + SourceSide u` with `u > 0`, and the sentence describing that chart. `"LocalRoot"` is always the positive displacement `u`; `"LocalApproximation"` approximates `u` for power `1` and the signed observable `(SourceSide u)^Power` otherwise, `"LocalReferenceObservable"` is that observable at the recovered root, and `"ObservablePower"` records the power. Absolute-coordinate fields reconstruct `SourceOffset + SourceSide u` with extra presentation digits. |
| `"EndpointComponent"`, `"BranchComponentVerified"` | Ordinary numerical check: the endpoint-incident monotone component `{0, u1}` of an exact numeric polynomial source, bounded by its least positive critical point or `Infinity`, inside which the unique equation root was taken; `"NotPolynomial"` or `"NotExactNumericPolynomial"` with `False` when the solver's root was kept without that verification. |
| `"AbsoluteRemainderBound"`, `"RemainderBoundConditions"` | Explicit Zeta/Lerch forward tail bound and its conditions. These go beyond a bare big-O scale but are not an inverse interval certificate. `SeriesTruncate` transports the absolute bound by adding `Abs` of the discarded part. |
| `"TruncationDiscardedPart"` | Finite part removed by a bound-transporting `SeriesTruncate`; the transported `"ForwardRemainderContract"` has `"Type" -> "TransportedThroughTruncation"` and retains the original contract. Absent after a no-op truncation. |
| `"FirstOmittedInteger"`, `"RemainderLowerBound"` | Zeta's first omitted Dirichlet term index and positive tail lower bound. |
| `"LerchParameters"`, `"FirstOmittedMoment"`, `"FiniteSourceExpansion"`, `"RemainderBoundConstant"` | Lerch parameters, first omitted moment, finite-source flag, and bound constant. The omitted-moment value can be `None`. |

Source: [NativeSpecialFunctions.wl](../Kernel/NativeSpecialFunctions.wl) and
[DirichletSpecialFunctions.wl](../Kernel/DirichletSpecialFunctions.wl).
An operation that constructs a new generic arithmetic result need not retain
the original special-function bound fields; recheck the resulting properties.

## Native results

Source: [NativeCompatibility.wl](../Kernel/NativeCompatibility.wl).
See the [native guide](UserGuide.md#native-backend-expansions) and
[result contract](../../docs/development/NATIVE_RESULT_CONTRACTS.md) for request
semantics and current coverage gaps.

| Property | Meaning |
| --- | --- |
| `"Kind"`, `"Scale"` | Both are `"Native"`. |
| `"NativeBackend"`, `"NativeResult"` | Selected `"Series"` or `"Asymptotic"` backend and its complete returned expression. |
| `"Expression"` | `Normal[NativeResult]` as computed during construction. `Normal[s]` returns this stored value; it does not invoke a new expansion. It can contain an infinite sum or unresolved native expression. |
| `"Remainder"`, `"Assumptions"` | Both are `Missing["NativeContract"]`. No independent package analytic remainder or proof context is manufactured. |
| `"Exact"` | `Missing["NotEstablished"]`, even if the returned expression happens to be exact. |
| `"RemainderContract"` | `"NativeFormalOrder"` for Series, `"NativeAsymptotic"` for Asymptotic. |
| `"NativeEvaluationStatus"` | Structural classification of the result outside `Hold`-family wrappers, in priority order: `"Aborted"` if `$Aborted` occurs; `"Failed"` if `$Failed` or a `Failure` occurs; `"Unresolved"` if a native Series/Asymptotic call with a specification remains; `"Nonfinite"` if the value, a term, factor, series coefficient or list entry is an infinity or `Indeterminate`; otherwise `"Computed"`. This is not a theorem that the requested expansion is complete or correct. |
| `"NativeRequest"`, `"OriginalArguments"` | Held delegated call and held original argument record. They preserve provenance; they are not instructions to evaluate the request again during inspection. |
| `"SourceCondition"` | For a native result whose source was one top-level `ConditionalExpression`, the condition that was added to the native assumptions; `None` otherwise. |
| `"ExpansionSpecifications"` | Recognized specifications retained in held form. |
| `"Variable"` | The unique recognized expansion variable, or `Missing["MultipleOrUnresolvedVariables"]`. In the latter case numerical application returns `Failure["NativeVariables", ...]`; substitute explicitly into `Normal[s]` or `"NativeResult"`. |
| `"AmbientAssumptions"` | Captured ambient assumption context used for delegation. It is separate from the missing package analytic `"Assumptions"` contract. |
| `"NativeKernelVersion"`, `"NativeSystemID"` | Runtime identity for the delegated computation. |

Automatic native routing additionally supplies:

| Property | Meaning |
| --- | --- |
| `"BackendSelection"`, `"OrderConvention"` | `Automatic` and `"Native"`, respectively. |
| `"BackendSelectionReason"` | Routing reason such as `"NativeSpecification"`, `"NativeOptions"`, or `"PackageRepresentation"`. |
| `"PackageFailure"` | Original analytic representation failure for a fallback, or `None` when no such failure initiated delegation. |
| `"NativeAttempts"` | Ordered list of nested attempt associations. Each stores `"Backend"`, `"EvaluationStatus"`, and a held `"Request"` or `Missing["NotDelegated"]`. These nested fields are not additional properties of the outer result. |

Explicit native selection does not add the automatic-routing fields.
The current search stops on a structurally computed result or an abort;
it can try another compatible backend after a failed or unresolved result.
The wrapper preserves a returned native outcome even when its status is
failed or unresolved. Thus matching `_GeneralizedSeries` alone does not
establish successful native computation.

Native objects do not store analytic `"Terms"`, `"Blocks"`, `"Cutoff"`,
`"SeriesData"`, or single remainder-order fields. Those queries return the
ordinary absent-key `Missing` value. Package analytic operations refuse a
native remainder contract where required; use `"NativeResult"` for native
formal operations.

## Optional provenance and refinement metadata

| Properties | Where they arise and how to read them |
| --- | --- |
| `"InverseFunctionSyntax"`, `"InverseFunctionBranch"`, `"SourceVariable"`, `"SourceDomain"` | Callable/applied-inverse admission records. They supplement the selected inverse result. |
| `"InverseFunctionExpression"`, `"InverseFunctionExpansionPoint"`, `"InverseFunctionExpansionDirection"` | Original applied inverse expression and the request's expansion approach, distinct from an inverse result's source endpoint. |
| `"InverseFunctionBranches"`, `"InverseFunctionProvenance"` | Branch selections and records accumulated during expression construction or observable evaluation. |
| `"OriginalExpression"`, `"ConditionalSourceReplay"` | Conditional-source reconstruction data where retained. |
| `"CompositionScope"` | Optional exact-source replay record for composition involving a varying parameter. It records that an old fixed-parameter remainder was not simply transported as a uniform bound. |
| `"RefinementStatistics"`, `"RefinementHistory"` | Operation-specific counts and history added by supported refinement. A replayed operation reports `"ReplayRounds"` and, when the request stayed short, `"AchievedCutoff"`; an exact derived value reports `"Strategy" -> "ExactDerivedValue"` with zero coefficient evaluations. They are not a mathematical error certificate or a uniform performance guarantee. |
| `"RefinementRequest"` | Nested additional-block request and outcome when that structured refinement path returns a new series. A numerical-tolerance refinement request instead returns a certificate association, not a `GeneralizedSeries`. |

Sources: [inverse-expression admission](../Kernel/InverseFunctionExpressions.wl),
[composition and arithmetic refinement](../Kernel/SeriesOperations.wl),
[retained inverse state](../Kernel/RefinementState.wl), and
[structured refinement](../Kernel/RefinementRequests.wl).

## Missing values and unavailable views

Absence is generally local to the requested representation or property. It
does not invalidate the whole expansion or imply numerical zero.

| Value or reason | Interpretation |
| --- | --- |
| `Missing["KeyAbsent", key]` | The property is not stored on this object. |
| `Missing["NativeContract"]` | A native object has no package analytic remainder/assumption contract. |
| `Missing["NotEstablished"]` | The native wrapper makes no exactness claim. |
| `Missing["Unknown"]`, `Missing["NotComputed"]` | Some constructors retain a valid error bound without a concrete first omitted term. |
| `Missing["NotAvailable"]` in `"SeriesData"` | The optional ordinary export does not support this endpoint, side, or observable layout. |
| `Missing["Exact"]` in `"SeriesData"` | The ordinary exporter deliberately omits a dense native series for an exact result. It is not an exactness failure. |
| `Missing["IrrationalExponents"]` | The result cannot use that rational-index native export. |
| `Missing["LogarithmicRemainder", ...]` | Export would lose the logarithmic remainder factor. |
| `Missing["NativeSeriesDataRange", ...]` | Required indices, denominator, or order span exceed the runtime's native representation range. |
| `Missing["DenseSeriesDataLimit", ...]` | The optional dense coefficient view exceeds its allocation cap. The sparse result remains available. |
| Family reasons such as `"LogarithmicScale"`, `"SourceCoordinate"`, `"ExplicitCalculus"`, or `"CompositeErrorScales"` | The family intentionally declines the ordinary native view or ordinary inverse model. Consult the family table instead of substituting a default value. |

The [native-view guide](UserGuide.md#native-series-remainder-view) explains
the export boundaries. The dispatch itself only returns stored values;
operations such as inversion, refinement, composition, or numerical checking
perform their own capability checks and can return `Failure` independently.
Preserve the object and use those operations to change it. Editing its
association directly does not recompute the coefficients, branch, or error
contract.
