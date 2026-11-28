# Home & More — approved L1 shop artwork

**Status: APPROVED by the game director, 21 November 2026.**

The exact approved source image is `Home and More - Approved Shop Layout.png` (1670 × 942, RGBA) in the user's ChatGPT Library at `/Hero Shooter/Approved Artwork/`. A visually matching web-optimised export is saved beside it as `Home and More - Approved Shop Layout - Web Optimized.webp` (1670 × 942; approximately 333 KB).

Source image SHA-256: `b91caf887e01dface3df0c086f03b6455f7da6ce24826a2674ad34f02eed945d`.
WebP SHA-256: `cd6f4cda2cbb3cb9ad4f7bbbf6dd98f0bfefb9b1fff9d85d6e5f27e30f89d6d2`.

**Important:** These binary files are saved in the user's Library, **not yet copied into this Git repository**. This document records the approval without falsely implying the current playable shop uses this background. When transferring the art into the repository, the recommended runtime path is `public/play/maps/home-and-more-approved.webp`; the full-resolution PNG should be preserved as the canonical original.

## Approved visual composition

- **Perspective / visual treatment:** near-vertical overhead anime-inspired pixel painting with dense detailed merchandise, crisp shelving outlines, warm orange retail lights, dusty pink-grey floor tiles, and an orange/purple/red sunset-acacia brand mural.
- **Back / northern edge:** the full-width **Home & More** mural on the rear wall; low rear stock and box displays; a receiving/storage enclosure occupies the **upper-left** section, with cartons, a pallet jack, and safety-hatched flooring.
- **Centre:** a set of stocked parallel freestanding retail aisles; appliances, lamps, household bottles, tools, textiles, paint and boxed inventory are readable as different merchandise groups rather than clones. Yellow safety strips border the fixtures.
- **Front / southern edge:** broad centre entrance with glass doors, light spilling into the mall passage, a compact trolley collection at lower-left, two checkout terminals on one long counter at lower-right, and red queue barrier rails in front of the tills.
- **Left side:** a clearly marked **STAFF ONLY** passage from the retail floor, an enclosed computer/workstation room below it, and a staff kitchen/canteen with a small table and seating at the bottom-left.
- **Right side:** boxed goods and vertical display racks line the wall. Decorative plants, spotlights and sunset banners reinforce the visual identity.

## Implementation boundary

1. **Visual authority:** use this exact image to align retail topology, fixtures, room entrances, colours, lighting and art direction. The older provisional procedural drawing is no longer the visual target.
2. **Collision remains separate:** `public/play/maps/home-and-more.tmj` remains the current gameplay geometry. Do not swap its colliders, spawn, stairwell, room links or interaction triggers without spatially aligning them to the approved image.
3. **No image stretching:** maintain the approved 1670:942 aspect ratio. Choose a world-to-image coordinate transformation and explicitly map the walkable regions, aisle boundaries, entrance, staff door, tills and receiving access.
4. **Dynamic objects remain layers:** C, Chen family, workers, movable props, shutters, entrance interaction, visual damage and particle effects must not be baked into the static art.
5. **Room continuity:** the Chen upstairs offices/boardroom and stairwell are separate scenes. The left-side rooms in the approved L1 art must not silently replace the mezzanine unless a transition is deliberately redesigned.
6. **Source quality:** the original PNG is the archival master. Use the smaller WebP for a browser runtime after it has been placed into the repository; pre-decode/cache where practical.
7. **QA:** perform a browser walk-through across aisles, doors, checkout, stockroom, staircase and staff areas before declaring the artwork a playable map update.

This approval is about **what the shop looks like**, not an approval to erase current scripted interactions, mapped actors or scene transitions.
