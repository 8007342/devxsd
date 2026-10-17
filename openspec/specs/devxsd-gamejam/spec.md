# DEVxSD GameJam

## Purpose

Provide a locally runnable Flutter and Flame mobile puzzle with bundled assets and Cloudflare hosting.

## Requirements

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

### Requirement: Web build and deployment

The repository SHALL provide an npm build command producing Flutter web assets for Cloudflare Workers static hosting.

#### Scenario: Build and deploy

- **WHEN** a developer runs `npm ci` and `npm run build`
- **THEN** the release web app is generated in `build/web`
- **AND** `npx wrangler deploy` can deploy those assets to an authenticated Cloudflare account

### Requirement: Local development

The repository SHALL document how to run Flutter development and a local Wrangler preview.

#### Scenario: Start development

- **WHEN** a developer follows the README setup instructions
- **THEN** they can analyze, test, and preview the app locally

### Requirement: Locally available greeting font
The app SHALL use a bundled open-source font for game UI and render without external font downloads.

#### Scenario: External font services unavailable
- **WHEN** the app opens with external font services blocked
- **THEN** game text and controls remain visible
