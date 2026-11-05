# Context Engineering (컨텍스트 엔지니어링)

LLM 추론 시 컨텍스트 윈도우에 포함되는 정보를 체계적으로 설계, 구성, 관리하는 시스템 수준의 엔지니어링입니다.

## 목차

- [정의](#정의)
- [Prompt Engineering vs Context Engineering](#prompt-engineering-vs-context-engineering)
- [핵심 구성요소](#핵심-구성요소)
- [Context Rot (컨텍스트 부패)](#context-rot-컨텍스트-부패)
- [프로덕션 적용 가이드](#프로덕션-적용-가이드)
- [참고 자료](#참고-자료)

---

## 정의

> "Context engineering is the delicate art and science of filling the context window with just the right information for the next step."
> -- Andrej Karpathy (2025.06)

**CPU/RAM 비유**: LLM을 CPU, 컨텍스트 윈도우를 RAM으로 생각합니다. 엔지니어의 역할은 **운영체제**처럼 작업에 맞는 코드와 데이터를 적시에 로딩하는 것입니다.

단순히 "좋은 프롬프트를 작성하는 것"이 아니라, 모델이 올바른 결과를 생성할 수 있도록 **적시에 적절한 정보를 동적으로 조합하는 시스템 설계**를 의미합니다.

### 용어의 역사

- **2025.06**: Shopify CEO **Tobi Lutke**가 용어를 대중화 ("I really like the term 'context engineering' over prompt engineering")
- **2025.06**: **Andrej Karpathy**가 동의하며 정의를 확립
- **2025.07**: **Gartner** 공식 선언 — "Context engineering is in, and prompt engineering is out."
- **2025.09**: **Anthropic** Engineering Blog에서 에이전트용 컨텍스트 엔지니어링 가이드 발행

---

## Prompt Engineering vs Context Engineering

| 구분 | Prompt Engineering | Context Engineering |
|------|-------------------|-------------------|
| **초점** | 모델에 "어떻게" 물을 것인가 | 모델이 "무엇을" 알고 있는 상태에서 물을 것인가 |
| **범위** | 단일 입출력 쌍 (single turn) | 메모리, 히스토리, 도구, 시스템 프롬프트 전체 |
| **관계** | Context Engineering의 **부분집합** | Prompt Engineering을 **포함**하는 상위 개념 |
| **스케일** | 수동 튜닝, 재현 어려움 | 시스템 수준 설계, 일관성과 재사용 고려 |
| **적합 케이스** | 단순 Q&A, 1회성 작업 | 복잡한 에이전트, 멀티턴, 프로덕션 시스템 |

**핵심 구분**:
- **Prompt Engineering**: 컨텍스트 윈도우 *안에서* 하는 일
- **Context Engineering**: 컨텍스트 윈도우를 *무엇으로 채울지* 결정하는 시스템 설계

> "Most agent failures are not model failures anymore, they are context failures."
> -- Philipp Schmid (Google DeepMind)

---

## 핵심 구성요소

### 1. Knowledge Retrieval (지식 검색)

RAG(Retrieval-Augmented Generation)가 대표적 패턴입니다:
- 외부 문서를 청킹(chunking) → 벡터 DB에 임베딩
- 쿼리 시 의미적으로 관련 높은 청크를 검색 → 프롬프트와 결합
- 2026년에는 **Vector Orchestration**으로 진화: 텍스트, 관계, API 등 다양한 데이터 타입을 조율

Context Engineering은 RAG를 **포함하면서도 넘어서는** 개념입니다.

### 2. Memory Management (메모리 관리)

| 유형 | 위치 | 내용 |
|------|------|------|
| **단기 메모리** | 컨텍스트 윈도우 내부 | 최근 대화 턴, 추론 과정, 도구 출력, 검색된 문서 |
| **장기 메모리** | 벡터 DB 등 외부 저장소 | 과거 이벤트, 사용자 선호, 도메인 지식 |

단기 메모리는 **린(lean)하게** 유지하고, 장기 메모리는 RAG로 필요 시 검색합니다.

### 3. Context Orchestration (컨텍스트 오케스트레이션)

LangChain이 정리한 에이전트 컨텍스트 엔지니어링의 **4가지 전략**:

| 전략 | 설명 | 예시 |
|------|------|------|
| **Write (쓰기)** | 컨텍스트 윈도우 밖에 정보 저장 | 파일, DB, 메모리 저장 |
| **Select (선택)** | 필요한 정보를 컨텍스트로 가져오기 | RAG 검색, 도구 호출 |
| **Compress (압축)** | 필요한 토큰만 남기고 압축 | 요약, 컴팩션(compaction) |
| **Isolate (분리)** | 컨텍스트를 분할하여 각 단계에 맞게 제공 | 멀티 에이전트 아키텍처 |

**Anthropic의 실전 기법** (Engineering Blog):
- **Compaction**: 컨텍스트 한계 도달 시 내용을 요약하고 새 윈도우를 요약으로 시작
- **Structured Note-taking**: 에이전트가 스스로 핵심 정보를 기록
- **Multi-agent Architecture**: 컨텍스트를 분리하여 각 에이전트에 할당

### 4. Tools & Environment (도구 및 환경)

외부 도구 실행 및 결과를 컨텍스트에 통합합니다:
- API 호출 결과
- 코드 실행 출력
- 파일 시스템 읽기/쓰기
- 데이터베이스 쿼리 결과

---

## Context Rot (컨텍스트 부패)

입력 토큰이 증가할수록 모델 성능이 **비선형적으로 저하**되는 현상입니다.

### 원인 (3가지 메커니즘)

1. **Lost-in-the-Middle**: 컨텍스트 중간에 배치된 정보가 시작/끝 대비 **30% 정확도 하락**
2. **Attention 희석**: 대규모 컨텍스트에서 관련 정보에 대한 attention이 분산
3. **Distractor 간섭**: 무관한 정보가 추론을 방해

> Chroma Research가 18개 프론티어 모델(GPT-4.1, Claude 4, Gemini 2.5 등)을 테스트한 결과, **모든 모델에서** 입력 길이 증가 시 성능 저하 확인

### 최적화 전략

| 전략 | 설명 |
|------|------|
| **Trimming** | 불필요한 컨텍스트 적극 제거 |
| **Ordering** | 가장 관련 높은 데이터를 시작/끝에 배치 (중간 매몰 방지) |
| **Expiration** | 장기 메모리 내 데이터 만료 관리 |
| **프롬프트 최적 길이** | 150~300단어가 실용적 최적점 (Levy et al. 2024) |

---

## 프로덕션 적용 가이드

### 캐싱 친화 레이아웃

```
┌──────────────────────────────┐
│  정적 Prefix (캐싱 대상)      │  ← 시스템 프롬프트, 역할, 규칙
│  - 시스템 지침                │
│  - 도구 정의                  │
│  - 예시                      │
├──────────────────────────────┤
│  동적 Suffix (매 요청 변경)    │  ← 사용자 입력, 검색 결과
│  - 사용자 메시지              │
│  - RAG 검색 결과              │
│  - 대화 히스토리              │
└──────────────────────────────┘
```

**효과**: 비용 최대 90% / 레이턴시 최대 85% 절감 (Anthropic 프롬프트 캐싱 기준)

### 모듈식 프롬프트 아키텍처

2026년 효과적 프롬프트는 단일 텍스트 블록이 아닌, 개별 컴포넌트로 조립되는 **모듈식 구조**입니다:

```yaml
system_prompt:
  identity: "역할 및 목표"
  rules: "행동 규칙"
  tools: "사용 가능한 도구 정의"
  examples: "포맷 정렬용 예시 1~2개"
  # --- 여기까지 정적 (캐싱) ---
  context: "동적 RAG 결과"
  history: "최근 대화 (요약)"
  user_input: "현재 요청"
```

### 프롬프트 최적 길이

| 범위 | 효과 |
|------|------|
| ~150단어 | 간단한 태스크에 충분 |
| 150~300단어 | **실용적 최적점** |
| 300~1000단어 | 복잡한 태스크에 필요 시 |
| 3000토큰+ | **성능 저하 시작** — 분할 또는 압축 권장 |

### 실무 체크리스트

- [ ] 핵심 지침을 프롬프트 시작 또는 끝에 배치 (중간 매몰 방지)
- [ ] 정적 콘텐츠를 앞, 동적 콘텐츠를 뒤에 배치 (캐싱 최적화)
- [ ] 불필요한 컨텍스트 제거 (Trimming)
- [ ] 장기 세션에서 컴팩션(Compaction) 적용
- [ ] 멀티 에이전트 시 컨텍스트 분리 (Isolate)

---

## 참고 자료

- [Anthropic - Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (2025.09)
- [Anthropic - Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (2025.11)
- [Andrej Karpathy - Context Engineering 정의](https://x.com/karpathy/status/1937902205765607626) (2025.06)
- [Tobi Lutke - 용어 대중화](https://x.com/tobi/status/1935533422589399127) (2025.06)
- [Simon Willison - Context Engineering](https://simonwillison.net/2025/jun/27/context-engineering/) (2025.06)
- [Gartner - Context Engineering](https://www.gartner.com/en/articles/context-engineering) (2025.07)
- [LangChain - Context Engineering for Agents](https://blog.langchain.com/context-engineering-for-agents/)
- [Chroma Research - Context Rot](https://research.trychroma.com/context-rot)
- [arXiv:2507.13334 - A Survey of Context Engineering for LLMs](https://arxiv.org/abs/2507.13334) (2025.07)
- [Philipp Schmid - The New Skill in AI is Not Prompting](https://www.philschmid.de/context-engineering)
