#!/usr/bin/env python3
"""Stage the known Asymptotic WL source layout from immutable Git objects.

This is not a general dependency resolver. Modular mode selects tracked .wl
files under src/Kernel; standalone mode selects AsymptoticAnalysis.wl. No
working-tree source bytes are read, so edits/restores cannot mix test inputs.
The destination must not already exist. No checksum files are generated.
"""
from __future__ import annotations
import argparse
import json
from pathlib import Path, PurePosixPath
import re
import subprocess
import tempfile


def git(repo: Path, *args: str) -> bytes:
    p = subprocess.run(['git','-C',str(repo),*args],capture_output=True,check=False)
    if p.returncode:
        raise RuntimeError(p.stderr.decode('utf-8','replace').strip())
    return p.stdout


def stage(repo: Path, revision: str, output: Path, mode: str) -> dict:
    if not re.fullmatch(r'[0-9a-fA-F]{40}', revision):
        raise ValueError('Supply a full 40-character immutable commit ID')
    commit = git(repo,'rev-parse','--verify',revision+'^{commit}').decode().strip()
    if mode not in {'modular','standalone'}:
        raise ValueError('Mode must be modular or standalone')
    prefix = 'src/Kernel' if mode == 'modular' else 'AsymptoticAnalysis.wl'
    names = [p.decode('utf-8') for p in git(repo,'ls-tree','-rz','--name-only',commit,'--',prefix).split(b'\0') if p]
    names = [n for n in names if n.endswith('.wl')]
    required = 'src/Kernel/AsymptoticAnalysis.wl' if mode == 'modular' else prefix
    if required not in names:
        raise ValueError('Selected commit does not contain the expected entry file')
    output = output.resolve()
    if output.exists():
        raise FileExistsError('Destination exists; refuse to merge or overwrite a snapshot')
    output.parent.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='.asymptotic-stage-',dir=output.parent) as tmp:
        temporary = Path(tmp)/'snapshot'
        temporary.mkdir()
        staged=[]
        for name in names:
            rel = PurePosixPath(name)
            if rel.is_absolute() or '..' in rel.parts:
                raise ValueError('Unexpected repository path')
            # Preserve the Kernel directory and all relative module paths.
            rel = PurePosixPath(*rel.parts[1:]) if mode == 'modular' else rel
            destination = temporary/str(rel)
            destination.parent.mkdir(parents=True,exist_ok=True)
            destination.write_bytes(git(repo,'show',f'{commit}:{name}'))
            staged.append(str(rel))
        temporary.rename(output)
    return {'commit':commit,'mode':mode,'entry':str(output/('Kernel/AsymptoticAnalysis.wl' if mode=='modular' else required)),
            'staged_files':staged,'source_of_bytes':'Git objects, not the working tree',
            'scope':'Known WL source layout only; re-audit additional external dependencies.'}


def main() -> int:
    p=argparse.ArgumentParser(description=__doc__)
    p.add_argument('repository',type=Path)
    p.add_argument('revision')
    p.add_argument('output',type=Path)
    p.add_argument('--mode',choices=['modular','standalone'],default='modular')
    a=p.parse_args()
    print(json.dumps(stage(a.repository,a.revision,a.output,a.mode),indent=2))
    return 0

if __name__=='__main__':
    raise SystemExit(main())
