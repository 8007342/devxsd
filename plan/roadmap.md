# Roadmap

- [ ] Playtest the first playable on real phones; tune inertia, lock delay, speed curve and camera proportions from feedback.
- [ ] Refine botanical variety, pixel density and front/rear readability through subsequent agreed changes.

Implemented: 18×42 upward wraparound puzzle, 30-ring Timed and Unlimited modes,
centered pieces, inclined landing-focused camera, dimensional bricks and pot,
starting sprout, growing Monstera/pothos, night parallax, touch/keyboard input,
and top-ten Durable Object API with browser-local fallback.

Current change: `upward-ascent-camera` replaces destination-only framing with
an upward-looking perspective. Start near the base/spawn, follow the active
piece smoothly, compress distant upper rows, and return immediately on each new
spawn. Large near-square local cells and the ornate crown remain priorities.

The earlier `cylindrical-monstera-game` and `living-chandelier` changes have
synchronized main specs; do not reapply their deltas when archiving. Their
implemented features include prompt exact snapping, an ornamental crown,
age-aware rooted pothos, weathering and sparse garden insects.

Camera rig, upward projection and full-ascent tests are implemented. Phone and
desktop playthroughs verify every ascent frame, seven repeated hard-launch
spawns, spinning/tall stacks and reset. Actual spawn, mid-ascent and contact
images are captured under build/test/. The visible sibling preview uses the
new camera. The Flutter route uses local score fallback; the
Worker API was smoke-tested separately.

Validation: flutter analyze, all 55 Flutter tests, release web build and strict
OpenSpec validation pass. Visible Chromium was reloaded and inspected.

Close-up playtest: keep the upward angle and follow rig, move the eye much nearer
to enlarge local blocks, and permit sides/rim cropping. Camera tests now require
at least 35px active cell edges on phones (28px on the short desktop viewport).

Latest framing: activepiece sits across the physical bottom edge with a thin
crop, and board drawing extends behind controls. Uniform zoom preserves cell
proportions while the crown stays framed. Full-ascent tests cover the new crop.
