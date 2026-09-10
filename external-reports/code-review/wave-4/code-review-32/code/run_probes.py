"""Run characterization probes against a coherent, archived Git revision.

This runner has NOT been used with a native kernel in the review environment.
It labels completion, not mathematical success. It reads committed repository
objects and never changes the checkout or installs package patches.
"""
from __future__ import annotations
import argparse
import io
import json
import os
from pathlib import Path, PurePosixPath
import signal
import subprocess
import sys
import tarfile
import tempfile
import time
from reference_algorithms import validate_timeout

PIN = '513917b5b387152256b14ac76d92dd30cd13a11d'
CASES = ('lambert-source', 'lambert-core', 'parameter-domain',
         'narrow-neighborhood', 'sparse-small', 'limit-default', 'terminating-hypergeometric')


def extract_regular_archive(data: bytes, directory: Path) -> None:
    """Refuse links and traversal; extract only ordinary directories/files."""
    with tarfile.open(fileobj=io.BytesIO(data), mode='r:') as archive:
        for member in archive.getmembers():
            relative = PurePosixPath(member.name)
            if relative.is_absolute() or '..' in relative.parts:
                raise ValueError('Unsafe archive member')
            destination = directory.joinpath(*relative.parts)
            if member.isdir():
                destination.mkdir(parents=True, exist_ok=True)
            elif member.isfile():
                destination.parent.mkdir(parents=True, exist_ok=True)
                stream = archive.extractfile(member)
                if stream is None:
                    raise ValueError('Missing archive file content')
                destination.write_bytes(stream.read())
            else:
                raise ValueError('Links and special files are not admitted')


def stop_tree(process: subprocess.Popen) -> None:
    if os.name == 'nt':
        try:
            subprocess.run(['taskkill.exe', '/PID', str(process.pid), '/T', '/F'],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                           timeout=10, check=False)
        except (OSError, subprocess.TimeoutExpired):
            pass
    else:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
    if process.poll() is None:
        process.kill()


def run_one(command: list[str], env: dict, cwd: Path, timeout: float) -> dict:
    started = time.monotonic()
    try:
        process = subprocess.Popen(command, env=env, cwd=cwd, stdout=subprocess.PIPE,
                                   stderr=subprocess.STDOUT, start_new_session=os.name != 'nt')
    except OSError as error:
        return {'Outcome': 'LaunchError', 'Output': str(error), 'ExitCode': None}
    try:
        output, _ = process.communicate(timeout=timeout)
        outcome = 'Completed' if process.returncode == 0 else 'NonzeroExit'
    except subprocess.TimeoutExpired:
        stop_tree(process)
        output, _ = process.communicate(timeout=10)
        outcome = 'Timeout'
    except BaseException:
        stop_tree(process)
        process.communicate(timeout=10)
        raise
    return {'Outcome': outcome, 'ExitCode': process.returncode,
            'ElapsedSeconds': round(time.monotonic()-started, 3),
            'Output': output.decode('utf-8', errors='replace')}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--repo', type=Path, required=True)
    parser.add_argument('--commit', default=PIN)
    parser.add_argument('--entry', choices=('modular', 'standalone'), default='modular')
    runtimes = parser.add_mutually_exclusive_group(required=True)
    runtimes.add_argument('--mathics-python', help='Python interpreter containing the selected Mathics version')
    runtimes.add_argument('--wolfram', help='Official kernel executable supporting -noinit -script')
    parser.add_argument('--case', action='append', choices=CASES)
    parser.add_argument('--timeout', type=float, default=180)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        timeout = validate_timeout(args.timeout)
    except ValueError as error:
        parser.error(str(error))
    repo = args.repo.resolve()
    # Resolve first, then archive this immutable object ID, not a moving branch.
    revision = subprocess.check_output(
        ['git', '-C', str(repo), 'rev-parse', '--verify', args.commit+'^{commit}'], text=True).strip()
    archive = subprocess.check_output(['git', '-C', str(repo), 'archive', '--format=tar', revision,
                                       'src/Kernel', 'AsymptoticAnalysis.wl'])
    report = {'Revision': revision, 'Entry': args.entry,
              'SourceAcquisition': 'git archive of the resolved commit object; working-tree edits are not tested',
              'Interpretation': 'Completed means process completion, NOT a passing mathematical assertion',
              'Results': []}
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix='asymptotic-review-') as temporary:
        directory = Path(temporary)
        extract_regular_archive(archive, directory)
        script = directory / 'portable_probe.wl'
        script.write_bytes(Path(__file__).with_name('portable_probe.wl').read_bytes())
        source = directory / ('src/Kernel/AsymptoticAnalysis.wl' if args.entry == 'modular'
                              else 'AsymptoticAnalysis.wl')
        executable = args.mathics_python or args.wolfram
        if Path(executable).is_file():
            executable = str(Path(executable).resolve())
        command = ([executable, '-m', 'mathics', '--quiet', '--no-readline', '--file', str(script)]
                   if args.mathics_python else [executable, '-noinit', '-script', str(script)])
        for case in args.case or CASES:
            env = dict(os.environ, ASYMPTOTIC_REVIEW_SOURCE=str(source),
                       ASYMPTOTIC_REVIEW_CASE=case, PYTHONIOENCODING='utf-8', PYTHONUNBUFFERED='1')
            for key in tuple(env):
                if key.upper() in ('WOLFRAMINIT', 'MATHKERNELINIT'):
                    del env[key]
            result = run_one(command, env, directory, timeout)
            result['Case'] = case
            report['Results'].append(result)
            args.output.write_text(json.dumps(report, indent=2)+'\n', encoding='utf-8')
            print(case, result['Outcome'], flush=True)
            if result['Outcome'] == 'LaunchError':
                break
    return 0 if (len(report['Results']) == len(args.case or CASES) and
                 all(r['Outcome'] == 'Completed' for r in report['Results'])) else 1

if __name__ == '__main__':
    raise SystemExit(main())
