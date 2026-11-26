extends Node2D
## Registered overhead equipment, holding poses, and cosmetic shot cycles.
const Actor = preload("res://scripts/actor.gd")
const Art = preload("res://scripts/sprite_kit_art.gd")
const ARMS := preload("res://assets/characters/sprite_kit/saafiya_arms_poses.png")
const MUZZLE := preload("res://assets/fx/weapon_art/muzzle.png")
const SMOKE := preload("res://assets/fx/weapon_art/smoke.png")
const DRAW_FLASH := 0.059
const DRAW_SMOKE := 0.27

var wearer: Actor
var catalog_index := 0
var draw_arms := true
var shot_age := -1.0
var fresh_shot := false
var shot_heading := 0.0
var flash_origin := Vector2.ZERO
var flash_variant := 0
var service_age := -1.0
var service_duration := 1.0

func configure(actor: Actor, player_arms: bool = true) -> void:
	wearer = actor
	draw_arms = player_arms
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func choose_slot(index: int) -> void:
	choose_catalog(Art.LIVE_SLOTS[clampi(index, 0, Art.LIVE_SLOTS.size() - 1)])

func choose_catalog(index: int) -> void:
	catalog_index = posmod(index, Art.CATALOGUE.size())
	shot_age = -1.0
	fresh_shot = false
	service_age = -1.0
	queue_redraw()

func entry() -> Dictionary:
	return Art.CATALOGUE[catalog_index]

func begin_service(duration: float) -> void:
	if entry().action == "blade":
		return
	service_duration = maxf(0.1, duration)
	service_age = 0.0

func service_progress() -> float:
	return 0.0 if service_age < 0.0 else clampf(service_age / service_duration, 0.0, 1.0)

func cycle_shift() -> float:
	if shot_age < 0.0:
		return 0.0
	match entry().action:
		"slide":
			return -1.65 * (1.0 - smoothstep(0.027, 0.12, shot_age))
		"bolt":
			return -1.29 * (1.0 - smoothstep(0.024, 0.105, shot_age))
		"pump":
			return -3.15 * smoothstep(0.064, 0.18, shot_age) * (1.0 - smoothstep(0.20, 0.34, shot_age))
		_:
			return 0.0

func pose_frame() -> int:
	if service_age >= 0.0:
		var progress := service_progress()
		if progress > 0.12 and progress < 0.55:
			return 2
		if progress >= 0.55 and progress < 0.91:
			return 3
		return 0
	if shot_age >= 0.0 and (shot_age < 0.07 or absf(cycle_shift()) > 1.15):
		return 1
	return 0

func grip_offset(gear: Dictionary, pose: int) -> Vector2:
	if not draw_arms:
		return Vector2(2.9, 5.7 if pose == 0 else 4.3)
	var point: Vector2 = gear.grips[pose]
	if wearer.crouched:
		point.y *= 0.82
	return point

func prop_scale() -> float:
	return 1.0 if draw_arms else 0.86

func display_heading() -> float:
	if shot_age >= 0.0 and shot_age < 0.095:
		return shot_heading
	return wearer.facing

func burst(direction: Vector2) -> Dictionary:
	# Caller has already accepted the gameplay action. All offsets are visual.
	if not is_instance_valid(wearer):
		return {}
	var gear := entry()
	shot_heading = direction.angle() if not direction.is_zero_approx() else wearer.facing
	shot_age = 0.0
	fresh_shot = true
	flash_variant = (flash_variant + 1) % 3
	var forward := Vector2.from_angle(shot_heading)
	global_position = wearer.global_position
	var grip := grip_offset(gear, pose_frame()).rotated(shot_heading - PI / 2.0)
	flash_origin = to_global(grip + forward * float(gear.tip) * prop_scale())
	queue_redraw()
	if str(gear.case).is_empty():
		return {}
	return {"point": to_global(grip + forward * float(gear.port) * prop_scale()),
		"outward": Vector2(-forward.y, forward.x), "look": gear.case,
		"delay": 0.16 if gear.action == "pump" else 0.0}

func _process(delta: float) -> void:
	if not is_instance_valid(wearer):
		return
	global_position = wearer.global_position
	if fresh_shot:
		fresh_shot = false
	elif shot_age >= 0.0:
		shot_age += delta
		if shot_age > 0.36:
			shot_age = -1.0
	if service_age >= 0.0:
		service_age += delta
		if service_age >= service_duration:
			service_age = -1.0
	if draw_arms:
		wearer.set_gear_pose(catalog_index, pose_frame(), display_heading())
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(wearer):
		return
	var gear := entry()
	var pose := pose_frame()
	var aim := display_heading()
	if draw_arms and not wearer.uses_alternate:
		var body_size := Vector2(Actor.DISPLAY_SIZE, Actor.DISPLAY_SIZE * (0.82 if wearer.crouched else 1.0))
		var cell := Rect2(pose * Actor.TILE, catalog_index * Actor.TILE, Actor.TILE, Actor.TILE)
		draw_set_transform(Vector2.ZERO, aim - PI / 2.0)
		draw_texture_rect_region(ARMS, Rect2(-body_size * 0.5, body_size), cell)
	var grip := grip_offset(gear, pose).rotated(aim - PI / 2.0)
	draw_set_transform(grip, aim)
	var width := float(gear.width) * prop_scale()
	var size := Vector2(width, width * Art.PROP_CELL.y / Art.PROP_CELL.x)
	var offset := Vector2.ZERO
	if service_age >= 0.0 and gear.action in ["slide", "bolt"]:
		var phase := service_progress()
		var drop := smoothstep(0.16, 0.38, phase) * (1.0 - smoothstep(0.53, 0.82, phase))
		offset = Vector2(-1.8, 3.2) * drop * prop_scale()
	_draw_piece(gear.art, 2, size, offset)
	_draw_piece(gear.art, 0, size, Vector2.ZERO)
	_draw_piece(gear.art, 1, size, Vector2(cycle_shift() * prop_scale(), 0.0))
	draw_set_transform(Vector2.ZERO)
	if gear.action != "blade" and shot_age >= 0.0:
		_draw_burst(gear)

func _draw_piece(texture: Texture2D, column: int, size: Vector2, offset: Vector2) -> void:
	var source := Rect2(Vector2(column * Art.PROP_CELL.x, 0), Art.PROP_CELL)
	draw_texture_rect_region(texture, Rect2(offset - size * 0.5, size), source)

func _draw_burst(gear: Dictionary) -> void:
	var position_at_shot := to_local(flash_origin)
	draw_set_transform(position_at_shot, shot_heading)
	if shot_age < DRAW_FLASH:
		var f := 1.0 - shot_age / DRAW_FLASH
		var reach := 15.0 if gear.action in ["bolt", "pump"] else 10.5
		var size := Vector2(reach, reach * 0.59) * prop_scale()
		var source := Rect2(flash_variant * 128, 0, 128, 80)
		draw_circle(Vector2(1.0, 0.0), 4.9, Color(1.0, 0.56, 0.23, f * 0.18), true, -1.0, true)
		draw_texture_rect_region(MUZZLE, Rect2(Vector2(-size.x * 0.12, -size.y * 0.5), size),
			source, Color(1, 1, 1, f))
	if shot_age > 0.022 and shot_age < DRAW_SMOKE:
		var progress := shot_age / DRAW_SMOKE
		var size := Vector2.ONE * (5.0 + progress * 9.0)
		var drift := Vector2(3.0 + progress * 8.5, -progress * 2.8)
		draw_texture_rect(SMOKE, Rect2(drift - size * 0.5, size), false, Color(1, 1, 1, 0.83 * (1.0 - progress)))
	draw_set_transform(Vector2.ZERO)
