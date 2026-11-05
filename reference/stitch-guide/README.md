# Google Stitch 가이드

> Gemini 기반 AI 디자인 → 코드 변환 플랫폼. MCP를 통해 코딩 에이전트와 직접 연동.

## 개요

Google Stitch는 Google Labs에서 제공하는 AI UI 디자인 도구다. 텍스트 프롬프트, 손 스케치, 스크린샷을 입력하면 고품질 UI 디자인과 프론트엔드 코드(HTML/CSS/JS)를 생성한다.

- **공식 사이트**: https://stitch.withgoogle.com
- **가격**: 무료 (Google Labs 실험 프로젝트)
- **모델**: Gemini 3 Flash / 3.1 Pro
- **출시**: Google I/O 2025

### 무료 플랜 제공량

| 구분 | 월 제공량 |
|------|-----------|
| Standard 생성 | 350회 |
| Pro 생성 | 200회 |
| Experimental 생성 | 50회 |

---

## MCP 연동

### 셋업

**1. 인증 (둘 중 택 1)**

```bash
# 방법 A: API Key (추천, 간편)
# Stitch 웹 → 프로필 → Settings → API Keys → Create Key
export STITCH_API_KEY="발급받은_키"

# 방법 B: OAuth (CLI 위저드)
npx @_davideast/stitch-mcp init
# → gcloud 설치, OAuth, 프로젝트 설정 자동 처리
# → 브라우저에서 Google 계정 로그인
```

**2. Claude Code 설정 (`settings.json`)**

```json
{
  "mcpServers": {
    "stitch": {
      "command": "npx",
      "args": ["@_davideast/stitch-mcp", "proxy"]
    }
  }
}
```

지원 클라이언트: Claude Code, Cursor, VS Code, Gemini CLI, Codex, OpenCode

### MCP 도구

| 도구 | 기능 | 파라미터 |
|------|------|----------|
| `build_site` | 프로젝트의 전체 스크린을 라우트로 매핑, 각 페이지 HTML 반환 | `projectId`, `routes[{screenId, route}]` |
| `get_screen_code` | 특정 스크린의 HTML/CSS 코드 다운로드 | `projectId`, `screenId` |
| `get_screen_image` | 특정 스크린의 스크린샷을 base64 이미지로 다운로드 | `projectId`, `screenId` |

### 도구 사용 예시

```bash
# 단일 스크린 코드 가져오기
npx @_davideast/stitch-mcp tool get_screen_code \
  -d '{"projectId": "123456", "screenId": "abc"}'

# 전체 사이트 빌드
npx @_davideast/stitch-mcp tool build_site \
  -d '{
    "projectId": "123456",
    "routes": [
      {"screenId": "abc", "route": "/"},
      {"screenId": "def", "route": "/about"},
      {"screenId": "ghi", "route": "/dashboard"}
    ]
  }'
```

### 트러블슈팅

```bash
# 상태 진단
npx @_davideast/stitch-mcp doctor --verbose

# 재인증
npx @_davideast/stitch-mcp logout --force
npx @_davideast/stitch-mcp init
```

---

## 실전 워크플로우

### 워크플로우 1: 스케치 → 프로덕션 코드

```
손 스케치/와이어프레임
  → Stitch에 업로드 → UI 디자인 자동 생성
  → Claude Code에서 get_screen_code로 HTML/CSS 가져오기
  → 프로젝트 프레임워크(React, Next.js 등)에 맞게 변환
  → 기존 디자인 시스템과 통합
```

### 워크플로우 2: 전체 사이트 구조화

```
Stitch에서 여러 화면 디자인 (홈, 대시보드, 설정 등)
  → build_site로 전체 스크린 라우트 매핑
  → Next.js App Router 구조로 자동 배치
  → 네비게이션, 라우팅 연결
```

### 워크플로우 3: 비개발자 협업

```
PM/디자이너가 Stitch에서 프로토타입 생성 (코딩 불필요)
  → 개발자가 MCP로 디자인 당겨옴
  → 프로젝트 컨벤션에 맞게 자동 변환
  → 비즈니스 로직 연결
```

### 워크플로우 4: 디자인 반복 루프

```
디자인 수정 → Stitch에서 업데이트
  → Claude Code에서 다시 당겨옴
  → diff로 변경분 확인 → 반영
```

---

## Google 공식 Agent Skills

Google이 Stitch MCP와 함께 사용할 수 있는 공식 스킬 라이브러리를 제공한다.

**레포**: https://github.com/google-labs-code/stitch-skills

| 스킬 | 기능 |
|------|------|
| **design-md** | Stitch 프로젝트를 분석하여 DESIGN.md 디자인 시스템 문서 자동 생성. 시맨틱 언어로 디자인 시스템을 기술하여 Stitch 스크린 생성에 최적화 |
| **enhance-prompt** | 모호한 UI 아이디어를 Stitch 최적화 프롬프트로 변환. UI/UX 키워드 추가, 디자인 시스템 컨텍스트 주입 |
| **react-components** | Stitch 스크린을 React 컴포넌트 시스템으로 변환. 자동 검증 + 디자인 토큰 일관성 보장 |
| **remotion** | Stitch 프로젝트에서 Remotion 기반 워크스루 비디오 생성. 전환 효과, 줌, 텍스트 오버레이 포함 |

---

## 주요 링크

| 리소스 | URL |
|--------|-----|
| Stitch 공식 사이트 | https://stitch.withgoogle.com |
| MCP 셋업 문서 | https://stitch.withgoogle.com/docs/mcp/setup |
| stitch-mcp CLI (David East) | https://github.com/davideast/stitch-mcp |
| stitch-mcp npm | https://www.npmjs.com/package/@_davideast/stitch-mcp |
| Google 공식 Agent Skills | https://github.com/google-labs-code/stitch-skills |
| stitch-mcp 자동 설치 | https://github.com/GreenSheep01201/stitch-mcp-auto |
| Gemini CLI 확장 | https://github.com/gemini-cli-extensions/stitch |

## 2026년 3월 기준 최신 업데이트

- AI 네이티브 무한 캔버스(Infinite Canvas) 도입
- 리디자인된 Design Agent
- 음성 인터랙션 지원
- 인스턴트 프로토타이핑
- DESIGN.md 기반 디자인 시스템 ("Vibe Design" 접근법)
- Exports 패널에서 직접 MCP 클라이언트 설정 안내 + API Key 발급 가능
