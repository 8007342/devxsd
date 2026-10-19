# Cylindrical puzzle

## Purpose
Provide a mobile upward stacking puzzle around a transparent chandelier, where clearing rings grows a central Monstera.

## Requirements

### Requirement: Upward wraparound board
The game SHALL use 18 wrapping columns and 42 rows with seven upward-rising tetrominoes. Three spaced upcoming pieces SHALL remain readable; the first SHALL have at least 1.5 times the block-edge length of the second, with the third smaller still.

#### Scenario: Center the active silhouette
- **WHEN** any of the seven pieces spawns or rotates in open space
- **THEN** its occupied silhouette stays centered on the front meridian rather than extending from a leftmost-cell anchor
- **AND** the landing halo and instant launch use the same collision-valid selected column

#### Scenario: Natural ascent
- **WHEN** a run begins
- **THEN** an active piece rises from the bottom and the next three pieces are visible
- **AND** horizontal coordinates wrap across the cylinder seam

### Requirement: Cylinder movement and collisions
Sideways dragging SHALL spin the cylinder with exact grid-anchor snapping. Gentle release SHALL preserve the selected halo column; deliberate flicks SHALL coast briefly. Piece rotation SHALL preserve cylinder yaw and snap phase across subsequent frames, except for a collision-required wall kick. Occupied cells SHALL block swept motion without overlap or tunneling. Ascent and opposite motion SHALL remain responsive.

#### Scenario: Spin reaches a fixed block
- **WHEN** cylinder motion would move the active piece through an occupied slot
- **THEN** motion stops with a small bounce before overlap
- **AND** opposite movement remains possible if its swept path is clear

#### Scenario: Finish a gentle drag or fast flick
- **WHEN** the player releases the cylinder on an unobstructed board
- **THEN** gentle motion starts snapping immediately and fast motion finishes settling into an exact column within half a second
- **AND** the rising piece and immediate launch remain responsive throughout

### Requirement: Piece controls and projected landing
Side taps SHALL rotate the piece and flash the matching borderless arrow. Each gesture SHALL express only one intent: rotation, cylinder turn, or upward send; sends SHALL never rotate. Holding the contoured upward control SHALL accelerate ascent until release. An upward swipe SHALL instantly lock at the halo destination using the selected release column, even while spinning or starting over an icon.

#### Scenario: Fire while spinning
- **WHEN** the user swipes upward while the cylinder is between columns
- **THEN** the piece locks at the same best-aligned column and destination shown by the halo

#### Scenario: Accelerate then adjust
- **WHEN** the player releases the upward button before contact
- **THEN** ascent returns to normal speed and piece rotation remains available

### Requirement: Final contact adjustment
Natural or accelerated contact SHALL allow a short lock delay for rotation and cylinder adjustment before locking. An upward swipe SHALL lock immediately without that delay.

#### Scenario: Slide before locking
- **WHEN** a naturally rising piece reaches its resting position
- **THEN** the user has a brief opportunity to rotate or slide into a reachable gap before it locks

### Requirement: Ring clearing and growth
Full 18-cell rows SHALL clear with circular effects and compact lower rows upward. A potted sprout SHALL grow without a gameplay height maximum. Leaves SHALL emerge, unfold and mature with per-run irregular sizes and poses. Multi-ring placements SHALL create larger, brighter new leaves. Uncleared blocks SHALL encourage crown pothos.

#### Scenario: Clear multiple rings
- **WHEN** a placement completes two rings
- **THEN** both rings clear with circular effects, lower rows compact upward, and the Monstera grows twice

#### Scenario: Begin with a living plant
- **WHEN** a new run begins with no cleared rings
- **THEN** a small Monstera sprout is visible above the soil in the dimensional base pot alongside the spawning piece

### Requirement: Perspective botanical presentation
The cylinder SHALL be transparent between blocks, revealing the Monstera and rear pieces. Front blocks SHALL be larger and brighter; rear blocks smaller, dimmer and curved around the cylinder. Blocks SHALL have visible brick depth through top and side faces with separated seams. An ornate six-arm brass crown with curled arms, crystal pendants and a warm shaded lamp, dimensional pot with rim and shaded sides, active silhouette and landing halo SHALL remain legible in pixel art.

#### Scenario: Turn the chandelier
- **WHEN** the player turns the cylinder
- **THEN** the plant turns in the same direction at no more than one third the speed
- **AND** subtle camera parallax reinforces depth without large camera swings

### Requirement: Responsive camera and controls
Portrait controls SHALL occupy the bottom 20 percent. The original inclined cylinder SHALL retain its 1.10 uniform zoom, aspect ratio and angles, allowing slight edge spill. The live HUD SHALL show absolute counts such as 27 Rings and plant height, without elapsed clocks, milestone clocks or target fractions. Controls and halos SHALL remain readable.

#### Scenario: Stack fills the board
- **WHEN** occupied rows extend toward the bottom
- **THEN** the view subtly pulls outward while preserving the original viewing angles and uniform zoom

### Requirement: Modes and difficulty
The UI SHALL offer one combined growing game. It SHALL capture the first-thirty-ring time internally and continue until blocked spawning, preserving time for results without showing a live clock. Rings, plant height and difficulty SHALL keep increasing. Speed SHALL rise logarithmically with cleared rings.

#### Scenario: Finish timed mode
- **WHEN** a placement reaches or exceeds 30 cleared rings
- **THEN** the first-thirty time is saved once, the result qualifies for time ranking, and play continues until blocked spawning

#### Scenario: Blocked spawn
- **WHEN** a new piece cannot occupy its bottom spawn position
- **THEN** the run ends; an incomplete timed run is not eligible for fastest completion ranking

### Requirement: Top ten persistence
One top-ten table SHALL rank completed runs by total rings descending, with height and elapsed duration as tie breakers. It SHALL show same-run 30 Rings time or dash, Rings count and Monstera height. The UI SHALL offer no alternate scoreboard tabs. Existing shared and local records SHALL remain readable, and fallback SHALL identify its source.

#### Scenario: Record a result
- **WHEN** an eligible run ends and the player submits three letters
- **THEN** the result is stored and the best ten for the combined garden are displayed in ranking order

#### Scenario: Offline preview
- **WHEN** the shared API is unavailable
- **THEN** results remain available locally and the interface identifies the board as local

### Requirement: Night landscape parallax
The bundled panorama SHALL form independently moving sky, distant terrain and near terrain layers with soft transitions. Slow bounded motion and a subdued twelve-minute night/dawn/day/dusk tint cycle SHALL continue without input. Motion SHALL remain weaker than gameplay and freeze on pause. No external asset fetch SHALL be required.

#### Scenario: Spin against the night landscape
- **WHEN** the player spins the cylinder
- **THEN** background layers shift gently at different depths while the board, halos and plants remain legible

### Requirement: Keyboard controls
Left/Right arrows SHALL turn the cylinder right/left by exactly one reachable grid anchor per key event, regardless of shape rotation, fractional angle, pending snap or seam. Occupied cells SHALL block movement rather than skip columns. Up/Down SHALL rotate counterclockwise/clockwise and flash the matching icon. Space SHALL instantly launch and lock. Keyboard input SHALL not accelerate ascent.

#### Scenario: Play with a keyboard
- **WHEN** a player presses Up, Down, Left, Right or Space
- **THEN** the corresponding rotation, column shift or immediate launch occurs without enabling soft ascent acceleration

### Requirement: Consistent cylinder end planes
The crown and base SHALL share a coherent shallow plane projection. The base SHALL appear flat relative to the crown rather than expanding into a steep independently tilted ellipse. Rear bricks SHALL retain depth scaling without stretching either end ring.

#### Scenario: Compare cylinder ends while turning
- **WHEN** the cylinder rotates at any board position
- **THEN** crown and base retain matching shallow projected profiles and remain connected to their corresponding grid rows

### Requirement: Solid brick face orientation
Active and settled bricks SHALL share outward radial and tangent face selection and one lighting model. Active cells SHALL be depth ordered and all active glow SHALL paint before all opaque solids, preventing hollow or inverted-looking faces. Front cells SHALL show their outer face and rear cells their inner face, with filled faces and separated seams.

#### Scenario: Turn bricks across the front and rear
- **WHEN** settled or active bricks rotate around either side of the cylinder
- **THEN** their visible faces and edge shading remain consistent with solid volume

### Requirement: Grounded pot and gentle camera motion
The pot SHALL begin close to the cylinder base, centered on its axis. The camera SHALL vary its viewing angle very slowly with small bounded motion, preserving readable controls, centered pieces and coherent crown/base profiles.

#### Scenario: View the starting sprout
- **WHEN** a run starts
- **THEN** the sprout pot rests near the base rather than floating high inside the cylinder

#### Scenario: Watch an idle view
- **WHEN** the cylinder is not being turned
- **THEN** its camera angle changes gently over a long cycle without rapid wobble or large swings
### Requirement: Living chandelier ecology
The crown SHALL have layered dimensional ornamental supports and warm central illumination. Accumulated blocks SHALL encourage quickly growing pothos hanging from the crown, roots attached to occupied pieces, and subtle dirt and moss increasing with settled age. Cleared cells SHALL lose their attached dirt and roots. Foliage SHALL preserve gameplay visibility.

#### Scenario: Let a stack mature
- **WHEN** settled blocks remain for several seconds
- **THEN** hanging vines grow visibly, roots grip occupied pieces and their surfaces gradually weather
- **AND** active cells and landing halos remain readable

#### Scenario: Clear rooted blocks
- **WHEN** a ring clears and the lower stack compacts upward
- **THEN** weathering follows surviving pieces and removed cells retain no floating root or dirt attachments

### Requirement: Sparse garden insects
Growing foliage SHALL attract occasional tiny flies, bees and ladybugs without forming swarms. A growing Monstera SHALL have at most three nearby butterflies, ordinarily one or two when present, with three appearing rarely. Decorative insects SHALL not affect collisions or inputs.

#### Scenario: Observe a taller Monstera
- **WHEN** the plant grows through ring clearing
- **THEN** a few butterflies wander gently around it with no more than three visible, while other garden insects remain sparse
