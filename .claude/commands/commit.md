---
description: Stage changes and commit with Conventional Commit message
allowed-tools: Bash(git add:*), Bash(git commit:*), Bash(git diff:*), Bash(git status:*), Bash(git log:*)
---
!`git status`
!`git diff --cached`
!`git diff`
!`git log -5 --oneline`

Generate Conventional Commit message:
- Subject in **English**, ≤50 chars, imperative ("add X", "fix Y")
- Type: feat / fix / chore / refactor / docs / test / perf
- Scope OK if helpful: `feat(economy): ...`, `fix(savesystem): ...`
- Body in PL OK, only when "why" is non-obvious
- NO Claude Code attribution footer
- NO emojis

Then run `git add -A` (only if user confirmed staging is OK), then commit with HEREDOC.
