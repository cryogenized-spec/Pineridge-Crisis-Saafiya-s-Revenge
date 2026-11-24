# Crowd artwork V10

The wardrobe system is reusable for any adult background character or fictional NPC. Appearance is independent of narrative role. Twelve presets combine plain tees, vests, windbreakers, denim and track jackets, jeans, shorts, casual shoes and flip-flops. Headwear includes bare heads, off-centre knit caps, peaked caps and decorative bands. Hair and body-build variations provide a mixed adult cast without relying on exaggerated features. Clothing remains opaque and trousers cover the waist.

The renderer uses layered shaded vector geometry in Godot, not the detailed VTK character mesh. Idle, walk and run poses are mathematical; the current scene uses idle/walk only. This is an initial art pass, pending visual review. The existing Saafiya asset pipeline is unchanged.

## V11 review

Rounded multilayer shading, garment folds, footwear highlights, knit-cap detail and hair highlights replace the initial flat wardrobe treatment. The F2 character workbench displays all twelve presets using the actual runtime actor code; 1/2/3 selects idle/walk/run, arrows rotate, T toggles automatic rotation, Z compares enlarged and game scale, Esc returns to the street. Automated smoke mode exercises the three states. No binary assets or image generator needed. These are still vector-based sprites, not textured 3D meshes.
