## MODIFIED Requirements

### Requirement: Upward wraparound board
The game SHALL use 18 wrapping columns and 42 rows, spawning one of seven tetrominoes centered by its occupied-cell silhouette at the bottom and moving it upward automatically. The next three pieces SHALL appear enlarged and clearly readable, with spacing that distinguishes their order and no overlap between previews.

#### Scenario: Center the active silhouette
- **WHEN** any of the seven pieces spawns or rotates in open space
- **THEN** its occupied silhouette stays centered on the front meridian rather than extending from a leftmost-cell anchor
- **AND** the landing halo and instant launch use the same collision-valid selected column

#### Scenario: Natural ascent
- **WHEN** a run begins
- **THEN** an active piece rises from the bottom and the next three pieces are visible
- **AND** horizontal coordinates wrap across the cylinder seam

### Requirement: Cylinder movement and collisions
Sideways dragging SHALL spin the cylinder with prompt exact grid-anchor snapping. Gentle releases SHALL preserve the selected landing column, including half-centered pieces; only deliberate fast flicks SHALL coast and settle within half a second on an unobstructed board. Ascent SHALL continue during turning and snapping. Occupied cells SHALL block motion, with a brief visual bounce and no overlap or tunneling. The player SHALL be able to take a clear path in the opposite direction.

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

### Requirement: Ring clearing and growth
Full 18-cell rows SHALL clear with circular effects and compact lower rows upward. A potted sprout SHALL grow without a gameplay height maximum. Leaves SHALL emerge, unfold and mature with per-run irregular sizes and poses. Multi-ring placements SHALL create larger, brighter new leaves. Uncleared blocks SHALL encourage crown pothos.

#### Scenario: Clear multiple rings
- **WHEN** a placement completes two rings
- **THEN** both rings clear with circular effects, lower rows compact upward, and the Monstera grows twice

#### Scenario: Begin with a living plant
- **WHEN** a new run begins with no cleared rings
- **THEN** a small Monstera sprout is visible above the soil in the dimensional base pot alongside the spawning piece

### Requirement: Responsive camera and controls
Portrait controls SHALL occupy the bottom 20 percent. The original inclined cylinder SHALL use a modest uniform 1.10 zoom with unchanged aspect ratio, projection and angles. Slight edge spill while panning or spinning SHALL be allowed. Stack-dependent pullback SHALL retain this projection. Bricks, halos and controls SHALL remain readable at phone and desktop sizes.

#### Scenario: Stack fills the board
- **WHEN** occupied rows extend toward the bottom
- **THEN** the view subtly pulls outward while preserving the original viewing angles and uniform zoom

### Requirement: Modes and difficulty
Both starting modes SHALL capture the elapsed time on first reaching at least 30 rings and continue until blocked spawning. The captured thirty-ring time SHALL remain fixed while total elapsed time, rings and plant height continue increasing. Time ranking SHALL order qualifying runs ascending; survival ranking SHALL order final ring counts descending. Blocked spawning SHALL end either run. Speed SHALL start at a familiar introductory pace and increase logarithmically with cleared rings.

#### Scenario: Finish timed mode
- **WHEN** a timed placement reaches or exceeds 30 cleared rings
- **THEN** the first-thirty time is saved once, the result qualifies for time ranking, and play continues until blocked spawning

#### Scenario: Blocked spawn
- **WHEN** a new piece cannot occupy its bottom spawn position
- **THEN** the run ends; an incomplete timed run is not eligible for fastest completion ranking

### Requirement: Top ten persistence
Time and survival rankings SHALL each retain ten three-letter entries. Rows SHALL show 30 Rings (milestone time or dash), Rings (final count), and Monstera (final height) from the same run. One submission SHALL record both rankings when qualified, otherwise survival only. Shared writes SHALL be atomic. Legacy entries SHALL remain readable; offline results SHALL persist locally with honest source labels.

#### Scenario: Record a result
- **WHEN** an eligible run ends and the player submits three letters
- **THEN** the result is stored and the best ten for the selected mode are displayed in ranking order

#### Scenario: Offline preview
- **WHEN** the shared API is unavailable
- **THEN** results remain available locally and the interface identifies the board as local

### Requirement: Keyboard controls
Left/Right arrows SHALL turn the cylinder right/left by exactly one reachable grid anchor per key event, regardless of shape rotation, fractional angle, pending snap or seam. Occupied cells SHALL block movement rather than skip columns. Up/Down SHALL rotate counterclockwise/clockwise and flash the matching icon. Space SHALL instantly launch and lock. Keyboard input SHALL not accelerate ascent.

#### Scenario: Play with a keyboard
- **WHEN** a player presses Up, Down, Left, Right or Space
- **THEN** the corresponding rotation, column shift or immediate launch occurs without enabling soft ascent acceleration
