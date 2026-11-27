-- Read-only runtime-owned history and privilege checks. Run as ADMIN.
@@_session.sql
@@_admin.sql
SET LONG 100000
SET LONGCHUNKSIZE 10000
SET LINESIZE 220
SELECT team_exec_id,team_name,state,team_owner,team_invoker,conversation_id,start_date
FROM dba_ai_agent_team_history WHERE team_owner='DDS_AGENT_RUNTIME'
ORDER BY start_date DESC FETCH FIRST 10 ROWS ONLY;
SELECT t.team_exec_id,t.tool_name,t.input,t.output,t.tool_output
FROM dba_ai_agent_tool_history t
WHERE t.team_exec_id IN (
 SELECT team_exec_id FROM dba_ai_agent_team_history
 WHERE team_owner='DDS_AGENT_RUNTIME' ORDER BY start_date DESC FETCH FIRST 5 ROWS ONLY)
ORDER BY t.start_date,t.invocation_id;
SELECT username,authentication_type FROM dba_users WHERE username='DDS_AGENT_RUNTIME';
SELECT 'system privileges' check_name,COUNT(*) remaining FROM dba_sys_privs WHERE grantee='DDS_AGENT_RUNTIME'
UNION ALL SELECT 'roles',COUNT(*) FROM dba_role_privs WHERE grantee='DDS_AGENT_RUNTIME'
UNION ALL SELECT 'employee object grants',COUNT(*) FROM dba_tab_privs
 WHERE grantee='DDS_AGENT_RUNTIME' AND owner='DDS_OWNER' AND table_name IN ('EMPLOYEES','EMPLOYEES_V');
-- All three privilege counts must be zero. Team invoker is the runtime;
-- the tool result principal identifies the authenticated DDS consumer.
