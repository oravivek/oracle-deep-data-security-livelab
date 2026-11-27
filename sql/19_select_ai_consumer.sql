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
  failure_stack VARCHAR2(32767);
BEGIN
  DDS_OWNER.DDS_AI_TOOLS.reset_trace;
  c := DBMS_CLOUD_AI.CREATE_CONVERSATION();
  SELECT JSON_OBJECT('conversation_id' VALUE c RETURNING CLOB) INTO params FROM dual;
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
  EXCEPTION WHEN OTHERS THEN
    -- Save before cleanup can clear Oracle's active exception stack.
    failure_stack := DBMS_UTILITY.FORMAT_ERROR_STACK;
    DBMS_OUTPUT.PUT_LINE('ORIGINAL_FAILURE: '||failure_stack);
    DBMS_OUTPUT.PUT_LINE(DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    DBMS_OUTPUT.PUT_LINE('CONVERSATION_ID: '||c);
    BEGIN
      DBMS_OUTPUT.PUT_LINE('CURRENT_TOOL_TRACE: '||
        DBMS_LOB.SUBSTR(DDS_OWNER.DDS_AI_TOOLS.get_trace(),30000,1));
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('TRACE_READ_FAILED: '||SQLERRM);
    END;
    BEGIN
      DBMS_CLOUD_AI.DROP_CONVERSATION(c,TRUE);
    EXCEPTION WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('CLEANUP_FAILED (original error retained): '||SQLERRM);
    END;
    -- A bare RAISE here can produce ORA-21002 after failed cleanup.
    RAISE_APPLICATION_ERROR(-20028,SUBSTR(failure_stack,1,450),FALSE);
  END;
  DBMS_CLOUD_AI.DROP_CONVERSATION(c,TRUE);
END;
/
PRINT actual_tools
PRINT answer
-- Compare actual trace and answer. Wording varies; values must match above.
