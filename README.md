# OpenMed Agent

> Clinical AI in your terminal — medical workflows, coding and terminology tools, and reviewable output.

OpenMed Agent helps clinicians, healthcare operators, and technical teams work with clinical records, prior authorizations, appeals, coding, documentation, and care coordination. Choose a model provider, describe the task, and review the resulting plans, citations, and workflow artifacts.

**Latest release: [v1.0.3](https://github.com/openmed-labs/openmed-agent/releases/tag/v1.0.3)** · [All release notes](https://github.com/openmed-labs/openmed-agent/releases) · [Documentation](https://agent.openmed.life/docs/)

OpenMed Agent 1.0 is the final release line, and v1.0.3 is its last maintenance update. No further versions are planned, and there is no obligation to provide updates or support. This repository provides product information and public release notes. Your install link is sent with your access invitation; if you do not have one, [request access](https://waitlist.openmed.life/).

## What's new in 1.0

- **Headless runs:** `openmed agent --once` runs one request through the agent and its tools, then exits with a clean answer, an optional JSON receipt, and documented exit codes.
- **Newer models without an update:** use OpenAI and Anthropic model IDs newer than the built-in list, and save a default with `openmed config model-set`.
- **API keys first:** an OpenAI API key is the recommended way to use OpenAI models. ChatGPT sign-in remains available as an experimental option.
- **Service interruptions are reported:** reviews stop with a clear error, and coding workflows mark their output DEGRADED, instead of deciding from missing reference data.
- **Risk scores are labelled as estimates**, with the model, payment year, segment, and demographics used.
- **DEID mode is enforced:** in DEID and STRICT modes, workflows that read local files and tools that return raw record content are refused.

See the [v1.0.3 notes](https://github.com/openmed-labs/openmed-agent/releases/tag/v1.0.3), the [v1.0.0 notes](https://github.com/openmed-labs/openmed-agent/releases/tag/v1.0.0), the [provider guide](https://agent.openmed.life/docs/providers/), and the [release history](https://github.com/openmed-labs/openmed-agent/releases).

## Get started

Install with the link from your access invitation, then run:

```bash
openmed config provider-set openai --api-key "sk-..."   # Or another provider's key
openmed                # Open the terminal workspace
openmed --models       # List available models
openmed --help         # Show CLI commands
```

You can use an OpenAI, Anthropic, OpenRouter, MiMo, or Doubleword API key, or connect a custom OpenAI-compatible server. Follow the [provider setup guide](https://agent.openmed.life/docs/providers/).

GPT-6.1 Sol at medium reasoning is the default. Switch the model, reasoning effort, skill, and agent mode from the terminal interface, or save your own default with `openmed config model-set`.

To check for or install an update:

```bash
openmed --check-update
openmed update
```

[Getting started](https://agent.openmed.life/docs/getting-started/) · [Long-term use](https://agent.openmed.life/docs/long-term-use/) · [CLI reference](https://agent.openmed.life/docs/cli/) · [Headless workflows](https://agent.openmed.life/docs/headless-agent/) · [Terminal interface](https://agent.openmed.life/docs/tui/)

## Clinical and operational capabilities

| Area | What you can do |
| --- | --- |
| Prior authorization and appeals | Review requests, coverage criteria, and denial evidence; prepare reviewable drafts. |
| Coding and claims | Audit ICD-10 coding, inspect HCC and RAF context, use clinical classification and risk-model tools, and explain EOB or claims data. |
| Clinical documentation | Turn notes or transcripts into structured clinical documentation and SOAP-style drafts. |
| Care coordination | Triage inbox threads, prepare patient replies, create discharge and PCP handoffs, and organize follow-up tasks. |
| Consumer health | Summarize Apple Health, Health Connect, C-CDA, FHIR exports, and lab files; inspect timelines, trends, and visit-preparation questions. |
| Clinical text and evidence | Extract entities, de-identify text, search PubMed, and use coding and terminology lookups. |

Medical tools cover ICD-10, CPT, SNOMED CT, LOINC, RxNorm, MedlinePlus, HCC, CCSR, comorbidities, RxHCC, ESRD, and Orphanet. Availability depends on the medical services configured for your installation.

## Work in a reviewable workspace

- **Draft and finalize:** inspect workflow previews, artifacts, citations, and differences before completing a workflow.
- **Saved sessions:** return to conversations with their plans and previous tool results available for follow-up work.
- **Files and citations:** use `@` file and directory completion, select response text, and copy code blocks with `/copy`.
- **Project instructions and skills:** use `OPENMED.md` for workspace guidance and select built-in or custom skills for domain work.
- **Permissions:** configure tool approval behavior for your workspace.
- **Optional MCP:** connect additional medical or institutional tools.
- **Optional web search:** enable client-side search when needed; it is off by default.

[Skills](https://agent.openmed.life/docs/skills/) · [Configuration](https://agent.openmed.life/docs/configuration/) · [Web search](https://agent.openmed.life/docs/web-search/)

## Data handling

Sessions and generated artifacts are stored on the machine running OpenMed. Model requests and medical-service calls use your configured providers and endpoints. Choosing a local model does not make connected medical services offline.

Some medical services are operated by OpenMed and are provided as available; you can point either service at your own compatible server instead. DEID and STRICT modes restrict what reaches the model, but de-identification is automated and can miss identifiers. Review clinical outputs before use.

[Native medical services](https://agent.openmed.life/docs/native-medical-services/) · [Privacy and security](https://agent.openmed.life/docs/privacy/)

---

[Website](https://agent.openmed.life/) · [Documentation](https://agent.openmed.life/docs/) · [Releases](https://github.com/openmed-labs/openmed-agent/releases) · [Repository license](LICENSE)
