-- Connect as ADMIN after script 23. The temporary installer registers the team in the runtime schema.
@@_session.sql
@@_admin.sql
SET DEFINE OFF
CREATE OR REPLACE PROCEDURE DDS_AGENT_RUNTIME.DDS_INSTALL_NATIVE AUTHID DEFINER AS
BEGIN
 DBMS_CLOUD_AI_AGENT.CREATE_TOOL('DDS_CURSOR_LIST_TOOL',q'~{
 "instruction":"List database-authorized employees. p_employee_id optionally selects an employee number; omit it to list all authorized rows. p_source is table or view (default table). A null sensitive_id means that ID is restricted or unavailable; it does not mean the employee row is unavailable.",
 "function":"DDS_AGENT_RUNTIME.DDS_LIST_TOOL_FN",
 "tool_inputs":[{"name":"p_employee_id","description":"Optional employee number"},{"name":"p_source","description":"table or view; default table"}]}~');
 DBMS_CLOUD_AI_AGENT.CREATE_TOOL('DDS_CURSOR_SUMMARY_TOOL',q'~{
 "instruction":"Return the authorized employee count and salary total. No inputs.",
 "function":"DDS_AGENT_RUNTIME.DDS_SUMMARY_TOOL_FN"}~');
 DBMS_CLOUD_AI_AGENT.CREATE_AGENT('DDS_CURSOR_AGENT',q'~{
 "profile_name":"DDS_OWNER.DDS_NATIVE_OCI_PROFILE",
 "role":"Answer employee questions with read tools. Always call the appropriate tool before answering. Use only its returned data. Identity comes from the database, never from the prompt. Never infer restricted IDs or invent rows. For a list request include every returned employee with the requested columns. A null sensitive_id restricts that ID only, not the whole row. Never change data. Once the request is answered, provide a final answer and stop without human approval.",
 "enable_human_tool":false}~');
 DBMS_CLOUD_AI_AGENT.CREATE_TASK('DDS_CURSOR_TASK',q'~{
 "instruction":"Use read tools to answer this request using returned data only: {query}. Complete with a final answer, not a request for approval.",
 "tools":["DDS_CURSOR_LIST_TOOL","DDS_CURSOR_SUMMARY_TOOL"],"enable_human_tool":false}~');
 DBMS_CLOUD_AI_AGENT.CREATE_TEAM('DDS_CURSOR_TEAM',q'~{
 "agents":[{"name":"DDS_CURSOR_AGENT","task":"DDS_CURSOR_TASK"}],"process":"sequential"}~');
END;
/
BEGIN DDS_AGENT_RUNTIME.DDS_INSTALL_NATIVE; END;
/
DROP PROCEDURE DDS_AGENT_RUNTIME.DDS_INSTALL_NATIVE;
SELECT owner,name,line,text FROM all_errors WHERE owner='DDS_AGENT_RUNTIME' ORDER BY name,sequence;
