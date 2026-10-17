## ADDED Requirements

### Requirement: Locally available greeting font

The greeting SHALL use a bundled font and render without external font downloads.

#### Scenario: External font services unavailable

- **WHEN** the app opens with external font services blocked
- **THEN** the centered text "DEVxSD GameJam!" remains visible
