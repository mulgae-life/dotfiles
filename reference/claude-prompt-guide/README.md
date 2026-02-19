# Anthropic Claude Prompt Engineering Guide

이 폴더는 Anthropic의 공식 Claude 프롬프트 엔지니어링 문서를 수집한 참조 자료입니다.

## 목적

- **웹 서치 불필요**: 다음부터는 이 파일들을 직접 읽어서 Claude 프롬프트 기법을 확인할 수 있습니다
- **빠른 참조**: 각 기법별로 분리된 파일로 필요한 내용만 빠르게 찾을 수 있습니다
- **OpenAI 가이드 보완**: `../openai-prompt-guide/`와 함께 사용하여 플랫폼별 차이점을 비교할 수 있습니다

## 파일 목록

### 핵심 개요
- **[overview.md](overview.md)** - 9개 핵심 기법 요약

### 9개 핵심 기법
1. **[prompt-generator.md](prompt-generator.md)** - 프롬프트 자동 생성 도구
2. **[be-clear-and-direct.md](be-clear-and-direct.md)** - 명확하고 직접적인 프롬프트 작성
3. **[multishot-prompting.md](multishot-prompting.md)** - 예시 활용 (Few-shot/Multishot)
4. **[chain-of-thought.md](chain-of-thought.md)** - CoT 프롬프팅 (Let Claude think)
5. **[use-xml-tags.md](use-xml-tags.md)** - XML 태그로 구조화
6. **[system-prompts.md](system-prompts.md)** - System 프롬프트로 역할 부여
7. **[prefill-response.md](prefill-response.md)** - 응답 Prefilling ⭐ (Anthropic 특화)
8. **[chain-prompts.md](chain-prompts.md)** - 프롬프트 체이닝
9. **[long-context-tips.md](long-context-tips.md)** - 긴 컨텍스트 활용 ⭐ (Anthropic 특화)

### 모델별 가이드
- **[claude-4-best-practices.md](claude-4-best-practices.md)** - Claude 4.x (Sonnet 4.5, Opus 4.5, Haiku 4.5) 특화 베스트 프랙티스

## Anthropic vs OpenAI 주요 차이점

### Anthropic 특화 기능 ⭐

1. **Prefilling** - Assistant 메시지 prefill로 출력 제어
   - JSON 강제: `{"role": "assistant", "content": "{"}`
   - 캐릭터 유지: `[Sherlock Holmes]` prefill
   - OpenAI에는 없는 기능

2. **Long Context Tips** - 200K 토큰 활용 최적화
   - 긴 문서는 맨 위 배치 (성능 30%↑)
   - `<document>`, `<source>` 태그 구조화
   - 인용 기반 grounding

3. **Extended Thinking** (Claude 4.x)
   - 복잡한 추론 강화 모드
   - Context awareness (token budget 추적)
   - Multi-window workflows

### 용어 차이

| OpenAI | Anthropic | 개념 |
|--------|-----------|------|
| Few-shot | Multishot | 예시 기반 학습 (동일 개념) |
| `developer` role | `system` parameter | 시스템 지침 전달 |
| - | Prefilling | 응답 사전 채우기 |

### 공통 기법

- XML 태그 활용
- Chain of Thought (CoT)
- 명확한 지시
- 예시 제공 (3-5개)
- 모순 제거

## 사용 방법

### 기본 학습
1. [overview.md](overview.md)로 9개 기법 파악
2. 필요한 기법 파일을 개별적으로 읽기

### OpenAI와 비교
1. `../openai-prompt-guide/` 문서와 함께 읽기
2. 플랫폼별 차이점 확인
3. 프로젝트에 맞는 기법 선택

### Claude 4.x 사용 시
1. [claude-4-best-practices.md](claude-4-best-practices.md) 먼저 읽기
2. 모델별 권장사항 확인
3. 핵심 9개 기법 적용

## 출처

모든 문서는 Anthropic 공식 문서에서 가져왔습니다:
- https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview
- https://docs.anthropic.com/en/docs/build-with-claude/prompt-engineering/

## 업데이트

- **최초 수집**: 2025-02-01
- **문서 버전**: Claude 4.x (2025년 1월 기준)
- **수집 범위**: 9개 핵심 기법 + Claude 4.x 베스트 프랙티스

## 관련 문서

- **OpenAI 가이드**: `../openai-prompt-guide/`
- **Culture Calendar 프롬프트 스킬**: `../../.claude/skills/writing-prompts/`
