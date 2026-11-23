# Getting Started

## Introduction

Prepare an Oracle Autonomous Database 26ai and the local tools used to present the lab.

Estimated Time: 15 minutes excluding provisioning and downloads.

### Objectives

- Confirm the database supports Deep Data Security.
- Prepare ADMIN access, a wallet, SQLcl, Python and Ollama.


## Task 1: Prepare Autonomous Database

1. Use an isolated Oracle Autonomous Database **26ai** with Deep Data Security available. This workshop configures an existing database and does not provision or terminate OCI resources.
2. Obtain the ADMIN database password and permission to create dedicated demo principals. Setup and cleanup use ADMIN. All application queries use the authenticated end user.
3. In OCI, confirm that your client can reach the database endpoint under its network access rules. A private endpoint needs a permitted network route. Use Database Connection to record the exact service and download the **instance wallet** for the main mTLS path. Keep its password private.
4. Use the existing DATA tablespace. DDS_OWNER receives only a 10 MB quota there. No tablespace, listener, operating system or database parameter change is needed for the main path.

[Autonomous Deep Data Security prerequisites](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/deep-data-security.html)

## Task 2: Prepare local tools

1. Install a current SQLcl supporting `SET CLOUDCONFIG`, Python 3.15, a text editor, and a browser. Run commands in a POSIX shell such as bash or zsh.
2. Install Ollama from https://ollama.com/download. The local LLM is **Qwen3 8B**, model tag `qwen3:8b`; its download is about 5.2 GB. Allow additional memory for inference. The tested presenter Mac has 16 GB RAM.
3. Download packages and the model while internet access is available. The main lab requires no cloud LLM API key, external IAM integration or Oracle Instant Client. Python uses python-oracledb Thin mode.
4. Prepare four distinct database passwords meeting the Autonomous password profile. The SQL substitution prompts support letters, digits, underscore and # only; start with a letter and use at least 16 mixed-case characters. Keep them separate from the wallet password.

## Task 3: Extract the project

Extract the ZIP to a writable folder named `deep-data-security-livelabs`. Keep SQL helpers, agent code, tests and configuration together. Open `index.html` for the self-contained workshop preview. All commands assume the project root.

The Word document includes the full executable SQL and Python listings. The ZIP already contains those files, so no copying from Word is required. Follow Labs 1 through 6, optionally Lab 7, and finally Lab 8.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 23 November 2026
