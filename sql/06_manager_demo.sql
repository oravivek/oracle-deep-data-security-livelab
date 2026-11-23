-- Connect as DDS_MARVIN. Expected IDs 200,400,500; never 300.
@@_session.sql
DEFINE dds_expected_end_user = DDS_MARVIN
@@_end_user.sql
SELECT employee_id, first_name, sensitive_id, salary, phone
FROM DDS_OWNER.EMPLOYEES ORDER BY employee_id;
-- Own ID visible. Emma and Taylor IDs are NULL.
SELECT employee_id, first_name,
       CASE WHEN ORA_IS_COLUMN_AUTHORIZED(sensitive_id)
            THEN sensitive_id ELSE 'Restricted' END AS id_display,
       ORA_CHECK_DATA_PRIVILEGE(e,'UPDATE',phone) AS edit_phone,
       ORA_CHECK_DATA_PRIVILEGE(e,'UPDATE',salary) AS edit_salary
FROM DDS_OWNER.EMPLOYEES e ORDER BY employee_id;
SELECT employee_id, first_name, sensitive_id, salary, phone
FROM DDS_OWNER.EMPLOYEES_V ORDER BY employee_id;
-- Expected same 3 rows and same hidden cells via the view.

PROMPT Allowed edit: Emma salary becomes 81000 in this session.
UPDATE DDS_OWNER.EMPLOYEES SET salary = 81000
WHERE employee_id = 400;
SELECT employee_id, salary FROM DDS_OWNER.EMPLOYEES
WHERE employee_id = 400;
ROLLBACK;

PROMPT Restricted edit: Emma phone must stay 555-0400.
UPDATE DDS_OWNER.EMPLOYEES SET phone = '555-9999'
WHERE employee_id = 400;
SELECT employee_id, phone FROM DDS_OWNER.EMPLOYEES
WHERE employee_id = 400;
ROLLBACK;

PROMPT Out of scope edit: Chris is outside the team.
UPDATE DDS_OWNER.EMPLOYEES SET salary = 1 WHERE employee_id = 300;
SELECT COUNT(*) AS unrelated_rows FROM DDS_OWNER.EMPLOYEES
WHERE employee_id = 300;
-- Expected: unrelated_rows = 0; owner verifies salary 95000 later.
ROLLBACK;
