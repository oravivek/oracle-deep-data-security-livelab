-- Autonomous Database administrative operations use ADMIN.
BEGIN
  IF SYS_CONTEXT('USERENV','SESSION_USER') <> 'ADMIN' THEN
    RAISE_APPLICATION_ERROR(-20003,'Connect as ADMIN on Autonomous Database');
  END IF;
END;
/
