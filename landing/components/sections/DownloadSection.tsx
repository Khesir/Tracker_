import ReactMarkdown from "react-markdown";
import { SectionLabel } from "@/components/primitives/SectionLabel";
import { InteractiveLabel } from "@/components/primitives/InteractiveLabel";
import { getLatestReleases, type NormalizedRelease } from "@/lib/releases";
import styles from "./DownloadSection.module.scss";

const RELEASES_PAGE_URL = "https://github.com/Khesir/Tracker_/releases";
const CHANGELOG_LIMIT = 5;

// Matches the root README.md's "## Platform" support table — Windows is the
// only shipped target, macOS/Linux are "Not configured".
const UNAVAILABLE_PLATFORMS = ["macos", "linux"] as const;

function formatReleaseDate(publishedAt: string): string {
  return new Date(publishedAt).toLocaleDateString("en-US", {
    year: "numeric",
    month: "short",
    day: "numeric",
  });
}

/**
 * Download & changelog section (issue 026). Async Server Component — fetches
 * the release list once per revalidation window via `getLatestReleases()`
 * (issue 024) rather than on the client, so there's no loading state to
 * design for.
 *
 * Network/API failures are caught locally (rather than left to throw and
 * take down the whole page render) and fall back to a plain link to the
 * GitHub releases page, since this is the first section on the page that
 * depends on a live external fetch.
 */
export async function DownloadSection() {
  let releases: NormalizedRelease[] = [];
  let loadFailed = false;

  try {
    releases = await getLatestReleases();
  } catch {
    loadFailed = true;
  }

  if (loadFailed || releases.length === 0) {
    return (
      <section className={styles.section} id="download">
        <SectionLabel as="h2" className={styles.heading}>
          download
        </SectionLabel>
        <p className={styles.fallback}>
          Releases are temporarily unavailable.{" "}
          <InteractiveLabel href={RELEASES_PAGE_URL} target="_blank" rel="noreferrer noopener">
            view on github
          </InteractiveLabel>
        </p>
      </section>
    );
  }

  const latest = releases[0];
  const changelog = releases.slice(0, CHANGELOG_LIMIT);

  return (
    <section className={styles.section} id="download">
      <SectionLabel as="h2" className={styles.heading}>
        download
      </SectionLabel>

      <div className={styles.versionRow}>
        <span className={styles.versionLabel}>current version</span>
        <span className={styles.version}>{latest.version}</span>
      </div>

      <ul className={styles.platforms}>
        <li className={styles.platform}>
          {latest.windowsAsset ? (
            <InteractiveLabel href={latest.windowsAsset.url} className={styles.platformLink}>
              windows
            </InteractiveLabel>
          ) : (
            <>
              <InteractiveLabel
                as="span"
                aria-disabled="true"
                className={styles.platformLink}
              >
                windows
              </InteractiveLabel>
              <span className={styles.platformNote}>no build published</span>
            </>
          )}
        </li>
        {UNAVAILABLE_PLATFORMS.map((platform) => (
          <li key={platform} className={styles.platform}>
            <InteractiveLabel as="span" aria-disabled="true" className={styles.platformLink}>
              {platform}
            </InteractiveLabel>
            <span className={styles.platformNote}>coming soon</span>
          </li>
        ))}
      </ul>

      <SectionLabel as="h3" className={styles.subheading}>
        changelog
      </SectionLabel>

      <ol className={styles.changelog}>
        {changelog.map((release, index) => {
          const isCurrent = index === 0;

          return (
            <li
              key={release.tag}
              className={isCurrent ? `${styles.releaseItem} ${styles.current}` : styles.releaseItem}
            >
              <div className={styles.releaseHeader}>
                <span className={styles.releaseVersion}>{release.version}</span>
                {isCurrent && <span className={styles.currentBadge}>current</span>}
                <time className={styles.releaseDate} dateTime={release.publishedAt}>
                  {formatReleaseDate(release.publishedAt)}
                </time>
              </div>
              {release.body && (
                <div className={styles.releaseBody}>
                  <ReactMarkdown
                    components={{
                      a: ({ ...props }) => (
                        <a {...props} target="_blank" rel="noreferrer noopener" />
                      ),
                    }}
                  >
                    {release.body}
                  </ReactMarkdown>
                </div>
              )}
            </li>
          );
        })}
      </ol>
    </section>
  );
}
