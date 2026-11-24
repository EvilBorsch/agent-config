#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DO_CLAUDE=false
DO_CODEX=false
DO_ANTIGRAVITY=false
DO_OPENCODE=false
DO_DETECTED=false
SKIP_EXTERNAL=false
ANY_TARGET=false

usage() {
  cat <<'EOF'
Usage: ./install.sh [options]

Restores global instructions (AGENTS.md / CLAUDE.md), custom skills, plugins,
and CLI configuration for selected CLIs. Each CLI target is self-contained and
does NOT require Claude Code or Codex to be installed on the machine.

Options:
  --detected       Install only for CLIs detected on this machine (default if no target flag is passed)
  --all            Install/restore all 4 CLIs
  --claude         Restore Claude Code config (~/.claude)
  --codex          Restore Codex CLI config (~/.codex, ~/.agents, ~/plugins)
  --antigravity    Restore Antigravity config (~/.gemini/config)
  --opencode       Restore OpenCode config (~/.config/opencode)
  --skip-external  Skip installing upstream superpowers & impeccable from network
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)
      DO_CLAUDE=true; DO_CODEX=true; DO_ANTIGRAVITY=true; DO_OPENCODE=true; ANY_TARGET=true
      ;;
    --detected) DO_DETECTED=true; ANY_TARGET=true ;;
    --claude) DO_CLAUDE=true; ANY_TARGET=true ;;
    --codex) DO_CODEX=true; ANY_TARGET=true ;;
    --antigravity) DO_ANTIGRAVITY=true; ANY_TARGET=true ;;
    --opencode) DO_OPENCODE=true; ANY_TARGET=true ;;
    --skip-external) SKIP_EXTERNAL=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
  shift
done

if [[ "$ANY_TARGET" == "false" ]]; then
  DO_DETECTED=true
fi

log() { printf '\n==> %s\n' "$*"; }

detect_clis() {
  if command -v claude >/dev/null 2>&1 || [[ -d "$HOME/.claude" ]]; then
    DO_CLAUDE=true
  fi
  if command -v codex >/dev/null 2>&1 || [[ -d "$HOME/.codex" ]]; then
    DO_CODEX=true
  fi
  if command -v agy >/dev/null 2>&1 || command -v antigravity >/dev/null 2>&1 || [[ -d "$HOME/.gemini/config" ]] || [[ -d "$HOME/.gemini/antigravity" ]]; then
    DO_ANTIGRAVITY=true
  fi
  if command -v opencode >/dev/null 2>&1 || [[ -d "$HOME/.config/opencode" ]]; then
    DO_OPENCODE=true
  fi

  if [[ "$DO_CLAUDE" == "false" && "$DO_CODEX" == "false" && "$DO_ANTIGRAVITY" == "false" && "$DO_OPENCODE" == "false" ]]; then
    echo "No supported CLIs detected. Pass explicit flags, e.g.: ./install.sh --antigravity --opencode" >&2
    exit 1
  fi
}

if [[ "$DO_DETECTED" == "true" ]]; then
  detect_clis
fi

run_impeccable_install() {
  local providers="$1"
  local bin=""
  if command -v impeccable >/dev/null 2>&1; then
    bin="$(command -v impeccable)"
  elif [[ -d "$HOME/.impeccable/bin" ]]; then
    bin="$(find "$HOME/.impeccable/bin" -maxdepth 2 -type f -name impeccable -perm -u+x 2>/dev/null | sort -V | tail -n 1 || true)"
  fi

  if [[ -n "$bin" ]]; then
    "$bin" install --providers="$providers" --global --yes --force
  elif command -v npx >/dev/null 2>&1; then
    npx -y impeccable install --providers="$providers" --global --yes --force
  else
    echo "WARN: neither impeccable nor npx found; install impeccable manually for providers=$providers" >&2
  fi
}

install_claude() {
  log "Restoring Claude Code (~/.claude)"
  mkdir -p "$HOME/.claude/skills/code-review"
  cp "$REPO_DIR/instructions/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  cp "$REPO_DIR/skills/code-review/SKILL.md" "$HOME/.claude/skills/code-review/SKILL.md"

  python3 - "$REPO_DIR/claude/settings.template.json" "$HOME/.claude/settings.json" <<'PY'
import json, os, sys

tpl_path, dst_path = sys.argv[1], sys.argv[2]
with open(tpl_path, "r", encoding="utf-8") as f:
    tpl = json.load(f)

if os.path.exists(dst_path):
    with open(dst_path, "r", encoding="utf-8") as f:
        cur = json.load(f)
else:
    cur = {}

for key, val in tpl.items():
    if isinstance(val, dict) and isinstance(cur.get(key), dict):
        merged = dict(cur[key])
        merged.update(val)
        cur[key] = merged
    else:
        cur[key] = val

os.makedirs(os.path.dirname(dst_path), exist_ok=True)
with open(dst_path, "w", encoding="utf-8") as f:
    json.dump(cur, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

  if [[ "$SKIP_EXTERNAL" == "false" ]]; then
    if command -v claude >/dev/null 2>&1; then
      claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
      claude plugin install superpowers@claude-plugins-official --scope user 2>/dev/null || true
    else
      echo "WARN: claude CLI not found on PATH; enable superpowers@claude-plugins-official after installing Claude Code" >&2
    fi
    run_impeccable_install "claude"
  fi
}

install_codex() {
  log "Restoring Codex CLI (~/.codex, ~/.agents, ~/plugins)"
  mkdir -p "$HOME/.codex" "$HOME/.agents/plugins" "$HOME/.agents/skills" "$HOME/plugins"

  cp "$REPO_DIR/instructions/AGENTS.md" "$HOME/.codex/AGENTS.md"

  rm -rf "$HOME/plugins/made-code-review"
  cp -R "$REPO_DIR/codex/plugins/made-code-review" "$HOME/plugins/made-code-review"

  python3 - "$REPO_DIR/codex/plugins/marketplace.json" "$HOME/.agents/plugins/marketplace.json" <<'PY'
import json, os, sys

src_path, dst_path = sys.argv[1], sys.argv[2]
with open(src_path, "r", encoding="utf-8") as f:
    src = json.load(f)

if os.path.exists(dst_path):
    with open(dst_path, "r", encoding="utf-8") as f:
        cur = json.load(f)
    existing = {p.get("name"): p for p in cur.get("plugins", []) if isinstance(p, dict)}
    for p in src.get("plugins", []):
        existing[p["name"]] = p
    cur["plugins"] = list(existing.values())
    out = cur
else:
    out = src

with open(dst_path, "w", encoding="utf-8") as f:
    json.dump(out, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

  python3 - "$REPO_DIR/codex/config.snippet.toml" "$HOME/.codex/config.toml" <<'PY'
import os, re, sys

snippet_path, dst_path = sys.argv[1], sys.argv[2]
if not os.path.exists(dst_path):
    with open(snippet_path, "r", encoding="utf-8") as f:
        content = f.read()
    with open(dst_path, "w", encoding="utf-8") as f:
        f.write(content)
    sys.exit(0)

with open(dst_path, "r", encoding="utf-8") as f:
    text = f.read()

desired_plugins = [
    ("made-code-review@personal", "true"),
    ("superpowers@openai-curated", "false"),
    ("superpowers@openai-curated-remote", "false"),
]

for plugin_id, enabled in desired_plugins:
    header = f'[plugins."{plugin_id}"]'
    pattern = re.compile(rf'(?ms)^\[plugins\."{re.escape(plugin_id)}"\]\n(.*?)(?=^\[|\Z)')
    m = pattern.search(text)
    if m:
        body = m.group(1)
        if re.search(r'(?m)^enabled\s*=', body):
            new_body = re.sub(r'(?m)^enabled\s*=.*$', f'enabled = {enabled}', body)
        else:
            new_body = f'enabled = {enabled}\n' + body
        text = text[:m.start(1)] + new_body + text[m.end(1):]
    else:
        if text and not text.endswith("\n"):
            text += "\n"
        text += f"\n{header}\nenabled = {enabled}\n"

with open(dst_path, "w", encoding="utf-8") as f:
    f.write(text)
PY

  if [[ "$SKIP_EXTERNAL" == "false" ]]; then
    local tmp_sp
    tmp_sp="$(mktemp -d)"
    trap 'rm -rf "$tmp_sp"' RETURN
    git clone --depth 1 https://github.com/obra/superpowers.git "$tmp_sp/superpowers"
    rm -rf "$HOME/.agents/skills/superpowers"
    mkdir -p "$HOME/.agents/skills/superpowers"
    cp -R "$tmp_sp/superpowers/skills/." "$HOME/.agents/skills/superpowers/"
    rm -rf "$tmp_sp"
    trap - RETURN

    run_impeccable_install "codex"
  fi
}

install_antigravity() {
  log "Restoring Antigravity (~/.gemini/config)"
  mkdir -p "$HOME/.gemini/config/plugins" "$HOME/.gemini/config/skills"

  # Если Claude Code установлен на этой машине, шарим общий CLAUDE.md и ~/.claude/skills;
  # иначе ставим всё автономно внутрь ~/.gemini/config без создания ~/.claude.
  if [[ "$DO_CLAUDE" == "true" || -f "$HOME/.claude/CLAUDE.md" ]]; then
    ln -sfn "$HOME/.claude/CLAUDE.md" "$HOME/.gemini/config/AGENTS.md"
  else
    cp "$REPO_DIR/instructions/AGENTS.md" "$HOME/.gemini/config/AGENTS.md"
  fi

  if [[ "$DO_CLAUDE" == "true" || -f "$HOME/.claude/skills/code-review/SKILL.md" ]]; then
    python3 - "$REPO_DIR/antigravity/skills.json" "$HOME/.gemini/config/skills.json" <<'PY'
import os, sys

src_path, dst_path = sys.argv[1], sys.argv[2]
with open(src_path, "r", encoding="utf-8") as f:
    content = f.read().replace("$HOME", os.path.expanduser("~"))
with open(dst_path, "w", encoding="utf-8") as f:
    f.write(content)
PY
  else
    mkdir -p "$HOME/.gemini/config/skills/code-review"
    cp "$REPO_DIR/skills/code-review/SKILL.md" "$HOME/.gemini/config/skills/code-review/SKILL.md"
  fi

  if [[ "$SKIP_EXTERNAL" == "false" ]]; then
    local sp_dir="$HOME/.gemini/config/plugins/superpowers"
    if [[ -d "$sp_dir/.git" ]]; then
      git -C "$sp_dir" pull --ff-only || true
    else
      rm -rf "$sp_dir"
      git clone --depth 1 https://github.com/obra/superpowers.git "$sp_dir"
    fi
    cp "$REPO_DIR/antigravity/superpowers-plugin.json" "$sp_dir/plugin.json"
    mkdir -p "$sp_dir/rules"
    cp "$REPO_DIR/antigravity/superpowers-rules-AGENTS.md" "$sp_dir/rules/AGENTS.md"

    run_impeccable_install "antigravity"
  fi
}

install_opencode() {
  log "Restoring OpenCode (~/.config/opencode)"
  mkdir -p "$HOME/.config/opencode"

  # Если Claude Code установлен на этой машине, шарим общий CLAUDE.md и ~/.claude/skills;
  # иначе копируем AGENTS.md и code-review напрямую в ~/.config/opencode.
  if [[ "$DO_CLAUDE" == "true" || -f "$HOME/.claude/CLAUDE.md" ]]; then
    ln -sfn "$HOME/.claude/CLAUDE.md" "$HOME/.config/opencode/AGENTS.md"
  else
    cp "$REPO_DIR/instructions/AGENTS.md" "$HOME/.config/opencode/AGENTS.md"
  fi

  if [[ "$DO_CLAUDE" != "true" && ! -f "$HOME/.claude/skills/code-review/SKILL.md" ]]; then
    mkdir -p "$HOME/.config/opencode/skills/code-review"
    cp "$REPO_DIR/skills/code-review/SKILL.md" "$HOME/.config/opencode/skills/code-review/SKILL.md"
  fi

  # Мержим базовые настройки OpenCode (plugin, compaction), не затрагивая локальных провайдеров.
  python3 - "$REPO_DIR/opencode/opencode.json" "$HOME/.config/opencode/opencode.json" <<'PY'
import json, os, sys

src_path, dst_path = sys.argv[1], sys.argv[2]
with open(src_path, "r", encoding="utf-8") as f:
    tpl = json.load(f)

if os.path.exists(dst_path):
    with open(dst_path, "r", encoding="utf-8") as f:
        cur = json.load(f)
else:
    cur = {}

if "$schema" not in cur and "$schema" in tpl:
    cur["$schema"] = tpl["$schema"]

cur_plugins = cur.get("plugin") if isinstance(cur.get("plugin"), list) else []
for p in tpl.get("plugin", []):
    if p not in cur_plugins:
        cur_plugins.append(p)
cur["plugin"] = cur_plugins

if "compaction" in tpl:
    comp = cur.get("compaction") if isinstance(cur.get("compaction"), dict) else {}
    comp.update(tpl["compaction"])
    cur["compaction"] = comp

with open(dst_path, "w", encoding="utf-8") as f:
    json.dump(cur, f, indent=2, ensure_ascii=False)
    f.write("\n")
PY

  if [[ "$SKIP_EXTERNAL" == "false" ]]; then
    # Если Codex уже ставит ~/.agents/skills/impeccable, OpenCode подхватит его оттуда;
    # иначе ставим нативно в ~/.config/opencode (без создания ~/.codex).
    if [[ "$DO_CODEX" == "false" && ! -d "$HOME/.agents/skills/impeccable" ]]; then
      run_impeccable_install "opencode"
    fi
  fi
}

[[ "$DO_CLAUDE" == "true" ]] && install_claude
[[ "$DO_CODEX" == "true" ]] && install_codex
[[ "$DO_ANTIGRAVITY" == "true" ]] && install_antigravity
[[ "$DO_OPENCODE" == "true" ]] && install_opencode

log "Done! Remember to configure API keys/OAuth logins for each configured CLI (see README.md)."
