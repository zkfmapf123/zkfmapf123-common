# common

Claude Code 공용 스킬 플러그인. 외부 API 키 없음 — 전부 Claude Code 구독 위에서 돈다.

| 스킬 | 호출 | 한 줄 |
|---|---|---|
| [judge](#judge) | `/common:judge "질문"` | 역할별 Claude 서브에이전트 패널이 한 질문을 여러 관점에서 판단, 합성 + HTML 리포트 |
| [report-outputs](#report-outputs) | "보고해줘" / `/common:report-outputs` | 세션 결과를 결과-근거-미해결 순 HTML 페이지로 만들어 Artifact 링크로 전달 |
| [context-init](#context-init) | `/common:context-init` | 프로젝트 `.claude/CLAUDE.md` 에 컨텍스트/루프 규율 포인터 심기 (프로젝트당 1회) |
| [context-engineering](#context-engineering) | 자동 | 정보를 컨텍스트 윈도우에 둘지 디스크에 둘지 결정하는 규율 |
| [loop-engineering](#loop-engineering) | 자동 | 여러 세션에 걸친 장기 작업의 supervisor 사이클, 상태는 `.claude/state/` |

## 설치

```
/plugin marketplace add <owner>/<repo>        # 로컬 clone 이면 절대경로
/plugin install common@common
```

갱신: `/plugin update common@common` 후 세션 재시작. 설치 없이 한 번만: `claude --plugin-dir /path/to/common`.

선택: `/plugin install frontend-design@claude-plugins-official` — report-outputs 가 디자인 패스에 사용. 없으면 내장 폴백.

---

## judge

한 질문을 여러 Claude 서브에이전트에게 **서로 다른 역할** 로 동시에 묻고, 어디서 갈리는지 합성한다. 전원 같은 모델이라 합의는 검증이 아니라 공통 편향일 수 있음 — 출력에 그렇게 표시한다. 가치는 관점 커버리지.

```
/common:judge "SaaS users 테이블 PK, UUID vs BIGINT?"
/common:judge --roles=security,devil,simplicity "..."
/common:judge --model=sonnet --roles=architecture --no-artifact "..."
/common:judge --file=src/auth.ts "이 코드 문제 있어?"
```

흐름:

1. 모델 선택 (opus / fable / sonnet / haiku) — `--model` 로 생략
2. 렌즈 선택 — 번호표 16개 출력 후 프리셋 4개 또는 Other 에 `1,3,8` — `--roles` 로 생략. 3~4개 권장
3. 답이 달라지는 미확인 사항 1~3개를 한 번에 질문 (멤버 전원이 "X 에 따라 다름" 반복하는 것 방지)
4. 역할당 서브에이전트 1개, 병렬, 서로 못 봄. 각자 Position / Key points / Risks & blind spots / Confidence, 350단어 이내
5. 채팅엔 멤버당 1줄 + 합성(공통 출발점 / 진짜 긴장 / 사각지대 / 제안 방향)
6. 전문은 `./judge/<ts>.md`, 리포트 `./judge/<ts>.html` → Artifact 링크. `--no-artifact` 로 생략

플래그: `--model`, `--roles=<list|preset>`, `--file=<path>`, `--no-auto-context`, `--no-artifact`.

렌즈 16개 (`config/roles.json`, 각각 focus / ignore / 존재 이유 포함):

| key | 관점 |
|---|---|
| correctness | 논리 오류·경계값·레이스 |
| security | 취약점·인증/인가·인젝션, 공격 경로 |
| performance | 복잡도·N+1·캐싱, 10x 부하 기준 |
| reliability | 장애 모드·재시도/멱등성·관측성·롤백 |
| maintainability | 2년 뒤 인수자 시점 |
| simplicity | 과설계·불필요 추상화 제거 |
| scalability | 수평 확장·파티셔닝·비가역 결정 |
| devil | 가정 반박, 반대편 최강 논거 |
| dx | API 사용성·에러 메시지·디버깅 |
| compliance | 개인정보·감사 로그·GDPR/PIPA/PCI |
| cost | 인프라·API/토큰·인력 비용 |
| migration | 기존 시스템에서 전환 경로·롤백 |
| testability | 테스트 가능 구조·회귀 위험 |
| data | 스키마·정합성·데이터 수명주기 |
| product | 사용자 가치, "왜 만드나" |
| team | 팀 역량·온보딩·버스 팩터 |

프리셋: `balanced` (correctness, security, simplicity, maintainability) · `review` · `architecture` · `security-focused` · `ops` · `decision` (devil, cost, migration, product, team) · `data`.

비용 감각: 멤버 1명 ≈ 입력 70k(대부분 캐시) + 출력 2k. 4명 opus 가 기본 권장, 8명은 스프레드 대비 비쌈.

## report-outputs

"보고해줘", "보고서로", "report this" 에 반응. 이 세션에서 한 일을 **결과 → 근거 → 미해결** 순으로 HTML 페이지로 만들어 Artifact 로 게시하고, 채팅엔 결과 1줄 + 링크 1줄만 남긴다.

- 근거는 실제 명령 출력·diff·숫자 인용. 세션에서 검증 안 된 건 미해결로 분류
- 디자인 패스: `frontend-design` (설치 시) → 내장 `artifact-design` → 순수 HTML
- 파일: `.claude/reports/report-<ts>.html`
- 아닌 것: 인터랙티브 대시보드(dataviz), judge 리포트(judge 자체 생성), 청중 없는 "요약해줘"(채팅으로)

## context-init

프로젝트의 `./.claude/CLAUDE.md` 끝에 두 줄을 추가해, 이후 모든 세션이 context-engineering / loop-engineering 규율을 상기하게 한다. 멱등. `~/.claude/CLAUDE.md` 나 루트 `CLAUDE.md` 는 건드리지 않고, `.claude/state/` 도 미리 만들지 않는다.

## context-engineering

컨텍스트 윈도우는 휘발성 캐시. 정보 수명에 따라 배치: 안정적 전역 맥락 → `CLAUDE.md`, 절차 → skill, 진행 상태 → `.claude/state/tasks.json` + `progress.md`, 이력 → git. sub agent 출력은 구조화된 요약만 받고, 컨텍스트가 차면 `/clear` 후 재수화. CLAUDE.md 가 비대해지거나 `/clear` 후 진행 상태가 사라질 때 자동 트리거.

## loop-engineering

여러 세션에 걸친 장기 작업의 supervisor 규율. 매 사이클: 상태 파악(`progress.md`, `git log`, `tasks.json`) → 작업 **하나** 위임 → 검증 → `tasks.json`/`progress.md` 갱신 + 커밋. `pending` 이 없어질 때까지 반복, `/clear` 후에도 디스크 상태로 무손실 재개. `tasks.json` 은 JSON 고정, 200줄/20개 초과 시 압축.

context-init / context-engineering / loop-engineering 은 [zkfmapf123/context_skills](https://github.com/zkfmapf123/context_skills) 원본 그대로.

---

## 구조 / 스킬 추가

```
.claude-plugin/plugin.json      매니페스트 — 동작 바꾸면 version 올려야 update 됨
.claude-plugin/marketplace.json 마켓플레이스 등록
commands/<name>.md              인자 파싱이 필요한 스킬만. 스킬만으로도 /common:<name> 생김
skills/<name>/SKILL.md          스킬 하나 = 폴더 하나 (+ 보조 파일)
config/                         공유 데이터 (roles.json)
```

새 스킬: `skills/<name>/SKILL.md` 에 frontmatter(`name`, `description` = 트리거 조건) → 필요하면 `commands/<name>.md` → README 표·CHANGELOG·version → `claude plugin validate .` → `/plugin update common@common`. 상세 규칙은 `.claude/CLAUDE.md`.
