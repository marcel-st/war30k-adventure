# Third-Party Audio Licenses

This project includes third-party audio assets integrated into:

- `tps/assets/audio/music/`
- `tps/assets/audio/sfx/`

Primary provenance metadata is maintained in:

- `tps/audio/ASSET_MANIFEST.json`

## License summary

The curated runtime assets currently in use are sourced from OpenGameArt and Kenney
packs that are published under CC0/public-domain style terms for game use.

Attribution is generally not required for CC0 content, but source/author data is retained
for transparency and future audits.

## Source packs used

### 1) Kenney - Sci-Fi Sounds

- Source page: https://opengameart.org/content/sci-fi-sounds
- Download source: `sci-fi_sounds.zip`
- License: CC0 1.0 Universal (pack metadata and included license text)
- Note: Kenney credit is appreciated but not required for CC0 usage.

Used for selected combat/UI/impact style sounds.

### 2) OpenGameArt - 50 CC0 Sci-Fi SFX

- Source page: https://opengameart.org/content/50-cc0-sci-fi-sfx
- Download source: `sci-fi-sfx.zip`
- License: CC0 (as listed on source page)

Used for selected ranged fire and impact cues.

### 3) OpenGameArt - Platformer Sounds (yd)

- Source page: https://opengameart.org/content/platformer-sounds-terminal-interaction-door-shots-bang-and-footsteps
- Download source: `yd-Sounds.zip`
- License: CC0 (as listed on source page)

Used for selected combat and interaction cues.

### 4) OpenGameArt - 100 CC0 SFX #2

- Source page: https://opengameart.org/content/100-cc0-sfx-2
- Download source: `sfx_100_v2.zip`
- License: CC0 (as listed on source page)

Used for selected ambient machine loops and utility SFX.

### 5) OpenGameArt - 30 CC0 SFX loops

- Source page: https://opengameart.org/content/30-cc0-sfx-loops
- Download source: `sfx_loops.zip`
- License: CC0 (as listed on source page)

Used for selected ambient warzone loops.

### 6) OpenGameArt - Metal footsteps on concrete

- Source page: https://opengameart.org/content/metal-footsteps-on-concrete
- Download source: `metal_steps_48k24b.7z`
- License: CC0 (as listed on source page)

Used for curated metal footstep variants.

### 7) OpenGameArt Music (hard-rock / rock-ballad theme)

#### A) Boss Battle #6 Metal
- Source page: https://opengameart.org/content/boss-battle-6-metal
- Download source: `Boss Battle 6 Metal V1.wav`
- License: CC0

#### B) Last Stand Lets Go
- Source page: https://opengameart.org/content/last-stand-lets-go
- Download source: `Peachtea-LastStandLetsGo_0.ogg`
- License: page indicates free use with or without attribution.
- Suggested credit text (optional): Last Stand Lets Go by Noah Cedeno ("Peachtea")

#### C) R&B Rock Fusion Song!
- Source page: https://opengameart.org/content/rb-rock-fusion-song-1
- Download source: `rb_rock_song_0.ogg`
- License: CC0

## Runtime integration notes

- Audio playback is routed through `tps/scripts/systems/SYS_AudioManager.gd`.
- Music/SFX/UI buses are created/managed at runtime.
- Headless mode intentionally disables runtime audio initialization to keep smoke checks stable.

## Auditability notes

- `tps/audio/sources/` contains original source downloads/extractions used during selection.
- `tps/assets/audio/` contains the curated subset used by runtime systems.
