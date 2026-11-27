# Run the Autonomous Database 26ai lab

Run all shell commands from the extracted project root. Use SQLcl, not the Python interpreter, for @sql commands. CONNECT prompts for passwords. Replace ADB_LAB with your wallet alias.

1. Download the Autonomous mTLS wallet, keep it outside the repository, and configure SQLcl TNS_ADMIN. Query the actual CON_NAME as ADMIN; edit sql/00_config.sql with it and retain DATA as the tablespace.
2. In SQLcl, run the base setup in this order:

```sql
CONNECT ADMIN@ADB_LAB
@sql/01_preflight.sql
@sql/02_create_principals.sql
CONNECT DDS_OWNER@ADB_LAB
@sql/03_create_sample_data.sql
@sql/04_create_data_grants.sql
CONNECT DDS_EMMA@ADB_LAB
@sql/05_employee_demo.sql
CONNECT DDS_MARVIN@ADB_LAB
@sql/06_manager_demo.sql
CONNECT DDS_OUTSIDER@ADB_LAB
@sql/07_no_data_grant_demo.sql
```

3. Configure the database-specific OCI dynamic group, model-scoped inference policy, region, compartment and model as described in python-agent-setup/python-agent-setup.md. Edit sql/15_select_ai_config.sql, then:

```sql
CONNECT ADMIN@ADB_LAB
@sql/16_select_ai_admin.sql
CONNECT DDS_OWNER@ADB_LAB
@sql/17_select_ai_tools.sql
@sql/18_select_ai_team.sql
CONNECT ADMIN@ADB_LAB
@sql/22_native_cursor_runtime.sql
CONNECT DDS_OWNER@ADB_LAB
@sql/23_native_cursor_profile.sql
CONNECT ADMIN@ADB_LAB
@sql/24_native_cursor_team.sql
CONNECT DDS_EMMA@ADB_LAB
@sql/25_native_cursor_verify.sql
CONNECT DDS_MARVIN@ADB_LAB
@sql/25_native_cursor_verify.sql
```

The native cursor profile reads the same public settings from sql/15_select_ai_config.sql; the released model is `xai.grok-4.3`. Verify its availability and IAM permission in your inference region. Script 19 retains the original direct shared-team path for diagnosis.

4. Install and launch the client:

```bash
bash setup.sh
source .venv315/bin/activate
python -m pip check
cp config.env.example config.env
# Edit config.env; keep passwords out of it. Preserve an existing file.
chmod 600 config.env
source config.env
export SELECT_AI_EXECUTION=cursor_bridge
python -m unittest discover -s tests -v
python agent/verify_live.py
python -m streamlit run streamlit_app.py
```

5. Open http://127.0.0.1:8501. Authenticate as Emma, click Show database results, then run all six sample prompts. Sign out; repeat as Marvin. Compare every answer with its actual RUN_TEAM tool trace. Use AI_VERIFICATION.md to record results.
6. Stop Streamlit with Ctrl+C and close all DDS sessions. Run ADMIN native cursor cleanup 95, then run the owner AI cleanup 97 (including both AI profiles), ADMIN AI cleanup 96, optional delegated cleanup 98 if applicable, base cleanup 99, then verification 14. See cleanup/cleanup.md for exact commands and confirmation strings.

For an existing base lab, retain its data and identities and begin at step 3. No local model service is required. The selected OCI model runs remotely; the database orchestrates tool selection and inference. An invoker-rights entry opens fixed query cursors under DDS before native tools fetch their authorized results. The no-authentication runtime has no employee-table/view privileges or data roles.
