/**
 * Converts arbitrary text into the site's trailing-underscore snake_case
 * interactive-label convention (e.g. "Report Issue" -> "report_issue_"),
 * mirroring the label style used throughout the Flutter app's own UI
 * (see PRD "Implementation Decisions" — `download_`, `report_issue_`).
 */
export function toTerminalLabel(text: string): string {
  const snake = text
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "_")
    .replace(/^_+|_+$/g, "");

  return snake ? `${snake}_` : "_";
}
