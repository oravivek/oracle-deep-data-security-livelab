-- Connect as ADMIN to the Autonomous Database PDB first.
@@_session.sql
@@_admin.sql
SELECT SYS_CONTEXT('USERENV','CON_NAME') AS pdb,
       SYS_CONTEXT('USERENV','SERVICE_NAME') AS service_name
FROM dual;
SELECT banner_full FROM v$version;
SELECT name, value FROM v$parameter WHERE name = 'compatible';
SELECT tablespace_name, status, contents FROM dba_tablespaces
WHERE tablespace_name = UPPER('&&dds_tablespace');
-- These dictionary views must be present.
SELECT COUNT(*) AS existing_end_users FROM dba_end_users;
SELECT COUNT(*) AS existing_data_roles FROM dba_data_roles;
DECLARE
  l_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count FROM dba_tablespaces
  WHERE tablespace_name = UPPER('&&dds_tablespace')
    AND status = 'ONLINE' AND contents = 'PERMANENT';
  IF l_count <> 1 THEN
    RAISE_APPLICATION_ERROR(-20005,'Choose an online data tablespace');
  END IF;
  SELECT SUM(n) INTO l_count FROM (
    SELECT COUNT(*) n FROM dba_users
      WHERE username IN ('DDS_OWNER','DDS_EMMA','DDS_MARVIN',
                         'DDS_OUTSIDER')
    UNION ALL
    SELECT COUNT(*) FROM dba_end_users
      WHERE username IN ('DDS_OWNER','DDS_EMMA','DDS_MARVIN',
                         'DDS_OUTSIDER')
    UNION ALL
    SELECT COUNT(*) FROM dba_roles
      WHERE role IN ('DDS_LOGIN_DB_ROLE','DDS_EMPLOYEE_ROLE',
                     'DDS_MANAGER_ROLE','DDS_LOGIN_ONLY_ROLE','DDS_AI_DB_ROLE')
    UNION ALL
    SELECT COUNT(*) FROM dba_data_roles
      WHERE data_role IN ('DDS_LOGIN_DB_ROLE','DDS_EMPLOYEE_ROLE',
                          'DDS_MANAGER_ROLE','DDS_LOGIN_ONLY_ROLE','DDS_AI_DB_ROLE')
  );
  IF l_count <> 0 THEN
    RAISE_APPLICATION_ERROR(-20006,'Demo names exist; review first');
  END IF;
  DBMS_OUTPUT.PUT_LINE('PASS: target, tablespace and names checked');
END;
/
