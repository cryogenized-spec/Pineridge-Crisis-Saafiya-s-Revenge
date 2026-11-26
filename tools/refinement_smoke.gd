extends SceneTree

const Actor = preload("res://scripts/actor.gd")
const CHAPTERS := ["upper_ridge", "house_one", "main"]

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	for chapter in CHAPTERS:
		var scene := load("res://scenes/%s.tscn" % chapter) as PackedScene
		var level := scene.instantiate()
		root.add_child(level)
		await process_frame
		var encounter: Node = level.get("encounters" if chapter == "main" else "encounter")
		var hud: CanvasLayer = encounter.ornate_hud
		hud.run_hud_smoke()
		for size in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = size
			await process_frame
			var bounds: Rect2 = hud.layer_root.get_viewport_rect()
			assert(hud.layer_root.get_rect() == bounds and hud.artwork.get_rect() == bounds)
			assert(hud.story_panel.get_rect().end.x < hud.minimap.get_rect().position.x)
		var original_rounds: int = encounter.rounds[0]
		var original_spares: int = encounter.spares[0]
		encounter.rounds[0] = 987654
		encounter.spares[0] = 123456
		encounter.reload_clock = 0.4
		hud._refresh_data()
		assert(hud.ammo_display.current_rounds == 987654)
		assert(hud.ammo_display.magazine_reserve == 123456 and hud.ammo_display.is_reloading)
		encounter.rounds[0] = original_rounds
		encounter.spares[0] = original_spares
		encounter.equip(1)
		assert(encounter.slot == 0)
		encounter.unlocked[1] = true
		encounter.equip(1)
		hud._refresh_data()
		assert(encounter.slot == 1)
		assert(hud.weapon_nameplate.texture.resource_path.ends_with("/cz75_p07.png"))
		level.free()
	var body := Actor.new()
	body.wardrobe_index = 5
	body.position = Vector2(92, 160)
	root.add_child(body)
	assert(body.npc_reactions != null)
	var resting_cells: Array[Rect2] = []
	for style in range(Actor.COLLAPSE_NAMES.size()):
		var heading := float(style) * PI / 4.0
		body.set_down_progress(-1.0)
		body.travel = heading
		body.animate(0.016, Vector2.from_angle(heading) * 8.0, heading, false, style % 2 == 0)
		var current_frame := body.npc_gait_frame()
		var current_atlas := body.npc_gait_atlas()
		body.start_collapse(style)
		assert(body.down_phase == 0.0 and body.collapse_style == style)
		assert(body.entry_frame == current_frame and body.entry_atlas == current_atlas)
		assert(is_equal_approx(body.collapse_facing, heading))
		body.set_down_progress(2.0)
		assert(body.down_phase == 1.0 and body.position == Vector2(92, 160))
		var resting_cell := body.reaction_cell(style, body.reaction_frame(body.down_phase))
		assert(not resting_cells.has(resting_cell))
		resting_cells.append(resting_cell)
	body.set_down_progress(-1.0)
	body.start_reaction(0.28)
	body.animate(0.13, Vector2.ZERO, 0.0)
	assert(body.reaction_phase > 0.0)
	body.start_collapse(2)
	assert(body.entry_reaction >= 0 and body.reaction_phase == -1.0)
	body.set_down_progress(-1.0)
	body.start_reaction(0.28)
	body.animate(0.3, Vector2.ZERO, 0.0)
	assert(body.reaction_phase == -1.0)
	body.free()
	print("Graphics refinement smoke: all chapter HUDs, live equipment, and six anchored collapse states.")
	quit()
