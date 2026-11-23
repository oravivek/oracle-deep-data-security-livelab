-- Connect as DDS_OWNER after closing or rolling back end-user sessions.
@@_session.sql
@@_owner.sql
SELECT employee_id, first_name, sensitive_id, salary, phone
FROM DDS_OWNER.EMPLOYEES ORDER BY employee_id;
SELECT CASE WHEN COUNT(*) = 4 AND SUM(
  CASE
    WHEN employee_id = 200 AND salary = 120000 AND phone = '555-0200'
      THEN 1
    WHEN employee_id = 300 AND salary = 95000 AND phone = '555-0300'
      THEN 1
    WHEN employee_id = 400 AND salary = 80000 AND phone = '555-0400'
      THEN 1
    WHEN employee_id = 500 AND salary = 85000 AND phone = '555-0500'
      THEN 1
    ELSE 0 END) = 4 THEN 'PASS' ELSE 'FAIL' END AS baseline_check
FROM DDS_OWNER.EMPLOYEES;
-- Expected BASELINE_CHECK = PASS.
