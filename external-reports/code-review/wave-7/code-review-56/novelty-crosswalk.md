# Exclusion and novelty crosswalk

Snapshot: `efa1aeec4845a9c35e140963a0333d0c9ec33b05`.
The comparison used the umbrella review index, all six wave indexes, the
first 380 lines of the development status register, and the closest original
report READMEs listed below. It was not a fresh cover-to-cover rereading of
all archived articles, retired reports, PDFs, and code artifacts. The claim
is a mechanism-specific incremental contribution relative to this inspected
baseline, not a proof that no sentence anywhere in the archive anticipates it.

| This contribution | Closest prior record | What is excluded | Distinct contribution |
|---|---|---|---|
| N01 | wave-2/code-review-11, N04 | Inconsistent real-coefficient admission | Every retained coefficient is real; a discarded complex source term is amplified and then causes a false sine/cosine envelope. |
| N01 | wave-5/code-review-37, F01 | `fwdAbs` sign shortcut with retained complex terms | The failing operation is composite Sin/Cos on a pure remainder, not modulus simplification of retained terms. |
| N01 | wave-5/code-review-42, N01 | Loss of classical differentiability through real Abs | This is an incorrect magnitude bound, not a derivative regularity claim; complex modulus itself remains safe. |
| N02 | wave-6/code-review-47, N01 | Duplicated work in Mathics real/sign proof recursion | The persisted input conditions themselves triple in shared arithmetic, reproduced on Wolfram 15. The proposed change is idempotent condition construction, not prover memoization. |
| E01 | wave-6/code-review-49, E1 | Positive-parameter Lerch signed enclosure | The proposed Euler-difference provider covers negative arguments `z=-q`, including `q=1`, with positive transformed summands and nested geometric-tail intervals. |

No old report's positive-Lerch implementation, Abs repair, derivative
contract, native-backend backlog, or generic test infrastructure proposal is
reissued as a new finding. Classical Euler acceleration is expressly credited
as classical; the contribution is the tailored proof, strict reference code,
and integration specification for the current negative-Lerch use case.
