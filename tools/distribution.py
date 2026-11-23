"""Explicit release inventory shared by validation and ZIP generation."""
ROOT_FILES = {
    '.gitignore', 'README.md', 'RUN_LAB.md', 'AUTONOMOUS_CONNECTION.md',
    'AI_VERIFICATION.md', 'VALIDATION.md', 'BUILDING.md',
    'BUILD_VERIFICATION.txt', 'config.env.example', 'requirements.txt',
    'requirements-streamlit.txt', 'setup.sh', 'start_ollama.sh',
    'streamlit_app.py', 'index.html', 'SHA256SUMS.txt',
}
FOLDERS = {
    'sql': {'.sql'}, 'agent': {'.py'}, 'tests': {'.py'},
    'tools': {'.py', '.mjs', '.txt'}, '.streamlit': {'.toml'},
    'docs': {'.docx'}, 'workshops': {'.html', '.json'},
    'introduction': {'.md', '.svg'}, 'prerequisites': {'.md'},
    'prepare-workspace': {'.md'}, 'database-setup': {'.md'},
    'sql-demo': {'.md', '.svg'}, 'python-agent-setup': {'.md'},
    'ai-agent-demo': {'.md'}, 'streamlit-demo': {'.md', '.svg'},
    'identity-propagation': {'.md'}, 'cleanup': {'.md'},
    'need-help': {'.md'},
}


def release_files(root):
    files = [root / name for name in ROOT_FILES if (root / name).is_file()]
    for folder, suffixes in FOLDERS.items():
        for p in (root / folder).rglob('*'):
            if (p.is_file() and p.suffix in suffixes
                    and not p.name.startswith(('~$', '.'))
                    and '__pycache__' not in p.parts):
                if p.is_symlink():
                    raise ValueError('Release inventory contains a symlink')
                files.append(p)
    return sorted(files, key=lambda p: p.relative_to(root).as_posix())
