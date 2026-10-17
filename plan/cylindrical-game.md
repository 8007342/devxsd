# Cylindrical Monstera game — discovery

## User brief (2026-10-17)

- Flutter + Flame; mobile game with portrait controls.
- Cylindrical board: 18 columns around, 42 rows tall; horizontal wrap.
- Pieces spawn at the bottom and float upward at baseline 1.0x speed.
- Player turns the board rather than moving the piece horizontally.
- Bottom 20% overlays translucent, unlabeled left/right turn and fire-up controls.
- See-through halos show the active silhouette and projected landing position.
- Board resembles a chandelier with a bright central light at the top.
- Updated after first playable feedback: start with a small visible Monstera sprout, then grow with completed rings. Supersedes the empty-pot start.
- Plant has a 3D-like appearance; flat planes and visual tricks are acceptable.
- Plant turns with cylinder at one third or less of its speed.
- Timed mode: top ten fastest completions of 100 rings.
- Unlimited mode: top ten tallest plants.
- Pixel graphics; establish style guides before generating production assets.
- Bundle open-source fonts; Noto Sans is currently bundled. Roboto Mono is an option.
- Keep OpenSpec and plan current across extended work.

## References

- Artwork: https://github.com/8007342/macron.dev/tree/main/assets
- Canon: https://raw.githubusercontent.com/8007342/macron.dev/refs/heads/main/assets/Tlato%C4%81ni%20%2B%20M%C4%81cron%20cannon%20guidelines.md
- Botany: https://en.wikipedia.org/wiki/Monstera_deliciosa

## Confirmed interaction and presentation decisions

- Cylinder surface is transparent: empty cells reveal the central plant and rear pieces; occupied pieces may occlude the view.
- Updated after first playable feedback: show the WHOLE 42-row cylinder at a mild angle, including crown and base. Supersedes the initial two-thirds crop; subtle stress pullback must not clip endpoints.
- Drag horizontally to spin the cylinder freely with inertia and friction; settle by snapping to columns. The earlier alignment-only ascent rule is superseded below: natural ascent continues during turning.
- Plant turns in the same direction at one third or less of the cylinder speed.
- Active launch piece stays at the bottom center; subtle camera movement during turning adds depth without causing dizziness.
- Tap left/right screen sides to rotate the piece. Overlay unlabeled translucent TurnLeft, TurnRight and FireUp controls in the bottom 20%; turn buttons rotate the active piece, never the cylinder. Only sideways swipes/drags rotate the cylinder.
- Swipe up sends the piece instantly to its projected landing position. FireUp button only accelerates ascent; hold/release behavior remains open.
- Landing halo clearly previews the destination.
- Ring completion triggers a brief circular explosion starting at the completing piece and finishing at the back, followed by upward compaction of remaining rows.
- Clearing rings reveals the plant. Plant growth continues without a fixed maximum while rings are completed.

## Further confirmed decisions

- Taps and turn buttons rotate the piece; sideways swipe/drag is the only cylinder-turn input.
- Naturally rising pieces remain in view. Their world motion must be independent of camera motion; rotating the cylinder should feel spatial, not like rotating a flat image.
- Device motion stabilization using accelerometers is a possible future technique, not a required implementation decision yet.
- Occupied slots cannot be crossed or occupied by the active piece. A fixed block can stop cylinder rotation in one direction, while the other direction remains available when its path is clear.
- A piece reaching its upward resting position locks and the next piece spawns at the bottom.
- Show the next three queued pieces smaller, dimmer, and slightly behind the active area, appearing to float while waiting.
- Natural ascent continues during turning, superseding the earlier alignment-only ascent rule. Mid-column angles resolve to a discrete overlapping column; firing during fast rotation is allowed and may be a poor move. Exact selection and tie rules remain open.

## Latest confirmed decisions

- Perspective makes front blocks larger; rear blocks are much smaller and dimmer, with cylinder curvature reinforcing their depth. The plant can occlude rear blocks.
- Start near a documented standard Tetris baseline, then increase speed logarithmically with progressively smaller increments. Formula, progression unit, and cap remain open.
- Collision stops cylinder motion; a small bounce may communicate inertia without allowing overlap.
- Permit a final adjustment after contact before locking, to tuck pieces into corners. Exact inverse-gravity lock delay and movement rules need clarification.
- Hold FireUp to accelerate; release returns to normal ascent, allowing final adjustments.
- Blocked spawning ends a run.
- Leaderboards use three-letter names and top-ten entries for timed and unlimited modes. Lakanoa Durable Objects implementation is a reference: https://github.com/8007342/lakanoa/

## Implementation defaults for the first playable

- Seven standard tetrominoes in shuffled bags; three previews; no hold feature.
- Baseline one row/second; speed = 1 + 0.55 × ln(1 + rings/5); held acceleration 12×.
- Lock delay 500 ms with at most 15 movement resets; swipe-up locks immediately.
- Best-aligned column is nearest; exact half ties follow movement direction; halo uses same rule.
- Plant height grows one centimeter per ring; visible segments provide bounded rendering work.
- Initial Timed target is 30 rings (supersedes original 100); only successful runs qualify.
- Durable Object shared leaderboard with three uppercase letters and browser-local fallback.
- Noto Sans bundled with OFL; Flutter's default Roboto family aliases this asset locally.
- Device accelerometers, accounts, native store packaging and character cameos are future options.

## Presentation revision after first playable

- User found the top frequently offscreen and blocks too flat.
- Keep entire cylinder visible at an angle; render blocks as extruded bricks with top/side faces and mortar-like seams.
- Add a bundled pixel-art landscape and night sky, with gently shifting full parallax layers as the cylinder spins.
- Start with a living sprout; give the pot an elliptical soil/rim opening, shaded volume and base shadow.

## Centering and board proportions revision

- User found active pieces displaced right because their leftmost local cell was treated as the front meridian.
- Center by occupied silhouette bounds for every shape/orientation; selection/halo/hard launch stay on consistent valid grid columns.
- Stretch the complete board vertically within HUD/control boundaries and modestly narrow it so bricks look less collapsed. Later feedback requests a little closer zoom and permits slight side overflow while moving.

## Keyboard controls

- Left arrow turns the cylinder right one column; Right arrow turns it left one column (reversed after playtest feedback).
- Up/Down arrows: rotate piece counterclockwise/clockwise.
- Space: immediate upward launch and lock. No keyboard ascent acceleration.
- P: pause/resume. Touch retains hold-to-accelerate.

## Playtest questions

- Tune initial camera crop, pullback tension and halo readability during fast spins.
- Tune friction, collision bounce, lock delay, speed curve and acceleration multiplier.
- Assess pixel density, botanical variety and front/rear overlap on real phones.
- Consider verified scores before treating the shared top ten as competitive.

## Implementation approach

A pure Dart wraparound model owns collisions, shape centering, timers and scoring.
Flame projects it into an inclined transparent cylinder with depth-sorted bricks.
Generated isolated Monstera leaves combine with procedural stems, juvenile leaves,
pothos and a shaded pot. A bundled night panorama and nearer silhouette layers
move at distinct rates. Art guide: `plan/art-style.md`.

## Current implementation state

The model, perspective renderer, generated leaf asset, touch/keyboard shell and
leaderboard backend/client are implemented under change `cylindrical-monstera-game`.
Model, widget, rendering/layout, persistence, release build and strict spec checks have passed (28 Flutter tests and 3 Worker tests). The live sibling preview remains open in controllable Chromium. See roadmap for subsequent playtest work.
Design guide: `plan/art-style.md`. Asset provenance: `assets/images/README.md`.

## Cylinder base perspective correction

User found the base ring much steeper than the crown. Both are procedural paths,
not images. Correct vertical projection so ring planes have consistent shallow
profiles; apply perspective to individual brick heights around row centers rather
than amplifying each whole row's displacement. Verify rotating crown/base geometry
and full framing before marking the correction complete.

The same correction reverses the incorrectly selected tangent side face and uses
the inward radial face for rear bricks. The live view has been hot-reloaded;
the matching ring-profile regression and browser checks pass. Analysis, all 28 Flutter tests, release build and strict spec validation pass for the correction.

## Grounded pot and living camera

Lower the pot to approximately one row above the base, keeping its center on the
cylinder axis. Add a small, very slow camera roll/pitch/drift cycle independent
of player input. Preserve the shallow matching end planes and full readable
framing. After verification, commit this game and fast-forward main, then push
to origin as explicitly requested by the user.

Grounded-pot and slow-camera changes are implemented and verified: analysis,
28 Flutter tests, 3 Worker tests, release build and strict specs pass. The visible
Chromium preview is hot-reloaded. Publication to main/origin follows this check.

## Solid brick readability follow-up

The player still read the shaded blocks as hollow after the face-normal fix.
Use an opaque filled face with broad outward top/left highlights and darker
bottom/right bevels. Move active halo behind the silhouette and remove its face
wash/center square. Verify front, side and rear views before completing task 2.3.
Remote push also requires quoting scaffolded OpenSpec dates for the receiver's
Ruby YAML validator; this does not change their date values.

Further feedback identifies inverted face normals: use true radial extrusion
from the cylinder surface and normal-based face lighting, with no inset bevel
frame. This supersedes the temporary screen-space bevel approach.

Root cause found during full-pass review: _drawHalf repainted a dark inset cell
rectangle and a fixed highlight after the solid brick renderer. Remove both
overlays. Use brighter top-plane lighting from the above/front light; renderer
geometry now uses viewer-facing outward radial normals and filled faces.

Final outward-normal renderer and removal of the occupied-cell overlay are
hot-reloaded and verified in Chromium. Analysis, 28 Flutter tests, release build
and strict specs pass. Both scaffold dates are now quoted YAML strings.
