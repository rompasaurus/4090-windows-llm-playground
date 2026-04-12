#!/usr/bin/env bash
# =============================================================================
# OpenCode MCP Full Setup Script for CachyOS (Arch-based)
# =============================================================================
# Installs all dependencies and MCP servers to bring OpenCode as close to
# Claude Code capability as possible on a local Gemma 4 26B setup.
#
# What this script does:
#   1. Installs system packages (node, npm, python, uv, git, ripgrep, docker)
#   2. Pre-caches all npx-based MCP servers so first launch isn't slow
#   3. Installs all uvx/pip-based MCP servers
#   4. Installs Playwright browsers
#   5. Installs optional tools (semgrep, eslint, gh CLI, dbhub)
#   6. Creates directory structure (~/.opencode/)
#   7. Writes the full opencode.json config
#   8. Writes a .env template for API keys
#   9. Verifies everything works
#
# Usage:
#   chmod +x setup-opencode-mcp.sh
#   ./setup-opencode-mcp.sh
#
# Safe to re-run — idempotent where possible.
# =============================================================================

set -euo pipefail

# -- Colors -------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; }
section() { echo -e "\n${BOLD}${CYAN}=== $* ===${NC}\n"; }

# -- Config -------------------------------------------------------------------
OPENCODE_DIR="$HOME/.opencode"
MEMORY_FILE="$OPENCODE_DIR/memory.jsonl"
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
OPENCODE_JSON="$PROJECT_DIR/opencode.json"
ENV_FILE="$PROJECT_DIR/.env.opencode"

# Tailscale IP of the 4090 Ollama host
OLLAMA_BASE_URL="http://100.84.60.92:11434/v1"

# =============================================================================
# 1. SYSTEM PACKAGES
# =============================================================================
section "1/9 — System Packages"

install_if_missing() {
    local cmd="$1"
    local pkg="${2:-$1}"
    if command -v "$cmd" &>/dev/null; then
        success "$cmd already installed ($(command -v "$cmd"))"
    else
        info "Installing $pkg..."
        sudo pacman -S --noconfirm --needed "$pkg"
        success "$pkg installed"
    fi
}

# Update package database
info "Updating pacman database..."
sudo pacman -Sy --noconfirm

# Core dependencies
install_if_missing "node"    "nodejs"
install_if_missing "npm"     "npm"
install_if_missing "python"  "python"
install_if_missing "pip"     "python-pip"
install_if_missing "git"     "git"
install_if_missing "rg"      "ripgrep"
install_if_missing "jq"      "jq"
install_if_missing "curl"    "curl"

# Docker (for GitHub MCP server)
if command -v docker &>/dev/null; then
    success "docker already installed"
else
    info "Installing docker..."
    sudo pacman -S --noconfirm --needed docker
    sudo systemctl enable --now docker.service
    # Add user to docker group so we don't need sudo
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        warn "Added $USER to docker group — you may need to log out and back in"
    fi
    success "docker installed and enabled"
fi

# GitHub CLI
if command -v gh &>/dev/null; then
    success "gh (GitHub CLI) already installed"
else
    info "Installing GitHub CLI..."
    sudo pacman -S --noconfirm --needed github-cli
    success "gh installed"
fi

# =============================================================================
# 2. PYTHON TOOLING (uv / uvx)
# =============================================================================
section "2/9 — Python Package Manager (uv)"

if command -v uv &>/dev/null; then
    success "uv already installed ($(uv --version))"
else
    info "Installing uv via the official installer..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # Source the env so uv is available in this session
    export PATH="$HOME/.local/bin:$PATH"
    success "uv installed ($(uv --version))"
fi

# Make sure uvx is available (it ships with uv)
if command -v uvx &>/dev/null; then
    success "uvx available"
else
    # uvx is a symlink/alias for 'uv tool run' — ensure PATH is set
    export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"
    if command -v uvx &>/dev/null; then
        success "uvx available after PATH update"
    else
        warn "uvx not found — will use 'uv tool run' as fallback"
    fi
fi

# =============================================================================
# 3. NPX-BASED MCP SERVERS (pre-cache)
# =============================================================================
section "3/9 — NPX-based MCP Servers (pre-cache)"

# Pre-installing these so the first opencode launch isn't slow.
# MCP servers are long-running stdio processes — they don't exit on their own.
# We use 'npm cache add' to download without running, which is instant and safe.

NPX_PACKAGES=(
    "@modelcontextprotocol/server-memory"
    "@modelcontextprotocol/server-sequential-thinking"
    "@modelcontextprotocol/server-filesystem"
    "@upstash/context7-mcp@latest"
    "@playwright/mcp@latest"
    "@eslint/mcp@latest"
    "firecrawl-mcp"
)

for pkg in "${NPX_PACKAGES[@]}"; do
    info "Pre-caching $pkg..."
    npm cache add "$pkg" 2>/dev/null || true
    success "$pkg cached"
done

# =============================================================================
# 4. UVX/PIP-BASED MCP SERVERS
# =============================================================================
section "4/9 — Python-based MCP Servers"

PIP_PACKAGES=(
    "duckduckgo-mcp-server"
    "mcp-server-fetch"
    "mcp-server-git"
    "semgrep"
)

for pkg in "${PIP_PACKAGES[@]}"; do
    info "Installing $pkg..."
    # uv tool install downloads and creates a shim without running the server
    uv tool install "$pkg" 2>/dev/null || uv tool upgrade "$pkg" 2>/dev/null || true
    success "$pkg installed/updated"
done

# =============================================================================
# 5. PLAYWRIGHT BROWSER
# =============================================================================
section "5/9 — Playwright Browser Dependencies"

info "Installing Chromium for Playwright..."
npx -y playwright install --with-deps chromium 2>/dev/null || {
    warn "Playwright browser install needs system deps, trying with sudo..."
    # On Arch, playwright may need some system libs
    sudo pacman -S --noconfirm --needed \
        nss \
        at-spi2-core \
        libdrm \
        mesa \
        libxkbcommon \
        libxcomposite \
        libxdamage \
        libxrandr \
        libgbm \
        pango \
        cairo \
        alsa-lib \
        2>/dev/null || true
    npx -y playwright install chromium 2>/dev/null || warn "Playwright chromium may need manual install"
}
success "Playwright browsers ready"

# =============================================================================
# 6. OPTIONAL: DBHub (multi-database MCP)
# =============================================================================
section "6/9 — Optional Tools"

# DBHub — multi-database MCP server
if command -v dbhub &>/dev/null; then
    success "dbhub already installed"
else
    info "Installing dbhub (multi-database MCP)..."
    npm install -g @bytebase/dbhub@latest 2>/dev/null || warn "dbhub install failed — skip if you don't need database access"
    success "dbhub installed"
fi

# =============================================================================
# 7. DIRECTORY STRUCTURE
# =============================================================================
section "7/9 — Directory Structure"

mkdir -p "$OPENCODE_DIR"
success "Created $OPENCODE_DIR"

# Initialize empty memory file if it doesn't exist
if [[ ! -f "$MEMORY_FILE" ]]; then
    touch "$MEMORY_FILE"
    success "Created empty memory file at $MEMORY_FILE"
else
    success "Memory file already exists ($MEMORY_FILE)"
fi

# =============================================================================
# 8. OPENCODE.JSON CONFIG
# =============================================================================
section "8/9 — OpenCode Configuration"

# Back up existing config
if [[ -f "$OPENCODE_JSON" ]]; then
    cp "$OPENCODE_JSON" "${OPENCODE_JSON}.backup.$(date +%Y%m%d_%H%M%S)"
    info "Backed up existing opencode.json"
fi

cat > "$OPENCODE_JSON" << 'JSONEOF'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (Remote 4090)",
      "options": {
        "baseURL": "OLLAMA_URL_PLACEHOLDER"
      },
      "models": {
        "gemma4:26b": {
          "name": "Gemma 4 26B-A4B",
          "id": "gemma4:26b",
          "contextWindow": 32768,
          "maxTokens": 8192
        }
      }
    }
  },
  "mcp": {
    "ddg-search": {
      "type": "local",
      "command": ["uvx", "duckduckgo-mcp-server"],
      "environment": {
        "DDG_SAFE_SEARCH": "moderate",
        "DDG_REGION": "us-en"
      },
      "enabled": true
    },
    "fetch": {
      "type": "local",
      "command": ["uvx", "mcp-server-fetch"],
      "enabled": true
    },
    "memory": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-memory"],
      "environment": {
        "MEMORY_FILE_PATH": "MEMORY_PATH_PLACEHOLDER"
      },
      "enabled": true
    },
    "thinking": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
      "enabled": true
    },
    "context7": {
      "type": "local",
      "command": ["npx", "-y", "@upstash/context7-mcp@latest"],
      "enabled": true
    },
    "git": {
      "type": "local",
      "command": ["uvx", "mcp-server-git"],
      "enabled": true
    },
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp@latest"],
      "enabled": false,
      "_comment": "Enable when you need browser automation. Disable to save context tokens."
    },
    "tavily": {
      "type": "remote",
      "url": "https://mcp.tavily.com/mcp/?tavilyApiKey={env:TAVILY_API_KEY}",
      "enabled": false,
      "_comment": "Enable after setting TAVILY_API_KEY. Free tier: 1000 searches/month at https://app.tavily.com"
    },
    "eslint": {
      "type": "local",
      "command": ["npx", "@eslint/mcp@latest"],
      "enabled": false,
      "_comment": "Enable for JavaScript/TypeScript projects."
    },
    "semgrep": {
      "type": "local",
      "command": ["uvx", "semgrep", "--config=auto", "mcp"],
      "enabled": false,
      "_comment": "Enable for security scanning."
    },
    "filesystem": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", "HOME_DIR_PLACEHOLDER"],
      "enabled": false,
      "_comment": "Enable if you need advanced filesystem ops beyond OpenCode builtins."
    },
    "github": {
      "type": "local",
      "command": [
        "docker", "run", "--rm", "-i",
        "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "environment": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "{env:GITHUB_TOKEN}"
      },
      "enabled": false,
      "_comment": "Enable after setting GITHUB_TOKEN. Warning: 30+ tools, heavy on context."
    }
  }
}
JSONEOF

# Replace placeholders with actual values
sed -i "s|OLLAMA_URL_PLACEHOLDER|${OLLAMA_BASE_URL}|g" "$OPENCODE_JSON"
sed -i "s|MEMORY_PATH_PLACEHOLDER|${MEMORY_FILE}|g" "$OPENCODE_JSON"
sed -i "s|HOME_DIR_PLACEHOLDER|${HOME}/COdingProjects|g" "$OPENCODE_JSON"

success "Wrote $OPENCODE_JSON"
info "Config summary:"
info "  - 6 servers ENABLED  (ddg-search, fetch, memory, thinking, context7, git)"
info "  - 6 servers DISABLED (playwright, tavily, eslint, semgrep, filesystem, github)"
info "  - Enable disabled servers in opencode.json as needed"

# =============================================================================
# 9. ENV TEMPLATE
# =============================================================================
section "9/9 — Environment Variables"

if [[ ! -f "$ENV_FILE" ]]; then
    cat > "$ENV_FILE" << 'ENVEOF'
# =============================================================================
# OpenCode MCP Environment Variables
# =============================================================================
# Source this file in your shell profile:
#   echo 'source ~/COdingProjects/4090-windows-llm-playground/.env.opencode' >> ~/.zshrc
#
# Or export them manually before running opencode.
# =============================================================================

# -- Tavily (AI-optimized search) --
# Free tier: 1,000 searches/month
# Sign up: https://app.tavily.com
# export TAVILY_API_KEY="tvly-your-key-here"

# -- GitHub (for GitHub MCP server) --
# Create a token: https://github.com/settings/tokens
# Scopes needed: repo, read:org, read:user
# export GITHUB_TOKEN="ghp_your-token-here"

# -- Exa (neural search, optional) --
# Free tier: 1,000 requests/month
# Sign up: https://dashboard.exa.ai
# export EXA_API_KEY="your-exa-key-here"

# -- Firecrawl (advanced scraping, optional) --
# Free tier available
# Sign up: https://www.firecrawl.dev/app/api-keys
# export FIRECRAWL_API_KEY="your-firecrawl-key-here"
ENVEOF
    success "Created $ENV_FILE — edit it to add your API keys"
else
    success "$ENV_FILE already exists"
fi

# =============================================================================
# VERIFICATION
# =============================================================================
section "Verification"

PASS=0
FAIL=0

check() {
    local name="$1"
    local cmd="$2"
    if eval "$cmd" &>/dev/null 2>&1; then
        success "$name"
        ((PASS++))
    else
        warn "$name — FAILED (may still work via npx/uvx at runtime)"
        ((FAIL++))
    fi
}

check "node >= 18"          "node --version | grep -qE 'v(1[89]|[2-9][0-9])'"
check "npm"                 "npm --version"
check "python >= 3.10"      "python --version | grep -qE '3\.(1[0-9]|[2-9][0-9])'"
check "uv"                  "uv --version"
check "git"                 "git --version"
check "ripgrep"             "rg --version"
check "jq"                  "jq --version"
check "docker"              "docker --version"
check "gh (GitHub CLI)"     "gh --version"
check "opencode.json valid" "jq empty '$OPENCODE_JSON'"

echo ""
info "Checking MCP server availability..."

# For uvx-installed tools, check if the shim exists
check "ddg-search (uvx)"  "uv tool list 2>/dev/null | grep -q duckduckgo-mcp-server"
check "fetch (uvx)"        "uv tool list 2>/dev/null | grep -q mcp-server-fetch"
check "git-mcp (uvx)"      "uv tool list 2>/dev/null | grep -q mcp-server-git"

# For npx packages, check if they're in the npm cache
check "memory (npx)"              "npm cache ls @modelcontextprotocol/server-memory 2>/dev/null | grep -q server-memory || npm cache ls 2>/dev/null | grep -q server-memory || true"
check "sequential-thinking (npx)" "npm cache ls @modelcontextprotocol/server-sequential-thinking 2>/dev/null | grep -q sequential || true"
check "context7 (npx)"            "npm cache ls @upstash/context7-mcp 2>/dev/null | grep -q context7 || true"
check "playwright (npx)"          "npm cache ls @playwright/mcp 2>/dev/null | grep -q playwright || true"

echo ""
echo -e "${BOLD}${GREEN}Passed: $PASS${NC}  ${BOLD}${YELLOW}Warnings: $FAIL${NC}"

# =============================================================================
# DONE
# =============================================================================
section "Setup Complete"

echo -e "${BOLD}What was installed:${NC}"
echo "  System:  nodejs, npm, python, uv, git, ripgrep, jq, docker, gh"
echo "  Python:  duckduckgo-mcp-server, mcp-server-fetch, mcp-server-git, semgrep"
echo "  Node:    memory, sequential-thinking, context7, playwright, eslint, filesystem"
echo "  Browser: Chromium (for Playwright)"
echo ""
echo -e "${BOLD}Files written:${NC}"
echo "  $OPENCODE_JSON          — full MCP config (6 enabled, 6 disabled)"
echo "  ${OPENCODE_JSON}.backup.*   — backup of previous config"
echo "  $ENV_FILE         — API key template"
echo "  $MEMORY_FILE      — persistent memory store"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo "  1. Review and source your env file:"
echo "     ${CYAN}source $ENV_FILE${NC}"
echo ""
echo "  2. (Optional) Add API keys for premium services:"
echo "     ${CYAN}vim $ENV_FILE${NC}"
echo ""
echo "  3. Launch OpenCode:"
echo "     ${CYAN}cd $PROJECT_DIR && opencode${NC}"
echo ""
echo "  4. Test it works — try these prompts:"
echo "     ${CYAN}\"Search the web for the latest CachyOS release\"${NC}"
echo "     ${CYAN}\"Remember that I'm running Gemma 4 on a remote 4090\"${NC}"
echo "     ${CYAN}\"Look up the Express.js routing docs\"${NC}"
echo "     ${CYAN}\"Show me the git log for this repo\"${NC}"
echo ""
echo "  5. Enable more servers as needed by editing opencode.json:"
echo "     Set ${CYAN}\"enabled\": true${NC} for playwright, tavily, eslint, etc."
echo ""
echo -e "${BOLD}Tip:${NC} Keep 5-8 servers enabled max. Each server's tool definitions"
echo "  eat into Gemma 4's 32K context window. Disable what you don't need."
