# Configure Select AI Agent and the Python Client

## Introduction

Create an OCI-backed agent in Autonomous Database, then connect the Python client using each authenticated DDS end user.

Estimated Time: 35 minutes after OCI permissions are available.

### Objectives

- Configure OCI inference, a shared AI profile, two invoker-rights tools and a sequential agent team.
- Verify database tools independently of AI responses.

### Prerequisites

- Complete Labs 1 through 3 and retain the successful Emma and Marvin SQL baselines.
- An OCI administrator can configure a dynamic group and policy for this Autonomous Database.

## Task 1: Choose OCI inference settings

In OCI Console, open Generative AI in your chosen region. Select a currently available chat model that supports tool/function calling and is supported by Select AI Agent. Record its exact model ID, region and inference compartment OCID. Availability changes by region; a database in Phoenix can use a supported inference region subject to your network and residency requirements. Do not assume every model supports tools.

Edit `sql/15_select_ai_config.sql` with those three public settings. All CHANGE_ME values must be replaced. This file controls the real model; Python has no model weights or OCI SDK credentials. For an example identifier, `meta.llama-3.3-70b-instruct` appears in Oracle's profile examples; confirm current availability and tool support before choosing it. The lab intentionally has no implicit model default.

[Select AI Agent package](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/dbms-cloud-ai-agent-package.html), [OCI model availability](https://docs.oracle.com/en-us/iaas/Content/generative-ai/pretrained-models.htm)

## Task 2: Configure OCI resource-principal permissions

Create a dedicated dynamic group, for example DDS_ADB_DG, with a rule restricted to this database's resource OCID:

```text
<copy>
ALL {resource.type = 'autonomousdatabase', resource.id = 'YOUR_ADB_OCID'}
</copy>
```

Create a policy in a compartment where your OCI administrator can authorize the inference compartment. Replace the names and model ID:

```text
<copy>
Allow dynamic-group DDS_ADB_DG to use generative-ai-chat in compartment YOUR_INFERENCE_COMPARTMENT where target.model.id = 'YOUR_APPROVED_MODEL_ID'
</copy>
```

Allow time for IAM propagation. Verify no broader policy defeats the intended model restriction. Inference consumes OCI resources and can incur charges. Prompts and authorized synthetic tool data are sent from the database to the configured OCI Generative AI service. Keep real employee data out of this demonstration.

The database administrator enables the database resource principal in script 16, grants access to DDS_OWNER, and gives the AI consumer role the corresponding credential privilege. Team/profile sharing alone does not grant credential access. The role reaches Emma and Marvin through DDS_EMPLOYEE_ROLE; it grants no extra employee rows or columns.

If your Autonomous outbound network configuration requires a host ACL or private endpoint route, allow the selected regional inference HTTPS endpoint for DDS_OWNER and DDS_AI_DB_ROLE using your approved network configuration. Do not open all hosts to solve a connection error.

[Resource-principal setup](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/resource-principal.html), [Model-level IAM policies](https://docs.oracle.com/en-us/iaas/Content/generative-ai/limit-model-access.htm)

## Task 3: Create database tools and the shared team

From the project root, open SQLcl without a password on its command line:

```bash
<copy>
sql /nolog
</copy>
```

In SQLcl, run the following. Replace ADB_LAB with your wallet alias; CONNECT prompts for the password. The existing `sql/00_config.sql` must contain the correct PDB guard.

```sql
<copy>
CONNECT ADMIN@ADB_LAB
@sql/16_select_ai_admin.sql
CONNECT DDS_OWNER@ADB_LAB
@sql/17_select_ai_tools.sql
@sql/18_select_ai_team.sql
</copy>
```

Script 16 first checks the required API surface, then creates DDS_AI_DB_ROLE, grants package execution through the employee data role, and prepares resource-principal access. It does not grant DML or broader employee data access. Scripts 17 and 18 create:

| Object | Purpose |
| --- | --- |
| DDS_OWNER.DDS_AI_TOOLS | Session-local trace and fixed employee SELECTs; AUTHID CURRENT_USER |
| DDS_LIST_EMPLOYEES / DDS_SALARY_SUMMARY | Invoker-rights standalone functions registered as tools |
| DDS_OCI_PROFILE | OCI provider, resource principal, region, compartment, model, temperature 0 |
| DDS_LIST_TOOL / DDS_SUMMARY_TOOL | Only two custom read tools; no arbitrary SQL tool |
| DDS_HR_AGENT / DDS_HR_TASK / DDS_HR_TEAM | Single worker, sequential task, human interaction disabled |

All custom functions use invoker rights. The owner stores definitions; the caller supplies the security context. The shared team runs in the initiating consumer session. No owner or ADMIN login is used by the application. GRANT_PROFILE_ACCESS and GRANT_TEAM_ACCESS target DDS_AI_DB_ROLE, which is granted to DDS_EMPLOYEE_ROLE. DDS_OUTSIDER receives neither AI role access nor data grants.

The API preflight deliberately fails if profile/team sharing or GET_TEAM_STATE is missing. Request an Autonomous service update or support guidance; do not switch tools to definer rights. Oracle's maintained Python client confirms the profile-sharing parameter names used here: [Profile.grant_access source](https://github.com/oracle/python-select-ai/blob/main/src/select_ai/profile.py).

The AI setup is a one-time extension of the base lab. For an existing installation, retain scripts 01 through 04 and run only 16 through 19. For a partial AI setup, inspect the failing object and remove the extension with scripts 97 and 96 before retrying. Do not rerun principal creation over existing identities.

## Task 4: Verify the same PL/SQL tools as each consumer

```sql
<copy>
CONNECT DDS_EMMA@ADB_LAB
@sql/19_select_ai_consumer.sql
CONNECT DDS_MARVIN@ADB_LAB
@sql/19_select_ai_consumer.sql
</copy>
```

The first two function calls require no LLM. The final RUN_TEAM call performs real OCI inference and prints its actual session tool trace and answer. Expected Emma summary: count 1, total 80000. Expected Marvin summary: count 3, total 285000. If the direct functions differ from Lab 3, stop and inspect data grants and invoker rights before any inference demonstration.

## Task 5: Install Python and configure the connection

```bash
<copy>
bash setup.sh
source .venv315/bin/activate
python -m pip check
cp config.env.example config.env
# Edit config.env with your actual wallet alias, PDB and absolute wallet paths.
chmod 600 config.env
source config.env
python -m unittest discover -s tests -v
</copy>
```

If config.env already exists, edit it rather than overwriting it. Remove any former local-model setting. The corrected Python 3.15 binary-wheel environment is retained; no CMake or local model installation is required. Optional Python 3.12 support uses `.venv` instead. Thin mode requires no Instant Client. The app prompts for the wallet password and the selected user's database password; neither belongs in config.env or Git.

If macOS Python needs a trusted CA bundle, install certifi and set SSL_CERT_FILE without disabling verification:

```bash
<copy>
python -m pip install certifi
export SSL_CERT_FILE="$(python -m certifi)"
</copy>
```

Offline tests use mocks and do not certify OCI inference or DDS enforcement.

## Task 6: Verify real Python access

```bash
<copy>
python agent/agent.py --user DDS_EMMA --probe
python agent/agent.py --user DDS_MARVIN --probe
python agent/verify_live.py
python agent/agent.py --user DDS_EMMA --prompt 'Count my visible employees and total their salaries.'
python agent/agent.py --user DDS_MARVIN --prompt 'Count my visible employees and total their salaries.'
</copy>
```

The probes must match the SQL baseline before running AI. Inference prints TOOL_RESULT records from the PL/SQL functions actually invoked by RUN_TEAM. Every prompt gets a new conversation and fresh authenticated connection. The client rejects an empty trace, a different principal, an unknown tool, too many tools, a non-SUCCEEDED state or an empty answer. It drops its conversation after the request. Framework run history is separate from the displayed trace; review database retention and access before adapting this synthetic lab to other data.

**Checkpoint** Both consumer SQL runs, both Python probes and both OCI-backed prompts complete with matching results. Do not treat an offline test pass as this checkpoint.

You may now proceed to the next lab.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 23 November 2026
