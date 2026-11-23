-- Autonomous Database guard. Run as ADMIN in the configured PDB.
BEGIN
  IF SYS_CONTEXT('USERENV','SESSION_USER') <> 'ADMIN' THEN
    RAISE_APPLICATION_ERROR(-20003,'Connect as ADMIN on Autonomous Database');
  END IF;
END;
/
