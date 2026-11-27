# Validation scope

The working cursor bridge was installed and verified on an Autonomous Database 26ai deployment reporting 23.26.4.1.0, with OCI xai.grok-4.3, on 28 November 2026. Both Emma and Marvin completed native RUN_TEAM in SQL and real Chrome/Streamlit sessions. State was SUCCEEDED; actual successful tool traces and AI answers agreed.

| Consumer | Employee IDs | Count | Salary total | Sensitive IDs |
| --- | --- | --- | --- | --- |
| DDS_EMMA | 400 | 1 | 80000 | Own ID visible |
| DDS_MARVIN | 200,400,500 | 3 | 285000 | Own ID visible; reports null |

Both consumers passed a combined view, employee-300 and claimed-owner prompt. View rows remained restricted and employee 300 returned an empty list. Browser sessions independently showed the correct identity, submitted prompt, tool rows/summary, SUCCEEDED indicator and matching AI prose. No passwords or private connection values are included in this release.

The runtime has NO AUTHENTICATION, zero system privileges, zero conventional roles, no data roles and no employee-table/view object grants. The temporary installer and all DDS_DIAG accounts/code/jobs/programs were removed. The permanent approved runtime remains installed. Error preservation retained the original null-prompt -20085; a subsequent valid native request in the same session succeeded.

The original direct shared-team ORA-01435 remains reproducible on the tested deployment; the bridge is a verified architectural workaround, not a claim to have patched Oracle internals. It uses native planning and tool execution, not a Python/chat compatibility workflow. Ordinary SELECT grants on the runtime would undermine the design and are not used.

Offline tests validate client identity/state/trace checks, bound prompts, error handling and Streamlit session isolation. They do not emulate DDS. The optional Entra delegated path is supplied separately and is not live-validated. Participants must repeat the SQL and agent checkpoints against their own update, region and configuration. Model prose can vary; validate it against tool results.

The setup was executed successfully on the retained demo. Release cleanup was structurally reviewed and packaged, but the permanent runtime/base demo was deliberately not deleted simply to test this documentation release. Diagnostic objects were actually removed and their absence checked. Do not interpret cleanup documentation as evidence of a destructive end-to-end teardown test.
