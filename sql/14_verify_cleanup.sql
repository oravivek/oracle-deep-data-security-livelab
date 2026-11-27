-- Read-only post-cleanup check. Run as ADMIN in the same configured database.
@@_session.sql
@@_admin.sql
DECLARE
  l_count NUMBER;
BEGIN
  SELECT SUM(n) INTO l_count FROM (
    SELECT COUNT(*) n FROM dba_users
      WHERE username IN ('DDS_OWNER','DDS_AGENT_APP','DDS_AGENT_RUNTIME')
    UNION ALL
    SELECT COUNT(*) FROM dba_end_users
      WHERE username IN ('DDS_EMMA','DDS_MARVIN','DDS_OUTSIDER')
    UNION ALL
    SELECT COUNT(*) FROM dba_roles
      WHERE role IN ('DDS_LOGIN_DB_ROLE','DDS_AI_DB_ROLE')
    UNION ALL
    SELECT COUNT(*) FROM dba_data_roles
      WHERE data_role IN ('DDS_EMPLOYEE_ROLE','DDS_MANAGER_ROLE',
                          'DDS_LOGIN_ONLY_ROLE')
  );
  IF l_count <> 0 THEN
    RAISE_APPLICATION_ERROR(-20010,'Some dedicated lab objects remain');
  END IF;
  DBMS_OUTPUT.PUT_LINE('PASS: all dedicated lab principals removed');
END;
/
