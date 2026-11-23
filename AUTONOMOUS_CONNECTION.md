# Autonomous Database connection reference

This lab targets Oracle Autonomous Database 26ai with Deep Data Security available.
The main path uses password-authenticated DDS end users over mTLS. Setup and
cleanup use ADMIN. Application tools never connect as ADMIN or DDS_OWNER.

1. Download the instance wallet from OCI Database Connection and keep it outside
   the project. Prepare SQLcl with `SET CLOUDCONFIG /absolute/path/to/Wallet_youradb.zip`.
2. Connect as `ADMIN@youradb_high`, letting SQLcl prompt for the database password.
   Query `SYS_CONTEXT('USERENV','CON_NAME')` and set `sql/00_config.sql` accordingly.
3. Run `01_preflight.sql` and `02_create_principals.sql` once. Then run
   `03_create_sample_data.sql` and `04_create_data_grants.sql` as DDS_OWNER.
4. Copy `config.env.example` to `config.env`, set the TNS alias, container name,
   and extracted wallet paths. Source the file before launching Python.
5. The Python mTLS path reads `tnsnames.ora` and `ewallet.pem`. Enter the wallet
   password and each database password at prompts or in Streamlit, never in chat.

The compatibility entry points 12 and 13 call canonical scripts 01 and 02. Do
not execute both pairs. Existing configured demo objects must not be recreated.

| Persona | Visible employee IDs | Salary total | Identifier access |
| --- | --- | --- | --- |
| Emma | 400 | 80000 | Own identifier visible |
| Marvin | 200, 400, 500 | 285000 | Own visible; team identifiers NULL |

The fixed table and view probes must agree on rows and sensitive values.
Employee 300 must yield no matching authorized record for both users.
On the tested Autonomous release, manager team identifiers remain NULL through
the view even though its `id_authorized` flag can be true. The base-table flag
is the primary diagnostic; do not infer visibility from the view flag alone.

Run `python agent/verify_live.py` before presenting. See `VALIDATION.md` for what
was actually exercised, versus expected results and unexecuted optional paths.
