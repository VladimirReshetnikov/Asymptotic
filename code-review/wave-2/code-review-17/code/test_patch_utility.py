#!/usr/bin/env python3
"""Exercise the patch utility on synthetic Git fixtures, not the real repository."""
import importlib.util
import json
from pathlib import Path
import subprocess
import tempfile

base=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('patcher',base/'code/apply_patches.py')
patcher=importlib.util.module_from_spec(spec)
spec.loader.exec_module(patcher)
checks=0
assert patcher.replace_once('a X b','X','Y')=='a Y b';checks+=1
for text in ('none','X X'):
    try: patcher.replace_once(text,'X','Y')
    except ValueError: checks+=1
    else: raise AssertionError('Unsafe source anchor accepted')
for eol in ('\n','\r\n'):
    with tempfile.TemporaryDirectory() as tmp:
        root=Path(tmp)
        subprocess.run(['git','init','-q',str(root)],check=True)
        originals={}
        for name,rel in patcher.PATCHES.items():
            f=root/rel;f.parent.mkdir(parents=True,exist_ok=True)
            raw=('(* synthetic fixture *)\n'+
                 (base/'patches'/f'{name}_old.txt').read_text()).replace('\n',eol).encode()
            f.write_bytes(raw);originals[rel]=raw
        subprocess.run(['git','-C',str(root),'-c','core.autocrlf=false','add','.'],check=True)
        subprocess.run(['git','-C',str(root),'-c','user.email=test@example.invalid',
                        '-c','user.name=Fixture','commit','-qm','fixture'],check=True)
        cmd=['python',str(base/'code/apply_patches.py'),str(root),'--allow-other-revision']
        assert subprocess.run(cmd,capture_output=True).returncode==0;checks+=1
        assert subprocess.run(cmd+['--write'],capture_output=True).returncode==0;checks+=1
        assert subprocess.run(cmd+['--write'],capture_output=True).returncode==2;checks+=1
        for name,rel in patcher.PATCHES.items():
            f=root/rel
            assert f.with_suffix(f.suffix+'.pre-delta-audit').read_bytes()==originals[rel];checks+=1
            expected=(base/'patches'/f'{name}_new.txt').read_text().rstrip('\n').replace('\n',eol).encode()
            assert expected in f.read_bytes();checks+=1
result={'scope':'Synthetic-fixture patch utility tests, NOT native package tests',
        'checks_passed':checks,'line_endings':['LF','CRLF'],
        'remote_flat_source_anchor_matches':1}
(base/'evidence/patch_utility_results.json').write_text(json.dumps(result,indent=2)+'\n')
print(result)
