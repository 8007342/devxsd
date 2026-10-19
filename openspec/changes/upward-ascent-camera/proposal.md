# Proposal

## Why
A destination-only close view hides the spawning piece and loses the tension of its journey. The player needs an upward-looking view from the base that follows ascent while showing the relevant stack ahead.

## What Changes
- Use an upward-looking perspective camera with depth compression of distant rows.
- Begin at the base with the spawning piece, then follow its natural or accelerated ascent smoothly.
- Return immediately to the next spawn after locking or instant launch; keep controls responsive.
- Preserve large near-square local faces, the ornate crown, botanical detail and solid face orientation.

## Capabilities

### New Capabilities
None.

### Modified Capabilities
- `cylindrical-puzzle`: ascent-focused camera, perspective end planes, square local cells and correct visible brick surfaces.

## Impact
New camera policy module, Flame projection and visible faces, internal spawn serial, camera/render/playthrough tests and art guide. No scoring, controls or service changes.
