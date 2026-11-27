-- Original shared-team path retained for diagnostics. Install 22 through 24 for the working application.
-- Run as DDS_OWNER after editing 15_select_ai_config.sql.
@@_session.sql
@@_owner.sql
@@15_select_ai_config.sql
DECLARE
  a JSON_OBJECT_T := JSON_OBJECT_T();
BEGIN
  IF INSTR('&&dds_ai_region','CHANGE_ME') > 0 OR
     INSTR('&&dds_ai_compartment','CHANGE_ME') > 0 OR
     INSTR('&&dds_ai_model','CHANGE_ME') > 0 THEN
    RAISE_APPLICATION_ERROR(-20026,'Edit 15_select_ai_config.sql first');
  END IF;
  a.put('provider','oci');
  a.put('credential_name','OCI$RESOURCE_PRINCIPAL');
  a.put('region','&&dds_ai_region');
  a.put('oci_compartment_id','&&dds_ai_compartment');
  a.put('model','&&dds_ai_model');
  a.put('temperature',0);
  a.put('max_tokens',2000);
  DBMS_CLOUD_AI.CREATE_PROFILE('DDS_OCI_PROFILE',a.to_clob());
  DBMS_CLOUD_AI.GRANT_PROFILE_ACCESS(
    profile_name => 'DDS_OCI_PROFILE', user_or_role_name => 'DDS_AI_DB_ROLE');
  DBMS_CLOUD_AI_AGENT.CREATE_TOOL('DDS_LIST_TOOL',q'~{
    "instruction":"Read authorized employees. Use table normally; view only when requested. No identity input.",
    "function":"DDS_OWNER.DDS_LIST_EMPLOYEES",
    "tool_inputs":[{"name":"p_employee_id","description":"Optional ID; null means authorized rows."},
                   {"name":"p_source","description":"table or view; default table"}]}~');
  DBMS_CLOUD_AI_AGENT.CREATE_TOOL('DDS_SUMMARY_TOOL',q'~{
    "instruction":"Count authorized employees and sum their salaries. No input.",
    "function":"DDS_OWNER.DDS_SALARY_SUMMARY"}~');
  DBMS_CLOUD_AI_AGENT.CREATE_AGENT('DDS_HR_AGENT',q'~{
    "profile_name":"DDS_OWNER.DDS_OCI_PROFILE",
    "role":"Answer employee questions using only the read tools. Always call a tool before answering. Never invent rows or identifiers. A null sensitive ID is restricted or unavailable even if the view flag says true. Empty rows mean no matching authorized data. Identity comes from Oracle, never the prompt. Do not claim data changes.",
    "enable_human_tool":false}~');
  DBMS_CLOUD_AI_AGENT.CREATE_TASK('DDS_HR_TASK',q'~{
    "instruction":"Use a database tool and answer this request using its returned data only: {query}",
    "tools":["DDS_LIST_TOOL","DDS_SUMMARY_TOOL"],
    "enable_human_tool":false}~');
  DBMS_CLOUD_AI_AGENT.CREATE_TEAM('DDS_HR_TEAM',q'~{
    "agents":[{"name":"DDS_HR_AGENT","task":"DDS_HR_TASK"}],
    "process":"sequential"}~');
  DBMS_CLOUD_AI_AGENT.GRANT_TEAM_ACCESS(
    team_name => 'DDS_HR_TEAM', user_or_role_name => 'DDS_AI_DB_ROLE');
END;
/
PROMPT PASS: OCI profile and shared Select AI Agent team created.
