# Teddoro — architecture note

## State model

Four documents, each one JSON file under the app's documents directory
(`KeyValueStore`), all with ids and timestamps so a sync layer can diff them
later without a schema change:

| Key | Type | Owner |
|-----|------|-------|
| `settings` | `AppSettings` (presets, sounds, colours, goal, earned badges…) | `SettingsController` |
| `tasks`, `projects`, `active_task` | `List<Task>`, `List<Project>`, current task id | `TaskController` |
| `sessions` | append-only `List<SessionRecord>` | `SessionLogController` |
| `timer` | `TimerSnapshot` | `TimerController` |

Every model is immutable with `copyWith`; controllers replace and notify,
never mutate in place. Writes go through a temp file + rename so a crash
mid-write cannot corrupt a document.

Stats (`StatsCalculator`) and badges (`BadgeEvaluator`) are pure functions
over the session log; nothing derived is stored except the set of badges
already celebrated.

## Timer engine

`TimerEngine` (`lib/domain/timer/`) is a pure state machine with no timers
of its own. Every method takes `now`, which makes it deterministic in tests
and independent of the OS scheduler.

```
idle ──start──▶ running ──pause──▶ paused ──start──▶ running
                  │                                     │
                  └──tick(now ≥ endsAt)──▶ SessionEnded ─┘──▶ next session (idle, or running if auto-start)
```

The only time-critical field is `endsAt`, an absolute instant. Remaining
time is always `endsAt − now`, so:

* backgrounding or screen-off does not drift the countdown;
* a force-quit is recovered on launch by `TimerController.restore()`, which
  reloads the snapshot and calls `tick(now, allowAutoStart: false)`. A
  session that ended while the app was dead is logged with its true end
  time, and the timer lands idle on the following session;
* auto-started sessions are anchored at the previous `endsAt`, not at the
  moment the app noticed, so no seconds are lost.

Pause stores `pausedRemainingSeconds` and clears `endsAt`; resume
recomputes `endsAt = now + remaining`.

Cycle bookkeeping: `cycleCount` counts completed work sessions; when it
reaches the preset's `longBreakEvery` the next break is long and the count
rolls to zero. Skipping a work session still advances the count so the user
can reach a long break.

`TimerController` wraps the engine with a 250 ms `Timer.periodic` while
running (notifying listeners only when the displayed second changes), and
on every state change re-syncs the side effects:

1. persist the snapshot
2. publish to the home-screen widget
3. wakelock on/off
4. ambient loop start/stop (only restarted when the sound actually changes)
5. app blocking on/off
6. notifications — an ongoing chronometer notification plus scheduled
   end-of-session alerts (see below)

## Notifications

Two Android channels: `teddoro_running` (low importance, ongoing, uses the
system chronometer counting down to `when = endsAt`, so it ticks without
the app) and `teddoro_finished` (max importance, alarm category, full-screen
intent). End alerts are scheduled with `zonedSchedule` at the absolute
instant using `exactAllowWhileIdle`. When auto-start is on, the follow-on
session's alert is scheduled at the same time so it fires even if the app
is suspended between the two.

The audible alarm itself is played by `audioplayers` with the Android
usage type set to `alarm` and the iOS session to `playback` so it is heard
under silent mode where the OS allows.

## Storage and sync readiness

`KeyValueStore` is a two-method interface (`read`, `write`). The file
implementation is used by the app; `MemoryKeyValueStore` by tests. A future
sync layer would add a third implementation (or wrap the file one) and
merge by document id + `updatedAt`; nothing in the domain layer would
change. A PWA build only needs an IndexedDB-backed store.

## Dependency wiring

`AppDependencies.create` is the single composition root. It takes optional
service overrides, so widget tests boot the real controllers against an
in-memory store, a `FixedClock` and no-op audio/notification/wakelock
services — the same path production uses, minus the platform.
