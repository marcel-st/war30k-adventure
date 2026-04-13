# Third-Party Graphics Licenses

This project includes third-party visual assets integrated into:

- `tps/assets/textures/environment/`
- `tps/assets/textures/skyboxes/`

Primary provenance metadata is maintained in:

- `tps/art/GRAPHICS_ASSET_MANIFEST.json`

## License summary

The curated runtime graphics assets currently in use are sourced from:

- ambientCG (CC0)
- Poly Haven (CC0)

These licenses allow free use in commercial and non-commercial projects.

## Source assets used

### 1) ambientCG - Metal Plates 006

- Source page: https://ambientcg.com/view?id=MetalPlates006
- Download source: https://ambientcg.com/get?file=MetalPlates006_1K-JPG.zip
- License: CC0 1.0 Universal

Used maps:
- albedo/color
- normal (OpenGL)
- roughness
- metallic

### 2) ambientCG - Concrete 048

- Source page: https://ambientcg.com/view?id=Concrete048
- Download source: https://ambientcg.com/get?file=Concrete048_1K-JPG.zip
- License: CC0 1.0 Universal

Used maps:
- albedo/color
- normal (OpenGL)
- roughness
- ambient occlusion

### 3) Poly Haven - Studio Small 09

- Source page: https://polyhaven.com/a/studio_small_09
- Download source: https://dl.polyhaven.org/file/ph-assets/HDRIs/extra/Tonemapped%20JPG/studio_small_09.jpg
- License: CC0

Used for VS01 sky/panorama background in the world environment.

## Integration notes

- Textures are wired into `StandardMaterial3D` in level/player/enemy scenes.
- Sky texture is used through `PanoramaSkyMaterial` + `Sky` in the VS01 environment.
- Source archives are retained under `tps/art/sources/graphics/` for auditability.
