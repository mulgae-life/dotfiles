#!/usr/bin/env python3
"""프로젝트의 Claude Code·Codex 세션 기록(jsonl)을 회고용 요약으로 만든다.

기록 원문은 수 MB라 그대로 읽을 수 없다. 이 스크립트는 사용자 메시지, 도구 호출 흐름,
읽은 파일과 고친 파일, 반복 읽기·반복 검색, 실패한 명령, 사용자 중단만 뽑아 마크다운으로 낸다.
판단(무엇이 헛걸음인지, 무엇이 정정인지)은 하지 않는다 — 그건 읽는 쪽의 몫이다.

사용 예:
  python3 session_digest.py --list                 # 이 프로젝트의 세션 목록
  python3 session_digest.py                        # 가장 최근 세션 1개
  python3 session_digest.py --last 3 --no-timeline # 최근 3개, 집계만
  python3 session_digest.py --since 2026-09-01     # 그 날짜 이후 세션 전부
  python3 session_digest.py --session <jsonl 경로>
"""
from __future__ import annotations

import argparse
import json
import os
import re
import shlex
import signal
import subprocess
import sys
from collections import Counter, defaultdict
from dataclasses import dataclass, field
from pathlib import Path

# 사용자 메시지처럼 보이지만 도구가 주입한 문맥인 것들
INJECTED_PREFIXES = (
    "# AGENTS.md instructions",
    "<environment_context>",
    "<user_instructions>",
    "<skill>",
    "<system-reminder>",
    "<local-command-stdout>",
    "<local-command-caveat>",
    "Base directory for this skill",
    "Caveat: The messages below",
)
READ_CMDS = {"cat", "sed", "head", "tail", "nl", "less", "bat"}
SEARCH_CMDS = {"grep", "rg", "find", "ls", "fd", "tree", "wc", "stat", "du", "file"}
NEUTRAL_CMDS = {"cd", "echo", "printf", "true", "sort", "uniq", "cut", "tr"}
NON_CALL = {"user", "reply", "interrupt", "compact"}  # 도구 호출이 아닌 이벤트


@dataclass
class Event:
    kind: str  # user | reply | interrupt | read | search | edit | cmd | skill | agent | web | mcp | compact | tool
    ts: str
    text: str
    path: str = ""
    size: int = 0
    failed: bool = False
    error: str = ""


@dataclass
class Session:
    tool: str
    path: Path
    sid: str = ""
    cwd: str = ""
    start: str = ""
    end: str = ""
    forked_from: str = ""
    parent_mentions: int = 0  # 상위 경로에서 연 세션이면 이 프로젝트를 언급한 줄 수
    events: list[Event] = field(default_factory=list)


# ---------- 탐색 ----------

def project_root(arg: str | None) -> Path:
    if arg:
        return Path(arg).resolve()
    try:
        out = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True, check=True)
        return Path(out.stdout.strip()).resolve()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return Path.cwd().resolve()


def under(cwd: str, root: Path) -> bool:
    cwd = cwd.removeprefix("file://")
    return cwd == str(root) or cwd.startswith(str(root) + "/")


def is_ancestor(cwd: str, root: Path) -> bool:
    cwd = cwd.removeprefix("file://").rstrip("/") or "/"
    return cwd != str(root) and str(root).startswith(cwd.rstrip("/") + "/")


def mentions(path: Path, root: Path) -> int:
    """상위 경로에서 연 세션이 이 프로젝트 경로를 몇 줄에서 언급하는지 센다."""
    needle = str(root)
    try:
        with path.open(encoding="utf-8", errors="replace") as fh:
            return sum(needle in line for line in fh)
    except OSError:
        return 0


def claude_files(root: Path) -> list[tuple[Path, int]]:
    """(경로, 상위 경로 세션의 언급 줄 수 — 이 프로젝트에서 연 세션이면 0)"""
    base = Path(os.environ.get("CLAUDE_CONFIG_DIR", Path.home() / ".claude")) / "projects"
    if not base.is_dir():
        return []
    enc = re.sub(r"[^A-Za-z0-9]", "-", str(root))
    ancestors = {re.sub(r"[^A-Za-z0-9]", "-", str(p)) for p in root.parents if str(p) != "/"}
    files = []
    for d in base.iterdir():
        if not d.is_dir():
            continue
        if d.name == enc or d.name.startswith(enc + "-"):
            files += [(f, 0) for f in d.glob("*.jsonl")]
        elif d.name in ancestors:
            files += [(f, n) for f in d.glob("*.jsonl") if (n := mentions(f, root))]
    return files


def codex_files(root: Path) -> list[tuple[Path, dict, int]]:
    base = Path(os.environ.get("CODEX_HOME", Path.home() / ".codex"))
    found = []
    for sub in ("sessions", "archived_sessions"):
        d = base / sub
        if not d.is_dir():
            continue
        for f in d.rglob("rollout-*.jsonl"):
            try:
                with f.open(encoding="utf-8") as fh:
                    first = json.loads(fh.readline())
            except (OSError, json.JSONDecodeError):
                continue
            meta = first.get("payload", {}) if first.get("type") == "session_meta" else {}
            if not meta:
                continue
            if under(meta.get("cwd", ""), root):
                found.append((f, meta, 0))
            elif is_ancestor(meta.get("cwd", ""), root) and (n := mentions(f, root)):
                found.append((f, meta, n))
    return found


# ---------- 파싱 ----------

def short(s: str, n: int) -> str:
    s = re.sub(r"\s+", " ", s or "").strip()
    return s if len(s) <= n else s[: n - 1] + "…"


def rel(p: str, root: Path) -> str:
    p = p.removeprefix("file://")
    r = str(root) + "/"
    return p[len(r):] if p.startswith(r) else p


def is_injected(text: str) -> bool:
    t = text.lstrip()
    return not t or t.startswith(INJECTED_PREFIXES)


def shell_events(ts: str, cmd: str, root: Path, size: int = 0) -> list[Event]:
    """셸 명령을 읽기·검색·기타로 대략 나눈다(휴리스틱).

    `nl -ba A && nl -ba B`처럼 읽기만 이어 붙인 명령은 파일마다 읽기 이벤트를 만들고,
    결과 크기는 균등하게 나눠 붙인다(추정치). 다른 동작이 섞이면 명령 하나로 둔다.
    """
    parts = []
    for seg in re.split(r"\s*(?:&&|\|\||;|\|)\s*", cmd.strip()):
        try:
            toks = shlex.split(seg)
        except ValueError:
            toks = seg.split()
        if not toks or toks[0] in NEUTRAL_CMDS:
            continue
        head = toks[0]
        args = [t for t in toks[1:] if not t.startswith("-") and not re.fullmatch(r"[\d,p]+", t)]
        if head in READ_CMDS:
            if args:  # 파일 인자 없는 head·sed는 파이프 중간 가공이라 무시
                parts.append(("read", args[-1]))
        elif head in SEARCH_CMDS or (head == "git" and toks[1:2] == ["grep"]):
            parts.append(("search", seg))
        else:
            parts.append(("cmd", seg))
    reads = [t for k, t in parts if k == "read"]
    if parts and all(k in ("read", "search") for k, _ in parts) and reads:
        each = size // len(reads)
        return [Event("read", ts, cmd, path=rel(t, root), size=each) for t in reads]
    if parts and all(k == "search" for k, _ in parts):
        return [Event("search", ts, cmd, size=size)]
    return [Event("cmd", ts, cmd, size=size)]


def add_reply(s: Session, ts: str, text: str) -> None:
    """에이전트 답변. 같은 글이 이벤트 두 종류로 겹쳐 기록되는 버전이 있어 연달아 같으면 버린다."""
    text = (text or "").strip()
    if not text:
        return
    last = next((e for e in reversed(s.events) if e.kind == "reply"), None)
    if last is None or last.text != text:
        s.events.append(Event("reply", ts, text))


def result_text(content) -> str:
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        return "\n".join(b.get("text", "") for b in content if isinstance(b, dict))
    return ""


def parse_claude(path: Path, root: Path) -> Session:
    s = Session("claude", path, sid=path.stem)
    pending: dict[str, Event] = {}
    bash_pending: dict[str, list[Event]] = {}
    with path.open(encoding="utf-8") as fh:
        for line in fh:
            try:
                o = json.loads(line)
            except json.JSONDecodeError:
                continue
            ts = o.get("timestamp", "")
            if ts:
                s.start = s.start or ts
                s.end = ts
            if o.get("cwd") and not s.cwd:
                s.cwd = o["cwd"]
            if o.get("isCompactSummary"):
                s.events.append(Event("compact", ts, "압축 요약 삽입"))
                continue
            t = o.get("type")
            msg = o.get("message") or {}
            content = msg.get("content")
            if t == "user":
                if o.get("isMeta"):
                    continue
                blocks = [{"type": "text", "text": content}] if isinstance(content, str) else (content or [])
                for b in blocks:
                    if b.get("type") == "tool_result":
                        tid = b.get("tool_use_id", "")
                        evs = bash_pending.pop(tid, None) or ([pending.pop(tid)] if tid in pending else [])
                        txt = result_text(b.get("content"))
                        for ev in evs:
                            ev.size = len(txt) // len(evs)
                            if b.get("is_error"):
                                ev.failed = True
                                ev.error = short(txt.splitlines()[0] if txt else "", 160)
                    elif b.get("type") == "text":
                        txt = b.get("text", "")
                        if txt.startswith("[Request interrupted by user"):
                            s.events.append(Event("interrupt", ts, "사용자 중단"))
                        elif txt.startswith("<command-name>") or "<command-name>" in txt[:200]:
                            m = re.search(r"<command-name>(.*?)</command-name>", txt)
                            a = re.search(r"<command-args>(.*?)</command-args>", txt, re.S)
                            s.events.append(Event("user", ts, f"{m.group(1) if m else ''} {a.group(1) if a else ''}".strip()))
                        elif not is_injected(txt):
                            s.events.append(Event("user", ts, txt))
            elif t == "assistant" and isinstance(content, list):
                for b in content:
                    if b.get("type") == "text" and b.get("text", "").strip():
                        add_reply(s, ts, b["text"])
                    if b.get("type") != "tool_use":
                        continue
                    name, inp = b.get("name", ""), b.get("input", {}) or {}
                    if name == "Read":
                        ev = Event("read", ts, "Read", path=rel(inp.get("file_path", ""), root))
                    elif name in ("Grep", "Glob"):
                        ev = Event("search", ts, f"{name} {inp.get('pattern', '')} {rel(inp.get('path', ''), root)}".strip())
                    elif name in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
                        ev = Event("edit", ts, name, path=rel(inp.get("file_path", inp.get("notebook_path", "")), root))
                    elif name == "Bash":
                        evs = shell_events(ts, inp.get("command", ""), root)
                        s.events += evs
                        bash_pending[b.get("id", "")] = evs
                        continue
                    elif name == "Skill":
                        ev = Event("skill", ts, inp.get("skill", ""))
                    elif name in ("Agent", "Task"):
                        ev = Event("agent", ts, inp.get("description", "") or short(inp.get("prompt", ""), 80))
                    elif name in ("WebFetch", "WebSearch"):
                        ev = Event("web", ts, inp.get("url", "") or inp.get("query", ""))
                    elif name.startswith("mcp__"):
                        ev = Event("mcp", ts, name)
                    else:
                        ev = Event("tool", ts, name)
                    s.events.append(ev)
                    pending[b.get("id", "")] = ev
    return s


def codex_cmd_events(ts: str, command, parsed, exit_code, output: str, root: Path) -> list[Event]:
    cmd = command[-1] if isinstance(command, list) and command else str(command or "")
    size = len(output or "")
    parsed = [p for p in (parsed or []) if isinstance(p, dict)]
    kinds = [p.get("type") for p in parsed]
    if kinds and all(k == "read" for k in kinds):
        each = size // len(parsed)
        evs = [Event("read", ts, cmd, path=rel(p.get("path") or p.get("name") or "", root), size=each) for p in parsed]
    elif kinds and all(k in ("search", "list_files") for k in kinds):
        evs = [Event("search", ts, cmd, size=size)]
    else:
        evs = shell_events(ts, cmd, root, size)
    try:
        code = int(exit_code) if exit_code is not None else 0
    except (TypeError, ValueError):
        code = 0
    if code != 0:
        tail = (output or "").strip().splitlines()
        for ev in evs:
            ev.failed = True
            ev.error = f"exit {code}: " + short(tail[-1] if tail else "", 140)
    return evs


JS_CMD = re.compile(r"""exec_command\(\s*\{\s*cmd\s*:\s*(?:"((?:[^"\\]|\\.)*)"|'((?:[^'\\]|\\.)*)'|`([^`]*)`)""")
JS_PATCH_FILE = re.compile(r"\*\*\* (?:Update|Add|Delete) File: (\S+)")


def js_string(raw: str) -> str:
    try:
        return json.loads('"' + raw.replace("\\'", "'") + '"')
    except json.JSONDecodeError:
        return raw


def codex_js_events(ts: str, code: str, output: str, root: Path) -> list[Event]:
    """중간 형식(0.14x 무렵): 명령이 `exec` 도구의 JS 코드 안에 들어 있고 별도 종료 이벤트가 없다."""
    cmds = [js_string(m.group(1) or m.group(2) or m.group(3) or "") for m in JS_CMD.finditer(code)]
    codes = [int(c) for c in re.findall(r'\\?"exit_code\\?"\s*:\s*(-?\d+)', output or "")]
    evs = []
    for i, cmd in enumerate(cmds):
        code_i = codes[i] if len(codes) == len(cmds) else 0
        evs += codex_cmd_events(ts, [cmd], None, code_i, "", root)
    evs += [Event("edit", ts, "apply_patch", path=rel(f, root)) for f in JS_PATCH_FILE.findall(code)]
    return evs


def parse_codex(path: Path, meta: dict, root: Path) -> Session:
    s = Session("codex", path, sid=meta.get("id", path.stem), cwd=meta.get("cwd", ""),
                forked_from=meta.get("forked_from_id") or "")
    js_calls: dict[str, tuple[str, str]] = {}  # call_id → (ts, code)
    fn_calls: dict[str, tuple[str, str]] = {}  # call_id → (ts, cmd)
    js_events: list[Event] = []
    has_cmd_events = has_patch_events = False
    with path.open(encoding="utf-8") as fh:
        for line in fh:
            try:
                o = json.loads(line)
            except json.JSONDecodeError:
                continue
            ts = o.get("timestamp", "")
            if ts:
                s.start = s.start or ts
                s.end = ts
            if o.get("type") == "compacted":
                s.events.append(Event("compact", ts, "압축"))
                continue
            p = o.get("payload", {})
            pt = p.get("type")
            if o.get("type") == "response_item":
                if pt == "custom_tool_call" and p.get("name") == "exec":
                    js_calls[p.get("call_id", "")] = (ts, p.get("input", ""))
                elif pt == "custom_tool_call_output" and p.get("call_id") in js_calls:
                    cts, code = js_calls.pop(p["call_id"])
                    js_events += codex_js_events(cts, code, str(p.get("output", "")), root)
                # 초기 형식(0.11x 무렵): 함수 호출과 출력만 있고 종료 이벤트가 없다
                elif pt == "function_call" and p.get("name") == "exec_command":
                    try:
                        cmd = json.loads(p.get("arguments", "{}")).get("cmd", "")
                    except json.JSONDecodeError:
                        cmd = ""
                    fn_calls[p.get("call_id", "")] = (ts, cmd)
                elif pt == "function_call" and p.get("name") == "spawn_agent":
                    s.events.append(Event("agent", ts, "spawn_agent"))
                elif pt == "function_call_output" and p.get("call_id") in fn_calls:
                    cts, cmd = fn_calls.pop(p["call_id"])
                    out = str(p.get("output", ""))
                    m = re.search(r"Process exited with code (-?\d+)", out)
                    body = out.split("Output:\n", 1)[1] if "Output:\n" in out else ""
                    js_events += codex_cmd_events(cts, [cmd], None, m.group(1) if m else 0, body, root)
                continue
            if o.get("type") != "event_msg":
                continue
            itype0 = p.get("item", {}).get("type") if pt == "item_completed" else None
            if pt == "exec_command_end" or itype0 == "CommandExecution":
                has_cmd_events = True
            if pt == "patch_apply_end" or itype0 == "FileChange":
                has_patch_events = True
            if pt == "web_search_end":
                s.events.append(Event("web", ts, str(p.get("query", ""))))
            # 구형 이벤트(0.118 무렵)
            if pt == "user_message":
                txt = p.get("message", "")
                if not is_injected(txt):
                    s.events.append(Event("user", ts, txt))
            elif pt == "agent_message":
                add_reply(s, ts, p.get("message", ""))
            elif pt == "turn_aborted":
                s.events.append(Event("interrupt", ts, f"턴 중단({p.get('reason', '')})"))
            elif pt == "exec_command_end":
                s.events += codex_cmd_events(ts, p.get("command"), p.get("parsed_cmd"), p.get("exit_code"),
                                             p.get("aggregated_output", ""), root)
            elif pt == "patch_apply_end":
                for f in (p.get("changes") or {}):
                    s.events.append(Event("edit", ts, "apply_patch", path=rel(f, root), failed=not p.get("success", True)))
            # 신형 이벤트(0.15x 무렵): item_completed 하나로 통일
            elif pt == "item_completed":
                it = p.get("item", {})
                itype = it.get("type")
                if itype == "UserMessage":
                    txt = "\n".join(c.get("text", "") for c in it.get("content", []) if isinstance(c, dict))
                    if not is_injected(txt):
                        s.events.append(Event("user", ts, txt))
                elif itype == "AgentMessage":
                    add_reply(s, ts, "\n".join(c.get("text", "") for c in it.get("content", []) if isinstance(c, dict)))
                elif itype == "CommandExecution":
                    s.events += codex_cmd_events(ts, it.get("command"), it.get("parsed_cmd"), it.get("exit_code"),
                                                 it.get("aggregated_output", ""), root)
                elif itype == "FileChange":
                    for f in (it.get("changes") or {}):
                        s.events.append(Event("edit", ts, "apply_patch", path=rel(f, root),
                                              failed=it.get("status") not in (None, "completed")))
                elif itype == "McpToolCall":
                    s.events.append(Event("mcp", ts, f"{it.get('server', '')}.{it.get('tool', '')}"))
                elif itype == "Extension" and str(it.get("kind", "")).startswith("web"):
                    s.events.append(Event("web", ts, str(it.get("query", ""))))
    # 종료 이벤트가 있는 종류는 응답 항목 파싱이 중복이 되므로 버린다
    for cts, code in js_calls.values():  # 출력이 기록되지 않은 호출
        js_events += codex_js_events(cts, code, "", root)
    js_events = [e for e in js_events
                 if not ((e.kind == "edit" and has_patch_events) or (e.kind != "edit" and has_cmd_events))]
    if js_events:
        s.events += js_events
        s.events.sort(key=lambda e: e.ts)
    return s


# ---------- 출력 ----------

def hhmm(ts: str) -> str:
    return ts[11:16] if len(ts) >= 16 else ts


def summarize(s: Session, root: Path, timeline: bool, max_lines: int) -> str:
    out = []
    users = [e for e in s.events if e.kind == "user"]
    calls = [e for e in s.events if e.kind not in NON_CALL]
    fails = [e for e in calls if e.failed]
    inter = [e for e in s.events if e.kind == "interrupt"]
    fork = f" · fork(원본 {s.forked_from[:8]})" if s.forked_from else ""
    end = s.end[11:16] if s.end[:10] == s.start[:10] else s.end[:16].replace("T", " ")
    out.append(f"## {s.tool} {s.sid[:8]} · {s.start[:16].replace('T', ' ')} ~ {end}{fork}")
    out.append(f"- 기록: `{s.path}`" + (f" (상위 경로 `{s.cwd}`에서 연 세션 — 이 프로젝트와 무관한 부분 포함)"
                                        if s.cwd and not under(s.cwd, root) else ""))
    out.append(f"- 사용자 메시지 {len(users)} · 도구 호출 {len(calls)} · 실패 {len(fails)} · 중단 {len(inter)} · "
               f"압축 {sum(e.kind == 'compact' for e in s.events)}")

    reads = [e for e in calls if e.kind == "read" and e.path]
    edits = {e.path for e in calls if e.kind == "edit"}
    guide = [e for e in reads if "agent-guide/" in e.path or e.path in ("CLAUDE.md", "AGENTS.md")]
    if guide:
        agg: dict[str, list[int]] = defaultdict(list)
        for e in guide:
            agg[e.path].append(e.size)
        out.append("\n### 지침 문서 읽기")
        for p, sizes in agg.items():
            total = f"결과 합계 {sum(sizes):,}자" if sum(sizes) else "결과 크기 기록 없음"
            out.append(f"- `{p}` {len(sizes)}회, {total}")

    read_bytes: dict[str, int] = defaultdict(int)
    read_count: Counter = Counter()
    for e in reads:
        read_bytes[e.path] += e.size
        read_count[e.path] += 1
    only_read = sorted((p for p in read_bytes if p not in edits), key=lambda p: -read_bytes[p])
    out.append(f"\n### 고친 파일 ({len(edits)})")
    out.extend(f"- `{p}`" for p in sorted(edits)[:40]) if edits else out.append("- 없음")
    if len(edits) > 40:
        out.append(f"- … 외 {len(edits) - 40}개")
    out.append(f"\n### 읽기만 한 파일 (상위 15, 전체 {len(only_read)}) — 참고용으로 쓰였을 수 있으니 헛걸음으로 단정하지 말 것")
    out.extend(f"- `{p}` {read_count[p]}회 {read_bytes[p]:,}자" for p in only_read[:15])

    rep = [(p, c) for p, c in read_count.items() if c >= 3]
    if rep:
        out.append("\n### 같은 파일 3회 이상 읽기")
        out.extend(f"- `{p}` {c}회" for p, c in sorted(rep, key=lambda x: -x[1]))
    srch = Counter(short(e.text, 100) for e in calls if e.kind == "search")
    rep_s = [(k, c) for k, c in srch.items() if c >= 2]
    if rep_s:
        out.append("\n### 같은 검색 2회 이상")
        out.extend(f"- {c}회: `{k}`" for k, c in sorted(rep_s, key=lambda x: -x[1]))
    if fails:
        out.append("\n### 실패한 호출")
        out.extend(f"- {hhmm(e.ts)} {e.kind} `{short(e.text if e.kind != 'edit' else e.path, 90)}` — {e.error}" for e in fails[:30])

    out.append("\n### 사용자 메시지")
    for i, e in enumerate(users, 1):
        extra = f" ({len(e.text):,}자)" if len(e.text) > 400 else ""
        out.append(f"- U{i} {hhmm(e.ts)} {short(e.text, 400)}{extra}")

    if timeline:
        out.append("\n### 흐름 (U=사용자, A=에이전트 답변, ✗=실패, ⏹=중단)")
        n_user, lines = 0, []
        for e in s.events:
            if e.kind == "user":
                n_user += 1
                lines.append(f"U{n_user} {hhmm(e.ts)} {short(e.text, 120)}")
            elif e.kind == "reply":
                lines.append(f"A {hhmm(e.ts)} {short(e.text, 150)}")
            elif e.kind == "interrupt":
                lines.append(f"⏹ {hhmm(e.ts)} {e.text}")
            elif e.kind == "compact":
                lines.append(f"— {hhmm(e.ts)} {e.text}")
            else:
                mark = "✗ " if e.failed else ""
                target = e.path if e.kind in ("read", "edit") and e.path else e.text
                size = f" ({e.size:,}자)" if e.kind == "read" and e.size else ""
                lines.append(f"  {mark}{e.kind} {short(target, 120)}{size}")
        if len(lines) > max_lines:
            head = max_lines * 2 // 3
            lines = lines[:head] + [f"  … {len(lines) - max_lines}줄 생략 (--max-lines로 늘림) …"] + lines[-(max_lines - head):]
        out.append("```")
        out.extend(lines)
        out.append("```")
    return "\n".join(out)


def conversation(s: Session, limit: int) -> str:
    """도구 호출을 빼고 사용자와 에이전트의 말만 시간순으로. 정정 직전에 에이전트가 무엇을 보고했는지 볼 때 쓴다."""
    out = [f"## {s.tool} {s.sid[:8]} · {s.start[:16].replace('T', ' ')} — 대화만 (메시지당 {limit}자)"]
    n_user = 0
    for e in s.events:
        if e.kind == "user":
            n_user += 1
            out.append(f"\n[U{n_user} {hhmm(e.ts)}] {short(e.text, limit)}")
        elif e.kind == "reply":
            out.append(f"[A {hhmm(e.ts)}] {short(e.text, limit)}")
        elif e.kind == "interrupt":
            out.append(f"[⏹ {hhmm(e.ts)}]")
    return "\n".join(out)


def main() -> int:
    if hasattr(signal, "SIGPIPE"):  # `| head`로 잘라 볼 때 BrokenPipeError 소음 방지
        signal.signal(signal.SIGPIPE, signal.SIG_DFL)
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--root", help="프로젝트 루트 (기본: git 루트 또는 현재 디렉토리)")
    ap.add_argument("--tool", choices=("claude", "codex", "all"), default="all")
    ap.add_argument("--last", type=int, default=1, help="최근 N개 세션 (기본 1)")
    ap.add_argument("--since", help="이 날짜(YYYY-MM-DD) 이후 끝난 세션 전부 (--last보다 우선)")
    ap.add_argument("--session", action="append", help="특정 jsonl 경로 (여러 번 지정 가능)")
    ap.add_argument("--include-forks", action="store_true", help="Codex 분기 세션 포함 (원본 기록을 복사해 중복이 많다)")
    ap.add_argument("--list", action="store_true", help="세션 목록만 출력")
    ap.add_argument("--no-timeline", action="store_true", help="흐름 절 생략")
    ap.add_argument("--max-lines", type=int, default=300, help="흐름 절 최대 줄 수 (기본 300)")
    ap.add_argument("--conversation", type=int, nargs="?", const=600, metavar="N",
                    help="도구 호출 없이 사용자·에이전트 대화만 출력 (메시지당 N자, 기본 600)")
    a = ap.parse_args()

    root = project_root(a.root)
    sessions: list[Session] = []
    if a.session:
        for sp in a.session:
            p = Path(sp).expanduser().resolve()
            with p.open(encoding="utf-8") as fh:
                first = json.loads(fh.readline())
            if first.get("type") == "session_meta":
                sessions.append(parse_codex(p, first.get("payload", {}), root))
            else:
                sessions.append(parse_claude(p, root))
    else:
        if a.tool in ("claude", "all"):
            for f, n in claude_files(root):
                s = parse_claude(f, root)
                s.parent_mentions = n
                sessions.append(s)
        if a.tool in ("codex", "all"):
            for f, m, n in codex_files(root):
                s = parse_codex(f, m, root)
                s.parent_mentions = n
                sessions.append(s)
        if not a.include_forks:
            sessions = [s for s in sessions if not s.forked_from]
        sessions = [s for s in sessions if any(e.kind == "user" for e in s.events)]
        sessions.sort(key=lambda s: s.end)

    if not sessions:
        print(f"세션 기록 없음: {root} (Claude ~/.claude/projects, Codex ~/.codex/sessions 기준). "
              "다른 환경에서 작업했다면 그 환경에서 실행하거나 --session으로 경로를 지정한다.")
        return 1

    if a.list:
        print(f"프로젝트: {root}\n")
        print("| 도구 | 시작 | 끝 | 사용자 | 호출 | 출처 | 기록 |\n|---|---|---|---|---|---|---|")
        for s in sessions:
            u = sum(e.kind == "user" for e in s.events)
            c = sum(e.kind not in NON_CALL for e in s.events)
            origin = "분기" if s.forked_from else (f"상위 경로({s.cwd}), 언급 {s.parent_mentions}줄" if s.parent_mentions else "")
            print(f"| {s.tool} | {s.start[:16].replace('T', ' ')} | {s.end[:16].replace('T', ' ')} | {u} | {c} | "
                  f"{origin} | `{s.path}` |")
        if any(s.parent_mentions for s in sessions):
            print("\n상위 경로 세션은 다른 일과 섞여 있다. 관련 있으면 --session으로 따로 요약한다 (--last·--since 선택에서는 빠진다).")
        return 0

    if not a.session:
        sessions = [s for s in sessions if not s.parent_mentions]
        sessions = [s for s in sessions if s.end[:10] >= a.since] if a.since else sessions[-a.last:]
    print(f"# 세션 기록 요약 — {root}\n")
    for s in sessions:
        print(conversation(s, a.conversation) if a.conversation else summarize(s, root, not a.no_timeline, a.max_lines))
        print()
    return 0


if __name__ == "__main__":
    sys.exit(main())
