"""Validate workshop structure and release integrity without database changes."""
from pathlib import Path
import argparse
import ast
import hashlib
import json
import re
from distribution import release_files

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--write-checksums', action='store_true')
parser.add_argument('--verify-checksums', action='store_true')
parser.add_argument('--release', action='store_true')
args = parser.parse_args()
manifest_path = root / 'workshops/livelabs/manifest.json'
manifest = json.loads(manifest_path.read_text())
assert 'Autonomous Database 26ai' in manifest['workshoptitle']
assert len(manifest['tutorials']) == 11
pages = []
for tutorial in manifest['tutorials']:
    assert set(tutorial) == {'title', 'description', 'filename'}
    p = (manifest_path.parent / tutorial['filename']).resolve()
    assert p.is_relative_to(root) and p.is_file(), tutorial['filename']
    content = p.read_text()
    assert content.startswith('# ') and '## Acknowledgements' in content, p
    assert content.count('<copy>') == content.count('</copy>'), p
    assert content.count('```') % 2 == 0, p
    assert not re.search(r'CONNECT\s+SYS\b|AS SYSDBA|ALTER SYSTEM SET', content, re.I), p
    for target in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)', content):
        if target.startswith(('https://', 'http://', '#', 'mailto:')):
            continue
        target = target.split('#', 1)[0].split(' "', 1)[0]
        assert (p.parent / target).resolve().is_file(), (p, target)
    pages.append(p)
for p in [*(root / 'agent').glob('*.py'), *(root / 'tests').glob('*.py'),
          *(root / 'tools').glob('*.py'), root / 'streamlit_app.py']:
    ast.parse(p.read_text(), filename=str(p))
sql_files = list((root / 'sql').glob('*.sql'))
for p in sql_files:
    for helper in re.findall(r'^@@([^\s]+)', p.read_text(), re.M):
        assert (p.parent / helper).is_file(), (p, helper)
    assert 'SYSDBA' not in p.read_text(), p
assert "<> 'ADMIN'" in (root / 'sql/_admin.sql').read_text()
assert 'REMOVE_DDS_DEMO' in (root / 'sql/99_cleanup.sql').read_text()
assert 'REMOVE_DDS_AGENT_APP' in (root / 'sql/98_cleanup_agent_app.sql').read_text()
assert (root / 'sql/14_verify_cleanup.sql').is_file()
assert (root / '.streamlit/config.toml').is_file()

# Validate literal custom-tool metadata against the documented API contract.
team_sql = (root / 'sql/18_select_ai_team.sql').read_text()
tool_defs = re.findall(r"CREATE_TOOL\('([^']+)',q'~(.*?)~'\)", team_sql, re.S)
assert len(tool_defs) == 2, 'Expected two custom tool definitions'
for tool_name, literal in tool_defs:
    attributes = json.loads(literal)
    if 'tool_inputs' in attributes:
        inputs = attributes['tool_inputs']
        assert isinstance(inputs, list), (tool_name, 'tool_inputs must be an array')
        for item in inputs:
            assert isinstance(item, dict), tool_name
            assert set(item) == {'name', 'description'}, tool_name
            assert all(isinstance(v, str) and v for v in item.values()), tool_name
        assert {i['name'] for i in inputs} == {'p_employee_id', 'p_source'}, tool_name

files = [p for p in release_files(root) if p.name != 'SHA256SUMS.txt']
if args.release:
    assert 'CHANGE_ME_PDB' in (root / 'sql/00_config.sql').read_text()
    assert 'DEFINE dds_tablespace = DATA' in (root / 'sql/00_config.sql').read_text()
    assert 'CHANGE_ME_PDB' in (root / 'config.env.example').read_text()
    forbidden = re.compile(r'^-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----$'
                           r'|gh[pousr]_[A-Za-z0-9]{20,}', re.M)
    for p in files:
        if p.suffix == '.docx':
            continue
        assert not forbidden.search(p.read_text()), p
        assert p.stat().st_size < 10_000_000, p
checksum_text = ''.join(hashlib.sha256(p.read_bytes()).hexdigest() + '  '
                        + p.relative_to(root).as_posix() + '\n' for p in files)
if args.write_checksums:
    (root / 'SHA256SUMS.txt').write_text(checksum_text)
if args.verify_checksums:
    assert (root / 'SHA256SUMS.txt').read_text() == checksum_text, 'Release checksums differ'
print(f'PASS: {len(pages)} pages, {len(sql_files)} SQL files, local links, '
      f'Autonomous guards, Python syntax, {len(files)} release files')
if args.verify_checksums:
    print('PASS: SHA256SUMS.txt matches every distributed payload file')
