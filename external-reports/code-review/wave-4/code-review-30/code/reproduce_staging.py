#!/usr/bin/env python3
"""Test immutable staging on a synthetic local Git repository, not the package."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import subprocess
import tempfile
from stage_git_sources import stage

BUNDLE=Path(__file__).resolve().parents[1]

def command(repo: Path, *args: str) -> str:
    p=subprocess.run(['git','-C',str(repo),*args],capture_output=True,text=True)
    if p.returncode:
        raise RuntimeError(p.stderr)
    return p.stdout.strip()

def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('--output',type=Path,default=BUNDLE/'evidence/staging_experiment.json')
    args=p.parse_args()
    with tempfile.TemporaryDirectory(prefix='asymptotic-stage-test-') as temp:
        root=Path(temp); repo=root/'repo'; repo.mkdir()
        command(repo,'init','-q')
        command(repo,'config','user.name','Synthetic Audit Fixture')
        command(repo,'config','user.email','audit-fixture@example.invalid')
        kernel=repo/'src/Kernel'; kernel.mkdir(parents=True)
        (kernel/'AsymptoticAnalysis.wl').write_text('Get["Helper.wl"];\n')
        helper=kernel/'Helper.wl'; helper.write_text('value=1;')
        command(repo,'add','src'); command(repo,'commit','-qm','Synthetic source snapshot')
        commit=command(repo,'rev-parse','HEAD')
        helper.write_text('value=999;')
        output=root/'frozen'
        report=stage(repo,commit,output,'modular')
        staged=(output/'Kernel/Helper.wl').read_text()
        assert staged == 'value=1;'
        assert helper.read_text() == 'value=999;'
        assert len(report['staged_files']) == 2
        try:
            stage(repo,commit,output,'modular')
        except FileExistsError:
            pass
        else:
            raise AssertionError('Existing destination must be refused')
        result={'scope':'Synthetic local Git repository; not the Asymptotic package',
                'staged_tracked_WL_files':len(report['staged_files']),
                'working_tree_mutation_ignored':True,
                'existing_destination_refused':True,
                'staged_helper':staged,'working_tree_helper':helper.read_text()}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps(result,indent=2)); return 0

if __name__ == '__main__':
    raise SystemExit(main())
