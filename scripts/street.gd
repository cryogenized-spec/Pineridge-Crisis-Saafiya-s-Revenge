extends Node2D

const Art = preload("res://scripts/environment_art.gd")
const Damage := preload("res://scripts/vehicle_damage.gd")

class Backdrop extends Node2D:
	var street: Node2D
	func _draw() -> void:
		street.paint_backdrop(self)

const SIZE := Vector2(2320, 700)
const SHOP_NAMES := ["HOME & MORE", "PINE RIDGE", "BAKERY", "RECORDS", "PHARMACY"]
const PARKED_ART := ["hatchback_russet", "sedan_silver", "hatchback_sage", "taxi", "utility_ivory"]
const Props = preload("res://scripts/prop_library.gd")
var cached_backdrop: SubViewport
var obstacles: Array[Rect2] = []
var parked: Array[Rect2] = []
var parked_models: Array[String] = []
var parked_directions: Array[int] = []
var vehicle_marks := {}
var litter: Array[Dictionary] = []
var haze_origins := PackedVector2Array([Vector2(580,268),Vector2(1290,435),Vector2(1880,262)])

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	# Scenic architecture is a backdrop, not an explorable building plan.
	obstacles.append(Rect2(0, 0, SIZE.x, 140))
	for x in range(330, 2240, 342):
		parked.append(Rect2(x - 54, (466 if x >= 1000 or x % 2 else 238) - 21.5, 108, 43))
	for i in range(parked.size()):
		parked_models.append(PARKED_ART[i % PARKED_ART.size()])
		parked_directions.append(-1 if parked[i].get_center().y > 350 else 1)
	obstacles.append_array(parked)
	var rng := RandomNumberGenerator.new()
	rng.seed = 67204
	for i in range(85):
		var p := Vector2(rng.randf_range(45,2275),rng.randf_range(220,480))
		var kinds := ["brick","rubble","bottle","carton"]
		litter.append({"p":p,"id":kinds[i%4],"angle":rng.randf_range(0,TAU),"size":rng.randf_range(5,11)})
	for p in haze_origins:
		litter.append({"p":p,"id":"tyre","angle":0.0,"size":26.0})
		litter.append({"p":p+Vector2(12,8),"id":"tyre","angle":0.6,"size":22.0})
	cached_backdrop = SubViewport.new()
	cached_backdrop.size = Vector2i(SIZE)
	cached_backdrop.world_2d = World2D.new()
	cached_backdrop.gui_disable_input = true
	cached_backdrop.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(cached_backdrop)
	var scenery := Backdrop.new()
	scenery.street = self
	cached_backdrop.add_child(scenery)

func blocked(p: Vector2, radius: float = 7.0) -> bool:
	if p.x < radius or p.y < radius or p.x > SIZE.x - radius or p.y > SIZE.y - radius:
		return true
	for r in obstacles:
		if r.grow(radius).has_point(p):
			return true
	return false

func impact_vehicle(contact: Vector2, heading: Vector2, aim: Vector2) -> Vector2:
	var hit := Damage.hit_parked(contact, heading, aim, parked, parked_models, parked_directions, vehicle_marks)
	if hit.is_finite():
		queue_redraw()
	return hit

func _draw() -> void:
	if is_instance_valid(cached_backdrop):
		draw_texture(cached_backdrop.get_texture(), Vector2.ZERO)
	for i in range(parked.size()):
		var bounds := parked[i]
		Art.vehicle(self, bounds, parked_models[i], parked_directions[i])
		Damage.draw(self, bounds, parked_models[i], parked_directions[i], vehicle_marks.get(i, {}))

func paint_backdrop(canvas: Node2D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123456
	canvas.draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#625c64"))
	canvas.draw_rect(Rect2(0, 208, SIZE.x, 284), Color("#43434d"))
	canvas.draw_texture_rect(Art.ASPHALT_GRAIN, Rect2(0, 0, SIZE.x, SIZE.y), true)
	Art.curb(canvas, 206.0, int(SIZE.x))
	Art.curb(canvas, 494.0, int(SIZE.x))
	for x in range(0, 2320, 48):
		canvas.draw_rect(Rect2(x, 349, 22, 2), Color("#b6a580"))
	# Fictional retail district: distant architecture and a landscaped foreground.
	retail_backdrop(canvas, rng)
	canvas.draw_rect(Rect2(0, 550, SIZE.x, 150), Color("#344943"))
	canvas.draw_rect(Rect2(0, 553, SIZE.x, 8), Color("#819083"))
	canvas.draw_rect(Rect2(0, 680, SIZE.x, 20), Color("#293d38"))
	for x in range(0, 2320, 24):
		var p := Vector2(x + rng.randf_range(-9, 9), rng.randf_range(573, 675))
		canvas.draw_circle(p + Vector2(5, 4), rng.randf_range(10, 18), Color(0.08,0.14,0.13,0.30), true, -1, true)
		canvas.draw_circle(p, rng.randf_range(8, 16), Color("#536e53").lightened(rng.randf_range(-0.20, 0.15)), true, -1, true)
	for x in range(90, 2320, 117):
		tree(canvas, Vector2(x, 600 + rng.randf_range(-15, 40)), rng)
	for x in range(80, 2320, 218):
		tree(canvas, Vector2(x, 181), rng)
		tree(canvas, Vector2(x + 30, 519), rng)
	# Scattered visual scenery, not tactical cover or barricades.
	for item in litter:
		var p: Vector2 = item.p
		var size: float = item.size
		var texture := Props.texture(item.id)
		canvas.draw_set_transform(p, float(item.angle))
		canvas.draw_texture_rect(texture,Rect2(Vector2.ONE*(-size*0.5),Vector2.ONE*size),false)
	canvas.draw_set_transform(Vector2.ZERO)

func retail_backdrop(canvas: Node2D, rng: RandomNumberGenerator) -> void:
	canvas.draw_rect(Rect2(0, 0, SIZE.x, 146), Color("#4d515b"))
	for i in range(9):
		var x := i * 267.0
		var top := -15.0 + rng.randf_range(0, 15)
		Art.building(canvas, Rect2(x, top, 257, 139), Art.SHOPS[i % Art.SHOPS.size()])
		canvas.draw_rect(Rect2(x + 76, top + 113, 108, 13), Color("#393a3e"))
		canvas.draw_string(ThemeDB.fallback_font, Vector2(x + 76, top + 123), SHOP_NAMES[i % SHOP_NAMES.size()],
			HORIZONTAL_ALIGNMENT_CENTER, 108, 9, Color("#efe1c3"))
		if i % 2 == 0:
			canvas.draw_texture_rect(Art.BIN, Rect2(x + 199, 157, 23, 23), false)
			canvas.draw_texture_rect(Art.CRATE, Rect2(x + 225, 153, 19, 19), false)
	canvas.draw_rect(Rect2(0, 142, SIZE.x, 19), Color("#546b55"))
	for x in range(0, 2320, 13):
		canvas.draw_circle(Vector2(x, 150 + rng.randf_range(-4, 4)), 6, Color("#63785e").darkened(rng.randf_range(0, 0.18)), true, -1, true)
	canvas.draw_line(Vector2(0, 165), Vector2(SIZE.x, 165), Color("#a49b8b"), 3)

func tree(canvas: Node2D, p:Vector2,rng:RandomNumberGenerator) -> void:
	canvas.draw_rect(Rect2(p-Vector2(9,9),Vector2(19,18)),Color("#93877b"))
	canvas.draw_circle(p+Vector2(6,7),13,Color(0.12,0.10,0.16,0.35),true,-1,true)
	canvas.draw_circle(p,12,Color("#475c54"),true,-1,true)
	for i in range(12):
		var off := Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(1,9)
		canvas.draw_circle(p+off,rng.randf_range(3,6),Color("#687961").lightened(rng.randf_range(-0.2,0.18)),true,-1,true)
