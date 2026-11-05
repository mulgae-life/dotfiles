/** ═══════════════════════════════════════════════════════════════════
 *  HW Design — Tailwind Preset
 *
 *  사용법:
 *    // tailwind.config.js
 *    module.exports = {
 *      presets: [require("./tailwind.preset.hw.js")],
 *      content: [...],
 *    };
 *
 *  tokens.css 의 CSS 변수를 Tailwind 유틸리티에 연결한다.
 *  Layer 1/2 가 tokens.css 에 있고, 이 프리셋은 그 alias 를 바라본다.
 *  → 리브랜딩은 tokens.css 만 수정 → Tailwind 클래스가 자동 재배색.
 * ═══════════════════════════════════════════════════════════════════ */

const withVar = (name) => `var(--${name})`;

/** @type {import('tailwindcss').Config} */
module.exports = {
  theme: {
    extend: {
      colors: {
        // Brand — role-based aliases
        primary:            withVar("color-primary"),
        "primary-hover":    withVar("color-primary-hover"),
        "primary-pressed":  withVar("color-primary-pressed"),
        "primary-bg":       withVar("color-primary-bg"),
        "primary-bg-subtle":withVar("color-primary-bg-subtle"),

        neutral:            withVar("color-neutral"),
        "neutral-light":    withVar("color-neutral-light"),
        "neutral-muted":    withVar("color-neutral-muted"),

        // Text
        text:               withVar("color-text"),
        "text-secondary":   withVar("color-text-secondary"),
        "text-tertiary":    withVar("color-text-tertiary"),
        "text-on-primary":  withVar("color-text-on-primary"),
        "text-on-neutral":  withVar("color-text-on-neutral"),

        // Surface / Border
        surface:            withVar("color-surface"),
        "surface-secondary":withVar("color-surface-secondary"),
        "surface-tertiary": withVar("color-surface-tertiary"),
        border:             withVar("color-border"),
        "border-light":     withVar("color-border-light"),

        // State
        success:            withVar("color-success"),
        "success-bg":       withVar("color-success-bg"),
        warning:            withVar("color-warning"),
        "warning-bg":       withVar("color-warning-bg"),
        danger:             withVar("color-danger"),
        "danger-bg":        withVar("color-danger-bg"),
        info:               withVar("color-info"),
        "info-bg":          withVar("color-info-bg"),
      },

      fontFamily: {
        sans:    [withVar("font-sans")],     // 본문·기본 (한화고딕 우선)
        display: [withVar("font-display")],  // Display·로고·Hero (한화체)
        numeric: [withVar("font-numeric")],  // 숫자 강조 (IBM Plex)
      },

      fontSize: {
        // 15px 본문 기본 (한글 가독성 우선)
        "body-sm": ["0.8125rem", { lineHeight: "1.5" }],
        body:      ["0.9375rem", { lineHeight: "1.6" }],
        "body-lg": ["1.0625rem", { lineHeight: "1.6" }],
      },

      spacing: {
        "hw-xxs":  withVar("space-50"),
        "hw-xs":   withVar("space-100"),
        "hw-sm":   withVar("space-150"),
        "hw-md":   withVar("space-200"),
        "hw-lg":   withVar("space-300"),
        "hw-xl":   withVar("space-400"),
        "hw-xxl":  withVar("space-600"),
        "hw-xxxl": withVar("space-800"),
        "hw-hero": withVar("space-hero"),
      },

      borderRadius: {
        DEFAULT: withVar("radius-md"),
        sm:      withVar("radius-sm"),
        md:      withVar("radius-md"),
        lg:      withVar("radius-lg"),
        xl:      withVar("radius-xl"),
        "2xl":   withVar("radius-2xl"),
        "3xl":   withVar("radius-3xl"),
        full:    withVar("radius-full"),
      },

      boxShadow: {
        card:          withVar("shadow-card"),
        "card-hover":  withVar("shadow-card-hover"),
        modal:         withVar("shadow-modal"),
        glass:         withVar("shadow-glass"),
        elevated:      withVar("shadow-elevated"),
        bubble:        withVar("shadow-bubble"),
        "bubble-accent": withVar("shadow-bubble-accent"),
        toast:         withVar("shadow-toast"),
        glow:          withVar("shadow-glow"),
      },

      backgroundImage: {
        "gradient-navy":        withVar("gradient-navy"),
        "gradient-navy-3stop":  withVar("gradient-navy-3stop"),
        "gradient-primary":     withVar("gradient-primary"),
        "gradient-primary-h":   withVar("gradient-primary-h"),
        "gradient-page":        withVar("gradient-page"),
        "gradient-page-light":  withVar("gradient-page-light"),
      },

      transitionDuration: {
        fast: "250ms",
        base: "350ms",
        slow: "550ms",
      },

      transitionTimingFunction: {
        "hw-ease":   "cubic-bezier(0.4, 0, 0.2, 1)",
        "hw-spring": "cubic-bezier(0.175, 0.885, 0.32, 1.275)",
      },

      zIndex: {
        sticky: "30",
        toast:  "40",
        modal:  "50",
      },

      keyframes: {
        "hw-fade-in-up": {
          "0%":   { opacity: "0", transform: "translateY(12px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "hw-slide-in-left": {
          "0%":   { opacity: "0", transform: "translateX(-16px)" },
          "100%": { opacity: "1", transform: "translateX(0)" },
        },
        "hw-pulse-ring": {
          "0%":   { boxShadow: "0 0 0 0 rgba(220, 38, 38, 0.4)" },
          "70%":  { boxShadow: "0 0 0 6px rgba(220, 38, 38, 0)" },
          "100%": { boxShadow: "0 0 0 0 rgba(220, 38, 38, 0)" },
        },
        "hw-shimmer": {
          "0%":   { backgroundPosition: "-200% 0" },
          "100%": { backgroundPosition: "200% 0" },
        },
      },
      animation: {
        "hw-fade-in-up":    "hw-fade-in-up 350ms cubic-bezier(0.4,0,0.2,1)",
        "hw-slide-in-left": "hw-slide-in-left 350ms cubic-bezier(0.4,0,0.2,1)",
        "hw-pulse-ring":    "hw-pulse-ring 1.5s infinite",
        "hw-shimmer":       "hw-shimmer 1.5s infinite",
      },
    },
  },
};
