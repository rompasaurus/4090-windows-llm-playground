# Remote Access via Tailscale

Connect to your local Gemma 4 26B model from any device on your Tailscale network.

---

## Architecture

```
┌──────────────────────┐         Tailscale          ┌──────────────────────┐
│  Remote Machine      │    ◄──── encrypted ────►    │  4090 Host Machine   │
│                      │         WireGuard           │                      │
│  OpenCode / Aider /  │                             │  Ollama + Gemma 4    │
│  Crush               │                             │                      │
│  OLLAMA_API_BASE=    │                             │  Listening on        │
│  http://100.x.y.z    │                             │  0.0.0.0:11434       │
│       :11434         │                             │                      │
└──────────────────────┘                             └──────────────────────┘
```

---

## Prerequisites

1. **Tailscale** installed on both machines: https://tailscale.com/download
2. Both machines logged into the same Tailnet
3. Ollama running on the host (4090) machine

---

## Host Machine Setup (the 4090 box)

### 1. Find your Tailscale IP

```powershell
tailscale ip -4
# Example output: 100.85.32.17
```

### 2. Configure Ollama to listen on all interfaces

By default Ollama only listens on `127.0.0.1`. To accept remote connections:

```powershell
# Set permanently (requires Ollama restart)
setx OLLAMA_HOST 0.0.0.0
```

Then restart Ollama:
- Right-click the Ollama tray icon → Quit
- Relaunch Ollama from Start Menu

### 3. Verify it's accessible

From the host machine:

```powershell
curl http://localhost:11434/api/tags
```

You should see your models listed (including `gemma4:26b`).

### 4. Set context window (recommended)

```powershell
setx OLLAMA_CONTEXT_LENGTH 32768
```

---

## Remote Machine Setup (laptop, another PC, etc.)

### Option A: Aider

```bash
# Install
pip install aider-chat

# Set environment
export OLLAMA_API_BASE=http://100.85.32.17:11434   # ← your Tailscale IP

# Run
aider --model ollama_chat/gemma4:26b
```

Or create a `.env` file in your project:

```env
OLLAMA_API_BASE=http://100.85.32.17:11434
AIDER_MODEL=ollama_chat/gemma4:26b
```

### Option B: OpenCode

OpenCode is a Claude Code-like TUI with built-in agents (coder, plan). It auto-detects Ollama and provides file editing, shell access, and tool calling.

```bash
# Install (any platform)
npm install -g opencode-ai@latest
```

Create `opencode.json` in your project directory:

```json
{
  "provider": {
    "ollama": {
      "id": "ollama",
      "name": "Ollama (Remote 4090)",
      "baseURL": "http://100.85.32.17:11434/v1",
      "models": {
        "gemma4:26b": {
          "name": "Gemma 4 26B-A4B",
          "id": "gemma4:26b",
          "contextWindow": 32768,
          "maxTokens": 8192
        }
      }
    }
  }
}
```

Launch:

```bash
opencode
```

OpenCode features closest to Claude Code:
- **Coder agent** — autonomous file editing and shell commands
- **Plan agent** — multi-step task planning before execution
- Interactive TUI with diff previews
- Repo-aware context

### Option C: Crush

Create `.crush.json` in your project directory:

```json
{
  "$schema": "https://charm.land/crush.json",
  "providers": {
    "ollama-remote": {
      "name": "Ollama (Remote 4090)",
      "base_url": "http://100.85.32.17:11434/v1/",
      "type": "openai-compat",
      "models": [
        {
          "name": "Gemma 4 26B-A4B",
          "id": "gemma4:26b",
          "context_window": 32768,
          "default_max_tokens": 8192
        }
      ]
    }
  }
}
```

Then launch:

```bash
crush
```

### Option D: Direct API calls (curl, scripts, etc.)

```bash
# Chat completion (OpenAI-compatible)
curl http://100.85.32.17:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gemma4:26b",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'

# Ollama native API
curl http://100.85.32.17:11434/api/generate \
  -d '{"model": "gemma4:26b", "prompt": "Hello!"}'
```

### Option E: Any OpenAI-compatible client

Ollama exposes an OpenAI-compatible API at `http://<tailscale-ip>:11434/v1/`. This works with:
- Python `openai` library
- LangChain
- LlamaIndex
- Any tool that accepts a custom OpenAI base URL

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://100.85.32.17:11434/v1/",
    api_key="unused",  # Ollama doesn't require a key
)

response = client.chat.completions.create(
    model="gemma4:26b",
    messages=[{"role": "user", "content": "Explain MoE architectures."}],
)
print(response.choices[0].message.content)
```

---

## Tailscale ACLs (Optional Security)

If you want to restrict which devices can access Ollama, add a Tailscale ACL rule:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["tag:dev-machines"],
      "dst": ["tag:llm-host:11434"]
    }
  ]
}
```

---

## CachyOS (Arch-based Linux) Client Setup

Step-by-step guide for connecting a CachyOS machine to your 4090 host via Tailscale.

### 1. Install Tailscale

```bash
# CachyOS uses pacman (Arch-based)
sudo pacman -S tailscale

# Enable and start the service
sudo systemctl enable --now tailscaled

# Authenticate
sudo tailscale up
```

Follow the browser link to log in. Once connected, verify:

```bash
tailscale status
# You should see your Windows 4090 machine listed
```

### 2. Find the host IP

```bash
# Get the 4090 host's Tailscale IP
tailscale status | grep "4090"   # or whatever hostname your Windows box has

# Or ping it by Tailscale hostname (MagicDNS)
tailscale ping <windows-hostname>
```

Note the IP (e.g., `100.85.32.17`). You can also use the MagicDNS hostname directly if enabled on your Tailnet (e.g., `windows-desktop`).

### 3. Test connectivity

```bash
# Verify Ollama is reachable
curl http://100.85.32.17:11434/api/tags

# Should return JSON with your models:
# {"models":[{"name":"gemma4:26b",...}]}
```

### 4. Install Aider

```bash
# Option A: pipx (recommended on Arch/CachyOS)
sudo pacman -S python-pipx
pipx install aider-chat

# Option B: pip with user install
pip install --user aider-chat

# Option C: aider-install helper
pip install --user aider-install
aider-install
```

### 5. Configure Aider for remote Ollama

```bash
# Set env vars (add to ~/.bashrc or ~/.zshrc for persistence)
export OLLAMA_API_BASE=http://100.85.32.17:11434
```

Or create a `.env` in your project directory:

```bash
cat > .env << 'EOF'
OLLAMA_API_BASE=http://100.85.32.17:11434
AIDER_MODEL=ollama_chat/gemma4:26b
EOF
```

Create model settings:

```bash
cat > .aider.model.settings.yml << 'EOF'
- name: ollama_chat/gemma4:26b
  extra_params:
    num_ctx: 32768
  edit_format: diff
  use_repo_map: true
EOF
```

Launch:

```bash
aider --model ollama_chat/gemma4:26b
```

### 6. Install OpenCode

```bash
# Option A: npm (requires Node.js)
sudo pacman -S nodejs npm
npm install -g opencode-ai@latest

# Option B: curl installer
curl -fsSL https://opencode.ai/install | bash
```

Create `opencode.json` in your project:

```json
{
  "provider": {
    "ollama": {
      "id": "ollama",
      "name": "Ollama (Remote 4090 via Tailscale)",
      "baseURL": "http://100.85.32.17:11434/v1",
      "models": {
        "gemma4:26b": {
          "name": "Gemma 4 26B-A4B",
          "id": "gemma4:26b",
          "contextWindow": 32768,
          "maxTokens": 8192
        }
      }
    }
  }
}
```

Launch:

```bash
opencode
```

### 7. Install Crush

```bash
# Option A: Go install (if Go is available)
go install github.com/charmbracelet/crush@latest

# Option B: Download binary directly
curl -fsSL https://github.com/charmbracelet/crush/releases/latest/download/crush_Linux_x86_64.tar.gz | tar xz
sudo mv crush /usr/local/bin/

# Option C: AUR (community package, check availability)
paru -S crush-bin   # or yay -S crush-bin
```

Create `.crush.json` in your project:

```json
{
  "$schema": "https://charm.land/crush.json",
  "providers": {
    "ollama-remote": {
      "name": "Ollama (Remote 4090 via Tailscale)",
      "base_url": "http://100.85.32.17:11434/v1/",
      "type": "openai-compat",
      "models": [
        {
          "name": "Gemma 4 26B-A4B",
          "id": "gemma4:26b",
          "context_window": 32768,
          "default_max_tokens": 8192
        }
      ]
    }
  }
}
```

Launch:

```bash
crush
```

### 8. Shell aliases (optional convenience)

Add to `~/.bashrc` or `~/.zshrc`:

```bash
# Remote LLM shortcuts
export OLLAMA_REMOTE="http://100.85.32.17:11434"

alias llm-opencode="opencode"
alias llm-aider="OLLAMA_API_BASE=$OLLAMA_REMOTE aider --model ollama_chat/gemma4:26b"
alias llm-crush="crush"
alias llm-status="curl -s $OLLAMA_REMOTE/api/tags | python3 -m json.tool"
alias llm-ping="tailscale ping 100.85.32.17"
```

### 9. Verify everything works

```bash
# Check Tailscale connection
tailscale ping 100.85.32.17

# Check Ollama is serving the model
llm-status

# Launch coding assistant
llm-chat
```

---

## Troubleshooting

### "Connection refused" from remote machine

1. Verify Ollama is running on the host: `curl http://localhost:11434`
2. Verify `OLLAMA_HOST` is set to `0.0.0.0`: check `echo %OLLAMA_HOST%`
3. Restart Ollama after changing env vars
4. Check Windows Firewall — allow inbound TCP on port 11434

### Slow responses over Tailscale

- Tailscale adds minimal latency (~1-5ms for direct connections)
- If using a relay (DERP), latency will be higher. Run `tailscale netcheck` to verify direct connection
- The bottleneck is almost always GPU inference speed, not network

### Model not found

Ensure the model is pulled on the host machine:

```powershell
ollama list
# Should show: gemma4:26b
```

---

## Performance Notes

- **Local latency:** ~0ms network overhead
- **Tailscale direct:** ~1-5ms network overhead (negligible vs inference time)
- **Tailscale relayed:** ~20-100ms (try `tailscale ping <ip>` to check)
- **Inference speed on 4090:** Gemma 4 26B-A4B at Q4_K_M typically produces 30-60 tokens/sec
