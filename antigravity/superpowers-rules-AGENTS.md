---
trigger: always_on
description: Core Superpowers workflow activation and Antigravity CLI tool mapping.
---

# Superpowers (Antigravity CLI)

You have the **superpowers** plugin installed. Before starting any task (including clarifying questions), check whether any of the installed superpowers skills apply (`brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`, `test-driven-development`, `systematic-debugging`, `verification-before-completion`, `requesting-code-review`, `receiving-code-review`, `dispatching-parallel-agents`, `using-git-worktrees`, `finishing-a-development-branch`, `writing-skills`). If there is even a 1% chance a skill applies, read its `SKILL.md` with `read_file` and follow it.

User instructions (`AGENTS.md`, `GEMINI.md`, direct user requests) always take precedence over skill instructions when they conflict (for example, local-only git restrictions override worktree/commit steps in skills).

## Antigravity CLI Tool Mapping

Superpowers skills use Claude Code tool names. Map them to Antigravity CLI equivalents:

| Claude Code reference | Antigravity CLI equivalent |
| :--- | :--- |
| `Skill` tool (invoke a skill) | `read_file` on the skill's `SKILL.md` |
| `Read` | `read_file` |
| `Write` | `write_file` |
| `Edit` | `edit_file` |
| `Bash` | `run_command` |
| `Grep` / `Glob` | `run_command` (`rg` / `find`) or workspace search tools |
| `Task` / `Agent` (subagents) | `invoke_subagent` (and `define_subagent` / `send_message`) |
| `AskUserQuestion` | `ask_question` |
| `WebSearch` | `search_web` |
| `TodoWrite` | Track checklist in conversation or an artifact file |
