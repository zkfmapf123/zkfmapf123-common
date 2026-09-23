---
name: report-outputs
description: Use when the user asks to be reported to — "보고해줘", "보고서로", "정리해서 보고", "report this", "write this up" — about work done in this session, an investigation, a comparison, or any result that has an audience beyond the terminal. Produces a designed HTML page published as an Artifact (frontend-design skill when installed), plus a two-line summary in chat.
---

# Report Outputs

"보고해줘" means: the result leaves the terminal and reaches someone who was not
in this session. Build a page they can read on its own, publish it, hand back
the link. The chat reply is not the report — the page is.

## Step 1: Decide what is being reported

Collect, from this conversation and the files it touched:

- **Question** — what was asked or attempted, in one sentence.
- **Result** — the answer, decision, or state now. Lead with it.
- **Evidence** — what supports it: commands run and their decisive output,
  files changed (`path:line`), numbers, screenshots already on disk.
- **Open items** — what is not done, not verified, or needs the reader's call.

If the user named a scope ("이번 작업", "이 버그", "비교 결과"), report only that.
If nothing in the session fits, ask one question: what should the report cover?

## Step 2: Design pass

Invoke the first that exists, in this order, before writing any HTML:

1. `frontend-design:frontend-design` (plugin `frontend-design@claude-plugins-official`)
2. `artifact-design` (built-in)
3. Neither → plain, readable HTML; no design flourishes.

If 1 is missing, say so in one line after the link: install with
`/plugin install frontend-design@claude-plugins-official`. Do not stop for it.

Whatever the pass says about aesthetics, the report's structure is fixed:
result first, then evidence, then open items. A reader who stops after the
first screen must already know the answer.

## Step 3: Write the page

Path: `.claude/reports/report-{UNIX_TIMESTAMP}.html`
(`mkdir -p .claude/reports`; add `.claude/reports/` to `.gitignore` if it is
not already ignored — reports embed session details).

Rules:

- Language: the user's, as written in the request.
- `<title>`: a short name for the subject, not "Report".
- Phone width, light and dark theme, no external resources except fonts from
  fonts.googleapis.com — the Artifact sandbox blocks everything else.
- Evidence is quoted, not paraphrased: real command output, real diffs, real
  numbers. Trim, never invent.
- No claims the session did not verify. An unverified item goes under open
  items, labelled as such.
- 다이어그램 스타일: Excalidraw 손그림 풍 — Caveat 폰트 라벨 + 둥근 모서리 박스
  + 얇은 스트로크(1.2~1.8px) + fill 없는 외곽선. 본문 한글은 IBM Plex Sans KR.
  후속 질문용 설명 그림도 같은 스타일 유지.

## Step 4: Publish and reply

1. `Artifact` tool, favicon `📋`, `description` = one sentence on what the
   report covers. If the tool is unavailable, give the HTML path instead.
2. Reply in chat with exactly:
   - one line: the result
   - one line: `🔗 {artifact url}` (or the path)
   Nothing else unless the user asks. The page carries the detail.

## Not this skill

- A chart or dashboard the user wants to interact with → `dataviz` /
  `artifact-capabilities`.
- A judge run's report → `judge` builds its own.
- "요약해줘" with no audience beyond the user → answer in chat; no page.
