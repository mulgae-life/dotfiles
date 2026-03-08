# Few-shot Learning (Multishot Prompting)

입력/출력 예시를 통해 모델 행동을 유도하는 기법입니다.

**용어**:
- **OpenAI**: Few-shot Learning
- **Anthropic**: Multishot Prompting
- **개념**: 동일 (3-5개 예시 권장)

## 기본 구조

```yaml
# Examples
<examples>
<example id="1">
<input>[사용자 입력]</input>
<output>[모델 응답]</output>
</example>

<example id="2">
<input>[사용자 입력]</input>
<output>[모델 응답]</output>
</example>
</examples>
```

## 권장사항

| 항목 | 권장 값 | 이유 |
|------|---------|------|
| 예시 개수 | 3-5개 | 너무 적으면 패턴 학습 부족, 너무 많으면 토큰 낭비 |
| 다양성 | 높음 | Edge case 포함 |
| 구조화 | XML 태그 | 명확한 구분 |
| 일관성 | 필수 | 형식 통일 |

## 실전 예시

### 감정 분류

```yaml
system_prompt: |
  # Identity
  당신은 제품 리뷰 감정 분류기입니다.

  # Instructions
  <rules>
  - 리뷰를 긍정/중립/부정으로 분류합니다
  - 단일 단어로만 응답하세요
  </rules>

  # Examples
  <examples>
  <example id="1">
  <product_review>정말 좋은 제품입니다! 강력 추천합니다.</product_review>
  <classification>긍정</classification>
  </example>

  <example id="2">
  <product_review>배송이 너무 느립니다. 실망했습니다.</product_review>
  <classification>부정</classification>
  </example>

  <example id="3">
  <product_review>가격 대비 괜찮지만 특별하진 않네요.</product_review>
  <classification>중립</classification>
  </example>
  </examples>
```

### 고객 서비스 응답

```yaml
<examples>
<example id="1">
<user_input>가족 요금제 옵션에 대해 알려주세요</user_input>

<assistant_response>
안녕하세요, NewTelco입니다. 무엇을 도와드릴까요?

가족 요금제 옵션에 대해 궁금하시군요. 최신 정보를 확인하겠습니다.

[도구 호출: lookup_policy_document(topic="가족 요금제")]

확인해 본 결과입니다. 저희 가족 요금제는 최대 5개 회선에서 공유 데이터를 제공하며 추가 회선마다 10% 할인을 제공합니다 [가족 요금제 정책](ID-010).

다른 도움이 필요하신가요?
</assistant_response>
</example>
</examples>
```

### JSON 출력 형식

```yaml
<examples>
<example id="1">
<input>이 제품은 정말 훌륭합니다!</input>
<output>
{
  "sentiment": "긍정",
  "confidence": 0.95,
  "keywords": ["훌륭합니다"]
}
</output>
</example>

<example id="2">
<input>배송이 늦었지만 제품은 좋습니다.</input>
<output>
{
  "sentiment": "중립",
  "confidence": 0.72,
  "keywords": ["늦었지만", "좋습니다"]
}
</output>
</example>
</examples>
```

## Edge Case 포함

중요한 경계 케이스를 예시에 포함하세요:

```yaml
<examples>
<!-- 일반 케이스 -->
<example id="1">
<input>이 제품은 최고입니다!</input>
<output>긍정</output>
</example>

<!-- Edge case: 혼합 감정 -->
<example id="2">
<input>가격은 비싸지만 품질은 좋습니다.</input>
<output>중립</output>
</example>

<!-- Edge case: 아이러니/반어법 -->
<example id="3">
<input>정말 "훌륭한" 제품이네요 (배송 1주일 걸림)</input>
<output>부정</output>
</example>
</examples>
```

## XML 속성 활용

예시에 메타데이터 추가:

```yaml
<examples>
<example id="1" difficulty="easy">
<input>정말 좋습니다!</input>
<output>긍정</output>
</example>

<example id="2" difficulty="hard">
<input>기대만큼은 아니지만 나쁘지 않네요.</input>
<output>중립</output>
</example>
</examples>
```

## 주의사항

### ❌ 너무 적은 예시

```yaml
# 나쁜 예: 1개만
<examples>
<example id="1">
<input>좋습니다</input>
<output>긍정</output>
</example>
</examples>
```

**문제**: 패턴 학습 부족

### ❌ 불일치하는 형식

```yaml
# 나쁜 예: 형식 불일치
<example id="1">
<input>좋습니다</input>
<output>긍정</output>
</example>

<example id="2">
<review>나쁩니다</review>  <!-- 태그 이름 다름 -->
<sentiment>부정</sentiment>
</example>
```

**문제**: 모델 혼란

### ✅ 일관성 있는 예시

```yaml
# 좋은 예: 일관된 형식
<examples>
<example id="1">
<product_review>좋습니다</product_review>
<classification>긍정</classification>
</example>

<example id="2">
<product_review>나쁩니다</product_review>
<classification>부정</classification>
</example>
</examples>
```

---

## 모델 세대별 Few-Shot 효과 (2025~2026 연구)

> **주의**: 최신 대형 모델에서는 few-shot의 역할이 "추론 향상"에서 **"포맷 정렬"**로 축소되었습니다.

### 모델별 권장 전략

| 모델 유형 | 권장 전략 | 근거 |
|-----------|----------|------|
| 소형/구형 (<14B) | Few-shot 3~5개 + CoT | 예시가 추론 방법을 가르침 |
| 대형 Instruction-tuned (14B+) | Zero-shot CoT, 필요 시 1~2개 | 2~3개만으로 패턴 학습 충분 |
| Frontier (GPT-5, Claude 4.5+) | **Zero-shot + 포맷 예시 1개** | 예시는 포맷 정렬에만 유효 |
| Reasoning (o1, o3, R1) | **간결한 Zero-shot. Few-shot 금지** | 내부 추론과 외부 CoT 충돌 |
| 긴 컨텍스트 특화 (Gemini 1.5+) | Many-shot(수백 예시) 고려 가능 | NeurIPS 2024 Spotlight |

### 예시 개수별 효과

| 예시 수 | 효과 | 비고 |
|---------|------|------|
| 0 (Zero-shot) | 최신 모델에서 충분 | 포맷 지정은 `<output_format>` 태그로 |
| 1~2 | 가장 큰 정확도 점프 | 비용 대비 효율 최고 |
| 3~5 | 안정적, 수확체감 시작 | 대부분 태스크의 sweet spot |
| 6~8 | 미미한 추가 향상 | 토큰 비용 증가 |
| 8+ | 일부 모델에서 **성능 하락** | Over-prompting 위험 |

### Few-Shot의 알려진 편향

1. **Majority Label Bias**: 예시에 특정 레이블이 많으면 해당 레이블로 편향
2. **Recency Bias**: 마지막 예시의 레이블로 편향
3. **Order Sensitivity**: 예시 순서가 성능을 극적으로 변화시킴

**대응**: 예시 레이블을 균등 분배하고, 순서를 변경하며 테스트

### 실무 권장

- Frontier 모델에서는 **포맷 정렬 용도로만** 1~2개 예시 사용
- 추론 향상이 목적이면 few-shot 대신 `reasoning_effort` 파라미터나 Extended Thinking 사용
- 예시 **품질**이 수량보다 중요 — 2~3개의 고품질 예시 > 8개의 평범한 예시

### 참고 논문

- Cheng et al. (2025) "Zero-shot Can Be Stronger than Few-shot" [arXiv:2506.14641](https://arxiv.org/abs/2506.14641)
- Tang et al. (2025) "The Few-shot Dilemma: Over-prompting LLMs" [arXiv:2509.13196](https://arxiv.org/abs/2509.13196)
- Zhao et al. (2021) "Calibrate Before Use" [ICML 2021](http://proceedings.mlr.press/v139/zhao21c/zhao21c.pdf)

## 출처

- OpenAI Prompt Engineering Guide
- Cheng et al. (2025) [arXiv:2506.14641](https://arxiv.org/abs/2506.14641)
- Tang et al. (2025) [arXiv:2509.13196](https://arxiv.org/abs/2509.13196)
- Agarwal et al. (2024) Many-Shot ICL [NeurIPS 2024](https://arxiv.org/abs/2404.11018)
