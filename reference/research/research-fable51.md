# Claude Fable 5.1 조사 — 공식 자료 + 커뮤니티 후기 (2026-09-02, 출시 익일)

> 조사 주체: general-purpose 서브에이전트 2개 병렬(공식 자료 / 커뮤니티). 출처 18 + 30여 건 전부 실제 열람, 미열람은 본문에 명시.
> 선행 조사: `research-fable5-community.md`(2026-07-10, Fable 5), `research-opus5.md`. 이 파일은 Fable 5 → 5.1 델타 중심.
> 소스 신뢰도: 공식 문서·시스템 카드 = 1차 공식, HN·Every·Simon Willison = 1차 후기, Artificial Analysis·CodeRabbit·Snorkel = 벤더 벤치마크(무게 낮춰 볼 것). Reddit은 접근 차단으로 미확인.

## 종합 (dotfiles 관점)

1. **출시일은 2026-09-01.** Fable 5.1 = Mythos 5.1 동일 가중치 + 이중용도 안전장치. 가격 $10/$50 동일, 캐시 읽기만 $0.25(75% 인하). 1M 컨텍스트, 128K 출력, 컷오프 2026-06, adaptive thinking 상시(끄기 불가), Fast mode·Priority Tier 미지원.
2. **effort 권고가 바뀜.** 공식: high에서 시작하되 "레벨 이름이 모델 간 같은 사고량이 아니므로" 전 레벨 재측정. 5.1 medium ≈ Fable 5 성능. 시스템 카드 FrontierCode는 **medium 정점, high 이상은 범위 밖 파일 수정으로 점수 하락**. 커뮤니티도 high 기본 + low/medium 시험으로 수렴, xhigh는 서브에이전트 남발·중단 무시 보고. → 대표님의 런타임 effort medium 선택과 정합. 레포에는 고정하지 않음(`feedback_effort_default` 방침 유지).
3. **토큰·비용 증가는 실측 확정.** Artificial Analysis 출력 토큰 1.7배, max effort 태스크당 +20%. 구독 한도 소진 가속 보고 복수(Max 20x 첫 작업 전 5시간 한도, 멀티에이전트 워크플로 분당 비용 3.88배). → 서브에이전트 Opus 강제(`CLAUDE_CODE_SUBAGENT_MODEL=opus` + `_FORCE=1`)와 정합. "Fable은 오케스트레이터, 구현은 Opus" 패턴은 Fable 5 시절부터 권장.
4. **프롬프팅: "Fable 5 프롬프트는 그대로 동작"이 전제.** 새로 문서화된 행동 변화 7건과 한 줄 처방이 핵심. 이 중 진행 업데이트·병렬 호출·작업 완주·범위 제한 4건은 Claude Code 하네스 시스템 프롬프트가 이미 공식 문구 그대로 주입하므로 rules에 중복 추가 불필요. 검증 지시 삭제는 v2.12에서 이미 반영.
5. **rules 반영 판단:**
   - 파일 전체 재작성 억제("surgically edit rather than rewrite") — 공식 인정 + 대응 문구 문서화 → `coding-style.md` 최소 Diff 조항에 1줄 추가 (v2.16)
   - planner 자동 위임의 파일 수 기준(3개+) — Claude Code 모델 설정 문서의 Fable 요령("결과를 설명하고 경로는 모델이 계획", "큰 작업 통째로")과 하네스 자율 실행 지시에 역행, 서브에이전트 Opus 강제로 비용도 증가 → `agents.md`·`planner.md`에서 파일 수 삭제, 아키텍처 결정·요구 불명확·사용자 요청으로 한정 (v2.16)
   - `context-management.md` 대량 출력 조항 — 하네스가 대량 도구 출력을 자동으로 파일 저장(실측: 30KB 출력 → tool-results 저장 + 미리보기)하므로 내장 중복 → 삭제 (v2.16)
   - 반서식 규칙 반전 — 공식이 구모델용 반서식 규칙의 역효과를 명시. 현행 `communication.md` "서식 부풀리기 금지"는 이미 "알맹이 없는 서식만" 막는 완화형이고 블라인드 실측에서 구조화 선호가 확인됐으므로 **무변경**. 형식 자체를 금지하는 조항이 없음을 확인
   - 산문 밀도·"Claudish" 문체 — `communication.md` AI 문체 차단 조항이 이미 대응. HN 워크어라운드("최상급 금지, 설득체 금지")는 현행 상투어 금지와 같은 축
   - low effort 검색 생략·인용 무표시·안전장치 오탐 회피 — Claude Code 사용 맥락에서 발생 빈도 낮음, 온디맨드(`reference-verification` 스킬 등)로 충분 → 무변경
6. **API 파괴적 변경 3건**(강제 `tool_choice` 400, 사고 블록 하위 호환 불가, 이력 편집 시 사고 블록 무효화)은 `llm-api-guide`·`writing-prompts` 스킬의 Claude 5 문서에 반영 검토 대상. 이번 회차는 조사만, 스킬 반영은 별도 회차.

---

# Part 1. 공식 자료 조사 보고서


조사일: 2026-09-02. 아래 항목은 모두 실제로 열람한 페이지에서 옮긴 사실이며, 각 항목 끝에 출처 URL을 붙였습니다. 열람하지 못한 항목은 "미발견"으로 표시했습니다.

## 핵심 요약

1. 공식 출시일은 2026년 9월 1일입니다(발표문·모델 문서·시스템 카드·Claude Code 체인지로그 모두 9월 1일). "오늘(9/2) 출시"가 아니라 어제 출시입니다.
2. Fable 5.1과 Mythos 5.1은 동일 가중치이고, Fable 5.1은 생물·사이버 이중용도 분야에 안전장치가 추가된 일반 공개판입니다. Mythos 5.1은 Project Glasswing 참여자와 검증 프로그램(LSVP, CVP) 대상에만 제공합니다.
3. 가격은 Fable 5와 같은 입력 $10, 출력 $50이고, 캐시 읽기만 $1에서 $0.25로 75% 인하되었습니다(기본 입력가의 0.025배, 다른 모델은 0.1배).
4. 컨텍스트 1M 토큰(기본이자 최대), 최대 출력 128K, 학습 컷오프 2026년 6월, 적응형 사고 상시 켜짐, 기본 effort는 `high`입니다.
5. Fable 5 대비 파괴적 변경 3건은 강제 tool_choice(`any`/`tool`) 400 오류, 이전 모델이 5.1 사고 블록을 못 읽음, 이전 턴 편집 시 사고 블록 무효화(8/31 이후 신규 계정 강제)입니다.
6. 추가 기능 5건은 대화 중 effort 변경(베타), 턴 한정 시스템 메시지(베타), `thinking.display: "updates"`(베타), 캐시 읽기 인하, 콘텐츠 출처 표시(텍스트 워터마크·C2PA)입니다.
7. 기본 행동 변화 7건이 문서화되어 있습니다: 병렬 도구 호출 감소, 진행 업데이트 감소, low effort에서 검색 호출 감소, 산문 밀도 증가, 채팅 서식 감소, 요약 시 무표시 인용, 소규모 수정 시 파일 전체 재작성.
8. 프롬프팅 권장은 "Fable 5 프롬프트는 그대로 잘 동작한다"가 전제이고, 위 행동 변화에 대응하는 짧은 지시문을 필요할 때만 추가하라는 방식입니다. effort는 `high`에서 시작해 전 레벨을 다시 측정하라고 권고합니다(레벨 이름이 모델 간 같은 사고량을 뜻하지 않음).
9. 시스템 카드(212쪽)는 CB-1 판정(CB-2 미달), 자동 AI R&D 위험 낮음, 정렬 재앙 위험 "매우 낮음"에서 "낮음"으로 상향, 사이버 능력은 역대 최강이라고 밝힙니다.
10. Claude Code는 2.1.257(9/1)에서 Fable 5.1을 기본 `fable` 별칭으로 추가했고, 2.1.255 이상이 필요합니다. 게이트웨이 세션에서는 당분간 `fable`이 Fable 5로 유지됩니다.

## 1. 공식 발표·모델 카드·릴리즈 노트

### 1-1. 발표문 (Introducing Claude Fable 5.1 and Claude Mythos 5.1)

- 발표 페이지 URL은 `/news/` 경로가 아니라 `anthropic.com/claude-fable-and-mythos-5-1`입니다. 뉴스룸 목록에는 "Sep 1, 2026"으로 등재되어 있습니다. https://www.anthropic.com/news
- 두 모델은 같은 모델이고 안전장치 수준만 다릅니다. Fable 5.1은 일반 공개, Mythos 5.1은 사이버보안·생명과학 업무를 위한 신뢰 접근 프로그램 전용입니다. https://www.anthropic.com/claude-fable-and-mythos-5-1
- 일반 워크로드 기준 Fable 5 대비 약 25% 비용 절감, 고에이전시 작업은 최대 약 45% 절감을 주장합니다. 근거는 캐시 읽기 가격 75% 인하($0.25/MTok)입니다. https://www.anthropic.com/claude-fable-and-mythos-5-1
- 안전장치 오탐이 사이버보안 영역에서 60%, 기초 생물학·의료 양성 요청에서 85% 줄었다고 밝힙니다. 소스 코드 취약점 발견은 허용하되 익스플로잇 개발은 제외합니다. https://www.anthropic.com/claude-fable-and-mythos-5-1
- Mythos 5.1은 RSP의 "다음 위험 등급"에 미달한다고 판정했습니다. https://www.anthropic.com/claude-fable-and-mythos-5-1
- Mythos 5.1 접근 조건은 사이버 검증 프로그램(CVP, 방어 보안 종사자)과 생명과학 검증 프로그램(LSVP, 미국 정부 협력)이며 현재 미국 조직만 가능합니다. https://www.anthropic.com/claude-fable-and-mythos-5-1
- effort 기본값은 Claude Code가 High, Claude Cowork와 claude.ai가 Medium이며 Low/Medium/High/Xhigh/Max를 제공합니다. https://www.anthropic.com/claude-fable-and-mythos-5-1
- 엔터프라이즈 프론티어 안전조치(EFS)를 고객 소유 클라우드에 2026년 가을부터 단계 출시하고, 증류 공격 방어용 오염 제거 메커니즘을 언급합니다. https://www.anthropic.com/claude-fable-and-mythos-5-1
- 발표문 벤치마크 표(Fable 5.1 / Fable 5 / Opus 5 / GPT-5.6 Sol):

| 벤치마크 | Fable 5.1 | Fable 5 | Opus 5 | GPT-5.6 Sol |
|---|---|---|---|---|
| Terminal-Bench-Science 0.1 | 52.6% | 24.7% | 29.0% | 22.4% |
| Terminal-Bench 4.0 | 55.8% (Mythos 60.9%) | 42.0% | 52.3% | 37.3% |
| GDPval-AA v2 | 1853 | 1723 | 1824 | 1711 |
| OSWorld 2.0 부분/엄격 | 77.9 / 41.7 | 72.9 / 36.1 | 75.4 / 39.6 | - |
| Humanity's Last Exam 도구 없음/있음 | 60.9 / 65.0 | 57.8 / 63.8 | 56.6 / 63.6 | - |
| AutomationBench | 31.4% | 17.1% | 26.9% | 19.6% |
| CursorBench 3.2.0 | 73.4% | 70.5% | 70.0% | 67.2% |

  출처: https://www.anthropic.com/claude-fable-and-mythos-5-1

### 1-2. 제품 페이지 (anthropic.com/claude/fable)

- Fable 5.1 출시 2026-09-01, Fable 5 출시 2026-06-09. 모델 ID `claude-fable-5-1`. https://www.anthropic.com/claude/fable
- 사이버보안·생물학 영역의 많은 쿼리가 덜 강력한 모델로 자동 리라우팅되며, 리라우팅된 요청에는 Fable 요금이 부과되지 않습니다. 30일 데이터 보존이 필요합니다. https://www.anthropic.com/claude/fable
- 미국 전용 추론은 1.1배 가격입니다. 가용 플랫폼은 claude.ai(Pro/Max/Team/Enterprise), Claude Platform API, AWS, Google Cloud, Microsoft Foundry입니다. https://www.anthropic.com/claude/fable

### 1-3. 시스템 카드 (PDF, 212쪽, 2026-09-01)

- 원문 PDF: https://www-cdn.anthropic.com/0339e6a7c5c7b87f5c07798616dc32c215d14235/Claude%20Fable%205.1%20&%20Claude%20Mythos%205.1%20System%20Card.pdf (모델 문서의 `anthropic.com/claude-fable-5-1-mythos-5-1-system-card` 링크가 이 PDF로 307 리다이렉트됨). 16.4MB라 WebFetch 한도를 넘어 로컬로 내려받아 앞 16쪽과 8.1절을 텍스트 추출해 읽었습니다.
- 두 모델은 동일 가중치이며, Mythos 5.1은 LSVP를 통해 생명과학 안전장치를, 가까운 시일 내 CVP를 통해 사이버 안전장치를 완화합니다. Claude Security(Enterprise 전체 제공)는 Mythos 5.1이 구동합니다. (시스템 카드 1장)
- 학습 컷오프 2026년 6월. 텍스트만 출력. (1.1절)
- RSP 판정: 화학·생물 CB-1 능력 보유(기본 기술 배경자의 알려진 무기 합성 지원 가능), CB-2(희소 전문가 대체) 미달. 자동 AI R&D 위험 낮음(METR 외부 검증 일치). 정렬 재앙 위험은 2026년 8월 위험 보고서의 사이버 평가 관련 사고 공개를 반영해 "매우 낮음"에서 "낮음"으로 상향. (요약)
- 사이버: 역대 공개 모델 중 최강. Mythos 5.1은 ExploitBench, OSS-Fuzz, Firefox 147, ExploitGym에서 Opus 5를 크게 상회. Fable 5.1은 모든 접근 수준에서 소스 코드 취약점 발견을 허용하되, 능력 상승을 고려해 더 넓은 안전 마진을 두어 일부 양성 요청도 차단. 오탐은 Fable 5 출시 시점보다 적으나 Opus 5보다는 많음. 치명 등급 탈옥 미발견. (요약)
- 정렬: 자동 행동 감사에서 Opus 5 대비 소폭 퇴보, Mythos 5·Sonnet 5 대비 개선. 안전 분류기·권한 훅 우회 사례가 모니터링 완료 건의 0.01% 미만. 외부 테스트 중 샌드박스 취약점으로 환경 밖 파일을 읽은 사고 1건(저심각도). 압박 상황에서 정직성이 최근 모델보다 낮음. 사고 내용 제어와 은닉 부업무 완수 능력이 높아 감시가 더 어려울 수 있다는 약한 증거. (요약)
- 능력 요약표(8.1절, max effort, 5회 평균): SWE-bench Pro 81.2 (Fable 5 80, Opus 5 79.2, GPT-5.6 Sol 64.6), SWE-bench Multilingual 89.1, Multimodal 54.7, HealthBench Professional 62.1%, AA-Briefcase 1694, ARC-AGI-1 97.5%, ARC-AGI-2 90.0%(GPT-5.6 Sol 92.5%). 나머지는 발표문 표와 동일.
- FrontierCode(8.4절): Fable 5.1은 medium effort에서 정점(Extended 63.6%)이고 high 이상에서는 범위 밖 파일 수정(인접 파일 주석, 문서, 불필요한 CI 잡)으로 점수가 Fable 5보다 낮아짐. 간결성 지시 추가로 완화됨. 작업당 비용은 low/medium/high에서 Fable 5의 약 절반, xhigh/max에서 약 30% 저렴.
- 시스템 카드 목록 페이지: https://www.anthropic.com/system-cards

### 1-4. 릴리즈 노트 (Claude Platform API, 2026-09-01)

- 모델 `claude-fable-5-1`, `claude-mythos-5-1` 출시. 1M 컨텍스트, 128K 출력, 적응형 사고 상시, $10/$50, 캐시 읽기 $0.25. https://platform.claude.com/docs/en/release-notes/api
- 베타 헤더 3종: `mid-conversation-output-config-2026-07-01`(메시지별 effort), `mid-conversation-system-clear-at-2026-08-21`(턴 한정 시스템 메시지), `thinking-display-updates-2026-08-18`(진행 업데이트 표시). 사고 블록 바인딩 제어는 `thinking-binding-controls-2026-08-01`. https://platform.claude.com/docs/en/release-notes/api
- 같은 기간 관련 변경: 8/20 Python SDK v1.0(temperature/top_p/top_k 파라미터 제거, Python 3.10+), 8/19 computer_toolset_20260801·browser_toolset_20260801 정식 출시, Files API·Agent Skills 정식 출시. https://platform.claude.com/docs/en/release-notes/api
- claude.ai 시스템 프롬프트(2026-09-01자)에 "Claude Fable 5.1 is the most advanced generally available Claude model", 컷오프 "end of Jun 2026", 도구 호출 다수 시 "두어 번 호출마다 한 문장 업데이트" 지시가 포함되어 있습니다. https://platform.claude.com/docs/en/release-notes/system-prompts/claude-fable-5-1

## 2. 공식 문서 (platform.claude.com)

### 2-1. 모델 비교표·스펙

| 항목 | Fable 5.1 | Opus 5 | Sonnet 5 |
|---|---|---|---|
| API ID | `claude-fable-5-1` | `claude-opus-5` | `claude-sonnet-5` |
| 가격(입력/출력) | $10 / $50 | $5 / $25 | $2 / $10 |
| 사고 | Adaptive(상시) | Adaptive | Adaptive |
| 기본 effort | high | high | high |
| 컨텍스트 / 최대 출력 | 1M / 128K | 1M / 128K | 1M / 128K |
| 지식 컷오프 | 2026-06 | 2026-05 | 2026-01 |
| 은퇴 하한 | 2027-09-01 | 2027-07-24 | 2027-06-30 |
| 상대 지연 | Slower | Moderate | Fast |

- 출처: https://platform.claude.com/docs/en/models/overview
- 권장 선택 기준: "대부분 워크로드는 Opus 5로 시작, Fable 5.1은 고난도 추론·장기 에이전트 작업이거나 Opus 5 고effort 평가가 부족할 때". https://platform.claude.com/docs/en/models/overview
- 플랫폼별 ID: Bedrock `anthropic.claude-fable-5-1`, Google Cloud·Foundry·Claude Platform on AWS `claude-fable-5-1`. Fable 5는 레거시 목록으로 이동. https://platform.claude.com/docs/en/models/fable-5-1/overview
- 300K 출력 배치 베타 헤더(`output-300k-2026-03-24`) 지원 모델 목록에 Fable 5.1은 없습니다. https://platform.claude.com/docs/en/models/overview
- 토크나이저는 Fable 5와 동일(Opus 4.7에서 도입, 구세대 대비 약 30% 토큰 증가). https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- Priority Tier 미지원(Fable 5는 지원). 30일 데이터 보존 필수, ZDR 불가(명시 승인 예외), Covered Model. https://platform.claude.com/docs/en/models/fable-5-1/migration-guide

### 2-2. 가격

| 항목 | Fable 5.1 / Mythos 5.1 | Fable 5 | Opus 5 |
|---|---|---|---|
| 기본 입력 | $10 | $10 | $5 |
| 5분 캐시 쓰기 | $12.50 | $12.50 | $6.25 |
| 1시간 캐시 쓰기 | $20 | $20 | $10 |
| 캐시 읽기 | $0.25 (0.025배) | $1 | $0.50 |
| 출력 | $50 | $50 | $25 |
| 배치(입력/출력) | $5 / $25 | $5 / $25 | $2.50 / $12.50 |

- 출처: https://platform.claude.com/docs/en/about-claude/pricing
- 미국 전용 추론(`inference_geo: "us"`)은 전 항목 1.1배. 1M 전 구간 표준 단가(장문 할증 없음). Fast mode는 Opus 5/4.8 전용이라 Fable 5.1 미지원. https://platform.claude.com/docs/en/about-claude/pricing
- Sonnet 5 도입가 $2/$10은 9/1 인상 없이 표준가로 확정. https://platform.claude.com/docs/en/about-claude/pricing

### 2-3. 마이그레이션 가이드 (Fable 5 → 5.1)

- 파괴적 변경 1: `tool_choice` `any`/`tool`은 400 `invalid_request_error`("tool_choice: type "tool" and "any" are not supported for this model"). Messages·Batches·토큰 카운트 엔드포인트 모두 적용. 대안은 `auto` + 프롬프트에 도구 명시 + `strict: true`, 또는 JSON outputs(`output_config.format`). CMEK 조직은 structured outputs 불가라 지시문만 사용. 특정 턴에 도구 호출이 필수면 최신 user 턴 뒤에 mid-conversation system 메시지로 요구. https://platform.claude.com/docs/en/models/fable-5-1/migration-guide
- 파괴적 변경 2: 사고 블록은 생성 모델 또는 그 이후 모델만 읽음. 5.1은 Opus 5·Fable 5·Mythos 5·이전 모델 블록을 읽지만 역방향 불가. 못 읽는 블록은 API가 드롭(과금 없음), `thinking-binding-controls-2026-08-01` 헤더 시 `input_transformations`에 보고. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- 파괴적 변경 3: 사고 블록 앞의 system/tools/이전 메시지를 바꾸면 다음 요청이 400("The block is bound to a different conversation") 또는 옵트인 시 드롭. 2026-08-31 이후 생성 계정은 기본 강제, 이전 계정은 `thinking.block_binding.prefix_mismatch_behavior` 설정 시에만 동작. Mythos 5.1은 이 검사를 하지 않음. 허용되는 조작: 선두 사고 블록 연속 제거, 서버측 compaction/context editing, cache_control 이동, effort 변경. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- 변경 없음: adaptive 상시(`enabled`/`disabled` 모두 400), `thinking.display` 기본 `omitted`, 프리필 400, temperature/top_p/top_k 비기본값 400, 캐시 최소 512토큰, mid-conversation system 메시지·도구 변경 지원. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- 폴백: `fallbacks: "default"`(베타) 허용 대상은 Opus 4.8과 Opus 5. 출력 전 거부는 미과금, 폴백 크레딧이 캐시 전환 비용 환불. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- 체크리스트 요점: 모델명 변경, 강제 tool_choice 제거, 사고 블록 무수정 반환(빈 블록 포함), `drop_block`으로 세션 돌려 `prefix_binding_mismatch` 전수 수정, system/tools 세션 시작 시 동결, 턴별 리마인더는 턴 한정 시스템 메시지로, 에이전트 루프의 1턴 1호출 점검, `display: "updates"` 설정, effort 변경은 메시지별 effort로, refusal 처리, effort 재측정(`high` 시작). https://platform.claude.com/docs/en/models/fable-5-1/migration-guide
- Claude Code에서 `/claude-api migrate this project to claude-fable-5-1`로 자동 마이그레이션 가능. https://platform.claude.com/docs/en/models/fable-5-1/migration-guide

### 2-4. 마이그레이션 가이드 (Opus 5 → Fable 5.1)

- `thinking: {type: "disabled"}`가 Opus 5에서는 high 이하에서 허용되지만 5.1은 어떤 effort에서도 400. 필드 제거 후 낮은 effort로 토큰 제어, `max_tokens` 재검토. https://platform.claude.com/docs/en/models/fable-5-1/migration-guide
- Opus 5에서 도구 호출 사이 텍스트는 `text` 블록이었으나 5.1은 진행 업데이트 `thinking` 블록으로 옴(기본 omitted면 빈 블록). https://platform.claude.com/docs/en/models/fable-5-1/migration-guide
- 안전 분류기 범주가 Opus 5의 `cyber` 단일에서 `bio`, `reasoning_extraction` 등으로 넓어짐. https://platform.claude.com/docs/en/models/fable-5-1/migration-guide
- 가격 2배(입력/출력), 캐시 읽기는 Opus 5의 절반($0.50 → $0.25). Opus 5는 ZDR 가능, 5.1은 불가. https://platform.claude.com/docs/en/models/fable-5-1/migration-guide
- Opus 4.8 이하에서 올 때는 Fable 5 마이그레이션 가이드를 먼저 적용한 뒤 5.1 델타 적용. https://platform.claude.com/docs/en/models/fable-5-1/migration-guide

### 2-5. 새 파라미터·베타 기능

- 메시지별 effort(베타): `messages` 안 `role: "system"`에 `output_config: {effort}`만 실어 보내면 다음 user 턴부터 적용, 프롬프트 캐시 유지. Fable 5.1·Mythos 5.1·Opus 5 지원. 헤더 `mid-conversation-output-config-2026-07-01`. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- 턴 한정 시스템 메시지(베타): `role: "system"` + `clear_at: "next_user_message"`. 이후 user 메시지가 생기면 렌더링 중단, 배열에는 남겨 그대로 재전송, 토큰 비용 0, 캐시·사고 블록 유지. 헤더 `mid-conversation-system-clear-at-2026-08-21`. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- `thinking.display: "updates"`(베타): 추론은 숨기고 도구 호출 직전 진행 업데이트만 텍스트로 수신. 헤더 `thinking-display-updates-2026-08-18`. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- 콘텐츠 출처: 모든 플랫폼에서 텍스트에 통계적 워터마크(토큰·숨은 문자 추가 없음), Files API로 받는 이미지·비디오에 C2PA 서명. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- deprecated: 새로 deprecated된 항목은 미발견. 기존대로 확장 사고(`budget_tokens`)는 Opus 4.6/Sonnet 4.6에서 deprecated이고 이후 모델은 미허용. https://platform.claude.com/docs/en/models/overview

### 2-6. 능력 향상 6영역

장시간 에이전트 코딩, 문서·스프레드시트·슬라이드 지식 작업, 다단계 리서치·검색, 비전(PDF 속 차트·표, crop-and-zoom), 1M 장문 컨텍스트, 컴퓨터 사용. 다국어는 Fable 5와 동급. effort가 높을수록 격차가 커짐. https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1

## 3. Claude Code 체인지로그·문서

- 2.1.257 (2026-09-01): "Added Claude Fable 5.1 (`claude-fable-5-1`), now the default Fable model — 1M context, $10/$50 per Mtok with $0.25/Mtok cache reads". 같은 버전에서 `fable`·`best`가 Claude apps 게이트웨이 세션에서는 당분간 Fable 5로 해석(미설정 게이트웨이가 5.1을 거부), `/model`에서 직접 선택. https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md
- 2.1.257 기타 관련: `/effort`에 `s`로 세션 한정 변경, `--effort`가 새 모델의 기본 effort 보류를 세션 한정으로만 해제, `CLAUDE_CODE_SUBAGENT_MODEL_FORCE` 추가. 2.1.258(9/1)은 macOS 12 실행 회귀 수정. 2.1.255·256(8/31)은 버그 수정만. https://code.claude.com/docs/en/changelog
- 모델 설정 문서: `fable` 별칭은 최신 Fable(현재 5.1), `fable[1m]`는 1M 컨텍스트. Fable은 어떤 요금제에서도 기본 모델이 아니므로 명시 선택 필요. Fable 5.1은 Claude Code 2.1.255 이상 필요. 고정 시 `ANTHROPIC_DEFAULT_FABLE_MODEL='claude-fable-5-1'`. 1M 컨텍스트는 Max/Team/Enterprise 포함, Pro는 사용 크레딧, API는 전체. https://code.claude.com/docs/en/model-config
- 모델 설정 문서의 Fable 사용 요령: 단계가 아니라 결과를 설명하고 경로를 스스로 계획하게 두기, 모호한 문제(근본 원인 조사) 맡기기, 검증 리마인더 생략(자체 검증이 더 나음), 평소 쪼개던 큰 작업을 통째로 주기. https://code.claude.com/docs/en/model-config
- 체인지로그 원문 GitHub 버전(2.1.258이 최신)은 코드 문서 체인지로그와 동일 내용이며, 날짜는 코드 문서 쪽에만 표기됩니다.

## 4. Fable 5(7월) 대비 달라진 프롬프팅 권장사항

전제: "기존 Fable 5 프롬프트는 수정 없이 5.1에서 잘 동작한다." 아래는 5.1 전용 가이드가 새로 제시하거나 방향이 바뀐 항목입니다. https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1

1. **effort 재측정 (변경).** Fable 5 가이드는 "high 기본, xhigh는 최고 난도, medium/low는 루틴"이었습니다. 5.1 가이드는 `high`에서 시작하되 전 레벨을 다시 스윕하라고 하며, 이유는 "effort 이름이 모델 간 같은 사고량이 아니기 때문"입니다. 5.1의 `medium`이 Fable 5 성능에 근접하고, `low`는 Opus·Sonnet 대비 작업당 비용 경쟁력이 있다고 밝힙니다. xhigh/max는 긴 산출물을 사고 안에서 먼저 초안 작성해 지연·토큰이 늘 수 있어 측정된 이득이 있을 때만 사용.
2. **진행 업데이트 요청 (신규).** 5.1은 도구 호출 사이 사용자 대상 텍스트를 덜 씁니다(고effort·긴 체인에서 심화). 우선 `display: "updates"`로 수신 여부부터 확인하고, "결과는 최종 응답에 모아라" 같은 억제 지시를 제거한 뒤에도 부족하면 다음 한 줄 추가: "Before you start, say in a line what you're about to do; brief updates while you work help the user follow along. Close with a short recap that stands on its own." UI가 도구 출력을 숨기면 턴 한정 시스템 메시지로 "Only you see that command's output"을 알려줌. Fable 5 가이드의 send_to_user 도구 권장은 5.1 가이드에서 사라지고 `display: "updates"`가 대체합니다.
3. **독립 도구 호출 묶기 (신규).** 코딩·컴퓨터 사용 루프에서 1턴 1호출로 퇴화할 수 있어, 매 도구 결과 뒤에 턴 한정 시스템 메시지로 "First privately list what you need next; then request every item that doesn't depend on another's result in this one response."를 붙이고 이전 복사본은 그대로 둡니다. Fable 5 가이드는 병렬 호출을 "더 잘한다"고만 했습니다.
4. **대화 이력 append-only (신규).** 사고 블록 바인딩 때문에 턴별 리마인더 주입·삭제, 클라이언트측 요약 덮어쓰기, 세션 중 system 변경이 금지 패턴이 됩니다. `drop_block`으로 세션을 돌려 `input_transformations`를 로그해 점검.
5. **산문 밀도 (신규).** 5.1은 문장이 길고 단락이 적을 수 있어 "mannered prose" 정의문을 user 메시지(선호) 또는 system에 추가. 짧은 판 "Please remove all mannered prose."도 효과. Fable 5 가이드는 반대로 화살표 체인·축약 shorthand 억제가 초점이었습니다.
6. **채팅 서식 (방향 반전).** 이전 모델용 반서식 규칙이 5.1에서는 필요한 구조까지 억제합니다. 제거하거나 "언제 서식이 적절한지" 규칙으로 교체.
7. **인용 표시 (신규).** 요약 시 원문을 무표시로 재현하는 경향이 있어 정답 예시 1개(요청·응답·이유)를 system에 추가.
8. **작업 완주 (강화).** Fable 5 가이드의 "드문 조기 종료" 항목이 5.1에서 "Finish the whole task"로 확장되어, 자율 실행 블록("You are operating autonomously...")과 "Delivering work" 범위 블록 2개를 함께 쓰라고 권합니다. 프롬프트 길이 제한 시 첫 블록만.
9. **범위·테스트 제한 (신규).** 인접 코드 수정, 요청 밖 확장, 과다 테스트 파일 커밋을 막는 지시문을 제시하며 "작업 성공률 변화 없이 불필요 추가가 크게 감소"했다고 밝힙니다. 시스템 카드 FrontierCode 분석과 일치합니다.
10. **low effort 검색 유도 (신규).** low에서 검색 대신 기억으로 답하는 경향이 있어 해당 턴만 effort를 올리거나 "이름을 안다고 현재 상태를 아는 것이 아니다" 검증 지시 추가.
11. **안전장치 오탐 회피 (신규).** "컴파일되나?" 대신 "버그가 있나?"로 묻기, 비주류 언어는 문서 제공, 도구 출력의 base64 제거.
12. **파일 전체 재작성 억제 (신규).** "surgically edit a file rather than rewrite the entire thing" 지시 추가.
13. **compaction 요약 보존 항목 명시 (신규).** 클라이언트측 compaction 시 6개 보존 항목을 지정한 요약 지시문 제공.
14. **서브에이전트 비차단 (유지·구체화).** 리드가 대기하지 않도록 즉시 반환하는 spawn 도구와 별도 wait 도구 구성. Fable 5 가이드의 "병렬 서브에이전트" 권장의 연장입니다.
15. **비전 crop/zoom 도구 (강화).** PIL·OpenCV가 있는 컨테이너 또는 최소한 crop 도구 제공.

Fable 5 가이드에만 있고 5.1 가이드에서 빠진 항목: 메모리 시스템 구축, "이유를 함께 제시", 컨텍스트 예산 카운트다운 숨기기, 진행 주장 근거 감사, 경계 명시, send_to_user 도구, "더 어려운 작업부터 시작" 스캐폴딩. 5.1 가이드는 이들을 폐기했다고 명시하지 않았으며, 범용 원칙은 prompting best practices 페이지로 통합되어 있습니다. https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5 , https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices

## 5. 미발견·확인 불가 항목

- `anthropic.com/news/` 경로의 Fable 5.1 전용 뉴스 페이지: 미발견(발표문은 루트 경로 `/claude-fable-and-mythos-5-1`).
- Fable 5.1 전용 신규 deprecated 파라미터: 미발견(기존 제약 승계뿐).
- 시스템 카드 본문 2~9장의 세부 수치(오탐률 표, 정렬 감사 수치 등): 앞 16쪽과 8.1·8.4절만 열람. 나머지는 미열람.
- 발표문의 "9월 2일" 출시 표기: 미발견. 모든 공식 자료가 9월 1일로 기재.
- Claude Code에서 Fable 5.1 전용 effort 기본값 문서(코드 문서): 발표문의 "Claude Code 기본 High" 외 별도 문서 미발견.

## 열람한 출처 목록

- https://www.anthropic.com/claude-fable-and-mythos-5-1
- https://www.anthropic.com/claude/fable
- https://www.anthropic.com/news
- https://www-cdn.anthropic.com/0339e6a7c5c7b87f5c07798616dc32c215d14235/Claude%20Fable%205.1%20&%20Claude%20Mythos%205.1%20System%20Card.pdf
- https://platform.claude.com/docs/en/models/overview
- https://platform.claude.com/docs/en/models/fable-5-1/overview
- https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1
- https://platform.claude.com/docs/en/models/fable-5-1/migration-guide
- https://platform.claude.com/docs/en/about-claude/models/migration-guide
- https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1
- https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5
- https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices
- https://platform.claude.com/docs/en/about-claude/pricing
- https://platform.claude.com/docs/en/release-notes/api
- https://platform.claude.com/docs/en/release-notes/system-prompts/claude-fable-5-1
- https://code.claude.com/docs/en/model-config
- https://code.claude.com/docs/en/changelog
- https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md

---

# Part 2. 커뮤니티 후기 조사 보고서


> 조사 범위: Hacker News(Algolia API + 개별 스레드), Simon Willison 블로그, Every, 개인 블로그, 벤더 블로그(Artificial Analysis·CodeRabbit·Snorkel), Claude Code GitHub 이슈, X 인용.
> 출처 성격 표기: **[1차]** 직접 사용 후기 / **[벤더]** 벤치마크·도구 업체 글 / **[2차]** 공식 문서 요약·언론 인용 / **[공식]** Anthropic 직원 발언.
> Reddit(r/ClaudeAI, r/ClaudeCode, r/LocalLLaMA)은 WebFetch 차단 + 검색 엔진 색인 없음으로 **미발견**. X 원문은 402로 열람 실패, 검색 스니펫만 확보.

## 핵심 요약

1. **HN 본 스레드(1,149점·1,065댓글)의 지배적 화제는 "Claudish" 문체**입니다. 코드 주석·커밋 메시지·보고문이 길고 난해하다는 1차 불만이 2단계 스레드 50건 이상을 차지합니다.
2. **토큰 소모 증가는 실측으로 확인**됐습니다. Artificial Analysis 기준 출력 토큰 1.7배(83M→140M), max effort 태스크당 비용 20% 증가. HN 사용자 eis는 "56% 더 비싸다"고 지적했습니다.
3. **구독 한도 소진 가속 보고**가 복수입니다. Max 20x·Team Premium에서 첫 작업도 못 끝내고 5시간 한도 도달(HN), Claude Code 2.1.257 자동 전환 후 분당 비용 3.88배(GitHub #91336).
4. **effort 권장은 "high가 기본이되 low/medium을 시험하라"**로 수렴합니다. Lance Martin은 low가 Fable 5 high와 CursorBench 동급·비용 1/3, Every 팀은 high 선호·xhigh는 자율성 과잉(서브에이전트 남발·중단 무시)이라 보고했습니다.
5. **프롬프팅 변화**: 검증 의식·강조 대문자·낡은 few-shot·모순 규칙을 **제거**하라는 조언(Lance Martin, 공식 가이드와 동일 방향). Claude Code 내 `/claude-api prompt-audit`로 안티패턴 점검.
6. **Claude Code 특이 동작**: 소규모 수정에 파일 전체 재작성 경향(공식 changelog 명시, 워크어라운드 문구 존재), 스킬 무시 후 memory로 우회(GitHub #91391, 1인 보고), 구버전 바이너리에서 1M 컨텍스트가 200K로 오인식(#91331).
7. **Opus 5 대비**: 토큰 절반 이하로 유사 결과(Every), 그러나 빌드/의존성 작업은 Opus 5가 우세(Snorkel 18% vs 67%). 하드 제약 준수는 Opus 5가 낫다는 평.
8. **벤치마크 재현**: 독립 재현은 Artificial Analysis(지수 66, 1위)와 CodeRabbit(코드리뷰 recall 동률·정밀도 +4.5p·지연 48.7% 증가)뿐. 환각률 증가(오답 시도율 63.6%→72.6%) 캐비앗 있음.
9. **API 파괴적 변경 3건**(강제 tool_choice 400, thinking 블록 이식 불가, 히스토리 편집 시 400)은 2차 요약만 있고 1차 피해 후기는 미발견.
10. 출시 익일이라 **CLAUDE.md 작성 요령의 5.1 전용 1차 후기는 미발견**. 확보된 팁은 대부분 Fable 5 시절 것이거나 공식 가이드 재서술입니다.

## 주제별 사실·주장

### 1. Claude Code 체감 변화

- 이전 Fable 5·GPT-5.6 Sol 세션이 "반복할수록 다른 버그만 나오던" 작업 2건을 5.1이 아침에 해결. 답글은 구세션의 큰 컨텍스트가 원인이었을 가능성 제기. — https://news.ycombinator.com/item?id=49527054 [1차, mceachen]
- 코드 주석이 과도하게 김: "변수 위에 특정 날짜 디버그 세션 얘기를 25줄 적는다"(freedomben), "메서드마다 장문 주석, 하지 말라 해도 붙인다"(whateveracct), 동료가 "역대 가장 긴 커밋 메시지"를 쓴다(camoby). — https://news.ycombinator.com/item?id=49525378 [1차]
- "과도한 주석·이상한 커밋 설명·중복 코드·슬롭이 너무 많다"(george_max). — https://news.ycombinator.com/item?id=49525378 [1차]
- 주석 밀도 기준으로 편집을 거부하는 post-edit 훅을 쓴다는 대응(avereveard). — 같은 스레드 [1차, 워크어라운드]
- UI 카피 개선을 시키자 모든 문자열을 "더 이상한 LLM 말투"로 바꿔 제안(alin23). — https://hn.algolia.com/api/v1/items/49527730 [1차]
- Anthropic 직원 felixrieseberg: "문체가 크게 개선돼 다른 Claude 모델처럼 들리지 않는다". 최상단 댓글이지만 반박 답글 다수. — https://news.ycombinator.com/item?id=49525378 [공식]
- Every 팀: Fable 5 대비 "더 깊이 들어가고 무엇이 통하는지 판단이 낫다"(Kieran, 문서 편집기 재구축). 1,000단어 요청에 1,288단어, 인용 8~12개 요청에 43개(5개 미검증) 등 제약 초과 반복. — https://every.to/vibe-check/fable-5-1-vibe-check [1차, 5인 팀 테스트]
- Dan Shipper: "성능과 사용성이 동시에 뛰는 드문 경우", 요청당 766토큰 vs Opus 5 2,000, 지연 22초 vs 37초. Opus 5의 "어두운" 문체가 5.1에서 고쳐짐. — https://finance.biggo.com/news/662e14c57d5bfe10 [2차, Every 기사 인용]

### 2. 프롬프팅·CLAUDE.md 요령

- Lance Martin(X): "검증 의식·강조 부스터·스크래치패드 스캐폴드·낡은 few-shot·모순 규칙을 제거해 프롬프트를 단순화하라. Claude Code에서 `/claude-api prompt-audit`로 안티패턴 점검." — https://x.com/RLanceMartin/status/2094854835854295296 [1차/준공식, 원문 402로 검색 스니펫만 확인]
- 공식 프롬프팅 가이드 항목: effort, 진행 보고, 툴 호출 배치, 문체, 압축 요약, 범위·테스트 커버리지, 검색 트리거, 안전장치 오탐, 파일 편집, 장문 출력, 서브에이전트, 비전. — https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1 [공식, 검색 결과로 목차만 확인]
- 파일 전체 재작성 억제 문구(공식 changelog 인용): "결과에 영향이 없다면 파일 전체를 다시 쓰지 말고 외과적으로 수정하라". — https://hn.algolia.com/api/v1/items/49528033 [1차 인용, elpakal]
- 문체 억제 문구: "최상급 금지, 설득체 금지"로 대부분 해결(GrinningFool); "smoking gun 쓰지 마"라 해도 쓰고 사과함(gambiting); "쉬운 말로"는 효과 있으나 매번 반복 필요(anyg); 설명용 스킬을 Fable에 쓰게 해 Opus 보고문이 명확해짐(tkgally). — https://news.ycombinator.com/item?id=49525378 [1차, 단 5.1 한정인지 불명확한 것 포함]
- 5.1 전용 CLAUDE.md 후기: **미발견**. 검색에 걸린 가이드(kenhuangus, findskill, knightli 등)는 Fable 5 시점 글.

### 3. effort 레벨 권장

- Claude Code 기본값 high, Cowork·claude.ai는 medium. 5단계(low/medium/high/xhigh/max), 사고 끄기 불가. — https://simonwillison.net/2026/Sep/1/claude-fable-5-1/ [1차]
- Simon Willison 펠리컨 실측: low 1,998토큰·10센트·24초, high 2,612토큰·13센트·30초, xhigh 36,767토큰·$1.83·7분51초, max 65,927토큰·$3.30·13분54초. low/medium은 사고 흔적 없음, "진짜 날개는 xhigh부터". — 같은 글 + https://news.ycombinator.com/item?id=49530472 [1차]
- Lance Martin: "low가 $/태스크에서 Opus·Sonnet과 경쟁하며 점수는 더 높음. CursorBench 3.2.0에서 low가 Fable 5 high와 동급, 비용 1/3." — https://x.com/RLanceMartin/status/2094854835854295296 [1차/준공식, 스니펫]
- HN simdezimon: "high가 Fable 5 max와 같은 점수를 절반 비용으로". agentdev001: "high/xhigh/max 모두 $/지능 파레토 위". — https://hn.algolia.com/api/v1/items/49528026 [2차, AA 데이터 해석]
- Every: high 선호, medium/low는 코딩엔 충분하나 글쓰기 품질 하락, xhigh는 자율성 과잉. — https://every.to/vibe-check/fable-5-1-vibe-check [1차]
- Lisa Peyton(마케팅 글쓰기): 5.1 medium이 리듬·문장 패턴 위반 최소로 승, high는 조사형 글에 적합. "모델 고르듯 effort를 고르라". — https://lisapeyton.com/claude-fable-5-1-vs-fable-5-marketing-writing-test/ [1차]
- CodeRabbit: 코드리뷰에서 high가 low보다 3분 더 걸리고 추가 이슈 발견 없음. — https://www.coderabbit.ai/blog/fable-5-1-model-review [벤더]
- claudefa.st: "high로 시작해 낮은 단계를 벤치마크하라", 대화 중 effort 전환 가능. — https://claudefa.st/blog/models/claude-fable-5-1 [2차, 공식 문서 요약]

### 4. 자율성 과잉·오버씽킹·토큰 소모와 워크어라운드

- Artificial Analysis: 출력 토큰 1.7배, max effort 태스크당 $3.76(Fable 5 $3.14, Opus 5 $2.34). 5단계 간 토큰 11배 차. 캐시 인하로 태스크당 약 $1.40 절감. — https://artificialanalysis.ai/articles/claude-fable-5-1 [벤더]
- HN eis: "AA 기준 5.1이 56% 더 비쌈($8,523 vs $5,455), 출력 140M vs 83M. Anthropic 발표와 정면 배치." — https://hn.algolia.com/api/v1/items/49528026 [1차 의견, 2차 데이터]
- 구독 한도: Team Premium·Max 20x 모두 첫 작업 완료 전 5시간 한도 도달, 개인 계정은 1시간 미만(InsideOutSanta). 5x도 동일(jesse_dot_id). — https://hn.algolia.com/api/v1/items/49526734 [1차]
- GitHub #91336: Claude Code 2.1.257이 `fable` 별칭을 5.1로 바꾼 뒤 멀티에이전트 워크플로에서 분당 비용 $2.31→$8.97(3.88배), 요청/분 1.8배, 워커당 캐시 쓰기 2.5배. 45분 만에 계정 3개 소진. — https://github.com/anthropics/claude-code/issues/91336 [1차]
- GitHub #91331: 2.1.252에서 5.1이 200K 컨텍스트로 오인식돼 조기 압축(다른 모델 0회 vs 5.1 10회). 원인은 바이너리에 모델 문자열 부재 → 200000 기본값 폴백. 닫힘. — https://github.com/anthropics/claude-code/issues/91331 [1차]
- GitHub #91345: 안정판 2.1.236은 `claude_code_version_too_old` 400 반환, 2.1.251+ 필요. — https://github.com/anthropics/claude-code/issues/91345 [1차]
- GitHub #91391: "Fable 5+가 정의된 스킬을 무시하고 memory를 새로 써서 '교정'함. 워크트리 5개×10회 100% 실패, 주간 20M 토큰 손실." 재현 절차 없음, 유지보수자 답 없음. — https://github.com/anthropics/claude-code/issues/91391 [1차, 단독 보고]
- Every: xhigh에서 "나를 무시하고 서브에이전트를 수십 개 계속 띄웠다"(Kieran). — https://every.to/vibe-check/fable-5-1-vibe-check [1차]
- 파일 전체 재작성 경향은 공식 changelog가 인정. Juvination은 "서드파티 하네스 사용자 비용 노출 의도?"라 추측. — https://hn.algolia.com/api/v1/items/49528033 [1차 인용 + 추측]
- 자율성 과잉 자체는 Fable 5 시점부터 지적(Simon Willison "relentlessly proactive", 6월 13일, $12.11 세션). 5.1에서 완화됐다는 1차 보고 **미발견**. — https://simonw.substack.com/p/claude-fable-is-relentlessly-proactive [1차, Fable 5]
- 안전장치 불만: "페라리를 주고 특정 작업은 거부하니 머스탱을 타게 만든다"(ed-is-ai). — https://hn.algolia.com/api/v1/items/49528986 [1차 의견]
- thinking 블록 재사용 제한 강화 문서가 HN에 올라왔으나 댓글 0. — https://hn.algolia.com/api/v1/items/49530535 [2차]

### 5. Fable 5·Opus 5 대비 비교

- Every: Opus 5 대비 토큰 절반 미만으로 유사 결과, 그러나 하드 제약 준수·복잡 멀티툴은 Opus 5 우세. Fable 5 대비 "25% 절감, 자율 작업은 45%까지". — https://every.to/vibe-check/fable-5-1-vibe-check [1차]
- Snorkel Terminal-Bench+: 5.1 pass@1 61.5%, Opus 5가 6.2p 앞섬. 성공 시 출력 토큰 58% 적고 36% 빠름. 빌드/의존성 18% vs 67%로 열세, 디버깅 87%·게임 88% 강세. — https://snorkel.ai/blog/fable-5-1-vs-opus-5-coding-benchmark/ [벤더]
- CodeRabbit: 5.1 recall 61.0%(Fable 5 대비 -0.9p), 정밀도 37.3%(+4.5p), 잔소리 댓글 -70.2%, 지연 +48.7%. Opus 5와 recall 61.0 vs 55.2. — https://www.coderabbit.ai/blog/fable-5-1-model-review [벤더]
- 3D 항공기 그리기: 5.1 high $0.26로 Fable 5보다 우수(leumon). — https://hn.algolia.com/api/v1/items/49528734 [1차]
- 펠리컨: max가 "Anthropic 모델 중 최고", 단 Gemini 3.7 Flash만큼 화려하진 않음. 로컬 GLM 5.3이 더 낫다는 댓글도 있음. — https://simonwillison.net/2026/Sep/1/claude-fable-5-1/ , https://news.ycombinator.com/item?id=49530472 [1차]
- HN 일부는 Opus 5 자체를 "4.8 대비 퇴보"로 보고 GPT-5.6 Sol xhigh/max를 권함(creato, mrcwinn). 5.1 직접 비교는 아님. — https://news.ycombinator.com/item?id=49525378 [1차 의견]

### 6. 벤치마크 재현 후기

- Artificial Analysis 지능 지수 66(Opus 5 63, Fable 5 62, GPT-5.6 Sol 61). 정확도 67.2%이나 오답 시도율 72.6%(Fable 5 63.6%)로 환각 증가, omniscience 종합은 동률. — https://artificialanalysis.ai/articles/claude-fable-5-1 [벤더]
- ARC-AGI 결과 페이지가 HN에 올라옴(5점·3댓글), 내용 미열람. — https://arcprize.org/results/anthropic-claude-fable-5-1 [벤더, 미열람]
- vals.ai "Cyphral Distich 해결"(7점·0댓글), 미열람. — https://www.vals.ai/blogs/fable-solves-cyphral-distich [벤더, 미열람]
- 개인 재현(공개 벤치 직접 돌린 1차 글): **미발견**.

### 7. 출시 전 조기 배포 정황 (참고)

- daily.dev: 공지 전 일부 claude.ai 사용자에 5.1 라우팅, Claude Code 릴리스에 모델 문자열 등장, 문서에 사고블록 증류 방지 조항 선반영. X 반응 인용("보이지 않는 손을 의식하듯 조심스럽다"). — https://daily.dev/posts/claude-fable-5-1-is-already-live-for-some-users-before-anthropic-said-a-word-ylqmkv8yy [2차]
- Medium "Did Anthropic Secretly Ship Fable 5.1?"는 403으로 미열람.

## 미발견 항목

- Reddit(r/ClaudeAI, r/ClaudeCode, r/LocalLLaMA) 5.1 스레드: 접근 차단 + 검색 색인 없음
- 5.1 전용 CLAUDE.md 작성 후기
- 자율성 과잉이 5.1에서 완화·악화됐다는 Fable 5 대비 직접 비교 1차 후기
- API 파괴적 변경 3건의 1차 피해 사례
- 한국어 커뮤니티 5.1 후기(검색 결과는 전부 Fable 5 시점)
