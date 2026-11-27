-- Run as ADMIN before 97_cleanup_select_ai.sql and 96_cleanup_select_ai_admin.sql.
@@_session.sql
@@_admin.sql
ACCEPT native_remove CHAR PROMPT 'Type REMOVE_NATIVE_DDS to remove the native cursor agent: '
BEGIN
 IF NVL('&native_remove','CANCEL')<>'REMOVE_NATIVE_DDS' THEN
  RAISE_APPLICATION_ERROR(-20028,'Native cursor cleanup cancelled');
 END IF;
END;
/
UNDEFINE native_remove
-- Drop framework metadata as its owner before dropping the dedicated schema.
CREATE OR REPLACE PROCEDURE DDS_AGENT_RUNTIME.DDS_REMOVE_NATIVE AUTHID DEFINER AS
BEGIN
 DBMS_CLOUD_AI_AGENT.DROP_TEAM('DDS_CURSOR_TEAM',TRUE);
 DBMS_CLOUD_AI_AGENT.DROP_TASK('DDS_CURSOR_TASK',TRUE);
 DBMS_CLOUD_AI_AGENT.DROP_AGENT('DDS_CURSOR_AGENT',TRUE);
 DBMS_CLOUD_AI_AGENT.DROP_TOOL('DDS_CURSOR_LIST_TOOL',TRUE);
 DBMS_CLOUD_AI_AGENT.DROP_TOOL('DDS_CURSOR_SUMMARY_TOOL',TRUE);
END;
/
BEGIN DDS_AGENT_RUNTIME.DDS_REMOVE_NATIVE; END;
/
DROP USER DDS_AGENT_RUNTIME CASCADE;
-- Continue as DDS_OWNER with 97_cleanup_select_ai.sql to remove both AI profiles.
-- Then run 96_cleanup_select_ai_admin.sql as ADMIN for the AI role/API grants.
