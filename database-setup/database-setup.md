# Build the Database Security Model

## Introduction

Create the dedicated principals as ADMIN, then create the synthetic data, view and data grants as DDS_OWNER in Autonomous Database.

Estimated Time: 20 minutes.

### Objectives

- Create the principals, sample rows, view, and policies.

### Prerequisites

This lab assumes the following are complete:

- Lab 1: Prepare the Workspace

## Task 1: Run the preflight and create principals

From the ADMIN SQLcl session at the project root, run the following once on a fresh lab:

```sql
<copy>
@sql/01_preflight.sql
@sql/02_create_principals.sql
</copy>
```

Preflight must report the expected PDB, a supported database banner, an ONLINE PERMANENT tablespace, and PASS for target, tablespace, and names. Inspect COMPATIBLE separately; it is not the RU number. The script displays it but does not upgrade or change it. Use the Autonomous 26ai release with DDS available; do not change COMPATIBLE in this workshop. Existing demo names stop setup; inspect them before rebuilding.

Enter four distinct passwords meeting the database profile. The SQL substitution prompts support letters, digits, underscore, and # only; begin with a letter and use at least 16 mixed case characters. Do not use &, quotes, whitespace, or shell supplied passwords in these prompts. Echo, verification, and spooling are disabled for entry.

| Principal or role | Type | Purpose or membership |
| --- | --- | --- |
| DDS_OWNER | Database user | Owns the table, view, and data grants |
| DDS_EMMA | Local end user | DDS_EMPLOYEE_ROLE |
| DDS_MARVIN | Local end user | DDS_EMPLOYEE_ROLE and DDS_MANAGER_ROLE |
| DDS_OUTSIDER | Local end user | DDS_LOGIN_ONLY_ROLE only |
| DDS_LOGIN_DB_ROLE | Database role | CREATE SESSION only |
| DDS_EMPLOYEE_ROLE | Data role | Receives login role and self and view data grants |
| DDS_MANAGER_ROLE | Data role | Receives the team data grant |
| DDS_LOGIN_ONLY_ROLE | Data role | Receives login role and no employee data grant |

End users use CREATE END USER, not CREATE USER. The conventional login role is granted to data roles, then GRANT DATA ROLE assigns them to end users. Do not add ordinary object privileges to the login role. Chris and Taylor are data rows; they need no login accounts. [Create end users](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/create-end-user.html), [Grant database roles to data roles](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/grant-database-role-data-role.html)

The compatibility files `12_autonomous_preflight.sql` and `13_autonomous_create_principals.sql` call these same scripts. Do not run both pairs. If the demo objects already exist, skip creation and verify the baseline instead.

## Task 2: Create the data and view

```sql
<copy>
CONNECT DDS_OWNER@ADB_LAB
@sql/03_create_sample_data.sql
</copy>
```

Expect four rows matching the scenario table and phone numbers 555-0200, 555-0300, 555-0400, and 555-0500. The schema contains EMPLOYEES and a broad EMPLOYEES_V view over the same columns.

## Task 3: Create the data grants and mandatory enforcement

```sql
<copy>
@sql/04_create_data_grants.sql
</copy>
```

| Grant | Row predicate | Allowed operations |
| --- | --- | --- |
| EMPLOYEE_SELF | login_name equals authenticated end user | SELECT all columns and UPDATE phone |
| MANAGER_TEAM | manager_login equals authenticated end user | SELECT except sensitive_id and UPDATE salary |
| EMPLOYEE_VIEW | Broad access to EMPLOYEES_V | SELECT with underlying table enforcement |

The script enables SET USE DATA GRANTS ONLY on the base table through dynamic SQL so the SQL client sends the statement to the database. It then checks USER_DATA_GRANTS. USE_DATA_GRANTS_ONLY must be TRUE for EMPLOYEES. This protects the base table when accessed through the broad view in this demo. These rules govern DDS end users; the ordinary owner and administrator retain their conventional database access. [Create data grants](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/create-data-grants.html), [Mandatory data privileges](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/enforce-mandatory-data-privileges.html)

**Checkpoint** Three data grants exist, mandatory base table enforcement is confirmed, and no unexpected setup errors occurred. Do not demonstrate restrictions using the schema owner or ADMIN.

## Task 4: Review the complete setup scripts

The files are included and executable without copying code from this page:

- [Preflight](../sql/01_preflight.sql)
- [Users and roles](../sql/02_create_principals.sql)
- [Sample employee data and view](../sql/03_create_sample_data.sql)
- [Data grants and mandatory enforcement](../sql/04_create_data_grants.sql)

Read the policy definitions before presenting. Use the same files in every path.


You may now proceed to the next lab.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 23 November 2026
