# Research Log

Ongoing investigation notes for setting up a local LLM coding assistant on Windows 11 with an RTX 4090.

---

## 1. Gemma 4 Model Family Overview

**Released:** April 2, 2026 | **License:** Apache 2.0

| Model | Architecture | Effective Params | Total Params | Context | Modalities |
|---|---|---|---|---|---|
| Gemma 4 E2B | Dense | 2.3B | 5.1B | 128K | Text, Image, Audio |
| Gemma 4 E4B | Dense | 4.5B | 8B | 128K | Text, Image, Audio |
| Gemma 4 26B-A4B | **MoE** | ~3.8B active | 26B | 256K | Text, Image, Video |
| Gemma 4 31B | Dense | 31B | 31B | 256K | Text, Image, Video |

- "E" prefix = "Effective" — total params include embeddings, active compute matches the label.
- "A4B" = only ~4B parameters activate per forward pass (Mixture of Experts). Nearly as fast as a 4B model despite 26B total.
- All models have both **base** and **instruction-tuned (-it)** checkpoints.

### Hugging Face Model IDs

**Official:**
- `google/gemma-4-E2B-it`
- `google/gemma-4-E4B-it`
- `google/gemma-4-26B-A4B-it`
- `google/gemma-4-31B-it`

**Best GGUF quantized (by downloads):**
- `unsloth/gemma-4-26B-A4B-it-GGUF` (1.36M downloads)
- `unsloth/gemma-4-31B-it-GGUF` (907K)
- `lmstudio-community/gemma-4-26B-A4B-it-GGUF` (705K)
- `bartowski/google_gemma-4-31B-it-GGUF` (150K)
- `ggml-org/gemma-4-26B-A4B-it-GGUF` (116K, official llama.cpp org)

---

## 2. VRAM Analysis — RTX 4090 (24GB)

### What fits at each precision

| Model | FP16 (full) | Q8 | Q4_K_M | Fits 24GB? |
|---|---|---|---|---|
| E2B (5.1B) | ~10GB | ~6GB | ~3GB | Yes — all precisions |
| E4B (8B) | ~16GB | ~10GB | ~4GB | Yes — all precisions |
| 26B-A4B (MoE) | ~52GB | ~28GB | ~16-17GB | **Q4_K_M only** |
| 31B (Dense) | ~62GB | ~31GB | ~20GB | Q4 tight, short context only |

### Decision

**Selected model: Gemma 4 26B-A4B-it at Q4_K_M**

- Weights: ~17GB VRAM
- Remaining for KV cache: ~7GB (sufficient for moderate context)
- MoE architecture: only ~4B params active per token = fast inference
- Quantization loss at Q4_K_M is minimal for code tasks
- Outperforms E4B at full FP16 in practice due to larger total knowledge

### What it would take to run full precision

| Hardware | VRAM | 26B FP16 | 31B FP16 | Cost |
|---|---|---|---|---|
| RTX PRO 6000 | 96GB | Yes | Yes | ~$7,000 |
| 3x RTX 4090 (tensor parallel) | 72GB | Yes | Tight | ~$6,000+ |
| A100 80GB | 80GB | Yes | Tight | ~$5,000 used |
| Mac Studio M4 Ultra | 192GB unified | Yes | Yes | ~$6,000-8,000 (bandwidth limited) |

**Conclusion:** Full precision 26B requires 52GB+ VRAM — not feasible on a single 4090. Q4_K_M is the pragmatic choice with negligible real-world accuracy impact for coding tasks.

---

## 3. Local Inference Runtimes

### Evaluated

| Runtime | Gemma 4 Support | Tool Calling | Windows | Notes |
|---|---|---|---|---|
| **Ollama** | Yes (`gemma4:26b`) | **Broken** (v0.20.1) — parser crash, token spam | Native | Easiest install. Tool parser bugs: issues #15315, #15241 |
| **llama.cpp** | Yes (GGUF) | **Working** (PR #21326 merged) | Native | Best tool-calling support today. Build from source recommended |
| **LM Studio** | Yes | Limited | Native | GUI-focused, good for quick testing |
| **vLLM** | Yes | Working (OpenAI-compatible API) | WSL2 only | Production-grade but Linux-centric |
| **text-generation-webui** | Yes (GGUF) | Limited | Native | Good for experimentation |

### Current status (as of April 2026)

**Ollama tool-calling bugs for Gemma 4:**
- Tool parser crashes with "invalid character" errors
- Streaming drops tool calls
- Tokenizer bug causes `<unused25>` token spam
- Open issues: ollama/ollama#15315, ollama/ollama#15241

**llama.cpp fixes:**
- PR #21326 merged — fixes Gemma 4 chat template and tokenizer
- Building from latest source is recommended for full tool-calling support

### Decision

**Primary runtime: Ollama** for model management and serving.
**Fallback: llama.cpp** (built from source) if Ollama tool-calling bugs are a blocker.
Monitor Ollama releases for tool-calling fixes.

---

## 4. Claude Code-Like CLI Tools for Local Models

### Goal
Replicate the Claude Code experience (autonomous coding agent with file editing, shell access, tool calling) using a local Gemma 4 model.

### Evaluated

| Tool | Approach | Local Model Support | Tool Calling | Claude Code Similarity |
|---|---|---|---|---|
| **OpenCode** | TUI coding agent | Ollama, OpenAI-compatible API | Yes (native) | **Highest** — has "build" and "plan" agents, auto-detects Ollama |
| **Aider** | Diff-based pair programming | Ollama, any OpenAI-compatible | Diff-based (avoids tool-call bugs) | Medium — excellent for editing, less autonomous |
| **Goose** | Autonomous agent | Ollama, 15+ providers | Yes + tool shim for non-native models | High — plans, executes shell, edits files, 70+ MCP extensions |
| **Open Interpreter** | Code execution agent | Ollama, local models | Yes | Medium — more general-purpose |
| **Continue.dev** | IDE extension + chat | Ollama, local models | Yes | Low — IDE-focused, not standalone CLI |
| **Gemini CLI** | CLI agent | Gemini API only (not local) | Yes | High — but requires cloud API, not local |

### Key findings

- **OpenCode and Crush are separate projects** with a shared origin. The original author was hired by Charmbracelet and now maintains Crush. OpenCode was forked and is maintained by the SST team at `anomalyco/opencode`. Both are actively developed.
- **OpenCode** (95K+ GitHub stars) is the closest to Claude Code for local models. Has "coder" and "plan" agents, auto-detects Ollama. Install: `npm install -g opencode-ai@latest` or `curl -fsSL https://opencode.ai/install | bash`.
- **Crush** (Charmbracelet) is the original author's continuation. Install: `winget install charmbracelet.crush` or `scoop install crush`.
- **Aider** sidesteps tool-calling parser bugs entirely by using diff-based editing. Most battle-tested with many LLM backends.
- **Goose** has an "Ollama tool shim" that wraps models without native tool calling, making it resilient to parser bugs.

### Decision

All three top tools installed for comparison:
- **OpenCode v1.4.3** — primary recommendation for Claude Code-like experience
- **Crush v0.56.0** — alternative TUI, same lineage
- **Aider v0.86.2** — best for pair programming, sidesteps tool-call bugs

Configuration files created for all three pointing at local Ollama with Gemma 4 26B.

---

## 5. Gemma 4 Tool Calling Architecture

Gemma 4 instruction-tuned models natively support function/tool calling using 6 special tokens:

| Token | Purpose |
|---|---|
| `<\|tool>` / `<tool\|>` | Tool declaration |
| `<\|tool_call>` / `<tool_call\|>` | Function invocation |
| `<\|tool_result>` / `<tool_result\|>` | Tool response |

**Workflow:**
1. Define tools via `apply_chat_template()` with `tools` argument (JSON Schema or Python functions)
2. Model generates structured function calls
3. Developer parses output, executes functions, appends results
4. Model generates final response

**Practical status:** Native support works in `transformers` (Python) and `llama.cpp`. Ollama's parser is currently broken for Gemma 4.

---

## Appendix: Sources

- [Google DeepMind — Gemma 4](https://deepmind.google/models/gemma/gemma-4/)
- [HuggingFace Blog — Welcome Gemma 4](https://huggingface.co/blog/gemma4)
- [Google AI — Function Calling with Gemma 4](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
- [Unsloth — Gemma 4 Local Guide](https://unsloth.ai/docs/models/gemma-4)
- [NVIDIA Blog — RTX AI Garage Gemma 4](https://blogs.nvidia.com/blog/rtx-ai-garage-open-models-google-gemma-4/)
- [Ollama — Gemma 4](https://ollama.com/library/gemma4)
- [OpenCode GitHub](https://github.com/anomalyco/opencode/)
- [Goose GitHub](https://github.com/block/goose)
- [Aider](https://aider.chat/)
- [Ollama Issue #15315](https://github.com/ollama/ollama/issues/15315) — Gemma 4 tool parsing errors
- [llama.cpp PR #21326](https://github.com/ggml-org/llama.cpp/pull/21326) — Gemma 4 template fixes
