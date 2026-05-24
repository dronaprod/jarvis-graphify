# jarvis-graphify

> **Enriched code knowledge graph** — point it at any codebase and get an interactive graph where every node has a working summary, every library has a threat profile, and every sensitive file is flagged.

---

## Install — one command

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/drona-jarvis-org/jarvis-graphify-releases/main/install.sh | bash
```

**Windows (PowerShell):**
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/drona-jarvis-org/jarvis-graphify-releases/main/install.ps1" -OutFile install.ps1; .\install.ps1
```

After install, restart your terminal then verify:
```bash
jarvis-graphify --version
```

---

## What it does

```
Your codebase
     │
     ▼
jarvis-graphify .
     │
     ├── graph.html             ← interactive graph (open in any browser)
     ├── graph.json             ← full graph data with summaries
     └── graph_understanding.md ← text report of every entity
```

Every node in the graph gets a **working summary** written by your LLM:

| Node type | Summary sections |
|-----------|-----------------|
| File | WHAT · WHY · IMPACT · EXTEND |
| Class | WHAT · WHY · IMPACT · EXTEND |
| Function / Method | WHAT · WHY · IMPACT · EXTEND |
| Library / Import | WHAT · WHY · IMPACT · DECAY · VULNERABILITIES |

Plus:
- **⭐ Entry point detection** — `main()`, HTTP routes, CLI commands, `__main__` blocks
- **🔴 Sensitive file detection** — credentials, tokens, PII, connection strings flagged red
- **Traversal paths** — click any entry point and walk the graph node-by-node with breadcrumb trail
- **Zero cloud dependency option** — works fully offline with a local Ollama model

---

## Quick start

### 1 · Install

```bash
curl -fsSL https://raw.githubusercontent.com/drona-jarvis-org/jarvis-graphify-releases/main/install.sh | bash
source ~/.zshrc
```

### 2 · Create config in your project

```bash
cd /path/to/your-project
jarvis-graphify setup
```

This creates `jarvis-graphify-in/settings.json`. Edit it to set your LLM backend (see below).

### 3 · Run

```bash
jarvis-graphify .
open jarvis-graphify-out/graph.html     # macOS
xdg-open jarvis-graphify-out/graph.html # Linux
```

---

## LLM backends

Set `"backend"` in `jarvis-graphify-in/settings.json` to one of: `ollama` · `litellm` · `bedrock`

---

### Option A — Ollama (local, no API key, fully offline)

Ollama runs models locally on your machine. Supports **any model available via Ollama** —
qwen3, llama3, mistral, phi3, gemma2, deepseek, and more.

```bash
# Install Ollama (macOS)
brew install ollama

# Pull a model and start the server
ollama pull qwen3:4b
ollama serve
```

```json
{
  "llm": {
    "backend": "ollama",
    "ollama": {
      "base_url": "http://127.0.0.1:11434",
      "model": "qwen3:4b"
    }
  }
}
```

> List available models: `ollama list`  
> Hosted Ollama server with TLS? Add `"ssl_verify": false` for self-signed certs.

---

### Option B — LiteLLM / OpenAI-compatible APIs

Works with **any endpoint that speaks OpenAI's `/chat/completions` format**:

| Platform | Notes |
|----------|-------|
| **LiteLLM proxy** | Self-hosted unified gateway to 100+ providers |
| **vLLM** | Self-hosted high-throughput inference server |
| **TensorRT-LLM** | NVIDIA GPU-optimised inference |
| **Custom Python** | Any FastAPI/Flask server with OpenAI-style API |
| **OpenRouter** | `https://openrouter.ai/api/v1` — 100+ models, one key |
| **Azure OpenAI** | Your Azure deployment endpoint |
| **Groq, Together AI, Anyscale** | Drop in their base_url + api_key |

```json
{
  "llm": {
    "backend": "litellm",
    "litellm": {
      "base_url": "https://your-litellm-server.example.com",
      "model": "gpt-4o",
      "api_key": "sk-YOUR-KEY-HERE",
      "ssl_verify": false
    }
  }
}
```

**Or read the key from an environment variable** (keeps secrets out of the file):
```json
{
  "llm": {
    "backend": "litellm",
    "litellm": {
      "base_url": "https://openrouter.ai/api/v1",
      "model": "anthropic/claude-3-haiku",
      "api_key_env": "OPENROUTER_API_KEY"
    }
  }
}
```
```bash
export OPENROUTER_API_KEY="sk-or-..."
```

> `"ssl_verify": false` — use for corporate/self-signed certificates.

---

### Option C — AWS Bedrock

Access Claude, Llama, Mistral, Titan and other foundation models via **AWS managed infrastructure**.
No model hosting needed — pay per token.

**Available models (examples):**

| Model | model_id |
|-------|---------|
| Claude 3.5 Haiku | `anthropic.claude-3-5-haiku-20241022-v1:0` |
| Claude 3.5 Sonnet | `anthropic.claude-3-5-sonnet-20241022-v2:0` |
| Llama 3.3 70B | `meta.llama3-3-70b-instruct-v1:0` |
| Mistral Large | `mistral.mistral-large-2402-v1:0` |
| Amazon Titan Premier | `amazon.titan-text-premier-v1:0` |

```json
{
  "llm": {
    "backend": "bedrock",
    "bedrock": {
      "region": "us-east-1",
      "model_id": "anthropic.claude-3-5-haiku-20241022-v1:0",
      "aws_access_key_id": "AKIAIOSFODNN7EXAMPLE",
      "aws_secret_access_key": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
    }
  }
}
```

**Or use environment variables (recommended — no keys in files):**
```bash
export AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE
export AWS_SECRET_ACCESS_KEY=wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY
export AWS_DEFAULT_REGION=us-east-1
```
```json
{
  "llm": {
    "backend": "bedrock",
    "bedrock": {
      "region": "us-east-1",
      "model_id": "anthropic.claude-3-5-haiku-20241022-v1:0"
    }
  }
}
```

**Credential resolution order:**
1. Explicit keys in `settings.json`
2. `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` / `AWS_SESSION_TOKEN` env vars
3. `~/.aws/credentials` profile (`aws configure`)
4. IAM role attached to EC2 / ECS / Lambda (no config needed)

**Install boto3** (required for Bedrock, not bundled):
```bash
pip install boto3
# or inside the jarvis-graphify venv:
~/.jarvis-graphify/venv/bin/pip install boto3
```

> Enable the model in your AWS account first:  
> AWS Console → Bedrock → Model access → Request access

---

## All commands

```bash
jarvis-graphify .                        # full scan — current directory
jarvis-graphify /path/to/project         # scan any directory
jarvis-graphify . --no-enrich            # structure + sensitive detection only (no LLM)
jarvis-graphify . --out /tmp/my-graph    # custom output directory
jarvis-graphify . -v                     # verbose — show each node as enriched

jarvis-graphify scan .                   # explicit subcommand form
jarvis-graphify setup                    # create config in current directory
jarvis-graphify setup --force            # overwrite existing config

jarvis-graphify --version
jarvis-graphify --help
```

---

## Using the graph

Open `jarvis-graphify-out/graph.html` in any browser — no internet required.

| Action | Result |
|--------|--------|
| **Click a node** | WHAT / WHY / IMPACT / EXTEND in the sidebar |
| **Click a library** | WHAT / WHY / IMPACT / DECAY / VULNERABILITIES |
| **Click a 🔴 red node** | Sensitive findings (category + line number) |
| **Entry point chips ⭐** | Jump to any entry point |
| **Next nodes panel** | All outgoing connections — click to traverse |
| **Breadcrumb trail** | Navigate back through your path |
| **Search box** | Find and highlight any node |
| Scroll / Drag | Zoom / Pan |

### Node colours

| Colour | Meaning |
|--------|---------|
| ⭐ Gold star | Entry point |
| 🔵 Blue box | Source file |
| 🟠 Orange ellipse | Class |
| 🟢 Green dot | Function |
| 🩵 Teal dot | Method |
| 🔴 Red diamond | Library / import |
| 🔴 Red (any shape) | Sensitive file — credentials / PII / secrets detected |

---

## Troubleshooting

**`jarvis-graphify: command not found`**
```bash
export PATH="$HOME/.local/bin:$PATH"
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
```

**`No LLM config found`**  
Run `jarvis-graphify setup`, then edit `jarvis-graphify-in/settings.json`.

**`SSL: CERTIFICATE_VERIFY_FAILED`**  
Add `"ssl_verify": false` to the `ollama` or `litellm` block.

**`Connection refused` (Ollama)**  
Start the server: `ollama serve`

**`boto3 is required for AWS Bedrock`**  
```bash
~/.jarvis-graphify/venv/bin/pip install boto3
```

**`Could not connect to the endpoint URL` (Bedrock)**  
Check your `region` and that the model is enabled in AWS Console → Bedrock → Model access.

**LLM returns empty responses**  
Run `jarvis-graphify . -v` to see which nodes fail. Try a smaller/faster model or check rate limits.

---

## How it works

```
scanner.py     → AST-based code scan (Python) + regex (JS/TS/Java/Go)
                 detects: files, classes, functions, methods, imports
                 flags:   entry points, sensitive data

enricher.py    → sends each node to your LLM for a structured summary
                 code nodes:    WHAT / WHY / IMPACT / EXTEND
                 library nodes: WHAT / WHY / IMPACT / DECAY / VULNERABILITIES

graph_builder  → assembles nodes + edges, BFS traversal from each entry point

renderer.py    → graph.html (vis.js), graph.json, graph_understanding.md
```

---

## License

MIT
