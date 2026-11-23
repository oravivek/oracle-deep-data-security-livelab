# Validation status

Updated 23 November 2026. Expected outputs in this workshop are acceptance
criteria unless explicitly described here as observed.

## Observed live checks before this documentation update

- Autonomous Database reported version 23.26.4.1.0 with COMPATIBLE 23.5.0.
- ADMIN successfully created the dedicated owner, local end users, roles,
  synthetic data, view and data grants using the Autonomous setup statements.
- Both Emma and Marvin signed in to Streamlit. Real table/view reads, hidden
  sensitive values, employee 300 lookups, counts and salary totals matched
  the documented baseline.
- Six Emma prompts completed against local Ollama Qwen3 8B: broad records,
  aggregate, own identifier, out-of-scope employee 300, view, and claimed
  manager identity. Answers matched the current authorized tool results.
- A request made before the model download completed failed; its retest passed.

## Limits and repeatable checks

Marvin's AI prompt suite is pending wallet sign-in. Optional delegated IAM
authentication has not been live-tested. Updated cleanup scripts have been
reviewed and packaged but have not been run against the active demonstration
database. No cleanup or identity-provider reconfiguration was performed as
part of this file update.

Before presenting on another target, run the SQL demos, owner baseline check,
`python agent/verify_live.py`, and all six model prompts for both personas.
Offline tests use fake services and do not establish Oracle authorization.

Use `python -m unittest discover -s tests -v` for application checks,
`python tools/validate_workshop.py` for package checks, and
`python tools/validate_workshop.py --verify-checksums` for release integrity.
Record the actual release verification in `BUILD_VERIFICATION.txt`.
