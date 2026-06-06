# trackr_ — Implementation Phases

## Status Legend
- `[x]` done
- `[-]` in progress
- `[ ]` not started

---

## Phase 0 — App Shell `[x]`
- [x] `flutter create` project scaffold
- [x] `pubspec.yaml` — hive_flutter, uuid, intl, window_manager, google_fonts, flutter_quill, hotkey_manager
- [x] `core/error/` — Failure hierarchy
- [x] `core/state/` — StreamState, AsyncState, StreamStateBuilder, AsyncStreamBuilder
- [x] `core/di/` — ServiceLocator, DiContainer, ScopedServiceLocator, DILogger, Disposable
- [x] `core/cache/` — LocalCache interface, HiveLocalCache
- [x] `core/models/` — ProjectModel, SessionModel, MusicEntryModel, AppSettingsModel
- [x] `core/theme/` — AppStyling (all design tokens), AppTheme (light/dark), spaceMono/dmSans helpers
- [x] `core/window/` — WindowService (full ↔ mini toggle via window_manager)
- [x] `core/media/` — MediaInfo, MediaService interface, NullMediaService stub
- [x] `core/ui/` — ScopedScreen, DesktopTitleBar (custom frameless titlebar)
- [x] `core/routing/` — Routes, AppRouter
- [x] `core/di/app_composition.dart` — global DI bootstrap
- [x] Feature scaffolds — timer, projects, sessions, analytics, settings (controllers, repos, datasources, states, DI, barrel exports)
- [x] `app.dart` — TrackrApp with mode-aware builder (full ↔ mini), left-rail nav shell
- [x] `main.dart` — bootstrap (Hive, DI, window init)
- [x] Tooltip/Overlay bug fix — Overlay wrapper in MaterialApp builder

---

## Phase 1 — Data Layer `[x]`
> Completed as part of Phase 0.
- [x] ProjectModel, SessionModel, MusicEntryModel, AppSettingsModel (toJson/fromJson)
- [x] Hive box initialization via HiveLocalCache
- [x] ProjectDatasource, SessionDatasource, TimerDatasource, SettingsDatasource

---

## Phase 2 — Projects Feature UI `[x]`
- [x] `ProjectsScreen` — dashboard layout matching design.md (active session header, project cards, stat cards)
- [x] `ProjectCardWidget` — name, time logged, optional progress bar, status badge (`active_` / `queued_` / `done_`)
- [x] `ProjectFormDialog` — create/edit: name input, color picker, optional target hours
- [x] `StatCardWidget` — reusable 2-col stat grid (today's hours, task count)
- [x] `ActiveSessionHeaderWidget` — live ticking timer + project name shown at top when session is running
- [x] Wire `ProjectsController.load()` on screen ready

---

## Phase 3 — Timer Core Logic `[x]`
> Completed as part of Phase 0.
- [x] `TimerController` — start, stop, inactivity auto-end, elapsed ticker, note sync
- [x] `TimerUiState` — running | idle + elapsed, projectId/name, media
- [x] `TimerRepository` + `TimerRepositoryImpl` + `TimerLocalDatasource`

---

## Phase 4 — Media Service (SMTC) `[x]`
- [x] `windows/runner/smtc_plugin.h` + `smtc_plugin.cpp` — background thread polls `GlobalSystemMediaTransportControlsSessionManager` every 500ms, EventChannel streams MediaInfo maps, MethodChannel for play/pause/skip
- [x] `CMakeLists.txt` updated — `smtc_plugin.cpp` in executable, links `windowsapp.lib`, C++17 + `/await`
- [x] `flutter_window.cpp` updated — `SmtcPlugin::RegisterWithRegistrar()` called in `OnCreate`
- [x] `WindowsMediaService` — Dart wrapper over EventChannel + MethodChannel
- [x] `app_composition.dart` updated — uses `WindowsMediaService` on Windows, `NullMediaService` otherwise, calls `initialize()` before registering
- [ ] macOS stub — `MRMediaRemote` (deferred)
- [x] Wire into `TimerController.onMediaChanged()` (done in Phase 5)

---

## Phase 5 — Mini Window Real UI `[x]`
- [x] `RecordDiskWidget` — vinyl circle with grooves painted via CustomPainter, album art in center label, `AnimationController` rotation tied to `isPlaying`
- [x] `MusicBarWidget` — `SizeTransition` slide-in/out, shows artist + track, auto-hides 5s after music stops, play/pause + skip controls
- [x] `SessionNoteWidget` — `flutter_quill` editor (bold, italic, bullets), 500ms debounced save to `TimerController.updateNote()`
- [x] `TimerScreen` rewritten — disk + timer side-by-side, note editor, music bar, stop bar, header with expand/close
- [x] Media stream wired from `MediaService` into `TimerController.onMediaChanged()`

---

## Phase 6 — Sessions History `[x]`
- [x] `SessionsScreen` — day-grouped `CustomScrollView`, day header with total duration, export button; uses `ScopedScreen`, loads both sessions + projects controllers
- [x] `SessionRowWidget` — color strip, project name + time, note preview (plain text), duration, music count badge
- [x] `SessionDetailSheet` — note plain text, music log rows, `edit_note_` + `delete_` action buttons
- [x] `SessionNoteEditDialog` — `SessionNoteWidget` inside a Dialog for editing note in-place
- [x] `SessionsController.exportCsv()` — writes CSV to `%USERPROFILE%\Downloads\trackr_sessions.csv`, shows path in snackbar
- [x] `SessionsController.load()` — now sorts descending and filters out active sessions

---

## Phase 7 — Dashboard (Main Screen) `[x]`
- [x] `_LiveIndicator` in `DesktopTitleBar` converted to stateful — subscribes to `TimerController`, pulses green + "• live" when running, grey "idle" otherwise
- [x] `ProjectsScreen` wired to `SessionsController` — loads sessions alongside projects in `onReady`
- [x] Per-project `loggedSeconds` computed from completed sessions and passed to `ProjectCardWidget`
- [x] Metrics expanded to 2×2 grid: today's hours, this week's hours, streak (consecutive days), top project (by weekly time)
- [x] All metric computations are local helpers (no new files, no packages)

---

## Phase 8 — Analytics `[x]`
- [x] `AnalyticsSummary` updated — added `dailySeconds: Map<DateTime, int>` for last 7 days
- [x] `AnalyticsController.load()` builds daily breakdown from week sessions
- [x] `AnalyticsScreen` — `ScopedScreen` loading both analytics + projects controllers
- [x] `_WeekBarChart` — animated `AnimatedContainer` bars for last 7 days, today highlighted in accent
- [x] `_StatPill` row — week total, today, streak
- [x] `_ProjectRankRow` — ranked list with color dot, progress bar showing fraction of weekly total

---

## Phase 9 — Settings `[x]`
- [x] `SettingsScreen` — full `ScopedScreen` with `CustomScrollView`
- [x] Theme toggle — two preview cards (ocean_deep_ / arctic_green_) with mini app layout preview; selecting triggers immediate theme change via `TrackrApp` subscription to `SettingsController`
- [x] `TrackrApp` in `app.dart` — subscribes to `SettingsController.uiState`, drives `MaterialApp.themeMode`
- [x] Inactivity timeout slider — 1–60 min, updates `TimerController.setInactivityTimeout()` on change
- [x] Float lock toggle
- [x] `_HotkeyPicker` — shows current hotkey, click to open `_CaptureDialog` which uses `KeyboardListener` to capture key combo, confirms on Enter or modifier+key
- [x] CSV export button (same export as sessions screen)

---

## Phase 10 — Global Hotkey + System Tray `[x]`
- [x] `HotkeyService` — parses key string (e.g. "ctrl+shift+t") to `HotKey`, registers with `hotkey_manager` at `HotKeyScope.system`; toggle: stops session if running, else brings window to front
- [x] `main.dart` — calls `HotkeyService.initialize()` after window init
- [x] `app_composition.dart` — registers `HotkeyService` as singleton
- [x] `HotkeyService.updateHotkey()` — called from settings when user rebinds
- [ ] System tray icon — deferred (requires `tray_manager`, not in approved packages)

---

## Deferred / Future
- System tray icon (requires `tray_manager` approval)
- Backend sync (repositories are swappable, no refactor needed)
- macOS SMTC (`MRMediaRemote`) full implementation
- Linux media detection (MPRIS)
- Notifications on session milestone durations
- Mobile / web
