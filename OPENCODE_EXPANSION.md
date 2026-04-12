# Expanding OpenCode: Closing the Gap with Claude Code

A comprehensive guide to extending OpenCode's capabilities via MCP servers, plugins, and configuration to match Claude Code's feature set as closely as possible — all running locally on a 4090 with Gemma 4 26B.

---

## Table of Contents

- [1. Feature Gap Analysis](#1-feature-gap-analysis)
  - [1.1 What OpenCode Already Has](#11-what-opencode-already-has)
  - [1.2 What Claude Code Has That OpenCode Doesn't](#12-what-claude-code-has-that-opencode-doesnt)
  - [1.3 What Can Be Added via MCP](#13-what-can-be-added-via-mcp)
  - [1.4 What Cannot Be Replicated](#14-what-cannot-be-replicated)
- [2. MCP Server Configuration](#2-mcp-server-configuration)
  - [2.1 How MCP Works in OpenCode](#21-how-mcp-works-in-opencode)
  - [2.2 Local (stdio) Server Config](#22-local-stdio-server-config)
  - [2.3 Remote (HTTP) Server Config](#23-remote-http-server-config)
  - [2.4 Environment Variable Substitution](#24-environment-variable-substitution)
- [3. Web Search](#3-web-search)
  - [3.1 Free Options (No API Key)](#31-free-options-no-api-key)
  - [3.2 Paid Options (Free Tiers Available)](#32-paid-options-free-tiers-available)
  - [3.3 Recommended Setup](#33-recommended-setup)
- [4. Web Scraping and Content Extraction](#4-web-scraping-and-content-extraction)
  - [4.1 Simple Page Fetching](#41-simple-page-fetching)
  - [4.2 Browser Automation](#42-browser-automation)
  - [4.3 Advanced Scraping](#43-advanced-scraping)
- [5. Deep Research](#5-deep-research)
  - [5.1 Multi-Step Research Servers](#51-multi-step-research-servers)
  - [5.2 Sequential Thinking / Planning](#52-sequential-thinking--planning)
  - [5.3 Building a Research Workflow](#53-building-a-research-workflow)
- [6. Memory and Knowledge Persistence](#6-memory-and-knowledge-persistence)
  - [6.1 Knowledge Graph Memory](#61-knowledge-graph-memory)
  - [6.2 Semantic Memory (Vector-Based)](#62-semantic-memory-vector-based)
- [7. Code Quality and Analysis](#7-code-quality-and-analysis)
  - [7.1 Linting](#71-linting)
  - [7.2 Security Scanning](#72-security-scanning)
- [8. Git and GitHub Integration](#8-git-and-github-integration)
  - [8.1 Local Git Operations](#81-local-git-operations)
  - [8.2 GitHub API Integration](#82-github-api-integration)
- [9. Database Access](#9-database-access)
- [10. Documentation Lookup](#10-documentation-lookup)
- [11. Filesystem Extensions](#11-filesystem-extensions)
- [12. Gemma 4 Tool Calling: Limitations and Workarounds](#12-gemma-4-tool-calling-limitations-and-workarounds)
  - [12.1 Known Issues](#121-known-issues)
  - [12.2 Ollama Version Requirements](#122-ollama-version-requirements)
  - [12.3 Context Window Budget](#123-context-window-budget)
  - [12.4 Gemma 4 vs Claude: Honest Comparison](#124-gemma-4-vs-claude-honest-comparison)
- [13. Recommended Configurations](#13-recommended-configurations)
  - [13.1 Minimal Setup (3 servers)](#131-minimal-setup-3-servers)
  - [13.2 Full Setup (8 servers)](#132-full-setup-8-servers)
  - [13.3 Complete opencode.json Example](#133-complete-opencodejson-example)
- [14. Installation Walkthrough](#14-installation-walkthrough)
  - [14.1 Prerequisites](#141-prerequisites)
  - [14.2 Step-by-Step Setup](#142-step-by-step-setup)
  - [14.3 Verification](#143-verification)
- [15. Troubleshooting](#15-troubleshooting)

---

## 1. Feature Gap Analysis

### 1.1 What OpenCode Already Has

OpenCode ships with a solid set of built-in tools out of the box:

| Tool | Description |
|------|-------------|
| `bash` | Execute shell commands |
| `edit` | Modify files via string replacement |
| `write` | Create or overwrite files |
| `read` | Read file contents (supports line ranges) |
| `grep` | Regex search across files (ripgrep-powered) |
| `glob` | Find files by pattern |
| `list` | List directory contents |
| `webfetch` | Fetch URL content as markdown |
| `websearch` | Web search via Exa AI (built-in, no key needed) |
| `todowrite` | Task checklist management |
| `question` | Ask user clarifying questions |
| `apply_patch` | Apply patches to files |
| `skill` | Load SKILL.md files into context |
| `lsp` | Language Server Protocol integration (experimental) |

OpenCode also provides features Claude Code lacks:
- **Air-gapped mode** with fully local models
- **Custom agents** defined via markdown files
- **Per-agent tool scoping** with glob patterns
- **Desktop app** and web interface
- **Plugin system** via npm packages

### 1.2 What Claude Code Has That OpenCode Doesn't

| Claude Code Feature | Category | MCP Solvable? |
|---------------------|----------|---------------|
| Subagent spawning (parallel) | Agent orchestration | No |
| Agent teams (multi-instance coordination) | Agent orchestration | No |
| Plan mode (read-only analysis) | Workflow | No |
| Checkpoints / rewind | Safety | No |
| Extended thinking / reasoning traces | Model capability | No |
| Computer use (mouse/keyboard) | Desktop automation | Partial (Playwright) |
| 200K token context window | Model capability | No |
| Session memory across conversations | Persistence | Yes |
| Git worktrees for isolation | Git | No |
| Hooks system (26 lifecycle events) | Extensibility | No |
| Deep multi-step research | Research | Yes |
| Database querying | Data | Yes |
| Code linting / security scanning | Code quality | Yes |
| Advanced git operations | Version control | Yes |
| IDE checkpoint integration | IDE | No |
| Permission modes (6 levels) | Security | No |

### 1.3 What Can Be Added via MCP

These Claude Code capabilities can be closely replicated with MCP servers:

1. **Web search** -- DuckDuckGo, Tavily, Exa, or Google scraping
2. **Web scraping** -- Fetch, Playwright, Firecrawl
3. **Deep research** -- GPT Researcher, sequential thinking
4. **Persistent memory** -- Knowledge graph, semantic memory
5. **Git operations** -- Local git + GitHub API
6. **Database access** -- SQLite, PostgreSQL, MySQL
7. **Code linting** -- ESLint, Semgrep
8. **Documentation lookup** -- Context7 (9,000+ libraries)
9. **Browser automation** -- Playwright (works without vision/multimodal)
10. **Advanced filesystem** -- Official filesystem MCP

### 1.4 What Cannot Be Replicated

These are fundamental to Claude Code's architecture and cannot be added via MCP:

- **Parallel subagent orchestration** -- requires native runtime support
- **Extended thinking** -- model-level feature (Gemma 4 doesn't have structured reasoning traces)
- **200K context window** -- Gemma 4 is limited to 32K in practice via Ollama
- **Checkpoint/rewind** -- requires deep IDE integration
- **Hooks system** -- requires native event lifecycle
- **Agent teams** -- requires multi-instance coordination
- **Computer use** -- requires vision model + OS-level control
- **Auto-mode safety classifier** -- model-level feature

---

## 2. MCP Server Configuration

### 2.1 How MCP Works in OpenCode

MCP (Model Context Protocol) is a standard for connecting AI models to external tools and data sources. OpenCode acts as an MCP **client** that connects to MCP **servers**. Each server exposes tools that the model can call during a conversation.

Servers are configured in your `opencode.json` file under the `"mcp"` key.

### 2.2 Local (stdio) Server Config

Local servers run as child processes on your machine, communicating via stdin/stdout:

```json
{
  "mcp": {
    "server-name": {
      "type": "local",
      "command": ["npx", "-y", "@some/mcp-package"],
      "environment": {
        "MY_VAR": "value"
      },
      "enabled": true,
      "timeout": 5000
    }
  }
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `type` | `"local"` | Yes | Runs as child process |
| `command` | `string[]` | Yes | Command + arguments |
| `environment` | `object` | No | Environment variables |
| `enabled` | `boolean` | No | Set `false` to disable without removing |
| `timeout` | `number` | No | Tool fetch timeout in ms (default: 5000) |

### 2.3 Remote (HTTP) Server Config

Remote servers communicate over HTTP (streamable HTTP or SSE):

```json
{
  "mcp": {
    "remote-server": {
      "type": "remote",
      "url": "https://mcp.example.com/mcp",
      "headers": {
        "Authorization": "Bearer {env:API_KEY}"
      },
      "enabled": true,
      "timeout": 5000
    }
  }
}
```

> **Note:** There is no separate `"sse"` type. Use `"remote"` for both SSE and streamable HTTP. If you encounter `UnknownError Server error`, remove `?transport=sse` from the URL.

### 2.4 Environment Variable Substitution

OpenCode supports two substitution patterns in MCP config:

- `"{env:VAR_NAME}"` -- reads from environment variables
- `"{file:path/to/file}"` -- reads from file contents

Example:
```json
{
  "environment": {
    "API_KEY": "{env:TAVILY_API_KEY}",
    "CONFIG": "{file:~/.config/mcp/config.json}"
  }
}
```

---

## 3. Web Search

### 3.1 Free Options (No API Key)

#### DuckDuckGo MCP Server (Recommended Free Option)

Privacy-focused search with content fetching. Most reliable free option.

- **Repo:** https://github.com/nickclyde/duckduckgo-mcp-server
- **Install:** `pip install duckduckgo-mcp-server` or use `uvx`

```json
{
  "mcp": {
    "ddg-search": {
      "type": "local",
      "command": ["uvx", "duckduckgo-mcp-server"],
      "environment": {
        "DDG_SAFE_SEARCH": "moderate",
        "DDG_REGION": "us-en"
      },
      "enabled": true
    }
  }
}
```

#### Open Web Search (Multi-Engine Fallback)

Cycles through Bing, DuckDuckGo, Brave, and Baidu. Falls back automatically if one engine is down.

- **Repo:** https://github.com/Aas-ee/open-webSearch
- **Install:** Clone repo, supports stdio and Docker

```json
{
  "mcp": {
    "open-websearch": {
      "type": "local",
      "command": ["python", "/path/to/open-webSearch/server.py"],
      "enabled": true
    }
  }
}
```

#### pskill9/web-search (Google Scraping)

Scrapes Google search results directly. No API key needed, but subject to rate limiting.

- **Repo:** https://github.com/pskill9/web-search
- **Install:** Clone + `npm install` + `npm run build`

```json
{
  "mcp": {
    "google-search": {
      "type": "local",
      "command": ["node", "/path/to/web-search/build/index.js"],
      "enabled": true
    }
  }
}
```

### 3.2 Paid Options (Free Tiers Available)

#### Tavily (Best Quality-to-Cost Ratio)

AI-optimized search designed for LLMs and RAG. Excels at technical documentation.

- **Repo:** https://github.com/tavily-ai/tavily-mcp
- **Free tier:** 1,000 searches/month at https://app.tavily.com
- **Install:** Remote MCP (no local install needed)

```json
{
  "mcp": {
    "tavily": {
      "type": "remote",
      "url": "https://mcp.tavily.com/mcp/?tavilyApiKey={env:TAVILY_API_KEY}",
      "enabled": true
    }
  }
}
```

#### Exa (Best for Deep Research)

Neural/semantic search. Better for research-style queries than keyword searches.

- **Repo:** https://github.com/exa-labs/exa-mcp-server
- **Free tier:** 1,000 requests/month at https://dashboard.exa.ai
- **Install:** `npx -y exa-mcp-server`

```json
{
  "mcp": {
    "exa": {
      "type": "local",
      "command": ["npx", "-y", "exa-mcp-server"],
      "environment": {
        "EXA_API_KEY": "{env:EXA_API_KEY}"
      },
      "enabled": true
    }
  }
}
```

> **Note:** Brave Search discontinued its free tier in February 2026. All plans now require metered billing ($5/month minimum).

### 3.3 Recommended Setup

**Budget-conscious:** DuckDuckGo MCP (free, reliable, good enough for most queries)

**Best results:** Tavily (free 1,000/month, significantly better quality for technical queries)

**Power user:** DuckDuckGo (free fallback) + Tavily or Exa (deep research)

---

## 4. Web Scraping and Content Extraction

### 4.1 Simple Page Fetching

#### Fetch MCP (Official Reference Server)

Fetches URLs and converts HTML to clean markdown. Lightweight, no JavaScript rendering.

- **Repo:** https://github.com/modelcontextprotocol/servers/tree/main/src/fetch
- **Install:** `uvx mcp-server-fetch` (Python) or `npx -y @modelcontextprotocol/server-fetch` (TypeScript)

```json
{
  "mcp": {
    "fetch": {
      "type": "local",
      "command": ["uvx", "mcp-server-fetch"],
      "enabled": true
    }
  }
}
```

> OpenCode has a built-in `webfetch` tool, but this MCP server provides more control (chunked reading, custom headers, robots.txt handling).

### 4.2 Browser Automation

#### Playwright MCP (Microsoft Official)

Full browser automation via accessibility snapshots. Works with text-only models (no vision/multimodal needed) because it uses the accessibility tree instead of screenshots.

- **Repo:** https://github.com/microsoft/playwright-mcp
- **Install:** `npx -y @playwright/mcp@latest`

```json
{
  "mcp": {
    "playwright": {
      "type": "local",
      "command": ["npx", "-y", "@playwright/mcp@latest"],
      "enabled": true
    }
  }
}
```

Capabilities:
- Navigate to URLs
- Click elements, fill forms
- Extract page content
- Handle JavaScript-rendered pages
- Take accessibility snapshots (text-based, works with Gemma 4)

### 4.3 Advanced Scraping

#### Firecrawl MCP

Production-grade web scraping with JavaScript rendering, batch processing, and structured extraction.

- **Repo:** https://github.com/firecrawl/firecrawl-mcp-server
- **Cloud API:** Free tier at https://www.firecrawl.dev/app/api-keys
- **Self-hosted:** Free (point `FIRECRAWL_API_URL` to your instance)

```json
{
  "mcp": {
    "firecrawl": {
      "type": "local",
      "command": ["npx", "-y", "firecrawl-mcp"],
      "environment": {
        "FIRECRAWL_API_KEY": "{env:FIRECRAWL_API_KEY}"
      },
      "enabled": true
    }
  }
}
```

---

## 5. Deep Research

### 5.1 Multi-Step Research Servers

#### GPT Researcher MCP

The most mature deep research server. Performs multi-step research: question elaboration, sub-question generation, parallel web search, analysis, and cited report generation.

- **Repo:** https://github.com/assafelovic/gpt-researcher
- **Install:** Python pip

#### Deep Research MCP

Similar multi-step workflow with Gemini integration.

- **Repo:** https://github.com/ssdeanx/deep-research-mcp-server
- **Install:** Python

> **Caveat:** Deep research servers work best with larger context windows and strong reasoning models. Gemma 4 26B at 32K context will produce shorter, less thorough reports than Claude with 200K context. Results will be functional but not as comprehensive.

### 5.2 Sequential Thinking / Planning

#### Sequential Thinking MCP (Official)

Structures problem-solving into explicit numbered thought sequences. The model decomposes problems step-by-step, can revise earlier thoughts, and adjusts the total number of steps dynamically.

- **Repo:** https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking
- **Install:** `npx -y @modelcontextprotocol/server-sequential-thinking`

```json
{
  "mcp": {
    "thinking": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-sequential-thinking"],
      "enabled": true
    }
  }
}
```

> **Warning:** This server requires strong instruction-following. Gemma 4 26B handles it reasonably well, but models under ~12B often produce malformed sequences.

### 5.3 Building a Research Workflow

To approximate Claude's deep research capability, combine these servers:

1. **Web search** (DuckDuckGo or Tavily) -- find relevant sources
2. **Fetch** -- read full page content from search results
3. **Sequential thinking** -- structure the analysis into steps
4. **Memory** -- persist findings across the session

The model will need to be prompted to chain these tools together. Example prompt:

> "Research [topic] in depth. Search the web for multiple sources, read the full content of the most relevant pages, think through the findings step by step, and produce a comprehensive report with citations."

This won't be as seamless as Claude's native research (which uses recursive subagent spawning), but it covers the same ground manually.

---

## 6. Memory and Knowledge Persistence

### 6.1 Knowledge Graph Memory

#### Official Memory MCP Server

Stores entities (nodes with observations) connected by typed relationships. Persists to a local JSONL file. Closest equivalent to Claude Code's auto-memory system.

- **Repo:** https://github.com/modelcontextprotocol/servers/tree/main/src/memory
- **Install:** `npx -y @modelcontextprotocol/server-memory`

```json
{
  "mcp": {
    "memory": {
      "type": "local",
      "command": ["npx", "-y", "@modelcontextprotocol/server-memory"],
      "environment": {
        "MEMORY_FILE_PATH": "/home/rompasaurus/.opencode/memory.jsonl"
      },
      "enabled": true
    }
  }
}
```

Tools provided:
- `create_entities` -- add new knowledge nodes
- `create_relations` -- connect entities
- `add_observations` -- attach facts to entities
- `search_nodes` -- find relevant memories
- `open_nodes` -- retrieve specific entities
- `delete_entities` / `delete_relations` / `delete_observations` -- remove data

### 6.2 Semantic Memory (Vector-Based)

#### mcp-mem0

Uses Mem0 library with vector embeddings for semantic search across memories. More powerful than the knowledge graph but requires PostgreSQL.

- **Repo:** https://github.com/coleam00/mcp-mem0
- **Requirements:** PostgreSQL + LLM API key for embeddings (can use local Ollama)

Only recommended if you already run PostgreSQL. The official memory server is sufficient for most use cases.

---

## 7. Code Quality and Analysis

### 7.1 Linting

#### ESLint MCP (Official)

First-party ESLint support via MCP. Lint JavaScript/TypeScript files directly.

- **Docs:** https://eslint.org/docs/latest/use/mcp
- **Install:** `npx @eslint/mcp@latest`

```json
{
  "mcp": {
    "eslint": {
      "type": "local",
      "command": ["npx", "@eslint/mcp@latest"],
      "enabled": true
    }
  }
}
```

### 7.2 Security Scanning

#### Semgrep MCP (Official)

AST-based security scanning with custom rules. Detects vulnerabilities, code smells, and anti-patterns.

- **Repo:** https://github.com/semgrep/mcp
- **Install:** pip or Docker

```json
{
  "mcp": {
    "semgrep": {
      "type": "local",
      "command": ["python", "-m", "semgrep_mcp"],
      "enabled": true
    }
  }
}
```

---

## 8. Git and GitHub Integration

### 8.1 Local Git Operations

#### Git MCP (Official)

Read, search, and manipulate local git repositories.

- **Install:** `uvx mcp-server-git` or `pip install mcp-server-git`

```json
{
  "mcp": {
    "git": {
      "type": "local",
      "command": ["uvx", "mcp-server-git"],
      "enabled": true
    }
  }
}
```

### 8.2 GitHub API Integration

#### GitHub MCP Server (Official by GitHub)

Full GitHub API access: repos, issues, PRs, code search, actions, workflows. Replaces the deprecated `@modelcontextprotocol/server-github` npm package.

- **Repo:** https://github.com/github/github-mcp-server
- **Install:** Docker (recommended)
- **Requires:** GitHub Personal Access Token

```json
{
  "mcp": {
    "github": {
      "type": "local",
      "command": [
        "docker", "run", "--rm",
        "-e", "GITHUB_PERSONAL_ACCESS_TOKEN",
        "ghcr.io/github/github-mcp-server"
      ],
      "environment": {
        "GITHUB_PERSONAL_ACCESS_TOKEN": "{env:GITHUB_TOKEN}"
      },
      "enabled": true
    }
  }
}
```

> **Note:** The GitHub MCP server exposes 30+ tools. This is a lot of tool definitions for Gemma 4 to parse, and will consume significant context window space. Only enable this if you actively need GitHub API access.

---

## 9. Database Access

#### DBHub (Multi-Database, Recommended)

Zero-dependency database server supporting PostgreSQL, MySQL, MariaDB, SQL Server, and SQLite — all in one.

- **Repo:** https://github.com/bytebase/dbhub
- **Install:** `npm install -g @bytebase/dbhub@latest`

```json
{
  "mcp": {
    "database": {
      "type": "local",
      "command": ["dbhub", "--dsn", "sqlite:///path/to/database.db"],
      "enabled": true
    }
  }
}
```

#### SQLite MCP (Official, Simpler)

If you only need SQLite:

```json
{
  "mcp": {
    "sqlite": {
      "type": "local",
      "command": ["uvx", "mcp-server-sqlite", "--db-path", "/path/to/database.db"],
      "enabled": true
    }
  }
}
```

---

## 10. Documentation Lookup

#### Context7 (by Upstash)

Pulls up-to-date, version-specific documentation and code examples for 9,000+ libraries directly into the model's context. Solves the "outdated training data" problem.

- **Repo:** https://github.com/upstash/context7
- **Install:** `npx -y @upstash/context7-mcp@latest`
- **No API key required**

```json
{
  "mcp": {
    "context7": {
      "type": "local",
      "command": ["npx", "-y", "@upstash/context7-mcp@latest"],
      "enabled": true
    }
  }
}
```

This is one of the most impactful servers for coding — when the model needs to use a library API, it can pull the current docs instead of relying on training data.

---

## 11. Filesystem Extensions

#### Filesystem MCP (Official)

Extends beyond OpenCode's built-in file tools with advanced features: media file handling (base64), line-based edits with diff preview, file metadata (size, timestamps, permissions), and configurable directory access control.

- **Install:** `npx -y @modelcontextprotocol/server-filesystem /allowed/path`

```json
{
  "mcp": {
    "filesystem": {
      "type": "local",
      "command": [
        "npx", "-y", "@modelcontextprotocol/server-filesystem",
        "/home/rompasaurus/COdingProjects"
      ],
      "enabled": true
    }
  }
}
```

> Only add this if you need capabilities beyond OpenCode's built-in `read`/`write`/`edit`/`glob`/`grep` tools.

---

## 12. Gemma 4 Tool Calling: Limitations and Workarounds

### 12.1 Known Issues

Gemma 4 26B has native function/tool calling support, but there are practical issues:

1. **Ollama v0.20.0 is broken for tool calling.** The tool call parser fails and streaming drops tool calls entirely — tool call data goes into the `reasoning` field with empty `content`.
2. **Complex tool chains** (5+ sequential calls) become unreliable — the model may skip steps or hallucinate tool outputs.
3. **Large tool schemas** (many servers with many tools) consume significant context and confuse the model.
4. **No strict schema enforcement** — the model may produce malformed JSON arguments.

### 12.2 Ollama Version Requirements

**You must be on Ollama v0.20.2 or later** for reliable tool calling with Gemma 4.

Check your version:
```bash
ollama --version
```

Update if needed:
```bash
# Windows (from the 4090 host)
winget upgrade Ollama.Ollama

# Or download from https://ollama.com/download
```

If tool calling is still unreliable after updating, consider building llama.cpp from source with the Gemma 4 template fix (PR #21326) and tokenizer fix (PR #21343).

### 12.3 Context Window Budget

Gemma 4 26B runs at 32K context in Ollama by default. Each MCP server's tool definitions consume context tokens. Budget carefully:

| Servers Enabled | Approx. Context Used by Tool Defs | Remaining for Conversation |
|-----------------|-----------------------------------|---------------------------|
| 3 servers | ~2K tokens | ~30K |
| 5 servers | ~4K tokens | ~28K |
| 8 servers | ~7K tokens | ~25K |
| 10+ servers | ~10K+ tokens | ~22K or less |

**Recommendation:** Keep to 5-8 servers maximum. Disable servers you're not actively using (`"enabled": false`).

### 12.4 Gemma 4 vs Claude: Honest Comparison

| Capability | Claude (Opus/Sonnet) | Gemma 4 26B |
|-----------|---------------------|-------------|
| Context window | 200K tokens | 32K (Ollama default) |
| Tool call reliability | Excellent | Good (with Ollama v0.20.2+) |
| Multi-step tool chains | 10+ steps reliably | 3-5 steps reliably |
| Parallel tool calls | Native | Supported but unreliable |
| Strict JSON output | Enforced | Best-effort |
| Reasoning depth | Extended thinking | No structured reasoning |
| Code generation quality | State of the art | Good for common patterns |
| Cost | ~$6/dev/day API | Free (local GPU) |
| Privacy | Cloud-based | Fully local, air-gapped |
| Speed (tokens/sec) | Network-dependent | 30-60 tok/s on 4090 |

**Bottom line:** Gemma 4 on OpenCode won't match Claude Code's depth of reasoning or tool-chaining reliability, but it's free, private, and fast. For straightforward coding tasks and simple research queries, it's genuinely useful. For complex multi-file refactors or deep research, expect to guide it more.

---

## 13. Recommended Configurations

### 13.1 Minimal Setup (3 servers)

Best for keeping context overhead low and maximizing reliability:

| Server | Purpose | Cost |
|--------|---------|------|
| DuckDuckGo Search | Web search | Free |
| Fetch | Read web pages | Free |
| Memory | Persistent knowledge | Free |

### 13.2 Full Setup (8 servers)

For maximum capability coverage:

| Server | Purpose | Cost |
|--------|---------|------|
| DuckDuckGo Search | Web search (free fallback) | Free |
| Tavily | High-quality search | Free (1,000/month) |
| Fetch | Read web pages | Free |
| Playwright | Browser automation | Free |
| Memory | Persistent knowledge | Free |
| Sequential Thinking | Structured reasoning | Free |
| Context7 | Library documentation | Free |
| Git | Local git operations | Free |

### 13.3 Complete opencode.json Example

Full configuration with the recommended 8-server setup:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "ollama": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Ollama (Local 4090)",
      "options": {
        "baseURL": "http://localhost:11434/v1"
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
        "MEMORY_FILE_PATH": "/home/rompasaurus/.opencode/memory.jsonl"
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
      "enabled": false
    },
    "tavily": {
      "type": "remote",
      "url": "https://mcp.tavily.com/mcp/?tavilyApiKey={env:TAVILY_API_KEY}",
      "enabled": false
    }
  }
}
```

> **Note:** Playwright and Tavily are set to `"enabled": false` by default. Enable them when needed to save context tokens.

---

## 14. Installation Walkthrough

### 14.1 Prerequisites

Ensure the following are installed on your system:

```bash
# Node.js and npm (for npx-based MCP servers)
node --version    # v18+ required
npm --version

# Python and uv/uvx (for Python-based MCP servers)
python --version  # 3.10+ required
uv --version      # or pip install uv

# Ollama (v0.20.2+ for reliable tool calling)
ollama --version
```

### 14.2 Step-by-Step Setup

#### Step 1: Update Ollama

Ensure you're on v0.20.2+ for Gemma 4 tool calling:

```bash
# Check current version on the 4090 host
ollama --version

# Update if needed (Windows host)
winget upgrade Ollama.Ollama
```

#### Step 2: Install uv/uvx (Python MCP server runner)

```bash
# Install uv (recommended method)
curl -LsSf https://astral.sh/uv/install.sh | sh

# This installs to ~/.local/bin/ — add to PATH if not already:
export PATH="$HOME/.local/bin:$PATH"
# Add the line above to ~/.bashrc or ~/.zshrc for persistence

# Verify uvx works
uvx --version
```

> **Important:** If `uvx` is not on your system PATH, OpenCode won't find it. Either add `~/.local/bin` to your PATH or use absolute paths in `opencode.json` (e.g., `"/home/youruser/.local/bin/uvx"` instead of `"uvx"`).

#### Step 3: Test MCP servers individually

Before adding to config, verify each server starts correctly:

```bash
# Test DuckDuckGo search
uvx duckduckgo-mcp-server --help

# Test Fetch
uvx mcp-server-fetch --help

# Test Memory
npx -y @modelcontextprotocol/server-memory --help

# Test Sequential Thinking
npx -y @modelcontextprotocol/server-sequential-thinking --help

# Test Context7
npx -y @upstash/context7-mcp@latest --help

# Test Git
uvx mcp-server-git --help
```

#### Step 4: Update opencode.json

Copy the configuration from [Section 13.3](#133-complete-opencodejson-example) into your `opencode.json`.

#### Step 5: Verify in OpenCode

```bash
# List configured MCP servers
opencode mcp list

# Launch OpenCode
opencode
```

### 14.3 Verification

Once inside OpenCode, test each capability:

1. **Web search:** "Search the web for the latest Node.js release"
2. **Page fetching:** "Read the content of https://nodejs.org/en"
3. **Memory:** "Remember that this project uses Gemma 4 26B on a 4090"
4. **Sequential thinking:** "Think through how to implement a REST API step by step"
5. **Documentation:** "Look up the Express.js routing documentation"
6. **Git:** "Show me the git log for this repository"

If any tool fails, check:
- Is the server enabled? (`opencode mcp list`)
- Is the required runtime installed? (Node.js, Python, uv)
- Is Ollama on v0.20.2+? (`ollama --version`)

---

## 15. Troubleshooting

### "Executable not found in $PATH: uvx"

OpenCode can't find `uvx` because `~/.local/bin` isn't in the PATH that OpenCode inherits. Two fixes:

**Option A — Add to PATH (recommended):**
```bash
# Add to ~/.bashrc or ~/.zshrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**Option B — Use absolute paths in opencode.json:**
```json
"command": ["/home/youruser/.local/bin/uvx", "duckduckgo-mcp-server"]
```

### MCP server won't start

```bash
# Check if the command works standalone
uvx duckduckgo-mcp-server
npx -y @modelcontextprotocol/server-memory

# Common fix: clear npm/uv cache
npm cache clean --force
uv cache clean
```

### Tool calls fail silently

1. Check Ollama version — must be v0.20.2+
2. Reduce the number of enabled MCP servers (fewer tool definitions = more reliable)
3. Check OpenCode logs: `opencode --print-logs --log-level DEBUG`

### "UnknownError Server error" with remote MCP

Remove `?transport=sse` from the URL. Use streamable HTTP instead:

```json
// Bad
"url": "https://mcp.example.com/mcp?transport=sse"

// Good
"url": "https://mcp.example.com/mcp"
```

### Context window exhausted quickly

Each MCP server adds tool definitions to the context. Solutions:
- Disable unused servers: `"enabled": false`
- Keep to 5-8 servers maximum
- Use `OLLAMA_CONTEXT_LENGTH=65536` on the host for a larger window (requires more VRAM)

### Model doesn't call tools

Gemma 4 sometimes needs explicit prompting to use tools:
- Instead of: "What's the latest version of React?"
- Try: "Search the web for the latest React version and tell me what you find"

### Playwright browser crashes

```bash
# Install browser dependencies
npx playwright install --with-deps chromium
```

---

## References

### OpenCode Documentation
- [OpenCode Config](https://opencode.ai/docs/config/)
- [OpenCode Providers](https://opencode.ai/docs/providers/)
- [OpenCode MCP Servers](https://opencode.ai/docs/mcp-servers/)
- [OpenCode Tools](https://opencode.ai/docs/tools/)
- [OpenCode Models](https://opencode.ai/docs/models/)

### MCP Ecosystem
- [MCP Official Servers](https://github.com/modelcontextprotocol/servers)
- [MCP Server Directory](https://mcpservers.org)
- [MCP Hub](https://mcp.so)

### MCP Servers Referenced
- [DuckDuckGo MCP](https://github.com/nickclyde/duckduckgo-mcp-server)
- [open-webSearch](https://github.com/Aas-ee/open-webSearch)
- [pskill9/web-search](https://github.com/pskill9/web-search)
- [Tavily MCP](https://github.com/tavily-ai/tavily-mcp)
- [Exa MCP](https://github.com/exa-labs/exa-mcp-server)
- [Fetch MCP (Official)](https://github.com/modelcontextprotocol/servers/tree/main/src/fetch)
- [Playwright MCP (Microsoft)](https://github.com/microsoft/playwright-mcp)
- [Firecrawl MCP](https://github.com/firecrawl/firecrawl-mcp-server)
- [Memory MCP (Official)](https://github.com/modelcontextprotocol/servers/tree/main/src/memory)
- [Sequential Thinking MCP](https://github.com/modelcontextprotocol/servers/tree/main/src/sequentialthinking)
- [Context7 (Upstash)](https://github.com/upstash/context7)
- [Git MCP (Official)](https://pypi.org/project/mcp-server-git/)
- [GitHub MCP (Official)](https://github.com/github/github-mcp-server)
- [ESLint MCP](https://eslint.org/docs/latest/use/mcp)
- [Semgrep MCP](https://github.com/semgrep/mcp)
- [DBHub (Bytebase)](https://github.com/bytebase/dbhub)
- [GPT Researcher](https://github.com/assafelovic/gpt-researcher)
- [Filesystem MCP (Official)](https://github.com/modelcontextprotocol/servers/tree/main/src/filesystem)

### Claude Code Comparison
- [OpenCode vs Claude Code (morphllm)](https://www.morphllm.com/comparisons/opencode-vs-claude-code)
- [OpenCode vs Claude Code (builder.io)](https://www.builder.io/blog/opencode-vs-claude-code)
- [Claude Code Docs](https://code.claude.com/docs/en/)
