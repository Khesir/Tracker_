import { getLatestReleases } from "@/lib/releases";
import { InteractiveLabel } from "@/components/primitives/InteractiveLabel";
import styles from "./Footer.module.scss";

const REPO_URL = "https://github.com/Khesir/Tracker_";
// No issue templates are configured on the repo (per the PRD), so this
// points straight at the blank "new issue" form rather than the issues
// list or a templated query string.
const NEW_ISSUE_URL = `${REPO_URL}/issues/new`;

/**
 * Site-wide footer: a link to the GitHub repository, a direct "report an
 * issue" link, and the current release version. Rendered from
 * `app/layout.tsx` rather than `app/page.tsx` since it's shared chrome for
 * every route (mirrors the `<header>` already there), not page-specific
 * content — this is a single-page site today, but the footer shouldn't need
 * to move if that changes.
 *
 * Async Server Component: fetches the same tested release data layer
 * (`lib/releases.ts`, issue 024) the Download section uses. Next.js's fetch
 * cache dedupes the underlying request within a render, so this doesn't add
 * a second network round trip when Download also calls it.
 */
export async function Footer() {
  const version = await getVersion();

  return (
    <footer className={styles.footer}>
      <div className={styles.links}>
        <InteractiveLabel href={REPO_URL} target="_blank" rel="noreferrer noopener">
          github
        </InteractiveLabel>
        <InteractiveLabel href={NEW_ISSUE_URL} target="_blank" rel="noreferrer noopener">
          report issue
        </InteractiveLabel>
      </div>
      {version && <span className={styles.version}>{version}</span>}
    </footer>
  );
}

/**
 * Falls back to omitting the version rather than failing the whole page if
 * the GitHub API is unreachable at request time — the footer's links stay
 * useful without it. `getLatestReleases` returns newest-first (GitHub
 * Releases API order), so the first entry is the current version.
 */
async function getVersion(): Promise<string | null> {
  try {
    const releases = await getLatestReleases();
    return releases[0]?.version ?? null;
  } catch {
    return null;
  }
}
