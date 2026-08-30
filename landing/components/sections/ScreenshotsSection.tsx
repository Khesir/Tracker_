import Image from "next/image";
import { SectionLabel } from "@/components/primitives/SectionLabel";
import { InteractiveLabel } from "@/components/primitives/InteractiveLabel";
import styles from "./ScreenshotsSection.module.scss";

interface Screenshot {
  src: string;
  /** Intrinsic pixel dimensions of the source PNG — required by next/image
   * when `src` is a public-folder path string rather than a static import,
   * so it can compute the correct aspect ratio and avoid layout shift. */
  width: number;
  height: number;
  alt: string;
  /** Caption text, auto-formatted to the trailing-underscore convention by
   * InteractiveLabel (e.g. "Minimize Mode" -> "minimize_mode_"). */
  caption: string;
}

// Sourced once from `assets/docs/` (the Flutter app's own doc screenshots) as
// a manual, one-time copy into `public/screenshots/` — see issue 027's notes.
// There is no automated sync between the two folders going forward.
const SCREENSHOTS: Screenshot[] = [
  {
    src: "/screenshots/Dashboard.png",
    width: 980,
    height: 699,
    alt: "trackr_ dashboard view showing tracked projects and daily stats",
    caption: "Dashboard",
  },
  {
    src: "/screenshots/session.png",
    width: 980,
    height: 702,
    alt: "An active tracking session in trackr_",
    caption: "Session",
  },
  {
    src: "/screenshots/analytics.png",
    width: 980,
    height: 700,
    alt: "trackr_ analytics view with time breakdowns and charts",
    caption: "Analytics",
  },
  {
    src: "/screenshots/minimize-mode.png",
    width: 683,
    height: 520,
    alt: "trackr_ running in its compact minimize mode",
    caption: "Minimize Mode",
  },
];

/**
 * Screenshots gallery section (issue 027). Reuses the app's own doc
 * screenshots, rendered via next/image for automatic responsive
 * sizing/format optimization. Grid is `auto-fit`/`minmax`-based so it
 * reflows to a single column on narrow viewports without any explicit
 * breakpoint (none is defined in styles/_variables.scss yet).
 */
export function ScreenshotsSection() {
  return (
    <section className={styles.section}>
      <SectionLabel as="h2">screenshots</SectionLabel>
      <ul className={styles.grid}>
        {SCREENSHOTS.map((shot) => (
          <li key={shot.src} className={styles.item}>
            <div className={styles.frame}>
              <Image
                src={shot.src}
                alt={shot.alt}
                width={shot.width}
                height={shot.height}
                sizes="(max-width: 700px) 100vw, 320px"
                className={styles.image}
              />
            </div>
            <InteractiveLabel as="span" className={styles.caption}>
              {shot.caption}
            </InteractiveLabel>
          </li>
        ))}
      </ul>
    </section>
  );
}
