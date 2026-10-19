## Context
Grid anchors depend on occupied-center offsets, which change with shape orientation. Snapping must preserve the selected halo column without using the new shape width to rotate the cylinder. The same brick renderer serves active and settled blocks, but active cells currently interleave halo strokes and faces in shape-array order, so later glows and faces can obscure earlier solids.

## Decisions
Store a cylinder snap phase independent of shape rotation. Choose the nearest angle on that phase lattice whose grid anchor matches the currently selected halo; keyboard shifts choose the adjacent anchor on the same lattice. Rotations and kicks retain this phase. Spawn and debug initialization establish phase from the current yaw. Add complete multi-frame rotation-cycle and gesture tests.

Use the existing survival board as the canonical total-rings table; preserve storage and legacy time data. Offer one play action and no score tabs. Keep milestone timing internally and in results, remove all live clocks and target denominators. Retain plant height and quiet occupancy feedback.

Extract a code-native backdrop compositor. Draw the bundled image as independently offset sky and terrain passes with broad alpha ramps between them, plus separate foreground silhouettes, mist and restrained dust. Slow bounded ambient offsets work with no input. A twelve-minute tint cycle suggests night, dawn, day and dusk without bright flashes. Pause freezes ambience. No raster asset editing or new external assets are required.

Share the settled/active solid painter, sort active cells far-to-near and upper-to-lower within each column like settled bricks, draw all glow first and filled solids last. Verify actual face pixels and captured fixtures on both sides of the cylinder, not just normals in isolation. First preview block edge is 15 logical pixels, followed by 10 and 9, all within portrait margins.

## Validation
Run rotation cycles across all pieces, orientations, directions, seams and fractional turns; check exact adjacent keyboard shifts and collision safety. Test the HUD and single-score interface. Render active solids, independent ambient times, and queue hierarchy. Run flutter analyze, flutter test, Worker tests, npm run build, openspec validate --all --strict. Inspect local visible Chromium, then commit, merge to main, and push without rewriting history.
