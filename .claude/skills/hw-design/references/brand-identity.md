# Hanwha Brand Identity — 출처 및 검증 기록

이 문서는 `DESIGN.md` 에 들어간 한화 브랜드 값의 **출처와 확실성 수준**을 기록한다. 레퍼런스 검증 규칙(`.claude/rules/reference-verification.md`)에 따라 공식 출처가 확인된 값과 추정값을 구분한다.

## 브랜드 에센스

- **슬로건**: "Energy for Life"
- **심볼**: **Tricircle** (3개의 원) — "우주 속으로 무한 진화·팽창·성장"을 상징. 세 원은 한화의 핵심가치, 비전, 사업영역을 뜻한다.
- **원칙**: 시그니처 컬러는 **화이트 배경 위에서 사용**함을 기본으로 한다. 인쇄는 CMYK, 디지털은 RGB.

출처: [㈜한화 CI 페이지](https://www.hanwhacorp.co.kr/hanwha/company/ci.jsp), [Hanwha Brand System Toolkit](https://www.hanwha.com/newsroom/media-library/brand-system-toolkit.do)

## 컬러 팔레트 — 확실성 표기

### ✅ HW 디지털 서비스 표준값

`assets/DESIGN.md` 와 `assets/tokens.css` 는 아래 값을 기준으로 한다. 공식 CI 원색을 그대로 복제한 값이 아니라, 한화손해보험 AI 서비스 화면에서 반복 사용하기 위해 확정한 디지털 제품용 표준이다.

| 역할 | Hex | 용도 |
|------|-----|------|
| Primary | `#F37321` | CTA, 액티브 상태, 포커스 링 |
| Primary Hover | `#E06A1B` | hover, 그래디언트 끝점 |
| Primary Pressed | `#C75E14` | pressed, 외곽선, 텍스트 포커스 |
| Primary Light | `#FFF3EB` | 배지·칩 배경 |
| Primary Muted | `#FDEEDE` | subtle hover 배경 |
| Neutral | `#1A2B4A` | 헤더·사이드바·본문 텍스트 |
| Neutral Light | `#2D4168` | 네이비 hover, 그래디언트 끝점 |
| Neutral Muted | `#3D537F` | on-navy 보조 텍스트, 구분선 |
| Text Secondary | `#64748B` | 보조 설명 |
| Text Tertiary | `#94A3B8` | placeholder, meta |

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

### ⚠️ 공식 출처 없는 보조값

상태 색상(`success/warning/danger/info`), 서피스·보더, hover·pressed 파생값은 공식 브랜드 가이드 수치가 아니라 디지털 제품 UI를 위해 정의한 값이다. 공식 값이 확인되면 `assets/DESIGN.md`, `assets/tokens.css`, `assets/token-audit.mjs`, `assets/tailwind.preset.js` 를 함께 갱신한다.

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
- 어두운 배경(네이비 등)에서는 **변형 PNG**(`-on-navy` / `-mono-white` / `tricircle-symbol-white`) 사용
- 주변 세이프존은 **로고 높이의 1/2 이상**
- 인쇄: CMYK / 디지털: RGB

### Don't

- 색상·비율 임의 변경 금지
- Tricircle 3원의 기하 변형 금지
- 복잡한 배경·패턴 위 직접 배치 금지 (대비 확보된 단색 배경 필요)

## 로고 변형(`-on-navy` / `-mono-white` / `tricircle-symbol-white`) 출처

`assets/logo/` 의 다음 변형 PNG 들은 **원본 PNG(`hanwha-tricircle.png` / `favicon.png`)의 색상 변환 시안**이다.

| 파일 | 변환 방식 |
|------|-----------|
| `hanwha-tricircle-on-navy.png` | 원본의 무채색 픽셀(검정 wordmark + 안티앨리어싱)만 흰색으로 invert. 컬러 트라이써클은 보존. |
| `hanwha-tricircle-mono-white.png` | 모든 비투명 픽셀의 RGB 를 흰색으로 변환 + 컬러 픽셀의 luminance 중앙값 기준으로 짙은 영역=알파 100%, 옅은 영역=알파 50% 이산 매핑 (트리서클 3원 구분 보존 목적). |
| `tricircle-symbol-white.png` | `favicon.png` 에 위와 동일한 매핑 적용. |

**비율·형태는 100% 보존**되며, 픽셀 색상만 변환했다. 변환 스크립트는 `~/dotfiles/.archive/2026-05-01_logo-variants-draft/` 에 보관.

### 교체 권장 조건

다음 중 하나가 충족되면 한화손보 BI 가이드의 **공식 mono/inverse 자산**으로 교체하는 것이 안전하다:

1. 한화손보 BI 가이드 PDF/페이지에서 mono/inverse 사양이 확인됨
2. 한화 그룹 본사가 배포하는 mono 표준이 별도로 존재
3. 사외 노출 산출물(웹사이트·인쇄물)에 사용해야 하는 경우 — 시안과 BI 가이드 정합성 검증 후 사용

지금까지는 **사내 시안 / 디자인 시스템 견본** 용도로 사용 가능. 외부 배포 전엔 BI 가이드 정합성 검증 필요.

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
