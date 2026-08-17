# OpenMed Agent

> **The clinical agent that runs in your terminal — deterministic medical workflows, native coding and terminology tools, reviewable output.**

OpenMed Agent gives clinicians, healthcare operators, and technical teams a terminal-native workspace for the work that sits between the chart and the claim: prior authorization and appeals, coding audit, clinical documentation, care coordination, and consumer health summaries.

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-preview-orange.svg)](#preview-status)
[![Docs](https://img.shields.io/badge/docs-agent.openmed.life-black.svg)](https://agent.openmed.life/docs)

> [!NOTE]
> OpenMed Agent is in preview. The product surface is real and usable today; the hosted medical-service tier is still evolving. See [Preview status](#preview-status).

## Install

```bash
# macOS / Linux
curl -fsSL "<install.sh URL shared during preview>" | bash

# Windows
irm "<install.ps1 URL shared during preview>" | iex
```

Install URLs are shared with evaluators during preview — [request access](https://agent.openmed.life).

## Quickstart

```bash
openmed login   # Authenticate with OAuth
openmed         # Launch the agent
openmed --help  # Full CLI reference
```

Or bring your own key:

```bash
openmed config provider-set openai --api-key "sk-..."
openmed config provider-set anthropic --api-key "sk-ant-..."
```

Runs on GPT-5.5 / GPT-5.6 and Claude models. `gpt-5.6-terra` at medium reasoning is the default; switch model, reasoning effort, skill, and agent mode from the TUI or with `openmed agent`.

## What it does

OpenMed Agent combines LLM reasoning with deterministic workflows and native medical tools. Describe the task in natural language, and the agent can:

- Review prior authorization and appeal cases against structured criteria
- Audit ICD-10 coding with HCC and RAF context
- Explain EOB and claims data in plain language
- Extract entities or de-identify clinical text
- Summarize consumer health records from Apple Health, Health Connect export, C-CDA, FHIR export, and labs files
- Triage inbox threads, draft reviewer-safe replies, and generate discharge handoffs
- Search PubMed and use protected terminology services for ICD-10, CPT, SNOMED, LOINC, RxNorm, MedlinePlus, HCC, and RAF

## What ships in preview

- `62` native tools
- `13` deterministic workflows with draft/finalize
- `13` built-in skills
- `4` agent modes: `clinical`, `consumer`, `coordination`, `plan`
- `104` demo scenarios covering every capability area

## Key capabilities

### Protected medical services

- **Clinical extraction** — entity extraction, PII detection, and de-identification through protected service endpoints
- **Terminology and coding** — ICD-10, CPT, SNOMED, LOINC, RxNorm, MedlinePlus, HCC, and RAF, with validation, crosswalks, and PubMed-backed lookup
- **Configurable deployment boundary** — the operator runtime stays local while medical-service endpoints can be moved across hosted, cloud, or customer-managed environments

### Clinical and operational workflows

- **Prior authorization and appeals** — review requests against deterministic criteria and structured evidence
- **Coding audit** — specificity review, compliance flags, HCC mapping, and RAF impact
- **Claims explanation** — patient-friendly EOB and billing explanations with clear next steps
- **Clinical documentation** — structured SOAP-style documentation from notes or transcripts
- **Care coordination** — inbox triage, reviewer-safe patient drafts, discharge and PCP handoffs, follow-up tasks
- **Consumer health** — record normalization, timeline and trend analysis, visit-prep questions, narratives, reconciliation, optional education topics, and optional FHIR output

### Agent runtime

- **Project instructions** — drop an `OPENMED.md` in your project root to shape agent behavior per workspace
- **Permission policy** — rule-based `auto` / `acceptall` / `denyall` / `plan` modes, with per-tool allow, deny, and ask rules from project or user settings
- **Tool safety classification** — every tool carries `is_read_only`, `is_concurrent_safe`, and `is_destructive` metadata used by the permission system
- **Oversized result handling** — large tool outputs persist to disk automatically, leaving compact stubs in context
- **Runtime diagnostics** — `/config` shows effective settings, loaded sources, and active project instructions

### Agent experience

- **Interactive TUI** — sessions, themes, model and skill switching, and workflow execution in the terminal
- **Draft and finalize** — reviewable cards, artifacts, provenance, and workflow diffs
- **Skills** — built-in clinical skills that shape how the agent approaches domain work
- **Plan auto-advance** — structured plans with deterministic, tool-based progress tracking
- **Session persistence** — save, restore, fork, and roll back conversations
- **Optional MCP** — connect external medical or institutional systems without changing the native tool surface
- **Self-update** — built-in binary updates with release checks

## Preview status

- The product surface is real and usable today
- The hosted medical-service tier is still evolving
- Some service-backed capabilities are operated by OpenMed during preview rather than fully self-serve
- Workflow, deployment, and integration details may continue to tighten as the product hardens

During preview, OpenMed operates the protected clinical-service endpoints so evaluators do not have to deploy extraction and terminology infrastructure themselves.

## Where the boundary sits

The operator runtime — sessions, artifacts, project instructions, and permission rules — stays on your machine. Medical capabilities call configured protected endpoints when those paths are invoked, and those endpoints can be moved across hosted, cloud, or customer-managed environments.

Three things worth stating plainly:

- **Not fully offline.** Invoking a protected capability means a call to a configured endpoint.
- **PHI handling modes are settings, not guarantees.** They are operator-visible workflow controls, not a blanket promise that every code path enforces the same policy.
- **No telemetry.** No built-in analytics or phone-home tracking ships with the product.

Reviewability is a core product characteristic: final clinical artifacts and care-coordination outputs are designed to be inspected before use.

---

[Website](https://agent.openmed.life) · [Documentation](https://agent.openmed.life/docs) · [X/Twitter](https://x.com/openmed_ai) · [LinkedIn](https://www.linkedin.com/company/openmed-ai/)
