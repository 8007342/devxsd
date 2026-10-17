# Design

## Context
See proposal.md and plan/cylindrical-game.md. The current app is a small Flame canvas with a bundled Noto Sans font. User explicitly authorized agents to design and implement in one pass; the new spec replaces starter-only scope.

## Goals / Non-Goals
Goals: deterministic board rules independent of visual perspective; mobile touch input; appealing plant-centered rendering; locally testable shared leaderboard.
Non-goals: device-sensor input, app store packaging, authenticated accounts, production deployment, and strict competitive anti-cheat in this prototype. These were not committed requirements.

## Decisions
- Pure Dart model owns the 18x42 grid, seven-bag randomizer, upward gravity, ring compaction and timers. Rows increase downward; cleared rows pull lower rows upward. This is simpler to verify than perspective physics.
- Column motion remains continuous visually. Select the active anchor by subtracting the rotated occupied silhouette center from the front meridian before choosing the nearest column; render the floating silhouette centered on that meridian. The halo remains on the selected grid cells. Half ties follow spin direction. Sweep each crossed column to prevent tunneling. Halo and hard launch share one projection function. Collisions cancel velocity with a small visual bounce.
- Introductory default is one row/second; speed = 1 + 0.55 * ln(1 + rings / 5). It grows with diminishing increments. Hold acceleration is 12x. These are tunable prototype defaults rather than claims of a universal Tetris standard.
- Contact delay defaults to 500 ms; successful moves reset it up to 15 times per piece, avoiding infinite stalling. Swipe-up immediately locks. Rotation uses collision-safe kicks mirrored for upward gravity. Seven-piece bags and no hold are initial defaults.
- A Flame renderer projects cylinder cells into perspective, scales and dims rear blocks, sorts back/plant/front, and draws a transparent lattice, halos and ring bursts. Radial extrusion adds lit top faces, shaded sides and dark brick seams. End planes use consistent shallow vertical projection; perspective scales local brick height about each row center rather than multiplying the entire row position, preventing base-ring distortion. Select the tangent side whose normal faces the viewer (left face on the right cylinder half), use the outer radial face in front and inner radial face at the rear, then shade the connecting top/side faces before the visible radial face. A bundled night panorama pans slowly behind procedural nearer hill/foliage silhouettes at distinct parallax rates. Pixel botanical assets complement procedural stems/leaves to allow unbounded measured growth. Plant rotation is 0.25x board rotation. A juvenile sprout is visible from ring zero; the pot uses an elliptical soil/rim opening, shaded side facets and a base shadow to fake volume.
- Camera fits all 42 rows and the crown/base at a mild fixed inclination, replacing the initially cropped follow camera. Stack depth adds a small dolly-out without ever clipping endpoints. Increase the vertical envelope and modestly narrow the radius to prevent flattened bricks; fit the projected envelope below the HUD and into the translucent control boundary across viewport sizes. A small closer zoom relaxes side margins; the crown retains a minimum HUD clearance. A small bounded parallax accompanies rotation. Independently, very slow bounded roll, shallow pitch and lateral drift vary over 52–73 second cycles. Anchor the pot on the central axis about one row above the base rather than compressing its vertical placement toward the center. Portrait bottom controls consume 20% and gestures distinguish tap, horizontal drag and upward swipe. Keyboard Left/Right shift one column in the opposite visible direction, Up rotates counterclockwise, Down clockwise, Space hard-launches; there is no keyboard soft acceleration.
- Flutter shell owns mode selection, HUD, pause, results, three-letter entry and top tens. Web repository uses same-origin /api/leaderboard with browser local storage fallback; native/test stub uses in-memory storage until platform packaging is requested.
- Worker Durable Object serializes top-ten updates, validates payloads, stores per-mode rankings and routes assets. Local Wrangler exercises the real API; Flutter debug route uses explicitly labeled local fallback when no API is attached.
- User reference repository returned 404 during discovery; implement a small self-contained Durable Object rather than claim reuse of unseen source.

## Risks / Trade-offs
- Rear/front visual overlap → perspective scale, dim rear surfaces and distinct halo styling.
- Gesture ambiguity → displacement threshold; tap fires only after gesture resolves; held button never hard-launches.
- Pixel raster generation may not tile exactly → use isolated botanical assets, nearest-neighbor sampling and deterministic geometry for gameplay cells.
- Public prototype scores are client submitted → validation and payload limits, with competitive verification left outside this prototype's promises.
- Forty-two rows make natural travel slow → acceleration and instant launch remain readily available.

## Migration Plan
Build and test locally, update main specs to shipped behavior, then leave local preview running. No production deployment. Rollback restores prior starter and removes API bindings together.
