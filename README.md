# Oracle Autonomous Database 26ai Deep Data Security live lab

Build database-enforced employee and manager authorization, connect a Python AI
agent, and demonstrate the results in Streamlit. Oracle Autonomous Database 26ai
enforces data grants before any employee data reaches the local **Qwen3 8B** LLM
served by **Ollama**. All sample records and identifiers are synthetic.

## Start here

Download the runnable [Autonomous Database lab ZIP](https://github.com/oravivek/oracle-deep-data-security-livelab/raw/refs/heads/main/downloads/Oracle_Autonomous_Database_26ai_DDS_LiveLab.zip).

1. Open `index.html` for the self-contained LiveLabs-style workshop. Follow
   Getting Started and Labs 1 through 6. Lab 7 is optional; Lab 8 is cleanup.
2. Use [RUN_LAB.md](RUN_LAB.md) for the executable quick start.
3. The complete Word guide is in
   [docs/Oracle_26ai_Deep_Data_Security_End_to_End_LiveLab.docx](docs/Oracle_26ai_Deep_Data_Security_End_to_End_LiveLab.docx).
   Its source listings are generated from the files in this repository.

## Prerequisites

- An isolated Autonomous Database **26ai** with DDS available and ADMIN access.
- A reachable database endpoint and its instance wallet for the main mTLS path.
- Current SQLcl, Python **3.15**, bash or zsh, a browser and Ollama.
- Internet for initial Python packages and the approximately 5.2 GB Qwen3 download.

The main lab requires no external IAM, cloud LLM API key or Oracle Instant Client.
It uses the existing DATA tablespace with a 10 MB DDS_OWNER quota. Setup and
cleanup use ADMIN; application queries use DDS_EMMA or DDS_MARVIN.

## Runtime setup

```bash
bash setup.sh
source .venv315/bin/activate
cp config.env.example config.env
# Edit the Autonomous alias, actual container name and wallet paths first.
chmod 600 config.env
source config.env
python -m unittest discover -s tests -v
python agent/verify_live.py
```

In a separate terminal, start `bash start_ollama.sh` if no service is running.
Download `qwen3:8b` using `ollama pull qwen3:8b` (or the installed local binary
`.local/ollama/ollama`). Then launch:

```bash
source .venv315/bin/activate
source config.env
python -m streamlit run streamlit_app.py
```

Open http://127.0.0.1:8501. Enter the chosen persona's database password and the
wallet password. Sign-out clears credentials; enter the wallet password again
when switching personas. Inspect database results before judging the AI answer.

| Evidence | Emma | Marvin |
| --- | --- | --- |
| Visible IDs in table and view | 400 | 200, 400, 500 |
| Own sensitive ID | Visible | Visible |
| Team sensitive IDs | No team rows | NULL |
| Employee 300 | No authorized row | No authorized row |
| Count and salary total | 1 and 80000 | 3 and 285000 |

## Contents and validation

`sql/` contains setup, demo, reset, inspection and guarded cleanup scripts.
`agent/`, `streamlit_app.py`, `tests/` and `.streamlit/` contain the runnable
application. Eleven Markdown pages and `workshops/livelabs/manifest.json`
provide the workshop. `tools/` contains validation, packaging, Word and preview
builders. `config.env.example` contains placeholders only.

Read [VALIDATION.md](VALIDATION.md) for observed tests and pending checks.
Marvin's live AI suite and optional delegated IAM flow are not yet validated.
Cleanup has not been executed against the active demo during this update.

```bash
python tools/validate_workshop.py
python tools/validate_workshop.py --verify-checksums
```

For the Oracle-hosted renderer shell, serve the root with
`python -m http.server 8000 --bind 127.0.0.1` and open
http://127.0.0.1:8000/workshops/livelabs/. That shell downloads Oracle assets;
the root `index.html` is the offline preview.

This is a custom workshop following the supplied OCI Database Management sample,
not a published Oracle LiveLabs catalog entry. The sample folder is unchanged.

## Distribution

Keep wallets, real config.env, passwords, tokens, model files, virtual environments
and private live-test evidence outside GitHub and release archives. The supplied
packager enforces exclusions and placeholder configuration. Each participant
supplies their own database connection, wallet and credentials.

See [BUILDING.md](BUILDING.md) to regenerate the Word document, preview and ZIP.
