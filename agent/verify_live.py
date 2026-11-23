"""Live acceptance checks; requires the configured Oracle demo database."""
import argparse
import getpass
import os
from database import Config, DatabaseTools, authenticate


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--mode", choices=["direct", "delegated"],
                        default="direct")
    args = parser.parse_args()
    wallet_password = (getpass.getpass("Wallet password: ")
                       if os.getenv("ORACLE_WALLET_LOCATION") else None)
    config = Config.from_environment(wallet_password)
    extra = {}
    if args.mode == "delegated":
        from tokens import client_credentials_token
        extra["app_password"] = getpass.getpass("DDS_AGENT_APP password: ")
        extra["database_access_token"] = client_credentials_token()
    for user, expected_ids, expected_total in [
            ("DDS_EMMA", [400], 80000),
            ("DDS_MARVIN", [200, 400, 500], 285000)]:
        password = getpass.getpass(user + " password: ")
        principal = authenticate(config, user, password)
        tools = DatabaseTools(config, principal, password,
                              mode=args.mode, **extra)
        for source in ("table", "view"):
            rows = tools.list_employees(source=source)["rows"]
            if [row["employee_id"] for row in rows] != expected_ids:
                raise RuntimeError(user + ": unexpected visible rows")
            for row in rows:
                expected_id = ("ID-DEMO-0400" if user == "DDS_EMMA"
                               else "ID-DEMO-0200"
                               if row["employee_id"] == 200 else None)
                if row["sensitive_id"] != expected_id:
                    raise RuntimeError(user + ": unexpected identifier access")
        if tools.list_employees(300)["rows"]:
            raise RuntimeError(user + ": unrelated record was exposed")
        summary = tools.salary_summary()
        if (summary["employee_count"] != len(expected_ids)
                or summary["salary_total"] != expected_total):
            raise RuntimeError(user + ": salary summary does not match baseline")
        print("PASS " + user + ": table, view, identifiers, lookup and total")


if __name__ == "__main__":
    main()
