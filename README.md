# 4090 Windows LLM Playground

A local LLM experimentation environment built around an NVIDIA RTX 4090 on Windows 11. This project is a hands-on workspace for running, testing, benchmarking, and fine-tuning large language models locally — exploring what's possible with consumer-grade hardware.

## Current Stack

| Component | Tool | Details |
|-----------|------|---------|
| **Model** | Gemma 4 26B-A4B | MoE, ~4B active params, Q4_K_M quantization |
| **Runtime** | Ollama | Local model serving on `localhost:11434` |
| **Coding CLI** | OpenCode | Claude Code-like TUI with coder/plan agents (SST team) |
| **Coding CLI** | Crush | Claude Code-like TUI (Charmbracelet) |
| **Pair Programming** | Aider | Diff-based AI coding assistant |
| **Remote Access** | Tailscale | Encrypted P2P access to Ollama API |

## Quick Start

```bash
# Automated setup (installs everything)
python setup.py

# Or verify existing installation
python setup.py --verify-only
```

### Manual Usage

```bash
# Launch OpenCode (closest to Claude Code)
opencode

# Launch Crush (Claude Code-like TUI)
crush

# Launch Aider pair programming
aider

# Raw Ollama chat
ollama run gemma4:26b

# Ollama API
curl http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{"model":"gemma4:26b","messages":[{"role":"user","content":"Hello!"}]}'
```

## Goals

- **Local inference** — Run open-weight models (Gemma, Llama, Mistral, Qwen, Phi, etc.) locally with full GPU acceleration
- **Benchmarking** — Measure throughput, latency, VRAM usage, and quantization trade-offs on the 4090
- **Tool exploration** — Evaluate runtimes and serving stacks (Ollama, llama.cpp, vLLM, etc.)
- **Prompt engineering** — Test prompting strategies, system prompts, and agentic workflows against local models
- **Fine-tuning** — Experiment with LoRA/QLoRA fine-tuning pipelines that fit within 24GB VRAM
- **Integration** — Build local API endpoints, tool-use chains, and prototype apps powered by local LLMs

## Hardware

| Component | Spec |
|-----------|------|
| GPU | NVIDIA RTX 4090 (24GB VRAM) |
| OS | Windows 11 Pro |

## Project Files

| File | Purpose |
|------|---------|
| [`setup.py`](setup.py) | Automated install & configuration script |
| [`research.md`](research.md) | Investigation notes, model comparisons, decisions |
| [`promptProgression.md`](promptProgression.md) | Log of every AI-assisted prompt in this project |
| [`REMOTE_ACCESS.md`](REMOTE_ACCESS.md) | Tailscale remote access documentation |
| [`OPENCODE_EXPANSION.md`](OPENCODE_EXPANSION.md) | Guide to expanding OpenCode with MCP servers |
| [`opencode.json`](opencode.json) | OpenCode TUI configuration |
| [`.crush.json`](.crush.json) | Crush TUI configuration |
| [`.env`](.env) | Aider environment configuration |
| [`.aider.model.settings.yml`](.aider.model.settings.yml) | Aider model settings |
