# Design

## Context
The renderer already uses radial cuboids and shared active/settled shading. The model exposes a mutable board and frictional spin; no placement ages currently exist. See proposal.md for motivation.

## Goals / Non-Goals
Deliver a richer procedural garden and predictable fast snapping. Keep gameplay, scoring and services unchanged.

## Decisions
- Keep front-meridian faces square and size the cylinder to occupy over half the viewport width. Follow the mean landing row smoothly, with a gentle diagonal tilt. The destination takes priority over the rising piece and distant rows; the logical board stays 42 rows. Keep the ornate crown compact independently of the grid zoom.
- Reuse radial brick geometry for active and settled pieces, inspecting halo compositing rather than adding another lighting model.
- Track settled timestamps alongside occupancy and apply identical ring compaction. Ages drive bounded dirt, moss and rooted plants; active pieces stay clean.
- Isolate deterministic bounded ecology painting with shared world projection and front/rear passes. Use sparse periodic insect visibility, with at most three butterflies and rare third appearances.
- Allow a short flick coast followed by bounded exact snap through the existing swept collision path. Gentle release skips the coast; new drags cancel snapping.

## Risks / Trade-offs
- Close framing hides distant rows and the active piece → preserve the landing halo and all controls; inspect phone/desktop destination tracking.
- Decorative detail can obscure cells → cap foliage and insect density; draw active halos last.
- Row compaction can orphan attachments → derive roots from current occupancy and compact placement timestamps with rows.
- Aggressive snapping can tunnel → route every movement through swept collision detection and test obstacles.

## Migration Plan
No persisted schema changes. Rebuild and reload local preview; reverting drawing/model changes restores prior presentation.
