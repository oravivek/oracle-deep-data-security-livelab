-- Optional recovery if someone committed an edit. Run as DDS_OWNER.
-- Close all end-user sessions first to avoid row locks.
@@_session.sql
@@_owner.sql
UPDATE DDS_OWNER.EMPLOYEES SET salary = 120000, phone = '555-0200'
WHERE employee_id = 200;
UPDATE DDS_OWNER.EMPLOYEES SET salary = 95000, phone = '555-0300'
WHERE employee_id = 300;
UPDATE DDS_OWNER.EMPLOYEES SET salary = 80000, phone = '555-0400'
WHERE employee_id = 400;
UPDATE DDS_OWNER.EMPLOYEES SET salary = 85000, phone = '555-0500'
WHERE employee_id = 500;
COMMIT;
@@08_verify_baseline.sql
