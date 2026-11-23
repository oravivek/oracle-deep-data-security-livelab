# Getting Started

## Introduction

Prepare your database and client tools before starting the timed labs. This
workshop configures an existing database and does not provision OCI resources.

Estimated Time: 10 minutes, excluding software installation.

### Objectives

- Verify database, client, model, and administrative prerequisites.
- Locate the runnable files included in this workshop.

### Prerequisites

Have these prerequisites ready before starting the timed tasks.

1. An isolated Linux hosted Oracle AI Database with DDS available, version 23.26.2 or later as required by the direct logon guide. Confirm support in your chosen deployment. This lab configures an existing database; it does not install Oracle. [Oracle direct logon prerequisites](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/you-begin-l.html)
2. SYS AS SYSDBA access to the target PDB for this lab’s bootstrap and cleanup, plus an existing ONLINE PERMANENT tablespace with at least 10 MB available. The default is USERS. Do not use a production schema.
3. SQL*Plus, or a compatible current SQLcl. Commands here use SQL*Plus syntax. A PDB service reachable from the client and Python host is required. Do not connect to CDB$ROOT or PDB$SEED.
4. Python 3.15, a POSIX shell such as bash or zsh, and permission to install packages in a virtual environment. The driver uses Thin mode and needs no Oracle Instant Client. [Python driver installation](https://python-oracledb.readthedocs.io/en/v26.1.0/user_guide/installation.html)
5. Ollama installed from its official site on the machine running Python and Streamlit. The qwen3:8b download is about 5.2 GB; allow additional memory for inference. Internet access is needed for initial package and model downloads. [Qwen3 8b model](https://ollama.com/library/qwen3:8b)
6. A text editor and a browser. No LLM API key or external IAM is required for the main path. The optional advanced lab requires Entra administrative support, database IAM trust, and certificate validated TCPS.

Record your PDB name, service alias, host and port, tablespace, and four lab passwords securely. Passwords are entered at prompts and are not included in configuration files. Database DDL and security setup commit independently of rollback.

## Task 1: Extract the workshop

1. Extract the workshop ZIP to a writable directory. The extracted project folder
   is named `deep-data-security-livelabs`.
2. Keep `sql`, `agent`, `tests`, `.streamlit`, and the configuration files together
   at the project root. All shell and SQL client launch commands in the labs assume
   that directory. No source copying from Word is needed.
3. Open `index.html` for the included self-contained workshop preview, or serve
   the root over HTTP to use the sample-compatible LiveLabs entry point.

## Task 2: Record your connection settings

1. Record the PDB service, actual PDB container name, host, port, tablespace, and
   administrator access method. All personas must use the same PDB.
2. Prepare four distinct lab passwords meeting the database password profile.
   The SQL setup prompts specify the supported substitution characters.
3. Review the optional IAM lab only if Entra administration and validated TCPS
   are available. The main database, agent, and web labs do not need IAM.

## Task 3: Locate the implementation

- [SQL setup and helpers](../sql/01_preflight.sql)
- [Database adapter](../agent/database.py)
- [Python agent](../agent/agent.py)
- [Streamlit interface](../streamlit_app.py)
- [Environment example](../config.env.example)
- [Complete executable quick start](../RUN_LAB.md)

You may now proceed to Lab 1.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 22 November 2026
