import { SectionLabel } from "@/components/primitives/SectionLabel";
import { InteractiveLabel } from "@/components/primitives/InteractiveLabel";
import { HeroSection } from "@/components/sections/HeroSection";
import { FeaturesSection } from "@/components/sections/FeaturesSection";
import { ScreenshotsSection } from "@/components/sections/ScreenshotsSection";
import { DownloadSection } from "@/components/sections/DownloadSection";
import styles from "./page.module.scss";

// Scaffold placeholder for issue 023 — proves the project scaffold, design
// tokens, theme toggle, and terminal-style primitives all work together.
// The real Hero / Screenshots / Features / Download / Footer sections are
// built in later issues (025-029).
export default function Home() {
  return (
    <main className={styles.main}>
      <HeroSection />

      <SectionLabel as="h1">trackr_ landing page</SectionLabel>
      <p className={styles.title}>trackr_</p>
      <p className={styles.tagline}>
        Scaffold, design tokens, and theme toggle for the trackr_ landing page. Sections land in
        later issues.
      </p>

      <SectionLabel as="h2">primitives preview</SectionLabel>
      <div className={styles.actions}>
        <InteractiveLabel href="#">download</InteractiveLabel>
        <InteractiveLabel
          href="https://github.com/Khesir/Tracker_/issues/new"
          target="_blank"
          rel="noreferrer noopener"
        >
          report issue
        </InteractiveLabel>
      </div>

      <ScreenshotsSection />

      <FeaturesSection />

      <DownloadSection />
    </main>
  );
}
