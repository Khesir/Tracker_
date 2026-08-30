"use client";

import { useCallback, useLayoutEffect, useSyncExternalStore } from "react";
import { InteractiveLabel } from "../primitives/InteractiveLabel";
import {
  applyTheme,
  DEFAULT_THEME,
  persistTheme,
  resolveInitialTheme,
  type Theme,
} from "./theme-script";
import styles from "./ThemeToggle.module.scss";

// A tiny module-level store, read via useSyncExternalStore — the React-
// recommended way to read a value that can legitimately differ between the
// server-rendered HTML and the client (here: localStorage / OS
// prefers-color-scheme, neither available during SSR). React reconciles the
// getServerSnapshot() value used for the SSR/hydration pass against
// getSnapshot()'s real client value itself, so no manual effect is needed
// just to correct React's own rendered *text* after mount.
let currentTheme: Theme | null = null;
const listeners = new Set<() => void>();

function getSnapshot(): Theme {
  if (currentTheme === null) {
    currentTheme = resolveInitialTheme();
  }
  return currentTheme;
}

// The <html data-theme="dark"> default in app/layout.tsx + the theme
// script's own fallback both agree on DEFAULT_THEME, so this is what the
// server (and the pre-hydration DOM) already show.
function getServerSnapshot(): Theme {
  return DEFAULT_THEME;
}

function subscribe(onStoreChange: () => void): () => void {
  listeners.add(onStoreChange);
  return () => listeners.delete(onStoreChange);
}

function setTheme(next: Theme): void {
  currentTheme = next;
  persistTheme(next);
  for (const listener of listeners) listener();
}

export function ThemeToggle() {
  const theme = useSyncExternalStore(subscribe, getSnapshot, getServerSnapshot);

  // Applying the `data-theme` attribute is a DOM side effect keyed off
  // React's resolved theme value, not a state update, so this doesn't fall
  // afoul of the "no setState in effects" rule. It runs before paint
  // (useLayoutEffect) so a click applies live with no visible delay, and it
  // also re-applies the attribute after React's hydration-mismatch
  // resolution and after React Strict Mode's dev-only remount — both cases
  // where the DOM can otherwise fall out of sync with `theme`.
  useLayoutEffect(() => {
    applyTheme(theme);
  }, [theme]);

  const toggle = useCallback(() => {
    setTheme(theme === "dark" ? "light" : "dark");
  }, [theme]);

  return (
    <button type="button" onClick={toggle} className={styles.toggle}>
      <InteractiveLabel as="span" raw>
        {`${theme}_mode_`}
      </InteractiveLabel>
    </button>
  );
}
