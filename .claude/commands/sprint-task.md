---
description: Pull next task from current sprint and start it
argument-hint: [sprint number, default 1]
---
Sprint: ${ARGUMENTS:-1}

1. Read @docs/roadmap.md → find Sprint $ARGUMENTS section
2. Read @docs/Capitalo_GDD.md §13.$ARGUMENTS for sprint detail
3. List unchecked deliverables `[ ]` from that sprint
4. Pick **smallest deliverable that unblocks others** (not biggest)
5. Print: chosen task + reasoning (1 sentence)
6. **WAIT** for user "go" or alternative pick
7. On approval → invoke `/feature <task>` workflow

Do NOT modify roadmap.md until task is committed.
