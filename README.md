# Chandelier · DEVxSD GameJam

A portrait Flutter + Flame puzzle in a transparent cylindrical chandelier.
Pieces float upward; complete an 18-block ring to grow the Monstera inside.
Each run starts with a little sprout in a shaded terracotta pot near the base.
A very slow, subtle camera wobble keeps the viewing angle alive.
Uncleared blocks bring hanging pothos. The board wraps around 18 columns and is
42 rows tall, with an inclined full-board camera, dimensional bricks and a landing halo.
A bundled pixel-art night landscape shifts in gentle parallax behind the board.

Choose **30-ring sprint** for a timed run, or **Endless garden** for plant height.
Blocked spawning ends a run. Timed rankings accept successful completions only.

## Play

- Drag sideways to turn the cylinder; release to spin, slow down and snap.
- Tap the left/right side or curved-arrow buttons to rotate the active piece.
- Hold the upward icon to accelerate; release to return to normal ascent.
- Swipe upward to immediately place and lock at the mint landing halo.
- Natural contact allows a brief adjustment before locking.
- Keyboard: Left turns the cylinder right one column; Right turns it left; Up/Down rotate the piece
  counterclockwise/clockwise; Space sends instantly; P pauses. No keyboard acceleration.

The next three pieces float in the background. Front blocks are larger/brighter;
rear blocks are smaller/dimmer and the central plant turns at quarter speed.

## Development

Use the Flutter SDK pinned in `.flutter-version` and Node.js 22 or newer.

```sh
flutter pub get
npm ci
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080 --no-web-resources-cdn
```

In this forge, `flutter` runs in the shared sibling toolchain container and prints
the routed local URL. Use `r` for hot reload and `R` for hot restart. Fonts and the
botanical sprite are bundled, so rendering needs no external font service.
The Flutter debug route uses a clearly labeled browser-local leaderboard fallback.

For the Worker preview, including shared Durable Object leaderboards:

```sh
npm run dev
```

This builds the release app and runs local Wrangler on port 8787. Local Durable
Object state persists in ignored `.wrangler/` storage. The API is same-origin:
`GET /api/leaderboard?mode=timed` (or `unlimited`) and `POST /api/leaderboard`
with `{mode,name,seconds,rings,height}`. Names are exactly three uppercase letters;
timed entries require at least 30 rings. Shared tables retain ten entries each.
When the API is unavailable the client persists a local top ten on this browser;
local fallback does not synchronize pending entries later.

## Checks

```sh
flutter analyze
flutter test
node --test worker/leaderboard.test.js
npm run build
openspec validate --all --strict
```

## Cloudflare Workers

Workers Builds: build command `npm run build`, deploy command
`npx wrangler deploy`, root directory repository root. Wrangler serves `build/web`
and binds the SQLite-backed `Leaderboard` Durable Object. The build script can
install the pinned Flutter SDK where absent. Authenticate before a requested
manual deployment; never commit credentials, caches or generated builds.

This prototype accepts client-submitted results, rather than replay-verified
competitive scores. Local preview data is separate from production data.

## Design and specifications

- `openspec/specs/` describes implemented behavior.
- `openspec/changes/cylindrical-monstera-game/` tracks this implementation.
- `plan/cylindrical-game.md` records decisions and playtest questions.
- `plan/art-style.md` defines the pixel palette, perspective and botanical layers.
- `assets/images/README.md` records the generated leaf's prompt and provenance.

Future behavior changes start with OpenSpec requirements, scenarios and tasks.
