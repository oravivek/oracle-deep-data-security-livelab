"""Select AI Agent client: orchestration and OCI inference run from the database."""
import argparse
import getpass
import json
import os
import sys

from database import ALLOWED_USERS, Config, DatabaseTools, authenticate, driver

TEAM = "DDS_OWNER.DDS_HR_TEAM"
CURSOR_BRIDGE = "DDS_AGENT_RUNTIME.RUN_DDS_AGENT"


def encode(value):
    return json.dumps(value, default=str, ensure_ascii=True)


def read_clob(value):
    text = value.read() if hasattr(value, "read") else value
    if not isinstance(text, str) or len(text) > 2_000_000:
        raise RuntimeError("Invalid or oversized Select AI result")
    return text


def checked_trace(raw, principal):
    records = json.loads(raw)
    if not isinstance(records, list) or not 1 <= len(records) <= 8:
        raise RuntimeError("No successful database tool call or tool limit exceeded")
    for record in records:
        if (not isinstance(record, dict)
                or record.get("tool") not in {"list_employees", "salary_summary"}
                or not isinstance(record.get("result"), dict)
                or record["result"].get("principal") != principal):
            raise RuntimeError("Tool trace identity or tool mismatch")
    return records


def ask(database, prompt, *, emit=print, on_tool_result=None):
    if not isinstance(prompt, str) or not prompt.strip() or len(prompt) > 4000:
        raise ValueError("Prompt must contain 1 to 4000 characters")
    execution = os.getenv("SELECT_AI_EXECUTION", "cursor_bridge")
    if execution == "shared_team":
        return _ask_shared_team(database, prompt, emit=emit,
                                on_tool_result=on_tool_result)
    if execution != "cursor_bridge":
        raise ValueError("SELECT_AI_EXECUTION must be cursor_bridge or shared_team")
    # Oracle performs native RUN_TEAM orchestration and tool calls. Python only
    # binds the prompt and verifies the response envelope from that same session.
    with database.connection(read_only=False) as connection:
        connection.call_timeout = 240000
        with connection.cursor() as cursor:
            raw = read_clob(cursor.callfunc(
                CURSOR_BRIDGE, driver().DB_TYPE_CLOB,
                keyword_parameters={"p_prompt": prompt}))
            result = json.loads(raw)
            if (not isinstance(result, dict)
                    or result.get("principal") != database.principal
                    or result.get("state") != "SUCCEEDED"
                    or not isinstance(result.get("answer"), str)
                    or not result["answer"].strip()):
                raise RuntimeError("Native DDS agent returned an invalid result")
            records = checked_trace(encode(result.get("tool_trace")),
                                    database.principal)
            for record in records:
                emit("TOOL_RESULT " + record["tool"] + " " + encode(record["result"]))
                if on_tool_result:
                    on_tool_result(record["tool"], record["result"])
            return result["answer"]


def _ask_shared_team(database, prompt, *, emit=print, on_tool_result=None):
    if not isinstance(prompt, str) or not prompt.strip() or len(prompt) > 4000:
        raise ValueError("Prompt must contain 1 to 4000 characters")
    # RUN_TEAM may write framework history. The custom tools themselves only SELECT.
    # Use one fresh authenticated consumer session for orchestration AND trace.
    with database.connection(read_only=False) as connection:
        connection.call_timeout = 240000
        with connection.cursor() as cursor:
            cursor.callproc("DDS_OWNER.DDS_AI_TOOLS.RESET_TRACE")
            conversation = cursor.callfunc("DBMS_CLOUD_AI.CREATE_CONVERSATION", str)
            try:
                params = encode({"conversation_id": conversation})
                answer = read_clob(cursor.callfunc(
                    "DBMS_CLOUD_AI_AGENT.RUN_TEAM", driver().DB_TYPE_CLOB,
                    keyword_parameters={"team_name": TEAM,
                                        "user_prompt": prompt, "params": params}))
                state = cursor.callfunc(
                    "DBMS_CLOUD_AI_AGENT.GET_TEAM_STATE", str,
                    keyword_parameters={"team_name": TEAM, "params": params})
                trace = read_clob(cursor.callfunc(
                    "DDS_OWNER.DDS_AI_TOOLS.GET_TRACE", driver().DB_TYPE_CLOB))
                records = checked_trace(trace, database.principal)
                for record in records:
                    emit("TOOL_RESULT " + record["tool"] + " " + encode(record["result"]))
                    if on_tool_result:
                        on_tool_result(record["tool"], record["result"])
                if state != "SUCCEEDED" or not answer.strip():
                    raise RuntimeError("Select AI Agent did not complete")
                return answer
            finally:
                # Separate conversations for every request, including failed requests.
                # Agent run history is separate; see the lab retention guidance.
                original_error = sys.exception()
                try:
                    cursor.callproc("DBMS_CLOUD_AI.DROP_CONVERSATION", [conversation, True])
                except Exception:
                    if original_error is None:
                        raise
                    original_error.add_note(
                        "Conversation cleanup also failed; inspect database history. "
                        "The original agent error was retained.")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--user", required=True, choices=sorted(ALLOWED_USERS))
    parser.add_argument("--mode", choices=["direct", "delegated"],
                        default="direct")
    parser.add_argument("--prompt")
    parser.add_argument("--probe", action="store_true",
                        help="Run database tools without invoking the LLM")
    args = parser.parse_args()
    wallet_password = (getpass.getpass("Wallet password: ")
                       if os.getenv("ORACLE_WALLET_LOCATION") else None)
    config = Config.from_environment(wallet_password)
    user_password = getpass.getpass(args.user + " database password: ")
    # Identity comes from successful DB authentication, never prompt text.
    principal = authenticate(config, args.user, user_password)
    kwargs = {}
    if args.mode == "delegated":
        from tokens import client_credentials_token
        kwargs["app_password"] = getpass.getpass("DDS_AGENT_APP password: ")
        kwargs["database_access_token"] = client_credentials_token()
    database = DatabaseTools(config, principal, user_password,
                             mode=args.mode, **kwargs)
    print("AUTHENTICATED " + principal + " MODE " + args.mode)
    if args.probe:
        print("TABLE " + encode(database.list_employees()))
        print("VIEW " + encode(database.list_employees(source="view")))
        print("EMPLOYEE_300 " + encode(database.list_employees(300)))
        print("SUMMARY " + encode(database.salary_summary()))
    elif args.prompt:
        print(ask(database, args.prompt))
    else:
        while True:
            prompt = input("Ask (or exit): ").strip()
            if prompt.lower() in {"exit", "quit"}:
                return
            if prompt:
                print(ask(database, prompt))


if __name__ == "__main__":
    try:
        main()
    except (KeyboardInterrupt, EOFError):
        print("Stopped.", file=sys.stderr)
    except Exception as error:
        print("Stopped: " + type(error).__name__ +
              ". Check database identity, Select AI grants, OCI IAM and model setup.",
              file=sys.stderr)
        sys.exit(1)
