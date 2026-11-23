# Rehearse Reset and Clean Up

## Introduction

Repeat the demonstration or remove the dedicated workshop objects.

Estimated Time: 10 minutes.

### Objectives

- Leave a repeatable demo or remove its dedicated objects.

### Prerequisites

This lab assumes the following are complete:

- Completed main labs
- Optional Lab 7 only if you created its application account

## Task 1: Rehearse the presenter sequence

Use this sequence for a short end user presentation after setup. Show the scenario and scope, run the same broad SQL as Emma and Marvin, point out the hidden team identifiers, show the UI’s active identity, run the fixed database probe, ask the same salary question as each persona, and finish with the out of scope employee 300 prompt. Show raw results before discussing the model’s explanation.

For a repeat session, run Labs 3 through 6 again without rerunning CREATE scripts. End all open transactions first. If someone committed a sample salary or phone edit, close the end user sessions and run:

```sql
<copy>
CONNECT DDS_OWNER@DEMO_PDB
@sql/10_reset_values.sql
@sql/08_verify_baseline.sql
</copy>
```

Expect PASS and the original displayed values. The reset fixes salaries and phones only; it does not repair deleted rows, changed manager relationships, identities, or policy definitions.

## Task 2: Stop the applications and remove the demo

Sign out in Streamlit, press Ctrl+C in its terminal, exit CLI processes, and disconnect end user and owner database sessions. Active end user sessions can prevent account removal. Connect as SYS AS SYSDBA in the target PDB. If you created the optional application user, remove it first:

```sql
<copy>
CONNECT SYS@DEMO_PDB AS SYSDBA
@sql/98_cleanup_agent_app.sql
</copy>
```

Then remove the base lab:

```sql
<copy>
@sql/99_cleanup.sql
</copy>
```

Type REMOVE_DDS_DEMO at the confirmation prompt only when you intend to delete these demo objects. The script drops the three dedicated end users, DDS_OWNER and its objects, the data roles, and the login database role. It does not drop the shared tablespace. DDL removal is not reversible with ROLLBACK.

If you used the optional IAM lab, restore the provider parameters you recorded and remove only the dedicated Entra registrations or secret and lab certificate material that are no longer needed. The SQL cleanup does not restore IAM configuration. Preserve infrastructure that predates this workshop. Keep the project source for future rehearsals and run deactivate to leave the virtual environment.

You have completed the workshop. See Need Help for troubleshooting and additional references.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 22 November 2026
