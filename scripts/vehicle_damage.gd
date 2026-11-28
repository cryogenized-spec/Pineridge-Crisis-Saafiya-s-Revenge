extends RefCounted
## Cosmetic damage follows the registered artwork. The arcade collision stays with the world.
const Art := preload("res://scripts/environment_art.gd")
const Catalogue := preload("res://scripts/vehicle_damage_art.gd")
const PUNCTURES := preload("res://assets/environment/vehicle_damage/panel_punctures.png")
const HAZE := preload("res://assets/fx/weapon_art/smoke.png")
const SHATTER_HITS := 3
const MAX_MARKS := 18
const MISS := Vector2.INF
static var silhouettes: Dictionary = {}

static func panel(model: String, direction: int) -> Dictionary:
	return Catalogue.PANELS[model][0 if direction > 0 else 1]

static func has_surface(texture: Texture2D, uv: Vector2) -> bool:
	if not Rect2(Vector2.ZERO, Vector2.ONE).has_point(uv):
		return false
	var key := texture.resource_path
	if not silhouettes.has(key):
		var decoded := texture.get_image()
		if decoded.is_compressed():
			decoded.decompress()
		silhouettes[key] = decoded
	var image: Image = silhouettes[key]
	var point := Vector2i(uv * Vector2(image.get_size()))
	return image.get_pixelv(point).a > .78

static func impact(footprint: Rect2, model: String, direction: int, contact: Vector2,
		heading: Vector2, aim: Vector2, damage: Dictionary) -> Vector2:
	if not footprint.grow(8).has_point(contact):
		return MISS
	var bounds := Art.vehicle_bounds(footprint)
	var texture := Art.vehicle_texture(model, direction)
	var hit := MISS
	if aim.is_finite() and has_surface(texture, (aim - bounds.position) / bounds.size):
		hit = aim
	else:
		for offset in range(-6, 30, 2):
			var sample := contact + heading * offset
			if has_surface(texture, (sample - bounds.position) / bounds.size):
				hit = sample
				break
	if not hit.is_finite():
		return MISS
	var uv := (hit - bounds.position) / bounds.size
	var glass := Geometry2D.is_point_in_polygon(uv, PackedVector2Array(panel(model, direction).glass))
	damage.hits = int(damage.get("hits", 0)) + 1
	if glass:
		damage.glass_hits = int(damage.get("glass_hits", 0)) + 1
	var marks: Array = damage.get("marks", [])
	if marks.size() >= MAX_MARKS:
		marks.pop_front()
	marks.append({"uv":uv, "glass":glass, "style":int(damage.hits) % 3})
	damage.marks = marks
	return hit

static func hit_parked(contact: Vector2, heading: Vector2, aim: Vector2, footprints: Array,
		models: Array, directions: Array, damage: Dictionary) -> Vector2:
	for i in range(footprints.size()):
		var record: Dictionary = damage.get(i, {})
		var hit := impact(footprints[i], models[i], directions[i], contact, heading, aim, record)
		if hit.is_finite():
			damage[i] = record
			return hit
	return MISS

static func draw(canvas: CanvasItem, footprint: Rect2, model: String, direction: int,
		damage: Dictionary) -> void:
	if damage.is_empty():
		return
	var bounds := Art.vehicle_bounds(footprint)
	var glass_art := panel(model, direction)
	var shattered := int(damage.get("glass_hits", 0)) >= SHATTER_HITS
	if shattered:
		canvas.draw_texture_rect(glass_art.shattered, bounds, false)
	var glass_points := PackedVector2Array()
	for point in glass_art.glass:
		glass_points.append(bounds.position + Vector2(point) * bounds.size)
	var diameter := clampf(footprint.size.x * .057, 3.3, 6.5)
	for mark in damage.marks:
		var point: Vector2 = bounds.position + Vector2(mark.uv) * bounds.size
		if mark.glass:
			if not shattered:
				glass_chip(canvas, point, glass_points, diameter * .83, int(mark.style))
		else:
			var source := Rect2(float(mark.style) * 48, 0, 48, 48)
			canvas.draw_texture_rect_region(PUNCTURES,
				Rect2(point - Vector2.ONE * diameter * .5, Vector2.ONE * diameter), source)

static func glass_chip(canvas: CanvasItem, point: Vector2, glass: PackedVector2Array,
		size: float, style: int) -> void:
	canvas.draw_circle(point, maxf(.9, size * .19), Color("#1c2833"), true, -1, true)
	canvas.draw_arc(point, maxf(1.1, size * .23), .8, 5.7, 9, Color("#cccfc4"), .66, true)
	for spoke in range(6):
		var direction := Vector2.from_angle(float(spoke) * TAU / 6.0 + style * .48)
		var length := size * (.47 + float((spoke + style) % 3) * .11)
		var tip := point + direction * length
		if not Geometry2D.is_point_in_polygon(tip, glass):
			tip = point + direction * length * .40
		if Geometry2D.is_point_in_polygon(tip, glass):
			canvas.draw_line(point, tip, Color("#d0dcdc"), .67, true)

static func draw_vapor(canvas: CanvasItem, footprint: Rect2, direction: int, clock: float) -> void:
	var bounds := Art.vehicle_bounds(footprint)
	var hood := bounds.position + bounds.size * Vector2(.77 if direction > 0 else .23, .52)
	for i in range(3):
		var rise := fposmod(clock * .48 + float(i) / 3.0, 1.0)
		var at := hood + Vector2(2.1 * sin(clock + i) + rise * 6, -rise * 13)
		var size := Vector2.ONE * (7.0 + rise * 13.0)
		var tint := Color(.65, .68, .70, sin(rise * PI) * .48)
		canvas.draw_texture_rect(HAZE, Rect2(at - size * .5, size), false, tint)
