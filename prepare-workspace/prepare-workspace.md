# Prepare the Autonomous Database connection

## Introduction

Open the supplied files and establish a wallet-protected ADMIN session in the intended database.

Estimated Time: 10 minutes.

### Objectives

- Configure SQLcl and record the real container name.
- Set the shared SQL target guard.


## Task 1: Open the project and prepare the wallet

```bash
<copy>
cd /path/to/deep-data-security-livelabs
ls sql agent tests streamlit_app.py config.env.example
mkdir -p "$HOME/.oracle-wallets/Wallet_youradb"
chmod 700 "$HOME/.oracle-wallets/Wallet_youradb"
unzip /path/to/Wallet_youradb.zip -d "$HOME/.oracle-wallets/Wallet_youradb"
chmod 600 "$HOME/.oracle-wallets/Wallet_youradb/"*
</copy>
```

Use your actual downloaded wallet and a new destination directory. Keep wallets outside the project and GitHub. The extracted wallet must contain `tnsnames.ora` and `ewallet.pem` for the Python Thin mTLS path. Protect the downloaded ZIP as well. Use OCI's connection instructions if your wallet lacks the PEM file; do not disable TLS checks to work around it.

## Task 2: Connect with SQLcl

Start SQLcl from the project root:

```bash
<copy>
sql /nolog
</copy>
```

Use the original wallet ZIP with SQLcl. Replace the paths and `youradb_high` alias with values from your wallet. `ADB_LAB` in subsequent CONNECT examples means this same actual alias; replace it everywhere.

```sql
<copy>
SET CLOUDCONFIG /absolute/path/to/Wallet_youradb.zip
CONNECT ADMIN@youradb_high
SELECT SYS_CONTEXT('USERENV','SESSION_USER') AS db_user,
       SYS_CONTEXT('USERENV','CON_NAME') AS pdb_name,
       SYS_CONTEXT('USERENV','SERVICE_NAME') AS service_name
FROM dual;
</copy>
```

Enter the ADMIN database password when prompted. The wallet password, when requested by a client, is a separate credential. Every persona uses the same Autonomous Database service and wallet; only its database username and password change.

## Task 3: Set the SQL target guard

Edit `sql/00_config.sql` with the returned container name, not the TNS alias or service:

```sql
<copy>
DEFINE dds_expected_pdb = YOUR_ACTUAL_PDB_NAME
DEFINE dds_tablespace = DATA
</copy>
```

All SQL scripts load this configuration and stop if the target does not match. Keep the full SQL directory together because `@@` resolves helper paths relative to each script.

**Checkpoint** The database user is ADMIN, the container is your Autonomous Database, and the SQL configuration contains its actual name. Leave this SQLcl session open for Lab 2.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 28 November 2026
