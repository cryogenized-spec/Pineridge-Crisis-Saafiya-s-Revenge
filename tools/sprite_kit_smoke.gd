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
	battle.unlocked[1] = true
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
	key.keycode = KEY_F8
	battle._unhandled_key_input(key)
	assert(hero.uses_alternate)
	key.keycode = KEY_F7
	battle._unhandled_key_input(key)
	assert(paused and is_instance_valid(battle.kit_review))
	battle.kit_review.show_mode(true)
	for index in range(Art.CATALOGUE.size()):
		battle.kit_review.choose(index)
		assert(battle.kit_review.held.entry().id == Art.CATALOGUE[index].id)
	battle.kit_review.close()
	assert(not paused)
	level.free()

	var house := HOUSE.instantiate()
	root.add_child(house)
	assert(house.player.uses_alternate)
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
	root.remove_meta(Actor.ALT_STATE)
	print("Sprite kit smoke: live slide, casing persistence, impact and pool, nine poses, alternate character and chapter isolation.")
	quit()
