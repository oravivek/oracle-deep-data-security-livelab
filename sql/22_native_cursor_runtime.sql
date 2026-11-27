-- Connect as ADMIN. Dedicated runtime: no authentication, CREATE SESSION, data role, or table/view SELECT.
@@_session.sql
@@_admin.sql
SET DEFINE OFF
CREATE USER DDS_AGENT_RUNTIME NO AUTHENTICATION;
GRANT EXECUTE ON DBMS_CLOUD_AI_AGENT TO DDS_AGENT_RUNTIME;
GRANT EXECUTE ON DBMS_CLOUD_AI TO DDS_AGENT_RUNTIME;
GRANT EXECUTE ON ADMIN.OCI$RESOURCE_PRINCIPAL TO DDS_AGENT_RUNTIME;
CREATE OR REPLACE PACKAGE DDS_AGENT_RUNTIME.DDS_AGENT_ENGINE AUTHID DEFINER AS
  FUNCTION run_agent(p_prompt CLOB,p_table INTEGER,p_view INTEGER,p_summary INTEGER) RETURN CLOB;
  FUNCTION list_employees(p_employee_id NUMBER DEFAULT NULL,p_source VARCHAR2 DEFAULT 'table') RETURN CLOB;
  FUNCTION salary_summary RETURN CLOB;
END;
/

CREATE OR REPLACE PACKAGE BODY DDS_AGENT_RUNTIME.DDS_AGENT_ENGINE AS
  g_table INTEGER; g_view INTEGER; g_summary INTEGER;
  g_table_json CLOB; g_view_json CLOB; g_summary_json CLOB;
  g_principal VARCHAR2(128); g_active BOOLEAN:=FALSE;
  g_trace JSON_ARRAY_T; g_calls PLS_INTEGER:=0;
  FUNCTION principal RETURN VARCHAR2 IS u VARCHAR2(128); BEGIN
    SELECT JSON_VALUE(ORA_END_USER_CONTEXT,'$.USERNAME') INTO u FROM dual;
    IF u IS NULL OR u NOT IN ('DDS_EMMA','DDS_MARVIN') OR SYS_CONTEXT('USERENV','ISDBA')<>'FALSE' THEN
      RAISE_APPLICATION_ERROR(-20081,'Authenticated DDS consumer required');
    END IF;
    RETURN u;
  END;
  PROCEDURE guard IS BEGIN
    IF NOT g_active THEN RAISE_APPLICATION_ERROR(-20082,'No active DDS cursor scope');END IF;
    IF principal()<>g_principal THEN RAISE_APPLICATION_ERROR(-20082,'DDS identity changed');END IF;
    g_calls:=g_calls+1;
    IF g_calls>8 THEN RAISE_APPLICATION_ERROR(-20083,'Tool call limit exceeded');END IF;
  END;
  PROCEDURE record_result(n VARCHAR2,v CLOB) IS o JSON_OBJECT_T:=JSON_OBJECT_T(); BEGIN
    o.put('tool',n);o.put('result',JSON_OBJECT_T.parse(v));g_trace.append(o);
  END;
  FUNCTION fetch_json(c IN OUT INTEGER) RETURN CLOB IS v CLOB; BEGIN
    IF DBMS_SQL.FETCH_ROWS(c)>0 THEN DBMS_SQL.COLUMN_VALUE(c,1,v);END IF;
    DBMS_SQL.CLOSE_CURSOR(c);
    IF v IS NULL THEN RAISE_APPLICATION_ERROR(-20085,'Missing authorized cursor result');END IF;
    RETURN v;
  END;
  FUNCTION list_employees(p_employee_id NUMBER DEFAULT NULL,p_source VARCHAR2 DEFAULT 'table') RETURN CLOB IS
    o JSON_OBJECT_T; rows_in JSON_ARRAY_T; rows_out JSON_ARRAY_T:=JSON_ARRAY_T();
    item JSON_OBJECT_T; src VARCHAR2(10):=LOWER(p_source);v CLOB;
  BEGIN
    guard;
    IF src IS NULL OR src NOT IN ('table','view') OR
       (p_employee_id IS NOT NULL AND (p_employee_id<=0 OR p_employee_id<>TRUNC(p_employee_id))) THEN
      RAISE_APPLICATION_ERROR(-20085,'Invalid read-tool arguments');
    END IF;
    IF src='table' THEN
      IF g_table_json IS NULL THEN g_table_json:=fetch_json(g_table);END IF;
      o:=JSON_OBJECT_T.parse(g_table_json);
    ELSE
      IF g_view_json IS NULL THEN g_view_json:=fetch_json(g_view);END IF;
      o:=JSON_OBJECT_T.parse(g_view_json);
    END IF;
    -- Optional employee-number selection operates only on rows already authorized by DDS.
    IF p_employee_id IS NOT NULL THEN
      rows_in:=o.get_array('rows');
      IF rows_in.get_size()>0 THEN
        FOR i IN 0..rows_in.get_size()-1 LOOP
          item:=TREAT(rows_in.get(i) AS JSON_OBJECT_T);
          IF item.get_number('employee_id')=p_employee_id THEN rows_out.append(item);END IF;
        END LOOP;
      END IF;
      o.put('rows',rows_out);
    END IF;
    v:=o.to_clob();record_result('list_employees',v);RETURN v;
  END;
  FUNCTION salary_summary RETURN CLOB IS BEGIN
    guard;
    IF g_summary_json IS NULL THEN g_summary_json:=fetch_json(g_summary);END IF;
    record_result('salary_summary',g_summary_json);RETURN g_summary_json;
  END;
  PROCEDURE close_cursor(c IN OUT INTEGER) IS BEGIN
    IF c IS NOT NULL AND DBMS_SQL.IS_OPEN(c) THEN DBMS_SQL.CLOSE_CURSOR(c);END IF;
    c:=NULL;
  END;
  PROCEDURE clear_scope IS BEGIN
    close_cursor(g_table);close_cursor(g_view);close_cursor(g_summary);
    g_active:=FALSE;g_table_json:=NULL;g_view_json:=NULL;g_summary_json:=NULL;
    g_principal:=NULL;g_trace:=NULL;g_calls:=0;
  END;
  FUNCTION run_agent(p_prompt CLOB,p_table INTEGER,p_view INTEGER,p_summary INTEGER) RETURN CLOB IS
    c VARCHAR2(128);p CLOB;a CLOB;s VARCHAR2(128);o JSON_OBJECT_T:=JSON_OBJECT_T();
    started BOOLEAN:=FALSE; saved_error VARCHAR2(32767); saved_code NUMBER;
  BEGIN
    IF g_active THEN RAISE_APPLICATION_ERROR(-20084,'Nested run refused');END IF;
    IF p_prompt IS NULL OR DBMS_LOB.GETLENGTH(p_prompt)>4000 THEN
      RAISE_APPLICATION_ERROR(-20085,'Prompt must contain 1 to 4000 characters');END IF;
    g_principal:=principal();g_table:=p_table;g_view:=p_view;g_summary:=p_summary;
    g_trace:=JSON_ARRAY_T();g_calls:=0;g_active:=TRUE;started:=TRUE;
    c:=DBMS_CLOUD_AI.CREATE_CONVERSATION();
    SELECT JSON_OBJECT('conversation_id' VALUE c RETURNING CLOB) INTO p FROM dual;
    a:=DBMS_CLOUD_AI_AGENT.RUN_TEAM('DDS_CURSOR_TEAM',p_prompt,p);
    s:=DBMS_CLOUD_AI_AGENT.GET_TEAM_STATE('DDS_CURSOR_TEAM',p);
    IF s<>'SUCCEEDED' OR s IS NULL OR a IS NULL OR g_trace.get_size()=0 THEN
      RAISE_APPLICATION_ERROR(-20086,'Native agent did not complete with a successful DDS tool call');
    END IF;
    o.put('principal',g_principal);o.put('conversation_id',c);o.put('state',s);
    o.put('answer',a);o.put('tool_trace',g_trace);
    DBMS_CLOUD_AI.DROP_CONVERSATION(c);
    clear_scope;RETURN o.to_clob();
  EXCEPTION WHEN OTHERS THEN
    saved_code:=SQLCODE;
    saved_error:=DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
    IF started THEN
      BEGIN clear_scope;EXCEPTION WHEN OTHERS THEN NULL;END;
      IF c IS NOT NULL THEN BEGIN DBMS_CLOUD_AI.DROP_CONVERSATION(c);EXCEPTION WHEN OTHERS THEN NULL;END;END IF;
    END IF;
    RAISE_APPLICATION_ERROR(-20087,SUBSTRB('Native DDS agent failed ('||saved_code||'): '||saved_error,1,1800),TRUE);
  END;
END;
/

CREATE OR REPLACE FUNCTION DDS_AGENT_RUNTIME.RUN_DDS_AGENT(p_prompt CLOB) RETURN CLOB AUTHID CURRENT_USER AS
  r SYS_REFCURSOR;vcur SYS_REFCURSOR;s SYS_REFCURSOR;
  n INTEGER;m INTEGER;k INTEGER;u VARCHAR2(128);v CLOB;
  saved_error VARCHAR2(32767);saved_code NUMBER;
  PROCEDURE close_number(c IN OUT INTEGER) IS BEGIN
    IF c IS NOT NULL AND DBMS_SQL.IS_OPEN(c) THEN DBMS_SQL.CLOSE_CURSOR(c);END IF;
  EXCEPTION WHEN OTHERS THEN NULL;END;
BEGIN
  SELECT JSON_VALUE(ORA_END_USER_CONTEXT,'$.USERNAME') INTO u FROM dual;
  IF u IS NULL OR u NOT IN ('DDS_EMMA','DDS_MARVIN') THEN
    RAISE_APPLICATION_ERROR(-20081,'Authenticated DDS consumer required');END IF;
  -- Fixed SQL opens and executes with the authenticated consumer's privileges.
  -- The runtime schema has no SELECT privilege on either source.
  OPEN r FOR q'~SELECT JSON_OBJECT(
    'principal' VALUE JSON_VALUE(ORA_END_USER_CONTEXT,'$.USERNAME'),'source' VALUE 'table',
    'rows' VALUE COALESCE(JSON_ARRAYAGG(JSON_OBJECT(
      'employee_id' VALUE employee_id,'first_name' VALUE first_name,
      'sensitive_id' VALUE sensitive_id,'salary' VALUE salary,'phone' VALUE phone,
      'id_authorized' VALUE CASE WHEN ORA_IS_COLUMN_AUTHORIZED(sensitive_id)
        THEN 'true' ELSE 'false' END FORMAT JSON RETURNING CLOB)
      ORDER BY employee_id RETURNING CLOB),TO_CLOB('[]')) FORMAT JSON RETURNING CLOB)
    FROM DDS_OWNER.EMPLOYEES~';
  OPEN vcur FOR q'~SELECT JSON_OBJECT(
    'principal' VALUE JSON_VALUE(ORA_END_USER_CONTEXT,'$.USERNAME'),'source' VALUE 'view',
    'rows' VALUE COALESCE(JSON_ARRAYAGG(JSON_OBJECT(
      'employee_id' VALUE employee_id,'first_name' VALUE first_name,
      'sensitive_id' VALUE sensitive_id,'salary' VALUE salary,'phone' VALUE phone,
      'id_authorized' VALUE CASE WHEN ORA_IS_COLUMN_AUTHORIZED(sensitive_id)
        THEN 'true' ELSE 'false' END FORMAT JSON RETURNING CLOB)
      ORDER BY employee_id RETURNING CLOB),TO_CLOB('[]')) FORMAT JSON RETURNING CLOB)
    FROM DDS_OWNER.EMPLOYEES_V~';
  OPEN s FOR q'~SELECT JSON_OBJECT('principal' VALUE JSON_VALUE(ORA_END_USER_CONTEXT,'$.USERNAME'),
    'employee_count' VALUE COUNT(*),'salary_total' VALUE NVL(SUM(salary),0) RETURNING CLOB)
    FROM DDS_OWNER.EMPLOYEES~';
  -- Use the normal cursor security level. No security checks are disabled.
  n:=DBMS_SQL.TO_CURSOR_NUMBER(r);m:=DBMS_SQL.TO_CURSOR_NUMBER(vcur);k:=DBMS_SQL.TO_CURSOR_NUMBER(s);
  DBMS_SQL.DEFINE_COLUMN(n,1,v);DBMS_SQL.DEFINE_COLUMN(m,1,v);DBMS_SQL.DEFINE_COLUMN(k,1,v);
  v:=DDS_AGENT_RUNTIME.DDS_AGENT_ENGINE.run_agent(p_prompt,n,m,k);RETURN v;
EXCEPTION WHEN OTHERS THEN
  saved_code:=SQLCODE;
  saved_error:=DBMS_UTILITY.FORMAT_ERROR_STACK||DBMS_UTILITY.FORMAT_ERROR_BACKTRACE;
  close_number(n);close_number(m);close_number(k);
  BEGIN IF r%ISOPEN THEN CLOSE r;END IF;EXCEPTION WHEN OTHERS THEN NULL;END;
  BEGIN IF vcur%ISOPEN THEN CLOSE vcur;END IF;EXCEPTION WHEN OTHERS THEN NULL;END;
  BEGIN IF s%ISOPEN THEN CLOSE s;END IF;EXCEPTION WHEN OTHERS THEN NULL;END;
  RAISE_APPLICATION_ERROR(-20088,SUBSTRB('DDS cursor entry failed ('||saved_code||'): '||saved_error,1,1800),TRUE);
END;
/

CREATE OR REPLACE FUNCTION DDS_AGENT_RUNTIME.DDS_LIST_TOOL_FN(
  p_employee_id NUMBER DEFAULT NULL,p_source VARCHAR2 DEFAULT 'table')
  RETURN CLOB AUTHID DEFINER AS
BEGIN RETURN DDS_AGENT_RUNTIME.DDS_AGENT_ENGINE.list_employees(p_employee_id,p_source);END;
/

CREATE OR REPLACE FUNCTION DDS_AGENT_RUNTIME.DDS_SUMMARY_TOOL_FN RETURN CLOB AUTHID DEFINER AS
BEGIN RETURN DDS_AGENT_RUNTIME.DDS_AGENT_ENGINE.salary_summary();END;
/
GRANT EXECUTE ON DDS_AGENT_RUNTIME.RUN_DDS_AGENT TO DDS_AI_DB_ROLE;
