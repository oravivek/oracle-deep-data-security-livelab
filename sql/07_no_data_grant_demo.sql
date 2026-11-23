-- Connect as DDS_OUTSIDER. Login succeeds but no data is authorized.
@@_session.sql
DEFINE dds_expected_end_user = DDS_OUTSIDER
@@_end_user.sql
PROMPT Negative tests below may return zero rows or authorization errors.
PROMPT No employee values may be returned by either query.
WHENEVER SQLERROR CONTINUE NONE
SELECT employee_id, first_name, salary FROM DDS_OWNER.EMPLOYEES;
SELECT employee_id, first_name, salary FROM DDS_OWNER.EMPLOYEES_V;
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
ROLLBACK;
-- Inspect both results. A connection or syntax error is not proof
-- of policy enforcement. No exact ORA number is assumed here.
