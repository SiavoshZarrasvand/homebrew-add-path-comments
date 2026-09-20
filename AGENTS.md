# Agent Instructions: homebrew-add-path-comments

## House rules: read first

Read `../../agent-docs/AGENTS.md` before starting any work. It is the shared foundation across all repos: conventions (commit messages, how work lands, local CI) expected to be followed, plus templates for build plans, beads, and reviews.

Add-Path-Comments specific overrides & details:
- **Stack**: Standalone Python 3 CLI executable + Homebrew Ruby formula (`Formula/add-path-comments.rb`).
- **Releases**: Managed via `./release.sh`, which auto-increments version, tags git commit, fetches tarball SHA256, and updates `Formula/add-path-comments.rb`.
- **Landing work**: Per `../../agent-docs/conventions/landing-work.md`, work on branches, verify tests pass, then merge locally.
- **Issue tracking**: Beads only (`bd`).
