# trackr_ — app design document

## overview

A minimal time-tracking app built around clarity and focus. The interface stays out of your way — techy monospaced typography, clean white surfaces, and a single accent color that carries all the meaning. Two modes, one identity.

---

## design philosophy

- **Minimal chrome** — no decorative UI. Every element earns its place.
- **Techy but readable** — monospaced fonts for data and labels, a clean sans-serif for body text.
- **Color = signal** — the accent color is reserved for active states, progress, and key numbers. Everything else is neutral.
- **Mode-consistent** — light and dark modes are not separate designs. They share the same layout, spacing, and type scale. Only the palette changes.

---

## typography

| role | font | weight | size |
|---|---|---|---|
| display / headings | Space Mono | 700 | 28–32px |
| labels / badges / timers | Space Mono | 400–700 | 9–13px |
| body / descriptions | DM Sans | 300–400 | 13–15px |
| stats / numbers | Space Mono | 700 | 18–32px |

**Naming convention:** all labels use `lowercase_underscore_` format with a trailing underscore — e.g. `active_`, `queued_`, `done_`. This reinforces the techy aesthetic and creates a consistent visual rhythm.

---

## color system

### light mode — arctic green

| token | value | usage |
|---|---|---|
| background | `#ffffff` | app background |
| surface | `#f8faf8` | cards, task rows |
| border | `#e2e8e2` | card borders, dividers |
| text primary | `#111812` | headings, task names |
| text muted | `#6b7c6e` | subtitles, timestamps |
| accent | `#22c55e` | active timer, progress bars, live dot |
| accent dim | `#bbf7d0` | badge backgrounds |
| accent dark | `#15803d` | badge text on dim bg |

### dark mode — ocean deep

| token | value | usage |
|---|---|---|
| background | `#0a1628` | app background |
| surface | `#0f1e34` | cards, task rows |
| surface raised | `#0f2340` | active task card |
| border | `#1a3a5c` | card borders, dividers |
| text primary | `#e8f4ff` | headings, task names |
| text muted | `#4a7a9a` | subtitles, timestamps |
| accent primary | `#1d9e75` | active timer, primary progress |
| accent secondary | `#4aaccc` | secondary highlights, timers |
| accent dim | `#04342c` | badge backgrounds |
| accent badge text | `#5dcaa5` | badge text on dim bg |

---

## components

### task card

Each task card shows:
- task name (`Space Mono`, 700)
- time logged vs. total (`DM Sans`, 300) — e.g. `2h 14m of 4h 00m`
- progress bar — 3px height, full width, accent fill
- percentage and time remaining (footer row)
- status badge — `active_` / `queued_` / `done_`

### active session timer

Large monospaced countdown/countup displayed prominently at the top of the active screen. Format: `HH:MM:SS`. Subtitle shows the task name and status in muted text below.

### status badges

Pill-shaped labels using `Space Mono` at 9px. Three states:

| state | light bg | light text | dark bg | dark text |
|---|---|---|---|---|
| `active_` | `#bbf7d0` | `#15803d` | `#04342c` | `#5dcaa5` |
| `queued_` | `#e2e8e2` | `#6b7c6e` | `#1a3a5c` | `#4a7a9a` |
| `done_` | `#bbf7d0` | `#15803d` | `#04342c` | `#5dcaa5` |

### stat cards

2-column grid at the bottom of the main view. Each card shows a large number + a small uppercase label. Surface color is slightly tinted with the accent in the active stat.

### top bar

App name `trackr_` on the left in `Space Mono` 700. Live indicator on the right — a 7px pulsing dot + the word `live` in muted text.

---

## screen layout — main dashboard

```
┌─────────────────────────────┐
│  trackr_          • live    │  ← top bar
├─────────────────────────────┤
│  // active session          │  ← section label
│  02:14:38                   │  ← big timer
│  design_sprint — running    │  ← subtitle
│                             │
│  ┌─────────────────────┐    │
│  │ Design sprint  [active_] │  ← task card (active)
│  │ 2h 14m of 4h 00m    │    │
│  │ ████████░░░░ 56%    │    │
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ Client call  [queued_]   │  ← task card (queued)
│  └─────────────────────┘    │
│  ┌─────────────────────┐    │
│  │ Code review   [done_]    │  ← task card (done)
│  └─────────────────────┘    │
│                             │
│  ┌──────────┐ ┌──────────┐  │
│  │  6.5h    │ │    3     │  │  ← stat cards
│  │  today   │ │  tasks   │  │
│  └──────────┘ └──────────┘  │
└─────────────────────────────┘
```

---

## spacing & shape

| token | value |
|---|---|
| card border radius | 10px |
| badge border radius | 20px (pill) |
| stat box border radius | 8px |
| progress bar height | 3px |
| card padding | 12px 14px |
| gap between cards | 10px |
| section label margin | 10px bottom |

---

## theme switching

The app supports user-selectable themes. The light/dark pairing (arctic green + ocean deep) is the default. Future theme options explored:

- **midnight ink** — dark background, violet accent (`#7f77dd`)
- **desert sand** — warm off-white, amber/gold accent (`#ba7517`)

Theme selection UI: a grid of tappable cards, each showing a miniature live preview of the app with real task data — not just color swatches. Selected theme has a highlighted border in its own accent color.

---

## voice & tone

- Labels are lowercase with underscores: `active_`, `running`, `done_`
- Section headers use `// comment` syntax: `// active session`, `// metrics`
- App name is always `trackr_` — trailing underscore, no caps
- Error/empty states use terminal-style phrasing: `no_tasks_found`, `session_ended`

---

*trackr_ design v0.1 — subject to iteration*
