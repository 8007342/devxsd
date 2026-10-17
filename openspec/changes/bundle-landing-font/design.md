## Context
Flutter default font requests fail in the project-only browser.

## Goals / Non-Goals
Render the existing greeting locally. No gameplay or new UI.

## Decisions
Bundle Noto Sans with its OFL license and declare an explicit font family.

## Risks / Trade-offs
Adds a font asset to the build. Verify in the restricted Chromium browser.
