"""Validate a local LiveLabs workshop without connecting to a database."""
from pathlib import Path
import argparse
import ast
import hashlib
import json
import re

root=Path(__file__).resolve().parents[1]
parser=argparse.ArgumentParser(description=__doc__)
parser.add_argument('--write-checksums',action='store_true')
args=parser.parse_args()
manifest_path=root/'workshops/livelabs/manifest.json'
manifest=json.loads(manifest_path.read_text())
assert manifest['workshoptitle']
assert len(manifest['tutorials'])==11
pages=[]
for tutorial in manifest['tutorials']:
    assert set(tutorial)=={'title','description','filename'}
    p=(manifest_path.parent/tutorial['filename']).resolve()
    assert p.is_relative_to(root) and p.is_file(),tutorial['filename']
    content=p.read_text()
    assert content.startswith('# '),p
    assert '## Acknowledgements' in content,p
    assert 'Appendix ' not in content,p
    assert content.count('<copy>')==content.count('</copy>'),p
    assert content.count('```')%2==0,p
    for target in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)',content):
        if target.startswith(('https://','http://','#','mailto:')):continue
        target=target.split('#',1)[0].split(' "',1)[0]
        assert (p.parent/target).resolve().is_file(),(p,target)
    pages.append(p)
for p in [*(root/'agent').glob('*.py'),*(root/'tests').glob('*.py'),root/'streamlit_app.py']:
    ast.parse(p.read_text(),filename=str(p))
sql_count=len(list((root/'sql').glob('*.sql')))
assert sql_count>=18
assert (root/'.streamlit/config.toml').is_file()
if args.write_checksums:
    files=sorted(p for p in root.rglob('*') if p.is_file()
                 and p.name not in {'SHA256SUMS.txt','config.env'}
                 and '__pycache__' not in p.parts and '.local' not in p.parts
                 and not any(part.startswith('.venv') for part in p.parts)
                 and p.suffix!='.pyc')
    (root/'SHA256SUMS.txt').write_text(''.join(
        hashlib.sha256(p.read_bytes()).hexdigest()+'  '+p.relative_to(root).as_posix()+'\n'
        for p in files))
print(f'PASS: {len(pages)} manifest pages, local links, copy tags, {sql_count} SQL files, Python syntax')
