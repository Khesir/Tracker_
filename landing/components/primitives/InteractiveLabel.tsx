import type { ComponentPropsWithoutRef, ElementType, ReactNode } from "react";
import { toTerminalLabel } from "./terminal-label";
import styles from "./InteractiveLabel.module.scss";

type InteractiveLabelOwnProps<T extends ElementType> = {
  as?: T;
  children: ReactNode;
  /** Pass true when `children` is already formatted (e.g. "download_"). */
  raw?: boolean;
  className?: string;
};

export type InteractiveLabelProps<T extends ElementType = "a"> = InteractiveLabelOwnProps<T> &
  Omit<ComponentPropsWithoutRef<T>, keyof InteractiveLabelOwnProps<T>>;

/**
 * Reusable primitive for the site's trailing-underscore snake_case
 * interactive-label convention (`download_`, `report_issue_`, ...). Renders
 * as an `<a>` by default; pass `as="button"` for non-navigational actions
 * (e.g. the theme toggle) or `as="span"` for a non-interactive display.
 *
 * By default, string children are auto-formatted via `toTerminalLabel`
 * ("Report Issue" -> "report_issue_"). Pass `raw` to render `children`
 * exactly as given.
 */
export function InteractiveLabel<T extends ElementType = "a">({
  as,
  children,
  raw,
  className,
  ...rest
}: InteractiveLabelProps<T>) {
  const Tag = (as ?? "a") as ElementType;
  const content = !raw && typeof children === "string" ? toTerminalLabel(children) : children;
  const classes = className ? `${styles.label} ${className}` : styles.label;

  return (
    <Tag className={classes} {...rest}>
      {content}
    </Tag>
  );
}
