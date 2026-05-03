# DESIGN.md 외부 카탈로그 서베이

> 외부 디자인 시스템 카탈로그를 사람이 읽고 학습하기 위한 보관소.
> **`hw-design` 스킬은 이 자료를 직접 참조·번들·배포하지 않는다.** 갭 분석·아이디어 발산 시 비교 레퍼런스로만 사용한다.

## 위치와 분리 원칙

- 위치: `dotfiles/reference/awesome-design-md-survey/` (이 디렉토리)
- 형제: `reference/참고디자인파일/` — 한화손보 자체 BI 원본 (1차 자료, 진실의 원천)
- **스킬 내부에 두지 않는 이유**: hw-design 스킬은 한화 BI 단일 출처여야 한다. 외부 학습 자료를 스킬 안에 넣으면 (1) 마치 hw-design이 외부 시스템을 인용·재배포하는 것처럼 오해 (2) 외부 자료가 스킬 산출물에 섞여들 위험 (3) 라이선스·책임 경계 흐림.

## 출처

- **VoltAgent/awesome-design-md** (MIT) — 영문 표준 카탈로그 (70+ 브랜드)
  - 페이지: https://getdesign.md/
  - 레포: https://github.com/VoltAgent/awesome-design-md
- **kzhrknt/awesome-design-md-jp** (MIT) — CJK 확장판 (32개 일본 서비스 + 9-section 일본어 템플릿)
  - 레포: https://github.com/kzhrknt/awesome-design-md-jp
- **표준 출처**: [Google Stitch — DESIGN.md 포맷](https://stitch.withgoogle.com/docs/design-md/overview/)
  - `AGENTS.md` (어떻게 만드는지) 와 짝을 이루는 `DESIGN.md` (어떻게 보이는지) 표준
- 수집 일자: 2026-05-03

> ⚠️ **법적 주의**: 위 카탈로그의 DESIGN.md 파일들은 해당 회사의 **공식 디자인 시스템 문서가 아니다**. 외부 사이트의 공개 CSS computed style 추출본이며, 회사명·상표는 각 권리자 소유. 외부 공유물에 그대로 인용 금지.

## 폴더 구조

```
awesome-design-md-survey/
├── README.md                      # 이 파일
├── cjk-jp/                        # 일본 CJK 확장판 (한화에 가장 직접 적용 가능)
│   ├── jp-README.md               # CJK 확장 근거 + 32 브랜드 목록
│   ├── jp-template.DESIGN.md      # 9-section CJK 템플릿 (한국어 가이드 출발점)
│   ├── jp-toyota.DESIGN.md        # 대기업 자동차, 격식 톤
│   ├── jp-muji.DESIGN.md          # 미니멀 + 격식, 한글 본문 톤 참고
│   └── jp-smarthr.DESIGN.md       # B2B SaaS, 폼·테이블 패턴
└── reference-brands/              # 한화 톤과 결이 가까운 영문 카탈로그
    ├── ibm.DESIGN.md              # Carbon, 엔터프라이즈
    ├── mastercard.DESIGN.md       # 크림 캔버스 + 단일 강브랜드, 핀테크 격식
    ├── vodafone.DESIGN.md         # 단일 강브랜드 컬러 + 챕터 밴드
    ├── stripe.DESIGN.md           # 정통 정장 + 그라디언트
    ├── vercel.DESIGN.md           # B&W 미니멀 정밀
    ├── apple.DESIGN.md            # whitespace philosophy 강함
    ├── linear.app.DESIGN.md       # 미니멀 정밀, 카드 기반
    ├── notion.DESIGN.md           # 따뜻한 minimalism, 세리프 헤딩
    └── nike.DESIGN.md             # 사진 중심, 거대 uppercase
```

## 1페이지 인사이트 요약

### 한화 DESIGN.md가 외부 대비 강한 부분

- **Frontmatter 토큰 풀세트**: 외부 다수가 본문 markdown만. 한화는 YAML 토큰으로 `colors/typography/spacing/components/shadows/gradients/motion`을 정의 — `token-audit.mjs` 자동 검증 가능
- **2색축 + 네이비 그림자 톤 통일**: 외부 다수가 검정 그림자 사용. 한화는 `rgba(26,43,74,x)` 통일 — brand DNA 일관성
- **로고 5종 + 배경별 결정 트리**: 외부 어떤 파일에도 없는 가드
- **Extended Patterns**: 스플래시·키워드 하이라이트·스크롤바 — 실무 레시피 부속

### 한화 DESIGN.md에 빠지거나 약한 부분 (Stitch 9-section 표준 대비)

| 표준 섹션 | 한화 보유 여부 | 비고 |
|-----------|----------------|------|
| 1. Visual Theme & Atmosphere | ⚠️ 약함 | "Energy for Life" 한 줄. 형용사 5개 + 정보밀도 + 톤 키워드 명시 필요 |
| 2. Color Palette & Roles | ✅ 강함 | 2색축 + alias + 상태 페어 |
| 3. Typography Rules | ⚠️ 부분 | 한국어 금칙·OpenType feature 표 누락 |
| 4. Component Stylings | ✅ 강함 | frontmatter 토큰 + 본문 가이드 |
| 5. Layout Principles | ✅ 강함 | Whitespace Philosophy 단락만 추가 가치 |
| 6. Depth & Elevation | ✅ 강함 | 네이비 톤 통일 |
| 7. Do's and Don'ts | ✅ 강함 | 페이지 끝 잘 정리됨 |
| 8. Responsive Behavior | ⚠️ 묻힘 | Layout 안에 흡수, 단독 섹션 분리 가치 |
| 9. Agent Prompt Guide | ❌ 없음 | 1-block 압축본 — 외부 LLM 호출 효율↑ |

### CJK 확장판이 한화에 직접 주는 것 (jp-template.DESIGN.md 기준)

- **§3.6 금칙·줄바꿈 룰**: 한국어용 5~6항목 (조사 단독 줄바꿈 금지, 부호 행두 금지, `line-break: strict` 등)
- **§3.7 OpenType feature 표**: 본문/헤딩/숫자별 `palt`/`kern`/`liga`/`tnum`/`lnum` 매핑
- **§3.5 행간·자간 가이드라인**: "한글 본문 1.5↑, 0.04em 양의 자간 — 단 한화체는 자간 0" 같은 정밀 룰
- **§9 Agent Prompt Guide**: Codex/GPT 등 외부 에이전트에 한화 톤 전달용 압축 블록

### 한화 정체성과 충돌해 도입 X

- Brand Color Spectrum (Notion 6색) — 2색축 위반
- Category Accent (Nike sport chips) — 단일 브랜드 무용
- Decorative Orbital Lines (Mastercard) — 트리서클 심볼과 시각 충돌
- 縦書き (세로쓰기) — 한국어 디지털 UI에서 거의 무용
- Console/Code Colors (Vercel) — 한화는 IDE 제품 아님

## 적용 단위 / 한계

- **이 서베이는 한화 그룹 BI 범용 관점이다.** 한화손보 서비스 페이지 도메인 특화 (약관 long-form, 가입/청구 stepper, 상품 비교표, 본인인증 폼 등) 분석은 포함하지 않는다.
- 한화손보 자체 BI 원본 (`reference/참고디자인파일/design.md`, `hiCI.png` 등) 이 진실의 원천이다. 이 카탈로그 자료는 그 원본을 보강·확장할 때 비교 참고용으로만 사용한다.
- 외부 카탈로그의 톤(Mastercard·Vodafone·Stripe 등) 을 한화손보 산출물에 그대로 차용하면 BI 일관성 깨진다 — 항상 한화 자체 BI를 기준으로, 카탈로그는 "패턴/구조/섹션 구성" 수준에서만 학습.
