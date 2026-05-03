#!/usr/bin/env node
/* ═══════════════════════════════════════════════════════════════════
 *  HW Design — 단일 파일 HTML 빌더
 *  외부 디자인 프로토타입 공유용. 모든 외부 자산(CSS·로고·폰트)을
 *  base64 / <style> 로 인라인하여 HTML 한 개로 완결시킨다.
 *
 *  사용:
 *    node build-standalone.mjs                  # 기본: core 4 weight 인라인
 *    node build-standalone.mjs --fonts none     # 시스템 폴백 (~200KB)
 *    node build-standalone.mjs --fonts all      # 한화체 3w + 한화고딕 5w
 *    node build-standalone.mjs index.html out.html
 *
 *  의존성: Node.js 18+ (그 외 zero dep). token-audit.mjs 와 같은 패턴.
 * ═══════════════════════════════════════════════════════════════════ */

import { readFileSync, writeFileSync, existsSync, statSync } from "node:fs";
import { resolve, dirname, join, basename } from "node:path";

/* ──────────────────────────────────────────────────
 *  CLI 파싱
 * ──────────────────────────────────────────────── */
const args = process.argv.slice(2);
let inputPath = null;
let outputPath = null;
let fontsMode = "core";

for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a === "-h" || a === "--help") {
    console.log(`HW Design — standalone HTML builder

Usage:
  node build-standalone.mjs [input] [output] [options]

Options:
  --fonts core     한화체 R/B + 한화고딕 R/B 만 인라인 (~1.5MB, 사이즈 절약)
  --fonts all      fonts.css 통째 mirror — 한화체 3w + 한화고딕 5w
                   + AtoZ 9w + IBM Plex 2개 모두 인라인 (~4MB,
                   index.html 과 시각적으로 100% 동일)
  --fonts none     폰트 제외, 시스템 폴백 (~200KB)
  -h, --help       이 도움말

Defaults:
  input  = ./index.html
  output = ./standalone.html`);
    process.exit(0);
  }
  if (a === "--fonts") {
    fontsMode = args[++i];
    if (!["core", "all", "none"].includes(fontsMode)) {
      console.error(`✗ --fonts 값 오류: '${fontsMode}'. core | all | none 중 선택.`);
      process.exit(1);
    }
  } else if (a.startsWith("--")) {
    console.error(`✗ 알 수 없는 플래그: ${a}`);
    process.exit(1);
  } else if (!inputPath) inputPath = a;
  else if (!outputPath) outputPath = a;
}

inputPath = resolve(inputPath || "index.html");
outputPath = resolve(outputPath || join(dirname(inputPath), "standalone.html"));
const baseDir = dirname(inputPath);

if (!existsSync(inputPath)) {
  console.error(`✗ 입력 파일 없음: ${inputPath}`);
  process.exit(1);
}

/* ──────────────────────────────────────────────────
 *  폰트 매트릭스 — fonts/ 폴더 기준 상대경로
 * ──────────────────────────────────────────────── */
const FONT_MATRIX = {
  core: [
    { family: "Hanwha",       weight: 400, file: "fonts/Hanwha/HanwhaR.woff2" },
    { family: "Hanwha",       weight: 700, file: "fonts/Hanwha/HanwhaB.woff2" },
    { family: "HanwhaGothic", weight: 400, file: "fonts/HanwhaGothic/HanwhaGothicR.woff2" },
    { family: "HanwhaGothic", weight: 700, file: "fonts/HanwhaGothic/HanwhaGothicB.woff2" },
  ],
  all: [
    { family: "Hanwha",       weight: 300, file: "fonts/Hanwha/HanwhaL.woff2" },
    { family: "Hanwha",       weight: 400, file: "fonts/Hanwha/HanwhaR.woff2" },
    { family: "Hanwha",       weight: 700, file: "fonts/Hanwha/HanwhaB.woff2" },
    { family: "HanwhaGothic", weight: 100, file: "fonts/HanwhaGothic/HanwhaGothicT.woff2" },
    { family: "HanwhaGothic", weight: 200, file: "fonts/HanwhaGothic/HanwhaGothicEL.woff2" },
    { family: "HanwhaGothic", weight: 300, file: "fonts/HanwhaGothic/HanwhaGothicL.woff2" },
    { family: "HanwhaGothic", weight: 400, file: "fonts/HanwhaGothic/HanwhaGothicR.woff2" },
    { family: "HanwhaGothic", weight: 700, file: "fonts/HanwhaGothic/HanwhaGothicB.woff2" },
  ],
  none: [],
};

/* ──────────────────────────────────────────────────
 *  유틸
 * ──────────────────────────────────────────────── */
const b64 = (path, mime) =>
  `data:${mime};base64,` + readFileSync(path).toString("base64");

const fmtKB = (n) => `${(n / 1024).toFixed(0)} KB`;
const fmtMB = (n) => `${(n / 1024 / 1024).toFixed(2)} MB`;

const escapeRegex = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

/**
 * fonts.css 본문을 그대로 보존하면서 안쪽 url() 의 woff2/woff/ttf/otf 를
 * 모두 base64 data URL 로 치환한다.
 *
 * 매트릭스 기반 인라인(core 모드)은 사이즈 절약이 목적이라 폴백 폰트가 빠지지만,
 * mirror 모드는 fonts.css 정의를 그대로 옮기므로 외부 로드와 동일하게 렌더된다.
 */
function inlineFontsCssMirror(fontsCssPath) {
  const cssDir = dirname(fontsCssPath);
  let css = readFileSync(fontsCssPath, "utf8");
  let bytes = 0, count = 0;
  const missing = [];

  css = css.replace(
    /url\(\s*["']?([^"')]+\.(?:woff2|woff|ttf|otf))["']?\s*\)/gi,
    (full, relPath) => {
      if (relPath.startsWith("data:") || relPath.startsWith("http")) return full;
      const fontPath = resolve(cssDir, relPath);
      if (!existsSync(fontPath)) {
        missing.push(relPath);
        return full;
      }
      const ext = relPath.split(".").pop().toLowerCase();
      const mime = ext === "woff2" ? "font/woff2"
                 : ext === "woff"  ? "font/woff"
                 : ext === "otf"   ? "font/otf"
                 : "font/ttf";
      const dataUrl = b64(fontPath, mime);
      bytes += dataUrl.length;
      count++;
      return `url("${dataUrl}")`;
    }
  );

  return { css, bytes, count, missing };
}

/* ──────────────────────────────────────────────────
 *  변환
 * ──────────────────────────────────────────────── */
let html = readFileSync(inputPath, "utf8");
const inputName = basename(inputPath);
console.log(`▸ 입력: ${inputName} (${fmtKB(statSync(inputPath).size)})`);

// 1) tokens.css 인라인 — <link rel="stylesheet" href="...tokens.css"> 매칭
const tokensLinkRe = /<link\s+rel="stylesheet"\s+href="([^"]*tokens\.css)"\s*\/?>/i;
const tokensMatch = html.match(tokensLinkRe);
let tokensInlined = false;
if (tokensMatch) {
  const tokensPath = resolve(baseDir, tokensMatch[1]);
  if (existsSync(tokensPath)) {
    const tokensCss = readFileSync(tokensPath, "utf8");
    html = html.replace(tokensLinkRe, `<style data-source="tokens.css">\n${tokensCss}\n  </style>`);
    tokensInlined = true;
    console.log(`▸ tokens.css 인라인 (${fmtKB(tokensCss.length)})`);
  } else {
    console.warn(`⚠ tokens.css 경로 못 찾음: ${tokensPath} — link 보존`);
  }
}

// 2) fonts.css 처리 — 모드별
const fontsLinkRe = /<link\s+rel="stylesheet"\s+href="([^"]*fonts\.css)"\s*\/?>\s*\n?\s*/i;
const fontsLinkMatch = html.match(fontsLinkRe);
let fontFaceBlock = "";
let fontsBytes = 0;

if (fontsMode === "none") {
  if (fontsLinkMatch) {
    html = html.replace(fontsLinkRe, "");
    console.log(`▸ fonts: 시스템 폴백 (link 제거)`);
  }
} else if (fontsMode === "all") {
  // fonts.css 통째 mirror — 한화체 + 한화고딕 + AtoZ + IBM Plex 모두 인라인.
  // 외부 로드와 동일 렌더 보장이 목적이라 사이즈는 큼.
  if (!fontsLinkMatch) {
    console.warn(`⚠ fonts.css link 없음 — mirror 위치 못 찾음`);
  } else {
    const fontsCssPath = resolve(baseDir, fontsLinkMatch[1]);
    if (!existsSync(fontsCssPath)) {
      console.warn(`⚠ fonts.css 경로 못 찾음: ${fontsCssPath} — link 보존`);
    } else {
      const result = inlineFontsCssMirror(fontsCssPath);
      fontsBytes = result.bytes;
      html = html.replace(
        fontsLinkRe,
        `<style data-source="fonts.css (mirror)">\n${result.css}\n  </style>\n  `
      );
      console.log(`▸ fonts: all 모드 (mirror) — ${result.count}개 인라인 (${fmtMB(fontsBytes)})`);
      if (result.missing.length > 0) {
        console.warn(`⚠ fonts.css 안에서 못 찾은 파일 ${result.missing.length}개:`);
        result.missing.forEach((p) => console.warn(`    - ${p}`));
      }
    }
  }
} else {
  // core 모드 — 명시 매트릭스 기반 인라인 (사이즈 절약, 폴백 폰트 제외)
  const fontsList = FONT_MATRIX[fontsMode];
  for (const { family, weight, file } of fontsList) {
    const fontPath = resolve(baseDir, file);
    if (!existsSync(fontPath)) {
      console.warn(`⚠ 폰트 파일 없음: ${file} — 건너뜀`);
      continue;
    }
    const dataUrl = b64(fontPath, "font/woff2");
    fontsBytes += dataUrl.length;
    fontFaceBlock += `\n@font-face {\n  font-family: "${family}";\n  font-style: normal;\n  font-weight: ${weight};\n  font-display: swap;\n  src: url("${dataUrl}") format("woff2");\n}`;
  }
  if (fontsLinkMatch) {
    html = html.replace(
      fontsLinkRe,
      `<style data-source="fonts.css">${fontFaceBlock}\n  </style>\n  `
    );
    console.log(`▸ fonts: ${fontsMode} 모드 — ${fontsList.length}개 인라인 (${fmtMB(fontsBytes)})`);
  } else {
    console.warn(`⚠ fonts.css link 없음 — @font-face 블록 추가 위치 못 찾음`);
  }
}

// 3) 로고/이미지 PNG 모두 base64 — src="..." 와 href="..." 둘 다
const pngRe = /(src|href)="(\.\/[^"]+\.png|[^"]+\.png)"/g;
const pngMatches = new Set();
let m;
while ((m = pngRe.exec(html)) !== null) {
  if (!m[2].startsWith("data:") && !m[2].startsWith("http")) {
    pngMatches.add(m[2]);
  }
}
let imageBytes = 0;
for (const path of pngMatches) {
  const fullPath = resolve(baseDir, path);
  if (!existsSync(fullPath)) {
    console.warn(`⚠ 이미지 없음: ${path} — 건너뜀`);
    continue;
  }
  const dataUrl = b64(fullPath, "image/png");
  imageBytes += dataUrl.length;
  const escaped = escapeRegex(path);
  html = html.replace(new RegExp(`(src|href)="${escaped}"`, "g"), `$1="${dataUrl}"`);
}
console.log(`▸ 이미지 base64: ${pngMatches.size}개 (${fmtKB(imageBytes)})`);

// 4) 외부 참조 검증 — data:/http(s)/anchor 외 남으면 경고
const externalRe = /(?:href|src)="(?!data:|#|https?:\/\/|mailto:)([^"]+)"/g;
const remaining = [];
while ((m = externalRe.exec(html)) !== null) remaining.push(m[1]);
if (remaining.length > 0) {
  console.warn(`⚠ 외부 참조 남음 (${remaining.length}개):`);
  remaining.forEach((p) => console.warn(`    - ${p}`));
} else {
  console.log(`▸ 외부 참조 검증: 없음 ✓`);
}

/* ──────────────────────────────────────────────────
 *  출력
 * ──────────────────────────────────────────────── */
writeFileSync(outputPath, html);
const finalSize = statSync(outputPath).size;
console.log(`\n✓ 생성: ${basename(outputPath)} — ${fmtMB(finalSize)} (${finalSize.toLocaleString()} bytes)`);

if (remaining.length > 0) process.exit(1);
