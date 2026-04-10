# Claude Code with Third-Party / Local LLMs

> Research compiled April 2026

---

## Gemma 4 + Claude Code: Currently Broken

Tool calling in Ollama for Gemma 4 is not working as of v0.20.1. Confirmed bugs:

- **Ollama #15390 / #15402** — invalid JSON for tool params, infinite retry loops, 100%+ CPU spikes from vision encoder running on text-only prompts
- **vLLM #39043** — reasoning tags and tool calls leak to chat output; `--tool-call-parser gemma4` flag exists but is incomplete
- MoE variant (`gemma4:26b-a4b`) is worse than dense (`gemma4:31b`)

### Gemma 4 Workarounds (if you must try)

```bash
export OLLAMA_CONTEXT_LENGTH=32768
export OLLAMA_FLASH_ATTENTION=0
ollama pull gemma4:31b   # use dense, not MoE
```

Still expect multi-step tool chaining to fail.

---

## How Claude Code Connects to Non-Anthropic Models

All working solutions set `ANTHROPIC_BASE_URL` to a proxy. Claude Code never knows it's talking to a different model.

### Option 1 — Ollama Direct (v0.14+ has Anthropic API compat)

```bash
export ANTHROPIC_BASE_URL=http://localhost:11434
export ANTHROPIC_AUTH_TOKEN=ollama
claude --model qwen3.5
```

### Option 2 — LiteLLM Proxy

```bash
pip install litellm[proxy]
litellm --model ollama/gemma4:31b --port 4000

export ANTHROPIC_BASE_URL=http://localhost:4000
export ANTHROPIC_AUTH_TOKEN=sk-fake
```

> **Warning:** LiteLLM PyPI versions 1.82.7 and 1.82.8 contained credential-stealing malware. Rotate keys if affected.

### Option 3 — claude-code-router (recommended)

[musistudio/claude-code-router](https://github.com/musistudio/claude-code-router) — 31.9k stars, most mature community solution.

- Routes to OpenRouter, DeepSeek, Gemini, Ollama, and more
- `/model` switch command works inside Claude Code
- Auto-routes long-context prompts to high-capacity models
- `tooluse` transformer improves tool call reliability on weaker models

---

## Feature Support Matrix

| Feature | Non-Claude Models |
|---|---|
| Basic chat / code generation | Works (quality varies) |
| Single tool call | Often works with strong models |
| Multi-step tool chaining | Unreliable — main failure point |
| Extended thinking / reasoning | Not available |
| Context compaction | Not available |
| Claude Skills system | Not available |
| Streaming | Works via most proxies |
| File read/write tools | Works when schema handled correctly |

---

## Better Alternatives for Local / Gemma 4 Use

| Tool | Local Model Support | Notes |
|---|---|---|
| **OpenCode** | Native, 75+ providers | 140k stars, best Claude Code alternative for local models |
| **Aider** | Native via Ollama | Git-native, 4x fewer tokens than Claude Code |
| **Gemini CLI** | Google models only | 1k free req/day Gemini 2.5 Pro, handles Gemma cleanly |
| **Continue.dev** | Native via Ollama | IDE extension (VS Code / JetBrains), best for autocomplete |

**For Gemma 4 specifically: use OpenCode.** Google's own tooling and model-agnostic tools handle Gemma 4's tool call schema better than Claude Code's proxy layer.

---

## Quality Reality Check

Benchmark: RTX 4070 Ti Super, Qwen2.5-32B local vs Claude Sonnet cloud

| Task | Local 32B | Claude Sonnet |
|---|---|---|
| Function generation | 4.1/5 | 4.4/5 |
| Bug detection | 3.8/5 | 4.6/5 |
| Refactoring | 4.0/5 | 4.3/5 |
| Multi-file context | 2.8/5 | 4.5/5 |
| Code explanation | 4.2/5 | 4.1/5 |

Local gets ~85-90% of Claude's quality on routine tasks. Claude's biggest advantage is multi-file context — which is exactly when you need the AI most.

---

## Recommended Models for Claude Code + Proxy (Stable)

These have reliable tool calling via claude-code-router / LiteLLM:

- `DeepSeek V3` via OpenRouter — best cost/quality ratio
- `Gemini 2.5 Flash` via OpenRouter — fast, cheap, solid tool use
- `qwen2.5-coder:32b` — best local coding model, needs 24GB VRAM
- `qwen3.5` via Ollama — good all-rounder, lighter weight

---

## Hardware Notes (M1 Max 64GB)

| Model | Q4 RAM | Fits? |
|---|---|---|
| gemma4:31b (dense) | ~19GB | Yes |
| gemma4:26b-a4b (MoE) | ~16GB | Yes (but broken tool use) |
| qwen2.5-coder:32b | ~20GB | Yes |
| llama3.3:70b | ~40GB | Yes |
| qwen2.5:72b | ~40GB | Yes |

With 64GB you can comfortably run 70B models at Q4. The 27B ceiling is a Gemma line limitation, not a hardware limitation.
