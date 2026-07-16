# Claude Code 설정 최신 모범 사례 리서치 결과

> 리서치 일자: 2026-03-08
> 대상: CLAUDE.md, .claude/ 디렉토리 전체 설정 시스템

---

## 1. 공식 문서 최신 변경사항

### 1.1 CLAUDE.md 메모리 시스템 (2026 기준)

**출처**: [How Claude remembers your project](https://code.claude.com/docs/en/memory)

주요 업데이트:
- **Managed Policy CLAUDE.md**: 조직 전체 적용되는 최상위 CLAUDE.md 추가 (Linux: `/etc/claude-code/CLAUDE.md`)
  - managed settings에서 배포, 개별 설정으로 exclude 불가
- **`claudeMdExcludes` 설정**: 모노레포에서 불필요한 CLAUDE.md 제외 가능
  ```json
  { "claudeMdExcludes": ["**/monorepo/CLAUDE.md", "/home/user/other-team/.claude/rules/**"] }
  ```
- **Auto Memory 시스템 고도화**:
  - `~/.claude/projects/<project>/memory/` 디렉토리에 `MEMORY.md` + 토픽별 파일 저장
  - `MEMORY.md` 첫 200줄만 세션 시작 시 로드, 나머지는 on-demand
  - 토픽 파일(예: `debugging.md`, `api-conventions.md`)은 필요 시 읽기
  - 서브에이전트도 자체 auto memory 유지 가능 (`memory` frontmatter)
- **Path-specific Rules (`.claude/rules/`)**: `paths:` YAML frontmatter로 특정 파일 패턴에만 룰 적용
  ```markdown
  ---
  paths:
    - "src/api/**/*.ts"
  ---
  # API 개발 규칙
  - 모든 API 엔드포인트에 입력 검증 필수
  ```
- **`@path` 임포트 문법**: 최대 5단계 깊이까지 재귀적 임포트 지원
- **`--add-dir` 플래그**: 추가 디렉토리의 CLAUDE.md 로드 (`CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`)
- **심볼릭 링크 지원**: `.claude/rules/`에서 symlink로 프로젝트 간 공유 규칙 가능

### 1.2 Skills 시스템 (2026 기준)

**출처**: [Extend Claude with skills](https://code.claude.com/docs/en/skills)

주요 업데이트:
- **Custom Commands → Skills 통합**: `.claude/commands/`가 `.claude/skills/`로 통합 (기존 commands 파일 계속 동작)
- **Agent Skills 표준**: [agentskills.io](https://agentskills.io) 오픈 표준 채택
- **새 frontmatter 옵션**:
  - `context: fork` - 서브에이전트에서 격리 실행
  - `agent: Explore|Plan|general-purpose|<custom>` - 서브에이전트 유형 지정
  - `user-invocable: false` - 사용자 메뉴에서 숨김 (Claude만 호출 가능)
  - `hooks:` - 스킬 수명주기에 hooks 연결
  - `model:` - 스킬 실행 모델 지정
- **`$ARGUMENTS[N]` / `$N` 인덱싱**: 개별 인수 접근 가능 (`$0`, `$1` 등)
- **`${CLAUDE_SKILL_DIR}` 변수**: 스킬 디렉토리 경로 참조
- **`${CLAUDE_SESSION_ID}` 변수**: 세션 ID 참조
- **Dynamic Context Injection**: `` !`command` `` 문법으로 쉘 명령 결과를 스킬 내용에 주입
  ```yaml
  ## PR context
  - PR diff: !`gh pr diff`
  - Changed files: !`gh pr diff --name-only`
  ```
- **번들 스킬 추가**:
  - `/simplify` - 코드 리뷰 및 정리 (3개 병렬 에이전트)
  - `/batch <instruction>` - 대규모 병렬 변경 (worktree 활용)
  - `/debug [description]` - 세션 디버그 로그 분석
  - `/loop [interval] <prompt>` - 반복 실행 (cron)
  - `/claude-api` - Claude API 레퍼런스 자동 로드
- **스킬 char budget**: 컨텍스트 윈도우의 2%로 동적 할당 (fallback: 16,000자)
  - `SLASH_COMMAND_TOOL_CHAR_BUDGET` 환경변수로 오버라이드

### 1.3 Hooks 시스템 (2026 기준)

**출처**: [Hooks reference](https://code.claude.com/docs/en/hooks), [Automate workflows with hooks](https://code.claude.com/docs/en/hooks-guide)

주요 업데이트:
- **새 Hook 이벤트**:
  - `InstructionsLoaded` - CLAUDE.md/rules 파일 로드 시점 감지
  - `ConfigChange` - 설정 파일 변경 감지 (감사 로그용)
  - `WorktreeCreate` / `WorktreeRemove` - worktree 수명주기
  - `PreCompact` - 컨텍스트 압축 전 (manual/auto 필터링)
  - `SessionEnd` - 세션 종료 (clear, logout 등 필터링)
  - `PermissionRequest` - 권한 요청 시점
  - `PostToolUseFailure` - 도구 실패 후
  - `TeammateIdle` - Agent Team 멤버 idle 시
  - `TaskCompleted` - 작업 완료 시
- **Hook 유형 확장**:
  - `type: "prompt"` - LLM 기반 판단 (Haiku 기본, `model` 필드로 변경 가능)
  - `type: "agent"` - 멀티턴 에이전트 검증 (파일 읽기/명령 실행 가능, 최대 50턴)
  - `type: "http"` - HTTP POST 엔드포인트 (헤더에 환경변수 보간 지원)
- **스킬/에이전트 내 hooks 정의**: frontmatter에서 직접 hook 설정 가능
- **Async hooks**: 비동기 실행 지원
- **`$CLAUDE_PROJECT_DIR`**: 프로젝트 디렉토리 환경변수

### 1.4 Subagents 시스템 (2026 기준)

**출처**: [Create custom subagents](https://code.claude.com/docs/en/sub-agents)

주요 업데이트:
- **새 frontmatter 옵션**:
  - `skills:` - 서브에이전트에 스킬 프리로드 (전체 내용 주입)
  - `memory: user|project|local` - 영구 메모리 스코프
  - `background: true` - 백그라운드 실행
  - `isolation: worktree` - git worktree 격리
  - `permissionMode:` - `default|acceptEdits|dontAsk|bypassPermissions|plan`
  - `maxTurns:` - 최대 에이전틱 턴 수
  - `hooks:` - 서브에이전트 수명주기 hooks
  - `mcpServers:` - MCP 서버 연결
  - `disallowedTools:` - 도구 거부 목록
- **`Agent(agent_type)` 도구 제한**: 특정 서브에이전트만 생성 허용
  ```yaml
  tools: Agent(worker, researcher), Read, Bash
  ```
- **`/agents` 커맨드**: 대화형 에이전트 관리 인터페이스
- **CLI `--agents` 플래그**: JSON으로 세션별 임시 에이전트 정의
- **Auto-compaction**: 서브에이전트도 자동 압축 지원 (`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE`)
- **Resume**: 서브에이전트 재개 가능 (agent ID로 컨텍스트 유지)

### 1.5 Agent Teams (실험적)

**출처**: [Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams)

- **활성화**: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- **구성**: Team Lead + Teammates, 공유 Task List, 메시지 시스템
- **Delegate Mode**: `Shift+Tab`으로 팀 리드를 coordination-only로 전환
- **Display Mode**: `in-process` (기본) 또는 `tmux/iTerm2` 분할 창
  ```json
  { "teammateMode": "in-process" }
  ```
- **Plan Approval**: 팀원이 구현 전 계획 승인 필요하도록 설정 가능
- **Quality Gates**: `TeammateIdle`, `TaskCompleted` hooks로 품질 게이트 설정

### 1.6 Plugins 시스템

**출처**: [Create plugins](https://code.claude.com/docs/en/plugins)

- **Plugin = Skills + Hooks + Agents + MCP + LSP + Settings 번들**
- **구조**:
  ```
  my-plugin/
  ├── .claude-plugin/plugin.json  # 매니페스트
  ├── skills/                     # 스킬들
  ├── agents/                     # 에이전트들
  ├── hooks/hooks.json            # 훅 설정
  ├── .mcp.json                   # MCP 서버
  ├── .lsp.json                   # LSP 서버 (코드 인텔리전스)
  └── settings.json               # 기본 설정
  ```
- **LSP 지원**: 타입별 코드 인텔리전스 플러그인 (TypeScript, Python, Rust 등)
- **`settings.json` > `agent` 키**: 플러그인의 에이전트를 메인 스레드로 활성화
- **공식 마켓플레이스**: `anthropics/claude-plugins-official`

### 1.7 settings.json 새 옵션들

**출처**: [Claude Code settings](https://code.claude.com/docs/en/settings)

주요 신규 설정:
```json
{
  "$schema": "https://json.schemastore.org/claude-code-settings.json",
  "attribution": {
    "commit": "Co-Authored-By: ...",
    "pr": "Generated with Claude Code"
  },
  "statusLine": { "type": "command", "command": "..." },
  "fileSuggestion": { "type": "command", "command": "..." },
  "outputStyle": "Explanatory",
  "alwaysThinkingEnabled": true,
  "plansDirectory": "./plans",
  "showTurnDuration": true,
  "spinnerVerbs": { "mode": "append", "verbs": ["Pondering"] },
  "language": "한국어",
  "autoUpdatesChannel": "stable",
  "fastModePerSessionOptIn": true,
  "teammateMode": "auto",
  "sandbox": {
    "enabled": true,
    "filesystem": { "allowWrite": [], "denyWrite": [], "denyRead": [] },
    "network": { "allowedDomains": [], "allowLocalBinding": true }
  },
  "cleanupPeriodDays": 30,
  "effortLevel": "high",
  "respectGitignore": true
}
```

### 1.8 기능 선택 가이드 (공식)

**출처**: [Extend Claude Code](https://code.claude.com/docs/en/features-overview)

| 기능 | 로드 시점 | 컨텍스트 비용 | 최적 용도 |
|------|----------|-------------|---------|
| CLAUDE.md | 세션 시작 | 매 요청 (전체) | 항상 적용되는 규칙 |
| `.claude/rules/` | 세션 시작 또는 파일 매칭 시 | 조건부 | 파일/언어별 규칙 |
| Skills | 설명은 시작 시, 전체는 호출 시 | 낮음 | 참조 자료, 워크플로우 |
| Subagents | 생성 시 | 격리됨 | 컨텍스트 보존, 병렬 |
| MCP | 세션 시작 | 매 요청 (스키마) | 외부 서비스 연결 |
| Hooks | 이벤트 발생 시 | 0 (반환값 제외) | 결정적 자동화 |

**핵심 원칙**: CLAUDE.md < 200줄 유지. 레퍼런스 자료는 Skills로, 파일별 규칙은 rules/로 분리.

---

## 2. 커뮤니티 모범 사례

### 2.1 Trail of Bits claude-code-config

**출처**: [trailofbits/claude-code-config](https://github.com/trailofbits/claude-code-config)

보안 중심 팀의 프로덕션 설정:

**주목할 패턴들**:

1. **자격 증명 차단 목록 (deny rules)**:
   ```json
   {
     "permissions": {
       "deny": [
         "Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)",
         "Read(~/.ssh/**)", "Read(~/.gnupg/**)",
         "Read(~/.aws/**)", "Read(~/.azure/**)", "Read(~/.kube/**)",
         "Read(~/.docker/config.json)",
         "Read(~/.npmrc)", "Read(~/.pypirc)",
         "Read(~/.git-credentials)", "Read(~/.config/gh/**)"
         ]
     }
   }
   ```

2. **Anti-rationalization Stop Hook**: Claude가 작업을 완료하지 않고 "out of scope", "pre-existing" 등으로 회피할 때 감지하는 prompt hook
   ```json
   {
     "Stop": [{
       "hooks": [{
         "type": "prompt",
         "prompt": "Check if all tasks are complete. If not, respond with {\"ok\": false, \"reason\": \"what remains\"}."
       }]
     }]
   }
   ```

3. **Bash 명령어 감사 로그**:
   ```json
   {
     "PostToolUse": [{
       "matcher": "Bash",
       "hooks": [{
         "type": "command",
         "command": "jq -r '[' + (now | todate) + '] ' + .tool_input.command' >> ~/.claude/bash-commands.log"
       }]
     }]
   }
   ```

4. **패키지 매니저 강제**: `hooks/enforce-package-manager.sh`로 pnpm 프로젝트에서 npm 차단

5. **Statusline 스크립트**: 2줄 상태바 (모델, git 브랜치, 컨텍스트 사용률 바, 비용, 경과 시간, 캐시 히트율)

6. **`cleanupPeriodDays: 365`**: 기본 30일 → 365일로 변경하여 `/insights` 분석용 대화 보존

7. **`bypassPermissions` + `/sandbox` 조합**: 권한 건너뛰기와 OS 수준 샌드박싱 병행

### 2.2 zircote/.claude

**출처**: [zircote/.claude](https://github.com/zircote/.claude)

대규모 설정 (10개 에이전트 카테고리):

**주목할 패턴들**:

1. **10-tier 에이전트 구조**: Core Development, Language Specialists, Infrastructure, Quality & Security, Data & AI, Developer Experience, Specialized Domains, Business & Product, Meta & Orchestration, Research & Analysis

2. **`includes/` 디렉토리**: 언어/프레임워크별 표준 (python.md, golang.md, react.md, testing.md, opus-4-5.md 등) - `@includes/python.md` 형태로 임포트

3. **다층 명령어 체계**:
   - `/git:cm`, `/git:cp`, `/git:pr` - Git 워크플로우
   - `/cr` - 병렬 전문가 코드 리뷰
   - `/explore` - Opus 4.5를 사용한 코드베이스 분석
   - `/deep-research` - 다단계 리서치 프로토콜

### 2.3 Awesome Claude Code

**출처**: [hesreallyhim/awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) (26.8k stars)

**주목할 도구들**:

1. **claudekit**: CLI 도구 (체크포인팅, 품질 hooks, 20+ 서브에이전트)
2. **ccexp**: 대화형 CLI로 Claude 설정 파일/커맨드 탐색
3. **ccflare**: 웹 기반 사용량 대시보드
4. **claude-rules-doctor**: glob 패턴 검증으로 dead rule 파일 감지
5. **ClaudeCTX**: 단일 명령으로 전체 설정 전환
6. **ccstatusline**: Rust 기반 커스텀 상태바 (Git 통합, 사용량 추적)
7. **CC Notify**: 데스크톱 알림 hook

**워크플로우 패턴**:
- **AB Method**: 스펙 기반 개발 (문제 → 집중 미션 변환)
- **RIPER Workflow**: Research → Innovate → Plan → Execute → Review 구조화 단계
- **Ralph Wiggum Technique**: 반복 작업 완료를 위한 자율 루프

### 2.4 Context Engineering Kit

**출처**: awesome-claude-code에서 언급

"Advanced context engineering techniques and patterns with minimal token footprint" - 최소 토큰으로 컨텍스트 엔지니어링하는 기법 모음

### 2.5 커뮤니티 Statusline

**출처**: [ccstatusline](https://github.com/sirmalloc/ccstatusline), [claude_monitor_statusline](https://github.com/gabriel-dehan/claude_monitor_statusline)

- Rust 기반 고성능 statusline
- SQLite 영속화, 번 레이트 계산, 테마 지원
- 주간 사용량 추적

---

## 3. 반영 후보 항목 (우리에게 없거나 개선할 수 있는 것)

### 3.1 [신규] Path-specific Rules

**현재**: `.claude/rules/`에 범용 규칙 파일만 존재
**권장**: `paths:` frontmatter로 파일 패턴별 조건부 룰 적용

```markdown
# .claude/rules/api-rules.md
---
paths:
  - "src/api/**/*.{ts,py}"
  - "routes/**/*"
---
# API 개발 규칙
- 모든 엔드포인트에 입력 검증 (Zod/Pydantic) 필수
- RESTful 네이밍 컨벤션 사용
```

**이점**: 불필요한 컨텍스트 소비 감소, 관련 파일 작업 시에만 로드

### 3.2 [신규] Credential/Secret Deny Rules

**현재**: permissions에 read-only allow만 있음, deny 규칙 없음
**권장**: 민감 파일 접근 차단

```json
{
  "permissions": {
    "deny": [
      "Read(./.env)", "Read(./.env.*)", "Read(./secrets/**)",
      "Read(~/.ssh/**)", "Read(~/.aws/**)", "Read(~/.config/gh/**)",
      "Read(~/.npmrc)", "Read(~/.pypirc)"
    ]
  }
}
```

**이점**: 프롬프트 인젝션 공격 시에도 시크릿 유출 방지 (security.md 원칙과 일치)

### 3.3 [신규] Notification Hook

**현재**: 알림 hook 없음
**권장**: Claude가 입력 대기 시 데스크톱 알림

```json
{
  "Notification": [{
    "matcher": "",
    "hooks": [{
      "type": "command",
      "command": "notify-send 'Claude Code' 'Claude Code needs your attention'"
    }]
  }]
}
```

### 3.4 [신규] Auto-format PostToolUse Hook

**현재**: 포맷팅 hook 없음 (CLAUDE.md에서 advisory로만 지시)
**권장**: 파일 편집 후 자동 포맷팅

```json
{
  "PostToolUse": [{
    "matcher": "Edit|Write",
    "hooks": [{
      "type": "command",
      "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write 2>/dev/null || true"
    }]
  }]
}
```

### 3.5 [신규] Stop Hook (Anti-rationalization / 완료 검증)

**현재**: 작업 완료 검증 hook 없음
**권장**: Claude가 작업을 불완전하게 끝내는 것을 방지

```json
{
  "Stop": [{
    "hooks": [{
      "type": "prompt",
      "prompt": "Check if Claude completed all requested tasks. Look for phrases like 'out of scope', 'pre-existing issue', 'follow-up needed', or incomplete implementations. If work is incomplete, respond with {\"ok\": false, \"reason\": \"specific remaining task\"}."
    }]
  }]
}
```

### 3.6 [신규] Statusline 설정

**현재**: statusline 미설정
**권장**: 컨텍스트 사용률, 비용, git 브랜치 실시간 표시

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/scripts/statusline.sh"
  }
}
```

### 3.7 [신규] SessionStart compact Hook

**현재**: 컨텍스트 압축 후 재주입 없음
**권장**: compact 후 핵심 컨텍스트 재주입

```json
{
  "SessionStart": [{
    "matcher": "compact",
    "hooks": [{
      "type": "command",
      "command": "echo '리마인더: 한국어로 응답. agent-guide/ 참고. 변경 이유 설명 필수.'"
    }]
  }]
}
```

### 3.8 [개선] Subagent Memory 활용

**현재**: 에이전트에 `memory` 필드 미사용
**권장**: `security-reviewer`, `verifier` 등에 영구 메모리 추가

```yaml
# .claude/agents/security-reviewer.md
---
name: security-reviewer
description: ...
memory: user
---
```

**이점**: 반복 리뷰에서 프로젝트별 보안 패턴 축적

### 3.9 [개선] Subagent skills 프리로드

**현재**: 에이전트에 skills 프리로드 미사용
**권장**: 전문 에이전트에 관련 스킬 주입

```yaml
# .claude/agents/build-resolver.md
---
name: build-resolver
skills:
  - react-best-practices
  - postgres-best-practices
---
```

### 3.10 [개선] Skills frontmatter 현대화

**현재**: 스킬에 `disable-model-invocation`, `context`, `agent` 등 미활용
**권장**: 부작용 있는 스킬에 `disable-model-invocation: true` 적용, 리서치 스킬에 `context: fork` + `agent: Explore`

### 3.11 [신규] Dynamic Context Injection in Skills

**현재**: 스킬에 동적 컨텍스트 주입 미활용
**권장**: `` !`command` `` 문법으로 실시간 데이터 주입

```yaml
# code-review 스킬
## 현재 변경사항
- Modified files: !`git diff --name-only`
- Recent commits: !`git log --oneline -5`
```

### 3.12 [신규] $schema 추가

**현재**: settings.json에 스키마 참조 없음
**권장**:
```json
{ "$schema": "https://json.schemastore.org/claude-code-settings.json" }
```
**이점**: IDE에서 자동완성, 설정 유효성 검증

### 3.13 [신규] Plugins / Marketplace 도입 검토

**현재**: 모든 스킬이 dotfiles 내 직접 관리
**권장**: 재사용 가능한 스킬 세트를 플러그인으로 패키징하여 팀 공유 또는 개인 프로젝트 간 재활용

### 3.14 [신규] LSP 플러그인 활용

**현재**: LSP 미활용
**권장**: 공식 마켓플레이스의 코드 인텔리전스 플러그인 설치 (TypeScript, Python 등)
**이점**: Claude에게 정확한 심볼 탐색, 편집 후 자동 에러 감지

### 3.15 [신규] Bash 명령어 감사 로그

**현재**: 명령어 로깅 없음
**권장**: PostToolUse hook으로 모든 Bash 명령어 기록

```json
{
  "PostToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "jq -r '.tool_input.command' >> ~/.claude/bash-commands.log"
    }]
  }]
}
```

### 3.16 [개선] rules/ 파일에 symlink 활용

**현재**: dotfiles에 rules/ 직접 포함
**권장**: 프로젝트 간 공통 규칙을 symlink로 공유

```bash
ln -s ~/dotfiles/.claude/rules/security.md /project/.claude/rules/security.md
```

---

## 4. 반영하지 않을 항목 (이유 포함)

### 4.1 10-tier 에이전트 구조 (zircote 스타일)

**이유**: 현재 4개 에이전트(build-resolver, planner, security-reviewer, verifier)로 충분. 과도한 에이전트는 컨텍스트 비용 증가와 위임 혼란 유발. 필요 시 점진적 추가가 적절.

### 4.2 `--dangerously-skip-permissions` 일상 사용

**이유**: Trail of Bits는 sandbox와 함께 사용하지만, 우리 설정은 이미 auto-approve-readonly.sh hook으로 읽기 전용 명령을 자동 승인하여 UX와 보안의 균형을 맞추고 있음. 전체 권한 건너뛰기는 불필요한 위험.

### 4.3 Agent-based Stop Hook (multi-turn 검증)

**이유**: `type: "agent"` hook은 매 Stop마다 서브에이전트를 생성하여 토큰 비용이 높음. `type: "prompt"` (Haiku 단일 판단)가 비용 대비 효과적.

### 4.4 HTTP Hooks

**이유**: 로컬 개발 환경에서 HTTP 서버 유지 필요. 현재 사용 사례(개인 dotfiles)에서는 command hook으로 충분.

### 4.5 `includes/` 디렉토리 패턴

**이유**: 이미 `.claude/rules/`와 `@path` 임포트로 동일 기능 구현 가능. 별도 `includes/` 디렉토리는 불필요한 중복.

### 4.6 Claude Code on the Web / Desktop App

**이유**: 클라우드 인프라 종속성. 현재 CLI 기반 워크플로우가 유연하고 설정 이식성이 높음.

### 4.7 Managed Policy CLAUDE.md

**이유**: 조직/팀 단위 배포용. 개인 dotfiles 설정에서는 `~/.claude/CLAUDE.md`로 충분.

### 4.8 MCP Tool Search 커스텀

**이유**: 현재 MCP 사용량이 적음. MCP 도구가 10개 이상일 때 의미 있는 최적화.

---

## 5. 우선순위 요약

### P0 (즉시 반영 권장)
1. **Credential Deny Rules** - 보안 강화 (security.md 원칙 실현)
2. **$schema 추가** - IDE 지원 향상
3. **Path-specific Rules** - 컨텍스트 최적화

### P1 (단기 반영 권장)
4. **Notification Hook** - 작업 효율 향상
5. **Stop Hook (prompt)** - 불완전 작업 방지
6. **SessionStart compact Hook** - 컨텍스트 압축 후 복구
7. **Skills frontmatter 현대화** - `disable-model-invocation`, `context: fork` 활용

### P2 (중기 검토)
8. **Statusline 설정** - 실시간 모니터링
9. **Subagent memory/skills** - 에이전트 지식 축적
10. **Dynamic Context Injection** - 스킬 동적 데이터
11. **Auto-format Hook** - 자동 포맷팅
12. **Bash 감사 로그** - 디버깅/감사

### P3 (장기 검토)
13. **LSP 플러그인** - 코드 인텔리전스
14. **Plugin 패키징** - 스킬 재사용성
15. **Symlink 공유 규칙** - 프로젝트 간 일관성

---

## 출처

### 공식 문서
- [Best Practices for Claude Code](https://code.claude.com/docs/en/best-practices)
- [How Claude remembers your project](https://code.claude.com/docs/en/memory)
- [Extend Claude with skills](https://code.claude.com/docs/en/skills)
- [Hooks reference](https://code.claude.com/docs/en/hooks)
- [Automate workflows with hooks](https://code.claude.com/docs/en/hooks-guide)
- [Create custom subagents](https://code.claude.com/docs/en/sub-agents)
- [Orchestrate teams of Claude Code sessions](https://code.claude.com/docs/en/agent-teams)
- [Claude Code settings](https://code.claude.com/docs/en/settings)
- [Extend Claude Code](https://code.claude.com/docs/en/features-overview)
- [Create plugins](https://code.claude.com/docs/en/plugins)
- [Discover and install plugins](https://code.claude.com/docs/en/discover-plugins)
- [Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)

### 커뮤니티 / GitHub
- [awesome-claude-code](https://github.com/hesreallyhim/awesome-claude-code) (26.8k stars)
- [trailofbits/claude-code-config](https://github.com/trailofbits/claude-code-config) - 보안 중심 설정
- [zircote/.claude](https://github.com/zircote/.claude) - 대규모 에이전트/스킬 구성
- [anthropics/skills](https://github.com/anthropics/skills) (86.8k stars) - 공식 스킬
- [awesome-claude-skills](https://github.com/travisvn/awesome-claude-skills)
- [shanraisshan/claude-code-best-practice](https://github.com/shanraisshan/claude-code-best-practice)

### 블로그 / 가이드
- [Writing a good CLAUDE.md - HumanLayer](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Claude Skills and CLAUDE.md: a practical 2026 guide](https://www.gend.co/blog/claude-skills-claude-md-guide)
- [Context Management Strategies for Claude Code](https://datalakehousehub.com/blog/2026-03-context-management-claude-code/)
- [My Claude Code setup - Freek Van der Herten](https://freek.dev/3026-my-claude-code-setup)
- [Claude Code Hooks: Complete Guide with 20+ Examples](https://aiorg.dev/blog/claude-code-hooks)
- [A Mental Model for Claude Code: Skills, Subagents, and Plugins](https://levelup.gitconnected.com/a-mental-model-for-claude-code-skills-subagents-and-plugins-3dea9924bf05)
