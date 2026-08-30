import { InteractiveLabel } from "@/components/primitives/InteractiveLabel";
import { getLatestReleases } from "@/lib/releases";
import styles from "./HeroSection.module.scss";

/**
 * Hero section (issue 025) — the first thing a visitor sees: app identity,
 * tagline, and a single, visually obvious primary CTA. The CTA links
 * directly to the latest release's Windows `.exe` asset (never to
 * github.com or a Releases page), sourced from the releases data layer
 * (issue 024's `getLatestReleases`). The fuller platform matrix and
 * changelog live in the separate Download & changelog section (issue 026),
 * not here — per the issue's own notes, this stays simple.
 *
 * This is the codebase's first async Server Component consumer of the
 * releases data layer — fetched here server-side (revalidated hourly, per
 * `getLatestReleases`'s own `fetch` cache config) so the download href is
 * ready on first paint with no client-side loading state.
 *
 * Deliberately has no `// section_label` header, unlike Features/Screenshots:
 * it's the top-of-page identity block, not a labeled content section.
 */
export async function HeroSection() {
  let downloadUrl: string | undefined;

  try {
    const releases = await getLatestReleases();
    downloadUrl = releases[0]?.windowsAsset?.url;
  } catch {
    // GitHub API/network failure — degrade to the "unavailable" state below
    // instead of crashing the whole page render.
    downloadUrl = undefined;
  }

  return (
    <section className={styles.hero}>
      <p className={styles.logo}>trackr_</p>
      <p className={styles.tagline}>
        intentional time tracking with session notes and music context
      </p>
      {downloadUrl ? (
        <InteractiveLabel as="a" href={downloadUrl} className={styles.cta}>
          download for windows
        </InteractiveLabel>
      ) : (
        // Should not happen in practice — every release ships a .exe — but
        // never render a broken or absent CTA if it somehow does.
        <span className={styles.ctaUnavailable}>
          download temporarily unavailable — check back soon
        </span>
      )}
    </section>
  );
}
