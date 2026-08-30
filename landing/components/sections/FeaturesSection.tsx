import { SectionLabel } from "@/components/primitives/SectionLabel";
import styles from "./FeaturesSection.module.scss";

// Copy sourced verbatim from the repo root README.md's "## Features" bullet
// list (Timer through Settings) — no new copywriting, per issue 028's notes.
const FEATURES = [
  {
    name: "Timer",
    description: "start/stop sessions with per-project tracking and inline notes",
  },
  {
    name: "Projects",
    description: "organize sessions by project; view active session header and stats",
  },
  {
    name: "Sessions",
    description: "browse past sessions, view/edit notes, heatmap activity view",
  },
  {
    name: "Analytics",
    description: "time breakdowns across projects and date ranges",
  },
  {
    name: "Mini mode",
    description: "compact floating window (top-right) with SMTC music context and project picker",
  },
  {
    name: "Music context",
    description: "Windows SMTC integration captures currently playing track per session",
  },
  {
    name: "Notes",
    description: "rich text (Quill) notes attached to each session",
  },
  {
    name: "Settings",
    description: "inactivity timeout, mini-mode behavior, theme",
  },
] as const;

/**
 * Features section — lists the app's capabilities as sourced from the root
 * README. Static content only; see issue 028.
 */
export function FeaturesSection() {
  return (
    <section className={styles.section}>
      <SectionLabel as="h2" className={styles.heading}>
        features
      </SectionLabel>
      <ul className={styles.grid}>
        {FEATURES.map((feature) => (
          <li key={feature.name} className={styles.item}>
            <span className={styles.name}>{feature.name}</span>
            <span className={styles.description}>{feature.description}</span>
          </li>
        ))}
      </ul>
    </section>
  );
}
