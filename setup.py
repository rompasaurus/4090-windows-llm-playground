#!/usr/bin/env python3
"""
4090 Windows LLM Playground — Setup & Configuration Script

Installs and configures:
  - Ollama (local LLM runtime)
  - Gemma 4 26B-A4B model (Q4_K_M quantization)
  - OpenCode (Claude Code-like TUI with MCP server support)
  - Crush (Claude Code-like TUI for local models)
  - Aider (AI pair programming CLI)
  - Tailscale network exposure for remote access

Requirements: Python 3.10+, Windows 11, winget available
"""

import subprocess
import sys
import os
import json
import shutil
import time
import argparse
from pathlib import Path

# ─── ANSI Colours ───────────────────────────────────────────────────────────

RESET  = "\033[0m"
BOLD   = "\033[1m"
DIM    = "\033[2m"
RED    = "\033[91m"
GREEN  = "\033[92m"
YELLOW = "\033[93m"
BLUE   = "\033[94m"
CYAN   = "\033[96m"

SPINNER_FRAMES = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"]


def log_info(msg):
    print(f"  {BLUE}ℹ{RESET}  {msg}")

def log_ok(msg):
    print(f"  {GREEN}✓{RESET}  {msg}")

def log_warn(msg):
    print(f"  {YELLOW}⚠{RESET}  {msg}")

def log_err(msg):
    print(f"  {RED}✗{RESET}  {msg}")

def log_step(msg):
    print(f"\n{BOLD}{CYAN}━━━ {msg} ━━━{RESET}")

def banner():
    print(f"""
{BOLD}{CYAN}╔══════════════════════════════════════════════════════════╗
║       4090 Windows LLM Playground — Setup Script         ║
╚══════════════════════════════════════════════════════════╝{RESET}
""")


# ─── Utility ────────────────────────────────────────────────────────────────

def cmd_exists(name):
    """Check if a command is available on PATH."""
    return shutil.which(name) is not None


def run(cmd, check=True, capture=False, timeout=None):
    """Run a shell command with nice error handling."""
    log_info(f"{DIM}$ {cmd}{RESET}")
    try:
        result = subprocess.run(
            cmd, shell=True, check=check, timeout=timeout,
            capture_output=capture, text=True,
        )
        return result
    except subprocess.CalledProcessError as e:
        log_err(f"Command failed (exit {e.returncode}): {cmd}")
        if capture and e.stderr:
            print(f"    {DIM}{e.stderr.strip()}{RESET}")
        if check:
            raise
        return e
    except subprocess.TimeoutExpired:
        log_err(f"Command timed out after {timeout}s: {cmd}")
        raise


def get_ollama_path():
    """Find ollama executable."""
    if cmd_exists("ollama"):
        return "ollama"
    candidate = Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Ollama" / "ollama.exe"
    if candidate.exists():
        return str(candidate)
    return None


def get_tailscale_ip():
    """Get this machine's Tailscale IP address."""
    try:
        result = subprocess.run(
            "tailscale ip -4", shell=True, capture_output=True, text=True, check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return None


def is_linux():
    """Check if running on Linux."""
    return sys.platform.startswith("linux")


def get_uvx_path():
    """Find uvx executable, checking common install locations."""
    if cmd_exists("uvx"):
        return "uvx"
    # Check common install location
    candidate = Path.home() / ".local" / "bin" / "uvx"
    if candidate.exists():
        return str(candidate)
    return None


def get_shell_profile():
    """Get the user's shell profile file path."""
    shell = os.environ.get("SHELL", "")
    if "zsh" in shell:
        return Path.home() / ".zshrc"
    return Path.home() / ".bashrc"


# ─── Install Steps ──────────────────────────────────────────────────────────

def install_ollama():
    log_step("Ollama")
    ollama = get_ollama_path()
    if ollama:
        result = run(f'"{ollama}" --version', capture=True)
        log_ok(f"Ollama already installed: {result.stdout.strip()}")
        return ollama

    log_info("Installing Ollama via winget...")
    run("winget install --id Ollama.Ollama -e --accept-source-agreements --accept-package-agreements")
    log_ok("Ollama installed")

    ollama = get_ollama_path()
    if not ollama:
        log_warn("Ollama installed but not found on PATH. You may need to restart your terminal.")
        ollama = str(Path(os.environ.get("LOCALAPPDATA", "")) / "Programs" / "Ollama" / "ollama.exe")
    return ollama


def pull_model(ollama, model="gemma4:26b"):
    log_step(f"Pulling Model: {model}")

    # Check if already pulled
    result = run(f'"{ollama}" list', capture=True)
    if model.split(":")[0] in result.stdout:
        log_ok(f"Model {model} already available")
        return

    log_info(f"Downloading {model} (~16GB). This will take a while...")
    run(f'"{ollama}" pull {model}', timeout=3600)
    log_ok(f"Model {model} pulled successfully")


def configure_ollama_env(tailscale_ip=None):
    log_step("Ollama Environment Configuration")

    # Set larger context window
    log_info("Setting OLLAMA_CONTEXT_LENGTH=32768 for adequate coding context...")
    run('setx OLLAMA_CONTEXT_LENGTH 32768', check=False)
    log_ok("OLLAMA_CONTEXT_LENGTH set to 32768")

    if tailscale_ip:
        log_info(f"Configuring Ollama to listen on all interfaces for Tailscale access...")
        run('setx OLLAMA_HOST 0.0.0.0', check=False)
        log_ok(f"Ollama will accept connections on {tailscale_ip}:11434")
        log_warn("Restart Ollama after setting OLLAMA_HOST for it to take effect")
    else:
        log_info("No Tailscale detected — Ollama will only listen on localhost")


def install_uv():
    log_step("uv / uvx (Python MCP Server Runner)")

    uvx = get_uvx_path()
    if uvx:
        log_ok(f"uvx already installed: {uvx}")
        return uvx

    log_info("Installing uv via official installer...")
    if is_linux():
        run("curl -LsSf https://astral.sh/uv/install.sh | sh", check=False)
    else:
        run("powershell -ExecutionPolicy Bypass -c \"irm https://astral.sh/uv/install.ps1 | iex\"", check=False)

    uvx = get_uvx_path()
    if uvx:
        log_ok(f"uvx installed: {uvx}")

        # Ensure ~/.local/bin is on PATH in shell profile
        if is_linux():
            profile = get_shell_profile()
            path_line = 'export PATH="$HOME/.local/bin:$PATH"'
            try:
                content = profile.read_text() if profile.exists() else ""
                if ".local/bin" not in content:
                    with open(profile, "a") as f:
                        f.write(f"\n# Added by setup.py — uv/uvx\n{path_line}\n")
                    log_ok(f"Added ~/.local/bin to PATH in {profile}")
                else:
                    log_ok(f"~/.local/bin already in {profile}")
            except OSError:
                log_warn(f"Could not update {profile}. Add manually: {path_line}")
    else:
        log_err("uvx installation failed. Install manually: https://docs.astral.sh/uv/getting-started/installation/")

    return uvx


def install_opencode():
    log_step("OpenCode (Claude Code-like TUI + MCP)")

    if cmd_exists("opencode"):
        log_ok("OpenCode already installed")
        return

    if cmd_exists("npm"):
        log_info("Installing OpenCode via npm...")
        run("npm install -g opencode-ai@latest", check=False)
    else:
        log_warn("npm not found. Install Node.js first, then: npm install -g opencode-ai@latest")
        return

    log_ok("OpenCode installed")


def configure_opencode(project_dir, tailscale_ip=None):
    log_step("OpenCode Configuration")

    base_url = f"http://{tailscale_ip}:11434/v1" if tailscale_ip else "http://localhost:11434/v1"
    name = f"Ollama (Remote 4090 via Tailscale @ {tailscale_ip})" if tailscale_ip else "Ollama (Local 4090)"

    # Use absolute path for uvx to avoid PATH issues with OpenCode's spawned processes
    uvx = get_uvx_path() or "uvx"

    config = {
        "$schema": "https://opencode.ai/config.json",
        "provider": {
            "ollama": {
                "npm": "@ai-sdk/openai-compatible",
                "name": name,
                "options": {
                    "baseURL": base_url,
                },
                "models": {
                    "gemma4:26b": {
                        "name": "Gemma 4 26B-A4B",
                        "id": "gemma4:26b",
                        "contextWindow": 32768,
                        "maxTokens": 8192,
                    }
                },
            }
        },
        "mcp": {
            "ddg-search": {
                "type": "local",
                "command": [uvx, "duckduckgo-mcp-server"],
                "enabled": True,
            },
            "fetch": {
                "type": "local",
                "command": [uvx, "mcp-server-fetch"],
                "enabled": True,
            },
            "memory": {
                "type": "local",
                "command": ["npx", "-y", "@modelcontextprotocol/server-memory"],
                "enabled": True,
            },
            "thinking": {
                "type": "local",
                "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
                "enabled": True,
            },
            "context7": {
                "type": "local",
                "command": ["npx", "-y", "@upstash/context7-mcp@latest"],
                "enabled": True,
            },
            "git": {
                "type": "local",
                "command": [uvx, "mcp-server-git"],
                "enabled": True,
            },
            "playwright": {
                "type": "local",
                "command": ["npx", "-y", "@playwright/mcp@latest"],
                "enabled": False,
            },
            "tavily": {
                "type": "remote",
                "url": "https://mcp.tavily.com/mcp/?tavilyApiKey={env:TAVILY_API_KEY}",
                "enabled": False,
            },
            "eslint": {
                "type": "local",
                "command": ["npx", "@eslint/mcp@latest"],
                "enabled": False,
            },
            "semgrep": {
                "type": "local",
                "command": [uvx, "semgrep-mcp"],
                "enabled": False,
            },
            "filesystem": {
                "type": "local",
                "command": ["npx", "-y", "@modelcontextprotocol/server-filesystem", str(project_dir)],
                "enabled": False,
            },
            "github": {
                "type": "local",
                "command": [
                    "docker", "run", "--rm", "-i",
                    "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
                    "ghcr.io/github/github-mcp-server",
                ],
                "environment": {
                    "GITHUB_PERSONAL_ACCESS_TOKEN": "{env:GITHUB_TOKEN}",
                },
                "enabled": False,
            },
        },
    }

    config_path = project_dir / "opencode.json"
    config_path.write_text(json.dumps(config, indent=2) + "\n")
    log_ok(f"OpenCode config written to {config_path}")
    log_info("6 MCP servers enabled (search, fetch, memory, thinking, context7, git)")
    log_info("6 MCP servers disabled (playwright, tavily, eslint, semgrep, filesystem, github)")
    log_info("See OPENCODE_EXPANSION.md for details on each server")


def configure_opencode_env(project_dir):
    log_step("OpenCode Environment File")

    env_path = project_dir / ".env.opencode"
    if env_path.exists():
        log_ok(f".env.opencode already exists at {env_path}")
        log_info("Edit it to add your API keys for Tavily, GitHub, Exa, Firecrawl")
        return

    env_content = """# =============================================================================
# OpenCode MCP Environment Variables
# =============================================================================
# Source this file in your shell profile:
#   echo 'source {project_dir}/.env.opencode' >> ~/.zshrc
#
# Or export them manually before running opencode.
# =============================================================================

# -- Tavily (AI-optimized search) --
# Free tier: 1,000 searches/month
# Sign up: https://app.tavily.com
export TAVILY_API_KEY=""

# -- GitHub (for GitHub MCP server) --
# Create a token: https://github.com/settings/tokens
# Scopes needed: repo, read:org, read:user
export GITHUB_TOKEN=""

# -- Exa (neural search, optional) --
# Free tier: 1,000 requests/month
# Sign up: https://dashboard.exa.ai
export EXA_API_KEY=""

# -- Firecrawl (advanced scraping, optional) --
# Free tier available
# Sign up: https://www.firecrawl.dev/app/api-keys
export FIRECRAWL_API_KEY=""
""".replace("{project_dir}", str(project_dir))

    env_path.write_text(env_content)
    log_ok(f"OpenCode env template written to {env_path}")
    log_warn("Edit .env.opencode to add your API keys, then source it in your shell profile")

    # Add source line to shell profile
    profile = get_shell_profile()
    source_line = f'source "{project_dir}/.env.opencode"'
    try:
        content = profile.read_text() if profile.exists() else ""
        if ".env.opencode" not in content:
            with open(profile, "a") as f:
                f.write(f"\n# OpenCode MCP API keys\n{source_line}\n")
            log_ok(f"Added source line to {profile}")
        else:
            log_ok(f".env.opencode already sourced in {profile}")
    except OSError:
        log_warn(f"Could not update {profile}. Add manually: {source_line}")


def install_crush():
    log_step("Crush (Claude Code-like TUI)")

    if cmd_exists("crush"):
        log_ok("Crush already installed")
        return

    log_info("Installing Crush via winget...")
    result = run("winget install --id charmbracelet.crush -e --accept-source-agreements --accept-package-agreements", check=False)

    if result.returncode != 0:
        log_warn("winget install failed. Trying npm fallback...")
        if cmd_exists("npm"):
            run("npm install -g @charmland/crush", check=False)
        else:
            log_err("Could not install Crush. Install manually: https://github.com/charmbracelet/crush/releases")
            return

    log_ok("Crush installed")


def configure_crush(project_dir, tailscale_ip=None):
    log_step("Crush Configuration")

    config = {
        "$schema": "https://charm.land/crush.json",
        "providers": {
            "ollama-local": {
                "name": "Ollama (Local 4090)",
                "base_url": "http://localhost:11434/v1/",
                "type": "openai-compat",
                "models": [
                    {
                        "name": "Gemma 4 26B-A4B",
                        "id": "gemma4:26b",
                        "context_window": 32768,
                        "default_max_tokens": 8192,
                    }
                ],
            }
        },
    }

    # Write project-local config
    config_path = project_dir / ".crush.json"
    config_path.write_text(json.dumps(config, indent=2))
    log_ok(f"Crush config written to {config_path}")

    # Also write a remote config example
    if tailscale_ip:
        remote_config = json.loads(json.dumps(config))
        remote_config["providers"]["ollama-remote"] = {
            "name": f"Ollama (Remote via Tailscale @ {tailscale_ip})",
            "base_url": f"http://{tailscale_ip}:11434/v1/",
            "type": "openai-compat",
            "models": [
                {
                    "name": "Gemma 4 26B-A4B (Remote)",
                    "id": "gemma4:26b",
                    "context_window": 32768,
                    "default_max_tokens": 8192,
                }
            ],
        }
        remote_path = project_dir / ".crush-remote.json"
        remote_path.write_text(json.dumps(remote_config, indent=2))
        log_ok(f"Remote Crush config written to {remote_path}")


def install_aider():
    log_step("Aider (AI Pair Programming CLI)")

    if cmd_exists("aider"):
        log_ok("Aider already installed")
        return

    log_info("Installing aider-chat via pip...")
    run(f"{sys.executable} -m pip install aider-chat", timeout=300)
    log_ok("Aider installed")


def configure_aider(project_dir, tailscale_ip=None):
    log_step("Aider Configuration")

    # .env file for aider
    env_lines = [
        "# Aider environment config for local Gemma 4",
        "OLLAMA_API_BASE=http://127.0.0.1:11434",
        "AIDER_MODEL=ollama_chat/gemma4:26b",
        "",
    ]
    env_path = project_dir / ".env"
    env_path.write_text("\n".join(env_lines))
    log_ok(f"Aider .env written to {env_path}")

    # Model settings for context window
    model_settings = [
        {
            "name": "ollama_chat/gemma4:26b",
            "extra_params": {"num_ctx": 32768},
            "edit_format": "diff",
            "use_repo_map": True,
        }
    ]

    import yaml  # aider installs pyyaml
    settings_path = project_dir / ".aider.model.settings.yml"
    settings_path.write_text(yaml.dump(model_settings, default_flow_style=False))
    log_ok(f"Aider model settings written to {settings_path}")

    # Remote config documentation
    if tailscale_ip:
        remote_env_lines = [
            "# Aider environment config for REMOTE Gemma 4 via Tailscale",
            f"OLLAMA_API_BASE=http://{tailscale_ip}:11434",
            "AIDER_MODEL=ollama_chat/gemma4:26b",
            "",
        ]
        remote_path = project_dir / ".env.remote"
        remote_path.write_text("\n".join(remote_env_lines))
        log_ok(f"Remote Aider .env written to {remote_path}")


def verify_gpu():
    log_step("GPU Verification")

    result = run("nvidia-smi --query-gpu=name,memory.total,driver_version --format=csv,noheader", capture=True, check=False)
    if result.returncode == 0:
        gpu_info = result.stdout.strip()
        log_ok(f"GPU detected: {gpu_info}")
    else:
        log_warn("nvidia-smi not found or failed. Ensure NVIDIA drivers are installed.")


def verify_tailscale():
    log_step("Tailscale Network")

    ts_ip = get_tailscale_ip()
    if ts_ip:
        log_ok(f"Tailscale connected — IP: {ts_ip}")
        return ts_ip
    else:
        log_warn("Tailscale not detected or not connected")
        log_info("Install from https://tailscale.com/download/windows")
        log_info("Remote access will not be configured (can re-run setup later)")
        return None


def print_summary(tailscale_ip=None):
    log_step("Setup Complete — Quick Reference")

    print(f"""
  {BOLD}Local usage:{RESET}

    {CYAN}opencode{RESET}                               Launch OpenCode TUI (Claude Code-like + MCP)
    {CYAN}crush{RESET}                                  Launch Crush TUI (Claude Code-like)
    {CYAN}aider{RESET}                                  Launch Aider pair programming
    {CYAN}aider --model ollama_chat/gemma4:26b{RESET}   Aider with explicit model
    {CYAN}ollama run gemma4:26b{RESET}                  Raw Ollama chat

  {BOLD}Ollama API:{RESET}

    Local:   http://localhost:11434""")

    if tailscale_ip:
        print(f"    Remote:  http://{tailscale_ip}:11434")
        print(f"""
  {BOLD}Remote usage (from another Tailscale device):{RESET}

    {CYAN}# Set env var on remote machine{RESET}
    export OLLAMA_API_BASE=http://{tailscale_ip}:11434

    {CYAN}# Then run Aider or Crush pointing at this machine{RESET}
    aider --model ollama_chat/gemma4:26b
""")

    print(f"""
  {BOLD}Docs:{RESET}  See {CYAN}REMOTE_ACCESS.md{RESET} for Tailscale setup
        See {CYAN}OPENCODE_EXPANSION.md{RESET} for MCP server guide
""")


# ─── Main ───────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Setup script for 4090 Windows LLM Playground",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--skip-model", action="store_true", help="Skip pulling the Gemma 4 model (if already downloaded)")
    parser.add_argument("--skip-opencode", action="store_true", help="Skip OpenCode installation")
    parser.add_argument("--skip-crush", action="store_true", help="Skip Crush installation")
    parser.add_argument("--skip-aider", action="store_true", help="Skip Aider installation")
    parser.add_argument("--model", default="gemma4:26b", help="Ollama model to pull (default: gemma4:26b)")
    parser.add_argument("--verify-only", action="store_true", help="Only verify existing installation, don't install anything")
    args = parser.parse_args()

    banner()

    project_dir = Path(__file__).parent.resolve()

    # ── Verify environment ──
    verify_gpu()
    tailscale_ip = verify_tailscale()

    if args.verify_only:
        ollama = get_ollama_path()
        if ollama:
            log_ok(f"Ollama: {ollama}")
            run(f'"{ollama}" list', check=False)
        else:
            log_err("Ollama not found")

        uvx = get_uvx_path()
        if uvx:
            log_ok(f"uvx: {uvx}")
        else:
            log_warn("uvx: not found (needed for MCP servers)")

        if cmd_exists("opencode"):
            log_ok("OpenCode: installed")
        else:
            log_warn("OpenCode: not found")

        if cmd_exists("crush"):
            log_ok("Crush: installed")
        else:
            log_warn("Crush: not found")

        if cmd_exists("aider"):
            log_ok("Aider: installed")
        else:
            log_warn("Aider: not found")

        if cmd_exists("docker"):
            log_ok("Docker: installed")
        else:
            log_warn("Docker: not found (needed for GitHub MCP server)")

        env_path = project_dir / ".env.opencode"
        if env_path.exists():
            log_ok(".env.opencode: exists")
        else:
            log_warn(".env.opencode: not found (API keys for MCP servers)")

        print_summary(tailscale_ip)
        return

    # ── Install Ollama + model ──
    ollama = install_ollama()

    if not args.skip_model:
        pull_model(ollama, args.model)

    configure_ollama_env(tailscale_ip)

    # ── Install uv/uvx (needed by MCP servers) ──
    install_uv()

    # ── Install CLI tools ──
    if not args.skip_opencode:
        install_opencode()
        configure_opencode(project_dir, tailscale_ip)
        configure_opencode_env(project_dir)

    if not args.skip_crush:
        install_crush()
        configure_crush(project_dir, tailscale_ip)

    if not args.skip_aider:
        install_aider()
        configure_aider(project_dir, tailscale_ip)

    # ── Done ──
    print_summary(tailscale_ip)
    log_ok("All done! Restart your terminal for environment changes to take effect.")


if __name__ == "__main__":
    main()
