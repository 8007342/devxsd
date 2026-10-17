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
Sideways dragging SHALL spin the cylinder with inertia, friction and eventual column snapping. Ascent SHALL continue during turning. Occupied cells SHALL block motion, with a brief visual bounce and no overlap or tunneling. The player SHALL be able to take a clear path in the opposite direction.

#### Scenario: Spin reaches a fixed block
- **WHEN** cylinder motion would move the active piece through an occupied slot
- **THEN** motion stops with a small bounce before overlap
- **AND** opposite movement remains possible if its swept path is clear

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
A full 18-cell row SHALL clear as a ring, with a brief explosion from the completing piece around to the rear, then remaining rows below SHALL shift upward. The plant SHALL begin as a small visible Monstera sprout. Each ring SHALL increase its height without a fixed gameplay maximum. Remaining blocks SHALL encourage pothos to grow down from the top.

#### Scenario: Clear multiple rings
- **WHEN** a placement completes two rings
- **THEN** both rings clear with circular effects, lower rows compact upward, and the Monstera grows twice

#### Scenario: Begin with a living plant
- **WHEN** a new run begins with no cleared rings
- **THEN** a small Monstera sprout is visible above the soil in a shaded dimensional pot

### Requirement: Perspective botanical presentation
The cylinder SHALL be transparent between blocks, revealing the Monstera and rear pieces. Front blocks SHALL be larger and brighter; rear blocks smaller, dimmer and curved around the cylinder. Blocks SHALL have visible brick depth through top and side faces with separated seams. A central top light, dimensional pot with rim and shaded sides, active silhouette and landing halo SHALL remain legible in pixel art.

#### Scenario: Turn the chandelier
- **WHEN** the player turns the cylinder
- **THEN** the plant turns in the same direction at no more than one third the speed
- **AND** subtle camera parallax reinforces depth without large camera swings

### Requirement: Responsive camera and controls
Portrait controls SHALL occupy the bottom 20 percent as translucent icons. An inclined view SHALL keep the entire cylinder, crown, base, active piece and landing target visible. Camera pullback as the stack fills SHALL preserve this full view. The board SHALL use available vertical space so bricks remain distinct rather than appearing collapsed. A closer camera SHALL permit relaxed side margins during movement. The view SHALL remain usable at phone and desktop sizes.

#### Scenario: Stack fills the board
- **WHEN** occupied rows extend toward the bottom
- **THEN** the view subtly pulls outward while the entire inclined board remains visible

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
The crown and base SHALL share a coherent shallow plane projection. The base SHALL appear flat relative to the crown rather than expanding into a steep independently tilted ellipse. Rear bricks SHALL retain depth scaling without stretching either end ring.

#### Scenario: Compare cylinder ends while turning
- **WHEN** the cylinder rotates at any board position
- **THEN** crown and base retain matching shallow projected profiles and remain connected to their corresponding grid rows

### Requirement: Solid brick face orientation
Bricks SHALL appear solid with visible side faces facing the viewer. Front-layer bricks SHALL show their outer radial face; rear-layer bricks SHALL show their inward face. Edge shading SHALL reinforce raised volume rather than a hollow recess.

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
