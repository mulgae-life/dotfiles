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

## 출처

- OpenAI Prompt Engineering Guide
