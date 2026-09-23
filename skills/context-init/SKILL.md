---
name: context-init
description: Use when setting up a project to use context-engineering and loop-engineering skills — user asks to initialize context/loop discipline for a project, wants the skills to activate automatically in future sessions, or invokes /context-init. (프로젝트에 컨텍스트 규율 초기 설정)
---

# Context Init (프로젝트 초기 설정)

프로젝트 CLAUDE.md에 포인터를 심어, 이후 **모든 세션**이
context-engineering·loop-engineering 규율을 상기하게 만든다.
1회 실행용이며 멱등하다 — 여러 번 실행해도 안전하다.

## 대상 파일

**현재 프로젝트의 `./.claude/CLAUDE.md`** (git 루트 기준,
예: `<프로젝트>/.claude/CLAUDE.md`).

- `~/.claude/CLAUDE.md`는 **절대 수정 금지** — 전역 사용자 메모리라
  모든 프로젝트에 영향을 준다
- 프로젝트 루트의 `./CLAUDE.md`도 건드리지 않는다 — 이 플러그인의
  포인터는 `./.claude/CLAUDE.md`에만 둔다

## 절차

1. `./.claude/CLAUDE.md`에서 `loop-engineering` 문자열을 검색한다
   (파일이 없으면 "없음"으로 간주하고 3으로)
2. **이미 있으면 아무것도 하지 않는다.** "이미 설정됨"이라고 보고하고 종료
3. 없으면 아래 두 줄을 `./.claude/CLAUDE.md` **끝에 추가**한다
   (파일·디렉토리가 없으면 새로 생성).
   기존 내용과의 사이에 빈 줄 하나를 두고, 파일 끝에 개행이 없으면 먼저 보정한다

```
장기·반복 작업을 오케스트레이션할 때는 loop-engineering skill의 절차를 따른다.
상태는 .claude/state/ 의 tasks.json·progress.md 에만 기록한다.
```

4. 완료를 보고한다: "포인터 심음. 이후 세션부터 자동으로 규율을 상기함"

## 하지 않는 것

- **`.claude/state/` 파일을 미리 만들지 않는다.** `tasks.json`은 실제
  요구사항을 작업 단위로 분해한 산물이다. 빈 파일을 미리 만들면
  loop-engineering의 첫 세션 절차("상태 파일이 없으면 요구사항을 분해해
  생성")와 충돌한다. 상태 파일은 첫 실제 작업 때 loop-engineering이 만든다.
- **기존 CLAUDE.md의 다른 내용은 수정·삭제하지 않는다.** 추가만 한다.

## 흔한 실수

| 실수 | 교정 |
|---|---|
| `~/.claude/CLAUDE.md`(전역)에 심음 | 프로젝트의 `./.claude/CLAUDE.md`가 대상. 전역 파일 수정 금지 |
| 프로젝트 루트 `./CLAUDE.md`에 심음 | `./.claude/CLAUDE.md`에만 둔다 |
| 포인터가 이미 있는데 또 추가 | 검색 먼저. 중복이면 종료 |
| 빈 tasks.json·progress.md 미리 생성 | 생성 금지. loop-engineering 몫 |
| CLAUDE.md 전체를 재작성 | 끝에 두 줄 추가만 |
