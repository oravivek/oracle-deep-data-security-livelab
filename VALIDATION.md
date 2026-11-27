# Validation scope

The Select AI migration includes offline tests for authenticated connections, wrong-PDB rejection, context teardown, bound prompt parameters, a fixed server-side team, invoker tool trace identity, failed inference cleanup, and Streamlit sign-in, switching and session isolation. See BUILD_VERIFICATION.txt for the actual release checks.

Earlier real Autonomous Database tests verified Emma sees only employee 400 and total 80000; Marvin sees 200,400,500 and total 285000; both cannot see 300; manager report identifiers are NULL. These remain expected results, not proof that the new OCI agent has run.

User-provided output on 27 November 2026 confirms Emma can invoke the new PL/SQL tools directly: employee 400, count 1, total 80000. The agent run fails with ORA-20053 (maximum failed iterations), followed by ORA-01435 during conversation cleanup. The runtime cause of the task failure remains unresolved. The supplied diagnostics preserve the original error and inspect scoped history; they are not a successful inference result. The previously saved connection currently has no DDS_OWNER objects or DDS team history, so the failing target must be identified before direct investigation. Cleanup scripts have not been live-validated.

Before presenting, complete the checkpoints in Lab 4 and AI_VERIFICATION.md. Confirm shared profile, team, credential privileges and invoker-rights functions on your Autonomous update. Do not treat mock tests as evidence of database policy enforcement. Cleanup is intentionally not run against the active demo solely to validate packaging.
