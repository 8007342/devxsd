# Botanical assets

`monstera-leaf.png` was generated with the built-in imagegen tool on 2026-10-17.
It is an isolated transparent leaf, rendered with nearest-neighbor filtering and
layered with procedural stems and pot geometry. No external asset requests are
needed at runtime.

Prompt:

> Use case: stylized-concept. Asset type: isolated botanical sprite for a mobile pixel-art game. Primary request: one single Monstera deliciosa leaf, mature heart-shaped deep green blade with distinctive split edges and internal fenestrations, short stem pointing straight downward. Pixel art with deliberately crisp stepped edges and chunky square pixel clusters, 3 restrained shades of jade green, pale mint veins and tiny warm golden highlights from a lamp above. Front three-quarter botanical view with slight asymmetry. Entire single leaf centered with generous transparent margins. Transparent background and transparent holes through the leaf. No pot, no scene, no shadow outside sprite, no text, no letters, no watermark, no border, no extra leaves. Cohesive warm garden aesthetic suitable for nearest-neighbor downsampling. Save the generated PNG for project use.

Art direction is in `plan/art-style.md`. Noto Sans and its OFL license are in
`assets/fonts/`; the Roboto family alias uses the same bundled font to satisfy
Flutter's engine default without a network request.

`night-landscape.png` was generated with the built-in imagegen tool on 2026-10-17
for the full-cylinder camera revision. It is bundled and used as the far landscape
layer. `GardenBackdrop` now composes it into softly blended sky and terrain
passes with independent time-driven offsets, additional foreground silhouettes
and a subdued light cycle. The original raster stays bundled and unchanged.

Prompt:

> Use case: stylized-concept. Asset type: landscape background for a mobile pixel-art botanical puzzle, used behind a transparent foreground cylindrical chandelier. Primary request: a tranquil wide night landscape with dark rolling hills and distant mountain silhouettes, sparse tiny warm lights far away, a luminous starry indigo and deep teal night sky with thin wispy clouds and a small crescent moon near upper right. Pixel art with crisp deliberately stepped clusters, restrained palette of midnight navy, deep teal, muted jade, soft cream starlight. Composition: wide panoramic scene, sky fills upper two thirds, horizon and layered hills lower third, unobtrusive dark central space to keep foreground gameplay legible. Warm, gentle garden atmosphere, no characters, no buildings in foreground, no plants covering center. No text, no letters, no logos, no watermark, no border. Subtle spatial depth between hills for parallax, no blurred photographic effects. Landscape aspect ratio.
