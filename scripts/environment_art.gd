extends RefCounted
## World-space artwork. The caller's ground and obstacle rectangles stay authoritative.
const VEHICLES := {
	"taxi": [preload("res://assets/environment/vehicles/taxi_east.png"), preload("res://assets/environment/vehicles/taxi_west.png")],
	"sedan_silver": [preload("res://assets/environment/vehicles/sedan_silver_east.png"), preload("res://assets/environment/vehicles/sedan_silver_west.png")],
	"sedan_ochre": [preload("res://assets/environment/vehicles/sedan_ochre_east.png"), preload("res://assets/environment/vehicles/sedan_ochre_west.png")],
	"hatchback_russet": [preload("res://assets/environment/vehicles/hatchback_russet_east.png"), preload("res://assets/environment/vehicles/hatchback_russet_west.png")],
	"hatchback_sage": [preload("res://assets/environment/vehicles/hatchback_sage_east.png"), preload("res://assets/environment/vehicles/hatchback_sage_west.png")],
	"utility_ivory": [preload("res://assets/environment/vehicles/utility_ivory_east.png"), preload("res://assets/environment/vehicles/utility_ivory_west.png")],
	"security": [preload("res://assets/environment/vehicles/security_east.png"), preload("res://assets/environment/vehicles/security_west.png")],
	"saafiya_car": [preload("res://assets/environment/vehicles/saafiya_car_east.png"), preload("res://assets/environment/vehicles/saafiya_car_west.png")],
}
const HOUSES := [
	preload("res://assets/environment/architecture/house_terracotta.png"),
	preload("res://assets/environment/architecture/house_slate.png"),
	preload("res://assets/environment/architecture/house_stone.png"),
]
const SHOPS := [
	preload("res://assets/environment/architecture/retail_copper.png"),
	preload("res://assets/environment/architecture/retail_teal.png"),
	preload("res://assets/environment/architecture/retail_sand.png"),
]
const BARRICADED_HOUSE := preload("res://assets/environment/architecture/barricaded_house.png")
const PARKING := preload("res://assets/environment/roadside/parking.png")
const FENCE := preload("res://assets/environment/roadside/fence.png")
const FENCE_VERTICAL := preload("res://assets/environment/roadside/fence_vertical.png")
const GATE := preload("res://assets/environment/roadside/gate.png")
const GATE_OPEN := preload("res://assets/environment/roadside/gate_open.png")
const WALL := preload("res://assets/environment/roadside/wall.png")
const CURB := preload("res://assets/environment/roadside/curb.png")
const BIN := preload("res://assets/environment/roadside/bin.png")
const CRATE := preload("res://assets/environment/roadside/crate.png")
const ASPHALT_GRAIN := preload("res://assets/environment/roadside/asphalt_grain.png")
const SHRUBS := [
	preload("res://assets/environment/roadside/shrub_0.png"),
	preload("res://assets/environment/roadside/shrub_1.png"),
	preload("res://assets/environment/roadside/shrub_2.png"),
]

static func vehicle_bounds(footprint: Rect2) -> Rect2:
	var size := footprint.size * Vector2(144.0 / 108.0, 68.0 / 43.0)
	return Rect2(footprint.get_center() - size * 0.5, size)

static func vehicle_texture(model: String, direction: int) -> Texture2D:
	return VEHICLES[model][0 if direction > 0 else 1]

static func vehicle(canvas: CanvasItem, footprint: Rect2, model: String, direction: int) -> void:
	canvas.draw_texture_rect(vehicle_texture(model, direction), vehicle_bounds(footprint), false)

static func building(canvas: CanvasItem, roof: Rect2, sprite: Texture2D) -> void:
	var margin := roof.size * Vector2(0.11, 0.20)
	var bounds := roof.grow_individual(margin.x, margin.y, margin.x, margin.y)
	canvas.draw_texture_rect(sprite, bounds, false)

static func curb(canvas: CanvasItem, y: float, length: int) -> void:
	for x in range(0, length, 96):
		canvas.draw_texture_rect(CURB, Rect2(x - 5, y - 8, 106, 17), false)

static func fence_run(canvas: CanvasItem, start: float, end: float, y: float) -> void:
	var count := maxi(1, roundi((end - start) / 54.0))
	var section := (end - start) / float(count)
	for index in range(count):
		canvas.draw_texture_rect(FENCE, Rect2(start + index * section - 4, y - 9, section + 8, 23), false)


static func shrub(canvas: CanvasItem, center: Vector2, seed: int, diameter: float) -> void:
	canvas.draw_texture_rect(SHRUBS[posmod(seed, SHRUBS.size())],
		Rect2(center - Vector2.ONE * diameter * 0.5, Vector2.ONE * diameter), false)
