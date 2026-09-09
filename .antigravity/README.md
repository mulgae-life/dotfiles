# .antigravity/ — Google Antigravity 지침·안전 정책

Claude Code / Codex CLI와 같은 원칙(자율성 우선, 확인 프롬프트 없음, 위험 명령은 지침이 금지하고 파국형만 기계 차단)을 Antigravity에 적용한다. 대상은 Antigravity CLI(`agy`)이며, IDE 층은 추정치로 남아 있다.

## 구조

```
.antigravity/
├── README.md                       # 이 문서
├── GEMINI.md                       # 전역 작업 지침 → ~/.gemini/GEMINI.md (CLI·IDE 공용)
├── cli/
│   ├── settings.json               # agy 관리 키 (toolPermission·artifactReviewPolicy·notifications·statusLine·permissions)
│   └── statusline-command.sh       # 상태줄 스크립트 (.claude/statusline-command.sh와 같은 배치)
├── settings.json                   # IDE 워크스페이스 설정 (추정치, 미검증)
├── hooks/
│   └── mcp-config-guard.sh         # IDE용 .agent/mcp_config.json 백도어 차단 (미검증)
├── global_workflows/               # IDE 글로벌 워크플로우 (링크 대상)
└── policies/                       # (예약)
```

`GEMINI.md`·`global_workflows/`는 Gemini CLI 층 은퇴(2026-09-07)로 `.gemini/`에서 이관됐다. `agy`가 `~/.gemini` 설정 트리를 물려받으므로 설치 경로는 `~/.gemini/` 아래에 그대로 둔다. 함께 이관됐던 `AGENTS.md`는 `GEMINI.md`로 통합했다 — 공식 문서는 CLI·IDE 모두 `GEMINI.md`를 전역 규칙 파일로 명시하고, `AGENTS.md`는 CLI가 워크스페이스 규칙의 대체 이름으로 받아주는 것뿐이다.

## CLI(`agy`) — 실측 기준 (1.1.27, Linux, 2026-09-07)

### 설치 경로

| 대상 | 경로 | 방식 |
|------|------|------|
| 전역 지침 (CLI·IDE) | `~/.gemini/GEMINI.md` | 심링크 하나. CLI 마이그레이션 문서([docs/cli/gcli-migration](https://antigravity.google/docs/cli/gcli-migration/))와 IDE 문서([docs/ide/rules](https://antigravity.google/docs/ide/rules/))가 모두 이 경로를 전역 규칙으로 명시하고, `/context` 패널의 자동 로드 목록에도 이 경로만 뜬다. `~/.gemini/config/GEMINI.md`·`AGENTS.md`도 로드되지만(마커 실측) 비공식 경로이고, 둘 다 두면 같은 지침이 두 번 주입된다(1.1.28 마커 실측 — 두 경로에 다른 표식을 두자 모델이 둘 다 나열). 별도 디렉토리에서 실행해도 주입되므로 cwd 상속이 아니라 전역이다. IDE에서 실제 로드는 미실측 |
| 스킬 | `~/.gemini/config/skills` → `.claude/skills` | 심링크. `agy`가 첫 실행 시 `~/.gemini/antigravity-cli/skills → ~/.gemini/config/skills` 링크를 스스로 만들므로 후자는 관리하지 않는다. `agy -p /skills`로 20개 인식 확인 |
| CLI 설정 | `~/.gemini/antigravity-cli/settings.json` | `cli/settings.json` 병합. `agy`가 `model`·`trustedWorkspaces`·승인 캐시를 되쓰고 희소 저장(기본값 미기록)하므로 복사 금지 |
| 상태줄 | `settings.json`의 `statusLine` → `~/.antigravity/cli/statusline-command.sh` | `{"type":"command","command":…,"stack_with_default":true}`. 스크립트는 stdin으로 JSON을 받는다(1.1.28 실측): `model.display_name`·`model.effort`, `context_window.used_percentage`(창 1,048,576), `quota.{gemini,3p}-{5h,weekly}.remaining_fraction`·`reset_time`, `workspace.project_dir`, `agent_state`. Claude Code 페이로드와 같은 골격이라 스크립트를 이식했고, 쿼터만 남은 비율→사용률로 환산하고 모델 계열(Gemini/Claude·GPT)에 따라 버킷을 고른다. 턴 종료와 모델·effort 변경 시 재실행되며 주기 갱신은 없다. 모델을 바꾸면 `context_window_size`도 그 모델 것으로 바뀐다(Claude 모델 선택 시 사용률이 뛰는 이유). `stack_with_default`는 내장 줄(단축키 힌트·모드 배지·설정 저장 실패 알림)을 위에 남긴다 — `/statusline` 명령으로 설정하면 이 플래그 없이 저장되므로 재설치 병합으로 복원된다 |
| 훅 | `~/.gemini/config/hooks.json` | 사용 0개. 파일 자체는 로드됨을 실측(PreInvocation `ephemeralMessage` 주입·Stop 발화 확인) |
| MCP | `~/.gemini/config/mcp_config.json` | 레포 미관리 |

`~/.gemini/config/rules/*.md`도 전역 규칙으로 로드되지만 프론트매터 `trigger: always_on`이 있어야 한다(없으면 `Invalid rule trigger`로 무시). 이 레포는 GEMINI.md 단일 파일을 쓰므로 사용하지 않는다.

### settings 병합 계약 (`install.sh` `merge_agy_settings`)

- `cli/settings.json`의 최상위 키(`_doc` 제외)는 레포 우선. `permissions`는 `allow`/`ask`/`deny` 3배열을 통째로 교체한다 — `/permissions`로 런타임에 추가한 규칙은 재설치 시 초기화된다
- 레포에 없는 키(`model`, `trustedWorkspaces`, `pickerGrouping` 등)는 보존. 대상이 심볼릭 링크면 링크를 그대로 둔 채 링크 대상 내용으로 병합·검증하고 마지막 교체에서 링크 자체가 일반 파일이 된다(링크 대상 파일은 무변경). 내용이 같아도 링크면 교체한다 — 남겨 두면 `agy`가 링크 대상에 되쓴다
- `jq` 부재·JSON 파싱 실패·신규 생성 실패·병합 결과 검증 실패·백업·교체 실패 → 대상 무변경 + 오류 (폴백 복사 없음). 나머지 설치는 계속하되 `install.sh`는 종료 코드 1로 끝난다
- 신규 생성·병합 모두 임시 파일에 쓰고 재파싱 검증 후 원자 교체, 병합 교체 전 `.pre-merge.bak` 백업. 2회 적용 시 동일 결과(`[SKIP]`) — `agy`가 빈 `allow`/`ask`를 빼고 희소 저장하므로 비교는 빈 배열 보충·`deny` 정렬로 정규화한 뒤 한다

### 권한 정책

| 키 | 값 | 이유 |
|----|----|------|
| `toolPermission` | `always-proceed` | Claude `bypassPermissions`·Codex `approval_policy="never"`와 동형. 확인 프롬프트가 자율 흐름을 끊는 문제(Claude 훅 은퇴 사유)를 반복하지 않는다 |
| `artifactReviewPolicy` | `always-proceed` | 산출물 검토 프롬프트도 무확인 원칙에 맞춘다(`agent-decides`는 에이전트 판단으로 검토를 요청할 수 있어 예외가 된다) |
| `notifications` | `true` | 내장 데스크톱 알림·터미널 벨. Claude·Codex의 `notify-send` 훅 대용 |
| `permissions.deny` | 66건 | 파국형만: `rm -rf`/`-fr` × {`/`, `/*`, `~`, `~/*`, `$HOME`, `$HOME/*`, `.`, `./`, `./*`, `..`, `../`, `../*`, `../..`, 루트 직하 시스템 디렉토리 9개}, `rm --recursive --force /`·`/*`, `mkfs`(접두)+dotted 9종, `reboot`·`shutdown`·`poweroff`·`halt`·`systemctl reboot/poweroff/halt`·`loginctl reboot/poweroff`·`crontab -r` |
| `permissions.allow`/`ask` | 빈 배열 | always-proceed에서 의미 없음. 명시적으로 비워 런타임 잔류 규칙을 교체 |
| `allowNonWorkspaceAccess` | 미설정 | 아래 실측 참조 — 통제 효과를 확인하지 못해 설정으로 보장을 주장하지 않는다 |

deny 매칭 실측(1.1.27): **토큰 단위 정확 일치 + 접두 매칭**. `command(printf X)`는 `printf X extra`를 막고 `printf X_y`는 통과. `*`는 글롭이 아니다(`command(printf G*)`가 `printf Gx`를 못 막음 — 따라서 `rm -rf /*`의 `/*`는 리터럴 토큰). `regex:` 접두는 `command(regex:^…)`·`regex:command(…)`·비앵커 세 형태 모두 deny에서 무효. 복합 명령(`rm -rf X && echo`)은 파트별로 검사돼 차단됨. `always-proceed`에서도 명시 deny는 유지된다.

Claude deny 49건과의 차이: 글롭이 없어 `rm -rf /home*`·`dd of=/dev/sd*`·`fdisk /dev/*`·`parted /dev/*`·`shred /dev/*`를 표현할 수 없다. `dd`·`fdisk`·`parted`·`shred`를 통째로 막으면 `fdisk -l` 같은 조회까지 막히므로 deny에서 제외하고 지침 통제에 둔다. 반대로 `rm -rf /tmp/x` 같은 일반 절대경로 삭제는 Claude에서는 `*` 확장 때문에 막히지만 여기서는 통과한다(설계 의도인 "파국형만"에 더 가깝다).

외부 접근 실측(한정 조건: 1.1.27 / Linux / 헤드리스 `-p --add-dir` / `allowNonWorkspaceAccess` 기본값 false / `toolPermission: always-proceed`): 파일 도구로 `~/x.txt` 쓰기 1건과 `/etc/hostname` 읽기 1건이 프롬프트 없이 통과했다. 대화형 모드와 명시 `false` 대조군은 미실측이다. `~/.gemini/config/config.json`의 `userSettings.permissions`는 읽히지 않는다(로그 `no shared config permissions`). 프로젝트 권한(`~/.gemini/config/projects/`)의 allow와 전역 deny가 충돌할 때의 우선순위는 미실측.

헤드리스 `-p`는 `--add-dir`가 없으면 워크스페이스가 비어 있고(`workspacePaths: []`), 승인이 필요한 도구는 소프트 거부(exit 0 + stderr 안내)된다.

### 검증

- 정적(모델 미호출): `bash scripts/verify-policies.sh agy` — JSON 객체, 관리 키 열거값, 3배열 명시, 런타임 키 미포함, 규칙 외형 `action(target)`, `regex:` 미사용, `*`는 `action(*)` 또는 리터럴 `/*` 토큰만, deny 필수 항목. 외형 검사이지 엔진 판정이 아니다
- 실측(모델 호출 6회, 쿼터 소모): `bash scripts/agy-live-check.sh` — 판정 근거는 `--output-format stream-json`의 도구 이벤트뿐이다(지시한 명령과 같은 `run_command` 이벤트가 `ERROR`+"deny rule"이면 차단, `DONE`+`output`이면 실행, 이벤트가 없거나 agy 종료 코드가 0이 아니면 판정 불가). 양성 대조·정확 토큰 차단·형제 토큰 통과·접두 차단·환경(`init` 이벤트의 cwd·permission_mode 일치)·전역 규칙 주입(`GEMINI.md` 제목을 도구 호출 없이 인용하는 간접 관측)을 PASS/FAIL/판정 불가로, 글롭 특성은 INFO로 보고. 검사 중 무해한 `printf AGY_CHECK_*` deny 2건을 임시 파일 검증 후 원자 교체로 추가하고, 종료 시 최신 설정에서 그 2건만 제거한다. 이전 실행의 백업이 남아 있거나 표식이 이미 deny에 있으면 어떤 쓰기도 하기 전에 중단하고, 복원에 실패하면 `settings.json.agy-check.bak`을 보존한 채 종료 코드 3으로 끝난다(검사 결과와 무관). 규칙 파일이 없는 임시 디렉토리를 cwd이자 `--add-dir` 워크스페이스로 써서 프로젝트 규칙 상속을 배제한다. 대화형 agy가 동시에 설정을 쓰는 경합은 배제하지 않는다

### 설계 검토 (2026-09-07, Codex와 토론)

- Codex 명시 동의: CLI 층 분리와 IDE 층 미변경, 병합 계약(실패 시 무변경·3배열 교체), 훅 0개·내장 알림 우선
- Codex 보완 반영(동의 확인): 레거시 `~/.gemini/GEMINI.md` 링크 보존, `artifactReviewPolicy: always-proceed`, `*` 검사를 `action(*)`·리터럴 `/*`로 한정, 외부 접근 서술을 실측 조건으로 한정, "deny는 기계 차단·나머지는 지침" 문구
- 실측 스크립트 `agy-live-check.sh`: Codex가 지적한 설정 파일 직접 쓰기·모델 산문 판정·cwd 미격리·복원 실패 종료 코드·백업 소유권을 재구현한 뒤 Codex 정적 재검토 후 구현 동의(운영 전제: 대화형 agy 미실행, 동시 쓰기 경합 미보장). 실행 결과(설치 후 실제 CLI 검사 6건 PASS, 오류 경로 스텁 4건)는 Claude 실행 보고이며 Codex 실행 검증이 아님
- 보류(미실측): 프로젝트 allow vs 전역 deny 우선순위, 대화형 모드 외부 접근, IDE의 `~/.gemini/GEMINI.md` 의존성, `notifications` 실제 발화

## IDE — 추정치 (미검증)

`settings.json`·`hooks/mcp-config-guard.sh`는 2026-07-13 2차 출처 기준 추정치이고 이 머신에서 IDE를 쓰지 않아 검증하지 못했다. CLI 규격과 대조하면 아래가 불일치다.

| 항목 | 상태 | 비고 |
|------|------|------|
| `permissions.{allow,ask,deny}` 구조·우선순위 Deny > Ask > Allow | 🟢 검증 | CLI 공식 문서와 일치 |
| `Bash(<pattern>)`·`Read()`/`Write()` 매처 | 🔴 오류 | 실제는 `command(...)`·`read_file(...)`/`write_file(...)`. CLI 값은 `cli/settings.json`이 대체. IDE용은 재작성 대상 |
| `hooks.before_tool_call` 이벤트·settings.json 내 훅 | 🔴 오류 | 실제 이벤트는 `PreToolUse`/`PostToolUse`/`PreInvocation`/`PostInvocation`/`Stop`, 위치는 별도 `hooks.json` |
| 훅 matcher 셸 도구명 | 🟢 검증 | `run_command` |
| `agentSettings.*` 키 명 | 🟡 추정 | GUI 라벨 기준. 설치 후 diff 필요 |
| IDE 글로벌 settings 경로 | 🟡 미확정 | macOS `~/Library/Application Support/Antigravity/User/settings.json`, Windows `%APPDATA%/Antigravity IDE/User/settings.json`(install.sh가 병합), Linux 미검증(건너뜀) |

## 알려진 보안 이슈 대응 (IDE)

| 이슈 | 출처 | 본 정책 대응 |
|------|------|---------------|
| `.agent/mcp_config.json` 영속 백도어 | Mindgard | `hooks/mcp-config-guard.sh`로 변경 시 ask 발동 (미검증) |
| `webhook.site` 기본 Allowlist | agentpedia | `browserDomainDenylist`로 강제 차단 |
| Linux sandbox 미지원 (symlink 우회 가능) | MaanVader | OS-레벨 격리 불가 → 정책 의존도 100% |
| Turbo mode `chmod -R 777` 폭주 | agentpedia | IDE는 `terminalExecutionPolicy: "off"`. CLI는 always-proceed를 택했으므로 deny + 지침이 같은 역할 |
| 자격증명 탈취 (.env / SSH 키) | Embrace The Red | IDE `permissions.deny`에 `Read(./.env)`, `Read(./**/id_rsa*)` |

## 3-tool 정합성

| 카테고리 | Claude Code | Codex CLI | Antigravity CLI |
|----------|:----:|:----:|:----:|
| FILE_DELETE | 지침 (+deny 파국형) | Starlark forbidden | 지침 (+deny 파국형) |
| SYSTEM | 지침 (+deny 파국형) | Starlark forbidden | 지침 (+deny mkfs·전원) |
| GIT_WRITE | 지침 (rules) | Starlark forbidden | 지침 |
| GIT_STATE | allow | Starlark forbidden | 지침 |
| GH_CLI | 지침 (rules) | Starlark forbidden | 지침 |
| DOCKER_DELETE | 지침 (rules) | Starlark forbidden | 지침 |
| INPLACE | 지침 (rules) | Starlark forbidden | 지침 |
| LINK_FORCE | 지침 (rules) | Starlark forbidden | 지침 |
| PERMISSION | 지침 (rules) | Starlark forbidden | 지침 |
| SHELL_BYPASS | 지침 (rules) | (단일토큰 한계) | 지침 |
| SCRIPT_INJECTION | 지침 (rules) | (단일토큰 한계) | 지침 |

세 도구가 공유하는 것은 "확인 프롬프트 없는 자율 실행" 원칙이지 차단 강도가 아니다. Codex는 위험 명령 전반을 forbidden으로 막고, Claude와 Antigravity CLI는 파국형만 deny하고 나머지는 지침에 맡긴다. Gemini CLI 열은 2026-09-07 은퇴로 제거했고 정책 원본과 회귀 케이스 62건은 `.archive/2026-09-07_gemini-cli-retirement/`에 있다.
