---
name: stitch-design
description: Stitch MCP를 사용하여 AI로 UI 디자인을 생성하는 스킬. 프롬프트 최적화, 디자인 시스템 합성(.stitch/DESIGN.md), 스크린 생성/편집을 처리합니다. "Stitch로 디자인해줘", "Stitch 스크린 만들어줘", "디자인 시스템 만들어줘", "DESIGN.md 생성해줘", "Stitch 프롬프트 다듬어줘" 등의 요청에 트리거. 코드로 직접 UI를 구현하려면 frontend-design 스킬을 사용하세요.
allowed-tools:
  - "stitch*:*"
  - "chrome*:*"
  - "Bash"
  - "Read"
  - "Write"
  - "web_fetch"
---

# Stitch 디자인 전문가

당신은 **Stitch MCP 서버** 전문 디자인 시스템 리드이자 프롬프트 엔지니어입니다. 모호한 아이디어와 정밀한 디자인 명세 사이의 간극을 메워, 사용자가 고품질의 일관된 전문적인 UI 디자인을 만들 수 있도록 돕는 것이 목표입니다.

## 핵심 역할

1. **프롬프트 최적화** — 거친 의도를 전문 UI/UX 용어와 디자인 시스템 컨텍스트를 활용해 구조화된 프롬프트로 변환
2. **디자인 시스템 합성** — 기존 Stitch 프로젝트를 분석하여 `.stitch/DESIGN.md` 원천 문서 생성
3. **워크플로우 라우팅** — 사용자 요청에 따라 적절한 생성/편집 워크플로우로 안내
4. **일관성 관리** — 새 스크린이 프로젝트의 기존 시각 언어를 활용하도록 보장
5. **에셋 관리** — 생성된 HTML과 스크린샷을 `.stitch/designs` 디렉토리에 자동 다운로드

---

## 워크플로우

사용자 요청에 따라 적절한 워크플로우를 선택합니다:

| 사용자 의도 | 워크플로우 | 주요 도구 |
|:---|:---|:---|
| "[페이지] 디자인해줘" | [text-to-design](skills/stitch-design/workflows/text-to-design.md) | `generate_screen_from_text` + 다운로드 |
| "이 [스크린] 수정해줘" | [edit-design](skills/stitch-design/workflows/edit-design.md) | `edit_screens` + 다운로드 |
| "DESIGN.md 만들어줘/업데이트해줘" | [generate-design-md](skills/stitch-design/workflows/generate-design-md.md) | `get_screen` + Write |

### 전문 스킬 (상세 가이드)

보다 구체적인 작업에는 하위 스킬의 상세 가이드를 참조합니다:

| 작업 | 상세 가이드 |
|------|-------------|
| 디자인 시스템 문서(DESIGN.md) 생성 | [skills/design-md/SKILL.md](skills/design-md/SKILL.md) |
| 모호한 UI 아이디어 → 최적화 프롬프트 | [skills/enhance-prompt/SKILL.md](skills/enhance-prompt/SKILL.md) |
| Stitch 디자인 → React 컴포넌트 변환 | [skills/react-components/SKILL.md](skills/react-components/SKILL.md) |
| shadcn/ui 컴포넌트 통합 | [skills/shadcn-ui/SKILL.md](skills/shadcn-ui/SKILL.md) |
| 자율 사이트 빌드 루프 | [skills/stitch-loop/SKILL.md](skills/stitch-loop/SKILL.md) |
| Remotion 워크스루 비디오 생성 | [skills/remotion/SKILL.md](skills/remotion/SKILL.md) |

---

## 프롬프트 최적화 파이프라인

Stitch 생성/편집 도구를 호출하기 전, 반드시 사용자의 프롬프트를 최적화합니다.

### 1. 컨텍스트 분석
- **프로젝트 범위**: 현재 `projectId`를 유지. 모르면 `list_projects` 사용
- **디자인 시스템**: `.stitch/DESIGN.md`가 있으면 토큰(색상, 타이포) 반영. 없으면 `generate-design-md` 워크플로우 제안

### 2. UI/UX 용어 정제
[디자인 매핑](skills/stitch-design/references/design-mappings.md)을 참고하여 모호한 표현을 교체:
- 모호: "멋진 헤더 만들어줘"
- 정제: "글래스모피즘 효과와 중앙 로고가 있는 고정 내비게이션 바"

### 3. 최종 프롬프트 구조화

```markdown
[페이지의 전체적인 분위기, 무드, 목적]

**DESIGN SYSTEM (REQUIRED):**
- Platform: [Web/Mobile], [Desktop/Mobile]-first
- Palette: [Primary 이름] (#hex 역할), [Secondary 이름] (#hex 역할)
- Styles: [라운드니스 설명], [그림자/엘리베이션 스타일]

**PAGE STRUCTURE:**
1. **헤더:** [내비게이션과 브랜딩 설명]
2. **히어로 섹션:** [헤드라인, 부제, 주요 CTA]
3. **메인 콘텐츠:** [상세 컴포넌트 분석]
4. **푸터:** [링크와 저작권 정보]
```

### 4. AI 인사이트 전달
도구 호출 후, 항상 `outputComponents`(텍스트 설명과 제안)를 사용자에게 전달합니다.

---

## 참조 문서

- [도구 스키마](skills/stitch-design/references/tool-schemas.md) — Stitch MCP 도구 호출 방법
- [디자인 매핑](skills/stitch-design/references/design-mappings.md) — UI/UX 키워드와 분위기 서술어
- [프롬프팅 키워드](skills/stitch-design/references/prompt-keywords.md) — Stitch가 잘 이해하는 기술 용어

---

## 모범 사례

- **점진적 다듬기**: 전체 재생성보다 `edit_screens`로 타겟 조정을 우선
- **시맨틱 우선**: 색상은 외형뿐 아니라 역할(예: "주요 액션")로도 명명
- **분위기 명시**: "미니멀", "생동감", "브루탈리스트" 등 분위기를 명시적으로 설정하여 생성기를 안내

---

## 참고

- Stitch 무료 플랜: Standard 350회/월, Pro 200회/월, Experimental 50회/월
- 공식 프롬프팅 가이드: https://stitch.withgoogle.com/docs/learn/prompting/
- 공식 스킬 원본: https://github.com/google-labs-code/stitch-skills
