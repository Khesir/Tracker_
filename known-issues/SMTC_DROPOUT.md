# SMTC Session Dropout

## What happens

The mini timer's media card (album art, song name, controls) disappears even though Spotify is still playing.

## Root cause

This is a Windows behavior. Spotify briefly drops and re-registers its SMTC (System Media Transport Controls) session during:

- Song transitions
- Internal Spotify reconnects
- Volume control interactions
- Background/foreground switches

When the session drops, the app can no longer detect that Spotify is playing, so the card hides.

## Mitigation in code

A 1.5s grace period (3 consecutive 500ms poll misses) is applied before the card clears. This absorbs most brief dropouts.

See: `windows/runner/smtc_plugin.cpp` — `PollLoop()`, `kMissThreshold`.

## When the grace period isn't enough

If the SMTC session drops for longer than 1.5s (or never recovers), the card will remain hidden even with Spotify still playing.

**Suggested fix: restart the app.** This re-initializes the poll loop and picks up the session fresh.

If restarting the app doesn't help, restart Windows. A full system restart clears any stale SMTC state that Windows itself is holding onto.

## Out of our control

- The SMTC session lifecycle is managed entirely by Windows and Spotify.
- There is no API to force Spotify to re-register its session.
- There is no way to read Spotify playback state without an active SMTC session (without using the Spotify Web API, which requires auth).
