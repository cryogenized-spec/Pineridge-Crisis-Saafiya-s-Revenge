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
	assert(battle.shots.size() == 1 and car.hurrying)
	level.traffic._process(0.25)
	assert(car.pace > car.speed)
	battle.update_character(pistol_carrier, 0.17)
	assert(battle.shots.size() == 2)
	battle.step_shots(0.40)
	assert(battle.player_hp == 3)
	battle.step_shots(0.06)
	assert(battle.player_hp == 2)
	var melee: Dictionary = battle.actors[2]
	melee.body.position = hero.position + Vector2(36, 0)
	melee.cooldown = 0.0
	melee.startle = 0.0
	battle.update_character(melee, 0.15)
	assert(melee.body.position.distance_to(hero.position) < 20.0)
	battle.update_character(melee, 0.01)
	assert(melee.windup > 0.0)
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
	var pistol: Button = battle.inventory_ui.boot_col.get_child(1)
	var pistol_name := pistol.text
	pistol.pressed.emit()
	pistol.pressed.emit()
	assert(battle.unlocked[1] and battle.inventory.equipment["Backup"] == pistol_name)
	assert(battle.rounds[1] == battle.KIT[1].size and battle.inventory_ui.contents.size() == 1)
	var magazine: Button = battle.inventory_ui.boot_col.get_child(1)
	magazine.pressed.emit()
	assert(battle.spares[1] == 1 and battle.inventory_ui.contents.is_empty())
	level._unhandled_key_input(loot_key)
	assert(not battle.inventory_open())
	battle.equip(1)
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
