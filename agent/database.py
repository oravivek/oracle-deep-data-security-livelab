"""Identity-bound database tools for the existing DDS SQL demo."""
from contextlib import contextmanager
from dataclasses import dataclass
import importlib
import os
import uuid

ALLOWED_USERS = {"DDS_EMMA", "DDS_MARVIN"}
OBJECTS = {"table": "DDS_OWNER.EMPLOYEES",
           "view": "DDS_OWNER.EMPLOYEES_V"}
IDENTITY_SQL = """
SELECT JSON_VALUE(ORA_END_USER_CONTEXT, '$.USERNAME'
                  RETURNING VARCHAR2(128)),
       SYS_CONTEXT('USERENV','CON_NAME'),
       SYS_CONTEXT('USERENV','ISDBA')
FROM dual
"""


@dataclass(frozen=True)
class Config:
    dsn: str
    expected_pdb: str
    config_dir: str | None = None
    wallet_location: str | None = None
    wallet_password: str | None = None

    @classmethod
    def from_environment(cls, wallet_password=None):
        dsn = os.environ.get("ORACLE_DSN", "").strip()
        pdb = os.environ.get("ORACLE_EXPECTED_PDB", "").strip()
        if not dsn or not pdb or "CHANGE_ME" in pdb.upper():
            raise ValueError("Set ORACLE_DSN and ORACLE_EXPECTED_PDB")
        return cls(dsn, pdb.upper(), os.getenv("ORACLE_CONFIG_DIR"),
                   os.getenv("ORACLE_WALLET_LOCATION"), wallet_password)

    def connect_options(self):
        options = {"dsn": self.dsn, "ssl_server_dn_match": True}
        for key in ("config_dir", "wallet_location", "wallet_password"):
            value = getattr(self, key)
            if value:
                options[key] = value
        return options


def driver():
    module = importlib.import_module("oracledb")
    if not module.is_thin_mode():
        raise RuntimeError("Use python-oracledb Thin mode")
    return module


def check_identity(connection, expected_user, expected_pdb):
    with connection.cursor() as cursor:
        cursor.execute(IDENTITY_SQL)
        name, pdb, is_dba = cursor.fetchone()
    if (not name or name.upper() != expected_user
            or not pdb or pdb.upper() != expected_pdb.upper()
            or is_dba != "FALSE"):
        raise RuntimeError("Database identity or PDB check failed")
    return name.upper()


def authenticate(config, requested_user, password):
    """Database authentication establishes the trusted CLI principal."""
    if requested_user not in ALLOWED_USERS:
        raise ValueError("Choose DDS_EMMA or DDS_MARVIN")
    with driver().connect(user=requested_user, password=password,
                          **config.connect_options()) as connection:
        connection.call_timeout = 15000
        return check_identity(connection, requested_user,
                              config.expected_pdb)


class DatabaseTools:
    def __init__(self, config, principal, password, *, mode="direct",
                 app_password=None, database_access_token=None):
        if principal not in ALLOWED_USERS:
            raise ValueError("Unsupported principal")
        if mode not in {"direct", "delegated"}:
            raise ValueError("Unsupported mode")
        if mode == "delegated" and (
                not app_password or not database_access_token):
            raise ValueError("Delegated mode requires app credentials/token")
        self.config, self.principal = config, principal
        self.password, self.mode = password, mode
        self.app_password = app_password
        self.database_access_token = database_access_token
        self.lookup_key = str(uuid.uuid4())

    @contextmanager
    def connection(self):
        """Fresh connection per tool; never falls back to an owner account."""
        db = driver()
        user = self.principal if self.mode == "direct" else "DDS_AGENT_APP"
        password = (self.password if self.mode == "direct"
                    else self.app_password)
        connection = db.connect(user=user, password=password,
                                **self.config.connect_options())
        context_attached = False
        try:
            connection.call_timeout = 15000
            if self.mode == "delegated":
                context = db.create_end_user_security_context(
                    database_access_token=self.database_access_token,
                    end_user_identity=(self.principal, self.lookup_key),
                )
                # No extra data roles: existing user grants decide access.
                connection.set_end_user_security_context(context)
                context_attached = True
            with connection.cursor() as cursor:
                cursor.execute("SET TRANSACTION READ ONLY")
            # Forces a round trip after context attachment, before data SQL.
            check_identity(connection, self.principal,
                           self.config.expected_pdb)
            yield connection
        finally:
            try:
                connection.rollback()
            finally:
                try:
                    if context_attached:
                        connection.clear_end_user_security_context()
                finally:
                    connection.close()

    def list_employees(self, employee_id=None, source="table"):
        if source not in OBJECTS:
            raise ValueError("source must be table or view")
        if (employee_id is not None and
                (type(employee_id) is not int or employee_id < 1
                 or employee_id > 999999)):
            raise ValueError("employee_id must be a positive integer")
        sql = """
SELECT employee_id, first_name, sensitive_id, salary, phone,
       ORA_IS_COLUMN_AUTHORIZED(sensitive_id) AS id_authorized
FROM """ + OBJECTS[source]
        binds = {}
        if employee_id is not None:
            sql += " WHERE employee_id = :employee_id"
            binds["employee_id"] = employee_id
        sql += " ORDER BY employee_id FETCH FIRST 101 ROWS ONLY"
        with self.connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute(sql, binds)
                names = [column[0].lower() for column in cursor.description]
                rows = cursor.fetchall()
        if len(rows) > 100:
            raise RuntimeError("Demo result exceeds 100 rows")
        return {"principal": self.principal, "source": source,
                "rows": [dict(zip(names, row)) for row in rows]}

    def salary_summary(self):
        with self.connection() as connection:
            with connection.cursor() as cursor:
                cursor.execute("""
SELECT COUNT(*) AS employee_count, NVL(SUM(salary),0) AS salary_total
FROM DDS_OWNER.EMPLOYEES
""")
                count, total = cursor.fetchone()
        return {"principal": self.principal,
                "employee_count": count, "salary_total": total}
