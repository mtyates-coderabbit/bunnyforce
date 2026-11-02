# Bunnyforce Apex Code Review Standards

These standards are the team's code review checklist. Reviewers (human and CodeRabbit) cite
rules by ID, e.g. **BF-PERF-1**. They are adapted from Amit Chaudhary's
[Salesforce code review checklist](https://www.salesforcereader.com/2021/04/code-review-checklist-amit-chaudhary.html)
and applied to this codebase's architecture.

Severity key:

- **Blocking**: the PR cannot merge until it is fixed. Enforced by a CodeRabbit pre-merge check in error mode.
- **Required**: fix it, or justify it in the PR and get a reviewer to agree.
- **Advisory**: a recommendation.

---

## 1. Basic review

| ID | Rule | Severity |
| --- | --- | --- |
| BF-BASIC-1 | A reviewer unfamiliar with the change can understand it from the code and PR description alone. | Required |
| BF-BASIC-2 | No class or method is too large (see BF-STD-3, BF-STD-4). | Required |
| BF-BASIC-3 | No SOQL, SOSL or DML inside loops (see BF-PERF-1). | Blocking |
| BF-BASIC-4 | Org-wide Apex coverage stays at or above 90% (Salesforce minimum is 75%); every new or changed class has tests that exercise it. | Required |
| BF-BASIC-5 | Formatting matches Prettier (`npm run prettier:verify`) and naming follows section 2. | Required |

## 2. Standards and naming (BF-STD)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-STD-1 | Classes are `PascalCase` nouns. Suffixes are mandatory: `*TriggerHandler`, `*Service`, `*Selector`, `*Controller`, `*Batch`, `*Queueable`, `*Schedulable`, `*Test`, `*Exception`. Interfaces are prefixed `I`. | Required |
| BF-STD-2 | Methods and variables are `camelCase`; constants are `UPPER_SNAKE_CASE` and `static final`. Booleans read as predicates (`isEnabled`, `hasPerishable`). No single-letter names except loop indexes. | Required |
| BF-STD-3 | Methods do one thing and fit on a screen: aim for 30 lines or fewer, with PMD NcssCount at 40 statements and cyclomatic complexity at 10. | Required |
| BF-STD-4 | Classes have a single responsibility (BF-OO-1). A class over about 400 statements is a design smell. | Advisory |
| BF-STD-5 | No duplicated logic. Shared rules live in one place, e.g. `CreditPolicy`, `OrderConstants`, `BunnyforceSettings`. | Required |
| BF-STD-6 | One statement per line; braces on every `if`/`for`/`while`. Avoid nested ternaries and chained operations on one line. | Required |
| BF-STD-7 | Picklist values and status strings come from constants (`OrderConstants`), never inline literals repeated across classes. | Required |
| BF-STD-8 | Public classes and non-trivial public methods carry an ApexDoc comment explaining *why*, not *what*. | Advisory |

## 3. Architecture (BF-ARCH)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-ARCH-1 | **One trigger per object.** The trigger body is a single line: `new XTriggerHandler().run();`. It declares all seven events so future logic never needs a second trigger. | Blocking |
| BF-ARCH-2 | Trigger handlers extend `TriggerHandler`, override only the needed context methods, and delegate business logic to services. Handlers stay thin. | Required |
| BF-ARCH-3 | All SOQL lives in `*Selector` classes. Services and handlers never write inline queries. | Required |
| BF-ARCH-4 | Know the order of execution. Use before triggers to change the triggering records (no DML). Use after triggers for related records. Field updates that must happen without re-entering triggers use `TriggerHandler.bypass()` and are commented. | Required |
| BF-ARCH-5 | Recursion is controlled by design (only act when `isChanged()` says a relevant field changed), not by static "run once" booleans. | Required |
| BF-ARCH-6 | Errors are handled through `Logger`. Catch specific exceptions, log with context (source, record id), and call `Logger.flush()` at the end of every entry point. Never use an empty `catch` or only `System.debug`. | Blocking for empty catch, Required otherwise |
| BF-ARCH-7 | Configuration (thresholds, paths, sizes, codes) lives in `Bunnyforce_Setting__mdt` and is read through `BunnyforceSettings`. Triggers can be switched off through `Trigger_Setting__mdt`. | Required |
| BF-ARCH-8 | Async work uses Queueable (callouts, chaining) or Batch (large volume). Check `Limits` before enqueueing from trigger context. No `@future` in new code. | Required |

## 4. Non-functional requirements (BF-NFR)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-NFR-1 | **Scale:** code works when 200 records arrive in one trigger invocation and when many users act concurrently. Avoid record locking hotspots, such as many child updates rolling into one parent at once. | Required |
| BF-NFR-2 | **Large data volume:** queries on objects that can grow past 100k rows use selective filters (indexed fields, external IDs, `Id IN :set`). Jobs that touch unbounded sets use Batch Apex. | Required |
| BF-NFR-3 | **Security:** see section 6. | Blocking |
| BF-NFR-4 | **Maintainability:** a future developer can change the code without fear. Behaviour is covered by tests and the intent is documented. | Required |

## 5. Apex best practices (BF-PERF / BF-APEX)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-APEX-1 | **Declarative first.** If a validation rule, formula, roll-up summary, Flow or duplicate rule solves the requirement simply, use it. When choosing Apex, say why in the PR. | Advisory |
| BF-APEX-2 | **No hardcoded IDs** (record, record type, profile, user, queue or price book). Look them up by DeveloperName, query, or `Schema.SObjectType...getRecordTypeInfosByDeveloperName()`. Also no hardcoded URLs or org-specific values. | Blocking |
| BF-PERF-1 | **Bulkify.** No SOQL, SOSL, DML, callouts, `Database.*` or `EventBus.publish` inside loops. Collect IDs into a `Set`, query once, and use a `Map<Id, SObject>` for lookups. | Blocking |
| BF-PERF-2 | Use maps for query results (`new Map<Id, Account>([...])`), not nested loops over lists. | Required |
| BF-PERF-3 | Use the `Limits` class to guard limit-sensitive operations (queueable jobs, callouts, DML rows), and design to stay well below limits. | Required |
| BF-PERF-4 | Query only the fields you need; never use `SELECT` with every field or `FIELDS(ALL)` in production code. Filter in SOQL, not in Apex. | Required |
| BF-PERF-5 | Avoid describe calls and expensive operations inside loops; cache results in static variables when reused. | Required |
| BF-PERF-6 | Partial-success DML (`Database.update(records, false)`) must inspect every `SaveResult` and log failures. | Required |

## 6. Security (BF-SEC)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-SEC-1 | Every class declares sharing explicitly: `with sharing` for user-facing entry points (controllers, REST), `inherited sharing` for services and selectors. `without sharing` needs a code comment and a PR justification. | Blocking |
| BF-SEC-2 | CRUD/FLS are enforced for user-initiated operations: `AccessLevel.USER_MODE`, `WITH USER_MODE`, `as user`, or `Security.stripInaccessible`. `SYSTEM_MODE` is allowed only for automation and must have a comment explaining why. | Blocking |
| BF-SEC-3 | No SOQL injection. Dynamic SOQL uses bind variables (`Database.queryWithBinds`). User input is never concatenated into a query, and `String.escapeSingleQuotes` is a last resort. | Blocking |
| BF-SEC-4 | Callouts use Named Credentials (`callout:Name`). No endpoints, API keys, tokens or passwords in code, custom labels or unprotected custom settings. | Blocking |
| BF-SEC-5 | `@AuraEnabled` and `@RestResource` methods validate input, return friendly errors (`AuraHandledException` with `setMessage`) and never leak stack traces. | Required |
| BF-SEC-6 | Permission changes ship with the metadata. New fields, objects or classes get access in the right permission set (never in profiles). | Required |
| BF-SEC-7 | No `global` access modifier unless required (`@RestResource`, managed packages). | Required |

## 7. Tests (BF-TEST)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-TEST-1 | Each test method verifies one behaviour, named `<scenario><expectedOutcome>` and laid out arrange / act / assert. The checklist's "one assert per method" means one *logical* assertion. Several asserts on the same outcome are fine. | Required |
| BF-TEST-2 | Every test has meaningful assertions using the `Assert` class, with a message. Asserting `true == true`, or only that no exception was thrown, does not count. | Blocking |
| BF-TEST-3 | `@IsTest(SeeAllData=true)` is never allowed. | Blocking |
| BF-TEST-4 | Test data comes from `TestDataFactory`. Add factory methods rather than building records inline. | Required |
| BF-TEST-5 | Trigger and service tests include a bulk case with 200 records. | Required |
| BF-TEST-6 | Positive, negative and permission paths are covered. User-facing code is tested with `System.runAs` a user holding the relevant permission set. | Required |
| BF-TEST-7 | Callouts are tested with `HttpCalloutMock`, and collaborators are faked through `Application.setMock`. Tests never depend on org data or real endpoints. | Required |
| BF-TEST-8 | Async code is exercised inside `Test.startTest()` / `Test.stopTest()`. | Required |
| BF-TEST-9 | Aim for 100% coverage of new code. Coverage without assertions is not coverage. | Advisory |

## 8. Object-oriented design (BF-OO)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-OO-1 | Separation of concerns: trigger, then handler, then service, then selector. Pure rules such as `CreditPolicy` and `CustomerTierCalculator` have no SOQL or DML. | Required |
| BF-OO-2 | DRY: extract shared logic instead of copying it. | Required |
| BF-OO-3 | Single responsibility: one reason to change per class and method. | Required |
| BF-OO-4 | Open/closed: extend behaviour through new implementations, such as a new `IPricingService`, rather than growing conditionals in existing classes. | Advisory |
| BF-OO-5 | Dependency inversion: depend on interfaces for external collaborators (callouts, pricing) and resolve them through `Application.newInstance()` so they can be injected in tests. | Required |

## 9. Static analysis and tooling (BF-TOOL)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-TOOL-1 | PMD (`config/pmd/apex-ruleset.xml`) runs on every PR, in CodeRabbit and in the `static-analysis` workflow. New violations must be fixed. Suppress with `@SuppressWarnings('PMD.RuleName')` only with a comment explaining why. | Required |
| BF-TOOL-2 | Gearset validation (deploy check plus `RunLocalTests`) must pass before merge. | Blocking |

## 10. Integration (BF-INT)

| ID | Rule | Severity |
| --- | --- | --- |
| BF-INT-1 | Outbound callouts go through an interface-backed client (`IFulfillmentClient`). Each callout sets a timeout, handles non-2xx responses explicitly, and sends an idempotency key where the provider supports one. | Required |
| BF-INT-2 | Callouts are never made from trigger context directly. Enqueue a Queueable that implements `Database.AllowsCallouts`. Make every callout before any DML in a transaction. | Blocking |
| BF-INT-3 | Inbound APIs authenticate through an integration user with a least-privilege permission set, validate payloads, and return correct HTTP status codes. | Required |
| BF-INT-4 | A failure for one record must not fail the whole batch. Capture it per record, log it, and set a status the business can act on. | Required |

## 11. Clean code

- Code is easy to read, maintain and change without fear of breaking something.
- Prefer clear names over comments; use comments for *why*.
- Don't put several operations on one line or write clever one-liners.
- Leave the code better than you found it, without mixing large refactors into feature PRs.
