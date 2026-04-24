#!/usr/bin/env node
/**
 * ═══════════════════════════════════════════════════════════════════
 *  HW Design — Token Audit
 *
 *  프로젝트 내 CSS/SCSS/Tailwind 파일에서 하드코딩된 hex·px·ms/s 값과
 *  Tailwind arbitrary px 유틸리티를 찾아내 정정 토큰을 제안한다.
 *  Node 18+ 단독 실행, 외부 의존성 0.
 *
 *  사용법:
 *    node token-audit.mjs                    # 프로젝트 루트에서 실행
 *    node token-audit.mjs --format json      # JSON 리포트
 *    node token-audit.mjs --strict           # warning 도 exit 1
 *    node token-audit.mjs src/components     # 특정 디렉토리만
 *
 *  Exit codes:
 *    0 — 오류 없음 (경고만 있을 수 있음)
 *    1 — 오류 발견 (또는 --strict 에서 경고 발견)
 * ═══════════════════════════════════════════════════════════════════ */

import { readFileSync, readdirSync, statSync } from "node:fs";
import { join, relative, extname } from "node:path";

// ────────────────────────────────────────────────────────────────────
//  Config
// ────────────────────────────────────────────────────────────────────

const SCAN_EXTS = new Set([".css", ".scss", ".sass", ".less", ".tsx", ".jsx", ".ts", ".js", ".vue", ".svelte", ".html"]);
const IGNORE_DIRS = new Set(["node_modules", ".next", ".git", "dist", "build", "out", ".turbo", "coverage", ".claude"]);

// HW 브랜드 토큰으로 매핑되는 hex 테이블
const HEX_TO_TOKEN = new Map([
  ["#f37321", "var(--color-primary)"],
  ["#e06a1b", "var(--color-primary-hover)"],
  ["#c75e14", "var(--color-primary-pressed)"],
  ["#fff3eb", "var(--color-primary-bg)"],
  ["#fdeede", "var(--color-primary-bg-subtle)"],
  ["#1a2b4a", "var(--color-neutral) or var(--color-text)"],
  ["#2d4168", "var(--color-neutral-light)"],
  ["#3d537f", "var(--color-neutral-muted)"],
  ["#ffffff", "var(--color-surface)"],
  ["#fff",    "var(--color-surface)"],
  ["#f7f9fc", "var(--color-surface-secondary)"],
  ["#eef2f7", "var(--color-surface-tertiary)"],
  ["#cbd5e0", "var(--color-border)"],
  ["#e2e8f0", "var(--color-border-light)"],
  ["#000000", "var(--color-text-primary)  # 순검정 금지! 네이비(#1A2B4A)를 쓴다"],
  ["#000",    "var(--color-text-primary)  # 순검정 금지! 네이비(#1A2B4A)를 쓴다"],
  ["#16a34a", "var(--color-success)"],
  ["#dcfce7", "var(--color-success-bg)"],
  ["#b45309", "var(--color-warning)"],
  ["#fef3c7", "var(--color-warning-bg)"],
  ["#dc2626", "var(--color-danger)"],
  ["#fee2e2", "var(--color-danger-bg)"],
  ["#3b82f6", "var(--color-info)"],
  ["#eff6ff", "var(--color-info-bg)"],
]);

// HW 공식 spacing 토큰
const PX_TO_TOKEN = new Map([
  ["4",   "var(--space-50)"],
  ["8",   "var(--space-100)"],
  ["12",  "var(--space-150)"],
  ["16",  "var(--space-200)"],
  ["24",  "var(--space-300)"],
  ["32",  "var(--space-400)"],
  ["48",  "var(--space-600)"],
  ["80",  "var(--space-800)"],
  ["128", "var(--space-hero)"],
]);

// HW 공식 radius 토큰
const RADIUS_TO_TOKEN = new Map([
  ["4",    "var(--radius-sm)"],
  ["8",    "var(--radius-md)"],
  ["12",   "var(--radius-lg)"],
  ["16",   "var(--radius-xl)"],
  ["20",   "var(--radius-2xl)"],
  ["24",   "var(--radius-3xl)"],
  ["9999", "var(--radius-full)"],
]);

// DESIGN.md 컴포넌트 크기 토큰과 직접 연결되는 값
const SIZE_TO_TOKEN = new Map([
  ["36",  "DESIGN.md Button sm height 또는 프로젝트 --size-* 토큰"],
  ["40",  "DESIGN.md components.avatar.size 또는 프로젝트 --size-avatar-md"],
  ["44",  "DESIGN.md components.button-*.height 또는 프로젝트 --size-control-md"],
  ["48",  "DESIGN.md components.input.height 또는 프로젝트 --size-input-md"],
  ["52",  "DESIGN.md Button lg height 또는 프로젝트 --size-control-lg"],
  ["84",  "DESIGN.md components.brand-logo.height-nav"],
  ["104", "DESIGN.md components.nav-top.height"],
]);

// HW 공식 duration 토큰
const DURATION_TO_TOKEN = new Map([
  ["250ms", "var(--motion-fast)"],
  ["350ms", "var(--motion-base)"],
  ["550ms", "var(--motion-slow)"],
  ["0.25s", "var(--motion-fast)"],
  ["0.35s", "var(--motion-base)"],
  ["0.55s", "var(--motion-slow)"],
]);

const HW_DURATIONS = new Set(["250ms", "350ms", "550ms", "0.25s", "0.35s", "0.55s"]);

const SPACING_PROPS = new Set([
  "padding", "padding-top", "padding-right", "padding-bottom", "padding-left",
  "padding-inline", "padding-inline-start", "padding-inline-end",
  "padding-block", "padding-block-start", "padding-block-end",
  "margin", "margin-top", "margin-right", "margin-bottom", "margin-left",
  "margin-inline", "margin-inline-start", "margin-inline-end",
  "margin-block", "margin-block-start", "margin-block-end",
  "gap", "row-gap", "column-gap",
  "top", "right", "bottom", "left",
  "inset", "inset-inline", "inset-inline-start", "inset-inline-end",
  "inset-block", "inset-block-start", "inset-block-end",
]);

const SIZE_PROPS = new Set(["width", "height", "min-width", "max-width", "min-height", "max-height"]);

function normalizeProp(prop) {
  return prop.replace(/[A-Z]/g, m => `-${m.toLowerCase()}`).toLowerCase();
}

function lengthRuleForProperty(prop) {
  if (SPACING_PROPS.has(prop)) {
    return {
      kind: "spacing",
      label: "spacing",
      knownRule: "hardcoded-spacing",
      unknownRule: "non-scale-spacing",
      knownSeverity: "error",
      tokenMap: PX_TO_TOKEN,
      fallback: "가장 가까운 --space-* 토큰으로 대체 또는 scale 에 추가",
    };
  }
  if (prop === "border-radius" || prop.endsWith("-radius")) {
    return {
      kind: "radius",
      label: "radius",
      knownRule: "hardcoded-radius",
      unknownRule: "non-scale-radius",
      knownSeverity: "error",
      tokenMap: RADIUS_TO_TOKEN,
      fallback: "가장 가까운 --radius-* 토큰으로 대체 또는 scale 에 추가",
    };
  }
  if (SIZE_PROPS.has(prop)) {
    return {
      kind: "size",
      label: "size",
      knownRule: "hardcoded-size",
      unknownRule: "non-token-size",
      knownSeverity: "warning",
      tokenMap: SIZE_TO_TOKEN,
      fallback: "DESIGN.md 컴포넌트 크기 토큰 확인 또는 프로젝트 --size-* 토큰 정의",
    };
  }
  return null;
}

function lengthRuleForUtility(utility) {
  const base = utility.split(":").pop().toLowerCase();
  if (/^(p[trblxy]?|m[trblxy]?|gap(?:-[xy])?|space-[xy]|inset(?:-[xy])?|top|right|bottom|left)$/.test(base)) {
    return lengthRuleForProperty("padding");
  }
  if (/^rounded(?:-[trbl]{1,2})?$/.test(base)) {
    return lengthRuleForProperty("border-radius");
  }
  if (/^(w|h|min-w|max-w|min-h|max-h)$/.test(base)) {
    return lengthRuleForProperty("width");
  }
  return null;
}

function pushLengthFinding({ path, lineIndex, col, rule, subject, pxVal, raw }) {
  const num = pxVal.replace("px", "");
  if (num === "0") return;
  const suggest = rule.tokenMap.get(num);
  findings.push({
    file: path,
    line: lineIndex + 1,
    col,
    severity: suggest ? rule.knownSeverity : "warning",
    rule: suggest ? rule.knownRule : rule.unknownRule,
    message: `Hardcoded ${rule.label} ${pxVal} in ${subject}`,
    suggest: suggest || rule.fallback,
    raw: raw.trim(),
  });
}

// ────────────────────────────────────────────────────────────────────
//  Scanning
// ────────────────────────────────────────────────────────────────────

/** @type {Array<{file:string, line:number, col:number, severity:'error'|'warning'|'info', rule:string, message:string, suggest:string, raw:string}>} */
const findings = [];

function walk(dir, out = []) {
  let entries;
  try { entries = readdirSync(dir); } catch { return out; }
  for (const name of entries) {
    if (IGNORE_DIRS.has(name)) continue;
    const p = join(dir, name);
    let s;
    try { s = statSync(p); } catch { continue; }
    if (s.isDirectory()) {
      walk(p, out);
    } else if (SCAN_EXTS.has(extname(name).toLowerCase())) {
      out.push(p);
    }
  }
  return out;
}

function scanFile(path) {
  let src;
  try { src = readFileSync(path, "utf8"); } catch { return; }
  const lines = src.split("\n");

  lines.forEach((line, i) => {
    // 토큰 소스/프리셋 파일은 스스로 hex를 포함하므로 스킵 대상
    const base = path.split("/").pop() || "";
    if (
      base === "tokens.css" ||
      base === "DESIGN.md" ||
      base.startsWith("tailwind.preset")   // tailwind.preset.js, tailwind.preset.hw.js 등
    ) return;

    // var(--...) 참조는 스킵 — 이미 토큰을 쓰고 있음
    const stripped = line.replace(/var\(--[a-z0-9-]+\)/gi, "");

    // ── 1. Hex 색상 감지 (3 or 6 hex) ────────────────────────────
    const hexRe = /#([0-9a-fA-F]{3}|[0-9a-fA-F]{6})\b/g;
    let m;
    while ((m = hexRe.exec(stripped)) !== null) {
      const hex = m[0].toLowerCase();
      const suggest = HEX_TO_TOKEN.get(hex);
      findings.push({
        file: path,
        line: i + 1,
        col: m.index + 1,
        severity: suggest ? "error" : "warning",
        rule: suggest ? "hardcoded-brand-hex" : "hardcoded-hex",
        message: `Hardcoded color ${hex}`,
        suggest: suggest || "토큰으로 추출 또는 DESIGN.md 의 colors 섹션에 정의 후 사용",
        raw: line.trim(),
      });
    }

    // ── 2. Duration 감지 (ms/s) ─────────────────────────────────
    const durRe = /\b(\d+(?:\.\d+)?)(ms|s)\b/g;
    while ((m = durRe.exec(stripped)) !== null) {
      const full = m[0];
      if (HW_DURATIONS.has(full.toLowerCase())) continue;          // 허용값 스킵
      // 0s·0ms 는 초기 상태로 자주 쓰임 → 스킵
      if (/^0(\.0+)?(ms|s)$/i.test(full)) continue;
      findings.push({
        file: path,
        line: i + 1,
        col: m.index + 1,
        severity: "warning",
        rule: "non-standard-duration",
        message: `Non-standard duration ${full}`,
        suggest: DURATION_TO_TOKEN.get(full.toLowerCase()) || "var(--motion-fast|base|slow) 중 하나로",
        raw: line.trim(),
      });
    }

    // ── 3. CSS/JS declaration px 감지 ─────────────────────────
    const declarationRe = /([a-zA-Z-]+)\s*:\s*([^;]+);?/g;
    while ((m = declarationRe.exec(stripped)) !== null) {
      const prop = normalizeProp(m[1]);
      const rule = lengthRuleForProperty(prop);
      if (!rule) continue;
      const value = m[2];
      const pxMatches = value.match(/\b(\d+)px\b/g);
      if (!pxMatches) continue;
      for (const pxVal of pxMatches) {
        pushLengthFinding({
          path,
          lineIndex: i,
          col: m.index + 1,
          rule,
          subject: prop,
          pxVal,
          raw: line,
        });
      }
    }

    // ── 4. Tailwind arbitrary px 유틸리티 감지 ────────────────
    const arbitraryRe = /\b((?:[a-z0-9-]+:)*(?:p[trblxy]?|m[trblxy]?|gap(?:-[xy])?|space-[xy]|inset(?:-[xy])?|top|right|bottom|left|w|h|min-w|max-w|min-h|max-h|rounded(?:-[trbl]{1,2})?))-\[(\d+)px\]/gi;
    while ((m = arbitraryRe.exec(stripped)) !== null) {
      const utility = m[1];
      const rule = lengthRuleForUtility(utility);
      if (!rule) continue;
      pushLengthFinding({
        path,
        lineIndex: i,
        col: m.index + 1,
        rule,
        subject: `Tailwind ${utility}-[]`,
        pxVal: `${m[2]}px`,
        raw: line,
      });
    }
  });
}

// ────────────────────────────────────────────────────────────────────
//  Report
// ────────────────────────────────────────────────────────────────────

const ICON = { error: "✗", warning: "!", info: "·" };
const COLOR = { error: "\x1b[31m", warning: "\x1b[33m", info: "\x1b[34m", reset: "\x1b[0m", dim: "\x1b[2m" };

function printText(root) {
  if (findings.length === 0) {
    console.log("\n✓ Token Audit — no issues found.\n");
    return;
  }

  const byFile = new Map();
  for (const f of findings) {
    if (!byFile.has(f.file)) byFile.set(f.file, []);
    byFile.get(f.file).push(f);
  }

  console.log("\nToken Audit");
  console.log(`Scanning ${byFile.size} file(s) with findings...\n`);

  for (const [file, items] of byFile) {
    console.log(`${relative(root, file)}`);
    for (const it of items) {
      const mark = `${COLOR[it.severity]}${ICON[it.severity]}${COLOR.reset}`;
      console.log(`  ${mark} L${it.line}: ${it.message}`);
      console.log(`    ${COLOR.dim}→ ${it.suggest}${COLOR.reset}`);
    }
    console.log();
  }

  const errs  = findings.filter(f => f.severity === "error").length;
  const warns = findings.filter(f => f.severity === "warning").length;
  console.log(`=== Summary ===`);
  console.log(`Errors:   ${errs}`);
  console.log(`Warnings: ${warns}`);
  console.log();
}

function printJson() {
  console.log(JSON.stringify({
    version: 1,
    findings,
    summary: {
      errors:   findings.filter(f => f.severity === "error").length,
      warnings: findings.filter(f => f.severity === "warning").length,
    },
  }, null, 2));
}

// ────────────────────────────────────────────────────────────────────
//  Main
// ────────────────────────────────────────────────────────────────────

const args = process.argv.slice(2);
const format = args.includes("--format") ? args[args.indexOf("--format") + 1] : "text";
const strict = args.includes("--strict");
const targetArg = args.find(a => !a.startsWith("--") && a !== format);
const root = targetArg ? targetArg : process.cwd();

const files = walk(root);
files.forEach(scanFile);

if (format === "json") {
  printJson();
} else {
  printText(process.cwd());
}

const hasError = findings.some(f => f.severity === "error");
const hasWarn  = findings.some(f => f.severity === "warning");
process.exit(hasError || (strict && hasWarn) ? 1 : 0);
