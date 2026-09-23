---
name: loop-engineering
description: Use when orchestrating long-running or multi-session work with a supervisor and sub agents — tasks spanning multiple context windows, work that must survive /clear or session restarts, autonomous task loops, or when progress keeps getting lost between sessions. (장기·반복 작업 오케스트레이션, 세션 간 무손실 인계)
---

# Loop Engineering (Supervisor 루프 규율)

이 skill은 supervisor가 **분리된 세션(컨텍스트 윈도우)에 걸쳐** 작업을
무손실로 이어가게 하는 절차를 정의한다. 핵심 원칙은 하나다:

> **상태는 컨텍스트가 아니라 디스크에 둔다.**
> 컨텍스트는 언제든 버릴 수 있고, 상태 파일만이 세션 간 유일한 진실이다.

## 상태 파일 (`.claude/state/` 폴더)

supervisor는 프로젝트의 `.claude/state/` 아래 다음 파일로 상태를 관리한다.

| 파일 | 역할 | 형식 |
|---|---|---|
| `tasks.json` | 무엇이 남았는가 (작업 원장) | **JSON** |
| `progress.md` | 무엇을 했는가 (진행 로그) | Markdown |

- `tasks.json`은 반드시 **JSON**으로 둔다. 모델이 Markdown보다 JSON을
  함부로 덮어쓰거나 지울 확률이 낮기 때문이다.
- **CLAUDE.md에는 상태를 쓰지 않는다.** CLAUDE.md는 스택·규약·아키텍처 같은
  안정적·전역 맥락 전용이다. 진행 상태는 `.claude/state/` 파일에만 둔다.
- **첫 세션 (상태 파일이 없으면):** 요구사항을 작업 단위로 분해해
  `tasks.json`을 생성하고, 빈 `progress.md`를 만들고, 프로젝트 CLAUDE.md에
  포인터를 심은 뒤(아래 "CLAUDE.md 포인터" 절차) 초기 커밋한다.
  그 다음부터 아래 사이클을 시작한다.

### tasks.json 스키마

```json
[
  {
    "id": "t1",
    "type": "coding | research | data | writing | ...",
    "desc": "무엇을 해야 하는지 한 문장",
    "status": "pending | in_progress | done | blocked",
    "verify": "이 작업이 '완료'로 인정되는 검증 조건",
    "notes": "인계에 필요한 짧은 메모 (선택)"
  }
]
```

## 매 사이클 절차

supervisor는 각 작업 사이클마다 아래를 **순서대로** 수행한다.

### 1. 상태 파악 (세션 시작 시 반드시)

1. `pwd`로 작업 디렉토리 확인
2. `.claude/state/progress.md`와 `git log --oneline -20`을 읽어 최근 작업 파악
3. `.claude/state/tasks.json`을 읽고, `status`가 `pending`인 것 중 **최우선 하나**를 선택
4. (환경이 있다면) `init.sh` 등으로 기본 상태를 한 번 점검해
   이전 세션이 남긴 깨진 상태가 없는지 먼저 확인한 뒤 새 작업을 시작한다

> 상태 점검 없이 바로 새 작업을 시작하지 말 것. 깨진 상태를 못 보고
> 문제를 키우는 것이 가장 흔한 실패다.

### 2. 위임 (한 번에 하나)

- 선택한 작업 **하나만** 해당 sub agent(`.claude/agents/`)에 위임한다.
- 한 사이클에 여러 작업을 동시에 끝내려 하지 말 것("one-shot" 금지).
- 위임 시 sub agent에게 "작업 결과를 **구조화된 요약**(무엇을 했는지 /
  무엇이 남았는지 / 검증 결과)으로 반환하라"고 지시한다.

### 3. 검증

- sub agent의 결과를 `verify` 조건에 비추어 **직접 확인**한다.
- 검증을 통과한 경우에만 `done`으로 표시한다.
- **성급한 완료 선언 금지.** "코드가 있으니 됐다"가 아니라, 실제로
  조건이 충족됐는지 확인한다. (예: 웹 기능이면 실제 동작을 확인)

### 4. 상태 기록 (세션 종료 전 반드시)

supervisor **본인이** 상태를 기록한다. sub agent는 다른 sub agent를
띄울 수 없으므로, 상태 갱신은 오케스트레이터의 책임이다.

1. `tasks.json`의 해당 항목 `status`를 갱신 (다른 필드는 건드리지 않음)
2. `.claude/state/progress.md`에 이번 사이클 요약 추가 (무엇을/왜/다음은)
3. **압축 검사** — 위 1·2를 반영한 **후의** 파일이 임계값을 넘었으면
   이 자리에서 압축한다:
   - `progress.md`가 **200줄 초과**: 최근 10사이클만 상세로 남기고,
     더 오래된 사이클은 상단 `## 요약` 절에 **사이클당 한 줄**로 압축
   - `tasks.json`의 `done` 항목이 **20개 초과**: `done` 항목 전부 삭제
     (`pending`/`blocked`/`in_progress`만 남김. 방금 `done` 처리한 항목이
     같이 지워져도 정상 — 완료 기록은 progress.md와 git에 있다)
   - 잘려나간 상세는 git 커밋에 전부 있으므로 손실이 아니다.
     별도 archive 파일은 만들지 않는다. 이력 조회는 `git log`.
4. `git`에 **서술적 커밋 메시지**로 커밋
   (나쁜 변경을 되돌리고 작동하던 상태로 복구하기 위함)

## 반복 (자율 진행)

- supervisor는 `tasks.json`에 `pending` 항목이 **남아있지 않을 때까지**
  위 사이클을 반복한다.
- 사람 입력 없이 반복하려면 이 루프를 **Dynamic Workflow**로 표현한다
  ("pending이 없어질 때까지 반복" 형태). 인터랙티브 세션에서 실행되며
  구독 사용량으로 과금된다.
- 컨텍스트가 차면 `/clear`로 컨텍스트만 비우고, 다시 **1. 상태 파악**부터
  시작한다. 상태는 디스크에 있으므로 무손실로 이어진다.

## 절대 규칙 (요약)

- 상태는 디스크에, 규율은 이 skill에, 규약은 CLAUDE.md에.
- `tasks.json`은 JSON. `status` 외 필드는 함부로 수정·삭제하지 않는다.
- 한 사이클에 작업 하나. one-shot 금지.
- 검증 통과 전에는 `done` 금지.
- 세션 종료 전 반드시 tasks/progress 갱신 + git 커밋.
- 상태 기록은 supervisor의 책임 (sub agent 아님).
- 상태 파일은 짧게 유지. 임계값(progress.md 200줄 / done 20개)을 넘으면
  기록 단계에서 압축한다. 상세 이력은 git이 보존한다.

## CLAUDE.md 포인터 (skill이 직접 심는다)

skill은 트리거될 때만 로드되므로, 이후 세션이 이 규율을 놓치지 않도록
**첫 세션 초기화 시 supervisor가 직접** 프로젝트 CLAUDE.md에 포인터를 추가한다.

절차 (멱등):

1. 프로젝트의 `./.claude/CLAUDE.md`에서 `loop-engineering` 문자열을 검색한다
   (`~/.claude/CLAUDE.md` 전역 파일은 **절대 수정 금지**)
2. **이미 있으면 아무것도 하지 않는다** (중복 추가 금지)
3. 없으면 아래 두 줄을 `./.claude/CLAUDE.md` 끝에 추가한다
   (파일·디렉토리가 없으면 생성)

```
장기·반복 작업을 오케스트레이션할 때는 loop-engineering skill의 절차를 따른다.
상태는 .claude/state/ 의 tasks.json·progress.md 에만 기록한다.
```

기존 CLAUDE.md의 다른 내용은 수정·삭제하지 않는다. 추가만 한다.

## (선택) 강제성 강화

skill은 지침이라 모델이 건너뛸 수 있다. 상태 갱신을 더 확실히 강제하려면
hook으로 "세션 종료 시 progress.md 갱신 여부 확인" 같은 검사를 추가할 수 있다.
필수는 아니며, 규율이 자주 새는 경우에만 도입한다.
