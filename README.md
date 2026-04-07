# OpenMed Agent

> **Preview medical workflow agent for the terminal — local operator runtime, protected medical services, reviewable outputs**

OpenMed Agent is currently in preview. It gives clinicians, healthcare operators, and technical teams a terminal-native workspace for clinical and operational workflows such as prior authorization review, appeal review, coding audit, consumer health summaries, care coordination, and clinical documentation.

[![Python 3.10+](https://img.shields.io/badge/python-3.10+-blue.svg)](https://www.python.org/downloads/)

---

## Install

```bash
curl -fsSL "<install.sh URL shared during preview>" | bash
```

---

## Preview Status

OpenMed Agent is in preview, which means:

- the product surface is real and usable today
- the hosted medical-service tier is still evolving
- some service-backed capabilities are operated by OpenMed during preview rather than fully self-serve
- workflow, deployment, and integration details may continue to tighten as the product hardens

During preview, OpenMed operates the protected clinical-service endpoints so evaluators do not need to deploy extraction and terminology infrastructure themselves.

---

## What It Does

OpenMed Agent combines LLM reasoning with deterministic workflows and native medical tools. You describe what you need in natural language, and the agent can:

- review prior authorization and appeal cases against structured criteria
- audit ICD-10 coding with HCC and RAF context
- explain EOB and claims data in plain language
- extract entities or de-identify clinical text
- summarize consumer health records from Apple Health, Health Connect export, C-CDA, FHIR export, and labs files
- triage inbox threads, draft reviewer-safe replies, and generate discharge handoffs
- search PubMed and use protected terminology services for ICD-10, CPT, SNOMED, LOINC, RxNorm, MedlinePlus, HCC, and RAF

```bash
openmed            # Launch the agent
openmed agent      # Launch with options (model, reasoning effort, skill, agent mode)
openmed --help     # Full CLI reference
```

---

## What Ships In Preview

- `62` built-in native tools
- `13` deterministic workflows with draft/finalize
- `13` built-in skills
- `4` agent modes: `clinical`, `consumer`, `coordination`, `plan`
- `104` demo scenarios covering all capability areas

---

## Key Capabilities

### Protected Medical Services

- **Clinical extraction** — entity extraction, PII detection, and de-identification through protected native service endpoints
- **Medical terminology and coding** — ICD-10, CPT, SNOMED, LOINC, RxNorm, MedlinePlus, HCC, RAF, validation, crosswalks, and PubMed-backed lookup
- **Configurable deployment boundary** — the operator runtime stays local while medical-service endpoints can be moved across hosted, cloud, or customer-managed environments

### Clinical And Operational Workflows

- **Prior authorization and appeals** — review requests against deterministic criteria and structured evidence
- **Coding audit** — specificity review, compliance flags, HCC mapping, and RAF impact
- **Claims explanation** — patient-friendly EOB and billing explanations with next-step guidance
- **Clinical documentation** — structured SOAP-style documentation from notes or transcripts
- **Care coordination** — inbox triage, reviewer-safe patient drafts, discharge handoff, PCP handoff, and follow-up tasks
- **Consumer health** — imported health-record normalization, timeline/trend analysis, visit-prep questions, narratives, reconciliation, optional education topics, and optional FHIR output

### Agent Runtime

- **Project instructions** — drop an `OPENMED.md` file in your project root to customize agent behavior per workspace
- **Permission policy** — rule-based `auto`/`acceptall`/`denyall`/`plan` modes with per-tool allow/deny/ask rules from project or user settings
- **Tool safety classification** — every tool carries `is_read_only`, `is_concurrent_safe`, and `is_destructive` metadata used by the permission system
- **Oversized result handling** — large tool outputs automatically persisted to disk with compact in-context stubs
- **Runtime diagnostics** — `/config` command shows effective settings, loaded sources, and active project instructions

### Agent Experience

- **Interactive TUI** — terminal interface with sessions, themes, model switching, skill switching, and workflow execution
- **Draft/finalize workflow lifecycle** — reviewable cards, artifacts, provenance, and workflow diffs
- **Skill system** — built-in clinical skills that bias how the agent approaches domain-specific work
- **Plan auto-advance** — structured plans with deterministic tool-based progress tracking
- **Session persistence** — save, restore, fork, and rollback conversation sessions
- **Optional MCP integration** — connect external medical or institutional systems without changing the native tool surface
- **Self-update** — built-in binary update path with release checks
- **No telemetry** — OpenMed does not ship built-in analytics or phone-home tracking

---

## Important Boundary Notes

- OpenMed Agent is not a universally offline product.
- The operator runtime is local, but many medical capabilities call configured protected endpoints when those paths are invoked.
- PHI handling modes are operator-visible workflow settings, not a blanket guarantee that every code path is automatically enforced the same way.
- Reviewability is a core product characteristic. Final clinical artifacts and care-coordination outputs are designed to be inspected before use.

---

Visit [agent.openmed.life](https://agent.openmed.life) for full documentation.

---

[Website](https://agent.openmed.life) | [Documentation](https://agent.openmed.life/docs) | [X/Twitter](https://x.com/openmed_ai) | [LinkedIn](https://www.linkedin.com/company/openmed-ai/)
