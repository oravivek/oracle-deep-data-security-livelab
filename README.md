# Oracle AI Database 26ai Deep Data Security LiveLabs Workshop

This package follows the supplied `oci-database-management` workshop structure:
one directory and Markdown page per lab, timed tasks, objectives, prerequisites,
copyable commands, local images, acknowledgements, and a JSON workshop manifest.
The SQL, Python agent, Streamlit app, tests, and nonsecret configuration examples
are included at the root. The original sample directory has not been modified.

## Set up the Python environment

The lab now supports your installed **Python 3.15**. Run from this folder:

```bash
bash setup.sh
source .venv315/bin/activate
python --version
```

The setup script defaults to `python3.15` and creates `.venv315` using that
interpreter. It installs binary wheels, checks dependencies, and prints versions.
The Python 3.15 requirements use Streamlit 1.67.0, pandas 3.1.1, and PyArrow
26.0.1. These replace the older dependency restrictions that triggered a source
build. CMake is not required. No system-wide Python package changes are made.

For a custom interpreter path, set `PYTHON_BIN=/absolute/path/to/python3.15` when
running setup. The optional original Python 3.12 environment remains available
with `PYTHON_BIN=python3.12 bash setup.sh` and `source .venv/bin/activate`.
Requirements select the older Streamlit release only on Python below 3.15.

The included Word document records the original Python 3.12 setup. Use this
README, the Markdown labs, and the bundled requirements for the Python 3.15
installation and launch commands; the database and agent workflow is unchanged.

## View the workshop

**Self-contained preview:** open `index.html` in your browser. It includes local
navigation, collapsible tasks, copy buttons, and all workshop text and diagrams.
It works directly from disk without downloading the Oracle renderer assets.

**Sample-compatible LiveLabs entry point:** from this directory run:

```bash
python3 -m http.server 8000 --bind 127.0.0.1
```

Then open http://127.0.0.1:8000/workshops/livelabs/ . This entry point reuses the
sample's Oracle Redwood LiveLabs shell and public Oracle JavaScript/CSS URLs;
internet access is required for those assets. If your network blocks them,
use http://127.0.0.1:8000/ for the self-contained preview. Stop with Ctrl+C.
The server is bound to your own computer and does not publish the workshop.

The authoritative content is `workshops/livelabs/manifest.json` and the Markdown
pages it references. `index.html` is a generated local preview; rebuild it after
editing Markdown with `tools/build-preview.mjs` as described below.

## Run the lab

Start with Introduction and Getting Started in the workshop. Follow Labs 1–6
for the main database, Python, and Streamlit demonstration. Lab 7 is optional
IAM/TCPS identity propagation; Lab 8 resets or removes the dedicated demo.

All shell commands run from this project root. Configure `sql/00_config.sql`
and create `config.env` from `config.env.example` before connecting. Database,
Ollama, and Python prerequisites are explained in the labs and [RUN_LAB.md](RUN_LAB.md).
No source copying from the included Word document is needed.

## Structure

```text
deep-data-security-livelabs/
  introduction/introduction.md
  introduction/images/architecture.svg
  prerequisites/prerequisites.md
  prepare-workspace/prepare-workspace.md
  database-setup/database-setup.md
  sql-demo/sql-demo.md
  sql-demo/images/access-comparison.svg
  python-agent-setup/python-agent-setup.md
  ai-agent-demo/ai-agent-demo.md
  streamlit-demo/streamlit-demo.md
  streamlit-demo/images/interface-layout.svg
  identity-propagation/identity-propagation.md
  cleanup/cleanup.md
  need-help/need-help.md
  workshops/livelabs/index.html
  workshops/livelabs/manifest.json
  sql/                         all 18 SQL files
  agent/                       Python adapter agent token helper and live verifier
  tests/                       19 offline checks
  .streamlit/config.toml
  streamlit_app.py
  requirements.txt
  requirements-streamlit.txt
  config.env.example
  setup.sh                     Python 3.15 environment installer
  docs/                        end-to-end Word lab
  index.html                   self-contained workshop preview
  RUN_LAB.md                   executable quick start
  tools/                       validation and preview builders
  SHA256SUMS.txt
```

## Validate or update the workshop

```bash
python3 tools/validate_workshop.py
```

This checks manifest paths, copy tags, local Markdown resources, script inclusion,
and Python syntax. To rebuild only the preview after editing content, install
`marked@17.0.5` with Node.js 20 or later in a separate tools environment and make it available
to the builder (the lab runtime itself requires no Node.js):

```bash
npm install --prefix /path/to/livelabs-preview-tools marked@17.0.5
node tools/build-preview.mjs /path/to/livelabs-preview-tools/node_modules/marked/lib/marked.esm.js
```

After changing package files, regenerate `SHA256SUMS.txt` before redistribution:

```bash
python3 tools/validate_workshop.py --write-checksums
```

The offline application tests use mock database and model services. Live Oracle,
IAM, and Ollama checks still require your configured environment. No credentials,
edited config.env, wallets, tokens, virtual environment, or models are packaged.

This is a custom workshop package, not a published Oracle LiveLabs catalog entry.
No help mailbox is configured because a published workshop support owner has
not been assigned. The Need Help page provides local diagnostics and references.
