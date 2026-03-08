# Context Engineering 심층 조사 리포트

> 조사일: 2026-03-08 | 웹 검색 기반 종합 정리

---

## 1. 용어의 정의와 출처

### 정의

**Context Engineering(컨텍스트 엔지니어링)**은 LLM 추론(inference) 시 컨텍스트 윈도우에 포함되는 토큰(정보)의 집합을 체계적으로 설계, 구성, 관리하는 분야다. 단순히 "좋은 프롬프트를 작성하는 것"이 아니라, 모델이 올바른 결과를 생성할 수 있도록 **적시에 적절한 정보를 동적으로 조합하는 시스템 수준의 엔지니어링**을 의미한다.

> "Context refers to the set of tokens included when sampling from a large-language model. The engineering problem is optimizing the utility of those tokens against the inherent constraints of LLMs in order to consistently achieve a desired outcome."
> -- [Anthropic Engineering Blog](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) (2025.09.29)

### 출처와 역사

- **학술적 기원**: 컨텍스트 인식(Context-Aware) 컴퓨팅의 개념은 2001년 Anind K. Dey가 유비쿼터스 컴퓨팅/HCI 연구에서 "엔티티의 상황을 특징짓는 모든 정보"로 정의한 것에서 시작.
- **LLM 맥락에서의 대중화**: 2025년 6월, Shopify CEO **Tobi Lutke**가 X(구 Twitter)에 다음과 같이 포스팅하면서 폭발적 관심을 받음 (2025.06.18, 190만 뷰):

> "I really like the term 'context engineering' over prompt engineering. It describes the core skill better: the art of providing all the context for the task to be plausibly solvable by the LLM."
> -- [Tobi Lutke (@tobi)](https://x.com/tobi/status/1935533422589399127)

- 다음 날(2025.06.19) **Andrej Karpathy**가 이에 동의하며 정의를 확립:

> "+1 for 'context engineering' over 'prompt engineering'. People associate prompts with short task descriptions you'd give an LLM in your day-to-day use. When in every industrial-strength LLM app, context engineering is the delicate art and science of filling the context window with just the right information for the next step."
> -- [Andrej Karpathy (@karpathy)](https://x.com/karpathy/status/1937902205765607626)

- 2025년 7월, **Gartner** 공식 선언: "Context engineering is in, and prompt engineering is out."

---

## 2. Prompt Engineering vs Context Engineering 차이점

| 구분 | Prompt Engineering | Context Engineering |
|------|-------------------|-------------------|
| **초점** | 모델에 "어떻게(how)" 물을 것인가 | 모델이 "무엇을(what)" 알고 있는 상태에서 물을 것인가 |
| **범위** | 단일 입출력 쌍(single turn) | 메모리, 히스토리, 도구, 시스템 프롬프트 등 전체 |
| **관계** | Context Engineering의 **부분집합** | Prompt Engineering을 **포함**하는 상위 개념 |
| **비유** | "마법 같은 문장 하나 찾기" | "AI를 위한 전체 각본(screenplay) 작성" |
| **스케일** | 수동 튜닝, 재현 어려움 | 시스템 수준 설계, 일관성과 재사용 고려 |
| **적합 케이스** | 단순 Q&A | 복잡한 에이전트, 멀티턴, 프로덕션 시스템 |

핵심 구분:
- **Prompt Engineering**: 컨텍스트 윈도우 *안에서* 하는 일
- **Context Engineering**: 컨텍스트 윈도우를 *무엇으로 채울지* 결정하는 시스템 설계

> "Prompt engineering is what you do inside the context window. Context engineering is how you decide what fills the window."
> -- [Elastic Search Labs](https://www.elastic.co/search-labs/blog/context-engineering-vs-prompt-engineering)

---

## 3. 핵심 구성요소

### 3.1 RAG (Retrieval-Augmented Generation)와의 관계

RAG는 컨텍스트 엔지니어링의 **핵심 패턴이자 하위 구성요소**다.

- RAG는 LLM의 정적 지식을 외부 지식 베이스로부터의 동적 검색으로 보강
- 문서를 청킹(chunking)하고 벡터 DB에 임베딩 -> 쿼리 시 의미적으로 가장 관련 높은 청크 검색 -> 프롬프트와 결합하여 LLM에 전달
- Context Engineering은 RAG를 **포함하면서도 넘어서는** 개념: RAG + 메모리 + 도구 통합 + 상태 관리 + 압축 등을 모두 아우름
- 2026년에는 RAG가 **Vector Orchestration**으로 진화: 텍스트, 관계, API 등 다양한 데이터 타입을 조율하여 고급 추론 지원

> "Context Engineering goes beyond prompt engineering and RAG."
> -- [The New Stack](https://thenewstack.io/context-engineering-going-beyond-prompt-engineering-and-rag/)

### 3.2 컨텍스트 윈도우 최적화

Andrej Karpathy의 비유가 핵심을 잘 설명한다:

> "Think of an LLM like a CPU, and its context window as the RAM or working memory. As an engineer, your job is akin to an operating system: load that working memory with just the right code and data for the task."

**주요 과제:**
- **컨텍스트 로트(Context Rot)**: 입력 토큰이 증가할수록 모델 성능이 비선형적으로 저하되는 현상. Chroma Research가 18개 프론티어 모델(GPT-4.1, Claude 4, Gemini 2.5 등)을 테스트한 결과, **모든 모델에서** 입력 길이 증가 시 성능 저하 확인
- **세 가지 메커니즘**: Lost-in-the-Middle 효과 + 대규모 Attention 희석 + Distractor 간섭이 복합적으로 작용
- **컨텍스트 오염(Context Pollution)**: 무관하거나 중복되거나 충돌하는 정보가 컨텍스트에 과다 포함되어 LLM의 추론 정확도를 떨어뜨리는 현상

**최적화 전략:**
- Trimming: 불필요한 컨텍스트 제거
- Ordering: 가장 최신/관련 높은 데이터를 우선 배치
- Expiration: 장기 메모리 내 데이터 만료 관리
- Context Folding: 모델이 자체적으로 컨텍스트를 관리하는 기법

### 3.3 동적 컨텍스트 구성 (Dynamic Context Construction)

LangChain이 정리한 에이전트 컨텍스트 엔지니어링의 **4가지 전략**:

| 전략 | 설명 |
|------|------|
| **Write (쓰기)** | 컨텍스트 윈도우 밖에 정보를 저장하여 나중에 활용 |
| **Select (선택)** | 필요한 정보를 컨텍스트 윈도우 안으로 가져오기 |
| **Compress (압축)** | 작업 수행에 필요한 토큰만 남기고 압축 |
| **Isolate (분리)** | 컨텍스트를 분할하여 각 에이전트/단계에 맞는 컨텍스트 제공 |

**Anthropic의 실전 기법** (Engineering Blog):
- Compaction(압축): 컨텍스트 윈도우 한계에 도달하면 내용을 요약하고 새 컨텍스트 윈도우를 요약으로 시작
- Structured Note-taking(구조화된 노트): 에이전트가 스스로 핵심 정보를 기록
- Multi-agent Architecture(멀티 에이전트): 컨텍스트를 분리하여 각 에이전트에 할당

### 3.4 메모리 관리 (단기/장기)

| 유형 | 위치 | 특성 | 내용 |
|------|------|------|------|
| **단기 메모리** | 컨텍스트 윈도우 내부 | 유한, 린(lean)하게 유지 | 최근 대화 턴, 추론 과정, 도구 출력, 검색된 문서 |
| **장기 메모리** | 벡터 DB 등 외부 저장소 | 영구적, RAG로 검색 | 에피소드 데이터(과거 이벤트, 사용자 상호작용), 도메인 지식, 사용자 선호 |

**4대 계층 아키텍처** (완전한 Context Engineering 시스템):
1. **Knowledge Retrieval Layer** (지식 검색 계층): RAG, 검색 엔진, API 연동
2. **Memory Management Layer** (메모리 관리 계층): 단기/장기 메모리 관리
3. **Context Orchestration Layer** (컨텍스트 오케스트레이션 계층): 적시에 적절한 정보 조합
4. **Tools & Environment Layer** (도구 및 환경 계층): 외부 도구 실행 및 결과 통합

---

## 4. AI 리더들의 주요 발언

### Andrej Karpathy (전 OpenAI/Tesla AI 수장)

- **핵심 정의**: "Context engineering is the delicate art and science of filling the context window with just the right information for the next step."
- **CPU/RAM 비유**: "LLM을 CPU로, 컨텍스트 윈도우를 RAM으로 생각하라. 엔지니어의 역할은 OS처럼 작업에 맞는 코드와 데이터를 로드하는 것."
- **구성 요소 열거**: task descriptions, few-shot examples, RAG, multimodal data, tools, state and history, compacting
- **경고**: "Too much or too irrelevant context can raise LLM costs and degrade performance, and doing this well is highly non-trivial."
- 출처: [X 포스트](https://x.com/karpathy/status/1937902205765607626) (2025.06.19)

### Simon Willison (Django 공동 창시자, AI 블로거)

- **용어 지지**: "I think 'context engineering' is going to stick."
- **'prompt engineering' 문제 지적**: "Most people's inferred definition of 'prompt engineering' is that it's a pretentious term for typing things into a chatbot. The inferred definitions are the ones that stick, and 'context engineering' is likely to have a much closer inferred definition to the intended meaning."
- 출처: [Simon Willison's Blog](https://simonwillison.net/2025/jun/27/context-engineering/) (2025.06.27), [X 포스트](https://x.com/simonw/status/1938745355916714448)

### Tobi Lutke (Shopify CEO)

- **용어 대중화의 기점**: "I really like the term 'context engineering' over prompt engineering. It describes the core skill better: the art of providing all the context for the task to be plausibly solvable by the LLM."
- **핵심 스킬 정의**: "The fundamental skill of using AI well is to be able to state a problem with enough context, in such a way that without any additional pieces of information, the task is plausibly solvable."
- 출처: [X 포스트](https://x.com/tobi/status/1935533422589399127) (2025.06.18, 190만 뷰)

### Philipp Schmid (Google DeepMind / 前 Hugging Face Technical Lead)

- **실패 원인 진단**: "Most agent failures are not model failures anymore, they are context failures."
- **차이 강조**: "The difference between a cheap demo and a 'magical' agent is about the quality of the context you provide."
- 출처: [The New Skill in AI is Not Prompting, It's Context Engineering](https://www.philschmid.de/context-engineering)

### Gartner (IT 리서치 기관)

- **공식 선언** (2025.07): "Context engineering is in, and prompt engineering is out. AI leaders must prioritize context over prompts."
- **예측**: 2028년까지 AI 애플리케이션 빌드 도구의 80%에 컨텍스트 엔지니어링 기능 탑재, 에이전틱 AI 정확도 최소 30% 향상
- 출처: [Gartner Article](https://www.gartner.com/en/articles/context-engineering)

---

## 5. 프로덕션 적용 사례

### 5.1 Amazon Alexa
- 6억 대 디바이스에서 안정적으로 작동시키기 위해 프롬프트 캐싱, 추론적 실행(speculative execution), 컨텍스트 엔지니어링, 출력 토큰 최소화 기법을 발명/적용

### 5.2 Five Sigma Insurance (보험)
- 폴리시 데이터, 클레임 히스토리, 규정을 동시에 인제스트하는 RAG + 동적 컨텍스트 어셈블리 적용
- **결과**: 클레임 처리 에러 80% 감소, 어저스터 생산성 25% 향상

### 5.3 Block (구 Square) (핀테크)
- Anthropic의 **Model Context Protocol (MCP)** 구현
- LLM을 실시간 결제/머천트 데이터에 연결
- 정적 프롬프트 -> 동적 정보 리치 환경으로 전환하여 운영 자동화 및 맞춤형 문제 해결 개선

### 5.4 Casetext / Co-Counsel (법률)
- GPT-4 기반 AI 법률 어시스턴트 프로덕션 배포
- 엄격한 TDD + 프롬프트/컨텍스트 엔지니어링으로 미션 크리티컬 애플리케이션의 LLM 신뢰성 확보
- **결과**: Thomson Reuters에 6.5억 달러 인수

### 5.5 Anthropic Claude Code
- 에이전트 하네스(harness) 설계에서 컨텍스트 엔지니어링 원칙 적용
- 장기 실행 에이전트의 컨텍스트 관리를 위한 compaction, structured note-taking, multi-agent 아키텍처 활용
- 출처: [Anthropic Engineering Blog - Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)

---

## 6. 주요 블로그 포스트, 발표, 논문 (2025-2026)

### 블로그 포스트

| 날짜 | 제목 | 저자/출처 | 링크 |
|------|------|----------|------|
| 2025.06.18 | 용어 대중화 트윗 | Tobi Lutke | [X](https://x.com/tobi/status/1935533422589399127) |
| 2025.06.19 | Context Engineering 정의 트윗 | Andrej Karpathy | [X](https://x.com/karpathy/status/1937902205765607626) |
| 2025.06.27 | Context Engineering | Simon Willison | [Blog](https://simonwillison.net/2025/jun/27/context-engineering/) |
| 2025.07 | Context Engineering is in, Prompt Engineering is out | Gartner | [Article](https://www.gartner.com/en/articles/context-engineering) |
| 2025.09.29 | Effective Context Engineering for AI Agents | Anthropic | [Blog](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) |
| 2025.11.05 | From Vibe Coding to Context Engineering: 2025 in Software Development | MIT Technology Review | [Article](https://www.technologyreview.com/2025/11/05/1127477/from-vibe-coding-to-context-engineering-2025-in-software-development/) |
| 2025.11.26 | Effective Harnesses for Long-Running Agents | Anthropic | [Blog](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) |
| 날짜 미상 | The New Skill in AI is Not Prompting, It's Context Engineering | Philipp Schmid | [Blog](https://www.philschmid.de/context-engineering) |
| 날짜 미상 | Context Engineering for Agents | LangChain | [Blog](https://blog.langchain.com/context-engineering-for-agents/) |
| 날짜 미상 | The Rise of Context Engineering | LangChain | [Blog](https://blog.langchain.com/the-rise-of-context-engineering/) |
| 날짜 미상 | Context Engineering vs Prompt Engineering | Elastic Search Labs | [Blog](https://www.elastic.co/search-labs/blog/context-engineering-vs-prompt-engineering) |
| 날짜 미상 | Context Engineering: The 6 Techniques That Actually Matter in 2026 | Towards AI | [Article](https://towardsai.net/p/machine-learning/context-engineering-the-6-techniques-that-actually-matter-in-2026-a-comprehensive-guide) |
| 날짜 미상 | Context Rot: How Increasing Input Tokens Impacts LLM Performance | Chroma Research | [Research](https://research.trychroma.com/context-rot) |

### 논문 (arXiv)

| 날짜 | 제목 | arXiv ID | 비고 |
|------|------|----------|------|
| 2025.07 | A Survey of Context Engineering for Large Language Models | [2507.13334](https://arxiv.org/abs/2507.13334) | **1,400편 이상의 논문 분석**, 컨텍스트 엔지니어링의 공식 분류 체계(taxonomy) 제시 |
| 2025.10 | Agentic Context Engineering: Evolving Contexts for Self-Improving Language Models | [2510.04618](https://arxiv.org/abs/2510.04618) | ACE 프레임워크: 컨텍스트를 진화하는 플레이북으로 취급 |
| 2025.10 | Context Engineering 2.0: The Context of Context Engineering | [2510.26493](https://arxiv.org/abs/2510.26493) | 체계적 정의와 역사적/개념적 지형 정리 |
| 2025.10 | Context Engineering for AI Agents in Open-Source Software | [2510.21413](https://arxiv.org/abs/2510.21413) | OSS에서의 AI 에이전트 컨텍스트 엔지니어링 |
| 2025.12 | Everything is Context: Agentic File System Abstraction for Context Engineering | [2512.05470](https://arxiv.org/abs/2512.05470) | 파일시스템을 컨텍스트 엔지니어링 추상화로 활용 |

### 오픈소스 리소스

| 리포지토리 | 설명 | 링크 |
|-----------|------|------|
| Awesome-Context-Engineering | 수백 편의 논문, 프레임워크, 구현 가이드 모음 | [GitHub](https://github.com/Meirtz/Awesome-Context-Engineering) |
| Context-Engineering (davidkimai) | Karpathy와 3Blue1Brown에서 영감받은 핸드북 | [GitHub](https://github.com/davidkimai/Context-Engineering) |
| langchain-ai/context_engineering | LangChain의 컨텍스트 엔지니어링 구현 | [GitHub](https://github.com/langchain-ai/context_engineering) |
| LangChain Docs - Context Engineering in Agents | 공식 문서 | [Docs](https://docs.langchain.com/oss/python/langchain/context-engineering) |

---

## 7. 종합 정리: Context Engineering의 현재 위상

### 타임라인

```
2001       Anind K. Dey의 Context-Aware 컴퓨팅 정의
2022-2023  Prompt Engineering 대중화 (ChatGPT 등장)
2025.06    Tobi Lutke + Andrej Karpathy가 "Context Engineering" 용어 대중화
2025.07    Gartner "Context Engineering is in, Prompt Engineering is out" 선언
2025.07    첫 종합 서베이 논문 (arXiv 2507.13334)
2025.09    Anthropic Engineering Blog 공식 가이드 발행
2025.10    ACE 프레임워크, CE 2.0 등 후속 논문 다수
2025.11    MIT Technology Review "2025년 소프트웨어 개발의 키워드" 선정
2026       프로덕션 표준으로 자리잡는 중, Context Rot 연구 심화
```

### 핵심 테이크어웨이

1. **용어 전환**: "Prompt Engineering"은 사람들이 "챗봇에 뭔가 타이핑하는 것"으로 오해하는 문제가 있어, "Context Engineering"이 더 정확한 의미를 전달하는 용어로 자리 잡고 있다.

2. **시스템 수준 사고**: 단일 프롬프트 최적화가 아니라, 메모리/RAG/도구/상태/히스토리를 포함한 **전체 정보 파이프라인 설계**가 핵심이다.

3. **에이전트 시대의 필수 역량**: 대부분의 에이전트 실패는 모델 실패가 아니라 **컨텍스트 실패**다 (Philipp Schmid).

4. **Context Rot은 실존 문제**: 모든 프론티어 모델이 입력 길이 증가 시 성능 저하를 겪으며, 이를 관리하는 것이 컨텍스트 엔지니어링의 핵심 과제다.

5. **Gartner 예측**: 2028년까지 AI 앱 빌드 도구의 80%에 컨텍스트 엔지니어링 기능이 탑재될 것.

---

## Sources

- [Anthropic - Effective Context Engineering for AI Agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Anthropic - Effective Harnesses for Long-Running Agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents)
- [Andrej Karpathy X Post](https://x.com/karpathy/status/1937902205765607626)
- [Tobi Lutke X Post](https://x.com/tobi/status/1935533422589399127)
- [Simon Willison - Context Engineering](https://simonwillison.net/2025/jun/27/context-engineering/)
- [Simon Willison X Post](https://x.com/simonw/status/1938745355916714448)
- [Philipp Schmid - The New Skill in AI is Not Prompting, It's Context Engineering](https://www.philschmid.de/context-engineering)
- [Gartner - Context Engineering](https://www.gartner.com/en/articles/context-engineering)
- [LangChain - Context Engineering for Agents](https://blog.langchain.com/context-engineering-for-agents/)
- [LangChain - The Rise of Context Engineering](https://blog.langchain.com/the-rise-of-context-engineering/)
- [Elastic Search Labs - Context Engineering vs Prompt Engineering](https://www.elastic.co/search-labs/blog/context-engineering-vs-prompt-engineering)
- [The New Stack - Context Engineering: Going Beyond Prompt Engineering and RAG](https://thenewstack.io/context-engineering-going-beyond-prompt-engineering-and-rag/)
- [Chroma Research - Context Rot](https://research.trychroma.com/context-rot)
- [Weaviate - Context Engineering: LLM Memory and Retrieval](https://weaviate.io/blog/context-engineering)
- [MIT Technology Review - From Vibe Coding to Context Engineering](https://www.technologyreview.com/2025/11/05/1127477/from-vibe-coding-to-context-engineering-2025-in-software-development/)
- [Towards AI - Context Engineering: The 6 Techniques That Actually Matter in 2026](https://towardsai.net/p/machine-learning/context-engineering-the-6-techniques-that-actually-matter-in-2026-a-comprehensive-guide)
- [arXiv 2507.13334 - A Survey of Context Engineering for Large Language Models](https://arxiv.org/abs/2507.13334)
- [arXiv 2510.04618 - Agentic Context Engineering](https://arxiv.org/abs/2510.04618)
- [arXiv 2510.26493 - Context Engineering 2.0](https://arxiv.org/abs/2510.26493)
- [arXiv 2512.05470 - Everything is Context](https://arxiv.org/abs/2512.05470)
- [FlowHunt - Context Engineering: The Definitive 2025 Guide](https://www.flowhunt.io/blog/context-engineering/)
- [MarkTechPost - Case Studies: Real-World Applications of Context Engineering](https://www.marktechpost.com/2025/08/12/case-studies-real-world-applications-of-context-engineering/)
- [Neo4j - Context Engineering vs Prompt Engineering](https://neo4j.com/blog/agentic-ai/context-engineering-vs-prompt-engineering/)
- [GitHub - Awesome-Context-Engineering](https://github.com/Meirtz/Awesome-Context-Engineering)
- [GitHub - langchain-ai/context_engineering](https://github.com/langchain-ai/context_engineering)
- [Inkeep - Fighting Context Rot](https://inkeep.com/blog/fighting-context-rot)
- [Redis - Context Rot Explained](https://redis.io/blog/context-rot/)
