# Rehearse reset and clean up Autonomous Database

## Introduction

Reset the synthetic values for another presentation or remove only the dedicated lab objects using ADMIN.

Estimated Time: 10 minutes.

### Objectives

- Rehearse without recreating principals.
- Remove dedicated objects and verify their absence.


## Task 1: Rehearse or reset the baseline

For another demonstration, repeat Labs 3 through 6 without rerunning CREATE scripts. Demo updates end in ROLLBACK. If someone committed a synthetic salary or phone change, close end-user sessions, connect as the owner and run:

```sql
<copy>
CONNECT DDS_OWNER@ADB_LAB
@sql/10_reset_values.sql
@sql/08_verify_baseline.sql
</copy>
```

Expect original values and `BASELINE_CHECK = PASS`. This reset changes salaries and phones only; it does not repair deleted rows, relationships or policies. Use your actual wallet service alias in place of `ADB_LAB`.

## Task 2: Close application and database sessions

Sign out of Streamlit, stop its server with Ctrl+C, exit the CLI agent and disconnect DDS_OWNER and all end-user SQL sessions. Active sessions may prevent end-user deletion; close them rather than granting broader privileges.

## Task 3: Remove the Select AI extension

Close the app and all DDS sessions. Remove the cursor runtime before the original AI extension:

```sql
<copy>
CONNECT ADMIN@ADB_LAB
@sql/95_cleanup_native_cursor.sql
CONNECT DDS_OWNER@ADB_LAB
@sql/97_cleanup_select_ai.sql
CONNECT ADMIN@ADB_LAB
@sql/96_cleanup_select_ai_admin.sql
</copy>
```

Script 95 requires REMOVE_NATIVE_DDS; it removes the native team, task, agent, tools and no-authentication runtime schema. Scripts 97 and 96 each require REMOVE_DDS_AI. Script 97 also removes DDS_NATIVE_OCI_PROFILE and removes the named team, task, agent, tools, AI profile and supporting functions/package. Script 96 removes the owner resource-principal access, AI execution grants and dedicated AI role. It keeps the ADMIN resource principal and any shared OCI IAM configuration. Run these before the base owner is dropped. For AI-only removal, stop here and retain the base DDS demo.

Inspect framework run history and conversation retention using your service documentation before removing the owner. The native runtime drops each request conversation and clears cursor/cache scope; this does not certify that every framework audit/history record is purged. Do not delete all cloud operations in a shared database.

After full lab removal, the OCI administrator can remove the dedicated DDS_ADB_DG policy and dynamic group only if created exclusively for this lab. No API key or dedicated AI cluster is created by these scripts.

## Task 4: Remove the optional application account

Only if Lab 7 created DDS_AGENT_APP, reconnect as ADMIN using SQLcl and the same wallet. For a new SQLcl process, repeat `SET CLOUDCONFIG` from Lab 1 first.

```sql
<copy>
CONNECT ADMIN@ADB_LAB
@sql/98_cleanup_agent_app.sql
</copy>
```

Type `REMOVE_DDS_AGENT_APP` to confirm. This script removes only that dedicated account. It does not disable or reconfigure any identity provider.

## Task 5: Remove and verify the base lab

```sql
<copy>
CONNECT ADMIN@ADB_LAB
@sql/99_cleanup.sql
@sql/14_verify_cleanup.sql
</copy>
```

Type `REMOVE_DDS_DEMO` only when you intend to delete DDS_EMMA, DDS_MARVIN, DDS_OUTSIDER, DDS_OWNER and all its objects, the three data roles and the login database role. DDL deletion cannot be undone with ROLLBACK. The scripts first enforce ADMIN and the configured container name.

Expected: `PASS: dedicated DDS lab principals and objects removed.` followed by `PASS: all dedicated lab principals removed`. The verifier also checks that DDS_AGENT_RUNTIME, DDS_AI_DB_ROLE and the optional DDS_AGENT_APP are absent. If an error occurs, stop and inspect it; do not treat partial cleanup as success.

Autonomous Database, its DATA tablespace, backups, network configuration and shared IAM configuration are retained. This workshop does not terminate the database. If the optional IAM extension changed provider settings, have its administrator restore the recorded configuration through the documented Autonomous API. Remove only lab-specific Entra registrations and secrets that are no longer needed.

## Task 6: Retain or remove local files

Keep the source and ZIP for future rehearsals. Run `deactivate` to leave the Python environment. Wallet files, downloaded wallet ZIPs and private credentials remain outside the distributed lab; remove your local copies only when no longer needed. Upload only the sanitized source package to GitHub.

**Checkpoint** The cleanup verifier passes, or the lab is deliberately retained with its baseline verified for another session.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 28 November 2026
