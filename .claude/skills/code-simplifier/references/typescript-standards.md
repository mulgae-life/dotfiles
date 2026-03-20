# TypeScript/React 코딩 표준

code-simplifier 스킬에서 TypeScript 코드 단순화 시 참조하는 표준.

## 함수 선언
- 최상위 함수는 `function` 키워드 사용
- 콜백/인라인은 화살표 함수 허용
```typescript
// 최상위 함수
function formatDate(date: Date): string {
  return date.toLocaleDateString('ko-KR');
}

// 콜백은 화살표 함수 OK
const doubled = numbers.map((n) => n * 2);
```

## React 컴포넌트
```typescript
// Props 타입 명시적 정의
interface EventCardProps {
  event: Event;
  onSelect: (id: string) => void;
}

// 함수 선언 + 명시적 반환 타입
function EventCard({ event, onSelect }: EventCardProps): JSX.Element {
  return (
    <div onClick={() => onSelect(event.id)}>
      {event.title}
    </div>
  );
}
```

## Next.js (App Router)
- 서버 컴포넌트 우선 (데이터 fetching, 정적 콘텐츠)
- 상호작용 필요 시 `'use client'` 명시 (useState, onClick 등)
- Tailwind CSS로 스타일링
