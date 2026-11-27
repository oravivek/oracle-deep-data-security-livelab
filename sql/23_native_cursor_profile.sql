-- Connect as DDS_OWNER after script 22. Clone existing OCI resource-principal settings.
@@_session.sql
@@_owner.sql
@@15_select_ai_config.sql
SET DEFINE ON
DECLARE
 a JSON_OBJECT_T:=JSON_OBJECT_T();
BEGIN
 FOR k IN (SELECT attribute_name,DBMS_LOB.SUBSTR(attribute_value,4000,1) val
 FROM user_cloud_ai_profile_attributes WHERE profile_name='DDS_OCI_PROFILE'
 AND LOWER(attribute_name) IN ('provider','credential_name','region','model','oci_compartment_id'))
 LOOP a.put(LOWER(k.attribute_name),k.val); END LOOP;
 IF INSTR('&&dds_ai_region','CHANGE_ME')>0 OR INSTR('&&dds_ai_compartment','CHANGE_ME')>0 OR INSTR('&&dds_ai_model','CHANGE_ME')>0 THEN
  RAISE_APPLICATION_ERROR(-20026,'Edit 15_select_ai_config.sql first');
 END IF;
 a.put('provider','oci');
 a.put('region','&&dds_ai_region');
 a.put('oci_compartment_id','&&dds_ai_compartment');
 a.put('model','&&dds_ai_model');
 a.put('temperature',0); a.put('max_tokens',8000);
 DBMS_CLOUD_AI.CREATE_PROFILE('DDS_NATIVE_OCI_PROFILE',a.to_clob());
 DBMS_CLOUD_AI.GRANT_PROFILE_ACCESS('DDS_NATIVE_OCI_PROFILE','DDS_AGENT_RUNTIME');

END;
/
