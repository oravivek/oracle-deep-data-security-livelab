# Install and Verify the Python Agent

## Introduction

Install the runtime and validate database tools before model inference.

Estimated Time: 15 minutes plus download time.

### Objectives

- Install the environment and prove real database access before using an LLM.

### Prerequisites

This lab assumes the following are complete:

- Lab 3: Prove Employee and Manager Access with SQL

## Task 1: Install the Python dependencies

Use your installed Python 3.15 explicitly and the updated requirements supplied with this workshop. In a terminal at the project root, run:

```bash
<copy>
python3.15 -m venv .venv315
source .venv315/bin/activate
python -m pip install --only-binary=:all: -r requirements-streamlit.txt
python -c "import oracledb; print(oracledb.__version__)"
python -c "import streamlit; print(streamlit.__version__)"
</copy>
```

Expected versions on Python 3.15 are oracledb 26.1.0, Streamlit 1.67.0, pandas 3.1.1, and PyArrow 26.0.1. requirements-streamlit.txt includes the base requirements. Do not call init_oracle_client; context APIs use Thin mode. [Python context APIs](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-python-applications.html), [Python driver installation](https://python-oracledb.readthedocs.io/en/v26.1.0/user_guide/installation.html)

## Task 2: Configure the connection

```bash
<copy>
cp config.env.example config.env
# Edit config.env with your actual connection values, then:
source config.env
</copy>
```

Set ORACLE_DSN to the same PDB service and ORACLE_EXPECTED_PDB to the actual container name. Set OLLAMA_MODEL to qwen3:8b. The application does not automatically read dotenv files; source this file in every terminal that launches the app. No database password belongs in it.

For a TNS alias, set ORACLE_CONFIG_DIR to the directory containing tnsnames.ora. If a configured PEM wallet is needed, set ORACLE_WALLET_LOCATION; the app prompts for its password. Certificate checking remains enabled. The main direct path does not require an application account, IAM token, or additional grants.

## Task 3: Install and start the local model

Install Ollama from https://ollama.com/download using the vendor installer for your operating system. Start the Ollama application. On a CLI installation, run this in a separate terminal if no Ollama service is already running:

```bash
<copy>
ollama serve
</copy>
```

Then download and inspect the model:

```bash
<copy>
ollama pull qwen3:8b
ollama list
</copy>
```

The agent calls http://127.0.0.1:11434/api/chat with tool schemas, stream false, think false, and temperature zero. Keep a current Ollama version supporting these options. The model runs on the Streamlit server’s machine, which may be different from the Oracle server. [Qwen3 8b model](https://ollama.com/library/qwen3:8b), [Ollama tool calling](https://docs.ollama.com/capabilities/tool-calling)

## Task 4: Run syntax and offline checks

```bash
<copy>
python -m py_compile agent/database.py agent/agent.py
python -m py_compile agent/tokens.py agent/verify_live.py streamlit_app.py
python -m unittest discover -s tests -v
</copy>
```

Expected: syntax commands finish without errors and 19 tests pass. These tests use mock database and model services. They check identity guards, argument binding, failed sign-ins, user switching, current result display, and session separation; they do not validate Oracle DDS enforcement.

## Task 5: Run deterministic real database probes

```bash
<copy>
python agent/agent.py --user DDS_EMMA --probe
python agent/agent.py --user DDS_MARVIN --probe
python agent/verify_live.py
</copy>
```

Enter the matching passwords when prompted. Each probe prints AUTHENTICATED with its verified persona, then TABLE, VIEW, EMPLOYEE_300, and SUMMARY results without invoking the model. The verifier prompts for both personas and must print PASS DDS_EMMA and PASS DDS_MARVIN.

| Evidence | Employee Emma | Manager Marvin |
| --- | --- | --- |
| Table and view IDs | 400 | 200, 400, 500 |
| Own sensitive identifier | ID-DEMO-0400 | ID-DEMO-0200 |
| Team sensitive identifiers | No team rows | NULL for 400 and 500 |
| Employee 300 lookup | Empty rows | Empty rows |
| Visible employee count | 1 | 3 |
| Salary total | 80000 | 285000 |

**Checkpoint** The live verifier passes. If it does not, fix the SQL baseline or connection settings before invoking the model. Inspect raw JSON null values; the words Restricted in a model answer alone are insufficient evidence.

You may now proceed to the next lab.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 22 November 2026
