"""Regenerate scoped evidence. Does not contact a network or run a CAS kernel."""
from __future__ import annotations
import json
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

BASE = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(BASE / "code"))
from proof_cost_model import observations
from documentation_fixture import BODIES, PREAMBLE, ENDING

def main() -> None:
    evidence = BASE / "evidence"
    evidence.mkdir(exist_ok=True)
    rows = []
    for source in (BASE / "upstream/check_documentation.py", BASE / "code/check_documentation_candidate.py"):
        for optimized in (False, True):
            for case in BODIES:
                command = [sys.executable, "-S"] + (["-O"] if optimized else []) + [str(BASE / "tests/documentation_fixture.py"), str(source), case]
                result = subprocess.run(command, text=True, capture_output=True, timeout=15)
                record = json.loads(result.stdout)
                record["process_exit_code"] = result.returncode
                if result.stderr:
                    record["stderr"] = result.stderr
                rows.append(record)
    (evidence / "documentation-fixtures.json").write_text(json.dumps({"records": rows}, indent=2) + "\n", encoding="utf-8")
    (evidence / "proof-costs.json").write_text(json.dumps({"evidence": "Restricted independent Python model", "observations": observations()}, indent=2) + "\n", encoding="utf-8")
    tex_rows = []
    engine = shutil.which("pdflatex")
    if engine:
        for case in ("valid", "comment_mask_reference", "comment_mask_citation", "comment_duplicate", "comment_input"):
            with tempfile.TemporaryDirectory(prefix="tex-comment-oracle-") as directory:
                folder = Path(directory)
                (folder / "witness.tex").write_text(PREAMBLE + BODIES[case] + ENDING, encoding="utf-8")
                outputs = []
                for _ in range(2):
                    result = subprocess.run([engine, "-interaction=nonstopmode", "-halt-on-error", "witness.tex"], cwd=folder, text=True, capture_output=True, timeout=20)
                    outputs.append({"exit_code": result.returncode, "stdout": result.stdout})
                log = (folder / "witness.log").read_text(errors="replace")
                warnings = [line for line in log.splitlines() if "Warning" in line or "undefined" in line or "multiply defined" in line]
                tex_rows.append({"case": case, "passes": 2, "exit_codes": [item["exit_code"] for item in outputs],
                                 "undefined_reference": "Reference `ghost'" in log and "undefined" in log,
                                 "undefined_citation": "Citation `ghost'" in log and "undefined" in log,
                                 "warnings": warnings})
                (evidence / f"tex-{case}.log").write_text(log.replace(str(folder), "<fixture-root>"), encoding="utf-8")
    if engine:
        (evidence / "tex-oracles.json").write_text(json.dumps({"engine_available": True, "records": tex_rows}, indent=2) + "\n", encoding="utf-8")
    else:
        print("pdflatex not found: compiler experiments skipped; shipped compiler receipts are unchanged.", file=sys.stderr)
    print(json.dumps({"documentation_observations": len(rows), "tex_oracles_executed_now": len(tex_rows), "proof_observations": 15}, indent=2))

if __name__ == "__main__":
    main()
