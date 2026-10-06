# OpenMed Agent

> Clinical AI in your terminal — medical workflows, coding and terminology tools, and reviewable output.

OpenMed Agent helps clinicians, healthcare operators, and technical teams work with clinical records, prior authorizations, appeals, coding, documentation, and care coordination. Choose a model provider, describe the task, and review the resulting plans, citations, and workflow artifacts.

**Latest release: [v0.6.0](https://github.com/openmed-labs/openmed-agent/releases/tag/v0.6.0)** · [All release notes](https://github.com/openmed-labs/openmed-agent/releases) · [Documentation](https://agent.openmed.life/docs/)

OpenMed Agent is in preview. This repository provides product information and public release notes. Installation instructions are shared with approved evaluators through the [preview access page](https://agent.openmed.life/).

## What's new

- **Updated model picker:** choose GPT-6.1 Sol, GPT-6 Astra, GPT-6 Sol, or GPT-6 Luna. GPT-6.1 Sol with medium reasoning is the default.
- **Reasoning controls:** available effort levels follow the selected model. Existing `none` settings use `low` with GPT-6.1 Sol and GPT-6 Astra.
- **Saved models:** GPT-5.6 IDs and the `gpt-5.6` alias are retired. Update saved selections to a current model ID; explicit GPT-5.5 selections remain available with an OpenAI API key.
- **Clearer setup and coding guidance:** provider setup tabs support keyboard selection, and the medical-service guide distinguishes code validity, membership, billability, and HCC reference context.

Doubleword supports real-time agent work, async flex requests, and 24-hour batches with one key. The TUI is real-time; async and batch jobs use the CLI. Direct request files do not execute agent tools or automatically de-identify input.

See the [v0.6.0 notes](https://github.com/openmed-labs/openmed-agent/releases/tag/v0.6.0), the [provider guide](https://agent.openmed.life/docs/providers/), and the [release history](https://github.com/openmed-labs/openmed-agent/releases).

## Get started

Use the installation instructions supplied with your preview access, then run:

```bash
openmed login          # Sign in with ChatGPT
openmed                # Open the terminal workspace
openmed --models       # List available models
openmed --help         # Show CLI commands
```

You can also configure your own OpenAI, Anthropic, OpenRouter, MiMo, or Doubleword API key, or connect a custom OpenAI-compatible server. Follow the [provider setup guide](https://agent.openmed.life/docs/providers/).

GPT-6.1 Sol at medium reasoning is the default for this preview. Switch the model, reasoning effort, skill, and agent mode from the terminal interface.

To check for or install an update:

```bash
openmed --check-update
openmed update
```

[Getting started](https://agent.openmed.life/docs/getting-started/) · [CLI reference](https://agent.openmed.life/docs/cli/) · [Terminal interface](https://agent.openmed.life/docs/tui/)

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

## Preview and data handling

Sessions and generated artifacts are stored on the machine running OpenMed. Model requests and medical-service calls use your configured providers and endpoints. Choosing a local model does not make connected medical services offline.

During preview, some medical services are operated by OpenMed. Service availability and integration details may change as the preview develops. PHI handling modes are workflow settings; they do not provide a blanket privacy guarantee. Review clinical outputs before use.

[Native medical services](https://agent.openmed.life/docs/native-medical-services/) · [Privacy and security](https://agent.openmed.life/docs/privacy/)

---

[Website](https://agent.openmed.life/) · [Documentation](https://agent.openmed.life/docs/) · [Releases](https://github.com/openmed-labs/openmed-agent/releases) · [Repository license](LICENSE)
