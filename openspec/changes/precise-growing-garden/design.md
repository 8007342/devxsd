## Context
The existing grid anchor is derived from cylinder angle minus the current shape center. Snapping to integer angles and direction-dependent half rounding causes adjacent-column changes. Rotation controls also have their own gesture recognizers outside the board listener. Timed mode currently stops the run at thirty.

## Decisions
Use direction-independent nearest rounding and snap to the currently selected anchor plus shape-center offset. Add a discrete one-column shift that cancels coast/snap and checks the swept adjacent cell. A gentle release preserves the halo selection; only deliberate fast flicks coast.

One pointer listener covers the game and rotation icons. Vertical intent locks a send gesture before release; taps require small maximum travel. Rotation visuals expose semantics actions but no competing pointer recognizer. Flash the corresponding icon for both touch and keyboard rotations. Center hold remains a distinct input and never becomes an accidental side tap.

Record a nullable first-thirty time once in either starting mode. End only at blocked spawning. Both entry paths can submit a single run into time ranking (if qualified) and total-ring ranking, atomically in the shared Worker. Every row displays milestone time (or dash), total rings and plant height from that run. Preserve old entries by treating legacy timed seconds as the milestone. Use a new local-cache version for the changed survival ranking semantics; preserve legacy data through read migration.

Keep original projection and apply 1.10 uniform scene zoom about its center, including all board-bound art, while leaving HUD and controls fixed. Allow a little boundary spill. Increase next-piece block size and space previews apart. Seed botanical variation per run. Persist leaf birth ring, opening age and multi-clear vigor in model growth events; derive repeatable leaf shape/scale from run seed. The stem continues extending and produces new nodes beyond the old visual growth cap, with older segments compressing into a mature canopy.

## Validation
Exhaustive shape/rotation/direction/seam keyboard and release tests; collision checks; widget tests for diagonal sends, icon-area swipes and tap feedback; milestone/reset/continued-growth tests; shared and local paired record tests; rendered young/open/multi-clear/late foliage fixtures. Run all required Flutter checks, Worker tests, release build, strict specs, and refresh visible Chromium in the local container.
