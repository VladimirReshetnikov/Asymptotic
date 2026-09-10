"""Summarize preserved GitHub Actions receipts; does not execute any kernel."""
from pathlib import Path
import csv, json
BASE=Path(__file__).resolve().parents[1]
rows=[]; ids=set()
for path in sorted((BASE/'results/ci').glob('*.json')):
    d=json.loads(path.read_text())
    row={'Artifact':path.stem, **{k:d.get(k) for k in ('Selected','Executed','Succeeded','Failed','NotRun','RunComplete','SourcesUnchangedDuringRun')}}
    rows.append(row)
    ids.update(r['TestID'] for r in d.get('Results',[]))
summary={'Commit':'7d1bc832895cc90a9b2a978b7b7684acab908bd2','WorkflowRun':34428390335,
         'WorkflowConclusion':'cancelled','Receipts':rows,
         'CompletedRecords':sum(r['Executed'] for r in rows),'SuccessRecords':sum(r['Succeeded'] for r in rows),
         'DistinctTestIDsWithRecords':len(ids),
         'Interpretation':'Retrieved upstream CI evidence, not tests executed locally by this audit. Incomplete runs are not passing suites.'}
(BASE/'results/ci-summary.json').write_text(json.dumps(summary,indent=2)+'\n')
with (BASE/'results/ci-summary.csv').open('w',newline='') as f:
    w=csv.DictWriter(f,fieldnames=rows[0].keys());w.writeheader();w.writerows(rows)
print(json.dumps(summary,indent=2))
