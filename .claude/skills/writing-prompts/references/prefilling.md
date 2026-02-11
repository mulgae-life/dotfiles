# Prefilling (Anthropic Claude 특화)

Anthropic Claude만의 고유 기능으로, `assistant` 메시지를 미리 채워 출력을 제어합니다.

## 개요

Prefilling은 **Anthropic Claude에서만 사용 가능**하며, OpenAI GPT에는 없는 기능입니다.

Assistant 메시지를 미리 채워두면:
- JSON/XML 출력 강제
- 프리앰블 건너뛰기
- 역할극 캐릭터 유지
- 특정 형식으로 시작 유도

**주의**: Prefilling은 non-extended thinking 모드에서만 사용 가능합니다.

## 사용 방법

```python
import anthropic

client = anthropic.Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "What is your favorite color?"},
        {"role": "assistant", "content": "As an AI assistant, I don't have a favorite color, But if I had to pick, it would be green because"}  # Prefill
    ]
)
```

**경고**: Prefill 내용은 **trailing whitespace로 끝나면 안 됩니다**.
- ❌ `"As an AI assistant, I "` (끝에 공백)
- ✅ `"As an AI assistant, I"`

## 활용 사례

### 1. JSON 출력 강제 ⭐

**문제**: Claude가 JSON 앞에 설명을 붙임

일반 프롬프트:
```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "Extract name, size, price as JSON: {{PRODUCT}}"}
    ]
)
```

출력:
```
Here's the extracted information in JSON format:

```json
{
  "name": "SmartHome Mini",
  "size": "5 inches",
  "price": "$49.99"
}
```

I've extracted the following details...
```

**해결**: `{` prefill

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "Extract name, size, price as JSON: {{PRODUCT}}"},
        {"role": "assistant", "content": "{"}  # Prefill
    ]
)
```

출력:
```json
"name": "SmartHome Mini",
"size": "5 inches",
"price": "$49.99"
}
```

**장점**:
- 프리앰블 없음
- 순수 JSON만 출력
- 파싱 용이

**참고**: 엄격한 JSON 스키마가 필요하면 [Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) 사용 권장

### 2. 역할극 캐릭터 유지

**문제**: 긴 대화에서 캐릭터가 깨짐

50번째 대화:
```python
# 이전 49번은 Sherlock Holmes 역할극
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        # ... 이전 49개 메시지 ...
        {"role": "user", "content": "What do you deduce about this shoe?"}
    ]
)
```

출력:
```
As an AI assistant, I would be happy to analyze the image...
```
→ 캐릭터 깨짐!

**해결**: `[캐릭터명]` prefill

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    system="You are Sherlock Holmes",  # system prompt와 함께 사용
    messages=[
        # ... 이전 49개 메시지 ...
        {"role": "user", "content": "What do you deduce about this shoe?"},
        {"role": "assistant", "content": "[Sherlock Holmes]"}  # Prefill
    ]
)
```

출력:
```
[Sherlock Holmes] Ah, what have we here? A most curious specimen, Watson!
Let us examine this shoe with a discerning eye. The mud, you see, is not
your common London clay, but rather the distinctive reddish hue of the
iron-rich soil found only in the environs of Hampstead Heath...
```
→ 캐릭터 유지!

### 3. XML 출력 강제

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "Analyze this data: {{DATA}}"},
        {"role": "assistant", "content": "<analysis>"}  # Prefill
    ]
)
```

출력:
```xml
<analysis>
  <summary>...</summary>
  <findings>...</findings>
  <recommendations>...</recommendations>
</analysis>
```

### 4. 리스트 출력 강제

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "List top 3 benefits"},
        {"role": "assistant", "content": "1."}  # Prefill
    ]
)
```

출력:
```
1. Benefit A
2. Benefit B
3. Benefit C
```

### 5. 특정 형식으로 시작

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "Summarize this article"},
        {"role": "assistant", "content": "**Summary:**"}  # Prefill
    ]
)
```

출력:
```markdown
**Summary:**
This article discusses...
```

## 공통 Prefilling 패턴

### JSON
```python
{"role": "assistant", "content": "{"}
```

### XML
```python
{"role": "assistant", "content": "<analysis>"}
```

### 캐릭터 유지
```python
{"role": "assistant", "content": "[캐릭터명]"}
```

### 프리앰블 건너뛰기
```python
{"role": "assistant", "content": "1."}  # 바로 리스트 시작
```

### 특정 톤 강제
```python
{"role": "assistant", "content": "물론입니다!"}  # 친근한 톤
{"role": "assistant", "content": "네, 말씀드리겠습니다."}  # 격식체 톤
```

## 모범 사례

### ✅ 좋은 사용

1. **짧게 유지** - 몇 글자 또는 몇 단어면 충분
   ```python
   {"role": "assistant", "content": "{"}  # 좋음
   ```

2. **명확한 명령과 함께**
   ```python
   # Prefill + 명확한 지시
   messages=[
       {"role": "user", "content": "Extract as JSON: {{DATA}}"},
       {"role": "assistant", "content": "{"}
   ]
   ```

3. **System prompt와 결합**
   ```python
   system="You are Sherlock Holmes",
   messages=[
       {"role": "user", "content": "..."},
       {"role": "assistant", "content": "[Sherlock Holmes]"}
   ]
   ```

### ❌ 피해야 할 것

1. **Trailing whitespace**
   ```python
   {"role": "assistant", "content": "{ "}  # ❌ 에러
   ```

2. **과도하게 긴 prefill**
   ```python
   # ❌ 너무 김
   {"role": "assistant", "content": "Here is a detailed analysis of..."}
   ```

3. **Prefill 없이도 충분한 경우**
   ```python
   # 간단한 작업은 명령만으로 충분
   {"role": "user", "content": "Answer briefly"}  # Prefill 불필요
   ```

4. **Extended thinking 모드와 함께**
   ```python
   # ❌ Extended thinking은 prefilling 미지원
   thinking={"type": "enabled"},
   messages=[..., {"role": "assistant", "content": "{"}]  # 작동 안 함
   ```

## 사용 시기

### ✅ Prefilling 사용

- JSON/XML 등 특정 형식 강제 필요
- 프리앰블 제거하여 파싱 간소화
- 긴 대화에서 캐릭터 유지
- 특정 톤/스타일로 시작 유도

### ❌ Prefilling 불필요

- 간단한 작업 (명령만으로 충분)
- Claude의 자연스러운 설명을 원할 때
- Extended thinking 사용 시
- Structured Outputs가 더 적합한 경우 (엄격한 JSON 스키마)

## OpenAI 대안

OpenAI GPT는 prefilling을 지원하지 않습니다. 대신:

```python
# OpenAI에서는 명령으로 제어
response = client.responses.create(
    model="gpt-5",
    instructions="""
    Output ONLY valid JSON. Do not include any preamble or explanation.
    Start directly with { and end with }.
    """,
    input="Extract data: {{DATA}}"
)
```

**차이점**:
- Claude: Prefill로 강제 (100% 보장)
- GPT: 명령으로 유도 (가끔 실패할 수 있음)

## 요약

| 항목 | 설명 |
|------|------|
| **플랫폼** | Anthropic Claude만 (OpenAI ❌) |
| **용도** | JSON/XML 강제, 프리앰블 제거, 캐릭터 유지 |
| **방법** | `assistant` 메시지에 시작 텍스트 prefill |
| **주의** | Trailing whitespace 금지, Extended thinking 미지원 |
| **길이** | 짧게 (몇 글자~몇 단어) |

**핵심**: "작은 힌트로 큰 효과" - 몇 글자만으로 출력 형식을 완전히 제어
