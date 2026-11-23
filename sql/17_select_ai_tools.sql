-- Run as DDS_OWNER. Only these two read tools are registered with the model.
@@_session.sql
@@_owner.sql
CREATE OR REPLACE PACKAGE DDS_OWNER.DDS_AI_TOOLS AUTHID CURRENT_USER AS
  PROCEDURE reset_trace;
  FUNCTION get_trace RETURN CLOB;
  FUNCTION list_employees(p_employee_id NUMBER DEFAULT NULL,
                          p_source VARCHAR2 DEFAULT 'table') RETURN CLOB;
  FUNCTION salary_summary RETURN CLOB;
END;
/
CREATE OR REPLACE PACKAGE BODY DDS_OWNER.DDS_AI_TOOLS AS
  g_trace JSON_ARRAY_T := JSON_ARRAY_T();
  g_calls PLS_INTEGER := 0;

  FUNCTION principal RETURN VARCHAR2 IS
    u VARCHAR2(128);
  BEGIN
    SELECT JSON_VALUE(ORA_END_USER_CONTEXT,'$.USERNAME') INTO u FROM dual;
    IF u IS NULL OR u NOT IN ('DDS_EMMA','DDS_MARVIN')
       OR SYS_CONTEXT('USERENV','ISDBA') <> 'FALSE' THEN
      RAISE_APPLICATION_ERROR(-20021,'Authenticated DDS consumer required');
    END IF;
    RETURN u;
  END;

  PROCEDURE reset_trace IS
    u VARCHAR2(128) := principal();
  BEGIN
    g_trace := JSON_ARRAY_T();
    g_calls := 0;
  END;

  FUNCTION get_trace RETURN CLOB IS
    u VARCHAR2(128) := principal();
  BEGIN
    RETURN g_trace.to_clob();
  END;

  PROCEDURE before_read IS
    u VARCHAR2(128) := principal();
  BEGIN
    g_calls := g_calls + 1;
    IF g_calls > 8 THEN
      RAISE_APPLICATION_ERROR(-20022,'Eight tool calls per question maximum');
    END IF;
  END;

  FUNCTION record_result(tool_name VARCHAR2, result JSON_OBJECT_T)
    RETURN CLOB IS
    item JSON_OBJECT_T := JSON_OBJECT_T();
  BEGIN
    item.put('tool',tool_name);
    item.put('result',result);
    g_trace.append(item);
    RETURN result.to_clob();
  END;

  FUNCTION list_employees(p_employee_id NUMBER DEFAULT NULL,
                          p_source VARCHAR2 DEFAULT 'table') RETURN CLOB IS
    result JSON_OBJECT_T := JSON_OBJECT_T();
    rows_json CLOB;
    rows_array JSON_ARRAY_T;
    src VARCHAR2(10) := LOWER(NVL(p_source,'table'));
    u VARCHAR2(128) := principal();
  BEGIN
    before_read;
    IF src NOT IN ('table','view') OR
       (p_employee_id IS NOT NULL AND
        (p_employee_id <> TRUNC(p_employee_id) OR
         p_employee_id NOT BETWEEN 1 AND 999999)) THEN
      RAISE_APPLICATION_ERROR(-20023,'Invalid employee ID or source');
    END IF;
    IF src = 'table' THEN
      SELECT JSON_ARRAYAGG(JSON_OBJECT(
        'employee_id' VALUE employee_id, 'first_name' VALUE first_name,
        'sensitive_id' VALUE sensitive_id, 'salary' VALUE salary,
        'phone' VALUE phone,
        'id_authorized' VALUE CASE WHEN ORA_IS_COLUMN_AUTHORIZED(sensitive_id)
                              THEN 'true' ELSE 'false' END FORMAT JSON
        NULL ON NULL RETURNING CLOB) ORDER BY employee_id RETURNING CLOB)
      INTO rows_json FROM DDS_OWNER.EMPLOYEES
      WHERE (p_employee_id IS NULL OR employee_id = p_employee_id);
    ELSE
      SELECT JSON_ARRAYAGG(JSON_OBJECT(
        'employee_id' VALUE employee_id, 'first_name' VALUE first_name,
        'sensitive_id' VALUE sensitive_id, 'salary' VALUE salary,
        'phone' VALUE phone,
        'id_authorized' VALUE CASE WHEN ORA_IS_COLUMN_AUTHORIZED(sensitive_id)
                              THEN 'true' ELSE 'false' END FORMAT JSON
        NULL ON NULL RETURNING CLOB) ORDER BY employee_id RETURNING CLOB)
      INTO rows_json FROM DDS_OWNER.EMPLOYEES_V
      WHERE (p_employee_id IS NULL OR employee_id = p_employee_id);
    END IF;
    IF rows_json IS NULL THEN rows_json := '[]'; END IF;
    rows_array := JSON_ARRAY_T.parse(rows_json);
    IF rows_array.get_size() > 100 THEN
      RAISE_APPLICATION_ERROR(-20024,'Demo result exceeds 100 rows');
    END IF;
    result.put('principal',u);
    result.put('source',src);
    result.put('rows',rows_array);
    RETURN record_result('list_employees',result);
  END;

  FUNCTION salary_summary RETURN CLOB IS
    result JSON_OBJECT_T := JSON_OBJECT_T();
    n NUMBER;
    total NUMBER;
    u VARCHAR2(128) := principal();
  BEGIN
    before_read;
    SELECT COUNT(*), NVL(SUM(salary),0) INTO n,total
      FROM DDS_OWNER.EMPLOYEES;
    result.put('principal',u);
    result.put('employee_count',n);
    result.put('salary_total',total);
    RETURN record_result('salary_summary',result);
  END;
END;
/
-- Standalone wrappers make function argument discovery unambiguous.
CREATE OR REPLACE FUNCTION DDS_OWNER.DDS_LIST_EMPLOYEES(
  p_employee_id NUMBER DEFAULT NULL, p_source VARCHAR2 DEFAULT 'table')
  RETURN CLOB AUTHID CURRENT_USER IS
BEGIN
  RETURN DDS_OWNER.DDS_AI_TOOLS.list_employees(p_employee_id,p_source);
END;
/
CREATE OR REPLACE FUNCTION DDS_OWNER.DDS_SALARY_SUMMARY
  RETURN CLOB AUTHID CURRENT_USER IS
BEGIN
  RETURN DDS_OWNER.DDS_AI_TOOLS.salary_summary();
END;
/
DECLARE
  n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM user_errors
    WHERE name IN ('DDS_AI_TOOLS','DDS_LIST_EMPLOYEES','DDS_SALARY_SUMMARY')
      AND attribute = 'ERROR';
  IF n <> 0 THEN
    RAISE_APPLICATION_ERROR(-20025,'Tool compilation failed; inspect USER_ERRORS');
  END IF;
END;
/
GRANT EXECUTE ON DDS_OWNER.DDS_AI_TOOLS TO DDS_AI_DB_ROLE;
GRANT EXECUTE ON DDS_OWNER.DDS_LIST_EMPLOYEES TO DDS_AI_DB_ROLE;
GRANT EXECUTE ON DDS_OWNER.DDS_SALARY_SUMMARY TO DDS_AI_DB_ROLE;
PROMPT PASS: invoker-rights read tools compiled and granted.
