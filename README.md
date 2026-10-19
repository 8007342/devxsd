# Chandelier · DEVxSD GameJam

A portrait Flutter + Flame puzzle in a transparent cylindrical chandelier.
Pieces float upward; complete an 18-block ring to grow the Monstera inside.
Each run starts with a little sprout in a shaded terracotta pot near the base.
A very slow, subtle camera wobble keeps the viewing angle alive. A modest 10%
uniform zoom preserves the original projection and angles with relaxed margins.
Uncleared blocks bring hanging pothos. The board wraps around 18 columns and is
42 rows tall, with an inclined full-board camera, dimensional bricks and a landing halo.
A bundled pixel-art night landscape shifts in gentle parallax behind the board.

Choose **Grow a garden**. Runs continue until blocked spawning. The live HUD
shows an absolute count such as **27 Rings** and plant height, with no timer.
The first-thirty time is recorded quietly for results. One top ten ranks total
rings, with **30 Rings** time, **Rings** total and **Monstera** height from the same
run. Incomplete runs show a dash for the milestone time.

Sky, distant terrain and nearer silhouettes drift independently even without
input. A quiet twelve-minute light cycle passes through night, dawn, day and dusk.
The ambient layers pause with the game and stay behind the main-plane movement.

## Play

- Drag sideways to turn the cylinder; careful releases preserve the halo column.
  Deliberate fast flicks coast briefly before snapping to a grid anchor.
- Tap either side to rotate the active piece and flash its borderless arrow icon.
  The whole side is the tap surface; upward sends never also tap-rotate.
- Hold the upward icon to accelerate; release to return to normal ascent.
- Swipe upward to immediately place and lock at the mint landing halo.
- Natural contact allows a brief adjustment before locking.
- Keyboard: Left turns the cylinder right one column; Right turns it left; Up/Down rotate the piece
  counterclockwise/clockwise; Space sends instantly; P pauses. No keyboard acceleration.

The next three pieces appear in a spaced vertical preview on the right; the
first has 1.5× the block-edge size of the second and the third is smaller still.
New Monstera leaves emerge rolled, unfold, and mature at irregular per-run sizes
and angles. Multi-ring clears produce larger, brighter leaves; the plant keeps
producing new nodes as the run continues. Front blocks are larger/brighter;
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
with `{mode:"run",view:"timed"|"unlimited",name,seconds,time30,rings,height}`.
`seconds` is total run duration; `time30` is the first-thirty time or null for an
incomplete run. One transaction records both rankings when qualified. The UI reads the survival board as its one canonical rings table. Legacy
single-board submissions remain readable. Names are exactly three uppercase
letters; time rankings require at least 30 rings. Shared tables retain ten entries each.
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
