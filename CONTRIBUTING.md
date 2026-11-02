# Contributing

## Branching

- Branch from `main`: `feature/<ticket>-<short-name>`, `fix/<ticket>-<short-name>`, or `hotfix/<short-name>`.
- Open a pull request against the pipeline's integration branch (`main` until Gearset environment branches are added).
- Use [Conventional Commits](https://www.conventionalcommits.org/) titles: `feat(pricing): add volume break for pellets`.

## Before opening a PR

1. `npm run prettier` and `npm run lint`.
2. `npm run scan`. Fix every PMD violation you introduce.
3. Run the Apex tests in your dev org or scratch org: `npm run test:apex`.
4. Fill in every section of the PR template, especially **Why code (not clicks)?** and **Deployment notes**.

## Review

- CodeRabbit reviews every PR automatically against [docs/apex-standards.md](docs/apex-standards.md).
  Blocking pre-merge checks must pass. Resolve or reply to every CodeRabbit comment.
- Gearset validation must pass (deployment plus `RunLocalTests`).
- At least one approval from a code owner (see `.github/CODEOWNERS`).
- To ask CodeRabbit questions, comment `@coderabbitai` on the PR. When a review comment doesn't fit
  this codebase, reply with the reason so CodeRabbit records a learning.

## Coding standards

Everything is in [docs/apex-standards.md](docs/apex-standards.md). The short version:

- One trigger per object; logic lives in handlers and services.
- SOQL only in selectors; nothing inside loops; always bulk-safe for 200 records.
- Declare sharing on every class. Use `USER_MODE` for anything a user triggers directly.
- No hardcoded IDs, endpoints or thresholds. Use custom metadata and Named Credentials.
- Errors go through `Logger`, and every entry point calls `Logger.flush()`.
- Tests use `TestDataFactory`, assert real behaviour, include a bulk case, and never use `SeeAllData=true`.
