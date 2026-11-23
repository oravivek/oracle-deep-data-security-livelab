#!/usr/bin/env bash
# Run with: bash setup.sh
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

lab_python="${PYTHON_BIN:-python3.15}"
if ! command -v "$lab_python" >/dev/null 2>&1; then
  echo 'Python 3.15 was not found. Select your installed Python 3.15 interpreter.' >&2
  echo 'For a custom location: PYTHON_BIN=/absolute/path/to/python3.15 bash setup.sh' >&2
  exit 1
fi
lab_version=$("$lab_python" -c 'import sys; v=sys.version_info[:2]; sys.exit("Use Python 3.15 or the legacy Python 3.12 environment") if v not in {(3, 12), (3, 15)} else print("%d.%d" % v)')
if [[ "$lab_version" == 3.15 ]]; then
  lab_venv=.venv315
else
  lab_venv=.venv
fi

if [[ -e "$lab_venv" ]]; then
  if [[ ! -x "$lab_venv/bin/python" ]]; then
    echo "An incomplete $lab_venv already exists. Move it aside before rerunning setup." >&2
    exit 1
  fi
  "$lab_venv/bin/python" -c 'import sys; current="%d.%d" % sys.version_info[:2]; sys.exit(0 if current == sys.argv[1] else "Existing environment uses another Python version. Move it aside and rerun setup.")' "$lab_version"
else
  "$lab_python" -m venv "$lab_venv"
fi

"$lab_venv/bin/python" -m pip install --only-binary=:all: --no-cache-dir -r requirements-streamlit.txt
"$lab_venv/bin/python" -m pip --no-cache-dir check
"$lab_venv/bin/python" -c 'import sys, oracledb, streamlit, pandas, pyarrow; print("Python", sys.version.split()[0]); print("oracledb", oracledb.__version__); print("streamlit", streamlit.__version__); print("pandas", pandas.__version__); print("pyarrow", pyarrow.__version__)'
echo "Setup complete. In your terminal, run: source $lab_venv/bin/activate"
