## Summary

<!-- What business problem does this solve? Link the Jira ticket, e.g. BUN-123. -->

## Changes

-

## Why code (not clicks)?

<!-- BF-APEX-1: if this adds Apex, explain why a Flow, validation rule, formula or roll-up summary wasn't enough. -->

## Governor limits & data volume

<!-- SOQL/DML per transaction, async usage, behaviour at 200 records. -->

## Security

- [ ] Sharing declared on every new class (BF-SEC-1)
- [ ] CRUD/FLS enforced for user-facing code (BF-SEC-2)
- [ ] New fields, objects and classes added to the right permission set (BF-SEC-6)

## Tests

- [ ] Tests added or updated, with meaningful assertions (BF-TEST-2)
- [ ] Bulk (200 record) scenario for trigger/service changes (BF-TEST-5)
- [ ] `System.runAs` permission tests for user-facing code (BF-TEST-6)

## Deployment notes

<!-- Manual post-deploy steps: named credentials, scheduled jobs, permission set assignments, data backfills. "None" if not applicable. -->
