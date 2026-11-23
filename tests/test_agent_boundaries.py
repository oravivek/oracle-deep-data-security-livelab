"""Offline boundary tests. These do NOT emulate or verify Oracle DDS."""
from pathlib import Path
import json
import sys
import unittest
from unittest.mock import MagicMock, patch

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "agent"))
import agent
import database


def fake_driver(identity="DDS_EMMA", pdb="LABPDB"):
    db = MagicMock()
    db.is_thin_mode.return_value = True
    connection = db.connect.return_value
    connection.__enter__.return_value = connection
    cursor = connection.cursor.return_value.__enter__.return_value
    cursor.fetchone.return_value = (identity, pdb, "FALSE")
    cursor.description = [("EMPLOYEE_ID",), ("FIRST_NAME",)]
    cursor.fetchall.return_value = [(400, "fixture")]
    return db, connection, cursor


class Boundaries(unittest.TestCase):
    def setUp(self):
        self.config = database.Config("dsn", "LABPDB")

    def test_direct_auth_checks_database_identity(self):
        db, _, _ = fake_driver(identity="DDS_MARVIN")
        with patch("database.driver", return_value=db):
            with self.assertRaises(RuntimeError):
                database.authenticate(self.config, "DDS_EMMA", "secret")

    def test_wrong_pdb_stops_before_employee_query(self):
        db, connection, cursor = fake_driver(pdb="OTHERPDB")
        with patch("database.driver", return_value=db):
            tool = database.DatabaseTools(self.config, "DDS_EMMA", "secret")
            with self.assertRaises(RuntimeError):
                tool.list_employees()
        self.assertFalse(any("FROM DDS_OWNER" in str(c)
                             for c in cursor.execute.call_args_list))
        connection.close.assert_called_once()

    def test_delegated_payload_uses_verified_user_and_no_extra_roles(self):
        db, connection, _ = fake_driver()
        with patch("database.driver", return_value=db):
            tool = database.DatabaseTools(
                self.config, "DDS_EMMA", "secret", mode="delegated",
                app_password="app-secret", database_access_token="token")
            tool.list_employees()
        kwargs = db.create_end_user_security_context.call_args.kwargs
        self.assertEqual(kwargs["end_user_identity"][0], "DDS_EMMA")
        self.assertNotIn("data_roles", kwargs)
        self.assertEqual(db.connect.call_args.kwargs["user"], "DDS_AGENT_APP")
        connection.clear_end_user_security_context.assert_called_once()
        connection.close.assert_called_once()

    def test_context_is_cleared_and_closed_when_query_fails(self):
        db, connection, cursor = fake_driver()
        def execute(sql, *args):
            if "FROM DDS_OWNER" in sql:
                raise RuntimeError("query failure")
        cursor.execute.side_effect = execute
        with patch("database.driver", return_value=db):
            tool = database.DatabaseTools(
                self.config, "DDS_EMMA", "secret", mode="delegated",
                app_password="app-secret", database_access_token="token")
            with self.assertRaises(RuntimeError):
                tool.list_employees()
        connection.rollback.assert_called_once()
        connection.clear_end_user_security_context.assert_called_once()
        connection.close.assert_called_once()

    def test_prompt_cannot_supply_another_identity(self):
        db = MagicMock()
        with self.assertRaises(ValueError):
            agent.dispatch(db, "list_employees", {"user": "DDS_MARVIN"})
        db.list_employees.assert_not_called()

    def test_values_are_bound_and_source_is_fixed(self):
        db, _, cursor = fake_driver()
        with patch("database.driver", return_value=db):
            tool = database.DatabaseTools(self.config, "DDS_EMMA", "secret")
            tool.list_employees(400)
            sql, binds = cursor.execute.call_args.args
            self.assertIn("employee_id = :employee_id", sql)
            self.assertEqual(binds, {"employee_id": 400})
            with self.assertRaises(ValueError):
                tool.list_employees("400 OR 1=1")
            with self.assertRaises(ValueError):
                tool.list_employees(source="DDS_OWNER.other_table")

    def test_tool_results_reach_llm_without_credentials(self):
        db = MagicMock()
        db.list_employees.return_value = {"rows": [{"employee_id": 400}]}
        transcript = []
        captured = []
        def llm(messages):
            transcript.append(agent.encode(messages))
            if len(transcript) == 1:
                return {"role": "assistant", "content": "", "tool_calls": [
                    {"function": {"name": "list_employees", "arguments": {}}}]}
            return {"role": "assistant", "content": "Employee 400."}
        answer = agent.ask(db, "Show employee records", llm=llm,
                           emit=lambda value: None,
                           on_tool_result=lambda name, result:
                               captured.append((name, result)))
        self.assertEqual(answer, "Employee 400.")
        tool_message = json.loads(transcript[-1])[-1]
        self.assertEqual(json.loads(tool_message["content"])["rows"],
                         [{"employee_id": 400}])
        self.assertEqual(captured, [("list_employees",
                                     json.loads(tool_message["content"]))])
        self.assertNotIn("database_access_token", transcript[-1])
        self.assertNotIn("password", transcript[-1])

    def test_no_database_tool_means_no_unsupported_answer(self):
        def llm(messages):
            return {"role": "assistant", "content": "Everyone earns 999999."}
        with self.assertRaises(RuntimeError):
            agent.ask(MagicMock(), "Show salaries", llm=llm)

    def test_missing_application_token_is_not_a_fallback(self):
        with self.assertRaises(ValueError):
            database.DatabaseTools(self.config, "DDS_EMMA", "secret",
                                   mode="delegated", app_password="app-secret")


if __name__ == "__main__":
    unittest.main()
