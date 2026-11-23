# Prepare the workspace and target PDB

## Introduction

Open the included executable files and confirm the target PDB.

Estimated Time: 10 minutes.

### Objectives

- Create every source file and confirm that the client reaches the intended PDB.

### Prerequisites

This lab assumes the following are complete:

- Getting Started

## Task 1: Open the supplied project

1. Extract the complete workshop archive. Open a terminal in its
   `deep-data-security-livelabs` project root.
2. Confirm the implementation files are present. Substitute your actual
   extraction location for the example path.

```bash
<copy>
cd /path/to/deep-data-security-livelabs
ls sql agent tests streamlit_app.py config.env.example
</copy>
```

3. Use the supplied scripts directly. Keep SQL helpers next to the main scripts;
   do not create a second empty project or copy source from the Word document.

## Task 2: Identify the PDB and edit configuration

In the terminal, start SQL*Plus from the project root:

```bash
<copy>
sqlplus /nolog
</copy>
```

Replace DEMO_PDB in every CONNECT command with your actual PDB TNS alias or Easy Connect service. Passwords will be prompted. For example, the service can be //dbhost:1521/pdb_service.

```sql
<copy>
CONNECT SYS@DEMO_PDB AS SYSDBA
SELECT SYS_CONTEXT('USERENV','CON_NAME') AS pdb_name,
       SYS_CONTEXT('USERENV','SERVICE_NAME') AS service_name
FROM dual;
</copy>
```

Edit sql/00_config.sql. Set dds_expected_pdb to the returned container name, not the alias. Set dds_tablespace to an existing simple unquoted tablespace name. All scripts read this file and reject a wrong PDB or an unchanged placeholder.

```sql
<copy>
DEFINE dds_expected_pdb = YOUR_ACTUAL_PDB_NAME
DEFINE dds_tablespace = USERS
</copy>
```

**Checkpoint** You are connected as SYS AS SYSDBA to the intended PDB, all listings have been saved, and the configuration matches this PDB. A script error can exit SQL*Plus; reconnect before retrying. Helper references use @@ so they resolve relative to the calling file.

You may now proceed to the next lab.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 22 November 2026
