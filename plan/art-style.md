# Chandelier garden — pixel art and interaction guide

Status: initial production direction for the first playable, 2026-10-17.
Gameplay authority is the OpenSpec change; this document defines its presentation.

## References and interpretation

- [Tlatoāni + Mācron canon](https://raw.githubusercontent.com/8007342/macron.dev/refs/heads/main/assets/Tlato%C4%81ni%20%2B%20M%C4%81cron%20cannon%20guidelines.md): warm natural materials, readable silhouettes, uncluttered environments, and image assets without lettering. Character cameos are not required for the first playable. If introduced later, curated canon images and immutable anatomy rules apply.
- [Monstera deliciosa reference](https://en.wikipedia.org/wiki/Monstera_deliciosa): use climbing stems and recognizable perforated mature leaves; distinguish smaller juvenile foliage visually.
- User direction: transparent cylindrical chandelier; larger front blocks and smaller dim rear blocks; central Monstera; pothos descending from the crown while uncleared blocks remain.

## Art direction

A little luminous greenhouse suspended against a pixel-art night landscape. The plant is the
reward and primary illustration. Terracotta, aged brass, soft cream light, and deep
teal frame it. Blocks are glazed translucent ceramic or cut glass, with crisp
stepped highlights rather than glossy modern gradients. Keep stars, distant hills and nearer vegetation restrained behind the cylinder. The bundled night panorama moves gently, while separate near silhouettes move at a slightly faster rate. No arbitrary ornaments or character mascots in this milestone.

Use chunky pixel silhouettes and stepped contours. Prefer coherent pixel clusters
to isolated noise. Render game art into a low-resolution surface, approximately
216 logical art pixels wide, and upscale with nearest-neighbor filtering. UI text
may remain native resolution for legibility. Smooth world rotation is compatible
with pixel silhouettes; collision state must never depend on pixel rounding.

## Working palette

| Role | Hex |
| --- | --- |
| Conservatory dark | `#091C21` |
| Deep teal shadow | `#123E42` |
| Teal structure | `#276D69` |
| Cream light and text | `#EFE0C4` |
| Brass highlight | `#D4B475` |
| Terracotta | `#BA7256` |
| Leaf deep | `#173F30` |
| Leaf body | `#3A7950` |
| Leaf lit | `#8BB866` |
| Landing halo | `#A9F1D5` |
| Active halo | `#FFF1BC` |

Tetromino accents: cyan `#62D6D1`, cream `#EFE0C4`, coral `#EC6F7B`,
terracotta `#BA7256`, lilac `#B59BCB`, blue `#729EBF`, gold `#D4B475`.
Each block has a dark perimeter, body color, a small upper-left highlight and
lower-right shade. Shape and borders carry identity in addition to color.

## Cylinder rendering

Keep one 18 × 42 wraparound rules grid. Project it into a continuous cylinder;
never use screen-space polygons to decide collisions. For a column angle θ,
place its corners on `(R sin θ, rowHeight × row, R cos θ)`, then apply a mild
camera yaw/pitch and perspective projection. Project all four cell corners, so
side columns taper and rear blocks show curvature. Do not draw a flat board and
scale an entire rear copy.

Use a stable camera depth making rear cells around 45–60% of front-cell linear
size. Near cells remain fully legible; rear cells use roughly 35–45% of their
front brightness. Draw rear grid and blocks first, then central plant layers,
then front grid and blocks. Within a half, sort projected faces by depth.
Empty cells have no fill. Grid outlines are restrained (roughly 8–14% opacity)
and cannot turn the whole cylinder into an opaque cage. Two slim brass crown
ellipses and a warm central lamp establish the chandelier.

The active piece remains world-space, near the front meridian; cylinder rotation
changes its relative board column. Plant yaw accumulates at 0.25–0.33 times board
yaw. Add only a small damped camera offset, capped around 2–3% of viewport width
and 1–2 degrees of yaw. Avoid camera shake during ordinary play. A collision
bounce belongs to the cylinder's visual angle and cannot change the valid rules
position.

The whole 42-row cylinder is always visible at a mild fixed inclination, including
the crown, base, active piece and landing destination. This supersedes the initial
cropped camera idea. Fit the measured projected near-face extent, not merely the cylinder
axis, between 17% and 79% of viewport height. The radius is modestly narrower
and rows taller to preserve brick proportions. Keep the active silhouette
centered by its occupied bounds on the front meridian; the halo stays on the
actual nearest valid destination cells. Stack crowding adds only a small dolly
outward. Never hide either endpoint or use a clamped crown detached from the board.

Bricks have outward radial depth: a lit top lip, shaded side face, highlighted
outer face and narrow dark mortar seams. Project every face from the same cylinder
coordinates so side faces curve around the well. Empty cells remain transparent.
The active piece uses the same volume under its cream silhouette; the mint landing
halo remains hollow and unmistakable.

A bundled pixel night panorama establishes moon, stars and distant terrain. Give
it a low-amplitude horizontal and vertical pan as the cylinder turns. Separate
nearer hill/foliage silhouettes shift slightly faster. Preserve readable stars and
hill colors; avoid covering the whole image with an almost opaque dark gradient.

## Botanical layers

Start with a tiny two-leaf juvenile sprout in a dimensional terracotta pot. Use a shaded curved body, elliptical rim and dark soil, lit rim lip, darker elliptical base and grounding shadow; a subtle rotating highlight supports the all-around illusion. Rings grow the stem, juvenile leaves, larger
split leaves, then repeated stem/leaf growth segments. Give each leaf its own
anchor, azimuth, scale and local shading; depth sorting and horizontal
foreshortening as the plant turns provide the flat-plane 3D illusion. Negative
space between leaf lobes and true interior fenestrations must remain visible.
Use a lighter central vein and two or three large shade clusters, not fine
photographic venation. Avoid identical leaves repeated in adjacent positions.

Pothos descend from the crown as uncleared occupancy persists. Use slender curved
vines with alternating small heart-shaped leaves; they must be visibly distinct
from the Monstera. Keep these near the side/back of the chamber and preserve the
landing halo. Clearing rings retracts/fades the corresponding overgrowth. It is
an ambient consequence, never an extra collision object.

## Effects and controls

A hollow cream active silhouette and mint landing silhouette use translucent
fills with crisp brighter perimeters. Rear blocks cannot obscure the landing
outline. The outline reflects the nearest currently selected column throughout
rotation, so firing between columns has an honest preview.

On clear, a short bright arc begins at the completing piece and travels around
the ring toward the back, followed by quick sparks and upward row compaction.
Aim for 180–240 ms for the arc. Growth can overlap subsequent play. Swipe-up
locks immediately and never waits for cosmetic effects. Natural/accelerated
contact has the rules-defined adjustment delay.

Bottom 20% contains three translucent circular icon controls: counterclockwise
curved arrow, double upward chevron, clockwise curved arrow. No visible words.
Use at least 48 logical pixels per hit target and clear pressed feedback. Expose
semantic accessibility labels. The arrows rotate the piece; only a sideways
drag rotates the cylinder. An initial movement threshold distinguishes tap from
drag, vertical swipe from horizontal drag, and prevents release from rotating a
piece after a spin. Holding the up control accelerates until pointer release or
cancel; swipe-up performs immediate placement. Keyboard equivalents are useful
for browser testing but do not replace touch gestures.

Show the next three pieces small, dim and offset in depth, with the nearest
preview the largest. Keep them outside occupied-cell ambiguity. HUD uses bundled
monospaced numerals, cream text, elapsed time, rings toward 30 in timed mode,
plant height and speed; avoid text embedded in art.

## Asset manifest and implementation sequence

| Asset | Initial implementation | Later production variant |
| --- | --- | --- |
| Cylinder bricks / halos / crown / lamp | Extruded Canvas polygons and pixel clusters | Keep code native for exact projection |
| Night panorama | Bundled generated pixel landscape | Gentle distant parallax plus independent near silhouettes |
| Three control icons | Code paths | Keep code native for legibility |
| Pot and stem | Pixel-aligned Canvas shapes | Optional 48 × 48 pot sprite |
| Juvenile leaf | Pixel-aligned silhouette | Transparent 32 × 32 raster, 3 variants |
| Mature Monstera leaf | Bundled generated transparent sprite, layered on stems | Additional palette-matched variants |
| Pothos leaf / vine | Code silhouettes and stem paths | Transparent 16 × 16 leaf, 3 variants |
| Ring sparks | Small palette-bound particles | Keep code native |

The playable uses a bundled generated mature leaf and procedural juvenile leaves,
stems and pothos. Additional botanical variants follow the imagegen skill: isolated leaf,
transparent background, prescribed palette, no pot or text, no baked contact
shadow, clear stem anchor and generous padding. Inspect sprites at native scale
and in rotation; generated sheets require consistent size, palette and cleaned
alpha before replacing procedural leaves. Do not generate a single full plant
image: it would prevent convincing growth, depth layering and relative rotation.

## Visual acceptance checks

- A portrait screenshot clearly distinguishes front cells, rear cells and plant.
- Empty space reveals the plant and rear pieces; the grid adds no opaque wall.
- Mature leaves read as Monstera; hanging pothos read as smaller heart leaves.
- Rotation continuously foreshortens cells, with a slower rotating central plant.
- Three icon-only controls remain usable over the busy lower board.
- Active and landing silhouettes remain recognizable in all seven piece colors.
- The complete inclined cylinder, crown and base fit between HUD and controls; subtle pullback preserves them.
- No runtime font download or raster asset fetch is needed to start a run.

## Closer camera and reversed keyboard turning

After playtesting, the camera moves a little closer with relaxed horizontal margins.
The projected crown stays below a 128px HUD clearance and the base may sit just
inside the translucent control region. Left arrow visibly turns the cylinder right
one column; Right turns it left. Touch dragging continues to follow the finger.

## End-plane and solid-face correction

Crown and base use matching shallow plane profiles. Apply vertical perspective
to each brick around its own row center, not to the whole row displacement; the
old transform exaggerated the lower ellipse. Use the outer projected face at the front and inward face at the rear. A shallow
down/right backplate, opaque colored center, broad lit top/left bevels and dark
bottom/right bevels deliberately fake clearly raised solid volume. Paint the
active halo behind the face, with no pale face wash or center square. Both rims remain procedural paths.

## Grounded pot and living camera

The pot base follows the cylinder center axis about one row above the bottom rim.
A 52-second roll cycle stays within roughly 0.7 degrees of its resting angle;
67-second shallow pitch and 73-second lateral drift add slower variation. Motion
is subtle and bounded, and fitting continues to protect HUD and controls.

## Outward radial box normals

The player still read screen-space bevels as inverted. Replace the UI-style bevel
with actual projected radial extrusion from the cylinder surface. Front boxes
face outward and rear boxes face inward toward the viewer. Choose the visible
tangent face from its outward normal and light every face from one upper-left,
above/front source. Preserve filled faces and external active halos.


## Living chandelier refinement

Square cell proportions are derived from the eighteen-cell circumference rather
than viewport width. Fitting all forty-two rows therefore gives the cylinder a
tall slender silhouette. A broad six-arm tiered brass crown, curled ends, small
crystal pendants and warm central shaded lamp balance its scale. Preserve legible
pot and leaf minimum sizes rather than shrinking every botanical element with
the board radius. Active cells use the identical radial cuboid and outward-normal
lighting as settled cells, with their glow behind the solid face.

Age-based ecology paints after each rear/front occupied pass: quick crown pothos,
roots gripping surviving occupied cells and subtle moss/dirt. Sparse insects and
one or two butterflies usually accompany growth; a third is rare. Attachment
age moves with compaction and removed cells retain no decoration. Draw landing
and active silhouettes after ecology so the garden never hides input feedback.

## Landing-focused camera (playtest revision)

Prioritize large square front faces over a full-height overview. The logical
18×42 board remains intact, but the cylinder now occupies roughly two thirds of
the phone width. Smoothly follow the mean landing row, leaving the halo near the
center of the playable area; distant rows and the active piece can leave view.
A gentle seven-degree diagonal tilt and slow bounded wobble reinforce depth.
Keep the six-arm crown's ornamental proportions compact independently of the
larger cell size. This supersedes the earlier full-board and slender-tube framing.


## Upward ascent camera (supersedes full-height and destination-only cameras)

Start just below the spawn region looking upward through the chandelier. A true
pinhole transform projects every world row, vertex, ring and botanical anchor;
the eye follows the active piece, never the landing target. Nearby cells remain
large and approximately square through one global horizontal/vertical focal
calibration. Upper rows compress into the distance. Do not stretch local faces
independently: shared seams must stay attached. Ordinary ascent eases smoothly;
a new piece cuts immediately back to the base. Limit follow lag to two rows.

Near base, the pot and juvenile sprout stay attached to their world soil height.
As the eye climbs, omit behind-eye geometry safely; plant leaves and stems each
retain world anchors. The upward view exposes brick undersides, with unchanged
outward radial and tangent normals. Near base rims appear larger than the crown.
Keep the broad ornamental canopy readable independently of its thin physical
end ring, using a compact six-arm silhouette with restrained pendants.

Close-up tuning: retain the 50-degree upward pitch, but move the eye nearer
from seven to three cells outside the wall and reduce trailing eye offset from
six to two rows. Nearby faces are roughly twice as large; rim/side cropping is
intentional. Keep active cells and the distant landing halo within safe bounds.

Bottom-edge composition: add up to45% uniform zoom, constrained by the crown
clearance and the active silhouette width. Anchor its bottom at101.5%screen
height, cropping only a thin strip. Draw the board behind the translucent bottom
controls so more of the screen shows the upper stack and receding crown.
