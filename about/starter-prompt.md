# Teddoro — Pomodoro app

Build a Pomodoro timer app called **Teddoro**. It must work fully offline, keep accurate time even when the phone screen is off or the app is in the background, and never lose a running session.

## Platform

- Built with **Flutter** (Dart), targeting iOS + Android from a single codebase.
- Must support: background timers, local notifications, keep-screen-awake, home/lock-screen widgets, and iOS Live Activities.
- All data stored locally on the device. No account or backend in v1.

## 1. Timer (core)

- Three session types: **Work**, **Short break**, **Long break**. Each duration is configurable in minutes.
- **Long break after N work sessions** (default N = 4).
- Controls: **Start / Pause / Skip / Reset**.
- **Auto-start toggles**, separate for breaks and for work sessions.
- **Alarm** on session end: choice of several sounds, volume slider, preview button. Must play even if the phone is on silent/DND where the OS allows it.
- **Keep the phone awake** while a timer is running (screen never locks or dims). Setting to turn this off.
- **Persistent notification / Live Activity** showing the countdown so it's visible without opening the app.
- **Confirm before quitting** with an active timer (back gesture / swipe-away / close prompt).
- **Focus message** shown on screen while a timer runs (e.g. "Stay on it — 12:34 left"). User can edit the message.
- Timing must use absolute timestamps (start time + duration), not tick counting, so backgrounding, sleep, or a killed process does not drift or lose the session. On relaunch, resume the correct remaining time.

## 2. Tasks

- **Task list** with title, estimated pomodoros, completed pomodoros, done checkbox.
- Assign each task to a **project** and optional **tags**; free-text **ticket/reference** field (e.g. JIRA-123).
- **Active task** shown next to the timer; its completed-pomodoro count increments when a work session finishes.
- **Daily goal** (e.g. 8 pomodoros/day) with a progress indicator on the main screen.
- Reorder, edit, archive, delete tasks. Filter by project/tag/done.

## 3. Stats & history

- Every completed session is logged (type, start, end, duration, task, project).
- **Daily / weekly / monthly reports**: pomodoros completed, total focus time, current streak, best streak.
- **Per-task and per-project time breakdown** (list + simple bar chart).
- **GitHub-style heatmap** of focus days for the last 12 months.
- Export session log as CSV.

## 4. Focus aids

- **Ambient sounds** during work sessions: rain, café, white noise, ticking clock. Independent volume, loops seamlessly, can mix with the alarm.
- **Strict mode**: while on, Pause/Skip/Reset are disabled until the session ends. Warn the user before enabling.
- **App/website blocking** during work sessions using the platform's native mechanism (iOS Screen Time / FamilyControls, Android Digital Wellbeing / accessibility-based blocking). User picks the apps/sites to block. If blocking isn't available on the device, hide the feature gracefully.
- **Minimal / full-screen mode**: hides everything except the countdown and the focus message. Tap to exit.

## 5. Gamification

- **Streaks**: consecutive days that hit the daily goal.
- **Badges**: daily goal reached, 7-day streak, 30-day streak, 100 pomodoros, etc. Show a small celebration when earned.

## 6. Personalisation

- **Color per mode**: red for work, green for short break, blue for long break (defaults, user-editable).
- **Light / dark / system** theme.
- **Timer presets**: built-in 25/5/15, 50/10/20, 90/20/30; user can save custom presets and switch between them in one tap.
- **Break reminders**: during breaks, show rotating prompts like "Stand up and stretch", "Drink water", "Look away from the screen". User can edit the list or turn it off.

## 7. Platform features

- **Offline-first**: everything works with no network.
- **Widgets**: home-screen widget (countdown + start/pause), lock-screen widget, iOS Live Activity / Android ongoing notification during a session.
- Design the data layer so **cross-device sync via account** and a **PWA/web build** can be added later without a rewrite (keep all state in one local store with IDs and timestamps).

## 8. Branding

- App name: **Teddoro**.
- Logo/app icon: a **teddy-bear face inside a clock** — round clock face, bear ears at the top, friendly bear eyes/nose in the centre, clock hands over the face. Provide it as an SVG plus all required app-icon sizes.
- Use the same bear motif in the empty states and the celebration screens.

## Non-functional

- Accessible: large tap targets, screen-reader labels on all controls, respects reduced-motion.
- Settings persist across restarts.
- Unit tests for the timer engine (state machine, long-break cadence, resume-after-kill) and for stats calculations; widget tests for the main timer screen.
- Native Flutter widgets (Material 3) with a custom theme — no web-view.
- Widgets and Live Activities are implemented as native iOS (SwiftUI / WidgetKit) and Android (Glance / RemoteViews) extensions that read from shared storage, bridged from Flutter via a plugin or method channel.
- Clean, warm visual style — friendly and playful, not corporate.

## Deliverables

1. Short architecture note (state model, timer engine, storage, notifications).
2. Working app with all sections 1–8.
3. Logo SVG + icon set.
4. README with how to run on iOS and Android (`flutter run`, required native setup for widgets/Live Activities/app blocking).
