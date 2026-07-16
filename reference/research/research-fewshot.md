# Few-Shot vs Zero-Shot 프롬프팅 최신 연구 조사

> 조사일: 2026-03-08
> 범위: 2024~2026 주요 연구 및 논문

---

## 1. "Few-Shot이 항상 좋은 것은 아니다" / "Zero-Shot이 더 낫다"

### 1-1. Revisiting Chain-of-Thought Prompting: Zero-shot Can Be Stronger than Few-shot

- **저자**: Xiang Cheng, Chengyan Pan, Minjun Zhao, Deyang Li, Fangchao Liu, Xinyu Zhang, Xiao Zhang, Yong Liu
- **날짜**: 2025-06-17 제출, 2026-01-08 최종판
- **출처**: [arxiv.org/abs/2506.14641](https://arxiv.org/abs/2506.14641)
- **핵심 발견**:
  - Qwen2.5 시리즈(0.5B~72B), LLaMA3(1B~70B), Gemma2 등 최신 모델에서 **Zero-Shot CoT가 Few-Shot CoT와 동등하거나 더 우수**
  - Qwen2.5-72B 기준 GSM8K: Zero-Shot CoT 95.83% vs 8-Shot CoT 95.75%
  - Qwen2.5-72B 기준 MATH: Zero-Shot 81.64% vs 8-Shot 81.30%
  - **CoT 예시(exemplar)의 역할이 "추론 능력 향상"에서 "출력 포맷 정렬"로 변화**
  - 모델이 예시보다 **지시(instruction)와 테스트 쿼리에 더 많은 attention을 배분**
  - 더 강력한 모델(DeepSeek-R1, Qwen2.5-Max)의 고품질 예시를 사용해도 성능 향상 없음
  - **실용적 권고**: 최신 강력한 모델(14B+)에는 Zero-Shot CoT 사용, 소형/구형 모델(<14B)에만 Few-Shot 유지

### 1-2. The Few-shot Dilemma: Over-prompting Large Language Models

- **저자**: Yongjian Tang, Doruk Tuncel, Christian Koerner, Thomas Runkler
- **날짜**: 2025-09-16
- **출처**: [arxiv.org/abs/2509.13196](https://arxiv.org/abs/2509.13196)
- **핵심 발견**:
  - **과도한 예시(Over-prompting)가 LLM 성능을 오히려 저하**시키는 현상 실증
  - GPT-4o, GPT-3.5-turbo, DeepSeek-V3 등 7개 모델로 검증
  - 특정 도메인에서 예시 수가 최적점을 넘으면 **성능이 점진적으로 하락**
  - 모델별로 하락 폭(decline margin)이 다름
  - TF-IDF + 계층화 샘플링(stratified sampling) 전략으로 최적 예시 수를 찾으면, 더 적은 예시로 SOTA 대비 1% 개선 달성
  - **"많을수록 좋다"는 가정이 틀림을 실증적으로 증명**

---

## 2. Few-Shot 예시 개수에 따른 성능 변화

### 2-1. 최적 예시 개수: 2~5개, 최대 8개

- 다수 연구에서 **1~2개 예시에서 가장 큰 정확도 향상**, 이후 수확체감(diminishing returns)
- 4~5개 이상에서는 토큰 비용 대비 정확도 향상이 미미
- 실용적 권장: **2~5개, 최대 8개** (예시 품질이 수량보다 중요)
- **출처**: [mem0.ai/blog/few-shot-prompting-guide](https://mem0.ai/blog/few-shot-prompting-guide), [prompthub.us/blog/the-few-shot-prompting-guide](https://www.prompthub.us/blog/the-few-shot-prompting-guide)

### 2-2. Many-Shot In-Context Learning (수백~수천 예시)

- **저자**: Rishabh Agarwal, Avi Singh 등 (Google DeepMind)
- **날짜**: 2024-04-17 제출, NeurIPS 2024 Spotlight
- **출처**: [arxiv.org/abs/2404.11018](https://arxiv.org/abs/2404.11018)
- **핵심 발견**:
  - Gemini 1.5 Pro 등 긴 컨텍스트 모델에서 수백~수천 예시 제공 시 **Few-Shot 대비 유의미한 성능 향상**
  - FLORES-200 영어→Bemba 번역: Many-Shot이 1-Shot 대비 15.3% 개선
  - Reinforced ICL(모델 생성 rationale) 및 Unsupervised ICL(입력만 제공) 도입
  - **사전학습 편향(pretraining bias) 극복** 효과 확인
  - 단, **추론 비용이 예시 수에 비례하여 선형 증가**

### 2-3. 요약: 예시 개수별 패턴

| 예시 수 | 효과 | 비고 |
|---------|------|------|
| 0 (Zero-Shot) | 최신 강력 모델에서 충분, Reasoning LLM에서 최적 | 포맷 지정만 별도 |
| 1~2 | 가장 큰 정확도 점프 | 비용 대비 효율 최고 |
| 3~5 | 안정적 성능, 수확체감 시작 | 대부분 태스크의 sweet spot |
| 6~8 | 미미한 추가 향상 | 토큰 비용 증가 |
| 8+ | 일부 모델/태스크에서 **성능 하락** | Over-prompting 위험 |
| 수백~수천 | 긴 컨텍스트 모델에서 재상승 (Many-Shot) | 특수 상황, 비용 높음 |

---

## 3. 최신 모델(GPT-5, Claude 4, Reasoning LLM)에서 Few-Shot 효과 변화

### 3-1. Frontier 모델: Few-Shot의 역할이 "포맷 정렬"로 축소

- **2026년 Context Engineering Guide** 에서 명시: **"Few-shot chain-of-thought는 더 이상 추론을 개선하지 않는다. 유일한 역할은 포맷 정렬(format alignment)"**
- GPT-5.2, Claude 4.6, Gemini 3.1 등에서 **컨텍스트 엔지니어링**(어떤 정보를 둘러싸느냐)이 예시 수보다 중요
- 2024-2025 프롬프팅 전략이 2026에서는 **"오히려 결과를 악화"**시킬 수 있음
- **출처**: [the-ai-corner.com/p/context-engineering-guide-2026](https://www.the-ai-corner.com/p/context-engineering-guide-2026)

### 3-2. Reasoning/Thinking 모델: Few-Shot이 성능을 저하

- **OpenAI o1/o3, DeepSeek-R1** 등 Thinking 모델은 내부적으로 CoT를 수행
- **Few-Shot 예시가 성능을 낮춤**: "OpenAI o1-preview 모델은 few-shot 예시를 제공하면 오히려 성능이 하락"
- **명시적 CoT 프롬프팅도 유해**: 이미 내부 추론을 하는 모델에 step-by-step을 강제하면 고유 추론 과정과 충돌
- **권장사항**: 간결한 Zero-Shot 프롬프트 사용, 필요 시 1~2개만
- **출처**: [helicone.ai/blog/prompt-thinking-models](https://www.helicone.ai/blog/prompt-thinking-models)

### 3-3. 대형 모델(GPT-4+, Claude 3.5+, LLaMA 3 70B+)

- 이미 **2~3개 예시만으로 복잡한 패턴을 학습** 가능
- Few-Shot의 한계 효용이 이전 세대 대비 급격히 감소
- **출처**: [mem0.ai/blog/few-shot-prompting-guide](https://mem0.ai/blog/few-shot-prompting-guide)

---

## 4. Few-Shot의 부작용: Bias, Contamination, Sensitivity

### 4-1. Calibrate Before Use: Few-Shot의 3대 편향

- **저자**: Tony Z. Zhao, Eric Wallace, Shi Feng, Dan Klein, Sameer Singh
- **날짜**: 2021 (ICML 2021), 후속 연구 2025까지 지속
- **출처**: [proceedings.mlr.press/v139/zhao21c](http://proceedings.mlr.press/v139/zhao21c/zhao21c.pdf)
- **3대 편향**:
  1. **Majority Label Bias**: 예시에 특정 레이블이 많으면 해당 레이블로 편향
  2. **Recency Bias**: 프롬프트 끝에 가까운 예시의 레이블로 편향 (예: 마지막 예시가 "Negative"면 Negative로 예측 경향)
  3. **Common Token Bias**: 학습 데이터에서 자주 등장하는 토큰/레이블로 편향
- **해결책**: Contextual Calibration - content-free 입력("N/A")으로 편향 분포 추정 후 보정
- **2025 후속**: Normalized Contextual Calibration(NCC)으로 F1 최대 10% 개선

### 4-2. Task Contamination: Language Models May Not Be Few-Shot Anymore

- **저자**: Changmao Li, Jeffrey Flanigan
- **날짜**: 2023-12-26 제출, AAAI 2024 수록
- **출처**: [arxiv.org/abs/2312.16337](https://arxiv.org/abs/2312.16337)
- **핵심 발견**:
  - LLM 학습 데이터에 평가 데이터가 포함(Task Contamination)되어 **Few-Shot 성능이 인위적으로 부풀려짐**
  - 학습 데이터 생성 이전에 공개된 데이터셋에서 **유의미하게 높은 성능**
  - 학습 데이터 이후 공개된 데이터셋에서는 성능 하락
  - **오염 가능성이 없는 분류 태스크에서, LLM은 Zero-Shot/Few-Shot 모두 단순 다수결 기준선(majority baseline)을 거의 넘지 못함**
  - 추출된 예시 수와 모델 정확도 간 강한 상관관계(R=.88)

### 4-3. Order & Token Sensitivity (선택 편향)

- **저자**: Sheng-Lun Wei, Cheng-Kuang Wu, Hen-Hsen Huang, Hsin-Hsi Chen
- **날짜**: 2024-06-05, ACL 2024 Long Findings
- **출처**: [arxiv.org/abs/2406.03009](https://arxiv.org/abs/2406.03009)
- **핵심 발견**:
  1. **Order Sensitivity**: 선택지 순서에 따라 LLM 성능이 유의미하게 변동
  2. **Token Sensitivity**: 선택지를 표현하는 토큰(A/B/C vs 1/2/3)이 내용과 무관하게 모델 선택에 영향
  3. Few-Shot 예시의 순서가 downstream 태스크 성능을 **극적으로 변화**시킴
- **실무 영향**: Few-Shot 설계 시 예시 순서와 레이블 토큰 선택에 주의 필요

### 4-4. Position Bias in LLM Recommendations

- **출처**: [arxiv.org/abs/2508.02020](https://arxiv.org/abs/2508.02020) (2025-08)
- In-context 예시의 위치(position)가 모델 출력에 불균형적으로 영향
- 개별 항목의 관련성과 무관하게 위치에 의존하는 편향 확인

---

## 5. Zero-Shot CoT vs Few-Shot CoT 비교

### 5-1. 역사적 맥락

- **Kojima et al. (2022)** "Large Language Models are Zero-Shot Reasoners" ([arxiv.org/abs/2205.11916](https://arxiv.org/abs/2205.11916))
  - "Let's think step by step" 한 줄 추가만으로 Zero-Shot 추론 성능 대폭 향상
  - 산술, 기호 추론 등 다양한 벤치마크에서 검증

### 5-2. 2025~2026: Zero-Shot CoT >= Few-Shot CoT (최신 모델)

| 모델 세대 | Few-Shot CoT 효과 | Zero-Shot CoT 효과 | 승자 |
|-----------|-------------------|-------------------|------|
| GPT-3, LLaMA-7B 등 초기 | 필수적, 큰 성능 향상 | 제한적 | Few-Shot CoT |
| GPT-4, Qwen2.5-14B+ | 미미한 향상 | 동등 또는 우위 | Zero-Shot CoT |
| Reasoning LLM (o1, R1) | **성능 하락** | 최적 (또는 프롬프트 불필요) | Zero-Shot |
| GPT-5, Claude 4.5+ | 포맷 정렬만 | 추론에 충분 | Zero-Shot CoT |

### 5-3. 핵심 메커니즘 변화

- **초기 모델**: 예시가 "추론 방법"을 가르침 (reasoning scaffold)
- **최신 모델**: 예시는 "출력 형태"만 보여줌 (format template)
- **Reasoning LLM**: 내부적으로 이미 추론 → 외부 예시가 간섭(interference)

### 5-4. Zero-Shot Verification-Guided CoT (신규)

- 구조화된 단계별 출력 + 자기 검증(self-verification) 프롬프트
- 중간 단계의 정확성을 반복적으로 분류하여 오류 전파 감소
- 예시 없이도 추론 품질 유지 가능

---

## 종합 결론 및 실무 권장사항

### 핵심 트렌드

1. **모델이 강해질수록 Few-Shot의 필요성 감소**: 최신 Frontier 모델에서 Few-Shot의 역할이 "추론 향상"에서 "포맷 정렬"로 축소
2. **Reasoning LLM에서는 Few-Shot이 유해**: o1, o3, DeepSeek-R1 등에서는 Zero-Shot이 최적
3. **예시 수보다 예시 품질이 중요**: 2~3개의 고품질 예시 > 8개의 평범한 예시
4. **과도한 예시는 성능 저하 초래**: Over-prompting 현상 실증
5. **Few-Shot 성능의 일부는 데이터 오염에 기인**: Task Contamination으로 인한 인위적 성능 부풀림

### 모델별 권장 전략

| 모델 유형 | 권장 전략 |
|-----------|----------|
| 소형/구형 (<14B) | Few-Shot 3~5개 + CoT |
| 대형 Instruction-tuned (14B+) | Zero-Shot CoT, 필요 시 1~2개 예시 |
| Frontier (GPT-5, Claude 4.5+) | Zero-Shot + 포맷 예시 1개 |
| Reasoning (o1, o3, R1) | 간결한 Zero-Shot, Few-Shot/CoT 금지 |
| 긴 컨텍스트 특화 (Gemini 1.5+) | Many-Shot(수백 예시) 고려 가능 |

---

## 참고 문헌 전체 목록

1. Cheng et al. (2025). "Revisiting Chain-of-Thought Prompting: Zero-shot Can Be Stronger than Few-shot" - [arxiv.org/abs/2506.14641](https://arxiv.org/abs/2506.14641)
2. Tang et al. (2025). "The Few-shot Dilemma: Over-prompting Large Language Models" - [arxiv.org/abs/2509.13196](https://arxiv.org/abs/2509.13196)
3. Agarwal et al. (2024). "Many-Shot In-Context Learning" (NeurIPS 2024 Spotlight) - [arxiv.org/abs/2404.11018](https://arxiv.org/abs/2404.11018)
4. Li & Flanigan (2023). "Task Contamination: Language Models May Not Be Few-Shot Anymore" (AAAI 2024) - [arxiv.org/abs/2312.16337](https://arxiv.org/abs/2312.16337)
5. Zhao et al. (2021). "Calibrate Before Use: Improving Few-Shot Performance of Language Models" (ICML 2021) - [proceedings.mlr.press/v139/zhao21c](http://proceedings.mlr.press/v139/zhao21c/zhao21c.pdf)
6. Wei et al. (2024). "Unveiling Selection Biases: Exploring Order and Token Sensitivity in LLMs" (ACL 2024) - [arxiv.org/abs/2406.03009](https://arxiv.org/abs/2406.03009)
7. Kojima et al. (2022). "Large Language Models are Zero-Shot Reasoners" - [arxiv.org/abs/2205.11916](https://arxiv.org/abs/2205.11916)
8. DeepSeek-AI (2025). "DeepSeek-R1: Incentivizing Reasoning Capability in LLMs via Reinforcement Learning" - [arxiv.org/abs/2501.12948](https://arxiv.org/abs/2501.12948)
9. Position Bias in LLM Recommendations (2025) - [arxiv.org/abs/2508.02020](https://arxiv.org/abs/2508.02020)
10. Context Engineering Guide 2026 - [the-ai-corner.com/p/context-engineering-guide-2026](https://www.the-ai-corner.com/p/context-engineering-guide-2026)
11. Few-Shot Prompting Guide 2026 - [mem0.ai/blog/few-shot-prompting-guide](https://mem0.ai/blog/few-shot-prompting-guide)
12. How to Prompt Thinking Models (DeepSeek R1, OpenAI o3) - [helicone.ai/blog/prompt-thinking-models](https://www.helicone.ai/blog/prompt-thinking-models)
