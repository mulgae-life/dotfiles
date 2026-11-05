#!/usr/bin/env node
// URL 또는 HTML 파일을 여러 뷰포트 폭으로 렌더링해 PNG와 진단 리포트를 남긴다.
// 사용: node shoot.mjs <url|파일> [--out DIR] [--widths 1440,768,390] [--no-full]
//       [--selector CSS] [--wait MS] [--dark] [--name PREFIX]

import { createRequire } from "node:module";
import { execSync } from "node:child_process";
import { mkdirSync, writeFileSync, existsSync } from "node:fs";
import { resolve, join } from "node:path";
import { pathToFileURL } from "node:url";

const PRESETS = { 1440: "desktop", 1024: "laptop", 768: "tablet", 390: "mobile" };

function loadPlaywright() {
  const localRequire = createRequire(import.meta.url);
  try {
    return localRequire("playwright");
  } catch {
    const globalRoot = execSync("npm root -g", { encoding: "utf8" }).trim();
    const globalRequire = createRequire(join(globalRoot, "package.json"));
    try {
      return globalRequire("playwright");
    } catch {
      console.error("playwright를 찾지 못했습니다. scripts/setup.sh를 먼저 실행하세요.");
      process.exit(2);
    }
  }
}

function parseArgs(argv) {
  const opts = { out: ".visual-check", widths: [1440, 768, 390], full: true, wait: 0, dark: false, selector: null, name: "" };
  const rest = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--out") opts.out = argv[++i];
    else if (a === "--widths") opts.widths = argv[++i].split(",").map((w) => Number(w.trim())).filter(Boolean);
    else if (a === "--no-full") opts.full = false;
    else if (a === "--selector") opts.selector = argv[++i];
    else if (a === "--wait") opts.wait = Number(argv[++i]);
    else if (a === "--dark") opts.dark = true;
    else if (a === "--name") opts.name = argv[++i];
    else rest.push(a);
  }
  if (rest.length !== 1) {
    console.error("사용법: node shoot.mjs <url|html파일> [--out DIR] [--widths 1440,768,390] [--no-full] [--selector CSS] [--wait MS] [--dark] [--name PREFIX]");
    process.exit(1);
  }
  opts.target = rest[0];
  return opts;
}

function toUrl(target) {
  if (/^https?:\/\//.test(target)) return target;
  const abs = resolve(target);
  if (!existsSync(abs)) {
    console.error(`파일이 없습니다: ${abs}`);
    process.exit(1);
  }
  return pathToFileURL(abs).href;
}

// 페이지 안에서 실행: 가로 넘침·폰트 상태·이미지 깨짐을 수집한다.
function collectDiagnostics() {
  const vw = window.innerWidth;
  const docWidth = document.documentElement.scrollWidth;
  const overflowing = [];
  for (const el of document.querySelectorAll("body *")) {
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    if (r.right > vw + 1 || r.left < -1) {
      const id = el.id ? `#${el.id}` : "";
      const cls = el.classList.length ? "." + [...el.classList].slice(0, 2).join(".") : "";
      overflowing.push(`${el.tagName.toLowerCase()}${id}${cls} (left ${Math.round(r.left)}, right ${Math.round(r.right)})`);
      if (overflowing.length >= 10) break;
    }
  }
  const fonts = [];
  for (const f of document.fonts) fonts.push({ family: f.family, weight: f.weight, status: f.status });
  const brokenImages = [];
  for (const img of document.images) {
    if (img.complete && img.naturalWidth === 0 && img.getAttribute("src")) brokenImages.push(img.getAttribute("src"));
  }
  const sample = (sel) => {
    const el = document.querySelector(sel);
    return el ? getComputedStyle(el).fontFamily : null;
  };
  return {
    viewportWidth: vw,
    documentWidth: docWidth,
    horizontalScroll: docWidth > vw + 1,
    overflowingElements: overflowing,
    fonts,
    computedFontFamily: { body: sample("body"), h1: sample("h1"), button: sample("button") },
    brokenImages,
    title: document.title,
  };
}

async function main() {
  const opts = parseArgs(process.argv.slice(2));
  const { chromium } = loadPlaywright();
  const url = toUrl(opts.target);
  mkdirSync(opts.out, { recursive: true });

  const browser = await chromium.launch();
  const report = { target: url, capturedAt: new Date().toISOString(), shots: [] };
  try {
    for (const width of opts.widths) {
      const label = PRESETS[width] ?? `w${width}`;
      const prefix = opts.name ? `${opts.name}-` : "";
      const file = join(opts.out, `${prefix}${label}.png`);
      // isMobile 에뮬레이션은 넘치는 콘텐츠에 맞춰 레이아웃 뷰포트를 넓혀 가로 넘침을 숨기므로 쓰지 않는다.
      const context = await browser.newContext({
        viewport: { width, height: 900 },
        deviceScaleFactor: 1,
        colorScheme: opts.dark ? "dark" : "light",
      });
      const page = await context.newPage();
      const consoleErrors = [];
      const pageErrors = [];
      const failedRequests = [];
      page.on("console", (m) => { if (m.type() === "error") consoleErrors.push(m.text()); });
      page.on("pageerror", (e) => pageErrors.push(String(e)));
      page.on("requestfailed", (r) => failedRequests.push(`${r.url()} (${r.failure()?.errorText ?? "failed"})`));
      page.on("response", (r) => { if (r.status() >= 400) failedRequests.push(`${r.url()} (HTTP ${r.status()})`); });

      const response = await page.goto(url, { waitUntil: "networkidle", timeout: 30000 });
      if (opts.wait > 0) await page.waitForTimeout(opts.wait);
      await page.evaluate(() => document.fonts.ready);

      if (opts.selector) {
        const el = page.locator(opts.selector).first();
        await el.screenshot({ path: file });
      } else {
        await page.screenshot({ path: file, fullPage: opts.full });
      }
      const diag = await page.evaluate(collectDiagnostics);
      report.shots.push({
        width,
        label,
        file,
        httpStatus: response?.status() ?? null,
        ...diag,
        consoleErrors,
        pageErrors,
        failedRequests,
      });
      await context.close();
    }
  } finally {
    await browser.close();
  }

  const reportPath = join(opts.out, `${opts.name ? opts.name + "-" : ""}report.json`);
  writeFileSync(reportPath, JSON.stringify(report, null, 2));

  // 사람이 바로 읽을 요약
  console.log(`대상: ${url}`);
  for (const s of report.shots) {
    const flags = [];
    if (s.horizontalScroll) flags.push(`가로 스크롤 발생(문서 ${s.documentWidth}px > 뷰포트 ${s.viewportWidth}px)`);
    if (s.overflowingElements.length) flags.push(`뷰포트 밖으로 나간 요소 ${s.overflowingElements.length}개`);
    if (s.brokenImages.length) flags.push(`깨진 이미지 ${s.brokenImages.length}개`);
    if (s.consoleErrors.length) flags.push(`콘솔 에러 ${s.consoleErrors.length}건`);
    if (s.pageErrors.length) flags.push(`페이지 에러 ${s.pageErrors.length}건`);
    if (s.failedRequests.length) flags.push(`실패 요청 ${s.failedRequests.length}건`);
    const unloaded = s.fonts.filter((f) => f.status !== "loaded");
    if (unloaded.length) flags.push(`미로드 폰트 ${unloaded.length}개`);
    console.log(`  [${s.label} ${s.width}px] ${s.file}${flags.length ? "  ⚠ " + flags.join(", ") : "  ✓ 진단 이상 없음"}`);
  }
  console.log(`리포트: ${reportPath}`);
}

main().catch((e) => {
  console.error(`실패: ${e.message}`);
  process.exit(1);
});
