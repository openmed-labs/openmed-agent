# OpenMed Agent

> **AI-powered medical assistant with interactive TUI, agentic workflows, and remote NLP inference**

OpenMed Agent provides an intelligent terminal interface for clinical workflows — entity extraction, PII de-identification, and medical reasoning — powered by LLMs and remote NLP inference.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

---

## Install

### Binary (recommended)

```bash
curl -fsSL https://agent.openmed.life/install.sh | bash
```

### pip

```bash
pip install openmed-agent[tui]
```

---

## Features

- **Interactive Agent TUI** — Rich terminal interface for clinical analysis and medical reasoning
- **Remote NLP Inference** — NER and PII tools connect to remote inference endpoints
- **MCP Server Integration** — Connect to medical data sources (PubMed, ICD-10, NPI, CMS)
- **Agentic Workflows** — Plan-based execution with skill-driven task automation
- **PHI Handling Modes** — Full, de-identified, and strict modes for HIPAA-aware workflows
- **Self-Update** — Binary releases with built-in update mechanism

---

## Usage

```bash
openmed            # Launch interactive agent TUI
openmed agent      # Explicit agent command
openmed login      # Authenticate via OAuth
openmed --help     # Full CLI reference
```

---

## Documentation

Visit [agent.openmed.life](https://agent.openmed.life) for full documentation and CLI reference.

---

## License

Released under the [Apache-2.0 License](LICENSE).
