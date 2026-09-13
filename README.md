# OpenMed Agent

> Clinical AI in your terminal — medical workflows, coding and terminology tools, and reviewable output.

OpenMed Agent helps clinicians, healthcare operators, and technical teams work with clinical records, prior authorizations, appeals, coding, documentation, and care coordination. Choose a model provider, describe the task, and review the resulting plans, citations, and workflow artifacts.

**Latest release: [v0.3.0](https://github.com/openmed-labs/openmed-agent/releases/tag/v0.3.0)** · [All release notes](https://github.com/openmed-labs/openmed-agent/releases) · [Documentation](https://agent.openmed.life/docs/)

OpenMed Agent is in preview. This repository provides product information and public release notes. Installation instructions are shared with approved evaluators through the [preview access page](https://agent.openmed.life/).

## What's new

- **More model choices:** OpenRouter and custom OpenAI-compatible endpoints, including servers such as vLLM and SGLang, alongside OpenAI and Anthropic.
- **A searchable model picker:** provider groups, Favorites, and Recent models, with `Ctrl+F` to favorite a model. `openmed --models` lists models available through your configured providers.
- **Smoother long sessions:** more compact plans and reasoning, improved scrolling and session recovery, and better handling of context limits and temporary provider errors.
- **Easier workflow handoffs:** request drafts or ready-to-deliver outputs in natural language, continue an active draft with a follow-up, and inspect clickable citations.
- **Expanded coding tools:** CCSR classification, comorbidity analysis, RxHCC and ESRD risk models, and Orphanet rare-disease mappings.
- **Simpler updates and sign-in:** update checks in the terminal, in-place macOS updates, and improved ChatGPT sign-in and recovery.

See the [v0.3.0 notes](https://github.com/openmed-labs/openmed-agent/releases/tag/v0.3.0) for the latest changes and the [release history](https://github.com/openmed-labs/openmed-agent/releases) for earlier additions and fixes.

## Get started

Use the installation instructions supplied with your preview access, then run:

```bash
openmed login          # Sign in with ChatGPT
openmed                # Open the terminal workspace
openmed --models       # List available models
openmed --help         # Show CLI commands
```

You can also configure your own OpenAI, Anthropic, or OpenRouter API key, or connect a custom OpenAI-compatible server. Follow the [provider setup guide](https://agent.openmed.life/docs/providers/).

GPT-5.6 Terra at medium reasoning is the default for this preview. Switch the model, reasoning effort, skill, and agent mode from the terminal interface.

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
