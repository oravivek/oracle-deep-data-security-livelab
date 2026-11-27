# Configure the Native Select AI Cursor Bridge

## Introduction

Install the working database-only cursor bridge, then connect Python using each authenticated DDS end user. Native Select AI Agent performs model planning, tool calls and response generation. Python binds the prompt and validates the result.

Estimated Time: 40 minutes after OCI permissions are available.

### Objectives

- Preserve DDS row and column enforcement while native RUN_TEAM invokes tools.
- Install a runtime account without authentication, login privileges, employee object privileges or data roles.
- Require native SUCCEEDED state and an identity-matching tool trace.

### Prerequisites

Complete Labs 1 through 3 and retain both SQL baselines. An OCI administrator must be able to authorize inference for this database.

## Task 1: Configure the verified model

Edit sql/15_select_ai_config.sql with the inference region and compartment OCID. The released model is xai.grok-4.3, verified with this lab on 28 November 2026. Confirm availability and permission in your region. A Phoenix database may use another supported inference region according to your network and residency requirements. Use the exact inference model ID documented for your model in target.model.id. Current Oracle model-access documentation uses provider IDs such as xai.grok-4.3; do not substitute an OCID merely because the condition is named model.id.

Script 23 uses these same settings for DDS_NATIVE_OCI_PROFILE. The original DDS_OCI_PROFILE and DDS_HR_TEAM remain available for diagnosis; they are not the default application path.

[Select AI Agent API](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/dbms-cloud-ai-agent-package.html), [Grok 4.3](https://docs.oracle.com/en-us/iaas/Content/generative-ai/xai-grok-4-3.htm)

## Task 2: Configure OCI resource principal permissions

Create a database-specific dynamic group such as DDS_ADB_DG:

```text
<copy>
ALL {resource.type = 'autonomousdatabase', resource.id = 'YOUR_ADB_OCID'}
</copy>
```

Create a model-scoped policy in the appropriate compartment. For this released model, use the explicit ID below and replace the compartment placeholder:

```text
<copy>
Allow dynamic-group DDS_ADB_DG to use generative-ai-chat in compartment YOUR_INFERENCE_COMPARTMENT where target.model.id = 'xai.grok-4.3'
</copy>
```

Allow IAM propagation and verify no broader policy overrides your intended restriction. Inference can incur charges. Prompts and authorized synthetic tool data are sent to OCI Generative AI. Do not use real employee data in this workshop. If outbound ACLs or private routes are required, authorize only the appropriate regional endpoint using your approved configuration.

[Resource principal](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/resource-principal.html), [Model access policies](https://docs.oracle.com/en-us/iaas/Content/generative-ai/limit-model-access.htm)

## Task 3: Prepare the original tools and OCI profile

From the extracted project root, open SQLcl and use the wallet alias for your database. CONNECT prompts for passwords. Configure sql/00_config.sql before running the guarded scripts.

```sql
<copy>
CONNECT ADMIN@ADB_LAB
@sql/16_select_ai_admin.sql
CONNECT DDS_OWNER@ADB_LAB
@sql/17_select_ai_tools.sql
@sql/18_select_ai_team.sql
</copy>
```

For an existing lab where 16 through 18 already succeeded, retain its objects and skip their creation. Do not recreate the base principals or overwrite data grants. Script 19 retains the failing direct shared-team reproduction and is optional, not a required checkpoint for the working bridge.

## Task 4: Install the cursor bridge

For a new bridge installation, run:

```sql
<copy>
CONNECT ADMIN@ADB_LAB
@sql/22_native_cursor_runtime.sql
CONNECT DDS_OWNER@ADB_LAB
@sql/23_native_cursor_profile.sql
CONNECT ADMIN@ADB_LAB
@sql/24_native_cursor_team.sql
</copy>
```

Do not rerun CREATE scripts over an installed runtime. Inspect existing objects after a partial failure; use the named cleanup scripts only if you intend to remove and reinstall the AI extension.

| Object | Purpose |
| --- | --- |
| DDS_AGENT_RUNTIME | NO AUTHENTICATION; no CREATE SESSION, system privileges, roles, data roles or employee-table/view grants |
| RUN_DDS_AGENT | Invoker-rights entry; checks the DDS principal and opens fixed table, view and summary cursors |
| DDS_AGENT_ENGINE | Definer-rights orchestration and session-local cursor/cache/trace scope; no employee SQL in this engine |
| DDS_LIST_TOOL_FN and DDS_SUMMARY_TOOL_FN | Fetch-only native tools; optional employee number and table/view selection over DDS-authorized results |
| DDS_NATIVE_OCI_PROFILE | OCI resource principal, configured model/region/compartment, temperature 0 and max_tokens 8000 |
| DDS_CURSOR_AGENT and DDS_CURSOR_TASK | Read-only tool calling; human tool disabled; no diagnostic persistence flag |
| DDS_CURSOR_TEAM | Native sequential team owned by the runtime, which also owns its conversation and state |

Only RUN_DDS_AGENT is granted to the existing DDS_AI_DB_ROLE for consumers. That database role reaches Emma and Marvin through DDS_EMPLOYEE_ROLE. The application continues to authenticate each end user; it never logs in as the runtime or owner. The model cannot supply an identity, SQL statement or cursor handle.

The SQL executes under DDS before the native runtime fetches its results. No security_level=0 cursor is opened, and no cursor checks are disabled. This bridge uses small, fixed synthetic query snapshots established before planning. It is not an unrestricted natural-language-to-SQL interface. The normal cursor-security behavior is described in [DBMS_SQL](https://docs.oracle.com/en/database/oracle/oracle-database/26/arpls/DBMS_SQL.html).

## Task 5: Verify native completion as both end users

```sql
<copy>
CONNECT DDS_EMMA@ADB_LAB
@sql/25_native_cursor_verify.sql
CONNECT DDS_MARVIN@ADB_LAB
@sql/25_native_cursor_verify.sql
</copy>
```

Require state SUCCEEDED and inspect tool_trace, not just fluent model text. Emma must return employee 400, count 1 and salary total 80000. Marvin must return 200/400/500, count 3 and total 285000; only his own sensitive identifier is visible. Both must return an empty list for employee 300 even when the prompt claims another identity.

The runtime checks GET_TEAM_STATE as the actual team owner. It rejects an empty trace or unfinished run and clears cursors, cached data and the conversation on completion/failure. Error handlers retain the original error before cleanup so a second error cannot replace it with ORA-21002. No manual state override marks a run successful.

ADMIN can run sql/26_native_cursor_history.sql for scoped native history and runtime privilege checks. History has the runtime as team invoker; use the tool result principal to identify the authenticated DDS consumer. Trace data contains synthetic employee values; retain it privately.

## Task 6: Install and configure Python

```bash
<copy>
bash setup.sh
source .venv315/bin/activate
python -m pip check
cp config.env.example config.env
# Edit the wallet alias, PDB and wallet paths. Preserve an existing config.env.
chmod 600 config.env
source config.env
export SELECT_AI_EXECUTION=cursor_bridge
python -m unittest discover -s tests -v
</copy>
```

Keep database and wallet passwords out of config.env and Git. The app prompts for them locally. The corrected Python 3.15 binary-wheel environment requires neither CMake nor a local model; Python 3.12 is also supported. Thin mode requires no Instant Client. For a macOS CA trust issue, use certifi rather than disabling TLS verification:

```bash
<copy>
python -m pip install certifi
export SSL_CERT_FILE="$(python -m certifi)"
</copy>
```

## Task 7: Verify Python access and inference

```bash
<copy>
python agent/agent.py --user DDS_EMMA --probe
python agent/agent.py --user DDS_MARVIN --probe
python agent/verify_live.py
python agent/agent.py --user DDS_EMMA --prompt 'Count my visible employees and total their salaries.'
python agent/agent.py --user DDS_MARVIN --prompt 'Count my visible employees and total their salaries.'
</copy>
```

The probes bypass the LLM and must match Lab 3. The agent calls the fixed RUN_DDS_AGENT function with a bound prompt on a fresh authenticated DDS connection. Python rejects a mismatched principal, unknown tool, empty/oversized trace, unfinished state or blank answer. There is no Python planning loop or chat-only compatibility mode. SELECT_AI_EXECUTION=shared_team explicitly retains the original direct shared-team path for diagnosis; it is not a fallback after errors.

**Checkpoint** Both consumers complete native inference and their tool traces and AI answers match the SQL baseline. Offline tests alone do not establish this checkpoint.

You may now proceed to the next lab.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 28 November 2026
