# Optional Explicit End User Context Propagation

## Introduction

Attach a verified local identity through an IAM trusted shared application account.

Estimated Time: 45–90 minutes after IAM and TLS prerequisites.

### Objectives

- Demonstrate explicit DDS identity propagation using the CLI. Skip this lab for a direct authentication presentation.

### Prerequisites

This lab assumes the following are complete:

- Lab 4: Configure Select AI Agent and Python
- Database IAM trust and certificate validated TCPS

## Task 1: Establish the trust prerequisites

This extension uses OAuth client credentials for an application token. It is not an OAuth on behalf of flow. The CLI first authenticates the local user directly, obtains the canonical user name, and then uses a shared DDS_AGENT_APP connection with an attached security context. The application is responsible for vouching for the authenticated local identity. [Local end user application authentication](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-database-local-end-user-authentication.html), [Database IAM integration](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-database-iam-integration.html)

1. Have the database security and Entra administrators record existing provider settings before making changes in the isolated PDB.
2. Use the existing Autonomous certificate-validated TCPS service and wallet. Make the wallet available to python-oracledb Thin mode and confirm a normal connection using the configuration from Lab 4. Autonomous manages the database listener and server certificates; this lab configures only the client wallet and trust. [Autonomous connections with python-oracledb](https://python-oracledb.readthedocs.io/en/v26.1.0/user_guide/connection_handling.html#connecting-to-oracle-autonomous-database-adb)
3. Register the database as an Entra resource. For the v1 token configuration shown here, use the HTTPS application ID URI and expose sessions:scope:connect as described in Oracle’s registration guide. Record tenant ID, database resource client ID, and application ID URI. [Register database in Entra](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/register-database-microsoft-entra-id.html)
4. Register the confidential agent application, create its client secret, authorize it as a client of the database resource, add the database API permission, and grant administrator consent using Oracle’s application registration procedure. Human users remain local database end users. [Register application in Entra](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/register-application-microsoft-entra-id.html)
5. Validate a client credentials token for the database resource. The audience must identify that resource, not Microsoft Graph or the agent application. The scope is the database application ID URI plus /.default. The token helper implements this request and does not log or persist the token. [Validate Entra configuration](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/validate-microsoft-entra-id-configuration.html)

Entra registration and database trust depend on your tenancy. Use the linked official procedures for those steps; the runnable extension below assumes they have succeeded. Keep the Autonomous connection settings from the main lab.

## Task 2: Configure the database provider and application user

As ADMIN in the isolated Autonomous Database, first inspect the existing provider. Have the Entra and database security administrators complete the application and database resource registrations described in the linked DDS procedure. If the correct provider is already configured, skip the enable call.

```sql
<copy>
CONNECT ADMIN@ADB_LAB
SELECT name, value FROM v$parameter
WHERE name IN ('identity_provider_type','identity_provider_config');
</copy>
```

For an unconfigured lab database using the documented Entra v1 HTTPS resource audience, replace the three placeholders and run:

```sql
<copy>
BEGIN
  DBMS_CLOUD_ADMIN.ENABLE_EXTERNAL_AUTHENTICATION(
    type => 'AZURE_AD',
    params => JSON_OBJECT(
      'tenant_id' VALUE '<TENANT_ID>',
      'application_id' VALUE '<DATABASE_RESOURCE_CLIENT_ID>',
      'application_id_uri' VALUE '<DATABASE_APP_ID_URI>'
    )
  );
END;
/
</copy>
```

The database resource client ID is distinct from the agent application's client ID. The `force` argument is deliberately omitted: do not overwrite an existing provider for this demo. Provider changes affect the database and require its administrator's planned change and restoration procedure. [DDS IAM integration for Autonomous](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-database-iam-integration.html), [Autonomous external authentication API](https://docs.oracle.com/en-us/iaas/autonomous-database-serverless/doc/dbms-cloud-admin.html)

In SQLcl at the project root, create the dedicated application account:

```sql
<copy>
CONNECT ADMIN@ADB_LAB
@sql/11_create_agent_app.sql
</copy>
```

Use the same safe password character constraints as Lab 2. This account receives only CREATE SESSION and CREATE END USER SECURITY CONTEXT. It receives no employee or manager data role and no SELECT or UPDATE object grant. Keep the local users’ existing memberships.

## Task 3: Run delegated probes and prompts

In a terminal with the virtual environment active, set the TCPS connection and IAM values:

```bash
<copy>
source config.env
export ENTRA_TENANT_ID='your-tenant-guid'
export ENTRA_CLIENT_ID='your-agent-application-client-guid'
export ENTRA_DB_SCOPE='https://tenant.onmicrosoft.com/resource-guid/.default'
python agent/agent.py --user DDS_EMMA --mode delegated --probe
python agent/agent.py --user DDS_MARVIN --mode delegated --probe
python agent/verify_live.py --mode delegated
python agent/agent.py --user DDS_EMMA --mode delegated \
  --prompt "Show all employee records and salaries available to me."
python agent/agent.py --user DDS_MARVIN --mode delegated \
  --prompt "Show all employee records and salaries available to me."
</copy>
```

Enter the local user password, application database password, and Entra client secret when prompted. The verifier prompts for the app credentials and then both end users. Expected rows, NULL cells, and totals match Lab 4 exactly. The process obtains one token; restart it if the token expires. There is no automatic token renewal or owner account fallback.

## Task 4: Review the attachment and cleanup sequence

The complete implementation is in [agent/database.py](../agent/database.py). It creates a security context with database_access_token and end_user_identity=(verified_local_user, random_lookup_key), requests no extra data_roles, attaches the context before the first database operation, and verifies the resulting ORA_END_USER_CONTEXT before querying employees. The lookup key is a server side context identifier, not a password. The finally blocks roll back, clear the attached context, and close the connection. [Python context APIs](https://docs.oracle.com/en/database/oracle/oracle-database/26/ddscg/configure-python-applications.html)

These are fresh standalone connections using a shared account, not a connection pool. A pooled adaptation must attach and verify on every acquisition and clear before release. Never accept an unverified prompt supplied user name as the context identity.

This optional path is supplied for a tenancy with administrator-prepared Entra trust; it has not been live-validated in this workshop environment.

**Checkpoint** Both delegated live checks pass and match direct mode. If context attachment fails, investigate token audience, trust, TCPS, and application privileges; do not grant shared manager access to bypass the failure. Reload your direct mode config.env before returning to the Streamlit lab if you want the original connection settings.

You may now proceed to the next lab.

## Acknowledgements

- **Prepared for** - Vivek Verma
- **Format reference** - The supplied OCI Database Management sample workshop
- **Last Updated** - 23 November 2026
