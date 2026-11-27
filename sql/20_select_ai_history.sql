-- Read-only diagnostics: run as DDS_OWNER on the database that failed.
-- Do not run an agent as DDS_OWNER to test employee authorization.
@@_session.sql
@@_owner.sql
SET LONG 100000
SET LONGCHUNKSIZE 10000
PROMPT Recent runs for the dedicated DDS team
SELECT * FROM user_ai_agent_team_history
WHERE team_name IN ('DDS_HR_TEAM','DDS_OWNER.DDS_HR_TEAM')
ORDER BY start_date DESC FETCH FIRST 5 ROWS ONLY;
PROMPT Task results for the dedicated DDS team
SELECT * FROM user_ai_agent_task_history
WHERE team_name IN ('DDS_HR_TEAM','DDS_OWNER.DDS_HR_TEAM')
ORDER BY start_date DESC FETCH FIRST 10 ROWS ONLY;
PROMPT Tool errors and returned data for the most recent DDS runs
SELECT * FROM user_ai_agent_tool_history
WHERE team_exec_id IN (
  SELECT team_exec_id FROM user_ai_agent_team_history
  WHERE team_name IN ('DDS_HR_TEAM','DDS_OWNER.DDS_HR_TEAM')
  ORDER BY start_date DESC FETCH FIRST 5 ROWS ONLY)
ORDER BY start_date DESC FETCH FIRST 20 ROWS ONLY;
-- Review locally. History can contain prompts and authorized synthetic data.
-- Do not grant these history views to end users or publish raw history to GitHub.
