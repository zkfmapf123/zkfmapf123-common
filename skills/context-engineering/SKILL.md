---
name: context-engineering
description: Use when deciding what belongs in the context window vs on disk — CLAUDE.md keeps growing, progress gets lost after /clear or compaction, sub agent output floods the main context, or important state lives only in the conversation. (컨텍스트 윈도우 관리, 상태 유실 방지)
---

# Context Engineering (컨텍스트 배치 규율)

컨텍스트 윈도우는 **휘발성 캐시**다. 언제든 compact·/clear로 사라진다.
정보를 어디에 둘지는 "얼마나 오래 살아야 하는가"로 결정한다.

> **컨텍스트에는 지금 필요한 것만, 나머지는 디스크에.**
> 대화에만 존재하는 정보는 이미 유실 예정인 정보다.

## 배치 기준표

| 정보 종류 | 두는 곳 | 이유 |
|---|---|---|
| 스택·규약·아키텍처 (안정적 전역 맥락) | `CLAUDE.md` | 모든 세션에 항상 로드 |
| 절차·규율 (특정 작업에만 필요) | skill (`.claude/skills/`) | 트리거될 때만 로드, 평소 토큰 0 |
| 진행 상태 (무엇이 남았나/했나) | `.claude/state/tasks.json` + `progress.md` | 세션 간 유일한 진실. 형식·스키마는 loop-engineering 참조 |
| 작업 이력·복구 지점 | git 커밋 (서술적 메시지) | 되돌리기 + 이력 조회 |
| 대화 중 결론·결정 | 디스크에 즉시 기록 | 컨텍스트만 믿으면 유실 |

## 규칙

- **CLAUDE.md는 항상 로드된다 = 항상 과금된다.** 안정적 전역 맥락만 남기고,
  작업별 절차는 skill로 빼고 CLAUDE.md에는 **포인터 한 줄**만 둔다.
- **sub agent로 컨텍스트 격리.** 탐색·조사처럼 출력이 큰 작업은 sub agent에
  위임하고 **구조화된 요약**(무엇을 했는지 / 무엇이 남았는지 / 검증 결과,
  1,000–2,000 토큰 수준)만 받는다. 원본 출력을 메인 컨텍스트에 들이지 않는다.
- **컨텍스트가 차면 /clear가 정답.** compact보다 확실하다. 단, /clear 전에
  상태가 디스크에 있어야 한다. 비운 뒤 재수화(rehydrate)한다 — 절차는
  loop-engineering skill의 "1. 상태 파악"을 따른다.
- **대화에서 나온 결정은 그 자리에서 디스크에.** "나중에 정리"는 유실이다.

## 흔한 실수

| 실수 | 결과 | 교정 |
|---|---|---|
| CLAUDE.md에 진행 상태 기록 | 전역 맥락 오염 + 매 세션 토큰 낭비 | 상태는 `.claude/state/` 파일로 |
| 결론을 대화에만 남김 | compact/clear 시 유실 | 즉시 디스크 기록 |
| sub agent 원본 출력을 그대로 수신 | 메인 컨텍스트 즉시 포화 | 구조화된 요약만 반환시킴 |
| 컨텍스트 아끼려고 상태 파일 안 읽음 | 깨진 상태 위에서 작업 | 재수화 절차는 생략 금지 |

**REQUIRED SUB-SKILL:** 장기·다중 세션 작업을 실제로 돌릴 때는
loop-engineering skill의 사이클 절차를 따른다.
