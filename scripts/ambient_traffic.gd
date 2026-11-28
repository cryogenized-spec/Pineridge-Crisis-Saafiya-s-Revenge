extends Node2D

const Art := preload("res://scripts/environment_art.gd")
const Damage := preload("res://scripts/vehicle_damage.gd")
const Actor := preload("res://scripts/actor.gd")
const DRIVER_GESTURE := preload("res://assets/characters/reactions/protest_09.png")
const HORN := preload("res://assets/audio/traffic_horn.wav")
const CAR_SIZE := Vector2(108, 43)
const LEVEL_WIDTH := 2320.0
const ALARM_RANGE := 500.0
const HONK_AFTER := 1.3
const EXIT_AFTER := HONK_AFTER + 6.0
const STALL_HITS := 5
const MODELS := ["sedan_silver", "hatchback_sage", "sedan_ochre", "utility_ivory"]
var avatar: Node2D
var top_lane := 451.0
var bottom_lane := 608.0
var cars: Array[Dictionary] = []
var elapsed := 0.0
var next_spawn := 4.0
var count := 0
var horn: AudioStreamPlayer2D

func configure(actor: Node2D, first_lane: float, second_lane: float) -> void:
	avatar = actor
	top_lane = first_lane
	bottom_lane = second_lane

func _ready() -> void:
	horn = AudioStreamPlayer2D.new()
	horn.stream = HORN
	horn.max_distance = 620
	horn.volume_db = -12
	add_child(horn)

func react_to_gunfire(at: Vector2) -> void:
	for car in cars:
		var center: Vector2 = car.pos + CAR_SIZE * 0.5
		if center.distance_to(at) < ALARM_RANGE:
			car.hurrying = true
	if at.y > top_lane - ALARM_RANGE and at.y < bottom_lane + ALARM_RANGE:
		next_spawn = maxf(next_spawn, elapsed + 6.0)

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= next_spawn:
		next_spawn = elapsed + 15.0 + float(count % 3) * 2.0
		if cars.size() < 2:
			spawn_car()
	for i in range(cars.size() - 1, -1, -1):
		if step_car(cars[i], delta):
			cars.remove_at(i)
	queue_redraw()

func step_car(car: Dictionary, delta: float) -> bool:
	var cruise: float = car.speed
	var desired := cruise * (1.9 if car.hurrying else 1.0)
	car.pace = move_toward(float(car.pace), desired, 240.0 * delta)
	var current := Rect2(car.pos, CAR_SIZE)
	var next := Rect2(current.position + Vector2(float(car.direction) * car.pace * delta, 0), CAR_SIZE)
	var blocked_by_player := is_instance_valid(avatar) and current.merge(next).grow(14.0).has_point(avatar.position)
	var driver: Actor = car.driver
	if int(car.damage.get("hits", 0)) >= STALL_HITS:
		if is_instance_valid(driver):
			update_driver(car, current, false, delta)
		return false
	if blocked_by_player and not car.hurrying:
		var was: float = car.waiting
		car.waiting += delta
		if was < HONK_AFTER and car.waiting >= HONK_AFTER:
			horn.position = current.get_center()
			horn.play()
		if was < EXIT_AFTER and car.waiting >= EXIT_AFTER:
			step_out(car, current)
	elif not blocked_by_player:
		car.waiting = 0.0
	if is_instance_valid(driver):
		update_driver(car, current, blocked_by_player and not car.hurrying, delta)
	elif not blocked_by_player:
		car.pos = next.position
	return car.pos.x < -170.0 or car.pos.x > LEVEL_WIDTH + 170.0

func door(rect: Rect2, direction: int) -> Vector2:
	return rect.get_center() + Vector2(direction * 11, direction * (rect.size.y * .5 + 4))

func step_out(car: Dictionary, rect: Rect2) -> void:
	var driver := Actor.new()
	driver.wardrobe_index = 9
	driver.action_atlas = DRIVER_GESTURE
	driver.z_index = 3
	driver.position = door(rect, car.direction)
	add_child(driver)
	car.driver = driver
	car.gesture = 0.0

func update_driver(car: Dictionary, rect: Rect2, waiting: bool, delta: float) -> void:
	var driver: Actor = car.driver
	var entry := door(rect, car.direction)
	var destination := entry + Vector2(4 * car.direction, 22 * car.direction) if waiting else entry
	var before := driver.position
	driver.position = before.move_toward(destination, delta * 76.0)
	var towards := (avatar.position - driver.position).angle() if waiting else (entry - before).angle()
	driver.animate(delta, driver.position - before, towards)
	driver.action_phase = -1.0
	if waiting and driver.position.is_equal_approx(destination):
		car.gesture += delta
		var loop := fmod(float(car.gesture), 2.4)
		if loop < 0.91:
			driver.action_phase = loop / 0.91
	elif not waiting and driver.position.is_equal_approx(entry):
		driver.queue_free()
		car.driver = null

func spawn_car() -> void:
	var heading := 1 if count % 2 == 0 else -1
	var y := top_lane if heading == 1 else bottom_lane
	var x := -126.0 if heading == 1 else LEVEL_WIDTH + 24.0
	var cruise := float(107 + (count % 4) * 11)
	cars.append({
		"pos":Vector2(x, y), "direction":heading,
		"speed":cruise, "pace":cruise, "hurrying":false, "waiting":0.0, "gesture":0.0,
		"driver":null, "damage":{},
		"model":"security" if count % 5 == 4 else MODELS[count % MODELS.size()]
	})
	count += 1

func blocked(p: Vector2, radius: float = 7.0) -> bool:
	for car in cars:
		if Rect2(Vector2(car.pos), CAR_SIZE).grow(radius).has_point(p):
			return true
	return false

func impact_vehicle(contact: Vector2, heading: Vector2, aim: Vector2) -> Vector2:
	for car in cars:
		var hit := Damage.impact(Rect2(car.pos, CAR_SIZE), car.model, car.direction,
			contact, heading, aim, car.damage)
		if hit.is_finite():
			queue_redraw()
			return hit
	return Damage.MISS

func _draw() -> void:
	for car in cars:
		var bounds := Rect2(car.pos, CAR_SIZE)
		Art.vehicle(self, bounds, car.model, car.direction)
		Damage.draw(self, bounds, car.model, car.direction, car.damage)
		if int(car.damage.get("hits", 0)) >= STALL_HITS:
			Damage.draw_vapor(self, bounds, car.direction, elapsed)
		var driver: Actor = car.driver
		if is_instance_valid(driver) and car.waiting >= EXIT_AFTER and not car.hurrying:
			draw_complaint(driver.position + Vector2(0, -27), floori(car.gesture / 2.4) % 3)
		elif not car.hurrying and car.waiting >= HONK_AFTER and car.waiting < HONK_AFTER + .75:
			var top := bounds.get_center() + Vector2(car.direction * 39, -24)
			draw_arc(top, 8, -.8, .8, 11, Color("#ead39d"), 1, true)
			draw_arc(top, 12, -.83, .83, 11, Color("#ead39d"), 1, true)

func draw_complaint(at: Vector2, icon: int) -> void:
	var border := Color("#643d49")
	var light := Color("#f1d9b4")
	draw_rect(Rect2(at - Vector2(16, 14), Vector2(32, 27)), light)
	draw_rect(Rect2(at - Vector2(16, 14), Vector2(32, 27)), border, false, 1.4)
	draw_colored_polygon(PackedVector2Array([at + Vector2(-4, 12), at + Vector2(3, 12), at + Vector2(-2, 19)]), light)
	match icon:
		0:
			draw_circle(at - Vector2(0, 3), 7.5, border, true, -1, true)
			draw_rect(Rect2(at + Vector2(-4, 2), Vector2(8, 5)), border)
			for side in [-1, 1]:
				draw_circle(at + Vector2(side * 3, -3), 1.7, light, true, -1, true)
			draw_line(at + Vector2(-2, 4), at + Vector2(2, 4), light, 1, true)
		1:
			for offset in [Vector2(-5, 0), Vector2(0, -3), Vector2(5, 0), Vector2(0, 3)]:
				draw_circle(at + offset, 5, border, true, -1, true)
			for offset in [Vector2(-10, -7), Vector2(9, -6), Vector2(7, 6)]:
				draw_line(at + offset - Vector2(2, 0), at + offset + Vector2(2, 0), border, 1.4, true)
				draw_line(at + offset - Vector2(0, 2), at + offset + Vector2(0, 2), border, 1.4, true)
		2:
			draw_circle(at, 8.5, Color("#ac5a53"), true, -1, true)
			draw_line(at + Vector2(-5, -4), at + Vector2(-1, -2), light, 1.4, true)
			draw_line(at + Vector2(1, -2), at + Vector2(5, -4), light, 1.4, true)
			draw_arc(at + Vector2(0, 6), 4, PI*1.13, TAU*.94, 9, light, 1.1, true)
