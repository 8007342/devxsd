## MODIFIED Requirements

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

### Requirement: Consistent cylinder end planes
The crown and base SHALL use the same upward-view perspective. Their apparent size SHALL reflect distance rather than independent end-ring tilts. The base SHALL remain attached to the spawn rows and the crown to the upper rows as the camera travels.

#### Scenario: Look from the base toward the crown
- **WHEN** a run starts
- **THEN** the nearby base appears larger than the distant crown, with both projected by the same camera

### Requirement: Responsive camera and controls
Portrait controls SHALL occupy the bottom 20 percent as translucent icons. The camera SHALL start near the base looking upward, showing the spawning piece and base, then follow the active piece smoothly through ascent. Perspective SHALL compress distant rows while keeping the local play area large. The landing halo and relevant stack ahead SHALL remain readable. New spawns SHALL regain a usable base view immediately. Camera motion SHALL remain bounded on phones and desktops.

#### Scenario: Begin an ascent
- **WHEN** a new run begins
- **THEN** the spawning piece and base are visible below the receding upper board
- **AND** the upward view communicates depth rather than just rotating a flat image

#### Scenario: Follow the piece toward the stack
- **WHEN** the piece rises naturally or with held acceleration
- **THEN** the camera follows without losing it behind the HUD or controls
- **AND** nearby cells stay large while the landing area and upper rows recede in perspective

#### Scenario: Lock and immediately play again
- **WHEN** an instant launch or natural lock spawns the next piece
- **THEN** the base view returns immediately so the player can act without waiting through a long camera sweep

### Requirement: Ring clearing and growth
A full 18-cell row SHALL clear as a ring, with a brief explosion from the completing piece around to the rear, then remaining rows below SHALL shift upward. The plant SHALL begin as a small Monstera sprout in the base pot, visible when the camera includes the base. Each ring SHALL increase its height without a fixed gameplay maximum. Remaining blocks SHALL encourage pothos to grow down from the top.

#### Scenario: Clear multiple rings
- **WHEN** a placement completes two rings
- **THEN** both rings clear with circular effects, lower rows compact upward, and the Monstera grows twice

#### Scenario: Begin with a living plant
- **WHEN** a new run begins with no cleared rings
- **THEN** the base pot contains a small Monstera sprout above the soil; the landing-focused camera may place this pot outside the viewport

## ADDED Requirements

### Requirement: Square dimensional cells
Front-meridian tetromino faces SHALL be approximately square; side and rear faces SHALL foreshorten. The cylinder SHALL occupy over half the play-area width. Active and settled pieces SHALL share solid outward face geometry and lighting.

#### Scenario: Inspect an active and settled piece
- **WHEN** pieces appear near the front meridian
- **THEN** their front-meridian cells read as squares and both active and settled pieces read as solid volumes

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
