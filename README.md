# Oracle Autonomous Database 26ai Deep Data Security Live Lab

Demonstrate Emma and Marvin with **Streamlit → Select AI Agent → OCI Generative AI**. Autonomous Database enforces row and column data grants when the invoker-rights entry opens fixed query cursors before authorized synthetic data reaches the LLM. The agent is implemented with DBMS_CLOUD_AI_AGENT, not a local Python orchestration loop.

[Download the complete ZIP](https://github.com/oravivek/oracle-deep-data-security-livelab/raw/refs/heads/main/downloads/Oracle_Autonomous_Database_26ai_DDS_LiveLab.zip) · [Word guide](docs/Oracle_26ai_Deep_Data_Security_End_to_End_LiveLab.docx)

Start with [RUN_LAB.md](RUN_LAB.md), then follow the eleven pages in the [workshop manifest](workshops/livelabs/manifest.json). Open index.html for a self-contained preview. This custom workshop follows Oracle LiveLabs task structure and the supplied OCI Database Management sample.

## Requirements

- Autonomous Database 26ai, ADMIN access, SQLcl, a downloaded mTLS wallet and the required Select AI sharing APIs.
- OCI administrator access for a database-specific dynamic group and model-scoped Generative AI inference policy.
- A Select AI-compatible, tool-capable OCI model available in the selected region. Set its exact ID, compartment and region in sql/15_select_ai_config.sql. The released working model is xai.grok-4.3; model changes require fresh verification.
- Python 3.15, bash/zsh and a browser. setup.sh retains the corrected binary-wheel installation; Python 3.12 is also supported.

## Run order

1. Configure sql/00_config.sql and complete base database setup: 01/02 as ADMIN, 03/04 as DDS_OWNER.
2. Run SQL employee/manager/outsider checks and preserve the expected baseline.
3. Configure OCI IAM and sql/15_select_ai_config.sql. Run 16 as ADMIN and 17/18 as DDS_OWNER. The original shared-team test in 19 is retained for diagnostics.
4. Install the native cursor bridge: run [22](sql/22_native_cursor_runtime.sql) as ADMIN, [23](sql/23_native_cursor_profile.sql) as DDS_OWNER, then [24](sql/24_native_cursor_team.sql) as ADMIN. The native profile uses the settings in sql/15_select_ai_config.sql (released model `xai.grok-4.3`); verify model availability and the model-scoped IAM policy.
5. Run [25](sql/25_native_cursor_verify.sql) separately as Emma and Marvin. Require `SUCCEEDED` and inspect the returned tool trace.
6. Run the following from the project root; edit an existing config.env rather than replacing it.

```bash
bash setup.sh
source .venv315/bin/activate
cp config.env.example config.env
# Edit wallet connection values and PDB in config.env.
chmod 600 config.env
source config.env
python agent/verify_live.py
python -m streamlit run streamlit_app.py
```

Open http://127.0.0.1:8501. Sign in with each persona's own database password and wallet password. Compare active identity, prompt, actual database tool results and AI response. Sign out before switching users.

| Identity | Visible employee IDs | Count | Salary total |
| --- | --- | --- | --- |
| DDS_EMMA | 400 | 1 | 80000 |
| DDS_MARVIN | 200,400,500 | 3 | 285000 |

Marvin sees his own identifier; report identifiers are NULL. Employee 300 is invisible to both. The AI profile uses OCI$RESOURCE_PRINCIPAL; no OCI API keys, database passwords, wallets or config.env are included in the release.

See [AI_VERIFICATION.md](AI_VERIFICATION.md) and [VALIDATION.md](VALIDATION.md) for the observed native SQL and Chrome results and the limits of the offline checks. Cleanup removes only dedicated lab objects; follow the cleanup lab before deleting the owner. [BUILDING.md](BUILDING.md) explains Word, preview, checksum and ZIP generation.

## Native cursor bridge

Streamlit defaults to `SELECT_AI_EXECUTION=cursor_bridge`. Oracle still performs native `DBMS_CLOUD_AI_AGENT.RUN_TEAM`, model planning, tool selection and final response generation. Python binds the prompt, validates the returned identity/state/tool trace, and displays results. There is no Python tool-planning loop or chat-only compatibility mode. Set `SELECT_AI_EXECUTION=shared_team` only to reproduce the original direct shared-team path.

The invoker-rights entry opens three fixed query cursors (table, view, summary) as the authenticated DDS consumer. DDS filters rows and masks columns at this boundary. A no-authentication runtime schema owns the native agent team and fetch-only tools. It has no employee-table/view SELECT privileges or data roles. Tools accept only optional employee-number/source selection over already authorized rows; prompt text cannot select an identity or supply SQL. Cursors and cached results are scoped to one request and cleared on success or failure. This lab uses small synthetic results; the cursors establish a per-request query snapshot before agent planning.

The runtime owns its conversations and team, so it can check native `GET_TEAM_STATE` and clean up conversations without the shared-consumer ownership error. A response is displayed only after `SUCCEEDED`, a nonblank answer, and a successful identity-matching tool trace.

Remove the runtime with [95_cleanup_native_cursor.sql](sql/95_cleanup_native_cursor.sql) as ADMIN before the original AI/base cleanup.
