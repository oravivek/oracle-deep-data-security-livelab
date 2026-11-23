# Need Help

## Introduction

Use these checks to identify the failing stage of the demonstration. Expected
outputs refer to the original four-row baseline and the supplied data grants.

| Symptom | Check and action |
| --- | --- |
| Wrong PDB guard fails | Set sql/00_config.sql and ORACLE_EXPECTED_PDB to the actual container name and use its service |
| DDS syntax or dictionary view missing | Confirm version, deployment support, target PDB, and documented prerequisites |
| End user sign-in fails | Check password and account status and the login database role to data role to end user chain |
| Employee sees all four rows | Check the actual end user context and ensure the session is neither owner nor ADMIN |
| View returns broader data | Confirm base table USE_DATA_GRANTS_ONLY TRUE and inspect all overlapping grants |
| Manager sees a team identifier | Inspect additional authorizations and role memberships |
| SQL update has an unexpected error | Script exits and rolls back; investigate and verify unchanged data as owner |
| Probe works but AI does not | Check Ollama service, model availability, and tool calling; inspect current tool results |
| AI answer contradicts tool data | Treat the tool result as evidence and revise or rerun the model request |
| Streamlit shows sign-in failure | Test the same persona with SQL and the CLI using the same PDB and server environment |
| Shared account cannot attach context | Check TCPS validation, IAM resource audience and trust, and CREATE END USER SECURITY CONTEXT |
| Totals differ from 80000 or 285000 | Verify visible IDs and original values; reset salaries and phones if appropriate |
| Cleanup cannot drop an end user | Disconnect its active sessions before retrying |

**Completion criteria** Real SQL tests and live verifier pass; the manager’s team identifiers remain NULL in raw table and view results; same prompts show one employee record versus three manager records; UI user switching clears prior data; no agent tool can change identity or execute arbitrary SQL. A mock test pass or an LLM refusal is not a substitute for these database checks.

## Autonomous connection diagnostics

- Confirm the OCI database is available, the service alias is from its wallet, and your network can reach its endpoint. Use the same wallet and service for all personas.
- `ORACLE_CONFIG_DIR` must contain `tnsnames.ora`; the Thin mTLS wallet location must contain `ewallet.pem`. A wallet password is separate from the user's database password.
- If a Python HTTPS certificate check fails on macOS, use `export SSL_CERT_FILE="$(python -m certifi)"` after installing certifi. Keep certificate and DN validation enabled.
- If the model endpoint returns 404, finish `ollama pull qwen3:8b` and confirm the model tag with `ollama list` before retrying. Database probes do not need the model.
- ADMIN setup errors are checked by the preflight. Use an Autonomous 26ai deployment with DDS available; do not replace missing privileges with SYS instructions.

## Python 3.15 dependency installation

The older Streamlit 1.51.0 dependency restrictions can cause PyArrow or pandas
source builds on Python 3.15. Use the updated requirements in this package:
Streamlit 1.67.0, pandas 3.1.1, and PyArrow 26.0.1. Run `bash setup.sh` at the
project root, then `source .venv315/bin/activate`. Binary wheels avoid the missing
CMake build failure. Confirm `python --version` identifies Python 3.15.

## What You Built

You built an identity aware database policy, a tool calling agent that retrieves authorized results, and a presenter interface that makes the active principal and supporting tool evidence visible. The same sample data and grants support every main lab path.

For a production application, replace lab password entry with an authenticated application login, select the supported identity propagation pattern, and verify identity isolation under concurrent requests and any connection pooling. Expand policies and tools only after adding corresponding real database acceptance checks.

## Autonomous Database reference

[Deep Data Security on Autonomous Database](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/deep-data-security.html)

## Learn More

The provided sample workshop informed the folder and page structure. Product documentation supports the mechanisms described here; it does not certify execution of this custom lab. Source references were checked on 23 November 2026.

[R1  Oracle direct logon prerequisites](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/you-begin-l.html)

[R2  Create data grants](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/create-data-grants.html)

[R3  Direct logon quick start](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-oracle-deep-data-security-direct-logon-local-end-users.html)

[R4  Create end users](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/create-end-user.html)

[R5  Grant database roles to data roles](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/grant-database-role-data-role.html)

[R6  Mandatory data privileges](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/enforce-mandatory-data-privileges.html)

[R7  Fine grained data authorization](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/fine-grained-data-authorization.html)

[R8  Access check functions](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/use-access-check-functions.html)

[R9  Python context APIs](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-python-applications.html)

[R10  Python driver installation](https://python-oracledb.readthedocs.io/en/v26.1.0/user_guide/installation.html)

[R11  Qwen3 8b model](https://ollama.com/library/qwen3:8b)

[R12  Ollama tool calling](https://docs.ollama.com/capabilities/tool-calling)

[R13  Local end user application authentication](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-database-local-end-user-authentication.html)

[R14  Database IAM integration](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-database-iam-integration.html)

[R15  Database TLS configuration](https://docs.oracle.com/en/database/oracle/oracle-database/26/dbseg/configuring-transport-layer-security-encryption.html)

[R16  Register database in Entra](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/register-database-microsoft-entra-id.html)

[R17  Register application in Entra](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/register-application-microsoft-entra-id.html)

[R18  Validate Entra configuration](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/validate-microsoft-entra-id-configuration.html)

[R19  Streamlit forms](https://docs.streamlit.io/develop/api-reference/execution-flow/st.form)

[R20  Streamlit Session State](https://docs.streamlit.io/develop/api-reference/caching-and-state/st.session_state)

[R21  Streamlit AppTest](https://docs.streamlit.io/develop/api-reference/app-testing/st.testing.v1.apptest)

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 23 November 2026
