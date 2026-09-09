#!/usr/bin/env python3
"""Emit review patches for an exact, user-supplied repository checkout.

NEVER modifies the input checkout. Writes changed source copies and a unified
patch to a NEW output directory. Source blobs are pinned and checked before
any output is written. Wolfram-native testing is still required.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
import json
from pathlib import Path

COMMIT = "75de8756175911cd8830704fd1a3406c1022f018"
MAIN = "AsymptoticInverse/Kernel/AsymptoticInverse.wl"
FLAT = "AsymptoticInverse/Kernel/FlatSectors.wl"
EXPECTED = {MAIN: "ea9eaf4a11130e922ac4fb3faae37fd8e8d29643", FLAT: "293450f13e3ede4b490680f9ac0dea2f39fa2183"}


def blob_hash(text: str) -> str:
    raw = text.encode("utf-8")
    return hashlib.sha1(b"blob " + str(len(raw)).encode("ascii") + b"\0" + raw).hexdigest()


def replace_exact(text: str, before: str, after: str, expected_count: int, label: str) -> str:
    count = text.count(before)
    if count != expected_count:
        raise ValueError(f"{label}: expected {expected_count} anchors, found {count}; no patch emitted")
    return text.replace(before, after)


def harden_main(text: str, dense_cap: int = 100_000) -> str:
    if isinstance(dense_cap, bool) or not isinstance(dense_cap, int) or dense_cap < 1:
        raise ValueError("dense_cap must be a positive integer")
    # The native remainder order is independent of coefficient-list length.
    # Avoid unnecessary trailing zero padding, then cap genuinely wide grids.
    before = "coeffs = Table[0, {nmax - nmin}];"
    after = f'''  (* Audit proposal: the O-order does not require trailing zero padding.
     Bound the genuinely dense retained lattice before allocating it. *)
  coeffs = Module[{{count = If[exps === {{}}, 0, 1 + Max[exps] den - nmin]}},
    If[count > {dense_cap},
      Missing["DenseSeriesDataLimit", <|"RequiredCoefficients" -> count,
        "Limit" -> {dense_cap}|>], ConstantArray[0, count]]];
  If[MissingQ[coeffs], Return[coeffs, Module]];'''
    text = replace_exact(text, before, after, 2, "forward/inverse dense view guards")
    before = '''  If[T === {},
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'''
    after = '''  If[T === {},
   (* A magnitude bound alone does not establish a real radical branch.
      Keep this invariant in the shared primitive, not only SeriesPower. *)
   If[P =!= Infinity && ! IntegerQ[rr],
    fail["UnknownLeadingTerm", "A pure remainder does not establish the real branch required by a noninteger power."]];
   If[less[0, rr], Return[{{}, If[P === Infinity, Infinity, rr P], Ceiling[rr D]}, Module],'''
    return replace_exact(text, before, after, 1, "shared real-power guard")


def broaden_flat_rates(text: str) -> str:
    before = ''' degrees = canon[#/base] & /@ rates;
 If[! And @@ (IntegerQ[#] && # > 0 & /@ degrees),
  fail["IncommensurateFlatRates", "Every phase rate must be an integer multiple of the smallest rate."]];'''
    after = ''' degrees = canon[#/base] & /@ rates;
 If[! And @@ ((IntegerQ[#] || Head[#] === Rational) && # > 0 & /@ degrees),
  fail["IncommensurateFlatRates", "Phase-rate ratios must be provably positive rational numbers."]];
 (* Audit proposal: use the rational gcd, not necessarily the smallest rate. *)
 base = canon[base (GCD @@ (Numerator /@ degrees))/(LCM @@ (Denominator /@ degrees))];
 degrees = canon[#/base] & /@ rates;
 If[! And @@ (IntegerQ[#] && # > 0 & /@ degrees),
  fail["FlatRateInvariant", "The rational rate-lattice normalization failed."]];
 If[Max[degrees] > limit,
  fail["ResourceLimit", "The normalized flat-sector degree exceeds MaxTerms."]];'''
    return replace_exact(text, before, after, 1, "rational fundamental flat rate")


def conservative_tail_proposal(text: str) -> str:
    # Narrow, optional mitigation of the identified no-visible-boundary case.
    # It does not certify arbitrary native SeriesData tails or add a theorem
    # for unrecognized functions. A full shared importer is the long-term fix.
    before = "      rho = sd2[[5]]/sd2[[6]]]]]];"
    after = '''      (* An unseen boundary block has unknown logarithmic degree.
         A half-lattice-step loss absorbs any fixed logarithmic polynomial. *)
      rho = (sd2[[5]] - 1/2)/sd2[[6]]]]]];'''
    return replace_exact(text, before, after, 1, "conservative unseen native tail")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("source", type=Path, help="Local checkout of the pinned source")
    ap.add_argument("output", type=Path, help="New directory, outside the input checkout")
    ap.add_argument("--dense-cap", type=int, default=100_000)
    ap.add_argument("--conservative-native-tails", action="store_true",
                    help="Also emit the narrower, still-native-unvalidated tail mitigation")
    args = ap.parse_args()
    source, output = args.source.resolve(), args.output.resolve()
    if output.exists() or output == source or source in output.parents:
        ap.error("output must be new and outside the input checkout")
    originals = {}
    try:
        for path, expected in EXPECTED.items():
            source_file = (source/path).resolve(strict=True)
            if source not in source_file.parents:
                raise ValueError(f"Source path escapes checkout: {path}")
            text = source_file.read_text(encoding="utf-8")  # Universal LF normalization.
            actual = blob_hash(text)
            if actual != expected:
                raise ValueError(f"Blob mismatch for {path}: expected {expected}, got {actual}")
            originals[path] = text
        modified = {MAIN: harden_main(originals[MAIN], args.dense_cap),
                    FLAT: broaden_flat_rates(originals[FLAT])}
        if args.conservative_native_tails:
            modified[MAIN] = conservative_tail_proposal(modified[MAIN])
        patch = "".join("".join(difflib.unified_diff(originals[p].splitlines(True), modified[p].splitlines(True),
                        fromfile="a/"+p, tofile="b/"+p)) for p in modified)
    except (OSError, ValueError) as exc:
        ap.error(str(exc))
    output.mkdir(parents=True)
    for path, text in modified.items():
        target = output/path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text, encoding="utf-8", newline="\n")
    (output/"proposals.patch").write_text(patch, encoding="utf-8", newline="\n")
    (output/"patch-manifest.json").write_text(json.dumps({
        "base_commit": COMMIT, "input_blobs": EXPECTED,
        "native_validation": "Required; not established by the audit",
        "dense_cap": args.dense_cap,
        "conservative_native_tails": args.conservative_native_tails,
        "output_sha256": {p: hashlib.sha256(t.encode()).hexdigest() for p,t in modified.items()}
    }, indent=2)+"\n", encoding="utf-8")
    print(f"Wrote proposals to {output}. Input checkout unchanged.")
    print("Review, apply to a separate branch, run native tests, then rebuild the standalone distribution.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
