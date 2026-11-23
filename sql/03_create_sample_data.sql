-- Connect as DDS_OWNER, not SYS.
@@_session.sql
@@_owner.sql
CREATE TABLE DDS_OWNER.EMPLOYEES (
  employee_id   NUMBER(6) PRIMARY KEY,
  first_name    VARCHAR2(30) NOT NULL,
  login_name    VARCHAR2(128) NOT NULL UNIQUE,
  manager_login VARCHAR2(128),
  sensitive_id  VARCHAR2(20) NOT NULL,
  salary        NUMBER(10,2) NOT NULL,
  phone         VARCHAR2(20)
);
-- Synthetic identifiers deliberately do not resemble real SSNs.
INSERT INTO DDS_OWNER.EMPLOYEES VALUES
  (200,'Marvin','DDS_MARVIN',NULL,'ID-DEMO-0200',120000,'555-0200');
INSERT INTO DDS_OWNER.EMPLOYEES VALUES
  (300,'Chris','DDS_CHRIS',NULL,'ID-DEMO-0300',95000,'555-0300');
INSERT INTO DDS_OWNER.EMPLOYEES VALUES
  (400,'Emma','DDS_EMMA','DDS_MARVIN','ID-DEMO-0400',80000,'555-0400');
INSERT INTO DDS_OWNER.EMPLOYEES VALUES
  (500,'Taylor','DDS_TAYLOR','DDS_MARVIN','ID-DEMO-0500',85000,
   '555-0500');
COMMIT;
CREATE VIEW DDS_OWNER.EMPLOYEES_V AS
  SELECT employee_id, first_name, login_name, manager_login,
         sensitive_id, salary, phone
  FROM DDS_OWNER.EMPLOYEES;
SELECT employee_id, first_name, sensitive_id, salary, phone
FROM DDS_OWNER.EMPLOYEES ORDER BY employee_id;
-- Expected owner baseline: 4 rows; all identifiers populated.
