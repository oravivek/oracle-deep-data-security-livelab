-- Run separately as DDS_EMMA and DDS_MARVIN; no owner/admin execution.
@@_session.sql
ACCEPT dds_expected_end_user CHAR PROMPT 'Expected DDS_EMMA or DDS_MARVIN: '
@@_end_user.sql
SET LONG 100000
SELECT JSON_VALUE(ORA_END_USER_CONTEXT,'$.USERNAME') active_end_user FROM dual;
EXEC DDS_OWNER.DDS_AI_TOOLS.reset_trace;
SELECT DDS_OWNER.DDS_LIST_EMPLOYEES(NULL,'table') AS tool_result FROM dual;
SELECT DDS_OWNER.DDS_SALARY_SUMMARY() AS summary FROM dual;
-- Expected Emma IDs [400], count 1, total 80000.
-- Expected Marvin IDs [200,400,500], count 3, total 285000;
-- Emma/Taylor sensitive identifiers NULL for Marvin.
VARIABLE answer CLOB
VARIABLE actual_tools CLOB
DECLARE
  c VARCHAR2(128);
  params CLOB;
  state VARCHAR2(100);
BEGIN
  DDS_OWNER.DDS_AI_TOOLS.reset_trace;
  c := DBMS_CLOUD_AI.CREATE_CONVERSATION();
  params := JSON_OBJECT('conversation_id' VALUE c RETURNING CLOB);
  BEGIN
    :answer := DBMS_CLOUD_AI_AGENT.RUN_TEAM(
      team_name => 'DDS_OWNER.DDS_HR_TEAM',
      user_prompt => 'Count my visible employees and total their salaries.',
      params => params);
    state := DBMS_CLOUD_AI_AGENT.GET_TEAM_STATE('DDS_OWNER.DDS_HR_TEAM',params);
    :actual_tools := DDS_OWNER.DDS_AI_TOOLS.get_trace();
    IF state <> 'SUCCEEDED' THEN
      RAISE_APPLICATION_ERROR(-20027,'Agent did not succeed');
    END IF;
    DBMS_CLOUD_AI.DROP_CONVERSATION(c,TRUE);
  EXCEPTION WHEN OTHERS THEN
    DBMS_CLOUD_AI.DROP_CONVERSATION(c,TRUE);
    RAISE;
  END;
END;
/
PRINT actual_tools
PRINT answer
-- Compare actual trace and answer. Wording varies; values must match above.
