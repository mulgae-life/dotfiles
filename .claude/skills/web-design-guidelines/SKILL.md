---
name: web-design-guidelines
description: Web Interface Guidelines 준수 여부 UI 코드 리뷰. "UI 리뷰해줘", "접근성 체크", "디자인 검토", "UX 리뷰", "모범 사례 확인" 요청 시 사용.
metadata:
  author: vercel
  version: "1.0.0"
  argument-hint: <file-or-pattern>
---

# Web Interface Guidelines

Web Interface Guidelines 준수 여부를 검토합니다.

## 작동 방식

1. 아래 소스 URL에서 최신 가이드라인 fetch
2. 지정된 파일 읽기 (또는 사용자에게 파일/패턴 요청)
3. fetch한 가이드라인의 모든 규칙 검사
4. `파일:라인` 형식으로 결과 출력

## 가이드라인 소스

리뷰 전 최신 가이드라인 fetch:

```
https://raw.githubusercontent.com/vercel-labs/web-interface-guidelines/main/command.md
```

WebFetch로 최신 규칙을 가져옵니다. fetch된 콘텐츠에 모든 규칙과 출력 형식 지침이 포함되어 있습니다.

## 사용법

사용자가 파일 또는 패턴 인자를 제공하면:
1. 위 소스 URL에서 가이드라인 fetch
2. 지정된 파일 읽기
3. fetch한 가이드라인의 모든 규칙 적용
4. 가이드라인에 지정된 형식으로 결과 출력

파일 미지정 시, 사용자에게 리뷰할 파일 요청.
