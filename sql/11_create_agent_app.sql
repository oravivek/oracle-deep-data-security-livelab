-- OPTIONAL: only for the delegated/TLS/IAM path, not the direct demo.
-- Run as ADMIN after the baseline SQL kit is configured.
@@_session.sql
@@_admin.sql
SPOOL OFF
ACCEPT dds_app_pwd CHAR PROMPT 'DDS_AGENT_APP lab password: ' HIDE
CREATE USER DDS_AGENT_APP IDENTIFIED BY "&dds_app_pwd";
UNDEFINE dds_app_pwd
GRANT CREATE SESSION, CREATE END USER SECURITY CONTEXT TO DDS_AGENT_APP;
-- No SELECT/UPDATE/object grants and no employee/manager data roles.
