-- Connect as ADMIN. Dictionary queries are read-only.
@@_session.sql
@@_admin.sql
SELECT username, account_status, authentication_type
FROM dba_end_users
WHERE username IN ('DDS_EMMA','DDS_MARVIN','DDS_OUTSIDER')
ORDER BY username;
SELECT data_role, role_type, grantee, grantee_type
FROM dba_data_role_grants
WHERE grantee IN ('DDS_EMMA','DDS_MARVIN','DDS_OUTSIDER',
                  'DDS_EMPLOYEE_ROLE','DDS_LOGIN_ONLY_ROLE')
ORDER BY grantee, data_role;
SELECT DISTINCT owner, grant_name, object_name, grantee,
       use_data_grants_only
FROM dba_data_grants WHERE owner = 'DDS_OWNER'
ORDER BY grant_name;
SELECT grantee, privilege FROM dba_sys_privs
WHERE grantee = 'DDS_LOGIN_DB_ROLE';
-- Expected: CREATE SESSION only.
SELECT grantee, table_name, privilege FROM dba_tab_privs
WHERE owner = 'DDS_OWNER';
-- Expected: no ordinary table grants. DDS grants use DBA_DATA_GRANTS.
