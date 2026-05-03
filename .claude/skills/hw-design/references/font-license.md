# 폰트 라이선스 근거

이 스킬이 번들하는 웹폰트 4종(한화체·한화고딕·AtoZ·IBM Plex Sans)의 라이선스와 사용 범위를 기록한다.

## 요약

| 폰트 | 라이선스 | 상업 사용 | 외부 재배포 | BI/CI 사용 | 번들 |
|------|----------|-----------|-------------|-------------|------|
| **Hanwha** (한화체) | Hanwha Group Internal | 한화 임직원 사내 라이선스 | ❌ 외부 재배포 금지 | ✅ (한화 BI 전용) | `assets/fonts/Hanwha/` 3 weights × (woff2+woff+ttf) |
| **HanwhaGothic** (한화고딕) | Hanwha Group Internal | 한화 임직원 사내 라이선스 | ❌ 외부 재배포 금지 | ✅ (한화 BI 전용) | `assets/fonts/HanwhaGothic/` 5 weights × woff2 |
| **AtoZ** (에이투지체) | SIL OFL 1.1 | ✅ | ✅ | ✅ 명시 허용 (폴백) | `assets/fonts/AtoZ/` 9 weights |
| **IBM Plex Sans Variable** | SIL OFL 1.1 | ✅ | ✅ | ✅ | `assets/fonts/IBMPlexSans/` 2 파일 + `OFL.txt` |

> ⚠️ 한화체·한화고딕은 **한화그룹 IP**다. 본 dotfiles 레포 번들은 사용자(한화 임직원)의 사내 라이선스 협의에 따른 것이며, 외부 비-한화 프로젝트로의 폰트 파일 재배포는 한화그룹 정책상 불가하다.

## Hanwha · HanwhaGothic — 상세

- **소유권**: 한화그룹 (`㈜한화 · 한화 BI/CI 자산`)
- **라이선스 유형**: Hanwha Group Internal — 그룹사 BI/CI 일관성 유지를 위한 사내 전용 서체. 판매·유상양도·무단배포·수정 금지.
- **본 스킬 사용 권한 근거**: 사용자(한화 임직원)의 사내 협의 완료 (2026-05 기준)
- **출처 (공식 한화 그룹 도메인 호스팅)**:
  - 폰트 정의 CSS (전체 weight): `https://www.hanwhaeagles.co.kr/css/fonts.css`
  - 폰트 파일 호스팅: `https://www.hanwhaeagles.co.kr/fonts/`
  - 한화체 메인 CSS (참고): `https://www.hanwhacorp.co.kr/_resource/font/hanwha/font.css`
- **번들 형식**:
  - **Hanwha**: woff2 + woff + ttf — 3 weight × 3 형식 = 9 파일 (~5.6MB). 데스크톱 도구 호환 위해 ttf까지 포함.
  - **HanwhaGothic**: woff2만 — 5 weight × 1 형식 = 5 파일 (~1.5MB). 한화이글스 서버에 woff/ttf 미호스팅(서버 응답 오류). 모든 모던 브라우저는 woff2를 100% 지원하므로 실용상 문제없음.
- **Family 검증** (file 명령으로 EOT family name 확인):
  - `Hanwha L family` / `Hanwha R family` / `Hanwha B family`
  - `hanwhaGothic T/EL/L/R/B family`

### 사용 시 주의

- **외부 협업자 또는 비-한화 프로젝트에서 dotfiles fork 사용 시** → `assets/fonts/Hanwha/`, `assets/fonts/HanwhaGothic/` 디렉토리는 **선택적으로 제거** 후 사용 권장. AtoZ + IBM Plex 폴백이 자동 동작 → UI 깨짐 없음.
- **외부 산출물(웹사이트·인쇄물 외부 노출) 사용 전** → 한화 BI 가이드 정합성 검증 권장.
- **상업 외부 배포 시** → 별도로 한화 그룹 BI 담당과 정식 사용 동의서를 확보하는 것이 안전.

## AtoZ — 상세

- **디자이너**: Autonomous A2Z × Lee Juim (자율주행 회사 A2Z 협업, 이주임 디자이너)
- **weight**: 9단 (Thin 100 → Black 900)
- **스크립트**: 한글 + 라틴
- **라이선스**: SIL Open Font License 1.1 (OFL)
- **허용**: 인쇄물·웹·패키징·영상·임베딩·**BI/CI(회사명/브랜드/로고/슬로건)** 전반
- **출처**: [noonnu.cc A2Z 페이지](https://noonnu.cc/en/font_page/1778), [freekoreanfont.com A2Z](https://www.freekoreanfont.com/a2z-font-download/)
- **본 스킬 역할**: 한화 폰트 미배포 환경(외부 협업자, 라이선스 미확보) 또는 로딩 실패 시 **폴백**. 9 weight × woff2 번들.

## IBM Plex Sans — 상세

- **디자이너**: IBM + Bold Monday (Mike Abbink)
- **라이선스**: SIL Open Font License 1.1 (OFL)
- **허용**: 상업·비상업 모두. 수정·파생작 배포 가능 (단 IBM Plex 이름은 reserved, 파생작에서 사용 금지)
- **배포**: [IBM/plex GitHub](https://github.com/IBM/plex), Google Fonts, Adobe Fonts, Font Squirrel
- **번들 이유**: 영문/숫자 전용 **숫자 강조 페어링**. 한화 대시보드·재무·KPI 표에서 한화고딕 한글 + IBM Plex 숫자의 조합이 가독성·브랜드 격식에 우수.
- **번들 파일**: Variable 2종 (Roman + Italic) + 원본 `OFL.txt`

**Reserved Font Name 경고** — IBM Plex 이름 자체가 상표. 파생 폰트를 만들 때 "Plex"를 포함한 이름을 쓰면 안 됨. 이 스킬은 원본을 그대로 번들하므로 해당 없음.

## 배포 규칙 — 폰트별 상이

### AtoZ · IBM Plex Sans (SIL OFL 1.1)

dotfiles 레포에 커밋되고 사용자 프로젝트로 복사되는 워크플로우가 라이선스를 위반하지 않는지 근거:

1. **SIL OFL §1** — 폰트 자체의 자유 사용/연구/수정/재배포 허용
2. **SIL OFL §2** — 번들(bundled, embedded, redistributed) 형태로 소프트웨어/문서에 포함 가능
3. **SIL OFL §3** — 수정 시 reserved name(IBM Plex)을 변경해야 하나, 이 스킬은 원본만 번들
4. **SIL OFL §5** — 폰트 파일 **단독 판매** 금지. 스킬/프로젝트는 폰트를 판매하지 않음

결론: OFL 조건 충족. 한화 상업 프로젝트에 그대로 배포·사용 가능.

### Hanwha · HanwhaGothic (Hanwha Group Internal)

OFL과 다르며, 한화그룹 IP 정책에 따른다:

1. **사용 권한**: 사용자(한화 임직원)의 사내 라이선스 협의 완료
2. **재배포 제한**: 외부 비-한화 프로젝트로 폰트 파일 자체를 재배포하지 않음 (dotfiles fork 시 사용자 책임)
3. **수정 금지**: 폰트 파일 수정·파생작 제작 금지
4. **BI/CI 사용**: 한화그룹 제품·서비스 UI에 자유롭게 사용 가능

## OFL 원문

- [SIL OFL 1.1 Web 페이지](https://openfontlicense.org/)
- IBM Plex 원본 라이선스: `assets/fonts/IBMPlexSans/OFL.txt` (이 스킬에 포함)
