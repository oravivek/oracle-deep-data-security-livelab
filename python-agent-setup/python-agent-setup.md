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

Use the documented Python 3.15 path from the project root:

```bash
<copy>
bash setup.sh
source .venv315/bin/activate
python --version
python -m pip check
</copy>
```

Setup installs binary wheels with the supplied version pins: python-oracledb 26.1.0, Streamlit 1.67.0, pandas 3.1.1 and PyArrow 26.0.1 on Python 3.15. CMake is not needed. Use `PYTHON_BIN=/absolute/path/to/python3.15 bash setup.sh` to select an interpreter. The optional Python 3.12 compatibility path uses `.venv`; all workshop commands and the Word document use `.venv315`.

The driver stays in Thin mode; do not call `init_oracle_client`. No Oracle Instant Client is needed. [Driver installation](https://python-oracledb.readthedocs.io/en/v26.1.0/user_guide/installation.html)

## Task 2: Configure the connection

```bash
<copy>
cp config.env.example config.env
# Edit config.env with your actual connection values, then:
source config.env
</copy>
```

Edit these values in `config.env`, using the alias and absolute wallet path from Lab 1:

```bash
<copy>
export ORACLE_DSN='youradb_high'
export ORACLE_EXPECTED_PDB='YOUR_ACTUAL_PDB_NAME'
export ORACLE_CONFIG_DIR='/absolute/path/to/Wallet_youradb'
export ORACLE_WALLET_LOCATION='/absolute/path/to/Wallet_youradb'
export OLLAMA_MODEL='qwen3:8b'
</copy>
```

`ORACLE_CONFIG_DIR` locates `tnsnames.ora`; `ORACLE_WALLET_LOCATION` locates `ewallet.pem`. The app prompts for the wallet password and each persona's database password. Do not put passwords in this file. A full TCPS descriptor from OCI Database Connection may replace the TNS alias. Keep server DN matching enabled.

```bash
<copy>
chmod 600 config.env
source config.env
</copy>
```

The app does not automatically load dotenv files. Source the file in every terminal launching Python. The documented main path uses mTLS; a separately configured wallet-free TLS endpoint must follow the Autonomous connection guidance. [Autonomous connection support in the driver](https://python-oracledb.readthedocs.io/en/v26.1.0/user_guide/connection_handling.html#connecting-to-oracle-autonomous-database-adb)

If Python on macOS reports a missing trusted CA bundle, use the maintained certifi bundle without disabling certificate verification:

```bash
<copy>
python -m pip install certifi
export SSL_CERT_FILE="$(python -m certifi)"
</copy>
```

Repeat that export in each launching terminal if needed. It also lets urllib validate HTTPS certificates for the optional Entra token endpoint.

## Task 3: Install and start the local model

Install Ollama from https://ollama.com/download using the vendor installer for your operating system. Use the supplied launcher in a separate terminal if no Ollama service is already running. It binds to loopback, disables cloud features, and recognizes either a standard installation or the project-local runtime:

```bash
<copy>
bash start_ollama.sh
</copy>
```

Then download and inspect the model:

```bash
<copy>
# Standard Ollama installation:
ollama pull qwen3:8b
ollama list
# If using the project-local runtime already installed on the presenter Mac:
# .local/ollama/ollama pull qwen3:8b
# .local/ollama/ollama list
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

Enter the wallet password and matching database passwords when prompted. They are separate credentials. Each probe prints AUTHENTICATED with its verified persona, then TABLE, VIEW, EMPLOYEE_300, and SUMMARY results without invoking the model. The verifier prompts for both personas and must print PASS DDS_EMMA and PASS DDS_MARVIN.

| Evidence | Employee Emma | Manager Marvin |
| --- | --- | --- |
| Table and view IDs | 400 | 200, 400, 500 |
| Own sensitive identifier | ID-DEMO-0400 | ID-DEMO-0200 |
| Team sensitive identifiers | No team rows | NULL for 400 and 500 |
| Employee 300 lookup | Empty rows | Empty rows |
| Visible employee count | 1 | 3 |
| Salary total | 80000 | 285000 |

On the tested Autonomous release, manager team identifiers remain NULL through the view even when its `id_authorized` flag is true. Check actual values and use the base-table flag to diagnose column authorization.

**Checkpoint** The live verifier passes. If it does not, fix the SQL baseline or connection settings before invoking the model. Inspect raw JSON null values; the words Restricted in a model answer alone are insufficient evidence.

You may now proceed to the next lab.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 23 November 2026
