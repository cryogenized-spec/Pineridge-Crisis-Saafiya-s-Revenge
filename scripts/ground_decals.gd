extends Node2D
## World-fixed decals. The chapter owns the settled descriptors for the run.
const IMPACT := preload("res://assets/fx/weapon_art/impact.png")
const POOL := preload("res://assets/fx/weapon_art/pool.png")
const CASINGS := {
	"short": preload("res://assets/fx/weapon_art/casing_short.png"),
	"long": preload("res://assets/fx/weapon_art/casing_long.png"),
	"shell": preload("res://assets/fx/weapon_art/casing_shell.png"),
}
# Half the old on-screen dimensions, preserving the sprite aspect ratio.
const CASING_SIZES := {"short": Vector2(2.3, 1.15), "long": Vector2(2.7, 1.35), "shell": Vector2(2.95, 1.475)}
const CASE_HOPS := [Vector2(0.0, 0.56), Vector2(0.56, 0.76), Vector2(0.76, 0.89)]
const CASE_HEIGHTS := [5.2, 2.1, 0.75]
const STAIN_CELL := 128
const SPLASH_LIFETIME := 0.21
const POOL_GROWTH := 2.7

var records: Array[Dictionary] = []
var growing := {}
var flying := {}
var splashes: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()

func configure(storage: Array[Dictionary], chapter: String) -> void:
	records = storage
	rng.seed = hash(chapter) + records.size() * 11951
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	set_process(false)

func impact(world_point: Vector2, heading: Vector2, strength: float) -> void:
	var point := to_local(world_point)
	var aim := heading.angle() if not heading.is_zero_approx() else rng.randf_range(0, TAU)
	records.append({"kind": "impact", "point": point, "angle": aim, "style": rng.randi_range(0, 3),
		"size": Vector2(15, 10) * strength, "strength": 0.98})
	for i in range(5):
		var spread := aim + rng.randf_range(-1.28, 1.28)
		var offset := Vector2.from_angle(spread) * rng.randf_range(3.0, 12.5) * strength
		var drop := rng.randf_range(1.3, 3.6) * strength
		records.append({"kind": "impact", "point": point + offset, "angle": spread, "style": i % 4,
			"size": Vector2(drop * 1.35, drop), "strength": rng.randf_range(0.63, 0.92)})
		splashes.append({"point": point, "motion": offset * 1.25, "size": drop, "age": 0.0})
	queue_redraw()
	set_process(true)

func pool(world_point: Vector2, angle: float, delay: float, strength: float = 1.0) -> void:
	var index := records.size()
	records.append({"kind": "pool", "point": to_local(world_point), "angle": angle,
		"style": rng.randi_range(0, 3), "size": Vector2(50, 37) * strength, "strength": 0.97})
	growing[index] = -maxf(delay, 0.0)
	queue_redraw()
	set_process(true)

func eject(appearance: Dictionary) -> void:
	if appearance.is_empty():
		return
	var point := to_local(appearance.point)
	var outward: Vector2 = appearance.outward
	var launch := outward.rotated(rng.randf_range(-0.43, 0.27))
	var landing := point + launch * rng.randf_range(10.0, 20.0)
	var index := records.size()
	# Store the settled pose immediately, so even a chapter change mid-flight
	# leaves the casing where it would have landed when this world is revisited.
	records.append({"kind": "case", "point": landing, "angle": rng.randf_range(0, TAU), "look": appearance.look})
	flying[index] = {"from": point, "duration": rng.randf_range(0.46, 0.60), "age": -float(appearance.get("delay", 0.0)),
		"spin": launch.angle() + rng.randf_range(-2.0, 2.0), "turns": rng.randf_range(1.4, 2.6)}
	queue_redraw()
	set_process(true)

func _process(delta: float) -> void:
	for index in growing.keys():
		growing[index] += delta
		if growing[index] >= POOL_GROWTH:
			growing.erase(index)
	for index in flying.keys():
		var state: Dictionary = flying[index]
		state.age += delta
		if state.age >= state.duration:
			flying.erase(index)
	for index in range(splashes.size() - 1, -1, -1):
		splashes[index].age += delta
		if splashes[index].age >= SPLASH_LIFETIME:
			splashes.remove_at(index)
	queue_redraw()
	if growing.is_empty() and flying.is_empty() and splashes.is_empty():
		set_process(false)

func _draw() -> void:
	for index in range(records.size()):
		var record := records[index]
		match record.kind:
			"case": _draw_casing(record, flying.get(index, {}))
			"pool": _draw_stain(record, POOL, growing.get(index, POOL_GROWTH))
			"impact": _draw_stain(record, IMPACT, POOL_GROWTH)
	draw_set_transform(Vector2.ZERO)
	for splash in splashes:
		var phase := float(splash.age) / SPLASH_LIFETIME
		var point := Vector2(splash.point) + Vector2(splash.motion) * (1.0 - pow(1.0 - phase, 2.0))
		var distance := sin(phase * PI) * 2.2
		draw_circle(point - Vector2(0, distance), float(splash.size) * (1.0 - phase * 0.69) * 0.52,
			Color(0.53, 0.075, 0.104, 0.84 * (1.0 - phase)), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)

func _draw_stain(record: Dictionary, texture: Texture2D, age: float) -> void:
	if age < 0.0:
		return
	var growth := smoothstep(0.0, POOL_GROWTH, age)
	var size: Vector2 = record.size * lerpf(0.19, 1.0, growth)
	draw_set_transform(record.point, record.angle)
	var source := Rect2(int(record.style) * STAIN_CELL, 0, STAIN_CELL, STAIN_CELL)
	var alpha := float(record.strength) * lerpf(0.69, 1.0, growth)
	draw_texture_rect_region(texture, Rect2(-size * 0.5, size), source, Color(1, 1, 1, alpha))

func _draw_casing(record: Dictionary, flight: Dictionary) -> void:
	var point: Vector2 = record.point
	var angle: float = record.angle
	var height := 0.0
	if not flight.is_empty():
		if float(flight.age) < 0.0:
			return
		var phase := clampf(float(flight.age) / float(flight.duration), 0.0, 1.0)
		point = Vector2(flight.from).lerp(point, 1.0 - pow(1.0 - phase, 1.45))
		for i in range(CASE_HOPS.size()):
			var hop: Vector2 = CASE_HOPS[i]
			if phase >= hop.x and phase <= hop.y:
				var t := inverse_lerp(hop.x, hop.y, phase)
				height = 4.0 * t * (1.0 - t) * float(CASE_HEIGHTS[i])
				break
		angle = lerp_angle(float(flight.spin) + float(flight.turns) * phase * TAU, angle, smoothstep(0.77, 1.0, phase))
	draw_set_transform(Vector2.ZERO)
	draw_circle(point + Vector2(0.24, 0.37), 0.84, Color(0.07, 0.05, 0.045, 0.36), true, -1.0, true)
	draw_set_transform(point - Vector2(0, height), angle)
	var size: Vector2 = CASING_SIZES[record.look]
	draw_texture_rect(CASINGS[record.look], Rect2(-size * 0.5, size), false)
