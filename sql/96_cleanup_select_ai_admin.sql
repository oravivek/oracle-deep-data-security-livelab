-- Run as ADMIN after 97; retains the base DDS data and identities.
@@_session.sql
@@_admin.sql
ACCEPT dds_ai_admin_remove CHAR PROMPT 'Type REMOVE_DDS_AI to revoke the AI extension: '
BEGIN
  IF NVL('&dds_ai_admin_remove','CANCEL') <> 'REMOVE_DDS_AI' THEN
    RAISE_APPLICATION_ERROR(-20028,'AI cleanup cancelled');
  END IF;
END;
/
UNDEFINE dds_ai_admin_remove
BEGIN
  DBMS_CLOUD_ADMIN.DISABLE_RESOURCE_PRINCIPAL(username => 'DDS_OWNER');
END;
/
REVOKE EXECUTE ON DBMS_CLOUD_AI FROM DDS_OWNER;
REVOKE EXECUTE ON DBMS_CLOUD_AI_AGENT FROM DDS_OWNER;
REVOKE CREATE PROCEDURE FROM DDS_OWNER;
DROP ROLE IF EXISTS DDS_AI_DB_ROLE;
-- Do not disable the database-wide ADMIN resource principal or delete shared IAM.
