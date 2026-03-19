# Vindow Almanac

A sacred calendar web app with role-based authentication, lunar cycles, seasonal themes, US federal holidays, and media-rich event management.

**Live:** https://vindow-calendar.vercel.app/

---

## Stack

| Layer | Technology |
|---|---|
| Frontend | Single-file HTML (`vindow-almanac.html`) — CSS + JS, no framework |
| Auth & Database | Supabase (email/password auth, PostgreSQL, Storage) |
| Deployment | Vercel (static + build step) |
| Fonts | Google Fonts — Cormorant Garamond, Cinzel, Inter |

---

## Local Development

1. Clone the repo
2. Create `supabase-config.js` in the project root (it is gitignored):

```js
const SUPABASE_URL  = 'https://your-project.supabase.co';
const SUPABASE_ANON = 'your-anon-key';
```

3. Open `vindow-almanac.html` directly in any modern browser — no build step needed locally.

> Requires an internet connection for Google Fonts and the Supabase CDN script.

---

## Supabase Setup

Run [`supabase-schema.sql`](supabase-schema.sql) once in **Supabase Dashboard → SQL Editor → New query**.

This creates:

| Object | Purpose |
|---|---|
| `profiles` table | Stores user role (`admin` / `ceo` / `guest`). Auto-populated on signup via trigger. |
| `events` table | Calendar events with title, type, date, icon, description. |
| `attachments` table | File metadata linked to events (name, mime type, storage path). |
| `event-attachments` bucket | Supabase Storage bucket for uploaded images, videos, PDFs, and docs. |
| Row-level security policies | Guests read-only; admin/ceo can create, edit, delete. |

### Managing User Roles

Every new signup defaults to `guest`. To promote a user:

1. Go to **Supabase Dashboard → Table Editor → profiles**
2. Find the user's row
3. Change the `role` field to `admin` or `ceo`

No code changes or redeployment needed.

---

## User Roles

| Role | Permissions |
|---|---|
| `guest` | View calendar and events, read-only |
| `ceo` | All guest permissions + create, edit, delete events and upload attachments |
| `admin` | All CEO permissions + manage user roles |

---

## Password Reset Flow

1. User clicks **Forgot password?** on the login screen
2. Enters email → Supabase sends a reset link to their inbox
3. User clicks the link → lands back on the app
4. App detects `PASSWORD_RECOVERY` auth event → shows **Set New Password** panel
5. User sets new password → redirected to login

**Required Supabase setting:** Add the app URL to **Authentication → URL Configuration → Redirect URLs**:
```
https://vindow-calendar.vercel.app
```

---

## Deployment (Vercel)

Vercel runs `npm run build` on every deploy, which executes `build.js` to generate `supabase-config.js` from environment variables.

Set these in **Vercel Dashboard → Project → Settings → Environment Variables**:

| Variable | Value |
|---|---|
| `SUPABASE_URL` | `https://your-project.supabase.co` |
| `SUPABASE_ANON` | your project's anon/public key |

To deploy manually:

```bash
SUPABASE_URL=https://xxx.supabase.co SUPABASE_ANON=eyJ... npm run build
```

---

## Calendar Features

- **Month grid** with day selection and event indicators
- **Lunar phase engine** — computes moon phase via Julian date math; highlights new/full moons
- **US federal holidays** — floating holidays calculated via `nthWeekday()` / `lastWeekday()`
- **Seasonal themes** — spring, summer, autumn, winter accent variables
- **Personal events** — birthdays, anniversaries, holy days (private to the adding user)
- **Animated star canvas** — 120 procedurally animated stars rendered behind all content
- **List view** toggle alongside the month grid

---

## File Structure

```
vindow-almanac.html   — entire app (HTML + CSS + JS, ~1550 lines)
supabase-schema.sql   — run once in Supabase to set up all tables, policies, and storage
supabase-config.js    — gitignored; holds Supabase URL + anon key
build.js              — writes supabase-config.js from env vars (used by Vercel CI)
package.json          — single script: "build": "node build.js"
vercel.json           — Vercel deployment config
```
