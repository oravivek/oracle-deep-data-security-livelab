-- Run once as ADMIN after 12_autonomous_preflight.sql.
-- Creates dedicated DDS_OWNER, DDS_EMMA, DDS_MARVIN, DDS_OUTSIDER
-- and four roles, with a 10 MB DATA quota; no existing objects replaced.
@@_session.sql
@@_autonomous_admin.sql
SPOOL OFF
PROMPT Enter distinct lab passwords meeting the database profile.
PROMPT For these substitution prompts, use letters/digits/_/# only.
PROMPT Start with a letter; use at least 16 mixed-case characters.
ACCEPT dds_owner_pwd CHAR PROMPT 'DDS_OWNER password: ' HIDE
ACCEPT dds_emma_pwd CHAR PROMPT 'DDS_EMMA password: ' HIDE
ACCEPT dds_marvin_pwd CHAR PROMPT 'DDS_MARVIN password: ' HIDE
ACCEPT dds_outsider_pwd CHAR PROMPT 'DDS_OUTSIDER password: ' HIDE

CREATE USER DDS_OWNER IDENTIFIED BY "&dds_owner_pwd"
  DEFAULT TABLESPACE &&dds_tablespace
  QUOTA 10M ON &&dds_tablespace;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW TO DDS_OWNER;
GRANT CREATE DATA GRANT TO DDS_OWNER;
GRANT SET USE DATA GRANTS ONLY TO DDS_OWNER;

CREATE END USER DDS_EMMA IDENTIFIED BY "&dds_emma_pwd";
CREATE END USER DDS_MARVIN IDENTIFIED BY "&dds_marvin_pwd";
CREATE END USER DDS_OUTSIDER IDENTIFIED BY "&dds_outsider_pwd";
UNDEFINE dds_owner_pwd
UNDEFINE dds_emma_pwd
UNDEFINE dds_marvin_pwd
UNDEFINE dds_outsider_pwd

CREATE ROLE DDS_LOGIN_DB_ROLE;
GRANT CREATE SESSION TO DDS_LOGIN_DB_ROLE;
CREATE DATA ROLE DDS_EMPLOYEE_ROLE;
CREATE DATA ROLE DDS_MANAGER_ROLE;
CREATE DATA ROLE DDS_LOGIN_ONLY_ROLE;
GRANT DDS_LOGIN_DB_ROLE TO DDS_EMPLOYEE_ROLE;
GRANT DDS_LOGIN_DB_ROLE TO DDS_LOGIN_ONLY_ROLE;
GRANT DATA ROLE DDS_EMPLOYEE_ROLE TO DDS_EMMA;
GRANT DATA ROLE DDS_EMPLOYEE_ROLE, DDS_MANAGER_ROLE TO DDS_MARVIN;
GRANT DATA ROLE DDS_LOGIN_ONLY_ROLE TO DDS_OUTSIDER;
PROMPT Principals created. Do not grant table privileges to login role.
