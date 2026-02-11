# Long Context 최적화 (Anthropic Claude 특화)

Claude의 200K 토큰 컨텍스트 윈도우를 효과적으로 활용하는 기법입니다.

## 핵심 원칙 (성능 30% 향상)

### 1. 긴 문서는 맨 위에 배치 ⭐

**20K+ 토큰의 긴 문서는 프롬프트 맨 위에 배치**하면 성능이 최대 **30% 향상**됩니다.

❌ **나쁜 예**:
```
질문: 이 보고서의 핵심 내용은?

<document>
{{50K_TOKEN_REPORT}}
</document>
```

✅ **좋은 예**:
```
<document>
{{50K_TOKEN_REPORT}}
</document>

위 보고서의 핵심 내용을 요약하세요.
```

**구조**:
```
1. 긴 문서들 (맨 위)
2. 지시사항
3. 예시
4. 질문/쿼리 (맨 아래)
```

### 2. XML 태그로 문서 구조화

다중 문서는 `<document>`, `<document_content>`, `<source>` 태그로 명확히 구분합니다.

```xml
<documents>
  <document index="1">
    <source>annual_report_2023.pdf</source>
    <document_content>
      {{ANNUAL_REPORT}}
    </document_content>
  </document>

  <document index="2">
    <source>competitor_analysis_q2.xlsx</source>
    <document_content>
      {{COMPETITOR_ANALYSIS}}
    </document_content>
  </document>

  <document index="3">
    <source>market_research.docx</source>
    <document_content>
      {{MARKET_RESEARCH}}
    </document_content>
  </document>
</documents>

위 3개 문서를 분석하여 Q3 전략을 수립하세요.
```

**장점**:
- 문서 경계 명확
- 인덱스/출처로 쉽게 참조
- 메타데이터 추가 가능
- Claude의 파싱 정확도 향상

### 3. 인용 기반 Grounding

긴 문서 작업 시, **답변 전에 관련 인용을 먼저 추출**하도록 요청합니다.

```xml
You are an AI physician's assistant. Your task is to help doctors diagnose
possible patient illnesses.

<documents>
  <document index="1">
    <source>patient_symptoms.txt</source>
    <document_content>
      {{PATIENT_SYMPTOMS}}
    </document_content>
  </document>

  <document index="2">
    <source>patient_records.txt</source>
    <document_content>
      {{PATIENT_RECORDS}}
    </document_content>
  </document>

  <document index="3">
    <source>patient01_appt_history.txt</source>
    <document_content>
      {{PATIENT01_APPOINTMENT_HISTORY}}
    </document_content>
  </document>
</documents>

Find quotes from the patient records and appointment history that are relevant
to diagnosing the patient's reported symptoms. Place these in <quotes> tags.

Then, based on these quotes, list all information that would help the doctor
diagnose the patient's symptoms. Place your diagnostic information in <info> tags.
```

**왜 효과적인가?**:
- Claude가 먼저 관련 부분을 식별
- "노이즈" 걸러냄
- 환각(hallucination) 감소
- 추적 가능한 추론

## 실전 패턴

### 패턴 1: 법률 문서 분석

```xml
<contracts>
  <contract id="1">
    <source>vendor_agreement_2024.pdf</source>
    <content>{{CONTRACT_1}}</content>
  </contract>
  <contract id="2">
    <source>saas_license.pdf</source>
    <content>{{CONTRACT_2}}</content>
  </contract>
  <contract id="3">
    <source>nda.pdf</source>
    <content>{{CONTRACT_3}}</content>
  </contract>
</contracts>

Review all contracts for non-standard liability clauses.
1. First, quote relevant sections in <quotes> tags
2. Then analyze risks in <analysis> tags
3. Finally, provide recommendations in <recommendations> tags
```

### 패턴 2: 연구 논문 종합

```xml
<papers>
  <paper id="1">
    <title>{{TITLE_1}}</title>
    <authors>{{AUTHORS_1}}</authors>
    <content>{{PAPER_1}}</content>
  </paper>
  <paper id="2">
    <title>{{TITLE_2}}</title>
    <authors>{{AUTHORS_2}}</authors>
    <content>{{PAPER_2}}</content>
  </paper>
  <!-- More papers -->
</papers>

Synthesize findings on "climate change impact on agriculture" from these papers.
1. Extract key quotes from each paper in <quotes> tags
2. Synthesize common themes in <synthesis> tags
3. Identify contradictions or gaps in <gaps> tags
```

### 패턴 3: 코드베이스 리뷰

```xml
<codebase>
  <file path="src/auth.py">{{AUTH_CODE}}</file>
  <file path="src/database.py">{{DB_CODE}}</file>
  <file path="src/api.py">{{API_CODE}}</file>
  <file path="tests/test_auth.py">{{TEST_CODE}}</file>
</codebase>

Review authentication implementation for security vulnerabilities.
1. Quote suspicious code in <suspicious_code> tags
2. Explain vulnerabilities in <vulnerabilities> tags
3. Suggest fixes in <fixes> tags
```

### 패턴 4: 계층적 문서 구조

```xml
<project>
  <specifications>
    <functional_requirements>{{FUNC_REQS}}</functional_requirements>
    <technical_requirements>{{TECH_REQS}}</technical_requirements>
  </specifications>

  <implementation>
    <codebase>{{CODE}}</codebase>
    <tests>{{TESTS}}</tests>
  </implementation>

  <documentation>
    <user_guide>{{USER_GUIDE}}</user_guide>
    <api_docs>{{API_DOCS}}</api_docs>
  </documentation>
</project>

Review the entire project for consistency between specifications, implementation,
and documentation. Flag any discrepancies.
```

## 고급 기법

### 1. 단계별 추출 후 분석

```
<large_dataset>
{{100K_TOKEN_DATASET}}
</large_dataset>

Step 1: Extract all entries related to "customer churn" and place them in
<churn_data> tags.

Step 2: Analyze the extracted churn data and provide insights in <analysis> tags.
```

**효과**:
- 먼저 관련 데이터만 추출
- 그 다음 집중 분석
- 노이즈 감소

### 2. Citation-Based Reasoning

```xml
<documents>
{{MULTIPLE_RESEARCH_PAPERS}}
</documents>

<instructions>
1. First, extract relevant quotes from the papers in <quotes> tags
2. Then, synthesize findings in <synthesis> tags
3. Finally, provide recommendations in <recommendations> tags

Always cite document index and approximate location for each quote.
</instructions>
```

### 3. Focused Extraction

```xml
<financial_data>
{{200K_TOKEN_FINANCIAL_STATEMENTS}}
</financial_data>

Extract only Q4 revenue data by region in <q4_revenue> tags.
Then analyze trends in <trends> tags.
```

## 모범 사례

### ✅ 좋은 예

1. **문서 우선 배치**
   ```xml
   <documents>{{DOCS}}</documents>

   질문: ...
   ```

2. **명확한 구조화**
   ```xml
   <document index="1">
     <title>보고서 A</title>
     <source>report_a.pdf</source>
     <content>{{CONTENT}}</content>
   </document>
   ```

3. **인용 먼저, 분석 나중**
   ```
   1. Quote relevant sections
   2. Analyze based on quotes
   ```

### ❌ 나쁜 예

1. **질문이 먼저**
   ```
   질문: ...

   <documents>{{DOCS}}</documents>  # ❌
   ```

2. **구조 없이 섞기**
   ```
   Here's doc 1: {{DOC1}}
   And doc 2: {{DOC2}}
   Now analyze...  # ❌ 경계 불명확
   ```

3. **인용 없이 바로 분석**
   ```
   <documents>{{DOCS}}</documents>

   Analyze this.  # ❌ 인용 단계 생략
   ```

## 성능 최적화

### 토큰 예산 관리

- Claude 3: 200K 토큰 컨텍스트
- 출력용 ~10% 예약 (20K)
- 입력용 ~180K 사용 가능

**권장 구조**:
```
- 문서: 150K 토큰
- 지시사항: 5K 토큰
- 예시: 5K 토큰
- 질문: 1K 토큰
- 출력: 20K 토큰 예약
```

### Prompt Caching 활용

정적 문서는 캐시 가능:

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    system=[
        {
            "type": "text",
            "text": "You are a legal analyst",
            "cache_control": {"type": "ephemeral"}
        }
    ],
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type": "text",
                    "text": "<documents>{{STATIC_DOCS}}</documents>",
                    "cache_control": {"type": "ephemeral"}  # 캐시됨
                },
                {
                    "type": "text",
                    "text": "Analyze contract X"  # 매번 변경
                }
            ]
        }
    ]
)
```

**효과**: 비용 절감, 응답 속도 향상

## 공통 함정

### ❌ 피해야 할 것

1. 쿼리를 맨 위에 배치
2. 문서 간 명확한 경계 없음
3. 구조나 메타데이터 없음
4. 복잡한 질문에서 인용 단계 생략

### ✅ 해야 할 것

1. 문서 맨 위, 쿼리 맨 아래
2. 명확한 XML 구조와 메타데이터
3. 복잡한 분석은 인용 기반 추론
4. 다단계 분석을 서브태스크로 분해

## OpenAI와의 차이

| 항목 | OpenAI GPT | Anthropic Claude |
|------|------------|------------------|
| **Long Context 가이드** | 일반적 사용 | ✅ 상세 최적화 가이드 |
| **문서 배치** | 특별한 권장사항 없음 | ✅ 맨 위 배치 (30%↑) |
| **구조화** | XML 권장 | ✅ XML + 메타데이터 강조 |
| **인용 패턴** | - | ✅ Quote-first 패턴 |

**OpenAI 사용 시**:
- 문서 배치 순서보다 명확한 구조화에 집중
- XML 태그는 여전히 유효
- 인용 기반 추론도 효과적

## 요약

| 원칙 | 방법 | 효과 |
|------|------|------|
| **문서 우선** | 긴 문서를 맨 위 배치 | 성능 30% 향상 |
| **XML 구조화** | `<document>`, `<source>` 태그 | 파싱 정확도↑ |
| **인용 grounding** | 답변 전 인용 먼저 추출 | 환각↓, 추적성↑ |
| **단계별 분석** | 추출 → 분석 → 종합 | 노이즈↓, 집중도↑ |

**핵심**: "문서 먼저, 질문 나중" + "인용으로 grounding"
