## Why
Shape-width changes still change the cylinder snap phase after rotation, causing cumulative drift. The combined game needs one relaxed interface, clearer preview priority and consistent active brick volume.

## What Changes
- Preserve cylinder alignment across piece rotations, including subsequent simulation frames.
- Present one game entry and one score table ordered by rings, retaining same-run thirty-ring times and height in results.
- Remove live timing and target fractions; display absolute counts such as 27 Rings.
- Decompose the existing panorama in code into softly blended sky, distant terrain and near terrain layers with slow independent temporal motion and a subdued night/dawn cycle.
- Make the first queued piece substantially larger than the following two.
- Depth-sort active solids and draw their glow beneath the whole piece using the same outward faces and lighting as settled bricks.
- Verify, refresh the local preview, merge this work into main and push origin/main.

## Capabilities
### Modified Capabilities
- `cylindrical-puzzle`: stable rotation, one quiet interface, ambient background, queue hierarchy and coherent active solids.

## Impact
Model, Flutter UI, renderer, visual and input regressions, docs and OpenSpec. Existing score storage remains compatible. No manual production deployment.
