"""Run fresh-kernel characterization probes against a frozen Git commit.

POSIX supervisor; requires an existing local Git clone and an installed runtime.
Probe completion is NOT an assertion that a mathematical expectation passed.
No repository working-tree file is modified. Network access is unnecessary
when the requested commit already exists locally.
"""
from __future__ import annotations
import argparse
from dataclasses import asdict
import json
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import tempfile
from bounded_process import positive_finite_timeout, run_bounded

PIN = '7d1bc832895cc90a9b2a978b7b7684acab908bd2'
CASES = ('root-precision','public-numerical-precision','core-negative-lambert',
         'limit-default','first-position-options','first-position-predicate-count',
         'affine-small-radius','terminating-pfq')


def freeze_package(repository: Path, destination: Path, commit: str, entry: str) -> Path:
    if not re.fullmatch(r'[0-9a-fA-F]{40}', commit):
        raise ValueError('Use a full 40-digit commit object ID')
    if entry not in ('modular','standalone'):
        raise ValueError('entry must be modular or standalone')
    prefix = 'src/Kernel' if entry == 'modular' else 'AsymptoticAnalysis.wl'
    listing = subprocess.check_output(
        ['git','-C',str(repository),'ls-tree','-rz',commit,'--',prefix])
    count = 0
    for record in listing.split(b'\0'):
        if not record:
            continue
        metadata, raw_path = record.split(b'\t',1)
        mode, kind, oid = metadata.decode('ascii').split()
        name = raw_path.decode('utf-8')
        if not name.endswith('.wl'):
            continue
        path = PurePosixPath(name)
        if mode not in ('100644','100755') or kind != 'blob' or path.is_absolute() or '..' in path.parts:
            raise ValueError(f'Unsupported snapshot entry: {name}')
        data = subprocess.check_output(['git','-C',str(repository),'cat-file','blob',oid])
        out = destination.joinpath(*path.parts)
        out.parent.mkdir(parents=True,exist_ok=True)
        out.write_bytes(data)
        out.chmod(0o444)
        count += 1
    source = destination / ('src/Kernel/AsymptoticAnalysis.wl' if entry == 'modular'
                            else 'AsymptoticAnalysis.wl')
    if not count or not source.is_file():
        raise ValueError('The selected commit does not contain the requested package entry')
    return source


def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument('repository',type=Path)
    p.add_argument('--commit',default=PIN)
    p.add_argument('--entry',choices=['modular','standalone'],default='modular')
    runtime = p.add_mutually_exclusive_group(required=True)
    runtime.add_argument('--mathics-python',help='Python executable containing Mathics3')
    runtime.add_argument('--wolfram',help='Wolfram kernel executable, not wolframscript')
    p.add_argument('--case',action='append',choices=CASES)
    p.add_argument('--timeout',type=positive_finite_timeout,default=180.0)
    p.add_argument('--output-limit',type=int,default=1048576)
    p.add_argument('--output',type=Path,default=Path('audit-probes.json'))
    args=p.parse_args()
    results=[]
    with tempfile.TemporaryDirectory(prefix='asymptotic-audit-') as temporary:
        work=Path(temporary)
        source=freeze_package(args.repository.resolve(),work/'snapshot',args.commit,args.entry)
        script=work/'PortabilityProbes.wl'
        script.write_bytes(Path(__file__).with_name('PortabilityProbes.wl').read_bytes())
        script.chmod(0o444)
        if args.mathics_python:
            executable = str(Path(args.mathics_python).resolve()) if Path(args.mathics_python).is_file() else args.mathics_python
            command=[executable,'-m','mathics','--quiet','--no-readline','--file',str(script)]
        else:
            executable = str(Path(args.wolfram).resolve()) if Path(args.wolfram).is_file() else args.wolfram
            command=[executable,'-noinit','-script',str(script)]
        for case in args.case or CASES:
            env=dict(os.environ,ASYMPTOTIC_AUDIT_SOURCE=str(source),ASYMPTOTIC_AUDIT_CASE=case,
                     PYTHONIOENCODING='utf-8',PYTHONUNBUFFERED='1')
            for key in list(env):
                if key.upper() in ('WOLFRAMINIT','MATHKERNELINIT'):
                    del env[key]
            result=run_bounded(command,timeout=args.timeout,max_output_bytes=args.output_limit,
                               cwd=str(work),env=env)
            row=asdict(result)
            row['Case']=case
            row['CompletedProbe']=(result.outcome=='Completed' and result.returncode==0
                and result.output.splitlines().count('AUDIT_COMPLETED\t'+case)==1)
            results.append(row)
    report={'Commit':args.commit,'Entry':args.entry,'FreshKernelPerProbe':True,
            'Inputs':'Read from Git blob objects, not the mutable working tree',
            'MathematicalAssertions':'Characterizations only; interpret values using the article',
            'Results':results}
    args.output.parent.mkdir(parents=True,exist_ok=True)
    args.output.write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    return 0 if all(row['CompletedProbe'] for row in results) else 1


if __name__=='__main__':
    raise SystemExit(main())
