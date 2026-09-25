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
- 훑어읽기 경로: 본문이 길어도 강조 부분만 이어 읽으면 보고 내용이 전달돼야 함.
  작성 후 `<mark>` 와 `<strong>` 만 순서대로 읽어 결론·근거 요지·위험이 잡히는지
  확인하고, 안 잡히면 강조를 고침.
- 형광펜: 섹션마다 "이것만 읽으면 되는" 문장 하나(최대 한 절)를 `<mark>` 로.
  - 배경 토큰 `--mark`(반투명 노랑 계열, 다크 모드는 채도 낮추고 불투명도
    조정). 글자색은 본문색 유지 — 형광펜 위에 색 글자 금지, 굵게는 허용.
  - 섹션당 최대 1개. 결과 섹션은 필수.
- 강조: 독자가 훑어만 봐도 요점이 잡히게, 핵심 구절을 `<strong>` + 색으로 표시.
  - 대상: 결론·결정, 핵심 수치, 위험·미해결, 독자가 해야 할 행동. 문단당
    1~2개, 단어·짧은 구절 단위. 문장 통째로 칠하지 않음. 강조가 많으면
    강조가 아님.
  - 색은 의미별 3종 토큰만: `--em-key`(결론·수치, 브랜드/파랑 계열),
    `--em-risk`(위험·실패, 빨강/주황), `--em-ok`(완료·검증됨, 초록).
    `:root` 에 정의하고 다크 모드에서 대비 4.5:1 이상 되게 재정의.
  - 마크업: `<strong class="key|risk|ok">`. 색만으로 의미 전달 금지 —
    굵기가 항상 같이 붙음.
  - 코드·명령·경로는 강조 대신 `<code>`.

## Step 4: Publish and reply

1. Always publish via the `Artifact` tool — a local file alone is not done.
   `icon: "report"`, `description` = one sentence on what the
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
