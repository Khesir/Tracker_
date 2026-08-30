const GITHUB_RELEASES_URL =
  "https://api.github.com/repos/Khesir/Tracker_/releases";

const WINDOWS_ASSET_PATTERN = /\.exe$/i;

/** One asset entry as returned by the GitHub Releases API. */
export interface RawGithubReleaseAsset {
  name: string;
  browser_download_url: string;
}

/** A single release item as returned by the GitHub Releases API. */
export interface RawGithubRelease {
  tag_name: string;
  assets: RawGithubReleaseAsset[];
  body: string | null;
  published_at: string;
  html_url: string;
}

/** The Windows installer asset for a release, if one was published. */
export interface WindowsAsset {
  name: string;
  url: string;
}

/** Everything the landing page's UI needs to render one release. */
export interface NormalizedRelease {
  /** Display version with the `+buildNumber` suffix stripped, e.g. "v0.1.4". */
  version: string;
  /** The raw, unmodified tag (e.g. "v0.1.4+35"), kept for linking. */
  tag: string;
  /** The Windows installer asset, or undefined if none was published. */
  windowsAsset?: WindowsAsset;
  body: string | null;
  publishedAt: string;
  url: string;
}

/**
 * Takes one raw GitHub Releases API item and returns exactly what the UI
 * needs: a display version with the `+buildNumber` suffix stripped, the
 * Windows installer asset (if any), and the changelog fields passed through
 * unchanged.
 */
export function normalizeRelease(raw: RawGithubRelease): NormalizedRelease {
  const tag = raw.tag_name;
  const version = tag.split("+")[0];

  const windowsAssetRaw = raw.assets.find((asset) =>
    WINDOWS_ASSET_PATTERN.test(asset.name)
  );
  const windowsAsset: WindowsAsset | undefined = windowsAssetRaw
    ? { name: windowsAssetRaw.name, url: windowsAssetRaw.browser_download_url }
    : undefined;

  return {
    version,
    tag,
    windowsAsset,
    body: raw.body,
    publishedAt: raw.published_at,
    url: raw.html_url,
  };
}

/**
 * Fetches the release list from GitHub (unauthenticated, revalidated hourly
 * via Next.js's fetch cache) and maps each item through `normalizeRelease`.
 */
export async function getLatestReleases(): Promise<NormalizedRelease[]> {
  const response = await fetch(GITHUB_RELEASES_URL, {
    next: { revalidate: 3600 },
  });

  if (!response.ok) {
    throw new Error(
      `Failed to fetch GitHub releases: ${response.status} ${response.statusText}`
    );
  }

  const raw: RawGithubRelease[] = await response.json();
  return raw.map(normalizeRelease);
}
