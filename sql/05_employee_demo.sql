-- Connect as DDS_EMMA. Expected: 1 row, employee_id 400.
@@_session.sql
DEFINE dds_expected_end_user = DDS_EMMA
@@_end_user.sql
PROMPT Same broad query will be run as the manager later.
SELECT employee_id, first_name, sensitive_id, salary, phone
FROM DDS_OWNER.EMPLOYEES ORDER BY employee_id;
SELECT COUNT(*) AS unrelated_rows FROM DDS_OWNER.EMPLOYEES
WHERE employee_id = 300;
-- Expected: UNRELATED_ROWS = 0.
SELECT employee_id, first_name, sensitive_id, salary, phone
FROM DDS_OWNER.EMPLOYEES_V ORDER BY employee_id;
-- Expected: same 1 row through the view.

PROMPT Allowed edit: own phone. Expected phone = 555-0499.
UPDATE DDS_OWNER.EMPLOYEES SET phone = '555-0499'
WHERE employee_id = 400;
SELECT employee_id, phone FROM DDS_OWNER.EMPLOYEES;
ROLLBACK;
PROMPT After rollback expected phone = 555-0400.
SELECT employee_id, phone FROM DDS_OWNER.EMPLOYEES;

PROMPT Restricted edit: own salary must stay 80000.
UPDATE DDS_OWNER.EMPLOYEES SET salary = 999999
WHERE employee_id = 400;
SELECT employee_id, salary FROM DDS_OWNER.EMPLOYEES;
ROLLBACK;
-- Unauthorized column update is documented as silently ignored.
-- If your release raises an error, the script exits and rolls back;
-- inspect the error, reconnect, and verify salary as DDS_OWNER.
