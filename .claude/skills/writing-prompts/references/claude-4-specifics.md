# Claude 4.x 특화 기법

Claude 4.x (Sonnet 4.5, Opus 4.5, Haiku 4.5) 모델 특화 베스트 프랙티스입니다.

## 핵심 특징

Claude 4.x 모델은 이전 세대보다 **정확한 지시 따르기**에 훈련되었습니다.

### 이전 모델과의 차이
- **더 명시적 지시 필요**: "above and beyond" 동작을 원하면 명시적 요청 필요
- **세부사항에 민감**: 예시와 디테일을 정확히 따름
- **더 간결한 스타일**: 불필요한 장황함 줄어듦

## 일반 원칙

### 1. 명시적 지시

❌ **덜 효과적**:
```
Create an analytics dashboard
```

✅ **더 효과적**:
```
Create an analytics dashboard. Include as many relevant features and interactions
as possible. Go beyond the basics to create a fully-featured implementation.
```

### 2. 맥락 제공

"왜"를 설명하면 Claude가 목표를 더 잘 이해합니다.

❌ **덜 효과적**:
```
NEVER use ellipses
```

✅ **더 효과적**:
```
Your response will be read aloud by a text-to-speech engine, so never use
ellipses since the text-to-speech engine will not know how to pronounce them.
```

### 3. 예시와 디테일 검증

Claude 4.x는 예시를 정확히 따릅니다. 예시가 원하는 동작과 일치하는지 확인하세요.

## Extended Thinking (Claude 4.x)

### Context Awareness

Claude 4.5는 **컨텍스트 윈도우** (토큰 예산)를 추적할 수 있습니다.

```text
Your context window will be automatically compacted as it approaches its limit,
allowing you to continue working indefinitely from where you left off. Therefore,
do not stop tasks early due to token budget concerns. As you approach your token
budget limit, save your current progress and state to memory before the context
window refreshes. Always be as persistent and autonomous as possible and complete
tasks fully, even if the end of your budget is approaching. Never artificially
stop any task early regardless of the context remaining.
```

### Multi-Window Workflows

여러 컨텍스트 윈도우에 걸친 작업:

1. **첫 윈도우에서 프레임워크 설정**
   - 테스트 작성
   - 설정 스크립트 생성

2. **구조화된 형식으로 테스트 기록**
   ```json
   {
     "tests": [
       {"id": 1, "name": "auth_flow", "status": "passing"},
       {"id": 2, "name": "user_mgmt", "status": "failing"}
     ]
   }
   ```

3. **QoL 도구 설정**
   - `init.sh`: 서버 시작, 테스트 실행, 린터 등

4. **Git으로 상태 추적**
   - Git 로그로 진행 상황 확인
   - 체크포인트 복원 가능

5. **검증 도구 제공**
   - Playwright MCP 서버
   - Computer use capabilities

### State Management

```json
// tests.json (구조화된 상태)
{
  "tests": [
    {"id": 1, "name": "authentication_flow", "status": "passing"},
    {"id": 2, "name": "user_management", "status": "failing"}
  ],
  "total": 200,
  "passing": 150,
  "failing": 25
}
```

```text
// progress.txt (비구조화된 진행 노트)
Session 3 progress:
- Fixed authentication token validation
- Updated user model to handle edge cases
- Next: investigate user_management test failures
- Note: Do not remove tests (could lead to missing functionality)
```

## 커뮤니케이션 스타일

Claude 4.5는 더 간결하고 자연스럽습니다:

- **직접적**: 사실 기반 진행 보고
- **대화적**: 더 유창하고 구어체적
- **덜 장황**: 효율성을 위해 요약 생략 가능

**Verbosity 조절**:
```text
After completing a task that involves tool use, provide a quick summary of the
work you've done.
```

## Tool 사용 패턴

### 명시적 지시 필요

❌ **덜 효과적** (제안만):
```
Can you suggest some changes to improve this function?
```

✅ **더 효과적** (실제 변경):
```
Change this function to improve its performance.
```

Or:
```
Make these edits to the authentication flow.
```

### Proactive Action 유도

```text
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's
intent is unclear, infer the most useful likely action and proceed, using tools
to discover any missing details instead of guessing.
</default_to_action>
```

### Conservative Action 유도

```text
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed. When
the user's intent is ambiguous, default to providing information, doing research,
and providing recommendations rather than taking action.
</do_not_act_before_instructions>
```

## 출력 형식 제어

### 1. 긍정형 지시

❌ Instead of:
```
Do not use markdown in your response
```

✅ Try:
```
Your response should be composed of smoothly flowing prose paragraphs.
```

### 2. XML 형식 지시

```
Write the prose sections of your response in <smoothly_flowing_prose_paragraphs> tags.
```

### 3. Markdown 최소화

```text
<avoid_excessive_markdown_and_bullet_points>
When writing reports, documents, technical explanations, analyses, or any long-form
content, write in clear, flowing prose using complete paragraphs and sentences. Use
standard paragraph breaks for organization and reserve markdown primarily for
`inline code`, code blocks (```...```), and simple headings (### and ###). Avoid
using **bold** and *italics*.

DO NOT use ordered lists (1. ...) or unordered lists (*) unless: a) you're
presenting truly discrete items where a list format is the best option, or b)
the user explicitly requests a list or ranking

Instead of listing items with bullets or numbers, incorporate them naturally into
sentences. Your goal is readable, flowing text that guides the reader naturally
through ideas rather than fragmenting information into isolated points.
</avoid_excessive_markdown_and_bullet_points>
```

## 특수 기능

### 연구 및 정보 수집

```text
Search for this information in a structured way. As you gather data, develop
several competing hypotheses. Track your confidence levels in your progress notes
to improve calibration. Regularly self-critique your approach and plan. Update a
hypothesis tree or research notes file to persist information and provide
transparency. Break down this complex research task systematically.
```

### Subagent Orchestration

Claude 4.5는 자동으로 subagent에 작업을 위임합니다.

**Conservative 설정**:
```text
Only delegate to subagents when the task clearly benefits from a separate agent
with a new context window.
```

### Parallel Tool Calling

Claude 4.x는 병렬 도구 실행에 뛰어납니다.

**최대 효율**:
```text
<use_parallel_tool_calls>
If you intend to call multiple tools and there are no dependencies between the
tool calls, make all of the independent tool calls in parallel. Prioritize calling
tools simultaneously whenever the actions can be done in parallel rather than
sequentially. For example, when reading 3 files, run 3 tool calls in parallel to
read all 3 files into context at the same time.
</use_parallel_tool_calls>
```

**순차 실행**:
```text
Execute operations sequentially with brief pauses between each step to ensure stability.
```

### Vision 개선 (Claude Opus 4.5)

이미지 처리 및 데이터 추출 향상. **Crop tool**을 제공하면 성능 더 향상:

```python
# Crop tool/skill 제공
# Claude가 이미지의 관련 영역을 "줌인"할 수 있음
```

### Frontend Design

Claude 4.x는 우수한 프론트엔드 디자인 능력이 있지만, 가이드 없이는 "AI slop" 심미성으로 수렴합니다.

**개선**:
```text
<frontend_aesthetics>
You tend to converge toward generic outputs. In frontend design, this creates
the "AI slop" aesthetic. Avoid this: make creative, distinctive frontends.

Focus on:
- Typography: Beautiful, unique fonts (not Arial, Inter)
- Color & Theme: Cohesive aesthetic with CSS variables
- Motion: CSS animations for micro-interactions
- Backgrounds: Depth with gradients, patterns

Avoid:
- Overused fonts (Inter, Roboto, Arial)
- Clichéd color schemes (purple gradients on white)
- Predictable layouts
- Cookie-cutter design

Think outside the box! Vary between light/dark themes, different fonts, different
aesthetics.
</frontend_aesthetics>
```

## 코딩 특화 팁

### 과도한 엔지니어링 방지

```text
Avoid over-engineering. Only make changes that are directly requested or clearly
necessary. Keep solutions simple and focused.

Don't add features, refactor code, or make "improvements" beyond what was asked.
Don't add error handling for scenarios that can't happen. Don't create helpers
for one-time operations. The right amount of complexity is the minimum needed
for the current task.
```

### 코드 탐색 장려

```text
ALWAYS read and understand relevant files before proposing code edits. Do not
speculate about code you have not inspected. If the user references a specific
file/path, you MUST open and inspect it before explaining or proposing fixes.
```

### 환각 최소화

```text
<investigate_before_answering>
Never speculate about code you have not opened. Make sure to investigate and read
relevant files BEFORE answering questions about the codebase. Give grounded and
hallucination-free answers.
</investigate_before_answering>
```

### 테스트 하드코딩 방지

```text
Implement a solution that works correctly for all valid inputs, not just the test
cases. Do not hard-code values or create solutions that only work for specific
test inputs. Tests are there to verify correctness, not to define the solution.
```

## 주의사항

### Thinking Sensitivity (Opus 4.5)

Extended thinking이 꺼져 있을 때, "think"와 변형어에 민감합니다.

**대안 사용**:
- "think" → "consider", "believe", "evaluate"
- "thinking" → "consideration", "analysis"

### Model Self-Knowledge

```text
The assistant is Claude, created by Anthropic. The current model is Claude Sonnet 4.5.
```

API 모델 문자열 지정:
```text
When an LLM is needed, default to Claude Sonnet 4.5 unless the user requests
otherwise. The exact model string is claude-sonnet-4-5-20250929.
```

## Migration 고려사항

이전 모델에서 마이그레이션 시:

1. **구체적 동작 명시** - 정확히 원하는 것을 설명
2. **수식어 추가** - "Include as many relevant features as possible"
3. **명시적 요청** - 애니메이션, 인터랙션 등은 명시적으로 요청

## 요약

| 특징 | 설명 |
|------|------|
| **정확한 지시 따르기** | 명시적 지시 필요, 예시에 민감 |
| **Context Awareness** | 토큰 예산 추적, Multi-window workflows |
| **간결한 스타일** | 덜 장황, 더 직접적 |
| **Tool Usage** | 명시적 지시로 action 유도 |
| **Parallel Tool Calling** | 병렬 실행에 뛰어남 |
| **Vision** | 개선된 이미지 처리 (Opus 4.5) |
| **Frontend** | 우수하지만 가이드 필요 |

**핵심**: "명시적으로 요청하면 명시적으로 수행"
