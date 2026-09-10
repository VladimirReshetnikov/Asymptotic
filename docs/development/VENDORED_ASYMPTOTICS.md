# Vendored asymptotics: implementation coverage matrix

**The package must successfully compute all asymptotics developed in the
articles under `vendor/proveit/docs`, including q-analogs, their inverses,
and combinatorial sequences. This goal is not yet achieved.** This matrix
connects the article corpus to the current implementation and identifies the
work needed to turn article formulas into supported public computations.

The pinned corpus contains **46 articles and 2 reference companions** from
ProveIt revision `a9e9c597c2a355702dfe775766ba2c0601653840`. The
[catalog](../../vendor/proveit/README.md),
[selection](../../vendor/proveit/selection.json), and
[manifest](../../vendor/proveit/manifest.json) identify the roots, dependent
chapters, and exact source files. The source index below assigns every selected
root to a reading family; this grouping does not exclude material in a root's
dependencies or restrict the all-asymptotics requirement. Supplied TeX, PDFs,
source notices, and provenance records remain unchanged.

## Status and evidence boundary

This is an initial **source and catalog audit**, using Asymptotic commit
`a4e1a3e3b09324f45b181843645eabbfa84abcdd`. It is not a fresh mathematical
verification of the articles or a native/Mathics acceptance run. No complete
article-to-test mapping has been established. Existing machinery is listed
as a starting point, not as proof that an entire article family is supported.

The audit inspected canonical dispatch and specialized modules and searched
the kernel and tests for named q-product, Fabius/Rvachev, sequence, and
saddle/quantile families. No dedicated article-level adapter or acceptance
mapping was identified for those families. Generic or native paths may
already compute particular supplied expressions; that possibility must be
tested and recorded rather than labeled blanket support or blanket failure.
For example, the current Catalan-number occurrences in inverse tests are
coefficient oracles for elementary inversion, not acceptance of Catalan
sequence asymptotics or a chosen sequence interpolation.

## Existing implementation building blocks

| Machinery | Source and current contract | Article coverage still to establish |
| --- | --- | --- |
| Real power-log forward and inverse calculus | [Core kernel](../../src/Kernel/AsymptoticAnalysis.wl), [coordinate transport](../../src/Kernel/CoordinateInverse.wl), and [incremental inverse](../../src/Kernel/IncrementalInverse.wl): exact weights, logarithmic coefficient blocks, local charts, and retained remainder information. | Explicit article inputs, generalized coefficient rings, uniform parameter regimes, and article-specific coefficient oracles. |
| Lambert and logarithmic scales | [Lambert inverse](../../src/Kernel/LambertInverse.wl), [logarithmic hierarchies](../../src/Kernel/LogarithmicScales.wl), and [core perturbation](../../src/Kernel/CorePerturbation.wl): supported real cores and finite hierarchies with scale-specific cutoffs. | Full branch matrices, moving saddles, log-periodic endpoint coefficients, and each article's inverse error transport. |
| Gamma and Barnes families | [Gamma forward](../../src/Kernel/GammaForward.wl), [Barnes forward](../../src/Kernel/BarnesForward.wl), [Gamma inverse](../../src/Kernel/GammaInverse.wl), and [Barnes inverse](../../src/Kernel/BarnesInverse.wl). Factorial, binomial, beta, and ordinary Pochhammer expressions have explicit Gamma reductions. | Sequence-specific interpolation and parity data, balanced quotient inverse families, subdominant sectors, and q-special functions. Ordinary `Pochhammer` reduction is not q-Pochhammer support. |
| Oscillatory and flat sectors | [Fourier coefficients](../../src/Kernel/FourierCoefficients.wl) use finite Fourier-polynomial coefficients; [flat sectors](../../src/Kernel/FlatSectors.wl) use finite commensurate exponential perturbations of an exact monomial core. | Infinite theta/pole lattices with controlled truncation, arithmetic residue sectors, general transseries support, and uniform sector remainder bounds. |
| Selected special functions | [Special-function adapters](../../src/Kernel/SpecialFunctionAdapters.wl), [parameterized functions](../../src/Kernel/ParameterizedSpecialFunctions.wl), and [Dirichlet scales](../../src/Kernel/DirichletSpecialFunctions.wl). | Automatic derivation of article-specific saddle, singularity-transfer, Mellin, q-product, or probability expansions. A special-function name in a coefficient does not implement the surrounding algorithm. |
| Arithmetic and quantitative checks | [Series operations](../../src/Kernel/SeriesOperations.wl), [composite bounds](../../src/Kernel/SeriesEnvelopeArithmetic.wl), and [inverse certificates](../../src/Kernel/InverseCertificates.wl). | Each article's complete coefficient, domain, branch, asymptotic-tail, or numerical enclosure contract. Formal residual cancellation alone does not certify an analytic inverse. |

The [kernel map](../../src/Kernel/README.md) and
[focused test guide](../../src/Tests/README.md) identify related regression
files. Their recorded runs retain their own source snapshots and scope.

## q-analogs and inverse q-functions

The [q reading list](../../vendor/proveit/README.md#q-analogs-and-inverse-q-functions)
provides pinned chapter-level source locations. The distinctions below are
part of the implementation contract; they are not alternative names for one
generic q-to-one expansion.

| Required family and regime | Source route | Existing starting point and outstanding work |
| --- | --- | --- |
| Finite and infinite q-Pochhammer near q=0, finite inverse anchors, and reciprocal-base limits | [q-series monograph][a8] | Power-log and Puiseux machinery may serve expanded finite products. Add explicit argument-versus-base inversion, rank/parameter admission, infinite-product tails, and public regression cases. |
| Fixed-argument q→1 infinite products | [q-series monograph][a8] | Implement the dilogarithmic leading scale and Bernoulli/polylogarithm coefficient generator with its stated uniform remainder and sector restrictions. Generic Gamma support does not provide this q-product model. |
| Coalescing argument a=q^x and fixed-target q→1 inversion | [q-series monograph][a8] | Add Gamma-normalized coalescing models and the separate fixed-target inverse recurrence. Do not substitute a→1 into a theorem proved only uniformly away from that boundary. |
| q-Gamma, q-digamma, q-beta, and q-exponential inverses | [q-series monograph][a8] | Ordered exponent collection and inverse calculus are useful. Add the q→0 rational/irrational exponent regimes, q→1 models, exceptional parameter values, and correct argument/base inverse selection. |
| Gaussian binomial and multinomial parameter inverses | [Gaussian calculus][a6], [q-series monograph][a8] | Implement q=0 and q=1 jets, palindromic ramification, cyclotomic anchors, and reciprocal/large-target branches. Exact finite-polynomial reductions need their own verified public examples. |
| Fixed-base large-index and q=exp(-tau/n) Gaussian regimes | [Gaussian calculus][a6] | Add separate fixed-lower-index, both-large, and double-scaling algorithms with uniform parameter sets. A finite-rank formula does not establish these limits. |
| Fixed-q large-argument products and theta/log-periodic inverses | [q-series monograph][a8] | Finite Fourier coefficients are a possible component. Supply the theta/periodic phase, large-target inverse correction, and controlled treatment of the infinite mode content. |
| Root-of-unity radial and cyclotomic blow-up limits | [q-series monograph][a8], [geometric q-Fabius][a7] | Add complex radial charts, branch normalization, coefficient generators, and formal/analytic result distinctions. The catalog's finite radial formula must not be relabeled all-order; the separate blow-up expansion has different hypotheses. |
| Modular exponentially small corrections | [q-series monograph][a8], [geometric q-Fabius][a7] | Implement dual-nome identities and retained exponentially small sectors. Existing finite commensurate flat sectors do not establish modular or resurgence coverage. |
| Geometric q-Fabius endpoint and inverse limits | [geometric q-Fabius][a7], [frontier directions][a11] | Lambert and Fourier machinery may assist. Supply the actual q-law source, endpoint saddle coefficients, periodic phase, and inverse transport; retain the articles' proved versus proposed general-q distinctions. |
| Standardized q→1 Gaussian, Edgeworth, and central quantile expansions | [geometric q-Fabius][a7], [geometric convolutions][a10] | Implement finite Bernoulli-Bell-Hermite coefficients, CDF integration, and Cornish-Fisher inversion with the stated central/uniform bounds. Endpoint, central quantile, and moderate-deviation regimes remain separate. |

## Combinatorial sequences and their inverses

The [sequence reading list](../../vendor/proveit/README.md#combinatorial-sequences-and-interpolated-inverses)
locates the relevant chapters and proof-status qualifications. Every inverse
case must name the continuous interpolation or the discrete threshold problem.
Integer samples alone do not determine an interpolation's correction terms.

| Required family | Source route | Existing starting point and outstanding work |
| --- | --- | --- |
| Fibonacci interpolation and inverse | [Transseries and inversion][a34] | Exponential and Fourier building blocks are relevant. Implement the specified real interpolation, branches, convergent inverse coefficients, and truncation bound. |
| Bell and Fubini forward asymptotics | [Transseries and inversion][a34], [coefficient calculus][a5] | Add the Bell saddle generator and Fubini pole-lattice expansion with their different error contracts. No dedicated Bell-interpolant inverse is supplied by the catalog. The withdrawn refined Moser-Wyman claim must not be used as a theorem. |
| Rooted trees | [Transseries and inversion][a34] | Supply the implicit Otter singularity, Puiseux-to-coefficient transfer, Lambert inverse carrier, and exponentially small corrections. Generic Puiseux inversion alone is insufficient. |
| Integer partitions | [Transseries and inversion][a34] | Implement Rademacher arithmetic sectors, their tail control, and the chosen continuous inverse separately from certified discrete threshold recovery. |
| Double/multifactorial, swing-factorial, and subfactorial families | [Transseries and inversion][a34] | Gamma machinery supplies some factors. Add parity/interpolation choices and algebraic/exponential inverse corrections; swing factorial cannot be assigned an unqualified eventually monotone inverse. |
| Catalan, Fuss-Catalan, central multinomial, and balanced Gamma quotients | [combinatorial inverses][a33], [coefficient calculus][a5] | Existing Gamma-product reductions are a concrete starting point. Establish public sequence forward requests, quotient inverse algorithms, retained error bounds, and all-order coefficient checks. |
| Fixed Stirling and Eulerian columns, surjections | [combinatorial inverses][a33], [coefficient calculus][a5] | Add the distinct finite-exponential and nested-logarithmic models, fixed-column conditions, interpolation choices, and inverse corrections. Bernoulli/Stirling coefficients in another engine do not provide sequence support. |
| Motzkin, trinomial, Delannoy, Schroder, involution, and alternating-permutation families | [combinatorial inverses][a33] | Add moment-endpoint extraction, two-saddle/stretched-exponential models, and parity-resolved Gamma sectors. One-saddle or bounded-drift inverse machinery cannot be assumed to cover every family. |
| Connected graphs, necklaces, Lyndon words, irreducible polynomials | [combinatorial inverses][a33] | Implement quadratic growth phases, successive exponential layers, divisor-sum sectors, and explicit finite-cutoff interpolants. Keep threshold recovery separate. |
| q-factorials, flags, classical-group orders, q-Catalan, and finite-field enumeration | [combinatorial inverses][a33], [q-series monograph][a8] | Add the rank/base parameter regimes, functional inverses, and convergent fixed-rank Puiseux corrections. The reciprocal of a q-factorial is not its functional inverse. |
| Galois theta inverses and the q→1 crossover | [combinatorial inverses][a33], [Gaussian calculus][a6] | Add residue sheets, theta coefficients, and the separate uniform dilogarithmic crossover model. An analytic-base limit q→1 is not a limit of finite-field orders, and asymptotic crossover formulas do not establish convergence. |

## Remaining article families

These rows cover the wider Fabius/Rvachev, transform, spectral, geometric,
and exact-extraction corpus. The source index below includes every selected
root, including compilations that overlap several rows.

| Family | Required algorithmic work and evidence |
| --- | --- |
| Fabius/Rvachev endpoint and inverse foundations | Supply the original function/transform model, lower-Lambert saddles, periodic correction jets, all-order endpoint transfer, Wright-omega resummation, and inverse-domain/error contracts. Existing Lambert routines are components, not a Fabius adapter. |
| Integration, weighted primitives, fractional endpoints, comb interpolation | Add transform-specific saddle transfer, complex-power Euler-Maclaurin corrections, filtered remainders, and inverse weighted primitives. Each uniform parameter range and approach must remain explicit. |
| Exact dyadic extraction, finite splines, and derivative spines | Implement finite-jet deconvolution, terminating geometric corrections, coefficient recovery, Richardson/Romberg extraction, polynomial/quasipolynomial asymptotics, and finite-spine derivatives. Preserve exact zero remainders when proved; exact recovery is a different contract from an asymptotic truncation. |
| Distribution deformations and geometry | Add Jacobi-digit, matrix-dilated, zonoid, zero-bias, Stein, cumulant, and chaos-specific models, including directional caps, Gaussianization, norm asymptotics, and phase-modulated corrections. Conditional cumulant theorems and conjectural full endpoint expansions retain those statuses. |
| Information expansions | Supply small-noise deconvolution and formal Hermite/Edgeworth information coefficients. The catalog identifies uniform entropic Edgeworth behavior as conjectural; a formal coefficient generator cannot certify that analytic claim. |
| Spectral, arithmetic, and representation families | Add Mellin-pole/log-periodic heat and determinant expansions, Jacobi-dual corrections, spectral divisors, Poisson/mod-Poisson/Gaussian transitions, large-p norms, coefficient saddles, discriminants, and arithmetic inverse phases. Higher-rank and conjectural extensions need their own mathematical and implementation work. |
| Fourier decay and Thue-Morse families | Add dyadic-shell and incomplete-shell phases, endpoint-Laplace/finite-block expansions, Bernoulli-zeta tails, weak differential expansions, lattice/spline corrections, and Mellin renormalization. A finite Fourier-polynomial coefficient algebra does not establish these global Fourier or distributional results. |

## Turning a row into verified support

Start with a precise article statement and a public input that exercises its
algorithm. Record the source definition, interpolation or branch, parameters,
limit, requested order, coefficient generator, and remainder contract. Check
the original function or equation with independent coefficients or a justified
error estimate; numerical samples supplement that evidence. Record the exact
Wolfram and Mathics scopes separately, including failures and unresolved cases.

For an all-orders result, exercise increasing finite orders and explain why
the implementation's recurrence and truncation rules implement the stated
family. A finite test selection alone cannot prove universal coverage.
Conditional/formal/conjectural or withdrawn source statements retain their
mathematical obligations; the goal requires correct computation, not merely
printing a source formula. Use the [three-goal register](COVERAGE_TARGETS.md)
and [validation workflow](../../validation/README.md) when recording progress.

## Complete source index

The following 13 reading families contain all 48 selected roots exactly once.
They are navigation groups, not assertions that the mathematical topics are
disjoint. Follow the [catalog](../../vendor/proveit/README.md#complete-article-catalog)
for each paired PDF, provenance, and detailed selection rationale.

### Reference companions

- [Mathematical Glossary for Analysis/FabiusFunction -- Complete Updated Edition][a0]
- [Mathematical Notation Catalogue for Analysis/FabiusFunction][a1]

### General transseries and Lambert inversion

- [The Lambert W Function: A Real-Variable Guide with Proofs][a18]
- [Transseries: The polynomial-logarithmic calculus, series reversal at infinity, and the inversion of rapidly growing functions][a34]

### Combinatorial coefficient and sequence calculus

- [Combinatorial Coefficient Calculus: A Unified Formulae Monograph][a5]
- [Combinatorial Transseries and Their Inverses][a33]

### q-products and Gaussian coefficients

- [Gaussian Coefficient Calculus: q-Binomial Kernels, Newton Bases, Bell Polynomials, Parameter Jets, Inversion, and Asymptotics][a6]
- [q-Series and Inverse q-Analogs][a8]

### Geometric q-Fabius limits

- [Geometric q-Fabius-Rvachev Frontiers][a7]
- [Geometric Uniform Convolutions and New Frontiers around the Fabius--Rvachev System][a10]
- [Frontier Directions for Fabius--Rvachev Analysis][a11]

### Fabius and Rvachev endpoint foundations

- [The Fabius Function and Rvachev's Up-Function][a2]
- [The Fabius Function Ecosystem in Lean: Complete Walkthrough of the ProveIt Development][a3]
- [The Fabius Function in Lean: A Guided Walkthrough of the ProveIt Formalization][a4]
- [Collected Frontier Reports for the Fabius--Rvachev System][a9]
- [Inverse Fabius Theory: Analyticity, asymptotics, computability, and dyadic sampling][a13]
- [Semi-Formalized Research Frontiers for the Fabius Function][a47]

### Integration and interpolation

- [Integration and Transform Frontiers for the Fabius--Rvachev System][a12]
- [Comb Interpolation and Sampling Frontiers][a14]

### Exact dyadic extraction and derivative spines

- [Exact Dyadic Extraction of Rvachev Up-Function from Finite Sinc-Product Splines][a15]
- [Recurrence-Free Dyadic Values of the Fabius and Rvachev Functions][a16]
- [Exact Rvachev Up-Function Polynomial Synthesis][a27]
- [Nowhere Analyticity of Every Positive Compositional Iterate of the Fabius Function][a30]

### Distribution deformations and geometry

- [Fabius--Rvachev New Frontiers][a19]
- [Noncommutative Cumulant Frontiers for the Fabius--Rvachev Law][a20]
- [Shape, Divisibility, and Stein Geometry of the Fabius--Rvachev Law][a21]
- [Dyadic Stein--Koopman and q-Oscillator Calculus for the Fabius--Rvachev Law][a22]
- [Zero-Bias Towers and Spectral Peeling in the Fabius--Rvachev System][a23]
- [Jacobi-Digit Deformations of the Fabius--Rvachev Law][a24]
- [Matrix-Dilated Fabius--Rvachev Laws][a25]
- [Common-Digit Fabius Zonoids][a28]
- [Dyadic Sensitivity and Polynomial-Chaos Frontiers for the Fabius--Rvachev Law][a29]

### Information expansions

- [Exact Information Geometry and New Frontiers for the Fabius Function, Rvachev Up-Function, Thue-Morse Sinc Products, and Geometric q-Convolutions][a17]

### Spectral and arithmetic asymptotics

- [Representation Frontiers for the Fabius--Rvachev System][a26]
- [Automatic Scale Factorizations of the Rvachev Law][a35]
- [Digital Spectral Geometry and Log-Periodic Saddles][a36]
- [Dyadic Radon Profiles in the Fabius--Rvachev Web][a37]
- [Dyadic Spectral Divisors and Gamma Duality][a38]
- [Automatic Spectra, Exact Dyadic Cubature, and Probabilistic Duals in the Pascal--Rvachev Hierarchy][a39]
- [Critical Ultradifferentiable Geometry of the Fabius--Rvachev System][a40]
- [Reciprocal-Integer Convolution Divisors of the Rvachev Law][a41]
- [Total Positivity and Cartwright Geometry in the Fabius--Rvachev Dyadic Sinc Product][a42]
- [Half-Integer Spectral Arithmetic for the Fabius--Rvachev System][a43]
- [Holonomic Rank, Exact Overlaps, and Non-P-Recursiveness in the Fabius--Rvachev System][a44]

### Fourier decay

- [Fourier Decay of Rvachev's Up-Function: A Guided and Rigorous Account][a31]
- [Fourier Decay of Rvachev's Up-Function: A Consolidated Account][a32]

### Thue-Morse expansions

- [The Thue--Morse Sequence: Formula Atlas and Fabius--Rvachev Frontier Results][a45]
- [Thue-Morse Frontier Deductions: Boundary Corrections, Dyadic Completion and Mellin Renormalization, Rational Resonances, Spline and Lattice Corrections, and Nonlinear Prouhet Geometry][a46]

[a0]: ../../vendor/proveit/docs/FabiusFunction_Mathematical_Glossary/FabiusFunction_Mathematical_Glossary.tex
[a1]: ../../vendor/proveit/docs/FabiusFunction_Mathematical_Notation_Catalogue/FabiusFunction_Mathematical_Notation_Catalogue.tex
[a2]: ../../vendor/proveit/docs/Fabius_Function_and_Rvachev_Up/Fabius_Function_and_Rvachev_Up.tex
[a3]: ../../vendor/proveit/docs/fabius_lean_walkthrough/fabius_lean_walkthrough%20%28part%20II%29.tex
[a4]: ../../vendor/proveit/docs/fabius_lean_walkthrough/fabius_lean_walkthrough.tex
[a5]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/combinatorial-coefficient-calculus/Combinatorial_Coefficient_Calculus/Combinatorial_Coefficient_Calculus.tex
[a6]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/combinatorial-coefficient-calculus/Gaussian_Coefficient_Calculus/Gaussian_Coefficient_Calculus.tex
[a7]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/exponents-and-q-series/geometric_q_fabius_frontiers/geometric_q_fabius_frontiers.tex
[a8]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/exponents-and-q-series/q_pochhammer_q_binomial_monograph/q_pochhammer_q_binomial_monograph.tex
[a9]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/frontier-compilations/Frontier_Compilations/Frontier_Compilations.tex
[a10]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/frontier-compilations/Geometric_Uniform_Convolutions_and_New_Frontiers/fabius-frontier-report-H.tex
[a11]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/frontier-compilations/Geometric_Uniform_Frontier_Directions/fabius_frontier_report.tex
[a12]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/integration-and-transforms/Integration_and_Transform_Frontiers/Integration_and_Transform_Frontiers.tex
[a13]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/inverse-and-sampling/Inverse_Fabius_Analyticity_Asymptotics_and_Computability/inverse_fabius_theory.tex
[a14]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/inverse-and-sampling/comb-interpolation/comb_interpolation_synthesis/comb_interpolation_synthesis.tex
[a15]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/inverse-and-sampling/dyadic-up-extraction/Dyadic_Up_Extraction/Dyadic_Up_Extraction.tex
[a16]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/inverse-and-sampling/dyadic-up-extraction/Recurrence_Free_Dyadic_Values/Recurrence_Free_Dyadic_Values.tex
[a17]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/inverse-and-sampling/fabius_information_frontier/fabius_information_frontier.tex
[a18]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/lambert-w/Lambert_W_Guide/Lambert_W_Guide.tex
[a19]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Fabius_Rvachev_New_Frontiers-2/fabius_rvachev_new_frontiers.tex
[a20]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Fabius_Rvachev_Noncommutative_Frontiers/Fabius_Rvachev_Noncommutative_Frontiers.tex
[a21]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Fabius_Rvachev_Shape_Divisibility_Stein_Geometry/Fabius_Rvachev_Shape_Divisibility_Stein_Geometry.tex
[a22]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Fabius_Stein_Koopman_Frontier_Report/dyadic_stein_koopman_frontier.tex
[a23]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Fabius_Zero_Bias_Frontier_Report/Zero_Bias_Towers_and_Spectral_Peeling.tex
[a24]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Jacobi_Digit_Fabius_Rvachev_Frontier_Report/jacobi_digit_frontier_report.tex
[a25]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Matrix_Dilated_Fabius_Rvachev_Frontier_Report/matrix_dilated_fabius_rvachev.tex
[a26]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Representation_Frontiers/Representation_Frontiers.tex
[a27]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/Up_Polynomial_Synthesis/Up_Polynomial_Synthesis.tex
[a28]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/common_digit_fabius_zonoids_frontier_report/common_digit_fabius_zonoids.tex
[a29]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/fabius_dyadic_chaos_frontier/fabius_dyadic_chaos_frontiers.tex
[a30]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/representations/fabius_iterates_nowhere_analytic/fabius_iterates_nowhere_analytic.tex
[a31]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/rvachev_up_fourier_decay/Rvachev_Up_Fourier_Decay-2/Rvachev_Up_Fourier_Decay-2.tex
[a32]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/rvachev_up_fourier_decay/Rvachev_Up_Fourier_Decay/Rvachev_Up_Fourier_Decay.tex
[a33]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/series-and-transseries/Combinatorial_Transseries_Inverses/Combinatorial_Transseries_Inverses.tex
[a34]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/series-and-transseries/Transseries_And_Inversion/transseries_and_inversion.tex
[a35]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Automatic_Scale_Factorizations_Rvachev_2026-08-30/automatic_scale_factorizations.tex
[a36]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Digital_Spectral_Geometry_and_Log_Periodic_Saddles/Fabius_Rvachev_Frontier_Report.tex
[a37]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Dyadic_Radon_Profiles_Fabius_Rvachev_2026-08-30/dyadic_radon_profiles_fabius_rvachev.tex
[a38]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Dyadic_Spectral_Divisors_and_Gamma_Duality/fabius_frontier_report.tex
[a39]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Fabius_Pascal_Frontiers_Report/Fabius_Pascal_Frontiers.tex
[a40]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Fabius_Rvachev_Carleman_Frontiers_2026-08-30/fabius_carleman_frontiers.tex
[a41]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Fabius_Rvachev_Reciprocal_Integer_Convolution_Divisors/Fabius_Rvachev_Reciprocal_Integer_Convolution_Divisors.tex
[a42]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Fabius_Total_Positivity_Frontier_Report/Fabius_Total_Positivity_Frontier_Report.tex
[a43]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/Spectra_and_Arithmetic_Frontiers/Spectra_and_Arithmetic_Frontiers.tex
[a44]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/spectra-and-arithmetic/fabius_holonomic_frontiers_report/fabius_holonomic_frontiers.tex
[a45]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/thue-morse/Thue_Morse_Atlas_and_Frontiers/Thue_Morse_Atlas_and_Frontiers.tex
[a46]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/drafts/thue-morse/Thue_Morse_Frontier_Deductions/Thue_Morse_Frontier_Deductions.tex
[a47]: ../../vendor/proveit/docs/semi-formalized-research-frontiers/semi-formalized-research-frontiers.tex
