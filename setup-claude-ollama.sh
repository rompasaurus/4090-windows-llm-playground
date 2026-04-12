#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────
# setup-claude-ollama.sh
# Connect Claude Code CLI to a remote Ollama instance running Gemma 4
# Remote host: 100.106.112.113 (Tailscale)
# ─────────────────────────────────────────────────────────────────────

set -euo pipefail

REMOTE_IP="100.106.112.113"
OLLAMA_PORT="11434"
OLLAMA_URL="http://${REMOTE_IP}:${OLLAMA_PORT}"
MODEL="gemma4"

# ─── ANSI Colours ───────────────────────────────────────────────────
RESET="\033[0m"
BOLD="\033[1m"
GREEN="\033[92m"
RED="\033[91m"
CYAN="\033[96m"
YELLOW="\033[93m"

info()  { echo -e "${CYAN}${BOLD}[INFO]${RESET}  $*"; }
ok()    { echo -e "${GREEN}${BOLD}[OK]${RESET}    $*"; }
warn()  { echo -e "${YELLOW}${BOLD}[WARN]${RESET}  $*"; }
fail()  { echo -e "${RED}${BOLD}[FAIL]${RESET}  $*"; exit 1; }

# ─── Preflight checks ──────────────────────────────────────────────
info "Checking prerequisites..."

if ! command -v claude &>/dev/null; then
    fail "Claude Code CLI not found. Install it first: npm install -g @anthropic-ai/claude-code"
fi
ok "Claude Code CLI found"

# ─── Test remote Ollama connectivity ────────────────────────────────
info "Testing connection to Ollama at ${OLLAMA_URL}..."

if ! curl -sf --connect-timeout 5 "${OLLAMA_URL}/api/tags" &>/dev/null; then
    fail "Cannot reach Ollama at ${OLLAMA_URL}. Make sure:\n  1. Ollama is running on the remote machine\n  2. It's bound to 0.0.0.0 (OLLAMA_HOST=0.0.0.0 ollama serve)\n  3. Port ${OLLAMA_PORT} is accessible via Tailscale"
fi
ok "Ollama is reachable"

# ─── Check if model is available ────────────────────────────────────
info "Checking if ${MODEL} is available on remote..."

MODELS=$(curl -sf "${OLLAMA_URL}/api/tags" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for m in data.get('models', []):
    print(m['name'])
" 2>/dev/null || echo "")

if echo "$MODELS" | grep -qi "${MODEL}"; then
    ok "${MODEL} is available on remote"
else
    warn "${MODEL} not found on remote. Available models:"
    echo "$MODELS" | sed 's/^/    /'
    echo ""
    read -rp "Pull ${MODEL} on the remote? (y/N) " answer
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        info "Pulling ${MODEL} on remote (this may take a while)..."
        curl -sf "${OLLAMA_URL}/api/pull" -d "{\"name\": \"${MODEL}\"}" | while read -r line; do
            status=$(echo "$line" | python3 -c "import sys,json; print(json.load(sys.stdin).get('status',''))" 2>/dev/null)
            [[ -n "$status" ]] && echo -e "    ${DIM:-}${status}${RESET}"
        done
        ok "${MODEL} pulled successfully"
    else
        fail "Model ${MODEL} is required. Pull it on the remote first: ollama pull ${MODEL}"
    fi
fi

# ─── Export environment variables ───────────────────────────────────
info "Setting environment variables..."

export ANTHROPIC_BASE_URL="${OLLAMA_URL}"
export ANTHROPIC_AUTH_TOKEN="ollama"
export ANTHROPIC_API_KEY="ollama"

ok "ANTHROPIC_BASE_URL=${OLLAMA_URL}"
ok "ANTHROPIC_AUTH_TOKEN=ollama"

# ─── Launch Claude Code ────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}=========================================${RESET}"
echo -e "${GREEN}${BOLD} Launching Claude Code with ${MODEL}${RESET}"
echo -e "${GREEN}${BOLD} Remote: ${OLLAMA_URL}${RESET}"
echo -e "${GREEN}${BOLD}=========================================${RESET}"
echo ""

claude --model "${MODEL}"
