# 2025~2026 프롬프트 전략 최신 연구 동향 및 실사용자 리뷰

> 조사일: 2026-03-08
> 출처: 학술 논문, 기술 블로그, 커뮤니티 토론, 공식 문서

---

## 목차

1. [핵심 요약 (Executive Summary)](#1-핵심-요약)
2. [학술/연구 동향](#2-학술연구-동향)
3. [모델 세대별 프롬프트 전략 변화](#3-모델-세대별-프롬프트-전략-변화)
4. [실무/커뮤니티 경험](#4-실무커뮤니티-경험)
5. [프롬프트 자동 최적화 도구](#5-프롬프트-자동-최적화-도구)
6. [출처 목록](#6-출처-목록)

---

## 1. 핵심 요약

### 패러다임 전환: Prompt Engineering -> Context Engineering

2025년 중반을 기점으로 업계 핵심 키워드가 "프롬프트 엔지니어링(Prompt Engineering)"에서 **"컨텍스트 엔지니어링(Context Engineering)"**으로 전환되었다.

- **Andrej Karpathy**가 2025년 6월 X(Twitter)에서 공식화: "Context engineering is the delicate art and science of filling the context window with just the right information for the next step."
- LLM을 CPU, 컨텍스트 윈도우를 RAM으로 비유 -- 엔지니어의 역할은 **운영체제**처럼 작업 메모리에 적절한 코드와 데이터를 로딩하는 것
- Gartner도 2025년 컨텍스트 엔지니어링을 "AI 프로세스 성공의 핵심 역량(critical skill)"으로 식별

### 2026년 현재 상태

| 영역 | 2024 | 2026 |
|------|------|------|
| 핵심 패러다임 | Prompt Engineering | Context Engineering + Flow Engineering |
| 직업 시장 | 독립 직군 성장 | 독립 직군 사실상 소멸, 모든 역할에 통합 (68% 기업이 표준 교육화) |
| CoT 전략 | "Think step by step" 만능 | 모델별 분기: 추론 모델에서는 불필요/유해, 표준 모델에서만 유효 |
| 프롬프트 길이 | 상세할수록 좋다 | 150~300단어 최적, 3000토큰 초과 시 성능 저하 |
| 구조화 출력 | 선택 사항 | 프로덕션 필수 (JSON/YAML 스키마 99%+ 준수율) |
| 비용 최적화 | 부차적 | 프롬프트 캐싱으로 90% 비용/85% 레이턴시 절감 가능 |

---

## 2. 학술/연구 동향

### 2.1 최신 프롬프팅 기법 연구

#### Chain-of-Thought(CoT)의 진화

**현황**: CoT는 죽지 않았지만, 적용 방식이 근본적으로 변했다.

- **추론 모델(Reasoning Models)에서의 CoT**: GPT-5는 `reasoning_effort` 파라미터(minimal/low/medium/high)를 도입하여 모델 내부에서 추론 깊이를 직접 조절. "Think step by step"을 명시적으로 지시하면 오히려 **중복 추론으로 성능 저하**.
- **Claude의 Extended Thinking**: Anthropic은 자동화된 구조적 추론 기능을 제공. Extended Thinking이 가능한 경우 수동 CoT보다 선호됨. 다만 투명한 추론 감사(audit)가 필요한 경우 수동 CoT가 여전히 유효.
- **표준 모델에서의 CoT**: 비추론 모델에서는 여전히 CoT가 20~40% 정확도 향상을 보여주며, 디버깅과 감사 추적에 핵심 도구.

**결론**: CoT는 "모든 프롬프트에 적용"에서 "상황별 선택적 적용"으로 전환. 추론 모델에서는 내장 기능 활용, 표준 모델에서는 어려운 태스크에만 적용.

#### Self-Consistency

- 다수의 추론 경로를 샘플링하여 가장 일관된 답변을 선택하는 기법
- 산술 및 상식 추론에서 CoT 단독 대비 지속적 성능 향상
- 2025~2026에도 **앙상블 전략**으로서 가치 유지 (비용이 허용되는 프로덕션 환경)

#### Tree-of-Thought (ToT)

- Game of 24 테스트: IO 7.3%, CoT 4%, CoT+Self-Consistency 9% vs **ToT 74%** 해결률
- 복잡한 의사결정과 탐색이 필요한 태스크에 효과적
- 2026년 실무 가이드: **일상 태스크에는 과잉(overkill)**, 복잡한 문제 해결/계획 수립에만 선택적 사용 권장

#### "Prompt Engineering is Dead" 논쟁

**주장측**:
- Fast Company (2025.05): 독립 직군으로서의 프롬프트 엔지니어링은 "사실상 사라짐"
- Karpathy: 프롬프트 엔지니어링이라는 용어 자체가 "짧은 태스크 설명"을 연상시켜 실제 산업 수준의 작업을 과소대표
- McKinsey 데이터: GenAI 파일럿 중 **10%만이 실질적 재무 영향**을 보고 -- 프롬프트만으로는 전략적 결과 불가

**반론측**:
- Lakera (2026): 프롬프트 엔지니어링은 죽은 것이 아니라 **컨텍스트 엔지니어링의 하위 기술로 흡수**
- 실무에서 프롬프트가 "전체 작업의 85%를 차지"하는 경우가 여전히 많음
- 78% AI 프로젝트 실패가 기술 한계가 아닌 **잘못된 인간-AI 커뮤니케이션**에서 기인

**종합**: 프롬프트 엔지니어링은 죽지 않았지만, 단독 역량에서 **컨텍스트 엔지니어링 + 플로우 엔지니어링의 구성 요소**로 진화. "프롬프트 최적화"만으로는 불충분하고, 컨텍스트 윈도우 전체 설계(시스템 지침, RAG, 도구 출력, 대화 이력, 사용자 메타데이터 등)가 핵심.

#### Structured Output의 영향

- JSON/YAML 스키마 기반 프롬프트: **99%+ 스키마 준수율** 달성
- 자유형 프롬프트: 구조화 데이터 태스크에서 **15~20% 파싱 실패율**
- 연구 결과 (Frontiers, 2025): JSON은 복잡 데이터에 고정확도, YAML은 가독성과 효율의 균형, Hybrid CSV/Prefix는 플랫 데이터에 토큰/시간 효율 최적
- 산업 합의: "자유형에서 구조화 프롬프팅으로의 전환은 스타일 선택이 아닌 **엔지니어링 필수사항**"

#### System Prompt 최적화 연구

핵심 발견:
- **배치(Placement) 중요**: 컨텍스트 중간에 매몰된 정보는 시작/끝 대비 **30% 정확도 하락**
- **프롬프트 최적 길이**: 150~300단어가 실용적 최적점 (Levy, Jacoby, Goldberg 2024 연구)
- **캐싱 친화 레이아웃**: 정적 콘텐츠를 앞(prefix), 가변 콘텐츠를 뒤(suffix)에 배치 → 비용 90%/레이턴시 85% 절감
- **모듈화 아키텍처**: 2026년 효과적 프롬프트는 단일 텍스트 블록이 아닌, 개별 컴포넌트로 조립되는 **모듈식 구조**

### 2.2 주요 학술 서베이 논문 (2024~2025)

| 논문 | 핵심 내용 | 출처 |
|------|----------|------|
| **The Prompt Report** (2024, v6 2025.02 업데이트) | 33개 용어 어휘, **58개 텍스트 프롬프팅 기법** 분류, 40개 멀티모달 기법. 6개 문제 해결 범주: Few-Shot, Thought Generation, Zero-Shot, Ensembling, Self-Criticism, Decomposition | [arXiv:2406.06608](https://arxiv.org/abs/2406.06608) |
| **Systematic Survey of PE in LLMs** (2024, 2025.03 업데이트) | 41개 기법을 응용 분야별 분류 | [arXiv:2402.07927](https://arxiv.org/abs/2402.07927) |
| **Survey of Automatic PE: Optimization Perspective** (2025.02) | 자동 프롬프트 최적화를 4대 패러다임으로 분류: FM 기반 최적화, 진화 컴퓨팅, 그래디언트 기반 최적화, 강화학습 | [arXiv:2502.11560](https://arxiv.org/html/2502.11560v1) |
| **Unleashing PE Potential** (Patterns, Cell Press, 2025) | LLM을 위한 프롬프트 엔지니어링의 체계적 잠재력 분석 | [Cell.com/Patterns](https://www.cell.com/patterns/fulltext/S2666-3899(25)00108-4) |
| **Prompt Engineering for Structured Data** (Preprints, 2025.06) | 프롬프트 스타일과 LLM 성능의 비교 평가 | [Preprints.org](https://www.preprints.org/manuscript/202506.1937) |

---

## 3. 모델 세대별 프롬프트 전략 변화

### 3.1 "큰 모델 = 간단한 프롬프트" 연구

**Larger Models' Paradox (NAACL 2025)**:
- 5개 기본 모델과 20개 응답 생성기 실험에서 "더 크고 강한 모델이 반드시 더 나은 교사가 아님" 발견
- Llama-3.1-405B-Instruct가 항상 더 나은 instruction-following 능력을 제공하지 않음
- 핵심: 모델 크기보다 **교사-학생 모델 간 호환성(Compatibility)**이 중요
- **CAR(Compatibility-Adjusted Reward)** 메트릭 제안

**실용적 함의**:
- 최신 대형 모델(GPT-5.x, Claude 4.x)은 instruction tuning이 잘 되어 있어 **간결하고 직접적인 프롬프트**가 더 효과적
- Zero-shot을 먼저 시도하고, 필요 시에만 Few-shot으로 전환하는 것이 권장 전략

### 3.2 모델별 프롬프트 패턴 (2026년 기준)

#### GPT-5.x (OpenAI)

| 기법 | 상태 | 비고 |
|------|------|------|
| "Think step by step" | **비권장** | 라우터 아키텍처가 내부적으로 추론 처리. 명시적 CoT가 불필요한 추론 라우팅 유발 |
| reasoning_effort 파라미터 | **권장** | minimal/low/medium/high로 추론 깊이 직접 제어 |
| 대화형 톤 | **권장** | 자연스러운 대화체가 최적 |
| 모델 스냅샷 고정 | **필수** | 프로덕션 앱은 특정 스냅샷(예: gpt-5-2025-08-07)에 고정. 라우터 동작이 버전 간 변동 |
| Few-shot | **선택적** | 추론 향상보다 **포맷 정렬** 용도로만 유효 |

#### Claude 4.x (Anthropic)

| 기법 | 상태 | 비고 |
|------|------|------|
| XML 태그 구조화 | **강력 권장** | `<instructions>`, `<context>`, `<example>` 등 XML 태그로 구조화 |
| Extended Thinking | **권장** | 자동 구조적 추론. 수동 CoT보다 선호 |
| 공격적 언어 | **비권장** | "CRITICAL!", "NEVER EVER", ALL-CAPS 등은 과잉 트리거로 **출력 품질 저하** |
| 차분하고 직접적 | **권장** | 침착하고 직접적인 요청이 최적 성능 |
| 프롬프트 캐싱 | **적극 활용** | 캐시 읽기 토큰이 기본 입력의 0.1배 가격 |

#### Gemini 3.x (Google)

| 기법 | 상태 | 비고 |
|------|------|------|
| Few-shot 예시 | **항상 포함** | Zero-shot보다 Few-shot이 항상 선호됨 |
| 짧고 직접적 | **권장** | Claude/GPT보다 더 짧은 프롬프트 선호 |
| 질문 배치 | **중요** | 데이터 컨텍스트 **뒤에** 구체적 질문 배치 |

### 3.3 2024 -> 2026 주요 변화 요약

**더 이상 효과적이지 않은 기법들**:
1. "Think step by step" -- 추론 모델에서 중복/유해
2. ALL-CAPS, "YOU MUST", "NEVER EVER" -- Claude/GPT에서 과잉 트리거
3. 3000토큰 초과 장문 프롬프트 -- 성능 저하 시작
4. Few-shot 예시의 추론 목적 사용 -- 포맷 정렬 용도로만 유효 (일부 모델)

**새롭게 부상한 기법들**:
1. **모듈식 컨텍스트 아키텍처** -- 프롬프트를 6개 핵심 컴포넌트로 분리 조립
2. **캐싱 친화 레이아웃** -- static prefix + dynamic suffix
3. **reasoning_effort 파라미터** -- 모델 내장 추론 깊이 제어
4. **긍정 프레이밍(Positive Framing)** -- "Only use real data"가 "Don't use mock data"보다 효과적

---

## 4. 실무/커뮤니티 경험

### 4.1 Reddit/HackerNews/X 커뮤니티 토론 요약

#### "실제로 효과 있었다" (What Actually Works)

1. **역할 프롬프팅(Role Prompting)**: "가장 높은 레버리지를 가진 시작점". 2주 일관 사용 시 효과 복리 증가. 단, `"You are an expert in marketing"` 같은 모호한 전문성 프롬프트는 기본 출력과 **구분 불가** -- 구체적 제약과 명명된 캐릭터 페르소나만 측정 가능한 스타일 차이를 생성 (r/PromptEngineering 2025 비교 테스트).

2. **메타 프롬프트**: "ChatGPT에게 명확화 질문을 하게 만드는" 메타 프롬프트가 다른 모든 콘텐츠 유형 대비 **3배 더 높은 업보트** -- AI를 늦추면 더 나은 출력을 생성.

3. **구체적 출력 형식 지정**: "출력이 어떻게 생겨야 하는지"를 말하는 것이 "얼마나 좋기를 원하는지"보다 효과적. `"Clear and under 100 words"`가 `"professional and polished"`를 테스트에서 상회.

4. **시스템 프롬프트 투자**: 반복 태스크 유형에 시스템 프롬프트 20분 작성 → 매 세션 수시간의 재프롬프팅 절약. 최고의 시스템 프롬프트 정의 요소: 페르소나, 제약, 출력 포맷, 톤, good/bad 출력 예시.

5. **단일 기법 집중**: "모든 기법을 한 번에 적용하려는 것"이 가장 흔한 실수. 하나의 방법을 선택하고 집중.

#### "실제로 효과 없었다" (What Didn't Work)

1. **모호한 전문성 선언**: `"You are an expert in X"` -- 기본 출력과 차이 없음
2. **과도한 강조**: ALL-CAPS, 강제어 남용 -- 최신 모델에서 역효과
3. **장문 프롬프트**: 3000토큰 초과 시 성능 저하 (Levy et al. 2024)
4. **과도한 최적화**: 모든 기법 동시 적용 시도 -- 혼란과 성능 저하

### 4.2 프로덕션 환경 전략: 간결 vs 상세

**2025~2026 업계 합의**: "간결(concise)은 빈약(sparse)을 의미하지 않는다 -- 모든 단어가 태스크, 제약, 원하는 출력 포맷을 명확히 하는 목적을 가져야 한다."

**비용 비교 사례** (Bolt vs Cluely):
- **상세 접근** (Bolt 스타일): 2500토큰 프롬프트, 10만 호출/일 → 약 $3,000/일
- **구조화 접근** (Cluely 스타일): 212토큰 프롬프트, 동일 볼륨 → 약 $706/일
- **76% 비용 절감** (구조화 접근이 반드시 품질 저하를 의미하지 않음)
- 권장 전략: "먼저 품질을 hill-climb, 그 다음 비용을 down-climb"

**프로덕션 10대 베스트 프랙티스** (종합):
1. 프롬프트를 **프로덕션 코드처럼** 버전 관리
2. **회귀 테스트**와 골든 테스트 세트 유지
3. 정적 콘텐츠 앞, 동적 콘텐츠 뒤 배치 (캐싱 최적화)
4. 모델 스냅샷 고정 (출력 드리프트 방지)
5. 프롬프트를 반복적으로 개선 (A/B 테스트)
6. 핵심 지침은 프롬프트 시작 또는 끝에 배치 (중간 매몰 방지)
7. 긍정 프레이밍 사용 ("~하지 마라" 대신 "~만 사용하라")
8. 태스크별 최적 CoT 전략 결정 (추론 모델 vs 표준 모델)
9. 구조화 출력 (JSON/YAML) 적극 활용
10. 평가(Eval) 파이프라인 구축 (수동 + 자동)

### 4.3 프롬프트 캐싱 전략

| 제공자 | 접근 방식 | 비용 절감 | 레이턴시 절감 |
|--------|----------|----------|-------------|
| **Anthropic (Claude)** | 수동 제어 (캐시 시점/기간 결정) | 최대 90% | 최대 85% |
| **OpenAI (GPT)** | 자동 캐싱 (기본 활성화) | 약 50% | 상당 |
| **Google (Gemini)** | 토큰 저장 기간/수량 기반 과금 | 상당 | 상당 |

**실제 사례**: PDF 분석 도구 -- 동일 50문서 반복 처리 시 쿼리당 $3 → 캐싱 적용 후 $0.15 (95% 절감)

**핵심 원칙**: "Prefix를 안정적으로 유지하고, 변경 데이터를 Suffix로 밀어내라."

---

## 5. 프롬프트 자동 최적화 도구

### 5.1 DSPy (Stanford NLP)

**현황**: DSPy 2.6 릴리스, DSPy 3.0 접근 중

**핵심 개념**: "프롬프팅이 아닌 프로그래밍으로 LLM을 다루는 프레임워크"
- 선언적(declarative), 모듈식 접근으로 프롬프트 파이프라인을 컴파일 타임에 최적화
- 데이터에서 Few-shot 예시를 자동 부트스트랩
- 성공 메트릭 정의 → 자동 프롬프트 최적화

**성능**:
- 프롬프트 평가 기준 태스크: 46.2% → **64.0%** 정확도 (DSPy 최적화 적용)
- 770M T5, Llama2-13b-chat 등 소형 LLM으로 GPT-3.5 수준의 파이프라인 구축 가능

**DSPy 3.0 전망**: 인간-인-더-루프(human-in-the-loop) 피드백 우선 새 옵티마이저 도입 예정. 추상화, UI/HCI, ML 수준의 패러다임 변화.

**프로덕션 적용**:
- 분류기, RAG 파이프라인, 에이전트 루프 등 다양한 시나리오 지원
- LiteLLM 통합으로 수십 개 LLM 제공자 지원
- `dspy.Reasoning`으로 추론 모델의 네이티브 추론 캡처

### 5.2 TextGrad (Stanford Zou Group)

**핵심 개념**: "텍스트를 통한 자동 미분" -- AI 시스템을 연산 그래프로 취급하고 텍스트 피드백을 그래디언트로 활용

**특징**:
- 인스턴스 수준 정제에 특화 (코딩, 과학 Q&A 등 어려운 태스크)
- LLM 생성 피드백으로 출력을 테스트 타임에 반복 개선
- Nature에 게재

**DSPy vs TextGrad 비교**:

| 측면 | DSPy | TextGrad |
|------|------|----------|
| 접근 | 컴파일 타임 파이프라인 최적화 | 테스트 타임 인스턴스 정제 |
| 강점 | 확장성, 재사용성, 시스템 수준 | 복잡한 단일 태스크 정밀도 |
| 적합 | 프로덕션 파이프라인 | 어려운 개별 문제 |
| 권장 | **상호 보완적 사용으로 최대 성능** |

### 5.3 Anthropic Prompt Improver

- Anthropic Console에서 기존 프롬프트를 자동 개선
- CoT 추론, 구조화 등 베스트 프랙티스 자동 적용
- **30% 정확도 향상** 보고
- 크로스 플랫폼 프롬프트 마이그레이션에 특히 유용 (다른 AI 플랫폼 → Claude 적응)
- API 엔드포인트로도 제공 (`/prompt-tools/improve`)

### 5.4 OpenAI Prompt Optimizer

- 대시보드 내 채팅 인터페이스
- 프롬프트 입력 → 현재 베스트 프랙티스에 따라 최적화 → 반환
- OpenAI 권고: 프로덕션 전 반드시 **평가 및 수동 검토** 필수

### 5.5 평가(Eval) 프레임워크

| 도구 | 유형 | 핵심 기능 |
|------|------|----------|
| **Promptfoo** | 오픈소스 CLI | TDD 기반 프롬프트 테스트, 멀티모델 비교, 레드팀 보안 테스트, CI/CD 통합, 로컬 실행 |
| **Maxim AI** | 엔터프라이즈 | 통합 평가/시뮬레이션/관찰성(observability) 플랫폼 |
| **LangSmith** | LangChain 통합 | 디버깅/모니터링, Prompt Hub |
| **Weights & Biases** | ML 확장 | ML 실험 추적을 LLM 워크플로우로 확장 |
| **Helicone** | 다중 제공자 | OpenAI/Anthropic/Azure/Google/오픈소스 지원 |

**Promptfoo 핵심**: CI/CD 규율을 프롬프트에 적용 -- 자동 테스트, 레드팀, 회귀 테스트. 2025~2026년 매월 활발한 릴리스 지속 중.

---

## 6. 출처 목록

### 학술/연구
- [The Prompt Report: A Systematic Survey (arXiv:2406.06608)](https://arxiv.org/abs/2406.06608)
- [A Systematic Survey of PE in LLMs (arXiv:2402.07927)](https://arxiv.org/abs/2402.07927)
- [A Survey of Automatic PE: Optimization Perspective (arXiv:2502.11560)](https://arxiv.org/html/2502.11560v1)
- [Unleashing PE Potential (Cell Patterns)](https://www.cell.com/patterns/fulltext/S2666-3899(25)00108-4)
- [PE for Structured Data Comparative Evaluation (Preprints.org)](https://www.preprints.org/manuscript/202506.1937)
- [Enhancing Structured Data Generation with GPT-4o (Frontiers)](https://www.frontiersin.org/journals/artificial-intelligence/articles/10.3389/frai.2025.1558938/full)
- [Stronger Models Not Always Stronger Teachers (NAACL 2025)](https://arxiv.org/html/2411.07133v3)
- [DSPy: Compiling Declarative LM Calls (Stanford HAI)](https://hai.stanford.edu/research/dspy-compiling-declarative-language-model-calls-into-state-of-the-art-pipelines)
- [TextGrad: Automatic Differentiation via Text (GitHub)](https://github.com/zou-group/textgrad)
- [Is It Time To Treat Prompts As Code? DSPy Case Study](https://arxiv.org/html/2507.03620v1)

### 기술 블로그 / 가이드
- [Prompt Engineering Guide 2026 (Lakera)](https://www.lakera.ai/blog/prompt-engineering-guide)
- [Prompt Engineering in 2025: The Latest Best Practices (Aakash Gupta)](https://www.news.aakashg.com/p/prompt-engineering)
- [Prompt Engineering Best Practices 2026 (Thomas Wiegold)](https://thomas-wiegold.com/blog/prompt-engineering-best-practices-2026/)
- [Context Engineering Guide 2026 (The AI Corner)](https://www.the-ai-corner.com/p/context-engineering-guide-2026)
- [The 2026 Guide to Prompt Engineering (IBM)](https://www.ibm.com/think/prompt-engineering)
- [A Practitioner's Guide to PE in 2025 (Maxim AI)](https://www.getmaxim.ai/articles/a-practitioners-guide-to-prompt-engineering-in-2025/)
- [10 Best Practices for Production-Grade LLM PE (Latitude)](https://latitude.so/blog/10-best-practices-for-production-grade-llm-prompt-engineering/)
- [Prompt Caching Guide 2025 (Prompt Builder)](https://promptbuilder.cc/blog/prompt-caching-token-economics-2025)
- [Best Practices for LLM PE (Palantir)](https://www.palantir.com/docs/foundry/aip/best-practices-prompt-engineering)
- [LLM Prompt Evaluation Guide 2025 (Keywords AI)](https://www.keywordsai.co/blog/prompt_eval_guide_2025)

### 공식 문서
- [Claude Prompt Engineering Best Practices](https://claude.com/blog/best-practices-for-prompt-engineering)
- [Claude Chain of Thought Docs](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/chain-of-thought)
- [Anthropic Prompt Improver](https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/prompt-improver)
- [Anthropic Prompt Caching](https://www.anthropic.com/news/prompt-caching)
- [OpenAI Prompt Engineering Guide](https://developers.openai.com/api/docs/guides/prompt-engineering/)
- [OpenAI Prompt Optimizer](https://platform.openai.com/docs/guides/prompt-optimizer)
- [DSPy Official (dspy.ai)](https://dspy.ai/)
- [DSPy GitHub (Stanford NLP)](https://github.com/stanfordnlp/dspy)

### Context Engineering 논의
- [Andrej Karpathy on X (Context Engineering)](https://x.com/karpathy/status/1937902205765607626)
- [Context Engineering Guide (Prompting Guide)](https://www.promptingguide.ai/guides/context-engineering-guide)
- [Context Engineering: Bringing Engineering Discipline to Prompts (Substack)](https://addyo.substack.com/p/context-engineering-bringing-engineering)
- [Prompt Engineering is Dead, Long Live Context Engineering (MarTech)](https://martech.org/prompt-engineering-is-dead-long-live-context-engineering/)
- [Context Engineering vs Prompt Engineering (Towards Agentic AI)](https://towardsagenticai.com/context-engineering-vs-prompt-engineering-the-2025-ai-shift/)
- [Simon Willison: Context Engineering](https://simonwillison.net/2025/jun/27/context-engineering/)

### 커뮤니티 / 뉴스
- [Prompt Engineering Playbook for Programmers (HN)](https://news.ycombinator.com/item?id=44182188)
- [Best ChatGPT Prompts Reddit Recommends 2026](https://www.aitooldiscovery.com/guides/chatgpt-prompts-reddit)
- [OpenAI CoT Monitorability Evaluation](https://openai.com/index/evaluating-chain-of-thought-monitorability/)
- [GPT-5 CoT Monitoring for AI Safety (AEI)](https://www.aei.org/technology-and-innovation/reading-the-mind-of-the-machine-why-gpt-5s-chain-of-thought-monitoring-matters-for-ai-safety/)
- [Prompt Engineering Statistics 2026 (SQ Magazine)](https://sqmagazine.co.uk/prompt-engineering-statistics/)
- [Promptfoo GitHub](https://github.com/promptfoo/promptfoo)

### 평가 프레임워크
- [Top Prompt Evaluation Frameworks 2025 (Helicone)](https://www.helicone.ai/blog/prompt-evaluation-frameworks)
- [5 Best Prompt Evaluation Tools 2025 (Braintrust)](https://www.braintrust.dev/articles/best-prompt-evaluation-tools-2025)
- [Top 5 Prompt Engineering Tools 2026 (Maxim AI)](https://www.getmaxim.ai/articles/top-5-prompt-engineering-tools-in-2026/)
- [LLM Evaluation Landscape 2026 (AI Multiple)](https://research.aimultiple.com/llm-eval-tools/)
