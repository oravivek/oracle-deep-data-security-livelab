"""Build and verify a sanitized lab ZIP using the explicit release inventory."""
from pathlib import Path
import argparse
import subprocess
import sys
import zipfile
from distribution import release_files

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--output', type=Path, required=True)
args = parser.parse_args()
subprocess.run([sys.executable, str(root / 'tools/validate_workshop.py'),
                '--release', '--verify-checksums'], check=True)
args.output.parent.mkdir(parents=True, exist_ok=True)
files = release_files(root)
with zipfile.ZipFile(args.output, 'w', zipfile.ZIP_DEFLATED) as archive:
    for p in files:
        archive.write(p, 'deep-data-security-livelabs/' + p.relative_to(root).as_posix())
with zipfile.ZipFile(args.output) as archive:
    assert archive.testzip() is None
    assert len(archive.namelist()) == len(files)
    assert not any('/.local/' in n or '/.git/' in n or '/.venv' in n
                   or n.endswith('/config.env') for n in archive.namelist())
print(f'PASS: verified ZIP with {len(files)} files: {args.output}')
