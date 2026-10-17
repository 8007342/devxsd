## MODIFIED Requirements

### Requirement: Minimal landing canvas
The app SHALL present the cylindrical Monstera puzzle with mode selection, gameplay controls and results, replacing the greeting-only starter canvas.

#### Scenario: Open the landing screen
- **WHEN** a visitor opens the app
- **THEN** the visitor can start a 30-ring timed game or an unlimited game

### Requirement: Responsive canvas
The game SHALL remain playable when the viewport changes size, retaining readable controls and a centered portrait play area.

#### Scenario: Resize the viewport
- **WHEN** the viewport changes from desktop to phone dimensions
- **THEN** gameplay and its controls remain visible and usable

### Requirement: Locally available greeting font
The app SHALL use a bundled open-source font for game UI and render without external font downloads.

#### Scenario: External font services unavailable
- **WHEN** the app opens with external font services blocked
- **THEN** game text and controls remain visible
