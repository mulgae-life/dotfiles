# 스킬 출처와 상류 갱신 절차

> 어떤 스킬이 공식 스킬을 이식한 것인지, 상류가 어디인지, 갱신할 때 무엇을 보존해야 하는지 기록한다. "공식 기반 스킬 업데이트" 요청은 이 문서의 2절 표를 기준으로 진행한다. 갱신 이력은 [CHANGELOG.md](../CHANGELOG.md).

## 1. 구분

| 구분 | 뜻 | 갱신 계기 |
|------|-----|-----------|
| **이식** | 공식 저장소의 스킬을 가져와 번역·조정한 것 | 상류 저장소가 바뀌었을 때 (2절) |
| **자체 제작** | 상류 저장소 없음. 공식 문서를 참고한 것도 여기 포함 | 필요할 때 직접 개정 (3절) |

## 2. 이식 스킬 — 상류 동기화 대상

| 스킬 | 상류 저장소 · 경로 | 이식 방식 | 갱신 때 보존할 로컬 변경 |
|------|-------------------|-----------|--------------------------|
| `frontend-design` | `anthropics/skills` · `skills/frontend-design/SKILL.md` | 본문 전문 번역. 프론트매터는 dotfiles 규격(`description`·`when_to_use`) | 없음. 번역만 다시 하면 된다 |
| `skill-creator` | `anthropics/skills` · `skills/skill-creator/` | 본문·`scripts/`·`references/` 영문 원문 유지, 프론트매터만 번역 | `scripts/` 4개: 하위 `claude` 호출 격리(`--tools ""` + `--safe-mode`), zip 패키징의 심링크 유출 차단, `quick_validate` 필드·`name` 규격 정합. 코드 예시 모델 ID는 `claude-opus-5`. `SKILL.md` 본문의 뷰어 실행은 `nohup … &`·`kill` 대신 `run_in_background` 배경 작업으로, 브라우저 열기는 `open` 대신 환경별(`xdg-open`·헤드리스는 경로 안내)로 바꿔 둔 것 |
| `react-best-practices` | `vercel-labs/agent-skills` · `skills/react-best-practices/` | `rules/`·`AGENTS.md`·`metadata.json` 원문 그대로, `SKILL.md`만 번역 | `rules/rendering-hydration-no-flicker.md`와 `AGENTS.md` 같은 절의 `suppressHydrationWarning` 보완 2곳. 상류의 옛 서술로 덮지 않는다 |
| `web-design-guidelines` | 규칙: `vercel-labs/web-interface-guidelines` · `command.md` / 래퍼: `vercel-labs/agent-skills` · `skills/web-design-guidelines/` | `command.md` 본문을 `references/` 스냅샷으로 원문 보관, `SKILL.md`는 자체 작성(카테고리 표, 심각도 3단계) | 출력은 로컬 심각도 형식이 상류 형식보다 우선. 스냅샷을 바꾸면 `SKILL.md` 카테고리 표도 함께 보강 |
| `postgres-best-practices` | `supabase/agent-skills` · `skills/supabase-postgres-best-practices/` | `references/` 원문 그대로, `SKILL.md` 번역. 상류가 없앤 `AGENTS.md`·`metadata.json`은 두지 않는다 | `references/conn-prepared-statements.md`의 prepare 귀속 정정(node-postgres는 기본 미사용), `references/monitor-explain-analyze.md`의 DML 경고, `references/schema-primary-keys.md`의 PG18 내장 `uuidv7()`, `references/_sections.md`의 자리표시 문장 삭제 |
| `stitch-design` | `google-labs-code/stitch-skills` · `plugins/stitch-design/`·`plugins/stitch-build/`·`plugins/stitch-utilities/` | 진입 `SKILL.md` 자체 작성(라우팅 표·공통 규약), 세 플러그인의 `skills/` 하위 16종을 한 `skills/`에 모아 영문 원문 유지 | 진입 파일의 도구명 `mcp__stitch__*`·경로 계약(`.stitch/` 아래) 규약. 하위 원문 수정: `design-md`·`enhance-prompt`의 `.stitch/DESIGN.md` 경로, `manage-design-system`의 업로더 스크립트 경로를 `skills/upload-to-stitch/…`로, `react-components/README.md`의 체크리스트 8항목(상류 오기 20), `remotion/examples/WalkthroughComposition.tsx`의 전환 길이 계산·`linearTiming`·`staticFile`, `remotion/scripts`의 서명 URL 쿼리 로그 제거, `shadcn-ui/README.md` 절대 링크, `shadcn-ui/SKILL.md`의 Base UI 언급, `shadcn-ui/scripts/verify-setup.sh`의 Tailwind v3/v4 겸용 검사. `stitch-loop`의 "Section 6" 일반화는 상류 문구가 파일명·절 제목을 함께 밝혀 모호하지 않으므로 되돌리지 않는다 |
| `code-simplifier` | `anthropics/claude-plugins-official` · `plugins/code-simplifier/agents/code-simplifier.md` | 52줄 에이전트 프롬프트를 복잡도 지표·5단계 프로세스로 확장, `references/`는 자체 작성 | 본문 전체가 확장본이다. 상류의 5원칙(기능 보존·프로젝트 표준·명확성·균형·범위)이 유지되는지만 대조한다 |
| `code-review` | `anthropics/claude-plugins-official` · `plugins/code-review/commands/code-review.md` | 구조가 다르다(상류는 PR 댓글 워크플로우, 로컬은 파일 리포트). 오탐 제외 목록만 차용 | 상류에서 대조할 것은 오탐 제외 목록뿐 |

## 3. 자체 제작 스킬

`start`, `brief`, `init-project`, `update-docs`, `work-verify`, `work-plan`, `feedback-analysis`, `reference-verification`, `recursive-discussion`, `llm-api-guide`, `writing-prompts`, `langchain-guide`, `hw-design`, `hw-ppt`

## 4. 이식 스킬 갱신 절차

1. 상류 최신본을 스크래치 디렉토리에 내려받는다. 파일은 `https://raw.githubusercontent.com/<저장소>/main/<경로>`, 디렉토리 목록은 `https://api.github.com/repos/<저장소>/contents/<경로>`.
2. 로컬과 대조한다. 원문 유지 파일은 `diff`로 통째로, 번역 파일은 절·문단 구조와 고유명사·수치로 대조한다.
3. 2절 표의 "보존할 로컬 변경"은 상류로 덮지 않고 다시 적용한다. 표에 없는 로컬 차이가 나오면 `git log -p`로 의도를 확인하고, 의도된 것이면 표에 추가한다.
4. 번역 대상은 다시 번역한다. 프론트매터는 dotfiles 규격(`name`·`description`·`when_to_use`)을 유지하고, 다른 스킬을 가리키는 문구는 넣지 않는다.
5. 룰 수와 `SKILL.md` 목록의 일치, 상대 링크, 프론트매터 파싱을 확인하고 `bash scripts/verify-policies.sh`를 돌린다.
6. `CHANGELOG.md`에 행을 추가하고, 보존 항목이 늘었으면 2절 표를 고친다.
