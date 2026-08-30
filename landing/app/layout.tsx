import type { Metadata } from "next";
import { JetBrains_Mono } from "next/font/google";
import "@/styles/globals.scss";
import { ThemeToggle } from "@/components/theme/ThemeToggle";
import { THEME_INIT_SCRIPT, DEFAULT_THEME } from "@/components/theme/theme-script";
import { Footer } from "@/components/layout/Footer";
import styles from "./layout.module.scss";

// JetBrains Mono is the site's sole typeface — mirrors the Flutter app's
// `spaceMono()`/`dmSans()` helpers in lib/core/theme/app_theme.dart, which
// both actually render JetBrains Mono despite the latter's name.
const jetBrainsMono = JetBrains_Mono({
  subsets: ["latin"],
  weight: ["400", "500", "700"],
  variable: "--font-jetbrains-mono",
  display: "swap",
});

// Title/description mirror the root README's identity + tagline ("trackr_"
// / "Intentional time tracking with session notes and music context.").
// `openGraph`/`twitter` are set explicitly (not left to fall back from the
// top-level title/description) because Next's metadata resolver only
// auto-fills `og:title`/`og:description` when an `openGraph` object is
// present at all — confirmed against
// `node_modules/next/dist/lib/metadata/resolvers/resolve-opengraph.js`,
// where `resolveOpenGraph` returns `null` outright when `metadata.openGraph`
// is undefined. The `opengraph-image.png`/`twitter-image.png` file
// conventions (app/opengraph-image.png, app/twitter-image.png) supply the
// image side automatically and get merged on top of this by
// `mergeStaticMetadata` — no `images` field needed here.
const SITE_TITLE = "trackr_";
const SITE_DESCRIPTION = "Intentional time tracking with session notes and music context.";

export const metadata: Metadata = {
  title: SITE_TITLE,
  description: SITE_DESCRIPTION,
  openGraph: {
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
    siteName: SITE_TITLE,
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: SITE_TITLE,
    description: SITE_DESCRIPTION,
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html
      lang="en"
      data-theme={DEFAULT_THEME}
      suppressHydrationWarning
      className={jetBrainsMono.variable}
    >
      <head>
        {/*
          Runs synchronously during HTML parsing, before React hydrates or
          the first paint — resolves localStorage -> OS prefers-color-scheme
          -> "dark" fallback and sets data-theme on <html> immediately, so
          there's no flash of the wrong theme. suppressHydrationWarning above
          tells React to accept whatever this script leaves in the DOM.
          See: https://nextjs.org/docs/app/guides/preventing-flash-before-hydration
        */}
        <script dangerouslySetInnerHTML={{ __html: THEME_INIT_SCRIPT }} />
      </head>
      <body>
        <header className={styles.siteHeader}>
          <span className={styles.brand}>trackr_</span>
          <ThemeToggle />
        </header>
        {children}
        <Footer />
      </body>
    </html>
  );
}
