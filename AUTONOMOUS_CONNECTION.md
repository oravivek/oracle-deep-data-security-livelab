# Autonomous Database connection

The local `config.env` is configured for the supplied Autonomous Database high
service over TCPS on port 1522. The database-reported PDB name is
`G4FD273CE522B7B_AIADB`. The saved `json_app` administrator connection uses the
same database's low service and was used for setup and inspection.

The existing PEM wallet directory is referenced by ORACLE_WALLET_LOCATION and
ORACLE_CONFIG_DIR. Its private key is encrypted, so each Streamlit sign-in asks
for the existing wallet password in addition to the selected end user's password.
Passwords are not stored in `config.env`. SSL server name verification stays on;
SSL_CERT_FILE points to the installed certifi CA bundle. Connection retries are
bounded for the interactive demo.

## Start the configured app

From this project root:

```bash
source .venv315/bin/activate
source config.env
python -m streamlit run streamlit_app.py
```

Open http://127.0.0.1:8501. Select Emma or Marvin, enter that user's database
password and the wallet password, and click Sign in. Then click Show database
results to test Oracle independently of the model.

The generated demo passwords are in `.local/demo-credentials.json`, readable
only by the local account. The `.local` directory is ignored by Git and excluded
from the workshop's distribution checksums. The wallet password is not in that
file and is entered only in the sign-in form. Sign-out clears credentials and
the displayed data for the browser session.

## Database objects initialized

Setup created DDS_OWNER with a 10 MB DATA quota, local end users DDS_EMMA,
DDS_MARVIN, and DDS_OUTSIDER, the conventional DDS_LOGIN_DB_ROLE, and the three
data roles DDS_EMPLOYEE_ROLE, DDS_MANAGER_ROLE, and DDS_LOGIN_ONLY_ROLE.

DDS_OWNER owns EMPLOYEES, EMPLOYEES_V, four synthetic rows, and the three data
grants EMPLOYEE_SELF, MANAGER_TEAM, and EMPLOYEE_VIEW. Mandatory data-grant
enforcement is enabled on EMPLOYEES. No administrator credentials are used by
the Streamlit app; its tools authenticate as the selected end user.

For a fresh Autonomous Database, use `sql/12_autonomous_preflight.sql` and
`sql/13_autonomous_create_principals.sql` as ADMIN, followed by the existing
sample-data and data-grant scripts as DDS_OWNER. These replace the original
SYS-based bootstrap for Autonomous Database. Setup is already complete on the
configured target; do not rerun the creation scripts against it.

## Expected live probe results

| Persona | Visible employee IDs | Salary total | Sensitive identifiers |
| --- | --- | --- | --- |
| Emma | 400 | 80000 | Own identifier visible |
| Marvin | 200, 400, 500 | 285000 | Own visible; team identifiers NULL |

The table and view must agree. Employee 300 must return no matching authorized
record for both personas. The fixed database probe does not invoke Ollama.

## Observed verification

Live sign-in and the fixed Streamlit database probe passed for DDS_EMMA and
DDS_MARVIN against the configured high service. The base table and view each
returned the expected employee IDs and sensitive values; the unrelated employee
300 lookup was empty, and totals were 80000 and 285000 respectively.
The manager base-table authorization flags were false for team identifiers.
On this release the view returns those identifiers as NULL while its column
authorization flag is true, so the base-table flag is the primary diagnostic.
The AI model was not invoked during this connection verification.
