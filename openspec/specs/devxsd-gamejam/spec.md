# DEVxSD GameJam

## Purpose

Initialize a development-ready Flutter and Flame web project for DEVxSD GameJam.

## Requirements

### Requirement: Minimal landing canvas

The app SHALL render a Flame game canvas inside Flutter displaying only the centered text "DEVxSD GameJam!" on a plain background.

#### Scenario: Open the landing screen

- **WHEN** a visitor opens the app
- **THEN** the canvas displays "DEVxSD GameJam!"
- **AND** there are no buttons, menus, counters, or other visible content

### Requirement: Responsive canvas

The greeting SHALL remain centered when the viewport changes size.

#### Scenario: Resize the viewport

- **WHEN** the viewport changes from desktop to phone dimensions
- **THEN** the greeting remains visible and centered

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
