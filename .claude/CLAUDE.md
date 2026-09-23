# common — Claude Code 플러그인 (공용 스킬 모음)

이 리포는 마켓플레이스 `common`, 플러그인 `common` 하나. 호출은 `/common:<skill>`.
bash 파이프라인 없음. 전부 마크다운 스킬 + 소량의 헬퍼 파일.

## 레이아웃

```
.claude-plugin/plugin.json      매니페스트 (name, version, description, keywords)
.claude-plugin/marketplace.json 로컬/GitHub 마켓플레이스 등록용. plugins[0].description 만 갱신
skills/<name>/SKILL.md          스킬 하나 = 폴더 하나. frontmatter name 은 폴더명과 동일
skills/<name>/*.md|*.sh|*.html  그 스킬만 쓰는 보조 파일 (프롬프트 템플릿, 리포트 템플릿, 빌드 스크립트)
commands/<name>.md              슬래시 명령이 인자 파싱·사전 처리를 해야 할 때만. 스킬만으로도 /common:<name> 은 생김
config/                         여러 스킬이 공유하는 데이터 (roles.json)
README.md                       사용자용. 스킬 표 + 설치
CHANGELOG.md                    버전별 변경. 스킬 추가/삭제/동작 변경마다 한 줄
```

## 현재 스킬

| 스킬 | 진입 | 보조 파일 | 출처 |
|---|---|---|---|
| judge | `commands/judge.md` → `skills/judge/SKILL.md` | `member-prompt.md`, `report-template.html`, `build-report.sh`, `config/roles.json` | 자체 |
| report-outputs | description 트리거("보고해줘") / `/common:report-outputs` | 없음 | 자체 |
| context-init | `/common:context-init` | 없음 | zkfmapf123/context_skills 그대로 |
| context-engineering | 자동 트리거 | 없음 | 〃 |
| loop-engineering | 자동 트리거 | 없음 | 〃 |

`context-*`, `loop-engineering` 은 원본 리포와 동일하게 유지. 수정하려면 원본 먼저.

## 새 스킬 추가 절차

1. `skills/<name>/SKILL.md` 생성. frontmatter:
   ```
   ---
   name: <name>                       # 폴더명과 같게
   description: <언제 쓰는지. 트리거 문구를 사용자 말 그대로 포함 — "보고해줘", "council review">
   ---
   ```
   description 이 자동 트리거 조건. 본문은 트리거 후에만 로드되니 상세는 본문에.
2. 인자·플래그가 있으면 `commands/<name>.md` 추가. frontmatter: `description`, `argument-hint`, `allowed-tools`.
   명령 본문에서 스킬 파일은 **Read 로 직접 읽게** 지시 (Skill 툴은 파일 내용을 안 돌려줌).
3. 플러그인 파일 경로는 항상 `${CLAUDE_PLUGIN_ROOT}/...`.
4. README 스킬 표, CHANGELOG, `plugin.json` version (형식 `YYYY.M.N`, N 은 월 내 증가) 갱신.
5. `claude plugin validate .` 통과 확인. 로드 확인:
   `claude -p --plugin-dir . "List slash commands starting with /common. Names only."`
6. 설치본 반영: `claude plugin update common@common` → 세션 재시작.

## 스킬 작성 규칙 (실행 후 피드백에서 나온 것)

- AskUserQuestion: 호출당 질문 ≤4, 질문당 옵션 ≤4, **질문 텍스트는 서로 달라야 함**. 옵션은 `label` 에 값만, 설명은 `description` — 라벨에 "(Recommended)" 붙이면 답을 파싱해야 함.
- 선택지가 4개 넘으면 채팅에 번호표 출력 + 옵션은 프리셋, 자유입력은 "Other".
- 서브에이전트: 한 메시지에 전부 스폰, `run_in_background: true`, `model` 명시. 응답 길이 상한을 프롬프트에 명시 (350 단어 등).
- 답변 언어 = 사용자 질문 언어. 스킬 본문의 영어는 스펙이지 그대로 출력할 문구가 아님 — 이걸 스킬 안에 써둘 것.
- 채팅엔 요약만, 전문은 파일/Artifact 로. 호스트가 HTML 을 손으로 쓰게 하지 말고 템플릿 + 스크립트 (`judge/build-report.sh` 방식).
- 출력물은 프로젝트 루트의 `judge/`, `.claude/reports/` 처럼 스킬별 고정 폴더, `.gitignore` 등록.
- Artifact 샌드박스: 외부 리소스는 cdnjs / fonts.googleapis 만. 라이트·다크·폰 폭 필수.

## 검증

- 실제 실행은 다른 세션에서. 트랜스크립트는 `~/.claude/projects/-Users-dong-dev-ai-claude-council/<id>.jsonl`, 서브에이전트는 `<id>/subagents/`. 거기서 툴 호출 순서·토큰·출력 형식 점검.
- 다른 세션에 실행자 관점 피드백을 물을 땐 ListAgents → SendMessage.
