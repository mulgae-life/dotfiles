# DESIGN.md Playbook — 고수 노하우 요약

Google 공식 스펙(`v0.1.0 alpha`) 출시 이후 커뮤니티가 축적한 실전 패턴. 이 스킬의 설계 근거를 이 파일에 모은다. 원문은 출처 섹션 참조.

## TL;DR (한 줄 요약)

> **"설계 의사결정은 이미 인간이 했다. LLM은 조회한다."** — Hardik Pandya
> 따라서 스킬이 해야 할 일은 (1) 선택지를 줄이고 (2) 선택한 걸 기계 판독 가능하게 고정하고 (3) 위반을 자동 감지하는 것이다.

## 핵심 패턴 1 — 3-Layer Token Architecture

Hardik Pandya의 Atlaskit 적용 사례에서 검증된 구조.

```
Layer 1: Design System 원천 (--ds-*)
  --ds-primary: #F37321
  --ds-space-100: 8px
            ↓ alias (의미 부여)
Layer 2: 프로젝트 의미 (--color-*, --space-*)
  --color-cta: var(--ds-primary)
  --space-100: var(--ds-space-100)
            ↓ 컴포넌트는 Layer 2만 참조
Layer 3: 컴포넌트 구현
  .button { background: var(--color-cta); padding: var(--space-100); }
```

**이점**: 업스트림 디자인 시스템이 `#F37321 → #E85A00`으로 바뀌어도 Layer 1 한 줄 수정 → 모든 컴포넌트 자동 재배색. 리브랜딩 0 비용.

**이 스킬 구현**: `assets/tokens.css` 가 정확히 이 구조를 따른다.

## 핵심 패턴 2 — 스펙 파일은 `LLM이 읽기 쉬운 계층`으로

실전 64개 파일 구성을 역추적하면:

| Tier | 역할 | 파일 예 |
|------|------|---------|
| **1. Foundations** | 토큰의 "정의" — 왜 이 값인가 | `color.md`, `typography.md`, `spacing.md`, `token-reference.md` |
| **2. Components** | atoms/molecules/organisms — 8섹션 템플릿 | `button.md`, `modal-dialog.md`, `navigation.md` |
| **3. Patterns** | 레이아웃·폼 규약 등 조합 원칙 | `responsive-grid.md`, `form-layout.md` |

각 컴포넌트 스펙의 **8섹션 템플릿**:
1. 메타데이터 (이름/카테고리/상태)
2. 개요 (언제 사용 · 언제 안 함)
3. 해부도 (부분 구성)
4. 토큰 사용 (참조하는 CSS 변수)
5. Props/API
6. 상태 (default/hover/active/focus/disabled/error)
7. 코드 예시
8. 상호참조

**이 스킬 구현**: `assets/DESIGN.md` 의 `## Components` 섹션에서 이 8포인트를 압축해 사용. 프로젝트 고유 컴포넌트는 프로젝트 쪽 `DESIGN.md` 연장판에서 정의하도록 비워둔다.

## 핵심 패턴 3 — Token Audit (하드코딩 감지 자동화)

CSS 파일 스캔 → 하드코딩 hex/px/rem 발견 → 정정 토큰 제안.

```
Token Audit
Scanning 28 CSS file(s)...

src/components/Nav.css
  ✗ L42: Hardcoded color #1868DB, use var(--color-link)
  ✗ L78: Raw spacing 12px in padding, use var(--space-150)
  ! L96: Raw duration 0.2s, consider using --motion-* token

=== Summary ===
Errors: 0    Warnings: 0
Exit: 0 (CI-friendly)
```

**심각도 규칙**:
- **Error** (exit 1): 색상, 간격 → CI 차단 가치 있는 위반
- **Warning** (exit 0): 애니메이션 duration, 드문 값 → 보고만

**이 스킬 구현**: `assets/token-audit.mjs` — Node 단독 실행, 외부 의존성 0.

## 핵심 패턴 4 — CLAUDE.md 지시사항 4줄

LLM이 매 세션 처음부터 추측하지 않도록 **프로젝트 CLAUDE.md 맨 앞에 4줄**을 박아 넣는다.

```markdown
## UI 작업 전 필독
1. 관련 spec (DESIGN.md 또는 specs/*.md) 를 먼저 읽는다.
2. tokens.css 에서만 값을 선택한다.
3. 커밋 전 `node token-audit.mjs` 를 돌린다.
4. 0 오류만 허용.
```

이 4줄이 **인간의 설계 의사결정을 LLM의 실행 시점에 강제 주입**한다. 이 스킬의 `assets/CLAUDE.md.snippet` 이 이것이다.

## 핵심 패턴 5 — 감기장성(Memory) 보완

LLM은 세션 간 기억이 없다. 해결책:
- **Spec = 메모리**: 매 세션 같은 파일 읽음
- **Token = 제약**: 추측 불가
- **Audit = 강제**: 위반 즉각 가시화

"10번째 AI 세션이 1번째와 같은 시각 품질을 낸다" — 이게 이 스킬이 달성하려는 목표.

## 핵심 패턴 6 — 3단계 드리프트 관리

업스트림 디자인 시스템이 업데이트되면 영향 범위를 자동 플래그.

1. 디자인 시스템 패키지 버전 고정 (skills-lock 개념)
2. 업데이트 감지 시 영향 리포트
3. **비차단**: 자동 수정 안 함, 사람이 검토 후 반영

**이 스킬에서는**: `references/brand-identity.md` 의 "업데이트 이력" 섹션이 이 역할. 버전/출처/불확실성 추적.

## 컴포넌트 단위 설계 격언

Oleksandra Huba, Sam Pierce Lolla 등 실무자 공통 교훈:

- **"Don't make LLMs navigate the filesystem"** — UI 컴포넌트 목록은 **한 파일**에 요약. 파일 여러 개 돌아다니게 하면 실패율 증가.
- **모놀리식 출력 요구 금지** — 큰 화면 한 번에 만들라고 하면 품질 급락. 티켓 단위로 쪼개서 순차 실행.
- **Reference material quality is the whole game** — 레퍼런스가 쓰레기면 결과도 쓰레기. 브랜드 이미지·스크린샷·색상표 등 양질의 입력 필수.
- **Quarantine tag 거버넌스** — 비디자이너·LLM이 추가한 토큰은 `quarantine` 태그를 달아두고 디자이너 검토 전까지 격리.

## 이 스킬이 설계에 반영한 결정

| 원칙 | 구현 위치 |
|------|----------|
| 3-layer token | `assets/tokens.css` (ds-* → color-*/space-* → components) |
| 공식 v0.1.0 포맷 | `assets/DESIGN.md` (YAML frontmatter + 8섹션) |
| Tailwind 사용자 배려 | `assets/tailwind.preset.js` |
| @font-face 원스톱 | `assets/fonts/fonts.css` |
| CLAUDE.md 4줄 지시 | `assets/CLAUDE.md.snippet` |
| Token Audit | `assets/token-audit.mjs` |
| 로고/파비콘 자산 | `assets/logo/` |
| 업데이트 이력 | `references/brand-identity.md` |

## 출처

### 공식
- [DESIGN.md Specification (Google Labs)](https://github.com/google-labs-code/design.md) — v0.1.0 alpha, Apache-2.0
- [Stitch DESIGN.md Format](https://stitch.withgoogle.com/docs/design-md/format/)
- [Claude Design by Anthropic Labs](https://www.anthropic.com/news/claude-design-anthropic-labs) — DESIGN.md 포맷과 별개의 자체 워크플로우

### 실전 노하우 (2026)
- [Hardik Pandya — Expose your design system to LLMs](https://hvpandya.com/llm-design-systems) — 3-layer token, 3-tier spec, audit script 원문
- [Oleksandra Huba — Dear LLM, here's how my design system works](https://uxdesign.cc/dear-llm-heres-how-my-design-system-works-b59fb9a342b7)
- [Sam Pierce Lolla — Tips for getting LLMs to write good UI](https://sampiercelolla.com/tips-for-getting-llms-to-write-good-ui-code/)
- [Addy Osmani — My LLM coding workflow going into 2026](https://medium.com/@addyosmani/my-llm-coding-workflow-going-into-2026-52fe1681325e)

### 도구/컬렉션
- [awesome-design-md (VoltAgent)](https://github.com/VoltAgent/awesome-design-md) — 69개 공개 DESIGN.md
- [designmd.app](https://designmd.app/) — 423개 DESIGN.md 라이브러리
- [design-distill (Muluk-m)](https://github.com/Muluk-m/design-distill) — 사이트 자동 추출
- [brandmd (yuvrajangadsingh)](https://github.com/yuvrajangadsingh/brandmd) — 동일 목적 도구
- [getdesign.md](https://getdesign.md/) — 컬렉션 사이트

### 디자인 토큰 이론
- [Nathan Curtis — Naming Tokens in Design Systems (EightShapes)](https://medium.com/eightshapes-llc/naming-tokens-in-design-systems-9e86c7444676) — Global → Alias → Component 3-tier 계보
- [Smashing Magazine — Best Practices For Naming Design Tokens](https://www.smashingmagazine.com/2024/05/naming-best-practices/) — 역할 기반 네이밍 원칙
