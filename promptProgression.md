# Prompt Progression Log

Chronological record of every AI-assisted prompt used to build this project.

---

## Prompt #1
- **Date/Time:** 2026-04-10
- **Prompt:** "ok I want to create a new project folder and init a new repo on my rompasaurus labeled 4090 windows llm playground"
- **Input Tokens (est):** ~30
- **Output Tokens (est):** ~200
- **Commit:** `18fc33c` — Initial commit
- **Files Created/Modified:**
  - `README.md` (created — placeholder title)

---

## Prompt #2
- **Date/Time:** 2026-04-10
- **Prompt:** "ok let's setup the readme with the project intent also create a promptProgression.md file to keep track of every prompt I input into this project directory"
- **Input Tokens (est):** ~350
- **Output Tokens (est):** ~1,200
- **Commit:** *(pending)*
- **Files Created/Modified:**
  - `README.md` (modified — added project intent, goals, hardware table, link to prompt log)
  - `promptProgression.md` (created — prompt tracking log with format template)

---

## Prompt #3
- **Date/Time:** 2026-04-10
- **Prompt:** "ok I want to setup Gemma 4 on this windows machine and access it via a nice CLI interface similar to Claude Code ensure tool calling and development works as close as possible to Claude CLI"
- **Input Tokens (est):** ~40
- **Output Tokens (est):** ~300
- **Commit:** *(none — research phase)*
- **Files Created/Modified:**
  - *(none — installed Gemini CLI globally via `npm install -g @google/gemini-cli` before realizing user meant local Gemma 4, not cloud Gemini)*

---

## Prompt #4
- **Date/Time:** 2026-04-10
- **Prompt:** "I want to run the Gemma 4 model locally on this computer with my 4090 GPU"
- **Input Tokens (est):** ~20
- **Output Tokens (est):** ~4,000
- **Commit:** *(none — research phase)*
- **Files Created/Modified:**
  - *(none — deep research into Gemma 4 model family, VRAM requirements, local runtimes, tool-calling support, and Claude Code-like CLI alternatives)*

---

## Prompt #5
- **Date/Time:** 2026-04-10
- **Prompt:** "is that the top end of the model specs can I run the full model on this card reliably without losing accuracy"
- **Input Tokens (est):** ~20
- **Output Tokens (est):** ~800
- **Commit:** *(none — analysis)*
- **Files Created/Modified:**
  - *(none — VRAM analysis: E4B at FP16 is largest full-precision model that fits 24GB; 26B MoE requires quantization)*

---

## Prompt #6
- **Date/Time:** 2026-04-10
- **Prompt:** "what would it take to run the full model"
- **Input Tokens (est):** ~15
- **Output Tokens (est):** ~600
- **Commit:** *(none — analysis)*
- **Files Created/Modified:**
  - *(none — hardware cost analysis: 26B FP16 needs 52GB+ VRAM, options range from RTX PRO 6000 to multi-GPU setups)*

---

## Prompt #7
- **Date/Time:** 2026-04-10
- **Prompt:** "let's go for the recommended model also create a research.md file to note the conclusions and research already performed in this chat and keep a nice org document on what was investigated as part of this process continue to update the promptProgression each time I make a prompt also let's then look at the best way to mimic a Claude-like experience with this Gemma model and run it locally"
- **Input Tokens (est):** ~80
- **Output Tokens (est):** ~8,000
- **Commit:** *(pending)*
- **Files Created/Modified:**
  - `research.md` (created — comprehensive research document covering model specs, VRAM analysis, runtime evaluation, CLI tool comparison, tool-calling architecture)
  - `promptProgression.md` (modified — added prompts #3–#7)

---

## Prompt #8
- **Date/Time:** 2026-04-10
- **Prompt:** "while this is downloading make me a python script that will install and configure this also account for it being on a tailscale network and provide documentation on how to connect to this llm via opencode and aider"
- **Input Tokens (est):** ~40
- **Output Tokens (est):** ~12,000
- **Commit:** *(pending)*
- **Files Created/Modified:**
  - `setup.py` (created — automated install/config script: Ollama, Gemma 4, Crush, Aider, Tailscale detection, GPU verification, CLI with --skip/--verify flags)
  - `REMOTE_ACCESS.md` (created — Tailscale remote access guide: architecture diagram, host/client setup, Aider/Crush/API/Python examples, ACLs, troubleshooting)
  - `.crush.json` (created — Crush TUI config pointing at local Ollama)
  - `.env` (created — Aider env config for local Ollama)
  - `.aider.model.settings.yml` (created — Aider model settings with 32K context, diff editing, repo map)
  - `.gitignore` (created)
  - `README.md` (modified — added current stack table, quick start, project files index)

---

## Prompt #9
- **Date/Time:** 2026-04-10
- **Prompt:** "I also need a guide on how to set up remote access to this LLM via Tailscale and a connected Linux CachyOS machine"
- **Input Tokens (est):** ~25
- **Output Tokens (est):** ~3,000
- **Commit:** *(pending)*
- **Files Created/Modified:**
  - `REMOTE_ACCESS.md` (modified — added full CachyOS Linux client section: Tailscale install via pacman, Aider/Crush setup, shell aliases, verification steps)

---

## Prompt #10
- **Date/Time:** 2026-04-10
- **Prompt:** "also you can make this repo public"
- **Input Tokens (est):** ~10
- **Output Tokens (est):** ~100
- **Commit:** *(pending)*
- **Files Created/Modified:**
  - *(none — repo visibility changed to public via `gh repo edit`)*

---

## Prompt #11
- **Date/Time:** 2026-04-10
- **Prompt:** "add section for OpenCode and remote access too"
- **Input Tokens (est):** ~10
- **Output Tokens (est):** ~5,000
- **Commit:** *(pending)*
- **Files Created/Modified:**
  - `opencode.json` (created — OpenCode TUI config pointing at local Ollama with Gemma 4 26B)
  - `REMOTE_ACCESS.md` (modified — added OpenCode as Option B in remote client setup; added OpenCode install/config to CachyOS section; renumbered all options; added OpenCode to architecture diagram and shell aliases)
  - `README.md` (modified — added OpenCode to stack table, quick start commands, and project files index)
  - `research.md` (modified — clarified OpenCode vs Crush as separate projects, updated decision section with all three tools installed)
  - `promptProgression.md` (modified — added prompt #11)

---

## Prompt #12
- **Date/Time:** 2026-04-10
- **Prompt:** "divide describe and commit don't forget to update the promptProgression"
- **Input Tokens (est):** ~15
- **Output Tokens (est):** ~2,000
- **Commit:** *(see commits below — changes split into logical groups)*
- **Files Created/Modified:**
  - `promptProgression.md` (modified — added prompt #12, updated pending commit hashes)

---

## Prompt #13
- **Date/Time:** 2026-04-10
- **Prompt:** *(OpenCode launched with config error: `Unrecognized key: "baseURL" provider.ollama`)*
- **Input Tokens (est):** ~20
- **Output Tokens (est):** ~500
- **Commit:** `b49b66b` — Fix baseURL key casing in opencode.json config
- **Notes:** Initial fix attempt changed `baseURL` to `baseUrl` — still invalid. The actual issue was a wrong config schema: `baseURL` belongs inside an `options` object, and the provider requires `"npm": "@ai-sdk/openai-compatible"`. Root cause was that the original config was written based on outdated/incorrect examples.
- **Files Created/Modified:**
  - `opencode.json` (modified — restructured to correct OpenCode provider schema)

---

## Prompt #14
- **Date/Time:** 2026-04-10
- **Prompt:** "update the documentation and guide as well so this doesn't happen in the future"
- **Input Tokens (est):** ~15
- **Output Tokens (est):** ~2,000
- **Commit:** *(see prompt #15)*
- **Files Created/Modified:**
  - `REMOTE_ACCESS.md` (modified — updated both OpenCode config examples to correct schema with `$schema`, `npm`, and `options.baseURL` structure)

---

## Prompt #15
- **Date/Time:** 2026-04-10
- **Prompt:** "ok opencode opens but it's not connecting to the Ollama model it defaulted to Big Pickle hosted by OpenCode... wait I had to select the right model via Ctrl+P, we're good. Also update prompts file, divide describe and commit these changes, also you can fix any grammar or spelling issues in the prompt progression if there are any"
- **Input Tokens (est):** ~50
- **Output Tokens (est):** ~3,000
- **Commit:** *(pending)*
- **Notes:** OpenCode was working correctly — just needed to select the Ollama model via Ctrl+P instead of the default hosted model.
- **Files Created/Modified:**
  - `promptProgression.md` (modified — added prompts #13–#15, fixed grammar/spelling across all entries)
  - `REMOTE_ACCESS.md` (modified — already updated in prompt #14)
  - `opencode.json` (modified — added `$schema` field)

---
