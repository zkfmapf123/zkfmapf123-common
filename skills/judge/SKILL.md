---
name: judge
description: Runs a panel of independent Claude subagents (one per role, blind to each other) that each answer the question from a single assigned lens, then synthesizes the spread of perspectives. Invoked by the judge command. Same-model panel — value is angle coverage, not consensus.
---

# Judge

Every member is Claude. They share priors and training, so *agreement between
them is weak signal*. The value is **independent angles and blind-spot
coverage**. The output MUST say so and MUST NOT present agreement as
corroboration.

Files you need, all under `${CLAUDE_PLUGIN_ROOT}`: `config/roles.json`,
`skills/judge/member-prompt.md`. Read them with the Read tool now if you have
not already — the Skill tool does not return their contents.

**Language**: the user's language, as written in the question, is the language
of everything below — the banner, the questions, the member answers, the
synthesis. English text in this file is a spec, not a script to echo.

## Step 1: Model

Skip if `--model` was passed.

```
AskUserQuestion:
  Question: "모든 멤버가 사용할 모델은?"  (in the user's language)
  Header: "Model"
  Options:                       # label is the bare model id; the note goes in description
    - label: opus     description: "추천 · 가장 강한 추론"
    - label: fable    description: "최신"
    - label: sonnet   description: "빠르고 저렴"
    - label: haiku    description: "가장 빠르고 저렴"
```

The answer's label is the model id — pass it to Agent's `model` as is.

## Step 2: Lenses

Skip if `--roles` was passed (a preset expands; a list is used as is; an
unknown role stops the run with the list of valid ones).

Print the numbered menu in chat, built from `roles.json` in file order, one
line per role: `N. key — summary`. Then one question. The options are presets;
numbers go in "Other".

```
AskUserQuestion:
  Question: "어떤 렌즈로 판단할까요? 프리셋을 고르거나, Other 에 위 번호를 입력 (예: 1,3,8). 3~4개 권장."
  Header: "Lenses"
  Options:
    - label: balanced      description: "correctness, security, simplicity, maintainability (추천)"
    - label: architecture  description: "scalability, reliability, simplicity, devil"
    - label: decision      description: "devil, cost, migration, product, team"
    - label: review        description: "correctness, security, maintainability, dx"
```

Resolve: preset label → its roles. Free text → split on commas/spaces; each
token is a menu number or a role key; dedupe; drop and mention anything that
matches neither. Empty → `balanced`. If more than 5 roles end up selected, say
in one line that a same-model panel gives diminishing spread past 4–5 and
proceed.

## Step 3: Fill the unknowns once

If the command's Step 1 produced NOT VERIFIED items that would change the
answer (existing cloud, team size, scale, budget, regulation...), ask the user
for the 1–3 most decisive ones in **one** AskUserQuestion call (free-text via
Other is fine), and fold the answers into OBSERVED. Do not skip this: eight
members repeating "depends on X" is the most expensive way to learn X. If the
question has no verifiable claims, there is nothing to ask — move on and omit
the OBSERVED / NOT VERIFIED block from the output.

## Step 4: Spawn members

For each role, build the prompt from `member-prompt.md` and spawn one member.
Launch **all in a single message** with:

- `subagent_type: "general-purpose"`
- `run_in_background: true`
- `model: <chosen model>` — same for every member; diversity comes from roles.
- `description: "judge: <role key>"`

Members run concurrently and stay blind to each other. Wait for ALL to finish
before synthesizing; a failed member is noted and skipped.

## Step 5: Save the transcript

```bash
mkdir -p .claude/council-cache
```

Write `.claude/council-cache/judge-{UNIX_TIMESTAMP}.md` with exactly this
shape (the report template keys off the `## 🗳️` and `## Synthesis` headers):

```
# {question, one line}

> **Judge** — 이 관점들은 모두 Claude 가 서로 다른 역할을 맡아 낸 것이며 서로 다른 벤더가 아닙니다.
> 일치하는 부분은 검증된 결론이 아니라 함께 압박 테스트할 공통 출발점으로 보세요.

Model: {model} · Roles: {keys}

OBSERVED: ...          (omit the two lines if there was nothing to verify)
NOT VERIFIED: ...

## 🗳️ {Role name}
{member's four sections verbatim}

## 🗳️ {next role}
...

## Synthesis
### Shared starting points
### Genuine tensions
### Blind spots
### Suggested direction
```

Synthesis rules — angles, not consensus:

- **Shared starting points** — where members converged. Say this is a common
  prior to stress-test, and what they might all miss for the same reason.
- **Genuine tensions** — where roles pull apart, and which tension matters most
  for this user's situation.
- **Blind spots** — risks one member raised that the others would walk into,
  plus anything *no* member covered (name the unselected lenses that would
  have covered it).
- **Suggested direction** — one recommendation, naming which roles support it
  and where the real uncertainty remains. Prefer one strong recommendation over
  several hedged ones. Only report divergence that changes the decision.

## Step 6: Show the user

In chat, do NOT paste the whole transcript. Show:

1. The banner (one line).
2. One line per member: `🗳️ {Role name} · {confidence} — {Position, trimmed to one sentence}`
3. The full `## Synthesis` section.
4. `💾 .claude/council-cache/judge-{TS}.md` and, after Step 7, the artifact link.

## Step 7: Publish the report

Skip when `--no-artifact` was passed.

```bash
bash ${CLAUDE_PLUGIN_ROOT}/skills/judge/build-report.sh .claude/council-cache/judge-{TS}.md
```

That prints the `.html` path (the markdown dropped into a fixed template; no
design work needed). If the Artifact tool exists, publish that file with
favicon `🗳️` and print the link as `🔗 {url}`. Otherwise print the HTML path.

## Errors

- One member fails → show it, continue.
- All fail → report, suggest retry.
- Only one role resolved → say so; a one-member panel is a single role-played
  answer.
