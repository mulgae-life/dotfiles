// Gemini CLI 정책 엔진 복제 테스트 러너 (verify-policies.sh에서 호출)
// 소스 대조: @google/gemini-cli 0.38.1 bundle — packages/core policy/utils.js + stable-stringify.js
// stdin: {"rules": [safety.toml의 rule 배열], "cases": [[command, expected], ...]}
// 한계: 단일 명령 판정만 복제. 복합 명령(;/&&/|)은 실제 엔진이 파트별 재귀 판정 후
//       집계하므로 여기서는 전체 문자열 매칭으로 근사 — 케이스는 단일 명령 위주로 작성할 것.
import { readFileSync } from 'node:fs';

// ── isSafeRegExp: ReDoS 가드 (중첩 수량자·2048자 초과 시 규칙째 무효) ──
function isSafeRegExp(pattern) {
  try { new RegExp(pattern); } catch { return false; }
  if (pattern.length > 2048) return false;
  const nestedQuantifierPattern = /\([^)]*[*+?{].*\)[*+?{]/;
  if (nestedQuantifierPattern.test(pattern)) return false;
  return true;
}
function escapeRegex(text) {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s"]/g, '\\$&');
}
// ── buildArgsPatterns: 최종 패턴 = `"command":"` + commandRegex ──
function buildArgsPatterns(commandPrefix, commandRegex) {
  if (commandPrefix) {
    const prefixes = Array.isArray(commandPrefix) ? commandPrefix : [commandPrefix];
    return prefixes.map((prefix) => {
      const encodedPrefix = JSON.stringify(prefix);
      const openQuotePrefix = encodedPrefix.substring(0, encodedPrefix.length - 1);
      const matchSegment = escapeRegex(`"command":${openQuotePrefix}`);
      return `${matchSegment}(?:[\\s"]|\\\\")`;
    });
  }
  if (commandRegex) return [`"command":"${commandRegex}`];
  return [];
}
// ── stableStringify: top-level pair를 \0로 감싸는 정렬 직렬화 ──
function stableStringify(obj) {
  const stringify = (o, top = false) => {
    if (o === null || o === undefined) return 'null';
    if (typeof o !== 'object') return JSON.stringify(o);
    if (Array.isArray(o)) return '[' + o.map((i) => stringify(i)).join(',') + ']';
    const pairs = [];
    for (const key of Object.keys(o).sort()) {
      let pairStr = JSON.stringify(key) + ':' + stringify(o[key]);
      if (top) pairStr = '\0' + pairStr + '\0';
      pairs.push(pairStr);
    }
    return '{' + pairs.join(',') + '}';
  };
  return stringify(obj, true);
}

// ── 판정: 매칭 규칙 중 최고 priority, 없으면 defaultDecision(ask_user, interactive) ──
const { rules, cases } = JSON.parse(readFileSync(0, 'utf-8'));
const compiled = [];
const invalid = [];
for (const r of rules) {
  for (const p of buildArgsPatterns(r.commandPrefix, r.commandRegex)) {
    if (!isSafeRegExp(p)) { invalid.push(r.commandRegex ?? r.commandPrefix); continue; }
    compiled.push({ re: new RegExp(p), decision: r.decision, priority: r.priority ?? 0 });
  }
}
if (invalid.length) {
  console.log('FAIL [무효 규칙 — isSafeRegExp 거부]');
  for (const i of invalid) console.log('  ', i);
}
let pass = 0, fail = 0;
for (const [command, expected] of cases) {
  const args = stableStringify({ command });
  let best = null;
  for (const c of compiled) {
    if (c.re.test(args) && (!best || c.priority > best.priority)) best = c;
  }
  const decision = best ? best.decision : 'ask_user';
  const ok = decision === expected;
  ok ? pass++ : fail++;
  console.log(`${ok ? 'PASS' : 'FAIL'} [기대=${expected} 실제=${decision}] ${command}`);
}
console.log(`gemini 소계: ${pass} PASS / ${fail} FAIL${invalid.length ? ` / 무효 규칙 ${invalid.length}` : ''}`);
process.exit(fail || invalid.length ? 1 : 0);
