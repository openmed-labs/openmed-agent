# OpenMed Agent

> **AI-powered medical assistant for the terminal — private, sandboxed, and built for clinical workflows**

An intelligent command-line agent for healthcare professionals and developers. Automate clinical documentation, research medical evidence, and process patient data — all within a sandboxed environment designed for privacy and regulatory compliance.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

---

## Install

```bash
curl -fsSL https://agent.openmed.life/install.sh | bash
```

---

## What It Does

OpenMed Agent is an interactive terminal application that combines LLM reasoning with medical tools. You describe what you need in natural language, and the agent executes multi-step clinical workflows — generating PA letters, extracting entities from clinical notes, looking up drug interactions, checking LCD coverage criteria, and more.

```bash
openmed            # Launch the agent
openmed agent      # Launch with options (model, reasoning effort, skill)
openmed --help     # Full CLI reference
```

---

## Key Features

### Privacy & Safety

- **Sandboxed Execution** — All tool calls run in a controlled environment with explicit user approval
- **PHI Handling Modes** — `full`, `deid`, and `strict` modes for HIPAA/GDPR-aware workflows
- **Local-First Architecture** — Patient data stays on your machine; nothing leaves without explicit consent
- **No Telemetry** — Zero data collection, no analytics, no phone-home

### Clinical Workflows

- **Prior Authorization** — Generate PA letters with clinical evidence and LCD/NCD criteria
- **Entity Extraction** — Identify diseases, medications, procedures, and anatomy from clinical text
- **Medical Research** — Query PubMed, ICD-10, NPI, and CMS databases via MCP servers
- **PDF Export** — Produce clinical documents, appeal packets, and visit prep reports

### Agent Capabilities

- **Interactive TUI** — Rich terminal interface with conversation history, themes, and session management
- **Agentic Workflows** — Plan-based execution with automatic step progression
- **Skill System** — Pre-built clinical skills that guide the agent through complex multi-step tasks
- **MCP Integration** — Connect to remote medical data sources for real-time evidence lookup
- **Self-Update** — Built-in binary update mechanism with SHA-256 verification

---

Visit [agent.openmed.life](https://agent.openmed.life) for full documentation.

---

## License

Released under the [Apache-2.0 License](LICENSE).

---

[Website](https://agent.openmed.life) | [Documentation](https://agent.openmed.life/docs) | [X/Twitter](https://x.com/openmed_ai) | [LinkedIn](https://www.linkedin.com/company/openmed-ai/)
