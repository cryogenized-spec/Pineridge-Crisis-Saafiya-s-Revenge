extends SceneTree

const Actor = preload("res://scripts/actor.gd")
const Art = preload("res://scripts/sprite_kit_art.gd")
const ChapterState = preload("res://scripts/chapter_state.gd")
const UPPER := preload("res://scenes/upper_ridge.tscn")
const HOUSE := preload("res://scenes/house_one.tscn")

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var level := UPPER.instantiate()
	root.add_child(level)
	var battle: Node = level.encounter
	battle.set_physics_process(false)
	var hero: Actor = level.player
	assert(hero.has_hero_atlases())
	var visual: Node2D = battle.held_visual
	var ground: Node2D = battle.stage_decals
	var records: Array[Dictionary] = ground.records
	var first_rounds: int = battle.rounds[0]
	battle.fire_player()
	assert(battle.rounds[0] == first_rounds - 1)
	assert(visual.pose_frame() == 1 and visual.cycle_shift() < -1.0)
	var case_records := records.filter(func(item: Dictionary) -> bool: return item.kind == "case")
	assert(case_records.size() == 1 and case_records[0].look == "short")
	var original_case: Dictionary = case_records[0].duplicate()
	var muzzle_position: Vector2 = visual.flash_origin
	hero.position += Vector2(240, 36)
	visual._process(0.02)
	assert(visual.flash_origin == muzzle_position)
	assert(visual.cycle_shift() < -1.0)
	visual._process(0.20)
	assert(is_zero_approx(visual.cycle_shift()) and visual.pose_frame() == 0)
	battle.fire_player()
	assert(battle.rounds[0] == first_rounds - 1)
	assert(records.filter(func(item: Dictionary) -> bool: return item.kind == "case").size() == 1)

	battle.equip(1)
	assert(battle.slot == 0)
	var pistol_carrier: Dictionary = battle.actors[3]
	var pistol_body: Actor = pistol_carrier.body
	hero.position = pistol_body.position + Vector2(-300, 0)
	var car: Dictionary
	level.traffic.spawn_car()
	car = level.traffic.cars[0]
	car.pos = pistol_body.position + Vector2(-50, -65)
	pistol_carrier.cooldown = 0.0
	pistol_carrier.startle = 0.0
	var firing_position := pistol_body.position
	battle.update_character(pistol_carrier, 0.01)
	assert(pistol_body.position == firing_position and pistol_carrier.windup > 0.0)
	battle.update_character(pistol_carrier, 0.30)
	assert(battle.shots.is_empty() and car.hurrying and battle.player_hp == 2)
	level.traffic._process(0.25)
	assert(car.pace > car.speed)
	battle.update_character(pistol_carrier, 0.17)
	assert(battle.shots.is_empty() and battle.player_hp == 2)
	assert(battle.actors[1].fleeing and battle.actors[1].escape_x > battle.actors[1].body.position.x)
	car.pos = hero.position + Vector2(-20, -21)
	car.hurrying = false
	level.traffic.step_car(car, 1.4)
	assert(level.traffic.horn.playing and car.driver == null)
	level.traffic.step_car(car, 6.1)
	assert(is_instance_valid(car.driver))
	level.traffic.step_car(car, 0.51)
	assert(car.driver.action_atlas != null and car.driver.action_phase >= 0.0)
	for hit in range(level.traffic.STALL_HITS):
		var at: Vector2 = car.pos + Vector2(21, 22)
		assert(level.traffic.impact_vehicle(at, Vector2.RIGHT, at).is_finite())
	var stalled_at: Vector2 = car.pos
	hero.position += Vector2(0, 48)
	level.traffic.step_car(car, 1.0)
	assert(car.pos == stalled_at)
	level.traffic.cars.clear()
	hero.position = firing_position + Vector2(-300, 0)
	var melee: Dictionary = battle.actors[2]
	melee.body.position = hero.position + Vector2(36, 0)
	melee.cooldown = 0.0
	melee.startle = 0.0
	battle.update_character(melee, 0.15)
	assert(melee.body.position.distance_to(hero.position) < 20.0)
	battle.update_character(melee, 0.01)
	assert(melee.windup > 0.0)
	assert(melee.body.action_atlas != null and melee.body.action_phase >= 0.0)
	hero.position += Vector2(0, 45)
	battle.player_invincible = 0.0
	battle.update_character(melee, 0.39)
	assert(battle.player_hp == 2 and melee.cooldown > 0.0)
	hero.position = firing_position + Vector2(16, 0)
	battle.hit_enemy(pistol_carrier, int(pistol_carrier.hp), Vector2.RIGHT)
	var loot_key := InputEventKey.new()
	loot_key.keycode = KEY_E
	loot_key.pressed = true
	level._unhandled_key_input(loot_key)
	assert(battle.inventory_open() and battle.inventory_ui.contents.size() == 2)
	var pistol_name: String = battle.inventory_ui.contents[0].label
	battle.inventory_ui.take_entry(0)
	assert(battle.unlocked[1] and battle.inventory.equipment["Backup"] == pistol_name)
	assert(battle.rounds[1] == battle.KIT[1].size and battle.inventory_ui.contents.size() == 1)
	level._unhandled_key_input(loot_key)
	assert(not battle.inventory_open())
	assert(battle.spares[1] == 1 and "pistol_mag" in battle.inventory.bag)
	assert(battle.inventory.footprint("pistol_mag") == Vector2i.ONE)
	battle.resolve_player_action(Vector2(190, 478), Vector2.RIGHT)
	assert(level.world.vehicle_marks.has(0))
	verify_vehicle_glass(battle, level.world)
	assert(battle.inventory.quick_slots == [0, 1, -1, -1])
	battle.toggle_inventory()
	var ui: CanvasLayer = battle.inventory_ui
	drag_between(ui, ui.SLOTS["Backup"].get_center(), ui.QUICK[3].get_center())
	assert(battle.inventory.quick_slots == [0, -1, -1, 1])
	drag_between(ui, ui.BAG + Vector2(24, 24), ui.BAG + Vector2(168, 120))
	assert(battle.inventory.bag_cells[0] == Vector2i(3, 2))
	drag_between(ui, ui.BAG + Vector2(168, 120), ui.BAG + Vector2(72, 24))
	assert(battle.inventory.bag_cells[0] == Vector2i(3, 2))
	drag_between(ui, ui.SLOTS["Head"].get_center(), ui.BAG + Vector2(120, 120))
	assert(battle.inventory.item_for_slot("Head").is_empty() and "glasses" in battle.inventory.bag)
	drag_between(ui, ui.BAG + Vector2(120, 120), ui.SLOTS["Head"].get_center())
	assert(battle.inventory.item_for_slot("Head") == "glasses")
	battle.toggle_inventory()
	battle.equip_quick(3)
	hero.animate(.5, Vector2.ZERO, hero.facing)
	battle.cooldown = 0.0
	battle.fire_player()
	assert(visual.entry().id == "cz75_p07" and visual.cycle_shift() < -1.0)
	battle.refill()
	assert(battle.reload_clock > 0.0 and visual.service_age == 0.0)
	visual._process(float(battle.reload_clock) * 0.35)
	assert(visual.pose_frame() == 2)
	var spent: int = battle.rounds[1]
	battle.fire_player()
	assert(battle.rounds[1] == spent)
	battle.street_suspended = true
	battle._physics_process(battle.reload_clock + 0.01)
	battle.street_suspended = false
	assert(battle.rounds[1] == int(battle.KIT[1].size) and battle.spares[1] == 0)
	assert("pistol_mag" not in battle.inventory.bag)

	var target: Dictionary = battle.actors[0]
	if target.down:
		target = battle.actors[1]
	if target.down:
		target = battle.actors[2]
	assert(not target.down)
	var prior := records.size()
	battle.hit_enemy(target, int(target.hp), Vector2.RIGHT)
	assert(target.down and records.size() == prior + 7)
	assert(not ground.growing.is_empty() and not ground.splashes.is_empty())
	var last: Dictionary = records[-1]
	assert(last.kind == "pool")
	var pool_point: Vector2 = last.point
	var emitter := {"point": hero.global_position, "outward": Vector2.DOWN, "look": "short"}
	for index in range(120):
		ground.eject(emitter)
	ground._process(5.0)
	assert(ground.growing.is_empty() and ground.flying.is_empty() and ground.splashes.is_empty())
	assert(records.has(original_case) and last.point == pool_point and records.has(last))

	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_F7
	battle._unhandled_key_input(key)
	assert(paused and is_instance_valid(battle.kit_review))
	battle.kit_review.show_mode(true)
	for index in range(Art.CATALOGUE.size()):
		battle.kit_review.choose(index)
		assert(battle.kit_review.held.entry().id == Art.CATALOGUE[index].id)
	battle.kit_review.close()
	assert(not paused)
	ChapterState.store(self, battle)
	battle.player_hp = 1
	battle.player_invincible = 0.0
	battle.hurt_player(Vector2.DOWN)
	assert(battle.player_hp == 0 and not visual.visible and hero.defeat_elapsed == 0.0)
	battle._physics_process(0.33)
	assert(hero.defeat_elapsed > 0.0 and hero.defeat_elapsed < Actor.DEFEAT_DURATION)
	battle._physics_process(1.0)
	assert(hero.defeat_elapsed == Actor.DEFEAT_DURATION)
	battle._physics_process(0.33)
	assert(hero.defeat_elapsed == Actor.DEFEAT_DURATION)
	level.free()

	var house := HOUSE.instantiate()
	root.add_child(house)
	assert(house.player.has_hero_atlases())
	assert(house.encounter.unlocked[1] and house.encounter.inventory.equipment["Backup"] == pistol_name)
	assert(house.encounter.inventory.quick_slots == [0, -1, -1, 1])
	assert(house.encounter.inventory.bag_cells[0] == Vector2i(3, 2))
	assert(house.encounter.stage_decals.records.is_empty())
	house.free()
	var revisit := UPPER.instantiate()
	root.add_child(revisit)
	var revisited_decals: Node2D = revisit.encounter.stage_decals
	assert(revisited_decals.records.has(original_case) and revisited_decals.records.has(last))
	assert(revisited_decals.flying.is_empty() and revisited_decals.growing.is_empty())
	ChapterState.clear_stage_decals(self, "upper_ridge")
	assert(ChapterState.stage_decals(self, "upper_ridge").is_empty())
	revisit.free()
	ChapterState.reset(self)
	print("Sprite kit smoke: live slide, decals, nine poses, default Saafiya, collapse, looting, ranged volleys and traffic reaction.")
	quit()

func drag_between(ui: CanvasLayer, from: Vector2, to: Vector2) -> void:
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = from
	ui.point_input(press)
	var move := InputEventMouseMotion.new()
	move.position = to
	ui.point_input(move)
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = to
	ui.point_input(release)

func verify_vehicle_glass(battle: Node, world: Node) -> void:
	var art := preload("res://scripts/environment_art.gd")
	var damage := preload("res://scripts/vehicle_damage.gd")
	var footprint: Rect2 = world.PLAYER_CAR
	var bounds := art.vehicle_bounds(footprint)
	var model := "saafiya_car"
	for direction in [1, -1]:
		var glass := PackedVector2Array(damage.panel(model, direction).glass)
		var center := Vector2.ZERO
		for point in glass:
			center += point / glass.size()
		var aim := bounds.position + bounds.size * center
		var result := {}
		assert(damage.impact(footprint, model, direction, footprint.get_center(), Vector2.RIGHT, aim, result) == aim)
		assert(result.glass_hits == 1 and result.marks[0].glass)
		if direction > 0:
			var pos := Vector2(aim.x, footprint.end.y + 35)
			var heading := (aim - pos).normalized()
			var actor_marks: int = battle.stage_decals.records.size()
			for i in range(damage.SHATTER_HITS):
				battle.resolve_player_action(pos, heading, aim)
			assert(world.vehicle_marks[0].glass_hits == damage.SHATTER_HITS)
			assert(world.vehicle_marks[0].hits == damage.SHATTER_HITS + 1)
			assert(battle.motes[-1].point == aim)
			assert(battle.stage_decals.records.size() == actor_marks)
		for i in range(2):
			var side := PackedVector2Array(damage.panel(model, direction).sides[i])
			var side_center := Vector2.ZERO
			for point in side:
				side_center += point / side.size()
			var point_on_side := bounds.position + bounds.size * side_center
			for impact_index in range(damage.SHATTER_HITS):
				assert(damage.impact(footprint, model, direction, footprint.get_center(),
					Vector2.RIGHT, point_on_side, result) == point_on_side)
			assert(result.pane_hits[i + 1] == damage.SHATTER_HITS)
		assert(result.glass_hits == 1)
