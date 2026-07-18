# Density Zone — 슬라이드 하단 채움 룰

> **문제**: 콘텐츠 슬라이드의 y=840–1010 영역이 비어 있으면 슬라이드가 얕아 보인다.
> **해결**: 본문을 **지지하되 중복하지 않는** 콘텐츠로 채운다. 슬라이드당 패턴 하나만 선택.

## 6개 패턴

### 1. Stat strip

**3–4개 보조 수치를 균등 간격으로 배치.**

- 각 수치: `Bold 40 px` (`--hw-orange` or `--hw-ink`) + 그 아래 `Light 13 px` 라벨 (`--hw-graphite`)
- 위치: y = 840 (수치) / y = 905 (라벨)
- 컬럼 간격: (1920 - 좌우 마진) ÷ N

**예시**:
```html
<div class="density-stat-strip">
  <div class="stat"><b>1,234</b><span>가입 고객</span></div>
  <div class="stat"><b>23.4%</b><span>YoY 성장</span></div>
  <div class="stat"><b>98.7%</b><span>고객 만족도</span></div>
  <div class="stat"><b>1566-8000</b><span>24시 고객센터</span></div>
</div>
```

```css
.density-stat-strip {
  position: absolute; left: 80px; right: 80px; top: 840px;
  display: grid; grid-template-columns: repeat(4, 1fr); gap: 24px;
}
.density-stat-strip .stat b {
  display: block; font-weight: 700; font-size: 40px;
  color: var(--hw-orange); line-height: 1;
}
.density-stat-strip .stat span {
  display: block; font-weight: 300; font-size: 13px;
  color: var(--hw-graphite); margin-top: 8px;
}
```

**언제 쓰나**: 본문이 정성적 설명일 때, 정량 백업 수치로 신뢰감 추가.

---

### 2. Key takeaway

**한 문장을 `--hw-orange-tint` 위에 강조.**

- 위치: y = 860 ~ 990, 좌우 마진 80 px
- 패딩 24 px, 라운드 8 px
- 텍스트: `Regular 18 px`, `--hw-ink`, 좌측 정렬
- 좌측에 4 px 두께 `--hw-orange` 세로 바 (옵션)

**예시**:
```html
<div class="density-takeaway">
  자율주행 시대, 한화손해보험은 AI 사고 분석 + 즉시 보상 + 24시 상담의 3단계 안전망을 제공합니다.
</div>
```

```css
.density-takeaway {
  position: absolute; left: 80px; right: 80px; top: 860px;
  padding: 24px 32px; background: var(--hw-orange-tint);
  border-radius: 8px; border-left: 4px solid var(--hw-orange);
  font-weight: 400; font-size: 18px; color: var(--hw-ink);
}
```

**언제 쓰나**: 본문에 데이터·근거가 많고, 한 줄로 결론을 강조해야 할 때.

---

### 3. Mini timeline

**3–5개 마일스톤을 가로로 배치.**

- 가로 트랙: y = 920, `--hw-orange-soft` 배경, 높이 6 px
- 마일스톤 노드: 원형 직경 16 px, `--hw-orange`
- 노드 위 라벨 (Regular 14 px, `--hw-ink`): 날짜
- 노드 아래 캡션 (Regular 13 px, `--hw-graphite`): 이벤트명
- 균등 간격

**예시**:
```html
<div class="density-timeline">
  <div class="track"></div>
  <div class="node" style="left: 5%"><span class="lbl">2024.01</span><span class="cap">개발 착수</span></div>
  <div class="node" style="left: 30%"><span class="lbl">2024.06</span><span class="cap">알파 출시</span></div>
  <div class="node" style="left: 55%"><span class="lbl">2024.12</span><span class="cap">베타 클로즈</span></div>
  <div class="node" style="left: 80%"><span class="lbl">2025.03</span><span class="cap">정식 출시</span></div>
</div>
```

**언제 쓰나**: 본문이 단일 시점 정보, Density Zone에서 시간 흐름 보완.

---

### 4. Comparison row

**3컬럼 마이크로 테이블, 최대 3행.**

- 헤더 한 행: `--hw-orange-tint` 배경, Bold 14 px `--hw-ink`
- 데이터 행 (1–2개): white / `--hw-mist` 교차
- 행 높이 36 px
- 라운드 6 px

**예시**:
```html
<table class="density-compare">
  <thead><tr><th>항목</th><th>기존</th><th>신규</th></tr></thead>
  <tbody>
    <tr><td>보장 한도</td><td>1억 원</td><td>3억 원</td></tr>
    <tr><td>월 보험료</td><td>32,000원</td><td>28,000원</td></tr>
  </tbody>
</table>
```

**언제 쓰나**: 본문이 한 항목 설명, Density Zone에서 다른 항목과 비교 강조.

---

### 5. Quote block

**짧은 인용 + 어트리뷰션.**

- 인용문: Light 22 px, `--hw-ink`, 좌측 4 px 두께 `--hw-orange` 바
- 어트리뷰션: Caption 12 px, `--hw-mute`, 인용문 아래 8 px

**예시**:
```html
<blockquote class="density-quote">
  <p>"안전한 운전이 가장 좋은 보험입니다."</p>
  <cite>— 한화손해보험 고객 가이드</cite>
</blockquote>
```

```css
.density-quote {
  position: absolute; left: 80px; right: 80px; top: 860px;
  padding: 16px 24px; border-left: 4px solid var(--hw-orange);
  margin: 0;
}
.density-quote p { font-weight: 300; font-size: 22px; color: var(--hw-ink); margin: 0; }
.density-quote cite { display: block; font-style: normal;
  font-weight: 300; font-size: 12px; color: var(--hw-mute); margin-top: 8px; }
```

**언제 쓰나**: 본문에 무게가 필요할 때, 권위 있는 인용으로 톤 보완.

---

### 6. Source / methodology

**데이터 출처 또는 방법론 표기.**

- Caption 12 px, `--hw-mute`, 우측 정렬
- 위치: y = 1010

**예시**:
```html
<p class="density-source">출처: 한화손해보험 내부 데이터, 2025.03 / 표본 1,234건</p>
```

> ⚠️ **단독 사용 금지** — Source 라인만으로 Density Zone을 채우면 안 된다. 다른 패턴(Stat strip, Key takeaway 등)과 **함께** 배치하거나, 본문이 명백히 데이터 시각화 중심일 때만 단독 허용.

---

## 패턴 선택 가이드

| 본문 성격 | 권장 Density 패턴 |
|----------|------------------|
| 정성 설명 (스토리) | Stat strip — 정량 백업 |
| 데이터 시각화 | Key takeaway — 결론 강조 |
| 단일 시점 정보 | Mini timeline — 시간 흐름 보완 |
| 한 항목 설명 | Comparison row — 비교 강조 |
| 분석·전망 | Quote block — 권위 보완 |
| 데이터 인용 | Source + 다른 패턴 |

## Hard Rules

- **장식 금지** — 모든 요소는 존재 이유가 있어야 한다
- **본문 중복 금지** — Density Zone은 본문을 지지만 한다
- **비워두지 않는다** — 진짜 채울 게 없으면 슬라이드가 얇은 것 → 본문 확장 또는 슬라이드 병합
- **예외**: As-Is/To-Be (아키타입 4)는 Density Zone을 연도/앵커 라벨로 사용 — Stat strip 대체
