---
name: writing-prompts
description: GPT/Claude/Gemma/Qwen 프롬프트 파일 생성 및 개선. OpenAI + Anthropic + Google + Alibaba 공식 가이드 기반. API 연동 코드는 범위 밖입니다.
when_to_use: "프롬프트 작성해줘, 톤 가이드 적용해줘, 시스템 프롬프트 만들어줘, AI 응답 품질 개선해줘 요청 시. LLM 프롬프트 작성, 챗봇 성격 설정, AI 응답 품질 개선이 필요한 모든 상황에서 사용."
---

# 프롬프트 작성 가이드 (OpenAI + Anthropic + 오픈웨이트 통합)

OpenAI GPT, Anthropic Claude, Google Gemma 4, Alibaba Qwen 3.8 공식 가이드 기반. **범용 원칙 우선, 모델별 최적화는 보조**. 한국어 프로젝트 특화 규칙(격식체) 포함.

---

## Quick Start (5분 온보딩)

### 처음이라면?

1. **기본 템플릿** 복사 → [templates.md](references/templates.md)
2. **Few-shot 예시** 추가 → [few-shot.md](references/few-shot.md)
3. 필요 시 플랫폼 특화 기능 적용

---

## TL;DR

### 클로즈드 API (OpenAI / Anthropic)

| 항목 | 공통 | OpenAI (GPT) | Anthropic (Claude) |
|------|------|--------------|-------------------|
| **구조** | Identity → Instructions → Examples → Context | ✅ | ✅ |
| **어조** | 제품 용도별 분기 (공식=격식체, 캐주얼=해요체) | ✅ | ✅ |
| **Message Roles** | - | `developer` (최고) / `user` | `system` 파라미터 / `user` |
| **Examples** | Frontier 0~2개(포맷 정렬), 소형 3-5개 | Few-shot | Multishot (동일 개념) |
| **XML 태그** | ✅ 권장 | ✅ | ✅ |
| **특화 파라미터** | - | `reasoning.effort` (GPT-6: `none` 미지원, low~max), `reasoning.mode`/`context` (5.6+), `verbosity`, `image_detail` | `output_config.effort` |
| **Prefilling** | - | ❌ | ❌ (400 → Structured Outputs) |
| **Long Context** | - | - | ✅ (문서 맨 위 → 30%↑) |
| **제약** | "~하지 마세요" 명시 | ✅ | ✅ |
| **모순 제거** | 충돌 지시 금지 | ✅ | ✅ |

### 오픈웨이트 (Google Gemma / Alibaba Qwen)

| 항목 | Google Gemma 4 | Alibaba Qwen 3.8 |
|------|---------------|------------------|
| **Chat template** | `<\|turn>...<turn\|>` (Gemma 3에서 완전 교체) | ChatML `<\|im_start\|>...<\|im_end\|>` (Qwen 3.6 동일) |
| **System role** | **신규 지원** (Gemma 3 워크어라운드 제거 필수) | 지원 (디폴트 없음, 단 thinking ON이면 template이 추론 지시문을 앞에 주입) |
| **Thinking** | `<\|think\|>` 토큰 + multi-turn strip 룰. OFF여도 E2B/E4B 제외 전부 빈 블록 emit. tool call 턴 유지는 `preserve_thinking=True`(기본 false) | 디폴트 ON, `reasoning_effort` = `xhigh`(기본)/`medium`/`low`, `preserve_thinking` 기본 ON. 2.4T-A95B는 끌 수 없음 |
| **Tool calling** | `<\|"\|>` delimiter 공식 포맷, 병렬은 `tool_responses` 배열, 히스토리 `arguments`는 JSON 객체 | XML 스타일 `<function=…><parameter=…>`, `qwen3_coder` 파서, Qwen-Agent 권장 |
| **Sampling 권장** | `temp=1.0, top_p=0.95, top_k=64` (모든 사용처) | 단일 프리셋: thinking `temp=1.0, top_p=0.95, top_k=20, presence=0.0` / instruct `0.7, 0.8, 20, 1.5` |
| **Context** | 256K (12B·26B·31B) / 128K (E2B·E4B) | 262K native + YaRN 1M (오픈웨이트), API는 1M. 출력 예산 reasoning 262K / 최종 131K |
| **Multimodal** | 5종 모두 vision, audio는 E2B/E4B/12B. image는 text 앞, audio는 text 뒤 | 27B·Flash-Next vision. 2.4T-A95B는 텍스트 전용 |
| **vLLM 필수 플래그** | `--reasoning-parser gemma4 --tool-call-parser gemma4` (MTP는 `--speculative-config`) | `--reasoning-parser qwen3 --tool-call-parser qwen3_coder` (Flash-Next 레시피는 `qwen3_xml`) |
| **라이선스** | Apache 2.0 (Gemma 3 Terms 제약 해소, 드래프터·QAT 포함) | 27B만 Apache 2.0. 2.4T-A95B 커스텀, Flash-Next Qwen Community 1.0 |

## 빠른 참조

### 1. 어조 규칙 (한국어 특화)

제품 용도에 맞는 어조를 고릅니다. 격식체(~습니다)는 B2B·공공·공지 등 공식 응대의 기본값이고, 캐주얼 서비스는 친근한 존댓말(~요, ~해요)이 적합합니다. 용도별 톤 스펙트럼은 [templates.md](references/templates.md) 7장을 따르세요. 아래는 격식체 예시입니다.

```yaml
# Instructions
<style>
- 반드시 격식체(~습니다, ~입니다, ~하세요)를 사용하세요
- 친절하고 전문적인 어조를 유지하세요
</style>

<constraints>
- 반말 또는 비격식체 사용 금지
- 비꼬는 표현이나 냉소적인 어조 사용 금지
</constraints>
```

**예시**:
```
❌ "이건 좋은 아이디어야"
✅ "이것은 좋은 아이디어입니다"
```

### 2. XML 태그

| 태그 | 용도 |
|------|------|
| `<rules>` | 행동 규칙 |
| `<style>` | 대화 스타일 |
| `<output_format>` | 출력 형식 |
| `<constraints>` | 제약/금지 사항 |
| `<examples>` | 예시 |

### 3. 플랫폼별 특화 기능

| 플랫폼 | 핵심 기능 | 상세 가이드 |
|--------|----------|------------|
| OpenAI | Outcome-first, 구조화 출력, Personality 분리, 주도성·테스트 범위·위임 명시(GPT-6), 티어 선택(5.6) | `references/gpt6-patterns.md` ⭐ (GPT-6 Astra), `references/gpt56-patterns.md` (5.6) |
| Anthropic | De-prescribe(Claude 5 세대), 검증 지시 삭제·위임 상한(Opus 5), 긴 컨텍스트 최적화 | `references/claude-5-specifics.md` ⭐ (Fable 5.1·Opus 5), `references/long-context.md` |
| Google Gemma 4 | `<\|turn>` 템플릿, `<\|think\|>` 토글, multi-turn thought strip, `<\|"\|>` delimiter | `references/gemma4-patterns.md` |
| Alibaba Qwen 3.8 | ChatML, `reasoning_effort` 3단계 + `preserve_thinking` 기본 ON, XML tool 포맷·`qwen3_coder` 파서, 단일 sampling | `references/qwen38-patterns.md` |

## 기본 템플릿

```yaml
system_prompt: |
  # Identity
  당신은 [역할명]입니다.
  [목적 1-2문장]

  # Instructions
  <rules>
  - 반드시 격식체(~습니다, ~입니다)를 사용하세요
  - [규칙 1]
  - [규칙 2]
  </rules>

  <style>
  - 친절하고 전문적인 어조를 유지하세요
  </style>

  <output_format>
  [출력 형식 설명]
  </output_format>

  <constraints>
  - 반말 사용 금지
  - [제약 1]
  </constraints>

  # Examples
  <examples>
  <example id="1">
  <input>[입력]</input>
  <output>[출력]</output>
  </example>
  </examples>

  # Context
  [필요 시 외부 데이터]
```

## 체크리스트

프롬프트 작성/수정 시 확인:

### 필수 (범용)
- [ ] 구조: Identity → Instructions → Examples → Context
- [ ] 격식체 명시 (한국어 톤 가이드 참조)
- [ ] XML 태그 사용
- [ ] Few-shot 예시: Frontier 모델은 포맷 정렬용 0~2개, 소형 모델은 3-5개 → [few-shot.md](references/few-shot.md)
- [ ] 제약 명시 ("~하지 마세요")
- [ ] 모순 제거

### 보안 (민감한 작업)
- [ ] 사용자 입력 분리 (XML 태그로 경계)
- [ ] 출력 검증 로직 고려
- [ ] 시크릿 하드코딩 확인 → [security.md](references/security.md)

### 품질 향상 (복잡한 작업)
- [ ] Self-correction 체인 고려 → [self-correction.md](references/self-correction.md)
- [ ] 추론 깊이 적절히 설정 → [reasoning-params.md](references/reasoning-params.md)

### 플랫폼별 최적화 (선택)

**OpenAI GPT-6 Astra** (최신, 권장):
- [ ] **주도성 명시**: 질문하고 멈추는 성향이 이전 세대보다 강함 → 자율 실행이 필요하면 "bias towards action, carry the task to completion" 계열 지시 추가. "can you…/help me…"는 실행 요청으로 취급하게
- [ ] **지시 파일 모순 감사**: 긴 지시는 잘 따르지만 문맥 모순에 민감 → AGENTS.md·스킬·시스템 프롬프트 사이의 상충·낡은 문구 제거가 감량보다 우선. 사용자 지시 > 스킬 지시 우선순위 명시
- [ ] **테스트 범위 축소**: 스스로 철저히 검증하는 성향 → "가역적·저영향 변경에 구현을 비추는 테스트 금지, 확대는 새 변경·실패가 정당화할 때만"으로 범위를 좁히는 지시(검증 강화 지시 아님)
- [ ] **위임 명시**: 서브에이전트 병렬 위임을 학습했지만 기대보다 덜 위임 → 갈래·리더 보유 범위·대기 여부·반환 요약 형식을 프롬프트에 지정
- [ ] **문체**: 문단 기본, 리스트는 병렬·순서·비교일 때만. 피할 표현("Bottom Line:", "delve", "leverage", "it's worth noting", "In short:") 차단
- [ ] `reasoning.effort`: `low`~`max` 5단계, 기본 `medium`. `none`/`minimal` 사용처는 `low`부터. `ultra`는 Codex·ChatGPT 전용(API 값 아님)
- [ ] **API 변경**: `temperature`·`top_p`·`top_logprobs` 제거, 도구 호출은 Responses API 전용, `prompt_cache_retention` → `prompt_cache_options.ttl`. 입력 272K 초과 시 요청 전체 2배 요율
- [ ] 5.6 계약 구조(Goal/Success criteria/Constraints/Tools/Output/Stop rules)·pro mode·`reasoning.context`·PTC는 그대로 유효 → 아래 5.6 항목 참조

**OpenAI GPT-5.6** (이전 세대):
- [ ] **티어 선택**: `gpt-5.6-sol`(플래그십)/`terra`(균형)/`luna`(고속저가) — 비용 레버리지는 effort보다 티어 라우팅
- [ ] **Outcome-first**: 절차가 아닌 목표·성공 기준·제약·중단 조건으로 정의 (5.5 계승)
- [ ] **Personality + Collaboration Style 분리** (각 1-2문단 이내)
- [ ] `reasoning.effort`: 신규는 `medium` 출발점 / 5.5·5.4에서 마이그레이션은 **기존 값 baseline + 한 단계 낮춰 비교**
- [ ] `text.verbosity`: 기본 상세도만 설정 — 근거 서술이 중요한 작업(리뷰·감사·마이그레이션)은 `low`/`medium`을 대표 사례로 비교
- [ ] **막연한 간결 지시("Be concise"류) 효용 재평가** → 우선순위 지시로 대체 ("결론 먼저, 근거, 중대 caveat, 다음 액션") — 5.6은 기본 출력이 더 간결해 과작동(지나치게 짧아짐) 위험
- [ ] **Markdown 절제** (plain prose 기본 — 5.6은 기본 출력이 더 간결)
- [ ] **Retrieval Budget** 명시 (도구 사용 시 stopping conditions)
- [ ] **Structured Outputs API**로 스키마 강제 (프롬프트 대신)
- [ ] **Tool Validation**: 출력 검증을 도구로 (테스트·린트·렌더링) — 5.6은 overstep 경향이 5.5보다 커 검증 루프 중요도 상승
- [ ] 마이그레이션: 5.5→5.6은 **모델만 교체 → 기존 프롬프트·effort 기준선 평가 → 한 그룹씩 프롬프트 축소 → 측정된 회귀에만 최소 수정**
- [ ] Message Roles (developer/user)

**Anthropic Claude Fable 5.1 / Claude 5 세대** (최신, 권장):
- [ ] **De-prescribe**: 절차 열거 대신 목표·제약·이유 서술 (과잉 지시는 품질 저하)
- [ ] **Prefill 금지**: 400 에러 → Structured Outputs(`output_config.format`)로 대체
- [ ] **"사고 과정 서술" 지시 제거**: `reasoning_extraction` refusal 유발
- [ ] **강제 `tool_choice` 금지** (5.1): `any`/`tool`은 400 → `auto` + 지시문 + `strict: true`
- [ ] **대화 이력 append-only** (5.1): 턴별 리마인더는 턴 한정 시스템 메시지로, 이력·system·tools 사후 편집 금지
- [ ] `output_config.effort`: `high` 시작 + 전 레벨 재측정 (레벨 이름이 모델 간 같은 사고량이 아님)
- [ ] **산문 밀도 지시** (5.1): 문장이 길고 단락이 적으면 "mannered prose" 정의문 추가
- [ ] **범위·테스트 제한** (5.1): 요청 밖 수정·과다 테스트 커밋을 막는 지시문 추가
- [ ] **반서식 규칙 제거** (5.1): 구모델용 "불릿·헤더 쓰지 마라"가 필요한 구조까지 억제 → 언제 서식이 적절한지로 교체
- [ ] 장기 자율 런: 진행 보고 근거화 + 메모리 파일 → [claude-5-specifics.md](references/claude-5-specifics.md)
- [ ] Long context 문서 배치 (맨 위)

**Google Gemma 4** (오픈웨이트):
- [ ] **Chat template 교체**: `<start_of_turn>` → `<|turn>`, `<end_of_turn>` → `<turn|>` (Gemma 3에서 완전 교체)
- [ ] **System role 사용**: Gemma 3의 "user 턴에 system 우겨넣기" 워크어라운드 제거
- [ ] **Thinking 활성화**: 시스템 프롬프트 맨 앞에 `<|think|>` 토큰 추가
- [ ] **Multi-turn thought strip**: 직전 model 턴의 `<|channel>thought` 블록 제거 (함수 호출 중에는 유지 — template은 `preserve_thinking=True`). OFF여도 빈 블록 strip (E2B/E4B 제외)
- [ ] **Multimodal placement**: image는 text 앞, audio는 text 뒤
- [ ] **Visual token budget**: 70/140/280/560/1120 작업별 명시 (분류 70-140, OCR 1120)
- [ ] **Tool calling**: `<|"|>` delimiter 포맷 사용, 히스토리 `arguments`는 JSON 객체(문자열이면 template 예외)
- [ ] **공식 sampling**: `temperature=1.0, top_p=0.95, top_k=64` (OpenAI식 0.7 금지)
- [ ] **vLLM**: `--reasoning-parser gemma4 --tool-call-parser gemma4` 필수
- [ ] **런타임 template 버전**: 2026-07-15 개정본(`preserve_thinking`·인자 검증)인지 확인
- [ ] Audio 워크로드: E2B/E4B/12B 사용 (26B A4B·31B 미지원)

**Alibaba Qwen 3.8** (오픈웨이트):
- [ ] **ChatML 템플릿**: `<|im_start|>role\n...\n<|im_end|>` (Qwen 3.6 동일)
- [ ] **`reasoning_effort` 선택**: `xhigh`(기본)/`medium`/`low`만 허용, `high`·`none`은 template 예외. 로컬 27B는 `low`~`medium`부터, 호스팅 API는 `xhigh` 후 실측
- [ ] **추론 지시문 자동 주입 인지**: `xhigh`·`low`는 시스템 턴 맨 앞에 영문 지시문이 붙음(`medium`은 없음). "천천히 생각하라" 류 문장을 프롬프트에 중복해 넣지 않기
- [ ] **`preserve_thinking` 기본 ON**: 클라이언트가 `reasoning_content`를 같은 필드로 되돌리는지 확인, 단발 작업은 `false`
- [ ] **thinking OFF는 27B·Flash-Next만**: 2.4T-A95B는 `enable_thinking=false`가 예외
- [ ] **Tool 포맷·파서**: XML 스타일 `<function=…><parameter=…>`, `--tool-call-parser qwen3_coder` (Flash-Next는 `qwen3_xml`)
- [ ] **예약 태그 회피**: `<think>`, `<tool_call>`, `<tool_response>`, `<tools>`, `<function=`, `<parameter=`를 커스텀 XML 태그로 쓰지 않기. 절 구분은 Markdown 헤더
- [ ] **Sampling 단일 프리셋**: thinking `temp=1.0, top_p=0.95, top_k=20, presence=0.0` / instruct `temp=0.7, top_p=0.8, presence=1.5`. 3.6의 모델별 `presence_penalty` 분기·코딩용 temp 0.6은 폐기
- [ ] **출력 예산**: reasoning 262,144 / 최종 131,072. 호스팅 API는 `max_completion_tokens`(CoT 포함)
- [ ] **Long context**: 262K native, YaRN 1M은 실제 길이가 262K를 넘을 때만(static YaRN). API는 1M 디폴트
- [ ] **라이선스 확인**: 27B만 Apache 2.0. 2.4T-A95B·Flash-Next는 MAU·매출 조건과 MaaS 별도 라이선스
- [ ] **공식 권장 프레임워크**: Qwen-Agent + MCP. 하네스는 Claude Code·Codex·Qwen Code·Qoder·OpenClaw 공식 설정

### 추가 도구 (사용자 직접)
- OpenAI Prompt Optimizer: https://platform.openai.com/chat/edit?optimize=true

## 상세 가이드

### 플랫폼 비교

- **[platform-differences.md](references/platform-differences.md)** ⭐ 핵심 차이점 한눈에 비교

### 공통 기법 (범용)

- **[few-shot.md](references/few-shot.md)** - Few-shot/Multishot 예시 패턴
- **[chain-of-thought.md](references/chain-of-thought.md)** - CoT 프롬프팅 (단계별 추론)
- **[templates.md](references/templates.md)** - 실전 템플릿 + 한국어 톤 가이드
- **[reasoning-params.md](references/reasoning-params.md)** - 추론 깊이/응답 길이 제어 (범용 원칙 + 프롬프트 패턴)

### 고급 기법 (범용)

- **[security.md](references/security.md)** 🔴 Prompt Injection 방어, 입력/출력 검증
- **[self-correction.md](references/self-correction.md)** 🔴 자기수정 체인 (생성→검토→개선)
- **[vision-prompting.md](references/vision-prompting.md)** 🔴 이미지/차트 분석 프롬프트
- **[context-engineering.md](references/context-engineering.md)** ⭐ Context Engineering 개념과 실무 적용
- **[prompt-trends-2026.md](references/prompt-trends-2026.md)** 2026 프로덕션 전략, 자동 최적화 도구

### OpenAI (GPT) 특화

- **[message-roles.md](references/message-roles.md)** - developer/user 역할 상세
- **[tool-calling.md](references/tool-calling.md)** - Agentic Tool Calling 가이드 (패턴 출처는 OpenAI 가이드 — Claude 5 세대에는 그대로 적용 금지)
- **[gpt6-patterns.md](references/gpt6-patterns.md)** ⭐ GPT-6 Astra 프롬프트 패턴 (주도성, 지시 파일 모순 감사, 테스트 범위 축소, 위임 명시, effort 5단계·`none` 폐지, 제거 파라미터, 5.6 → 6 마이그레이션)
- **[gpt56-patterns.md](references/gpt56-patterns.md)** GPT-5.6 프롬프트 패턴 (티어 선택, 우선순위 지시, effort 재튜닝, pro mode·reasoning.context·PTC) — 계약 구조·신규 API 기능은 GPT-6에서도 유효
- **[optimization.md](references/optimization.md)** - GPT 프롬프트 최적화 팁 (모순 제거, 지시 계층, 출력 형식, 캐싱)

### Anthropic (Claude) 특화

- **[claude-5-specifics.md](references/claude-5-specifics.md)** ⭐ Claude 5 세대 (Fable 5.1·Opus 5) 베스트 프랙티스 — De-prescribe, 하드 제약, 권장 스니펫, Opus 5 차이점, Fable 5 → 5.1 델타
- **[long-context.md](references/long-context.md)** ⭐ Long Context 최적화 (30%↑)

### Google Gemma 특화 (오픈웨이트)

- **[gemma4-patterns.md](references/gemma4-patterns.md)** ⭐ Gemma 4 패턴 요약 — chat template 교체와 2026-07 개정 인자, `<|think|>` 토글, multi-turn strip, `<|"|>` tool delimiter·병렬 호출, 공식 sampling, vLLM 플래그, MTP·QAT, Gemma 3 → 4 마이그레이션

### Alibaba Qwen 특화 (오픈웨이트)

- **[qwen38-patterns.md](references/qwen38-patterns.md)** ⭐ Qwen 3.8 패턴 요약 — ChatML, `reasoning_effort` + `preserve_thinking` 기본 ON, XML tool 포맷·`qwen3_coder` 파서, 단일 sampling, 라이선스 차이, agentic 시스템 프롬프트, Qwen 3.6 → 3.8 마이그레이션

## 참고 자료

### OpenAI
- [GPT-6 Astra 풀 가이드 (한국어)](../../../reference/openai-prompt-guide/gpt-6-prompt-guide.md) ⭐ 최신 — 행동 축 5개 스니펫 원문·API 변경·Codex 적용 수록
- [GPT-6 Astra Prompt Guidance (공식)](https://developers.openai.com/api/docs/guides/prompt-guidance) ⭐ 최신
- [Using GPT-6 Astra / Migration (공식)](https://developers.openai.com/api/docs/guides/latest-model)
- [GPT-6 Astra 모델 카드 (공식)](https://developers.openai.com/api/docs/models/gpt-6-astra)
- [GPT-5.6 풀 가이드 (한국어)](../../../reference/openai-prompt-guide/gpt-5.6-prompt-guide.md) (이전 세대) — 티어·마이그레이션·신규 파라미터 수록
- [OpenAI Prompt Engineering](https://platform.openai.com/docs/guides/prompt-engineering)
- [GPT-5.6 Prompting Guide](https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6) (이전 세대)
- [Upgrading to GPT-5.6 Sol](https://developers.openai.com/api/docs/guides/upgrading-to-gpt-5p6-sol) — 마이그레이션 공식 절차
- [Using GPT-5.6](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6)
- [Prompt Personalities (Cookbook)](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
- [Prompt Optimizer](https://platform.openai.com/chat/edit?optimize=true) (사용자 직접 실행)

### Anthropic
- [Fable 5.1 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-fable-5-1-prompt-guide.md) ⭐ 최신 — 행동 변화 대응 스니펫 원문 수록
- [Fable 5 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-5-fable-prompt-guide.md) — 스니펫 원문 전체 수록
- [Opus 5 풀 가이드 (한국어)](../../../reference/claude-prompt-guide/claude-opus-5-prompt-guide.md) ⭐ 최신 — 스캐폴딩 삭제·위임 상한·effort 역전
- [Prompting Claude Fable 5.1 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1) ⭐ 최신
- [Prompting Claude Fable 5 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)
- [Prompting Claude Opus 5 (공식)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
- [Introducing Claude Fable 5 (공식)](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5)
- [Claude Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview)

### Google Gemma 4
- [Gemma 4 풀 가이드 (한국어)](../../../reference/google-prompt-guide/gemma-4-prompt-guide.md) ⭐ 15섹션 + 외부 노하우
- [Gemma 4 모델 카드 (공식)](https://ai.google.dev/gemma/docs/core/model_card_4)
- [Prompt formatting (공식)](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
- [Function calling (공식)](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
- [MTP 드래프터 (공식)](https://ai.google.dev/gemma/docs/mtp/mtp)
- [Gemma 4 Technical Report (arXiv)](https://arxiv.org/abs/2607.02770)
- [HuggingFace 모델 카드 (31B-it)](https://huggingface.co/google/gemma-4-31B-it)
- [HuggingFace Blog — Gemma 4](https://huggingface.co/blog/gemma4)
- [vLLM Gemma 4 Recipe](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
- [Simon Willison — Gemma 4 출시일 분석](https://simonwillison.net/2026/Apr/2/gemma-4/)

### Alibaba Qwen 3.8
- [Qwen 3.8 풀 가이드 (한국어)](../../../reference/qwen-prompt-guide/qwen-3.8-prompt-guide.md) ⭐ 17섹션 + 외부 노하우
- [Qwen3.8 GitHub (공식)](https://github.com/QwenLM/Qwen3.8)
- [Qwen-Agent 프레임워크 (공식)](https://github.com/QwenLM/Qwen-Agent)
- [Qwen3.8-Max: A New Bar for Coding and Cowork (Alibaba Cloud 미러)](https://www.alibabacloud.com/blog/qwen3-8-max-a-new-bar-for-coding-and-cowork_603421)
- [Qwen3.8-27B Practical Guide (Alibaba Cloud)](https://www.alibabacloud.com/blog/qwen3-8-27b-practical-guide-control-reasoning-depth-and-extend-context-to-1m-tokens_603509)
- [HuggingFace 모델 카드 (27B)](https://huggingface.co/Qwen/Qwen3.8-27B)
- [QwenCloud OpenAI chat API reference (공식)](https://docs.qwencloud.com/api-reference/chat/openai-chat)
- [Simon Willison — Qwen 3.8 27B overthinking 분석](https://simonwillison.net/2026/Aug/16/qwen-38-27b/)
- [Caleb Fahlgren — Qwen 3 Chat Template 분석 (HF Blog)](https://huggingface.co/blog/qwen-3-chat-template-deep-dive)
