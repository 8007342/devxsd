## MODIFIED Requirements

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


#### Scenario: Stack fills the board
- **WHEN** occupied rows extend toward the bottom
- **THEN** the view subtly pulls outward while the entire inclined board remains visible

### Requirement: Square dimensional cells
Front-meridian cells near the active piece SHALL remain approximately square and large. Distant cells SHALL shrink and foreshorten with perspective; rear cells SHALL stay smaller and dimmer. Active and settled pieces SHALL share solid outward face geometry and lighting. The logical board SHALL remain 18 wrapping columns by 42 rows.

#### Scenario: Inspect local and distant cells
- **WHEN** the camera follows an active piece
- **THEN** nearby front faces remain near-square and the upper stack visibly recedes
- **AND** adjacent row faces retain coherent seams without compensation-induced overlap

### Requirement: Consistent cylinder end planes
The crown and base SHALL use the same upward-view perspective. Their apparent size SHALL reflect distance rather than independent end-ring tilts. The base SHALL remain attached to the spawn rows and the crown to the upper rows as the camera travels.

#### Scenario: Look from the base toward the crown
- **WHEN** a run starts
- **THEN** the nearby base appears larger than the distant crown, with both projected by the same camera


#### Scenario: Compare cylinder ends while turning
- **WHEN** the cylinder rotates at any board position
- **THEN** crown and base retain matching shallow projected profiles and remain connected to their corresponding grid rows

### Requirement: Solid brick face orientation
Bricks SHALL remain solid through the upward view, turning and ascent. Front blocks SHALL expose their outward radial face, rear blocks their inward face, and visible bottom or side surfaces SHALL use outward normals and consistent lighting. Active halos SHALL remain outside opaque solid faces.

#### Scenario: Inspect bricks from below
- **WHEN** the camera looks upward from below the active piece
- **THEN** exposed undersides and tangent faces read as filled solid volume rather than hollow boxes


#### Scenario: Turn bricks across the front and rear
- **WHEN** settled or active bricks rotate around either side of the cylinder
- **THEN** their visible faces and edge shading remain consistent with solid volume

### Requirement: Perspective botanical presentation
The cylinder SHALL remain transparent between blocks, revealing the Monstera and rear pieces. Front blocks SHALL be larger and brighter; rear blocks smaller, dimmer and curved. Visible brick surfaces SHALL follow the camera direction. The ornate crown, dimensional base pot and plants SHALL retain coherent world placement as the camera ascends. Halos SHALL remain legible in pixel art.

#### Scenario: Turn the chandelier
- **WHEN** the player turns the cylinder
- **THEN** the plant turns in the same direction at no more than one third the speed
- **AND** subtle camera parallax reinforces depth without large camera swings

### Requirement: Ring clearing and growth
A full 18-cell row SHALL clear as a ring, with a brief explosion from the completing piece around to the rear, then remaining rows below SHALL shift upward. The plant SHALL begin as a small Monstera sprout in the base pot, visible when the camera includes the base. Each ring SHALL increase its height without a fixed gameplay maximum. Remaining blocks SHALL encourage pothos to grow down from the top.

#### Scenario: Clear multiple rings
- **WHEN** a placement completes two rings
- **THEN** both rings clear with circular effects, lower rows compact upward, and the Monstera grows twice

#### Scenario: Begin with a living plant
- **WHEN** a new run begins with no cleared rings
- **THEN** a small Monstera sprout is visible above the soil in the dimensional base pot alongside the spawning piece

