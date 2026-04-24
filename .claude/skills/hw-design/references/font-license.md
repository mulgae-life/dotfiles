# 폰트 라이선스 근거

이 스킬이 번들하는 웹폰트 2종의 라이선스와 사용 범위를 기록한다. 한화 프로젝트(상업 BI/CI 포함)에서 안전하게 재배포·임베딩·수정할 수 있음을 확인했다.

## 요약

| 폰트 | 라이선스 | 상업 사용 | 수정/재배포 | BI/CI 사용 | 번들 |
|------|----------|-----------|-------------|-------------|------|
| **AtoZ** (에이투지체) | SIL OFL 1.1 | ✅ | ✅ | ✅ 명시 허용 | `assets/fonts/AtoZ/` 9 weights |
| **IBM Plex Sans Variable** | SIL OFL 1.1 | ✅ | ✅ | ✅ | `assets/fonts/IBMPlexSans/` 2 파일 + `OFL.txt` |

**공통 제한** — 폰트 파일 자체를 판매하는 행위만 금지. 프로젝트에 임베딩·재배포·수정은 자유.

## AtoZ — 상세

- **디자이너**: Autonomous A2Z × Lee Juim (자율주행 회사 A2Z 협업, 이주임 디자이너)
- **weight**: 9단 (Thin 100 → Black 900)
- **스크립트**: 한글 + 라틴
- **라이선스**: SIL Open Font License 1.1 (OFL)
- **허용**: 인쇄물·웹·패키징·영상·임베딩·**BI/CI(회사명/브랜드/로고/슬로건)** 전반
- **출처**: [noonnu.cc A2Z 페이지](https://noonnu.cc/en/font_page/1778), [freekoreanfont.com A2Z](https://www.freekoreanfont.com/a2z-font-download/)

**한화 프로젝트 적합성**: noonnu 라이선스 문구에 **BI/CI 사용을 명시적으로 허용**하므로, 한화그룹 제품·서비스의 로고 주변·랜딩·UI 전반에 문제없이 사용 가능. 웹폰트 `.woff2` 9개 번들.

## IBM Plex Sans — 상세

- **디자이너**: IBM + Bold Monday (Mike Abbink)
- **라이선스**: SIL Open Font License 1.1 (OFL)
- **허용**: 상업·비상업 모두. 수정·파생작 배포 가능 (단 IBM Plex 이름은 reserved, 파생작에서 사용 금지)
- **배포**: [IBM/plex GitHub](https://github.com/IBM/plex), Google Fonts, Adobe Fonts, Font Squirrel
- **번들 이유**: 영문/숫자 전용 **숫자 강조 페어링**. 한화 대시보드·재무·KPI 표에서 AtoZ 한글 + IBM Plex 숫자의 조합이 가독성·브랜드 격식에 우수.
- **번들 파일**: Variable 2종 (Roman + Italic) + 원본 `OFL.txt`

**Reserved Font Name 경고** — IBM Plex 이름 자체가 상표. 파생 폰트를 만들 때 "Plex"를 포함한 이름을 쓰면 안 됨. 이 스킬은 원본을 그대로 번들하므로 해당 없음.

## 배포 규칙 요약

이 스킬이 폰트 번들을 포함하여 dotfiles 레포에 커밋되고 사용자 프로젝트로 복사되는 워크플로우가 라이선스를 위반하지 않는지 근거:

1. **SIL OFL §1** — 폰트 자체의 자유 사용/연구/수정/재배포 허용
2. **SIL OFL §2** — 번들(bundled, embedded, redistributed) 형태로 소프트웨어/문서에 포함 가능
3. **SIL OFL §3** — 수정 시 reserved name(IBM Plex)을 변경해야 하나, 이 스킬은 원본만 번들
4. **SIL OFL §5** — 폰트 파일 **단독 판매** 금지. 스킬/프로젝트는 폰트를 판매하지 않음

결론: OFL 조건 충족. 한화 상업 프로젝트에 그대로 배포·사용 가능.

## OFL 원문

- [SIL OFL 1.1 Web 페이지](https://openfontlicense.org/)
- IBM Plex 원본 라이선스: `assets/fonts/IBMPlexSans/OFL.txt` (이 스킬에 포함)

## 업데이트 이력

- **2026-04-24 v1.0**: 초기 작성. A2Z·IBM Plex 모두 SIL OFL, BI/CI 사용 명시 허용 근거 확보.
