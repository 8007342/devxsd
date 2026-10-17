# Roadmap

- [ ] Playtest the first playable on real phones; tune inertia, lock delay, speed curve and camera proportions from feedback.
- [ ] Refine botanical variety, pixel density and front/rear readability through subsequent agreed changes.

Implemented: 18×42 upward wraparound puzzle, 30-ring Timed and Unlimited modes,
centered pieces, inclined full-cylinder camera, dimensional bricks and pot,
starting sprout, growing Monstera/pothos, night parallax, touch/keyboard input,
and top-ten Durable Object API with browser-local fallback.

Current change: `cylindrical-monstera-game`. Its main specs are synchronized;
review completed changes before archiving without applying those deltas twice.
Local sibling Flutter preview and visible Chromium remain running. The Flutter
route uses local score fallback; the Worker API has been smoke-tested separately.
