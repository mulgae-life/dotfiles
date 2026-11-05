---
name: cowork-set
description: 프로젝트에 Claude–Codex 협업 체계를 세팅합니다. 프로젝트 유형에 맞는 역할 배분과 소통·판정 규칙을 agent-guide/GUIDE.md의 협업 절로 기록하고, tmux에 떠 있는 상대 세션에 그 절을 읽혀 역할을 확인받습니다. 대표님이 직접 호출할 때만 씁니다.
disable-model-invocation: true
---

# cowork-set — 협업 체계 세팅

- 대표님이 한 번 불러 세팅하면 끝나는 스킬이다. 이후 협업 규칙의 정본은 GUIDE의 "협업 체계" 절이다.
- 루트 `CLAUDE.md`·`AGENTS.md`가 GUIDE 링크라 새 세션은 두 도구 모두 협업 절을 자동으로 읽는다. 이미 떠 있는 상대 세션은 3단계에서 맞춘다.
- Claude는 `/cowork-set`, Codex는 `$cowork-set`으로 부른다. **호스트**는 스킬을 실행한 쪽, **상대**는 다른 쪽이다.

## 분기

| 상태 | 할 일 |
|------|------|
| `agent-guide/GUIDE.md` 없음 | 중단하고 `/init-project`를 먼저 안내 |
| 협업 절 없음 | 1~4단계 |
| 협업 절 있음 (`grep -nE '^## .*협업 체계' agent-guide/GUIDE.md`) | 현재 역할 배분을 요약해 보여 주고 개정할지 묻는다. 개정이면 1~4단계를 밟되 2단계에서 바뀐 줄만 고친다 |

## 1단계: 정하고 확인받기

- **유형** — PROJECT.md와 코드에서 추정한다.

  | 유형 | 신호 | 배분 |
  |------|------|------|
  | 제품형 | 프론트엔드 프레임워크(`package.json`의 react·next·vue·svelte 등), UI 컴포넌트, 웹 서비스 | 설계·구현 Claude, 검수(설계서 검토·코드 리뷰·E2E·QA) Codex |
  | 연구형 | 수치 계산·시뮬레이션·실험·데이터 분석 코드, 논문·노트 | 연구 흐름·설계·감사·교열 Claude, 구현·실험·분석·문서 반영 Codex (문헌 정독·유도·실험 설계는 함께) |
  | 혼합형 | 두 성격이 영역별로 섞임 | 영역마다 구현 주체를 나눔 |

- **유형별 세부** — 제품형은 Codex가 고칠 테스트 경로, 혼합형은 영역별 경로와 구현·검수 주체. 모르면 `[TODO]`.
- **세션**
  - 상대: `tmux ls`로 찾는다. 없거나 후보가 여럿이면 묻고, 대신 띄우지 않는다.
  - 호스트: `$TMUX`가 있으면 `tmux display-message -p -t "$TMUX_PANE" '#S'`, 없으면 tmux 밖. `$TMUX` 없이 `display-message`를 부르면 다른 세션 이름이 나온다.
- **협업 문서 위치** — 기본 `agent-guide/cowork/`. 프로젝트에 협업 산출물 자리가 이미 있으면 그것을 쓴다.
- **GPT Pro 합류** — 반드시 묻는다.
  - 문헌을 깊이 조사하거나 새 수식을 유도·반증하는 연구가 아니면 넣지 않기를 추천한다.
  - 넣으면 브라우저 조작 절차 문서와 브라우저 tmux 세션이 있는지 확인한다. 이 서버에서는 `/workspace/CFD/agent-guide/docs/CHATGPT_PRO_BROWSER.md`와 `codex-pro-browser`이고, 없으면 묻는다.

정한 내용을 한 번에 보여 주고 확인받는다.

```
📋 협업 체계안
- 유형: 제품형 (근거: package.json에 next, app/ 아래 UI 컴포넌트)
- Claude: 요구 해석, 설계, UI·디자인, 구현 — tmux dot
- Codex: 설계서 검토, 코드 리뷰, E2E·QA — tmux dot-codex, 테스트 코드(e2e/)만 수정
- 협업 문서: agent-guide/cowork/<주제>/
- GPT Pro: 넣지 않음
```

## 2단계: GUIDE에 협업 절 넣기

- `references/guide-section.md`의 변수를 채우고 정한 블록만 남긴다.
- 처음이면 GUIDE 끝에 추가한다. 절 번호를 쓰는 GUIDE면 다음 번호를 붙인다.
- 개정이면 기존 협업 절 안에서 바뀐 줄만 고친다.
- 협업 절 밖은 고치지 않는다.

## 3단계: 상대 세션에 역할 확인받기

1. 상대 화면 끝을 본다(`tmux capture-pane -p -t <상대> | tail -20`). 입력창에 대표님이 쓰던 글이 있으면 건드리지 말고 보고한 뒤 멈춘다.
2. 알림을 보내고 기다린다. 종료 코드의 뜻은 `peer.sh` 사용법에 있다.

   ```bash
   P=~/.claude/skills/cowork-set/scripts/peer.sh
   bash "$P" send <상대> "[대표님 지시] agent-guide/GUIDE.md의 '협업 체계' 절을 읽고, 주로 맡는 일과 고칠 수 있는 범위, 상대가 맡는 일을 세 줄로 회신해 주세요."
   bash "$P" wait <상대>
   tmux capture-pane -p -t <상대> -S -60 | tail -40
   ```

   - `send`가 종료 코드 3이면 상대 화면을 본다. 작업 중이면 `wait` 뒤에 다시 보내고, 질문·승인 창이 떠 있으면 대표님께 보고한다.
   - Claude 호스트는 `wait`를 `run_in_background`로 돌린다. Codex 호스트는 명령 시간 제한을 넉넉히 준다.
3. 회신이 협업 절과 어긋나면 어긋난 줄만 짚어 다시 확인받는다.

## 4단계: 보고

- 넣거나 고친 절의 요지: 유형, 역할, Codex의 코드 수정 범위, GPT Pro 여부, `[TODO]` 항목
- 상대 회신의 핵심과 협업 절과의 일치 여부
- 커밋은 대표님 요청 시에만
