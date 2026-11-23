"""Streamlit UI tests with fake DB/model services, never Oracle DDS tests."""
from pathlib import Path
import sys
import unittest
from unittest.mock import patch

try:
    from streamlit.testing.v1 import AppTest
except ImportError:
    AppTest = None

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "agent"))
import agent as agent_runtime
from database import Config


class FakeTools:
    def __init__(self, config, principal, password, **kwargs):
        self.config, self.principal, self.password = config, principal, password

    def list_employees(self, employee_id=None, source="table"):
        rows = [{"employee_id": 400, "first_name": "Emma",
                 "sensitive_id": "TEST-EMMA", "salary": 80000,
                 "phone": "555-0400", "id_authorized": True}]
        if self.principal == "DDS_MARVIN":
            rows[0].update(sensitive_id=None, id_authorized=False)
            rows.insert(0, {"employee_id": 200, "first_name": "Marvin",
                            "sensitive_id": "TEST-MARVIN", "salary": 120000,
                            "phone": "555-0200", "id_authorized": True})
        if employee_id is not None:
            rows = [row for row in rows if row["employee_id"] == employee_id]
        return {"principal": self.principal, "source": source, "rows": rows}

    def salary_summary(self):
        return {"principal": self.principal, "employee_count": 1,
                "salary_total": 80000}


def fake_ask(database, prompt, *, on_tool_result, **kwargs):
    on_tool_result("list_employees", database.list_employees())
    return "Answer for " + database.principal


@unittest.skipIf(AppTest is None, "Install requirements-streamlit.txt for UI tests")
class StreamlitUI(unittest.TestCase):
    def setUp(self):
        self.auth_patch = patch("database.authenticate",
                                side_effect=lambda config, user, password: user)
        self.auth = self.auth_patch.start()
        self.tools_patch = patch("database.DatabaseTools", FakeTools)
        self.tools_patch.start()
        self.config_patch = patch("database.Config.from_environment",
                                  return_value=Config("dsn", "LABPDB"))
        self.config_patch.start()
        self.ask_patch = patch.object(agent_runtime, "ask", side_effect=fake_ask)
        self.ask = self.ask_patch.start()
        self.addCleanup(patch.stopall)
        self.app = AppTest.from_file(str(ROOT / "streamlit_app.py"),
                                     default_timeout=15)
        self.app.run()

    def button(self, label, app=None):
        return next(button for button in (app or self.app).button
                    if button.label == label)

    def login(self, persona="Employee · Emma", app=None):
        app = app or self.app
        app.selectbox(key="persona").select(persona)
        app.text_input(key="login_password").input("fixture-password")
        self.button("Sign in", app).click().run()
        self.assertFalse(app.exception)

    def metric(self, label):
        return next(metric.value for metric in self.app.metric
                    if metric.label == label)

    def test_logged_out_app_never_calls_database(self):
        self.assertFalse(self.app.exception)
        self.auth.assert_not_called()
        self.assertFalse(self.app.dataframe)
        self.assertFalse(self.app.text_area)

    def test_login_shows_verified_identity_and_clears_password_widget(self):
        self.login()
        self.assertEqual(self.metric("Active identity"), "DDS_EMMA")
        self.assertNotIn("login_password", self.app.session_state)
        self.assertEqual(self.auth.call_args.args[1], "DDS_EMMA")

    def test_agent_displays_prompt_tool_data_and_ai_answer(self):
        self.login()
        self.app.text_area(key="prompt").input("Show employee salaries")
        self.button("Run AI agent").click().run()
        self.assertFalse(self.app.exception)
        self.assertEqual(self.app.session_state["submitted_prompt"],
                         "Show employee salaries")
        self.assertEqual(len(self.app.dataframe), 1)
        self.assertEqual(self.app.session_state["ai_response"],
                         "Answer for DDS_EMMA")

    def test_probe_does_not_call_model(self):
        self.login()
        self.button("Show database results").click().run()
        self.assertFalse(self.app.exception)
        self.ask.assert_not_called()
        self.assertEqual(len(self.app.session_state["tool_results"]), 4)
        self.assertFalse(self.app.session_state["ai_response"])

    def test_manager_table_labels_restricted_identifier(self):
        self.login("Manager · Marvin")
        self.button("Run AI agent").click().run()
        self.assertEqual(self.metric("Active identity"), "DDS_MARVIN")
        frame = self.app.dataframe[0].value
        self.assertEqual(frame.loc[frame.employee_id == 400,
                                   "sensitive_id"].iloc[0], "Restricted")
        raw = self.app.session_state["tool_results"][0]["result"]["rows"]
        self.assertIsNone(raw[1]["sensitive_id"])

    def test_switch_clears_credentials_prompt_results_and_response(self):
        self.login("Manager · Marvin")
        self.button("Run AI agent").click().run()
        self.button("Sign out and switch user").click().run()
        for key in ("demo_database", "submitted_prompt", "tool_results",
                    "ai_response", "prompt"):
            self.assertNotIn(key, self.app.session_state)
        self.assertEqual(self.app.text_input(key="login_password").value, "")
        self.assertFalse(self.app.dataframe)
        self.login()
        self.assertEqual(self.metric("Active identity"), "DDS_EMMA")
        self.assertFalse(self.app.dataframe)

    def test_failed_login_shows_no_database_identity_or_data(self):
        self.auth.side_effect = RuntimeError("SENSITIVE-DETAIL")
        self.app.text_input(key="login_password").input("wrong")
        self.button("Sign in").click().run()
        self.assertFalse(self.app.exception)
        self.assertNotIn("demo_database", self.app.session_state)
        self.assertEqual(self.app.text_input(key="login_password").value, "")
        self.assertNotIn("SENSITIVE-DETAIL", str(self.app.error))

    def test_failure_replaces_old_answer_and_retains_only_current_trace(self):
        self.login()
        self.button("Run AI agent").click().run()
        def fail(database, prompt, *, on_tool_result, **kwargs):
            on_tool_result("salary_summary", database.salary_summary())
            raise RuntimeError("SENSITIVE-MODEL-ERROR")
        self.ask.side_effect = fail
        self.button("Run AI agent").click().run()
        self.assertFalse(self.app.exception)
        self.assertEqual(self.app.session_state["ai_response"], "")
        self.assertEqual([r["tool"] for r in
                          self.app.session_state["tool_results"]],
                         ["salary_summary"])
        self.assertNotIn("SENSITIVE-MODEL-ERROR", str(self.app.error))

    def test_revoked_login_clears_display_before_request(self):
        self.login()
        self.button("Run AI agent").click().run()
        self.auth.side_effect = RuntimeError("revoked")
        self.button("Run AI agent").click().run()
        self.assertFalse(self.app.exception)
        self.assertNotIn("demo_database", self.app.session_state)
        self.assertFalse(self.app.dataframe)
        self.assertTrue(self.app.error)

    def test_browser_sessions_do_not_share_identity_or_results(self):
        self.login("Manager · Marvin")
        self.button("Run AI agent").click().run()
        other = AppTest.from_file(str(ROOT / "streamlit_app.py"),
                                 default_timeout=15).run()
        self.assertNotIn("demo_database", other.session_state)
        self.assertFalse(other.dataframe)
        self.login(app=other)
        self.assertEqual(other.session_state["demo_database"].principal,
                         "DDS_EMMA")
        self.assertEqual(self.app.session_state["demo_database"].principal,
                         "DDS_MARVIN")


if __name__ == "__main__":
    unittest.main()
