# Cylindrical puzzle

## Purpose
Provide a mobile upward stacking puzzle around a transparent chandelier, where clearing rings grows a central Monstera.

## Requirements

### Requirement: Upward wraparound board
The game SHALL use 18 wrapping columns and 42 rows, spawning one of seven tetrominoes centered by its occupied-cell silhouette at the bottom and moving it upward automatically. The next three pieces SHALL appear smaller and dimmer behind the active area.

#### Scenario: Center the active silhouette
- **WHEN** any of the seven pieces spawns or rotates in open space
- **THEN** its occupied silhouette stays centered on the front meridian rather than extending from a leftmost-cell anchor
- **AND** the landing halo and instant launch use the same collision-valid selected column

#### Scenario: Natural ascent
- **WHEN** a run begins
- **THEN** an active piece rises from the bottom and the next three pieces are visible
- **AND** horizontal coordinates wrap across the cylinder seam

### Requirement: Cylinder movement and collisions
Sideways dragging SHALL spin the cylinder with inertia and prompt exact column snapping. Gentle releases SHALL start snapping immediately; fast releases SHALL interrupt residual momentum and settle within half a second on an unobstructed board. Ascent SHALL continue during turning and snapping. Occupied cells SHALL block motion, with a brief visual bounce and no overlap or tunneling. The player SHALL be able to take a clear path in the opposite direction.

#### Scenario: Spin reaches a fixed block
- **WHEN** cylinder motion would move the active piece through an occupied slot
- **THEN** motion stops with a small bounce before overlap
- **AND** opposite movement remains possible if its swept path is clear

#### Scenario: Finish a gentle drag or fast flick
- **WHEN** the player releases the cylinder on an unobstructed board
- **THEN** gentle motion starts snapping immediately and fast motion finishes settling into an exact column within half a second
- **AND** the rising piece and immediate launch remain responsive throughout

### Requirement: Piece controls and projected landing
Left/right screen taps and unlabeled translucent rotation buttons SHALL rotate the piece. Holding the upward button SHALL accelerate ascent; releasing SHALL restore normal speed. Swiping up SHALL instantly place and lock at the halo destination using the best-aligned column at release, even during a spin.

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
A full 18-cell row SHALL clear as a ring, with a brief explosion from the completing piece around to the rear, then remaining rows below SHALL shift upward. The plant SHALL begin as a small Monstera sprout in the base pot, visible when the camera includes the base. Each ring SHALL increase its height without a fixed gameplay maximum. Remaining blocks SHALL encourage pothos to grow down from the top.

#### Scenario: Clear multiple rings
- **WHEN** a placement completes two rings
- **THEN** both rings clear with circular effects, lower rows compact upward, and the Monstera grows twice

#### Scenario: Begin with a living plant
- **WHEN** a new run begins with no cleared rings
- **THEN** a small Monstera sprout is visible above the soil in the dimensional base pot alongside the spawning piece

### Requirement: Perspective botanical presentation
The cylinder SHALL remain transparent between blocks, revealing the Monstera and rear pieces. Front blocks SHALL be larger and brighter; rear blocks smaller, dimmer and curved. Visible brick surfaces SHALL follow the camera direction. The ornate crown, dimensional base pot and plants SHALL retain coherent world placement as the camera ascends. Halos SHALL remain legible in pixel art.

#### Scenario: Turn the chandelier
- **WHEN** the player turns the cylinder
- **THEN** the plant turns in the same direction at no more than one third the speed
- **AND** subtle camera parallax reinforces depth without large camera swings

### Requirement: Responsive camera and controls
Portrait controls SHALL occupy the bottom 20 percent as translucent icons over the board. The upward camera SHALL follow the active piece smoothly, with its recognizable silhouette crossing the bottom screen edge. Nearby cells SHALL stay large; sides MAY spill beyond view. The crown, upper stack and landing halo SHALL remain readable. New spawns SHALL immediately restore the base view. Camera motion SHALL remain bounded.

#### Scenario: Begin an ascent
- **WHEN** a new run begins
- **THEN** the spawning silhouette is recognizable at the bottom edge below the receding upper board; the base may lie outside the close-up
- **AND** the upward view communicates depth rather than just rotating a flat image

#### Scenario: Follow the piece toward the stack
- **WHEN** the piece rises naturally or with held acceleration
- **THEN** the camera follows without losing it behind the HUD or controls
- **AND** nearby cells stay large while the landing area and upper rows recede in perspective

#### Scenario: Lock and immediately play again
- **WHEN** an instant launch or natural lock spawns the next piece
- **THEN** the base view returns immediately so the player can act without waiting through a long camera sweep

### Requirement: Modes and difficulty
Timed mode SHALL finish immediately on clearing 30 rings and rank successful completion times ascending. Unlimited SHALL continue until blocked spawning and rank plant heights descending. Blocked spawning SHALL end either run. Speed SHALL start at a familiar introductory pace and increase logarithmically with cleared rings.

#### Scenario: Finish timed mode
- **WHEN** a timed placement reaches or exceeds 30 cleared rings
- **THEN** the timer stops immediately and the result is eligible for the timed leaderboard

#### Scenario: Blocked spawn
- **WHEN** a new piece cannot occupy its bottom spawn position
- **THEN** the run ends; an incomplete timed run is not eligible for fastest completion ranking

### Requirement: Top ten persistence
Each mode SHALL show a top ten with three-letter names. Shared results SHALL persist through a leaderboard API, with locally persisted fallback when the API is unavailable and an honest indication of which board is shown.

#### Scenario: Record a result
- **WHEN** an eligible run ends and the player submits three letters
- **THEN** the result is stored and the best ten for the selected mode are displayed in ranking order

#### Scenario: Offline preview
- **WHEN** the shared API is unavailable
- **THEN** results remain available locally and the interface identifies the board as local

### Requirement: Night landscape parallax
The game SHALL show a bundled pixel-art night landscape behind the cylinder, with sky, distant terrain and nearer silhouettes moving gently at different rates as the cylinder turns. The backdrop SHALL preserve gameplay contrast and require no external runtime image source.

#### Scenario: Spin against the night landscape
- **WHEN** the player spins the cylinder
- **THEN** background layers shift gently at different depths while the board, halos and plants remain legible

### Requirement: Keyboard controls
Left arrow SHALL turn the cylinder right one column; Right arrow SHALL turn it left one column. Up and Down arrows SHALL rotate the piece counterclockwise and clockwise respectively. Space SHALL instantly launch and lock. Keyboard input SHALL provide no controlled ascent acceleration.

#### Scenario: Play with a keyboard
- **WHEN** a player presses Up, Down, Left, Right or Space
- **THEN** the corresponding rotation, column shift or immediate launch occurs without enabling soft ascent acceleration

### Requirement: Consistent cylinder end planes
The crown and base SHALL use the same upward-view perspective. Their apparent size SHALL reflect distance rather than independent end-ring tilts. The base SHALL remain attached to the spawn rows and the crown to the upper rows as the camera travels.

#### Scenario: Look from the base toward the crown
- **WHEN** a run starts
- **THEN** the nearby base appears larger than the distant crown, with both projected by the same camera

### Requirement: Solid brick face orientation
Bricks SHALL remain solid through the upward view, turning and ascent. Front blocks SHALL expose their outward radial face, rear blocks their inward face, and visible bottom or side surfaces SHALL use outward normals and consistent lighting. Active halos SHALL remain outside opaque solid faces.

#### Scenario: Inspect bricks from below
- **WHEN** the camera looks upward from below the active piece
- **THEN** exposed undersides and tangent faces read as filled solid volume rather than hollow boxes

### Requirement: Grounded pot and gentle camera motion
The pot SHALL begin close to the cylinder base, centered on its axis. The camera SHALL vary its viewing angle very slowly with small bounded motion, preserving readable controls, centered pieces and coherent crown/base profiles.

#### Scenario: View the starting sprout
- **WHEN** a run starts
- **THEN** the sprout pot rests near the base rather than floating high inside the cylinder

#### Scenario: Watch an idle view
- **WHEN** the cylinder is not being turned
- **THEN** its camera angle changes gently over a long cycle without rapid wobble or large swings

### Requirement: Square dimensional cells
Front-meridian cells near the active piece SHALL remain approximately square and large. Distant cells SHALL shrink and foreshorten with perspective; rear cells SHALL stay smaller and dimmer. Active and settled pieces SHALL share solid outward face geometry and lighting. The logical board SHALL remain 18 wrapping columns by 42 rows.

#### Scenario: Inspect local and distant cells
- **WHEN** the camera follows an active piece
- **THEN** nearby front faces remain near-square and the upper stack visibly recedes
- **AND** adjacent row faces retain coherent seams without compensation-induced overlap

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
