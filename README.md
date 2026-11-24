# Agent CLI Config (Claude Code, Codex, Antigravity, OpenCode)

Personal dotfiles repository for restoring global instructions (`AGENTS.md` / `CLAUDE.md`), custom skills, plugins, and general CLI settings across **Claude Code**, **Codex CLI**, **Antigravity**, and **OpenCode**.

The **Claude Code** setup defines the canonical feature set; Codex, Antigravity, and OpenCode are kept in parity with it, **but each CLI target is completely standalone** — you can restore any subset on a machine where Claude Code or Codex is not installed. Built-in/bundled skills and secrets are intentionally excluded.

## Instructions for AI Agents

When the user hands you this repository to configure a machine:

1. **Configure only what the user asked for.** Do not assume all 4 CLIs are installed — on another machine Claude Code, Codex (GPT), Antigravity, or OpenCode may be absent.
2. If the user named specific CLIs (e.g. "настрой только Antigravity и OpenCode"), pass only those flags (`./install.sh --antigravity --opencode`).
3. If the user didn't specify which CLIs, run `./install.sh --detected` (auto-detects installed CLIs) or check what is installed and ask the user which ones to configure.
4. **Never create `~/.claude` or `~/.codex` on a machine where those CLIs are not requested/installed** — `./install.sh` handles this automatically (copies `AGENTS.md` and `code-review` directly into the requested CLI's own config directory).
5. **Antigravity prerequisite:** Google Antigravity (Desktop/IDE/CLI) works only with **[EvilBorsch/agfix](https://github.com/EvilBorsch/agfix)** applied (and VPN enabled). Set up `agfix` first if setting up Antigravity on a fresh machine.

---

## What is included

| Component | Source | Claude Code | Codex CLI | Antigravity | OpenCode |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Global instructions | `instructions/AGENTS.md` | `~/.claude/CLAUDE.md` | `~/.codex/AGENTS.md` | `~/.gemini/config/AGENTS.md` (copy, or symlink if Claude exists) | `~/.config/opencode/AGENTS.md` (copy, or symlink if Claude exists) |
| `code-review` skill | `skills/code-review/` | `~/.claude/skills/code-review/` | `~/plugins/made-code-review` (`made-code-review@personal`) | `~/.gemini/config/skills/code-review/` (or via `skills.json` if Claude exists) | `~/.config/opencode/skills/code-review/` (or auto-loaded from `~/.claude/skills/`) |
| `superpowers` | `obra/superpowers` | `superpowers@claude-plugins-official` | `~/.agents/skills/superpowers/` (local copy; curated remote disabled) | `~/.gemini/config/plugins/superpowers/` + Antigravity tool-mapping rule | `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]` |
| `impeccable` | `pbakaus/impeccable` | `~/.claude/skills/impeccable/` + agents + hooks | `~/.agents/skills/impeccable/` + `~/.codex/hooks.json` | `~/.gemini/config/skills/impeccable/` + `~/.gemini/config/hooks.json` | `~/.config/opencode/skills/impeccable/` + command (or `~/.agents/skills/impeccable/` if Codex exists) |
| CLI settings & plugins | per-CLI dirs | `claude/settings.template.json` | `codex/config.snippet.toml` | `antigravity/skills.json` | `opencode/opencode.json` (plugins & compaction only, no providers) |

### Intentionally excluded
- Built-in/bundled skills & plugins (`~/.claude/skills/synced`, `~/.codex/skills/.system`, `openai-bundled`, `openai-primary-runtime`, `openai-curated/github`, disabled `hatch-pet`, Antigravity `builtin/*`).
- Custom/work providers (OpenCode providers & provider-compat plugins are intentionally excluded; existing local providers in `~/.config/opencode/opencode.json` are preserved on merge).
- Work-only skills and all credentials, OAuth tokens, cookies, API keys (`auth.json`, `oauth_creds.json`).
- Session history, SQLite databases, caches, and machine-specific trusted folder lists.

---

## Quick Restore

```bash
chmod +x ./install.sh

# Auto-detect installed CLIs on this machine (default):
./install.sh --detected

# Or pick only what the user asked for:
./install.sh --claude
./install.sh --codex
./install.sh --antigravity
./install.sh --opencode
./install.sh --antigravity --opencode

# Or restore all 4 regardless of what is currently installed:
./install.sh --all
```

Use `--skip-external` to copy only local files from this repo without fetching `obra/superpowers` or `impeccable` from the network.

---

## Manual / Selective Agent Instructions

Each CLI section below works independently (no need to set up Claude Code or Codex first).

### 1. Claude Code (`~/.claude`)
1. Copy `instructions/AGENTS.md` → `~/.claude/CLAUDE.md`.
2. Copy `skills/code-review/SKILL.md` → `~/.claude/skills/code-review/SKILL.md`.
3. Merge `claude/settings.template.json` into `~/.claude/settings.json` (preserving any existing `hooks` or local settings).
4. Install `superpowers`:
   ```bash
   claude plugin marketplace add obra/superpowers-marketplace
   claude plugin install superpowers@claude-plugins-official --scope user
   ```
5. Install `impeccable` (skills, agents, hooks):
   ```bash
   npx -y impeccable install --providers=claude --global --yes --force
   ```

### 2. Codex CLI (`~/.codex`, `~/.agents`, `~/plugins`)
1. Copy `instructions/AGENTS.md` → `~/.codex/AGENTS.md`.
2. Install local `made-code-review` plugin:
   - Copy `codex/plugins/made-code-review` → `~/plugins/made-code-review`.
   - Merge `codex/plugins/marketplace.json` → `~/.agents/plugins/marketplace.json`.
   - Ensure `[plugins."made-code-review@personal"] enabled = true` in `~/.codex/config.toml`.
3. Install `superpowers` locally (avoids remote catalog discovery bug):
   - Clone `https://github.com/obra/superpowers.git` and copy its `skills/*` into `~/.agents/skills/superpowers/`.
   - Set `[plugins."superpowers@openai-curated"] enabled = false` and `[plugins."superpowers@openai-curated-remote"] enabled = false` in `~/.codex/config.toml`.
4. Optionally apply preferences from `codex/config.snippet.toml` to `~/.codex/config.toml`.
5. Install `impeccable`:
   ```bash
   npx -y impeccable install --providers=codex --global --yes --force
   ```

### 3. Antigravity (`~/.gemini/config`)

> **Important:** Google Antigravity (Desktop/IDE/CLI) requires **[EvilBorsch/agfix](https://github.com/EvilBorsch/agfix)** (plus VPN) to work. If setting up Antigravity on a fresh machine, install and apply `agfix` first following its README.

1. Instructions:
   - If Claude Code is installed: symlink `~/.gemini/config/AGENTS.md` → `~/.claude/CLAUDE.md`.
   - Otherwise: copy `instructions/AGENTS.md` → `~/.gemini/config/AGENTS.md`.
2. `code-review` skill:
   - If Claude Code is installed: copy `antigravity/skills.json` → `~/.gemini/config/skills.json`, replacing `$HOME` with the user's actual home directory path.
   - Otherwise: copy `skills/code-review/SKILL.md` → `~/.gemini/config/skills/code-review/SKILL.md`.
3. Install `superpowers` plugin:
   - Clone `https://github.com/obra/superpowers.git` → `~/.gemini/config/plugins/superpowers/`.
   - Copy `antigravity/superpowers-plugin.json` → `~/.gemini/config/plugins/superpowers/plugin.json`.
   - Copy `antigravity/superpowers-rules-AGENTS.md` → `~/.gemini/config/plugins/superpowers/rules/AGENTS.md`.
4. Install `impeccable`:
   ```bash
   npx -y impeccable install --providers=antigravity --global --yes --force
   ```

### 4. OpenCode (`~/.config/opencode`)
1. Instructions:
   - If Claude Code is installed: symlink `~/.config/opencode/AGENTS.md` → `~/.claude/CLAUDE.md`.
   - Otherwise: copy `instructions/AGENTS.md` → `~/.config/opencode/AGENTS.md`.
2. `code-review` skill:
   - If Claude Code is not installed: copy `skills/code-review/SKILL.md` → `~/.config/opencode/skills/code-review/SKILL.md`. (If Claude Code is installed, OpenCode auto-loads `~/.claude/skills/`.)
3. Merge `opencode/opencode.json` (`plugin` and `compaction`) into `~/.config/opencode/opencode.json` without overwriting any local `provider` / `model` config.
4. `superpowers` is loaded automatically via `"plugin": ["superpowers@git+https://github.com/obra/superpowers.git"]` in `opencode.json`.
5. Install `impeccable` (skip if Codex already installed `~/.agents/skills/impeccable/`):
   ```bash
   npx -y impeccable install --providers=opencode --global --yes --force
   ```

---

## Post-Restore Credentials Checklist

Secrets and providers are not stored in this repository. After restoring, configure only what applies to the installed CLIs:

1. **Claude Code / Codex / Antigravity**: sign in normally via each CLI's login flow.
2. **OpenCode**: configure your preferred providers/keys locally via `opencode auth` and `~/.config/opencode/opencode.json`.

---

## Verification

Run only the checks for the CLIs you configured:

```bash
# Instructions (check whichever CLI was configured)
ls -la ~/.claude/CLAUDE.md ~/.codex/AGENTS.md ~/.gemini/config/AGENTS.md ~/.config/opencode/AGENTS.md 2>/dev/null

# OpenCode config check
opencode debug config >/dev/null && echo "opencode config OK"
```
