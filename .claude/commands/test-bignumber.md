---
description: Run BigNumber unit tests headless
allowed-tools: Bash(godot --headless:*), Read
---
!`godot --headless --quit-after 5 --script tests/BigNumberTest.gd 2>&1 | tail -50`

Interpret output:
- 🟢 if you see `✓ All tests passed!` (12 groups expected)
- 🔴 quote first failing assertion + line number
- If `godot` not in PATH or version mismatch — report exact error, do not retry
