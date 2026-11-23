-- OPTIONAL: run before the baseline 99_cleanup.sql, as SYS AS SYSDBA.
-- Close all agent sessions first. IAM/TLS settings are not changed here.
@@_session.sql
@@_admin.sql
DROP USER IF EXISTS DDS_AGENT_APP;
