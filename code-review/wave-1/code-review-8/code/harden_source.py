#!/usr/bin/env python3
"""Create a review-only hardening candidate from the pinned Asymptotic source.

Never edits the input file. Verifies the upstream standalone SHA-256 or modular
entry Git blob ID, and refuses unexpected source text. This is NOT a full fix
for ambient-assumption leakage; see the article and regression probes.
"""
from __future__ import annotations
import argparse
import difflib
import hashlib
import json
from pathlib import Path

COMMIT = "07a9781212beb2eeb9ff16aa625b50ac27974078"
STANDALONE_SHA256 = "b2aebac8176649ff53634816f17e92c8f0ccb397f7606a5ac819b6f157b6d7ed"
NATIVE_CANDIDATE_SHA256 = "a3c5a870e93890884576f149cc31438b9294035406c4d647627e70953466f24b"
ENTRY_GIT_BLOB = "ea9eaf4a11130e922ac4fb3faae37fd8e8d29643"

OLD_POWER_SERIES = '''jetPowerSeries[u_List, cf_, cut_, ell_, ass_, limit_] := Module[{ans = {}, pw = {{0, 1}}, k = 0, c},
  If[u === {}, Return[{}, Module]];
  If[cut === Infinity, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  If[! less[0, jetValuation[u]], fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
   k++;
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
   c = cf[k];
   If[c === Null, Break[]];
   If[! zeroQ[c, ass], ans = jetAdd[ans, jetScale[pw, c, ell, ass], cut, ell, ass]]];
  ans];'''
NEW_POWER_SERIES = '''jetPowerSeries[u_List, cf_, cut_, ell_, ass_, limit_] := Module[{ans = {}, pw = {{0, 1}}, k = 0, c},
  If[u === {}, Return[{}, Module]];
  If[cut === Infinity, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  If[! less[0, jetValuation[u]], fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
   k++;
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
   c = cf[k];
   If[c === Null, Break[]];
   If[k > limit, fail["ResourceLimit", "Unit-series depth exceeds MaxTerms."]];
   If[! zeroQ[c, ass], ans = jetAdd[ans, jetScale[pw, c, ell, ass], cut, ell, ass]];
   If[Length[ans] > limit, fail["ResourceLimit", "Unit-series output support exceeds MaxTerms."]]];
  ans];'''
OLD_COMPOSE = '''jetComposeBlock[u_List, a_, P_, cut_, ell_, ass_, limit_] := Module[{ans, pw = {{0, 1}}, k = 0, Q = P},
  ans = jetMerge[{{0, P}}, ell, ass];
  If[u === {}, Return[ans, Module]];
  If[cut === Infinity, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  If[! less[0, jetValuation[u]], fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
   Q = Expand[((a - k) Q + D[Q, ell])/(k + 1)];
   k++;
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
   If[polyZeroQ[Q, ell, ass], Continue[]];
   ans = jetAdd[ans, jetMul[pw, {{0, Q}}, cut, ell, ass, limit], cut, ell, ass]];
  ans];'''
NEW_COMPOSE = '''jetComposeBlock[u_List, a_, P_, cut_, ell_, ass_, limit_] := Module[{ans, pw = {{0, 1}}, k = 0, Q = P},
  ans = jetMerge[{{0, P}}, ell, ass];
  If[u === {}, Return[ans, Module]];
  If[cut === Infinity, fail["InfiniteSeries", "An infinite series is required; a finite working order is needed."]];
  If[! less[0, jetValuation[u]], fail["NonSmallJet", "Unit-series arithmetic requires positive valuation."]];
  While[True,
   Q = Expand[((a - k) Q + D[Q, ell])/(k + 1)];
   k++;
   (* The recurrence is linear: zero stays zero at every later step. *)
   If[polyZeroQ[Q, ell, ass], Break[]];
   pw = jetMul[pw, u, cut, ell, ass, limit];
   If[pw === {}, Break[]];
   If[k > limit, fail["ResourceLimit", "Unit composition depth exceeds MaxTerms."]];
   ans = jetAdd[ans, jetMul[pw, {{0, Q}}, cut, ell, ass, limit], cut, ell, ass];
   If[Length[ans] > limit, fail["ResourceLimit", "Unit composition output support exceeds MaxTerms."]]];
  ans];'''
PURE_REMAINDER_ANCHOR = '''  If[T === {},
   If[less[0, rr], Return[{{},'''
PURE_REMAINDER_FIX = '''  If[T === {},
   If[P =!= Infinity && ! IntegerQ[rr],
    fail["UnknownLeadingTerm", "A pure remainder does not prove the real branch of a noninteger power; refine or supply a proved sign contract."]];
   If[less[0, rr], Return[{{},'''
DENSE_ANCHOR = '  coeffs = Table[0, {nmax - nmin}];'

def replace_exact(text: str, old: str, new: str, expected: int) -> str:
    count = text.count(old)
    if count != expected:
        raise ValueError(f"Source anchor mismatch: expected {expected}, found {count}: {old[:90]!r}")
    return text.replace(old, new)

def patch_text(text: str, dense_limit: int = 100_000) -> tuple[str, dict]:
    if not isinstance(dense_limit, int) or dense_limit < 1:
        raise ValueError("dense_limit must be a positive integer")
    text = replace_exact(text, OLD_POWER_SERIES, NEW_POWER_SERIES, 1)
    text = replace_exact(text, OLD_COMPOSE, NEW_COMPOSE, 1)
    text = replace_exact(text, PURE_REMAINDER_ANCHOR, PURE_REMAINDER_FIX, 1)
    guard = (
        f'  If[nmax - nmin > {dense_limit}, Return[Missing["DenseRepresentationLimit",\n'
        f'    <|"RequiredCoefficients" -> nmax - nmin, "MaximumCoefficients" -> {dense_limit}|>], Module]];\n'
        + DENSE_ANCHOR
    )
    text = replace_exact(text, DENSE_ANCHOR, guard, 2)
    return text, {"dense_limit": dense_limit,
                  "changes": ["bounded eager SeriesData cache", "unit-series depth and support guards",
                              "annihilated composition early exit", "shared uncertain-power branch guard"],
                  "not_fixed": ["ambient assumption capture and isolation", "global time/memory budget",
                                "all scale-specific operations and full regression validation"]}

def git_blob_id(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode("ascii") + b"\0" + data).hexdigest()

def identify_source(data: bytes) -> str:
    normalized = data.replace(b"\r\n", b"\n")
    if hashlib.sha256(normalized).hexdigest() == STANDALONE_SHA256:
        return "standalone"
    if git_blob_id(normalized) == ENTRY_GIT_BLOB:
        return "modular-entry"
    raise ValueError("Input is not the reviewed standalone or modular entry at the pinned revision. No output written.")

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Pinned standalone or modular entry .wl file")
    parser.add_argument("--out-dir", type=Path, default=Path("audit_patch"))
    parser.add_argument("--dense-limit", type=int, default=100_000)
    args = parser.parse_args()
    raw = args.source.read_bytes()
    kind = identify_source(raw)
    original = raw.replace(b"\r\n", b"\n").decode("utf-8")
    candidate, details = patch_text(original, args.dense_limit)
    args.out_dir.mkdir(parents=True, exist_ok=True)
    outputs = [args.out_dir / "AsymptoticInverse.audit.wl", args.out_dir / "hardening.patch", args.out_dir / "patch_manifest.json"]
    if any(p.exists() for p in outputs):
        raise FileExistsError("Output already exists; choose a new --out-dir. Input was not modified.")
    outputs[0].write_text(candidate, encoding="utf-8", newline="\n")
    rel = "AsymptoticInverse.wl" if kind == "standalone" else "AsymptoticInverse/Kernel/AsymptoticInverse.wl"
    diff = "".join(difflib.unified_diff(original.splitlines(True), candidate.splitlines(True),
                                       fromfile="a/" + rel, tofile="b/" + rel))
    outputs[1].write_text(diff, encoding="utf-8", newline="\n")
    manifest = {"upstream_commit": COMMIT, "input_kind": kind,
                "input_sha256": hashlib.sha256(original.encode()).hexdigest(),
                "candidate_sha256": hashlib.sha256(candidate.encode()).hexdigest(),
                "matches_focused_native_candidate": hashlib.sha256(candidate.encode()).hexdigest() == NATIVE_CANDIDATE_SHA256,
                "validation": "Review candidate. See evidence/ for the exact validation scope; full upstream suite not run.",
                **details}
    outputs[2].write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(json.dumps({"outputs": [str(p.resolve()) for p in outputs], **manifest}, indent=2))

if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError) as error:
        raise SystemExit(str(error)) from error
