## MODIFIED Requirements

### Requirement: Responsive camera and controls
The game SHALL restore the full-height cylinder projection and dimensions from main commit 413bf3b, with the complete 42-row board between HUD and controls and a subtle stack-dependent pullback. The ornate six-arm brass crown, crystal pendants and warm shaded lamp SHALL remain.

#### Scenario: Inspect the restored cylinder
- **WHEN** a run starts or the cylinder turns
- **THEN** crown and base retain matching shallow profiles and the complete board stays visible at main dimensions
- **AND** the ornate crown and living garden remain visible

#### Scenario: Ascend and respawn
- **WHEN** a piece rises, locks or respawns
- **THEN** framing remains a full-board overview rather than tracking the piece

#### Scenario: Stack fills the board
- **WHEN** occupied rows extend toward the bottom
- **THEN** the view subtly pulls outward while the entire inclined board remains visible
