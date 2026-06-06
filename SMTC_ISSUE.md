# SMTC (System Media Transport Controls) — Broken Event Channel

## Status
Open — unresolved after multiple fix attempts.

## Symptoms
- No `[SMTC] raw event received:` ever appears in `flutter run` console.
- `_NowPlayingIndicator` in the title bar never shows any track.
- Mini mode (`TimerScreen`) opens with empty media info regardless of what is playing.
- Media controls (play/pause, skip) fire method channel calls that return `Success` but nothing happens in Spotify or any other player.
- `[SMTC] initialize: subscribing to event channel` and `[SMTC] initialize: done` appear correctly — the Dart subscription is set up.
- No `[SMTC] event channel error:` or `[SMTC] event channel closed` either — the channel is silent, not erroring.

## What used to work (commit `ec659bb`)
- Controls (play/pause, skip) worked. After pressing a control, the poll loop detected the state change and emitted an event. Dart received it and updated the UI.
- First render did NOT show media info (see root cause below) — you had to press a control first to trigger the first event.

## Root cause of original first-render issue
The original poll loop updates `last_title`/`last_playing` on tick 1 even when `event_sink_` is null (because `OnListen` hasn't fired yet at that point). After tick 1, `changed = false` on every subsequent tick since nothing changed — so nothing is ever emitted until SMTC state actually changes (e.g., user presses a control).

## What was changed and broke controls too
`FindSpotifySession` (iterate sessions by app ID, return Spotify) was replaced with `GetBestSession` (iterate all sessions, call `TryGetMediaPropertiesAsync().get()` on each to find the best one). This introduced a double async call: once inside `GetBestSession` during session selection, and again in `PollLoop` on the returned session.

After this change, not even controls produce events anymore. The event channel went completely silent.

## Fix attempts (all failed)
1. Replaced `GetBestSession` with `FindMediaSession` using `GetCurrentSession()` (synchronous, no iteration). Same result — no events.
2. Added `warmup_ticks` to force emit for first 6 poll ticks regardless of change. No events received.
3. Added `snapshot` method channel call: Dart calls `requestSnapshot()`, C++ spawns thread, fetches SMTC, calls `EmitSnapshot`. No events received.
4. Added immediate emit in `OnListen`: when Dart subscribes, C++ spawns a thread immediately to push current state. No events received.
5. Added `flutter clean` before each run. No change.

## Diagnostics collected
- `[App] MediaService type=WindowsMediaService` — correct service is instantiated, not `NullMediaService`.
- `[SMTC] initialize: subscribing to event channel` — Dart subscription is created.
- No `[SMTC] raw event received:` ever — C++ `event_sink_->Success()` is either not being called, or the event is not reaching Dart.
- C++ `OutputDebugStringA` logs (DbgLog) are NOT visible in `flutter run` console — require DebugView or VS debugger to inspect.

## Current state of C++ plugin (`smtc_plugin.cpp`)
- `FindMediaSession`: uses `GetCurrentSession()`, falls back to `GetSessions()[0]`.
- `OnListen`: sets `event_sink_`, starts poll thread, spawns immediate-emit thread.
- `PollLoop`: emits on change only (no warmup).
- `snapshot` method: returns `Success()` immediately, spawns thread to call `EmitSnapshot`.
- `EmitSnapshot`: acquires `sink_mutex_`, checks `event_sink_ != nullptr`, calls `event_sink_->Success(map)`.

## Suspected root causes (uninvestigated)
1. `OnListen` is never actually called — the "listen" platform message is never processed by the Win32 message pump for some reason.
2. `event_sink_->Success()` is called but the binary messenger fails to deliver the message to Dart (e.g., task runner issue in the Flutter Windows embedder).
3. The C++ plugin is compiled correctly but there is a silent runtime crash in the background thread (SEH exception not caught by `catch(...)`).
4. The `flutter::EventChannel` using `StandardMethodCodec` has a codec mismatch with the Dart side in this specific Flutter Windows version.

## How to investigate further
- Attach a native debugger (VS or WinDbg) and set a breakpoint inside `SmtcPlugin::OnListen` and `SmtcPlugin::EmitSnapshot` to confirm they are called.
- Check if `OutputDebugStringA` from `DbgLog` appears in DebugView when running under VS debugger.
- Try replacing `event_sink_->Success()` with a simpler test value (e.g., a plain string) to rule out encoding issues.
- Check if the issue reproduces on a different machine or Flutter version.

## Files involved
- `windows/runner/smtc_plugin.cpp`
- `windows/runner/smtc_plugin.h`
- `lib/core/media/windows_media_service.dart`
- `lib/core/media/media_service.dart`
- `lib/core/di/app_composition.dart`
- `lib/core/ui/desktop_title_bar.dart` (`_NowPlayingIndicator`)
- `lib/features/timer/presentation/screen/timer_screen.dart`
