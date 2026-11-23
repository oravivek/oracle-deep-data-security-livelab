-- Run as ADMIN after the base DDS lab (01 through 04).
@@_session.sql
@@_admin.sql
-- Fail before granting anything if the required API surface is unavailable.
DECLARE
  n NUMBER;
BEGIN
  FOR p IN (
    SELECT 'DBMS_CLOUD_AI_AGENT' pkg, 'RUN_TEAM' sub FROM dual UNION ALL
    SELECT 'DBMS_CLOUD_AI_AGENT','GRANT_TEAM_ACCESS' FROM dual UNION ALL
    SELECT 'DBMS_CLOUD_AI_AGENT','GET_TEAM_STATE' FROM dual UNION ALL
    SELECT 'DBMS_CLOUD_AI','GRANT_PROFILE_ACCESS' FROM dual UNION ALL
    SELECT 'DBMS_CLOUD_AI','CREATE_CONVERSATION' FROM dual)
  LOOP
    SELECT COUNT(*) INTO n FROM all_procedures
    WHERE owner = 'C##CLOUD$SERVICE' AND object_name = p.pkg
      AND procedure_name = p.sub;
    IF n = 0 THEN
      RAISE_APPLICATION_ERROR(-20020,'Required API missing: '||p.pkg||'.'||p.sub);
    END IF;
  END LOOP;
END;
/
CREATE ROLE DDS_AI_DB_ROLE;
GRANT CREATE PROCEDURE TO DDS_OWNER;
GRANT EXECUTE ON DBMS_CLOUD_AI TO DDS_OWNER;
GRANT EXECUTE ON DBMS_CLOUD_AI_AGENT TO DDS_OWNER;
GRANT EXECUTE ON DBMS_CLOUD_AI TO DDS_AI_DB_ROLE;
GRANT EXECUTE ON DBMS_CLOUD_AI_AGENT TO DDS_AI_DB_ROLE;
-- Database roles reach end users through a data role, never directly.
GRANT DDS_AI_DB_ROLE TO DDS_EMPLOYEE_ROLE;
-- First configure the OCI dynamic group and inference policy in Lab 4.
BEGIN
  DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL();
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE <> -20031 THEN RAISE; END IF;
END;
/
BEGIN
  DBMS_CLOUD_ADMIN.ENABLE_RESOURCE_PRINCIPAL(username => 'DDS_OWNER');
EXCEPTION WHEN OTHERS THEN
  IF SQLCODE <> -20031 THEN RAISE; END IF;
END;
/
-- Share the actual privilege created by ENABLE_RESOURCE_PRINCIPAL, through
-- the consumer role. Do not guess a credential privilege or grant to PUBLIC.
DECLARE
  n PLS_INTEGER := 0;
BEGIN
  FOR p IN (SELECT owner,table_name,privilege FROM dba_tab_privs
            WHERE grantee = 'DDS_OWNER'
              AND table_name = 'OCI$RESOURCE_PRINCIPAL'
              AND owner = 'ADMIN')
  LOOP
    IF p.privilege NOT IN ('READ','EXECUTE') THEN
      RAISE_APPLICATION_ERROR(-20029,'Unexpected resource-principal privilege');
    END IF;
    EXECUTE IMMEDIATE 'GRANT '||p.privilege||' ON '||
      DBMS_ASSERT.ENQUOTE_NAME(p.owner,FALSE)||'.'||
      DBMS_ASSERT.ENQUOTE_NAME(p.table_name,FALSE)||' TO DDS_AI_DB_ROLE';
    n := n + 1;
  END LOOP;
  IF n = 0 THEN
    RAISE_APPLICATION_ERROR(-20030,'Resource-principal grant not found; inspect DBA_TAB_PRIVS');
  END IF;
END;
/
PROMPT PASS: owner and consumer role prepared. Continue as DDS_OWNER.
