# Changelog

## 2026.9.18

### Changed
- report-outputs: diagram style fixed — Excalidraw hand-drawn look (Caveat labels, rounded stroke-only boxes, 1.2–1.8px strokes), Korean body text IBM Plex Sans KR; follow-up explainer diagrams keep the same style.

## 2026.9.17

### Changed
- judge writes to `./judge/<ts>.md|html` in the project the question was asked from, instead of `.claude/council-cache/`. `/judge/` is gitignored.

## 2026.9.16

### Added
- `report-outputs` skill: on "보고해줘", builds a result-first HTML report (frontend-design → artifact-design → plain fallback) and publishes it as an Artifact.
- `context-init`, `context-engineering`, `loop-engineering` skills imported unchanged from zkfmapf123/context_skills v0.2.0. `/context-init` is now `/common:context-init`.

## 2026.9.15

First real run (8 lenses, EKS/GKE/AKS) reviewed from the transcript and the
executing session's own notes.

### Fixed
- Lens picker: one numbered menu + one question (presets, or numbers via Other). The four-screen picker produced `Question texts must be unique`.
- Model options: bare label (`opus`), note in description — the answer is the model id.
- Command tells the model to Read `SKILL.md`, `member-prompt.md`, `roles.json` directly; the Skill tool returns no file contents.
- Members answer in the question's language; explicit rule for non-code decision questions; 350-word cap.

### Changed
- Clarifying round before spawning: the 1–3 NOT VERIFIED items the answer hinges on are asked once, instead of every member repeating "depends on X".
- Chat shows one line per member plus the synthesis; the full transcript lives in the `.md`.
- HTML report is `build-report.sh` dropping the markdown into `report-template.html` (marked.js renders it) — no design skill, no second hand-written copy.
- Synthesis sits under a `## Synthesis` header; banner localized.

## 2026.9.14

Forked from hex/claude-council, renamed `common`, cut down to the local (Claude-only) council.

### Removed
- All external providers (OpenAI, Gemini, Grok, Perplexity, Kimi, OpenRouter, ollama) and their CLIs.
- Bash pipeline (`scripts/`), tmux pane, `mods/council-pane`, stop-review gate, async jobs.
- Commands `advise`, `result`, `status`; skills `council-execution`, `deep-execution`, `provider-integration`.
- bats tests, shellcheck, GitHub workflows.

### Changed
- `local-council-execution` skill renamed to `judge`; no longer a fallback — it is the only mode.
- Role prompts built from `config/roles.json` directly by the model; no jq/bash needed.
- Repo laid out as a multi-skill plugin: one directory per skill under `skills/`, one file per command under `commands/`.
