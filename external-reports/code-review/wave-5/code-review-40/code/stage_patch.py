"""Stage a conservative two-file patch into a NEW external directory.

The source checkout must be clean for the edited files and at the pinned
revision. Only changed modular files are written: this is NOT a complete
package. Regenerate the standalone and run native tests in a separate checkout.
No checksum files are generated. Exact-anchor fixture tests are not native tests.
"""
from __future__ import annotations
import argparse
from pathlib import Path
import shutil
import subprocess
import tempfile

REVISION = "651f2029d0b2cd4da9e4dfdf1f4275a124d23b99"
CORE = "src/Kernel/AsymptoticAnalysis.wl"
OPERATIONS = "src/Kernel/SeriesOperations.wl"
ABS_OLD = '''fwdAbs[j : {T_, P_, D_}, ell_, ass_] := Module[{q, c, degree},
  If[T === {}, Return[j, Module]];
  q = T[[1, 2]]; degree = polyDegree[q, ell];'''
ABS_NEW = '''fwdAbs[j : {T_, P_, D_}, ell_, ass_] := Module[{q, c, degree},
  If[T === {}, Return[j, Module]];
  (* A leading sign does not make complex subleading terms real.
     Refuse this shortcut; a norm-square adapter can support them later. *)
  If[! AllTrue[T, realPolynomialQ[#[[2]], ell, ass] &],
    fail["UnprovedAbsoluteValueArgument",
      "The signed real Abs shortcut requires real retained coefficient polynomials.",
      <|"Reason" -> "RetainedCoefficientsNotProvedReal"|>]];
  q = T[[1, 2]]; degree = polyDegree[q, ell];'''
OBS_OLD = '''  j = seriesJetApply[body, x, d["Jet"], d, h, limit];
  result = seriesMake[Join[d, <|"Jet" -> j|>], {"Observable", {s}, e, x}, h];'''
OBS_NEW = '''  j = seriesJetApply[body, x, d["Jet"], d, h, limit];
  (* A modulus magnitude bound does not establish classical differentiability.
     Conservative scope: all variable-dependent Abs nodes with a finite tail.
     Recover stronger contracts only with explicit per-node smoothness proof. *)
  If[j[[2]] =!= Infinity && ! FreeQ[body, node_Abs /; ! FreeQ[node, x]],
    d = Join[d, <|"RemainderDerivativeOrder" -> 0|>]];
  result = seriesMake[Join[d, <|"Jet" -> j|>], {"Observable", {s}, e, x}, h];'''


def transform_sources(sources: dict[str, str]) -> dict[str, str]:
    edits = {CORE: (ABS_OLD, ABS_NEW), OPERATIONS: (OBS_OLD, OBS_NEW)}
    output: dict[str, str] = {}
    for path, (old, new) in edits.items():
        if path not in sources:
            raise ValueError(f"Missing source: {path}")
        count = sources[path].count(old)
        if count != 1:
            raise ValueError(f"{path}: expected one exact anchor, found {count}")
        output[path] = sources[path].replace(old, new, 1)
    return output


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("checkout", type=Path)
    parser.add_argument("destination", type=Path)
    args = parser.parse_args()
    source = args.checkout.resolve(strict=True)
    destination = args.destination.resolve()
    if destination.exists() or destination.is_relative_to(source):
        parser.error("destination must be new and outside the input checkout")
    def git(*words: str) -> str:
        return subprocess.check_output(["git", "-C", str(source), *words], text=True).strip()
    try:
        if git("rev-parse", "HEAD") != REVISION:
            raise ValueError("checkout is not at the pinned revision")
        if git("status", "--porcelain", "--", CORE, OPERATIONS):
            raise ValueError("edited input files must have no local changes")
        raw = {p: (source / p).read_bytes() for p in (CORE, OPERATIONS)}
        text = {p: b.decode("utf-8") for p, b in raw.items()}
        patched = transform_sources(text)
        destination.parent.mkdir(parents=True, exist_ok=True)
        temporary = Path(tempfile.mkdtemp(prefix="abs-delta-", dir=destination.parent))
        try:
            for p, content in patched.items():
                target = temporary / p
                target.parent.mkdir(parents=True, exist_ok=True)
                target.write_text(content, encoding="utf-8", newline="")
            if git("rev-parse", "HEAD") != REVISION or any(
                    (source / p).read_bytes() != b for p, b in raw.items()):
                raise ValueError("source changed while staging")
            if destination.exists():
                raise ValueError("destination appeared while staging")
            temporary.rename(destination)
        finally:
            if temporary.exists():
                shutil.rmtree(temporary)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f"Patch not staged: {error}\n")
    print(f"Staged two changed modular files in {destination}; native validation NOT performed.")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
