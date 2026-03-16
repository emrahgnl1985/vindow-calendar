# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the Application

Open `vindow-almanac.html` directly in any modern browser. Requires an internet connection for Google Fonts and the Supabase CDN script.

**For local development:** `supabase-config.js` must exist with valid credentials (see below). The placeholder file in the repo has empty strings and will cause auth to fail.

## Build & Deployment

```bash
# Generate supabase-config.js from environment variables (used by Vercel CI)
SUPABASE_URL=https://xxx.supabase.co SUPABASE_ANON=eyJ... npm run build
```

`build.js` writes `supabase-config.js` from env vars. For local dev, edit `supabase-config.js` directly — it is gitignored. Deployment is via Vercel (`vercel.json`), which runs `npm run build` and serves `vindow-almanac.html` at `/`.

## Architecture

Everything lives in a single 1,550-line file: [vindow-almanac.html](vindow-almanac.html)

**Structure:**
- Lines 1–10: HTML head — Google Fonts, Supabase CDN, `supabase-config.js`
- Lines 11–762: Embedded CSS stylesheet (light theme)
- Lines 763–1548: All JavaScript logic
- Lines 1544–1548: Modal backdrop handlers

**Global state variables:**
- `currentUser`, `currentRole` — session state (populated from Supabase session)
- `viewYear`, `viewMonth` — calendar navigation
- `selectedDate` — highlighted day
- `currentView` — `'month'` or `'list'`
- `events` — array persisted to `localStorage`
- `editingId` — ID of event currently being edited
- `pendingFiles` — file attachments staged before save

**Data flow:** Supabase auth → `handleSession()` → role assignment → `initCalendar()` → `renderAll()` → user interactions trigger CRUD → `saveEvents()` to localStorage → `renderAll()` again.

## Key Subsystems

**Authentication** — Supabase email/password auth. Role (`admin`/`ceo`/`guest`) is read from `user.user_metadata.role`. Users must be created in the Supabase dashboard under Authentication → Users with metadata `{ "role": "admin" }`. Auth functions: `doLogin()`, `doLogout()`, `doSignup()`, `doForgotPassword()`. Session is restored on page load via `_supabase.auth.getSession()` + `onAuthStateChange`.

**Calendar rendering** — `renderCalendar()` builds the month grid; `renderAll()` is the top-level re-render that refreshes every panel.

**Event CRUD** — `saveEvent()`, `deleteEvent()`, `viewEvent()`, `openModal()`, `closeModal()`. Events are plain JS objects with a `uid()`-generated id stored in `localStorage`. File attachments in `pendingFiles` are stored as data-URLs on the event object.

**Lunar phase engine** — `getLunarPhase(date)` computes moon phase via Julian date math. `isMajorPhase()` flags new/full moons for special rendering.

**Holiday system** — `getHolidays(year, month)` returns US federal holidays. Uses `nthWeekday()` and `lastWeekday()` helpers for floating holidays (MLK Day, Thanksgiving, etc.).

**Canvas animation** — 120 procedurally animated stars rendered via `requestAnimationFrame` on a `<canvas>` positioned behind all content.

## Design System

CSS custom properties declared on `:root`. This is a **light theme**:
- `--deep: #ffffff`, `--panel: #f8f8f8`, `--card: #ffffff` (backgrounds)
- `--gold: #8a6a20`, `--gold2: #5a4010` (accents)
- `--lavender: #4a3a8a`, `--lavender2: #2e2560` (primary highlights)
- `--rose: #c0396a` (destructive actions)
- `--teal: #1a7a6a` (additional accent)
- `--text: #111111`, `--text2: #444444`, `--text3: #777777`
- Seasonal accent variables: `--spring`, `--summer`, `--autumn`, `--winter`
