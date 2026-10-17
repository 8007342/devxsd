# Proposal

## Why
Turn the existing Flame greeting into the requested mobile cylindrical puzzle: upward pieces feed a growing Monstera, and accumulated blocks obscure it with pothos. A 30-ring timed target enables early playtesting.

## What Changes
- Replace the greeting-only screen with a playable portrait game and mode/results UI.
- Add wraparound rules, inertial cylinder input, an inclined full-cylinder camera, extruded pixel bricks, a parallax night landscape, plant growth and ring effects.
- Add Timed (30 rings) and Unlimited modes with three-letter top-ten leaderboards persisted through a Cloudflare Durable Object, with local fallback.
- Define art direction and generate botanical assets; retain bundled open-source fonts.

## Capabilities
### New Capabilities
- `cylindrical-puzzle`: rules, presentation, controls, plants, modes and leaderboards.
### Modified Capabilities
- `devxsd-gamejam`: replace greeting-only landing scope with the mobile game while retaining local tooling and bundled fonts.

## Impact
Flutter/Flame source and tests, botanical assets, Workers API and Durable Object binding, OpenSpec and plan. No deployment is required for local playtesting.
