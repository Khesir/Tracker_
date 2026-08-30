/**
 * Theme resolution shared between:
 *  - the inline `<script>` injected into `<head>` in app/layout.tsx, which
 *    must run as a plain string before hydration (no imports available), and
 *  - ThemeToggle.tsx, which re-derives the same value on mount (see its
 *    comment on why: React Strict Mode's dev-only remount clears attributes
 *    the inline script set outside of React).
 *
 * Resolution order: an explicit stored choice wins, else the OS
 * `prefers-color-scheme`, else "dark" if neither is available.
 */

export type Theme = "light" | "dark";

export const THEME_STORAGE_KEY = "trackr-landing-theme";
export const DEFAULT_THEME: Theme = "dark";

// Minified by hand (no build step processes this string) and kept
// dependency-free — it runs synchronously during HTML parsing, before
// React or any bundled JS is available.
export const THEME_INIT_SCRIPT = `(function(){try{var k="${THEME_STORAGE_KEY}";var s=localStorage.getItem(k);var t;if(s==="light"||s==="dark"){t=s}else if(window.matchMedia&&window.matchMedia("(prefers-color-scheme: light)").matches){t="light"}else if(window.matchMedia&&window.matchMedia("(prefers-color-scheme: dark)").matches){t="dark"}else{t="${DEFAULT_THEME}"}document.documentElement.setAttribute("data-theme",t)}catch(e){document.documentElement.setAttribute("data-theme","${DEFAULT_THEME}")}})();`;

export function readStoredTheme(): Theme | null {
  if (typeof window === "undefined") return null;
  try {
    const stored = window.localStorage.getItem(THEME_STORAGE_KEY);
    return stored === "light" || stored === "dark" ? stored : null;
  } catch {
    return null;
  }
}

export function resolveSystemTheme(): Theme {
  if (typeof window === "undefined" || !window.matchMedia) return DEFAULT_THEME;
  if (window.matchMedia("(prefers-color-scheme: light)").matches) return "light";
  if (window.matchMedia("(prefers-color-scheme: dark)").matches) return "dark";
  return DEFAULT_THEME;
}

export function resolveInitialTheme(): Theme {
  return readStoredTheme() ?? resolveSystemTheme();
}

export function persistTheme(theme: Theme): void {
  try {
    window.localStorage.setItem(THEME_STORAGE_KEY, theme);
  } catch {
    // localStorage unavailable (private browsing / disabled) — the toggle
    // still works live for the session, it just won't persist.
  }
}

export function applyTheme(theme: Theme): void {
  document.documentElement.setAttribute("data-theme", theme);
}
