# Validation scope

The Select AI migration includes offline tests for authenticated connections, wrong-PDB rejection, context teardown, bound prompt parameters, a fixed server-side team, invoker tool trace identity, failed inference cleanup, and Streamlit sign-in, switching and session isolation. See BUILD_VERIFICATION.txt for the actual release checks.

Earlier real Autonomous Database tests verified Emma sees only employee 400 and total 80000; Marvin sees 200,400,500 and total 285000; both cannot see 300; manager report identifiers are NULL. These remain expected results, not proof that the new OCI agent has run.

The current release has not executed scripts 16 through 19 or the cleanup extension against the database and has not completed live OCI inference. The connected SQLcl service stopped returning output during API inspection, and the chosen OCI region/compartment/model and wallet interaction are still needed for an end-to-end test. Scripts fail on missing APIs or failed compilation rather than silently falling back to a privileged account.

Before presenting, complete the checkpoints in Lab 4 and AI_VERIFICATION.md. Confirm shared profile, team, credential privileges and invoker-rights functions on your Autonomous update. Do not treat mock tests as evidence of database policy enforcement. Cleanup is intentionally not run against the active demo solely to validate packaging.
