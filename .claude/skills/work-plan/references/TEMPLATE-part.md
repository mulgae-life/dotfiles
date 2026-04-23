# Part 템플릿 (Split 모드)

master Phase 맵에서 이 part에 매핑된 **Phase 범위**를 다룬다. part 하나에 phase 1개(1:1) 또는 여러 개(1:N) 매핑 가능.

> part는 작업 중인 part에서만 로드된다. 해당 Phase들의 전체 맥락을 part 안에서 자족적으로 완결해야 한다.
> 섹션 헤더 `(필수)`/`(선택)` 태그 준수.

---

```markdown
# Part N: [Part 이름] — Phase M, M+1

> master: [../master.md](../master.md)
> 선행 Part: part{N-1} (없으면 `-`) | 후속 Part: part{N+1} (없으면 `-`)
> 담당 Phase: M, M+1 | 변경 파일: N개 | 상태: 초안

## 목표 (필수)
[이 Phase에서 달성할 구체적 결과 1-2문장]

## 전제 조건 (필수 — 선행 Part 산출물)
- [ ] part{N-1} 완료 및 검증 통과
- [ ] 선행 산출물 1 (구체적 파일/함수/타입명)
- [ ] 선행 산출물 2

## 작업 목록 (필수)
- [ ] 작업 1
- [ ] 작업 2
- [ ] 작업 3

## 변경 예시 (필수, 핵심 시그니처만)
> 계획서는 청사진. 전체 구현 복붙 금지.

**`src/types/user.ts` — 신규**
\`\`\`typescript
import { z } from "zod";

export const UserSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  role: z.enum(["admin", "member"]),
});

export type User = z.infer<typeof UserSchema>;
\`\`\`

**`src/types/index.ts` — 수정**
\`\`\`typescript
+ export * from "./user";
\`\`\`

## 검증 (필수)
\`\`\`bash
npx tsc --noEmit   # 타입 체크 통과
npm test -- user   # user 관련 테스트 통과
\`\`\`

## 완료 기준 (필수 — 다음 Part로 진행 전)
- [ ] 모든 작업 목록 완료
- [ ] 검증 명령어 통과
- [ ] master의 Phase 맵에서 이 Phase 상태를 ✅로 갱신
- [ ] 후속 Part의 "전제 조건"이 모두 충족되는지 확인
```
