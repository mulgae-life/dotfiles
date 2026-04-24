# Hanwha Brand Identity — 출처 및 검증 기록

이 문서는 `DESIGN.md` 에 들어간 한화 브랜드 값의 **출처와 확실성 수준**을 기록한다. 레퍼런스 검증 규칙(`.claude/rules/reference-verification.md`)에 따라 공식 출처가 확인된 값과 추정값을 구분한다.

## 브랜드 에센스

- **슬로건**: "Energy for Life"
- **심볼**: **Tricircle** (3개의 원) — "우주 속으로 무한 진화·팽창·성장"을 상징. 세 원은 한화의 핵심가치, 비전, 사업영역을 뜻한다.
- **원칙**: 시그니처 컬러는 **화이트 배경 위에서 사용**함을 기본으로 한다. 인쇄는 CMYK, 디지털은 RGB.

출처: [㈜한화 CI 페이지](https://www.hanwhacorp.co.kr/hanwha/company/ci.jsp), [Hanwha Brand System Toolkit](https://www.hanwha.com/newsroom/media-library/brand-system-toolkit.do)

## 컬러 팔레트 — 확실성 표기

### ✅ 확인됨 (Hanwha Solutions 기준)

[brandcolorcode.com/hanwha-solutions](https://www.brandcolorcode.com/hanwha-solutions) 에서 Pantone·CMYK·RGB·Hex 4축 모두 확보된 값.

| 이름 | Hex | Pantone | CMYK | RGB |
|------|------|---------|------|-----|
| Dark Orange | `#F96D17` | **1585 C** | 0, 56, 91, 2 | 249, 109, 23 |
| Orange | `#FD996C` | **163 C** | 0, 40, 57, 1 | 253, 153, 108 |
| Light Orange | `#FFB386` | **713 C** | 0, 30, 48, 0 | 255, 179, 134 |
| Black | `#000000` | Black 6 C | 0, 0, 0, 100 | 0, 0, 0 |

### ⚠️ 불확실성

**Hanwha Solutions의 컬러값을 그룹 전체 표준으로 일반화했다.** 한화솔루션은 한화그룹의 핵심 계열사로 동일한 CI 체계를 쓰지만, 그룹 본사가 배포하는 `Hanwha Brand System` PDF(83.7 MB, 원본 접근 가능하나 텍스트 추출 불가 상태)의 정확 수치와 **미세하게 다를 가능성**이 있다.

**업데이트 조건**:
1. 그룹 공식 브랜드 가이드 PDF의 텍스트 추출이 가능해지면 (poppler-utils 설치 또는 대표님이 정확값 제공)
2. 한화 공식 디자인 시스템 문서가 별도로 배포되면
3. 사용자가 명시적으로 특정 계열사 표준을 지정하면 (예: 한화큐셀·한화생명·한화오션 등)

### ⚠️ 이 스킬이 **만든** 값 (공식 출처 없음)

다음 값은 공식 브랜드 가이드에 없고, 실무 편의를 위해 일반적 디자인 시스템 관행에 따라 **이 스킬이 정의한 것**이다. 공식 값이 확인되면 덮어써야 한다.

- `primary-hover: #DD5D10` — Hanwha Orange의 brightness −10% 추정값
- `text-primary: #111111` — 순검정 대신 digital-friendly near-black (공식 아님)
- `text-secondary: #4A4A4A`, `text-tertiary: #8A8A8A` — 관례적 grayscale ladder
- `surface-muted: #F7F7F8`, `border: #E5E5E5`, `border-strong: #C9C9C9` — 관례적 중성 팔레트
- State colors (`success/warning/danger/info`) — Tailwind 계열 관례값. 한화 공식 오류/경고 색은 미확인.

## 전용 서체

### Hanwha Gothic (한화고딕)

- 한화 공식 전용 서체. **Light (300) / Regular (400) / Bold (700)** 3종 weight.
- 출처: [SandollCloud - Hanwha Gothic](https://www.sandollcloud.com/font/18304/Hanwha-Gothic), [Fontwiki](https://fontwiki.com/en/font-detail/Hanwha-Gothic-c621), [typodesign.co.kr/Hanwha](https://typodesign.co.kr/Hanwha)

### Hanwha Font (한화 폰트)

- 로고 계열 전용 서체로, CI 로고타이프와의 일관성을 유지하기 위한 용도.
- 일반 본문 UI에는 **Hanwha Gothic을 사용**하는 것이 관례.

### 웹 폰트 배포

- 공식 웹폰트 CDN 또는 오픈 라이선스 배포가 **공개적으로 확인되지 않았다**. 라이선스 확보가 필요.
- **폴백**: [Pretendard](https://github.com/orioncactus/pretendard) (오픈소스, SIL OFL) — 한글·영문 혼용에 최적화. 한화 프로젝트에서 Hanwha Gothic 확보 전까지 안정적인 대체제.

## 로고 사용 규칙 (요약)

### Do

- 화이트 배경 위 사용이 기본
- 주변 세이프존은 **로고 높이의 1/2 이상**
- 인쇄: CMYK / 디지털: RGB

### Don't

- 색상·비율 임의 변경 금지
- Tricircle 3원의 기하 변형 금지
- 복잡한 배경·패턴 위 직접 배치 금지 (대비 확보된 단색 배경 필요)

## 외부 참조

### 공식
- [한화그룹 기업 소개](https://www.hanwha.co.kr/company/introduce.do)
- [㈜한화 CI](https://www.hanwhacorp.co.kr/hanwha/company/ci.jsp)
- [Hanwha Brand System Toolkit (다운로드)](https://www.hanwha.com/newsroom/media-library/brand-system-toolkit.do)
- [Hanwha Brand System Design Guide PDF](https://www.hanwha.com/upload/newsroom/media-library/contents/20240521/1716274557872.pdf) (2024-05-21 배포)

### DESIGN.md 포맷
- [Google Labs Code - design.md (공식 GitHub)](https://github.com/google-labs-code/design.md) — Apache-2.0, v0.1.0 alpha
- [Stitch DESIGN.md Overview](https://stitch.withgoogle.com/docs/design-md/overview/)
- [Stitch DESIGN.md Format](https://stitch.withgoogle.com/docs/design-md/format/)
- [Google Blog: DESIGN.md Open-Sourced](https://blog.google/innovation-and-ai/models-and-research/google-labs/stitch-design-md/)

## 업데이트 이력

- **2026-04-23 v1.0**: 초기 작성. Hanwha Solutions 기준 hex + Pretendard 폴백 + `#111111` 텍스트.
- **2026-04-23 v1.1**: 스킬명 `hwgi-design` → `hw-design` 리네임. `DESIGN.md` 를 `assets/` 로 이동. SKILL.md description pushy 화, CLAUDE.md 주입 블록 이유 설명 중심.
- **2026-04-23 v2.0 (현재)**: 실전 디자인 시스템 기반 전면 재작성.
  - **Primary 값 정정**: `#F96D17` (Hanwha Solutions 추정) → `#F37321` (실전 확인값). Hover `#E06A1B`, Pressed `#C75E14`, bg `#FFF3EB`, bg-subtle `#FDEEDE` 5단 팔레트로 확장.
  - **Neutral 축 추가**: Navy `#1A2B4A` / `#2D4168` / `#3D537F` 3단 — 한화 DNA 의 **2색 대비축**(Orange + Navy) 완성.
  - **폰트 교체**: Hanwha Gothic(미검증) → **AtoZ (에이투지체)** 9 weight 실제 웹폰트 번들. IBM Plex Sans Variable 을 영문/숫자 강조용으로 페어링.
  - **그림자 시스템**: 네이비 톤 `rgba(26, 43, 74, x)` 기반 9종. 브랜드 컬러 일관성 확보.
  - **Motion 3단계 원칙**: `fast 250 / base 350 / slow 550`ms 만 허용.
  - **3-Layer Token Architecture** 도입 (Hardik Pandya 패턴): Layer 1 `--hw-*` → Layer 2 `--color-*/--space-*/...` → Layer 3 컴포넌트.
  - **Token Audit 스크립트** 번들 (`token-audit.mjs`): 하드코딩 hex/px/duration 자동 감지.
  - **Tailwind 프리셋 + fonts.css** 번들로 프레임워크 연계 즉시 가능.
  - **출처 추가**: `references/source-design.md` (대표님의 `ai_assist` 실전 디자인 시스템 — DNA 추출 원천), `references/design-md-playbook.md` (공식 + 커뮤니티 고수 노하우 요약).
