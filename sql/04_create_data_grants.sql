-- Run as DDS_OWNER. Policy DDL persists independently of demo ROLLBACK.
@@_session.sql
@@_owner.sql
CREATE DATA GRANT DDS_OWNER.EMPLOYEE_SELF AS
  SELECT, UPDATE (phone)
  ON DDS_OWNER.EMPLOYEES
  WHERE login_name = ORA_END_USER_CONTEXT.username
  TO DDS_EMPLOYEE_ROLE;

CREATE DATA GRANT DDS_OWNER.MANAGER_TEAM AS
  SELECT (ALL COLUMNS EXCEPT sensitive_id), UPDATE (salary)
  ON DDS_OWNER.EMPLOYEES
  WHERE manager_login = ORA_END_USER_CONTEXT.username
  TO DDS_MANAGER_ROLE;

-- Intentionally broad SELECT on the VIEW; base-table MAC still applies.
CREATE DATA GRANT DDS_OWNER.EMPLOYEE_VIEW AS
  SELECT ON DDS_OWNER.EMPLOYEES_V
  TO DDS_EMPLOYEE_ROLE;

-- Dynamic SQL sends this database SET command to the server.
BEGIN
  EXECUTE IMMEDIATE
    'SET USE DATA GRANTS ONLY ON DDS_OWNER.EMPLOYEES ENABLED';
END;
/
SELECT DISTINCT grant_name, object_name, grantee,
       use_data_grants_only
FROM user_data_grants ORDER BY grant_name;
-- For EMPLOYEES, USE_DATA_GRANTS_ONLY must be TRUE.
DECLARE
  l_count NUMBER;
BEGIN
  SELECT COUNT(*) INTO l_count FROM user_data_grants
  WHERE object_name = 'EMPLOYEES' AND use_data_grants_only = TRUE;
  IF l_count = 0 THEN
    RAISE_APPLICATION_ERROR(-20007,'Base-table MAC not confirmed');
  END IF;
END;
/
