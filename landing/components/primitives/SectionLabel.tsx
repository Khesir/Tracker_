import type { ElementType, ReactNode } from "react";
import styles from "./SectionLabel.module.scss";

interface SectionLabelProps {
  children: ReactNode;
  /** Wrapping element — defaults to a plain paragraph-level label. */
  as?: ElementType;
  className?: string;
}

/**
 * Reusable primitive for the site's `// section_label` terminal-comment
 * header convention. Every later section (Hero, Screenshots, Features,
 * Download/Changelog, Footer) should use this rather than hand-rolling
 * the "// " prefix.
 */
export function SectionLabel({ children, as: Tag = "p", className }: SectionLabelProps) {
  const classes = className ? `${styles.label} ${className}` : styles.label;

  return (
    <Tag className={classes}>
      <span className={styles.comment} aria-hidden="true">
        {"//"}
      </span>
      {children}
    </Tag>
  );
}
