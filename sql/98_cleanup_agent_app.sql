-- OPTIONAL: remove only the account created by 11_create_agent_app.sql.
-- Run as ADMIN after stopping the delegated CLI and closing its sessions.
@@_session.sql
@@_admin.sql
ACCEPT dds_app_cleanup CHAR PROMPT 'Type REMOVE_DDS_AGENT_APP to delete: '
BEGIN
  IF NVL('&dds_app_cleanup','CANCEL') <> 'REMOVE_DDS_AGENT_APP' THEN
    RAISE_APPLICATION_ERROR(-20009,'Application cleanup cancelled');
  END IF;
END;
/
UNDEFINE dds_app_cleanup
DROP USER IF EXISTS DDS_AGENT_APP;
PROMPT PASS: optional DDS_AGENT_APP removed; IAM settings unchanged.
