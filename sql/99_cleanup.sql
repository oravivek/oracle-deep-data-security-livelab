-- DESTRUCTIVE: removes only the dedicated objects named in this kit.
-- Close ALL DDS end-user and DDS_OWNER sessions first.
-- Run as ADMIN in the configured PDB.
@@_session.sql
@@_admin.sql
PROMPT This removes DDS_EMMA, DDS_MARVIN, DDS_OUTSIDER and DDS_OWNER.
PROMPT DDS_OWNER objects and the dedicated DDS roles will be removed.
PROMPT Autonomous Database, DATA tablespace and IAM settings are retained.
ACCEPT dds_cleanup CHAR PROMPT 'Type REMOVE_DDS_DEMO to delete: '
BEGIN
  IF NVL('&dds_cleanup','CANCEL') <> 'REMOVE_DDS_DEMO' THEN
    RAISE_APPLICATION_ERROR(-20009,'Cleanup cancelled');
  END IF;
END;
/
UNDEFINE dds_cleanup
DROP END USER IF EXISTS DDS_EMMA;
DROP END USER IF EXISTS DDS_MARVIN;
DROP END USER IF EXISTS DDS_OUTSIDER;
DROP USER IF EXISTS DDS_OWNER CASCADE;
DROP DATA ROLE IF EXISTS DDS_EMPLOYEE_ROLE;
DROP DATA ROLE IF EXISTS DDS_MANAGER_ROLE;
DROP DATA ROLE IF EXISTS DDS_LOGIN_ONLY_ROLE;
DROP ROLE IF EXISTS DDS_AI_DB_ROLE;
DROP ROLE IF EXISTS DDS_LOGIN_DB_ROLE;
-- No shared tablespace or datafile is dropped.
PROMPT PASS: dedicated DDS lab principals and objects removed.
