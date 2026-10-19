# Design

## Context
The current renderer uses a large orthographic-like row scale and tracks only the landing row. It cannot show both distant destination and base at readable local size. See proposal.md for the player-visible change.

## Goals / Non-Goals
Follow the ascent through a depth-compressed upward scene while retaining fast controls and solid cells. Do not change rules, scoring or input mappings.

## Decisions
- Separate a deterministic camera rig from rendering. Follow the interpolated mean active row with short exponential smoothing; detect actual spawns with a monotonically increasing serial.
- Cut back to the base on each new spawn rather than sweeping rapidly down 42 rows. Normal ascent and small adjustments remain smooth; hard launch remains immediate.
- Use one pinhole projection for row centers, faces, rings and ecological attachments. Place the eye below the active piece and aim upward. Calibrate vertical camera scale globally for near-square nearby faces; do not stretch face vertices independently of row centers.
- Let distance compress upper rows naturally. Protect active/landing visibility and controls in phone and desktop playthroughs; avoid forcing every row to the same pixel size.
- Select visible underside faces for the upward camera while preserving existing radial outer/inner face orientation and shared Lambert shading.

## Risks / Trade-offs
- Strong depth can make distant targets too small → inspect landing halos and contact-stage framing with actual playthroughs.
- New spawn cuts may be noticeable → use the lock/spawn transition and prioritize immediate next-piece visibility.
- Perspective can bring geometry behind the camera → keep the relevant near scene outside the near plane and omit irrelevant clipped geometry safely.
- Camera-follow artifacts may be missed in stills → test complete natural and accelerated ascents, spin, hard drop, tall stacks and reset.

## Migration Plan
No persisted changes. Rebuild and reload the sibling preview. Revert the projection and rig if the playtest fails.

## Close-camera playtest refinement
Move the eye nearer in depth and reduce its trailing distance together, retaining
the upward pitch and shared projection. This increases nearby cell size without
zooming the distant landing halo out of view. Side cropping is intentional; the
active piece and target remain usable between the HUD and controls.

Bottom-edge framing: fit a modest additional uniform zoom between the crown
and the active silhouette, anchoring the latter just past the physical bottom
edge. Keep its full width visible; clip only a thin bottom strip. Extend the
world drawing behind the translucent controls and preserve crown clearance.
