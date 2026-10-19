## MODIFIED Requirements

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

### Requirement: Responsive camera and controls
Portrait controls SHALL occupy the bottom 20 percent. The original inclined cylinder SHALL retain its 1.10 uniform zoom, aspect ratio and angles, allowing slight edge spill. The live HUD SHALL show absolute counts such as 27 Rings and plant height, without elapsed clocks, milestone clocks or target fractions. Controls and halos SHALL remain readable.

#### Scenario: Stack fills the board
- **WHEN** occupied rows extend toward the bottom
- **THEN** the view subtly pulls outward while preserving the original viewing angles and uniform zoom

### Requirement: Top ten persistence
One top-ten table SHALL rank completed runs by total rings descending, with height and elapsed duration as tie breakers. It SHALL show same-run 30 Rings time or dash, Rings count and Monstera height. The UI SHALL offer no alternate scoreboard tabs. Existing shared and local records SHALL remain readable, and fallback SHALL identify its source.

#### Scenario: Record a result
- **WHEN** an eligible run ends and the player submits three letters
- **THEN** the result is stored and the best ten for the combined garden are displayed in ranking order

#### Scenario: Offline preview
- **WHEN** the shared API is unavailable
- **THEN** results remain available locally and the interface identifies the board as local

### Requirement: Modes and difficulty
The UI SHALL offer one combined growing game. It SHALL capture the first-thirty-ring time internally and continue until blocked spawning, preserving time for results without showing a live clock. Rings, plant height and difficulty SHALL keep increasing. Speed SHALL rise logarithmically with cleared rings.

#### Scenario: Finish timed mode
- **WHEN** a placement reaches or exceeds 30 cleared rings
- **THEN** the first-thirty time is saved once, the result qualifies for time ranking, and play continues until blocked spawning

#### Scenario: Blocked spawn
- **WHEN** a new piece cannot occupy its bottom spawn position
- **THEN** the run ends; an incomplete timed run is not eligible for fastest completion ranking

### Requirement: Night landscape parallax
The bundled panorama SHALL form independently moving sky, distant terrain and near terrain layers with soft transitions. Slow bounded motion and a subdued twelve-minute night/dawn/day/dusk tint cycle SHALL continue without input. Motion SHALL remain weaker than gameplay and freeze on pause. No external asset fetch SHALL be required.

#### Scenario: Spin against the night landscape
- **WHEN** the player spins the cylinder
- **THEN** background layers shift gently at different depths while the board, halos and plants remain legible

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

### Requirement: Solid brick face orientation
Active and settled bricks SHALL share outward radial and tangent face selection and one lighting model. Active cells SHALL be depth ordered and all active glow SHALL paint before all opaque solids, preventing hollow or inverted-looking faces. Front cells SHALL show their outer face and rear cells their inner face, with filled faces and separated seams.

#### Scenario: Turn bricks across the front and rear
- **WHEN** settled or active bricks rotate around either side of the cylinder
- **THEN** their visible faces and edge shading remain consistent with solid volume
