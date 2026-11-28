extends Node2D
## A fixed story entrance, staged entirely within the carriageway.
const Art := preload("res://scripts/environment_art.gd")
const Damage := preload("res://scripts/vehicle_damage.gd")
const DOOR := preload("res://assets/environment/vehicles/taxi_west_door.png")
const HORN := preload("res://assets/audio/traffic_horn.wav")
const SIZE := Vector2(118, 46)
const LANE := 541.0
const APPEAR := Vector2(1940, LANE)
const BRAKE := Vector2(1235, LANE)
const STOP := Vector2(1100, LANE + 19.0)
const GATE := Rect2(1175, 455, 550, 179)
const APPROACH_TIME := 1.80
const BRAKE_TIME := .69
const OPEN_TIME := .52
const SKEW := -.24
const REQUIRED_TAKEDOWNS := 3
enum Phase { WAIT, ARRIVAL, BRAKING, DOOR_OPEN, DONE }

var phase := Phase.WAIT
var encounter: Node
var avatar: Node2D
var car_position := APPEAR
var body_angle := 0.0
var timer := 0.0
var door_frame := 0
var damage: Dictionary = {}
var horn: AudioStreamPlayer2D

func configure(battle: Node, player: Node2D) -> void:
	encounter = battle
	avatar = player

func _ready() -> void:
	horn = AudioStreamPlayer2D.new()
	horn.stream = HORN
	horn.max_distance = 780.0
	horn.volume_db = -10.0
	add_child(horn)

func step(delta: float) -> void:
	if phase == Phase.WAIT:
		if encounter.looter_takedowns >= REQUIRED_TAKEDOWNS and encounter.player_hp > 0 and GATE.has_point(avatar.position):
			phase = Phase.ARRIVAL
			horn.position = APPEAR
			horn.play()
		return
	if phase == Phase.DONE:
		return
	timer += delta
	match phase:
		Phase.ARRIVAL:
			car_position = APPEAR.lerp(BRAKE, clampf(timer / APPROACH_TIME, 0, 1))
			clear_lane(delta)
			if timer >= APPROACH_TIME:
				phase = Phase.BRAKING
				timer = 0.0
		Phase.BRAKING:
			var progress := clampf(timer / BRAKE_TIME, 0.0, 1.0)
			car_position = BRAKE.lerp(STOP, 1.0 - (1.0 - progress) * (1.0 - progress))
			body_angle = smoothstep(0.0, 0.9, progress) * SKEW
			clear_lane(delta)
			if timer >= BRAKE_TIME:
				phase = Phase.DOOR_OPEN
				timer = 0.0
		Phase.DOOR_OPEN:
			door_frame = clampi(ceili(smoothstep(0.0, OPEN_TIME, timer) * 4), 0, 4)
			if timer >= OPEN_TIME:
				spawn_passengers()
				phase = Phase.DONE
	queue_redraw()

func clear_lane(delta: float) -> void:
	# Reserved road space gives the arrival a reproducible near miss while preserving
	# normal movement before and after the animation.
	var offset: Vector2 = avatar.position - car_position
	if absf(offset.x) < 94.0 and absf(offset.y) < 30.0:
		var side := -1.0 if offset.y < 0.0 else 1.0
		avatar.position.y = move_toward(avatar.position.y, car_position.y + side * 34.0, 310.0 * delta)

func body_bounds() -> Rect2:
	return Rect2(car_position - SIZE / 2.0, SIZE)

func blocked(point: Vector2, radius: float) -> bool:
	return phase >= Phase.DOOR_OPEN and body_bounds().grow(radius).has_point(point)

func impact_vehicle(contact: Vector2, heading: Vector2, aim: Vector2) -> Vector2:
	if phase < Phase.DOOR_OPEN:
		return Damage.MISS
	var local_contact := car_position + (contact - car_position).rotated(-body_angle)
	var local_aim := car_position + (aim - car_position).rotated(-body_angle) if aim.is_finite() else Damage.MISS
	var hit := Damage.impact(body_bounds(), "taxi", -1, local_contact, heading.rotated(-body_angle), local_aim, damage)
	if hit.is_finite():
		queue_redraw()
		return car_position + (hit - car_position).rotated(body_angle)
	return Damage.MISS

func spawn_passengers() -> void:
	encounter.spawn_character(STOP + Vector2(34, 43), "machete", 12, true)
	encounter.spawn_character(STOP + Vector2(66, 47), "machete", 13, true)
	encounter.spawn_character(STOP + Vector2(-18, 53), "rifle", 14, true)

func _draw() -> void:
	if phase == Phase.WAIT:
		return
	if phase >= Phase.BRAKING:
		var back := Vector2(maxf(STOP.x, car_position.x), car_position.y)
		for lateral in [-14.0, 14.0]:
			draw_line(BRAKE + Vector2(32, lateral), back + Vector2(28, lateral),
				Color("#27212ab5"), 3.0, true)
	var bounds := Art.vehicle_bounds(Rect2(-SIZE / 2.0, SIZE))
	draw_set_transform(car_position, body_angle)
	draw_texture_rect_region(DOOR, bounds, Rect2(288 * door_frame, 0, 288, 136))
	Damage.draw(self, Rect2(-SIZE / 2.0, SIZE), "taxi", -1, damage)
	draw_set_transform(Vector2.ZERO)
