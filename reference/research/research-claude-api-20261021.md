# Claude API 버전 2026-10-21 조사 — 공식 계약, 정정 기록, dotfiles 판단 (2026-10-22, 공개 1일 차)

> 조사 방식: Claude와 Codex가 같은 질문 일곱 개를 독립 조사한 뒤 메모 두 차례로 대조했습니다. 공식 문서는 URL 끝에 `.md`를 붙여 원문으로 받았고, SDK는 GitHub 태그의 소스(`pyproject.toml`·`_constants.py`·`_types.py`·`_exceptions.py`·`MIGRATION.md`)를 읽었습니다. API 호출, SDK 설치·실행, `/claude-api api-version` 실행은 하지 않았습니다.
> 문서 역할: 공개 시점의 사실, 조사 중 바로잡은 오류, dotfiles 판단을 기록합니다. 코드 작성 계약은 `llm-api-guide/references/anthropic-messages-api.md`의 "API 버전과 SDK" 절이 맡습니다.
> 시점: 2026-10-22 00:40~01:40 UTC. 과거 조사는 시점 기록이라 고치지 않습니다.

## 0. 요약

**결론**: `llm-api-guide`에 API 버전과 SDK 절을 새로 두고, 새 버전에서 문장대로 따르면 400이 나는 sampling 서술만 버전을 구분해 고쳤습니다. 설치·권한·설정은 바꾸지 않았습니다.

1. **API 버전 `2026-10-21`이 10/21 공개됐습니다.** SDK는 메이저마다 기본 날짜를 보내며, Python 2.0.0·TypeScript 1.0.0·C# 13.0.0·Go 2.0.0·Java 3.0.0·PHP 1.0.0·Ruby 2.0.0·`ant` CLI 2.0.0부터 새 날짜가 기본입니다. 같은 날 후속 마이너(Python 2.1.0, TypeScript 1.1.0 등)도 나왔습니다.
2. **`2023-06-01`은 계속 받고 종료 일정은 공지되지 않았습니다.** Amazon Bedrock은 Claude 4.7 이상 모델에서만 새 버전을 씁니다.
3. **Messages 계열 파괴적 변경은 세 가지입니다.** sampling 세 파라미터는 모든 모델에서 기본값이어도 400이고, assistant 메시지에 직접 넣은 `document` 블록과 user 메시지 `text` 블록의 비어 있지 않은 `citations`도 400입니다. Messages, 토큰 계산, 새 버전으로 만든 배치의 개별 요청에 적용됩니다.
4. **API 전체로는 Admin·Enterprise Analytics 응답 필드 이름도 바뀌었습니다.** Messages 변경이 세 건이라는 것과 API 전체 변경이 세 건이라는 것은 다릅니다.
5. **SDK 자체의 변경은 API 날짜와 따로 봐야 합니다.** Python은 1.0(8/20)에서 이미 `httpx2` 전환, Python 3.10 요구, Text Completions·Messages sampling 인자·툴 러너 `compaction_control` 제거를 마쳤고, 2.0에서는 메시지 타입·인증·Models `betas`가 바뀌었습니다.
6. **LangChain은 아직 SDK 2.x를 받지 않습니다.** `langchain-anthropic` 1.7.6이 `anthropic<2.0.0`을 요구합니다.

## 1. 합의한 사실

| 항목 | 내용 | 출처 |
|------|------|------|
| 버전 선택 | `anthropic-version` 헤더. SDK가 메이저별 기본 날짜를 보내고, 사용자 헤더(Python `default_headers`, TypeScript `defaultHeaders`)가 그 뒤에 병합됩니다. 헤더를 구 날짜로 고정해도 새 SDK에서 빠진 인자·타입은 돌아오지 않습니다 | API versions, SDK 소개, 태그 소스 |
| SDK 상수 | Python 1.17.0 `ANTHROPIC_API_VERSION = "2023-06-01"`, 2.0.0 `"2026-10-21"` | 태그 소스 |
| 구 버전 | "Earlier SDK and CLI versions sent `anthropic-version: 2023-06-01` with every request." 종료 날짜는 버전 정책·이전 안내서·릴리스 노트 어디에도 없습니다 | 이전 안내서, API versions |
| 플랫폼 | Claude API, Claude Platform on AWS, Microsoft Foundry, Google Cloud 지원. Bedrock은 "available for Claude 4.7 and later models". Google Cloud 직접 호출은 본문 `anthropic_version`에 날짜를 넣습니다. Foundry의 Python·TypeScript 클라이언트는 키를 계속 `x-api-key`로 보냅니다 | API versions, Google Cloud 문서, 이전 안내서 |
| sampling | "returns a 400 error, even at the parameter's default value." 빼면 기본값(`temperature` 1.0)으로 샘플링합니다. 원래 기본값만 받던 Claude 4.7 이상은 그대로이고, Sonnet 4.6처럼 다른 값을 받던 모델은 그 효과를 잃습니다. 대신할 설정은 없고, 필요하면 그 요청을 `2023-06-01`에 남깁니다 | 이전 안내서 |
| document·citations | assistant 메시지 바로 아래 `document`는 400(web fetch 결과처럼 다른 블록 안에 든 문서는 허용). user `text` 블록의 비어 있지 않은 `citations`는 `search_result` 안까지 400(assistant 응답 재전송의 인용과 `citations: {"enabled": true}` 설정은 허용) | 이전 안내서 |
| Admin·Analytics | `roles`→`role_ids`, `group_id`→`rbac_group_id`, `name`→`display_name`, `group_type`→`group.type`, API 키 `workspace_id`→`scope`, `actor.email`→`actor.email_address`, `summaries`→`data`. 옛 `workspace_id: null`을 Default Workspace로 보던 코드는 실제 ID 비교로 바꿔야 합니다 | 이전 안내서 |
| Python 2.0.0 | `MessageParam`이 역할별 유니언(dict 리터럴은 그대로, `MessageParam(...)` 호출은 `TypeError`), `client.models.list`·`retrieve`의 `betas` 제거(→ `client.beta.models`), API 키를 `Authorization: Bearer`로 전송, 기본 클라이언트당 자격 증명 하나(`ValueError`, 환경변수는 `ANTHROPIC_API_KEY` 우선), 예외 클래스 무변경(`_exceptions.py`가 1.17.0과 같음), Apache 2.0 | 이전 안내서, 태그 소스 |
| Python 1.0.0 (8/20) | `httpx`→`httpx2`(직접 만드는 `Timeout`·HTTP 클라이언트·전송 계층은 `httpx2` 객체, SDK가 `anthropic.Timeout`을 내보냄), Python 3.10 이상, Text Completions·Messages sampling 인자·툴 러너 `compaction_control` 제거, 비동기 `.with_raw_response`의 `parse()`는 `await` 필요. `MIGRATION.md`의 `extra_body={"temperature": ...}` 우회는 구 API용입니다 | 8/20 릴리스 노트, `MIGRATION.md`, `pyproject.toml` |
| TypeScript 1.0.0 | Python 2.0과 같은 타입·인증·`betas` 변경(자격 증명 중복은 `TypeError`), Text Completions(`client.completions`, `HUMAN_PROMPT` 등)와 `compactionControl` 제거(서버 측 압축 `compact_20260112`, 베타 `compact-2026-01-12`), sampling 타입 제거, TypeScript 5.0 이상·지원 중인 Node.js 20 이상, 플랫폼 패키지(`bedrock-sdk`·`vertex-sdk`·`foundry-sdk` 등)도 함께 1.x로. 태그 이름은 `sdk-v1.0.0` | 이전 안내서, README, 릴리스 |
| LangChain | `langchain-anthropic` 1.7.6(10/12)의 의존성은 `anthropic<2.0.0,>=0.120.0`. `ChatAnthropic`은 `default_headers`를 SDK에 넘길 뿐 날짜를 강제하지 않아, 헤더를 지정하지 않으면 `2023-06-01`입니다 | PyPI 메타데이터, 1.7.6 소스 |
| 대화 중 시스템 메시지 | 헤더 없이 정식(Fable 5.1, Mythos 5.1, Fable 5, Mythos 5, Opus 5.5, Opus 4.8, Opus 5, Sonnet 5.5, Haiku 5.5). Sonnet 5 미지원. 내용이 있는 메시지는 첫 위치 금지, user 턴(또는 서버 도구 결과로 끝난 assistant 턴) 바로 뒤, 외부 데이터 금지. 메시지별 effort는 베타(`mid-conversation-output-config-2026-07-01`) | 대화 중 시스템 메시지 문서 |
| Claude Code | 2.1.307 "Added `/claude-api api-version` to move Claude API code to API version `2026-10-21`". 설치본 번들에 `shared/api-version-migration.md`가 있습니다. 공개 `anthropics/skills` 저장소에는 조사 시점에 `api-version` 분기가 없었습니다 | 변경 기록, 설치본 번들, 공개 저장소 |

## 2. 조사 중 바로잡은 것

- **"모델별 풀 가이드는 조사 기록이라 그대로 둔다"(Claude 1단계)를 철회했습니다.** 스킬이 `reference/claude-prompt-guide/*`를 실제로 링크해 읽히므로, 두면 같은 오류가 재생산됩니다(Codex 근거). 대신 "새 버전에서 문장대로 따르면 400이 나는 문장(허용 서술과 기본값 단서)만 고친다"는 기준을 합의했고, "400", "제거", "모두 뺀다"처럼 두 버전 모두에서 맞는 서술은 두었습니다.
- **"SDK 메이저가 API 버전을 정한다"(Claude 초안)는 기본값을 말한 것이었습니다.** 사용자가 헤더로 덮어쓸 수 있으므로, SDK를 올릴 때 기본값과 직접 지정한 헤더를 함께 확인한다고 고쳤습니다(Codex 지적).
- **역할 표 `system` 행 초안의 "첫 메시지로는 못 쓴다"는 내용이 있는 메시지에만 해당합니다.** effort만 담은 메시지는 첫 위치를 포함해 어디든 받습니다. 그래서 배치 규칙은 공식 Limitations 절로 연결했고(Codex 지적), effort 변경은 베타라는 단서를 붙였습니다(Claude 지적).
- **인증 설명의 주어를 기본 클라이언트로 좁혔습니다.** Foundry는 `x-api-key`를 유지하고 Python `AnthropicAWS`는 키와 토큰을 함께 받았을 때 처리가 다릅니다(Codex 지적).
- **Haiku 5.5의 값별 허용 서술을 지웠습니다.** 10/7 조사 때 적은 "`temperature`는 1, `top_p`는 기본값 0.99만 받는다"는 현재 공식 이전 안내서의 sampling 절에 없고, 그 절은 "omit `temperature`, `top_p`, and `top_k`" 한 문장뿐입니다. 틀렸다고 판정한 것은 아니며, 생략 권고는 같습니다.
- **`APIError.status_code`(Codex 1단계 지적)는 이번 반영에서 뺐습니다.** v2.0.0 소스를 보면 예제의 `except` 순서상 마지막 `except APIError`에 닿는 것은 `status_code`를 가진 `APIStatusError` 하위 클래스나 `APIResponseValidationError`뿐입니다. `status_code`가 없는 `APIWebhookValidationError`는 `src/`에서 발생시키지 않고 `raise APIError(`도 없습니다. 현재 Messages 기본 경로의 실행 오류는 확인하지 못한 기존 타입 계약 문제이고, 이번 버전 변경과 무관합니다.

## 3. dotfiles 판단

| 대상 | 판단 |
|------|------|
| `anthropic-messages-api.md` | "API 버전과 SDK" 절 신설(기본 사용법 앞, 목차 포함), 역할 표 `system` 행, Haiku 5.5 sampling 문장 정정, Fable 5.1 sampling 문장 연결, 참고 자료 링크 두 개 |
| `llm-api-guide/SKILL.md` | 필수 체크리스트에 API 버전 확인 한 줄, 참고 자료 링크 두 개 |
| `common-patterns.md` | Anthropic 요청별 타임아웃을 `from anthropic import Timeout`으로 바꿈(Python SDK 1.0부터 `httpx2`). OpenAI 쪽 `httpx.Timeout`은 그대로 |
| sampling 서술 | `writing-prompts`의 `claude-4-specifics.md` 8곳(대부분 `2023-06-01` 단서, 표 아래 공통 문단 하나)과 `claude-5-specifics.md` 1곳, 풀 가이드 6개 파일 8곳 |
| 두지 않은 곳 | `writing-prompts/SKILL.md:19`는 틀린 문장이 아니고, 본문이 이미 agy의 24,000바이트 한도를 넘어 늘리지 않았습니다. `platform-differences.md`는 Claude 열에 sampling 서술이 없습니다. `langchain-core.md:50`은 LangChain 경로가 `2023-06-01`이고 코드가 sampling을 보내지 않습니다. 풀 가이드 색인과 Opus 5.5 직접 호출 예제도 고칠 문장이 없습니다 |
| Admin·플랫폼 세부 | 이 기록에만 둡니다. `llm-api-guide`는 Admin API와 Google Cloud·Foundry 호출 예제를 다루지 않습니다. SDK를 올릴 수 있는지 가르는 Bedrock 4.7 이상 한정만 새 절에 넣었습니다 |
| LangChain | `langchain-guide`는 그대로 두고 새 절에 한 줄을 넣었습니다. 문제가 되는 경우는 직접 SDK 2.x와 한 환경에 섞을 때뿐입니다. 상한은 10/22 PyPI 기준이며, 새 날짜를 헤더로 명시한 조합은 검증하지 않았습니다 |
| `/claude-api api-version` | 새 절 끝에 한 줄. 세 도구가 함께 쓰는 스킬이라 실행 절차는 넣지 않았습니다 |
| `APIError` 타입 계약 | 범위 밖. 대표님께 별건으로 보고합니다 |
| 설치·권한·설정 | 변경 없음 |

## 4. 미확인

- `2023-06-01`의 향후 종료 날짜
- `langchain-anthropic`이 SDK 2.x를 처음 받는 버전과 날짜
- `/claude-api api-version` 내장 절차의 세부(편집 순서, 지원 언어 범위, 확인 질문과 테스트 방식)
- `2023-06-01`에서 Haiku 5.5가 받는 sampling 값의 현재 세부

## 5. 출처

수집은 2026-10-22 00:40~01:35 UTC입니다. 릴리스 노트와 이전 안내서 사본은 `.collab-loop/20261022-claude-api-20261021/sources/`, Haiku 5.5 이전 안내서와 대화 중 시스템 메시지 문서 사본은 로컬 `.archive/2026-10-22_claude-api-20261021/raw/`에 있습니다. 두 조사 보고서(`research_v1_claude.md`·`research_v1_codex.md`)와 토론 메모도 같은 `.collab-loop` 폴더에 있습니다(두 경로 모두 git 추적 대상이 아닙니다).

- Claude API: [이전 안내서](https://platform.claude.com/docs/en/api/migration-2026-10-21) · [API versions](https://platform.claude.com/docs/en/api/versioning) · [릴리스 노트](https://platform.claude.com/docs/en/release-notes/api) · [SDK 소개](https://platform.claude.com/docs/en/cli-sdks-libraries/overview) · [대화 중 시스템 메시지](https://platform.claude.com/docs/en/build-with-claude/mid-conversation-system-messages) · [Haiku 5.5 이전 안내서](https://platform.claude.com/docs/en/models/haiku-5-5/migration-guide) · [Google Cloud](https://platform.claude.com/docs/en/build-with-claude/claude-on-vertex-ai) · [Amazon Bedrock](https://platform.claude.com/docs/en/build-with-claude/claude-in-amazon-bedrock)
- SDK: [Python v2.0.0](https://github.com/anthropics/anthropic-sdk-python/releases/tag/v2.0.0) · [Python v1.0.0](https://github.com/anthropics/anthropic-sdk-python/releases/tag/v1.0.0) · [Python `MIGRATION.md`](https://github.com/anthropics/anthropic-sdk-python/blob/v2.0.0/MIGRATION.md) · [Python `_exceptions.py`](https://github.com/anthropics/anthropic-sdk-python/blob/v2.0.0/src/anthropic/_exceptions.py) · [TypeScript sdk-v1.0.0](https://github.com/anthropics/anthropic-sdk-typescript/releases/tag/sdk-v1.0.0) · [TypeScript README 실행 환경](https://github.com/anthropics/anthropic-sdk-typescript/blob/sdk-v1.0.0/README.md#requirements)
- LangChain: [PyPI `langchain-anthropic` 1.7.6](https://pypi.org/project/langchain-anthropic/1.7.6/) · [1.7.6 `pyproject.toml`](https://github.com/langchain-ai/langchain/blob/langchain-anthropic%3D%3D1.7.6/libs/partners/anthropic/pyproject.toml)
- Claude Code: [변경 기록](https://github.com/anthropics/claude-code/blob/main/CHANGELOG.md) · [Claude API 스킬 소개](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/claude-api-skill)
