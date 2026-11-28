extends Node2D

const FRONT_ROOM_ART := preload("res://assets/environment/interiors/barricaded_front_room.png")
const Art = preload("res://scripts/environment_art.gd")
const Traffic = preload("res://scripts/ambient_traffic.gd")
const Damage := preload("res://scripts/vehicle_damage.gd")
var traffic: Traffic
var taxi: Node2D
# Segment 2: fictional house exterior near Pine Ridge mall.
# Orthographic overhead scenery, approximately 24 display pixels/metre.
const SIZE := Vector2(2320.0,1024.0)
const ROAD_TOP := 405.0
const ROAD_BOTTOM := 679.0
const GATE_POINT := Vector2(1365.0,427.0)
const EXIT_POINT := Vector2(2172.0,545.0)
const CAR_LENGTH := 108.0
const CAR_WIDTH := 43.0
const ROOF := Rect2(1048.0,75.0,515.0,208.0)
const CAR_A := Rect2(1048.0,320.0,CAR_LENGTH,CAR_WIDTH)
const CAR_B := Rect2(1180.0,320.0,CAR_LENGTH,CAR_WIDTH)
const STREET_CAR := Rect2(475.0,684.0,CAR_LENGTH,CAR_WIDTH)
const PARKED_CARS := [CAR_A, CAR_B, STREET_CAR]
const PARKED_ART := ["sedan_silver", "hatchback_russet", "sedan_ochre"]
const PARKED_FACING := [-1, 1, -1]
const PORCH := Vector2(1365, 305)
const ROOM_DOOR := Vector2(1365, 259)
const OTHER_HOUSES := [
	Vector2(105,66), Vector2(520,83), Vector2(1790,64), Vector2(300,765), Vector2(1540,768)
]
const ROOM := Rect2(1214, 104, 304, 176)
const ROOM_FURNITURE := [
	Rect2(1227, 121, 60, 58), Rect2(1454, 123, 47, 96), Rect2(1309, 148, 78, 37)
]
var solid: Array[Rect2] = []
var inside := false
var allow_entry := false
var vehicle_marks := {}

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	solid = [
		CAR_A,CAR_B,STREET_CAR,ROOF,
		Rect2(958,393,375,11),
		Rect2(1400,393,272,11),
		Rect2(958,278,9,126),
		Rect2(1663,278,9,126)
	]
	for at in OTHER_HOUSES:
		solid.append(Rect2(at, Vector2(318, 203)))
	queue_redraw()

func blocked(p: Vector2, radius: float = 7.0) -> bool:
	if is_instance_valid(taxi) and taxi.blocked(p, radius):
		return true
	if is_instance_valid(traffic) and traffic.blocked(p,radius):
		return true
	if not Rect2(Vector2.ZERO, SIZE).grow(-radius).has_point(p):
		return true
	if inside and ROOM.grow(-radius).has_point(p):
		for item in ROOM_FURNITURE:
			if item.grow(radius).has_point(p):
				return true
		return false
	for r in solid:
		if r.grow(radius).has_point(p):
			return true
	return false

func impact_vehicle(contact: Vector2, heading: Vector2, aim: Vector2) -> Vector2:
	if is_instance_valid(taxi):
		var staged: Vector2 = taxi.impact_vehicle(contact, heading, aim)
		if staged.is_finite():
			return staged
	if is_instance_valid(traffic):
		var moving := traffic.impact_vehicle(contact, heading, aim)
		if moving.is_finite():
			return moving
	var hit := Damage.hit_parked(contact, heading, aim, PARKED_CARS, PARKED_ART, PARKED_FACING, vehicle_marks)
	if hit.is_finite():
		queue_redraw()
	return hit

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,SIZE),Color("#405646"))
	draw_rect(Rect2(0,0,SIZE.x,382),Color("#66765e"))
	draw_rect(Rect2(0,706,SIZE.x,318),Color("#617156"))
	draw_rect(Rect2(0,ROAD_TOP-23,SIZE.x,ROAD_BOTTOM-ROAD_TOP+48),Color("#a8a49c"))
	draw_rect(Rect2(0,ROAD_TOP,SIZE.x,ROAD_BOTTOM-ROAD_TOP),Color("#434650"))
	draw_texture_rect(Art.ASPHALT_GRAIN, Rect2(0, ROAD_TOP, SIZE.x, ROAD_BOTTOM - ROAD_TOP), true)
	draw_rect(Rect2(0,386,SIZE.x,15),Color("#c5beb3"))
	draw_rect(Rect2(0,682,SIZE.x,15),Color("#c5beb3"))
	Art.curb(self, ROAD_TOP, int(SIZE.x))
	Art.curb(self, ROAD_BOTTOM, int(SIZE.x))
	for x in range(20,2260,102):
		draw_rect(Rect2(x,540,48,2),Color("#cfc3a6"))
	for i in range(17):
		var x := float(i)*146.0
		draw_line(Vector2(x,35),Vector2(x+60,302),Color(0.86,0.81,0.65,0.055),1)
		draw_line(Vector2(x+42,776),Vector2(x+105,995),Color(0.85,0.82,0.7,0.05),1)
	draw_decorative_home(Vector2(105,66),0,"RIDGE VIEW")
	draw_decorative_home(Vector2(520,83),1,"HILLSIDE")
	draw_decorative_home(Vector2(1790,64),2,"ROSE COTTAGE")
	draw_decorative_home(Vector2(300,765),2,"")
	draw_decorative_home(Vector2(1540,768),0,"")
	draw_primary_property()
	draw_parked(2)
	draw_sign(Vector2(180,410),"PINE RIDGE")
	draw_sign(Vector2(1885,697),"MALL ROUTE")
	for i in range(46):
		var px := 25.0+float(i)*50.0
		shrub(Vector2(px,369),i)
		shrub(Vector2(px+16,720),i+17)
	for i in range(7):
		tree(Vector2(148.0+float(i)*330.0,912.0+float((i*7)%45)))
	if not allow_entry:
		draw_marker(GATE_POINT,Color("#edc57a"),"CHECK THE HOUSE")
	else:
		draw_marker(ROOM_DOOR if inside else PORCH, Color("#edc57a"), "OUT TO YARD" if inside else "FRONT ROOM")
	draw_marker(EXIT_POINT,Color("#a4dbc7"),"NEXT BLOCK")

func draw_primary_property() -> void:
	draw_rect(Rect2(947,65,739,350),Color(0.07,0.10,0.09,0.3))
	draw_rect(Rect2(951,67,725,340),Color("#6e7e63"))
	draw_rect(Rect2(964,82,700,315),Color("#80906f"))
	for j in range(9):
		var px := 975.0+float(j)*78.0
		shrub(Vector2(px,292),j+25)
		draw_line(Vector2(px,68),Vector2(px+24,68),Color("#b2b3a7"),2)
	if inside:
		draw_front_room()
	else:
		Art.building(self, ROOF, Art.BARRICADED_HOUSE)
		draw_rect(Rect2(1348, 274, 34, 12), Color("#5a483f"))
		draw_rect(Rect2(1351, 284, 28, 20), Color("#918172"))
	draw_texture_rect(Art.PARKING, Rect2(1020, 292, 298, 107), false)
	draw_parked(0)
	draw_parked(1)
	draw_fence()
	draw_texture_rect(Art.BIN, Rect2(1477, 344, 31, 32), false)
	draw_texture_rect(Art.BIN, Rect2(1529, 351, 31, 32), false, Color("#b2c6c6"))
	draw_texture_rect(Art.CRATE, Rect2(1587, 343, 33, 28), false)
	shrub(Vector2(1625,324),13)
	# Occupied-home sign is deliberately legible at steep top-down.
	draw_rect(Rect2(1402,294,172,26),Color("#414a44"))
	draw_string(ThemeDB.fallback_font,Vector2(1409,312),"FAMILY INSIDE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e9dcbf"))

func draw_front_room() -> void:
	draw_rect(ROOF, Color("#3a3440"))
	draw_texture_rect(FRONT_ROOM_ART, Rect2(1025, 64, 550, 240), false)

func draw_parked(index: int) -> void:
	Art.vehicle(self, PARKED_CARS[index], PARKED_ART[index], PARKED_FACING[index])
	Damage.draw(self, PARKED_CARS[index], PARKED_ART[index], PARKED_FACING[index], vehicle_marks.get(index, {}))

func draw_fence() -> void:
	Art.fence_run(self, 958, 1333, 398)
	Art.fence_run(self, 1400, 1672, 398)
	draw_texture_rect(Art.FENCE_VERTICAL, Rect2(947, 274, 24, 138), false)
	draw_texture_rect(Art.FENCE_VERTICAL, Rect2(1653, 274, 24, 138), false)
	# Keep the walkthrough between the posts visually open.
	draw_texture_rect(Art.GATE_OPEN, Rect2(1325, 367, 82, 41), false)

func draw_decorative_home(at: Vector2, appearance: int, words: String) -> void:
	Art.building(self, Rect2(at, Vector2(318, 203)), Art.HOUSES[appearance])
	if words != "":
		draw_rect(Rect2(at.x + 17, at.y + 184, 130, 14), Color("#444b46"))
		draw_string(ThemeDB.fallback_font, at + Vector2(22, 195), words, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("#e6dac5"))
	for i in range(6):
		shrub(at + Vector2(16.0 + float(i) * 55.0, 220), i + 5)

func shrub(p: Vector2, index: int) -> void:
	Art.shrub(self, p, index, 26.0)

func tree(p: Vector2) -> void:
	draw_circle(p+Vector2(7,9),32,Color(0.1,0.14,0.12,0.25))
	draw_circle(p,27,Color("#345347"))
	draw_circle(p+Vector2(-8,-4),18,Color("#547354"))
	draw_circle(p+Vector2(9,2),16,Color("#688560"))

func draw_sign(p: Vector2, caption: String) -> void:
	draw_rect(Rect2(p-Vector2(8,11),Vector2(124,24)),Color("#334f4b"))
	draw_string(ThemeDB.fallback_font,p+Vector2(0,5),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("#ece1c6"))

func draw_marker(p: Vector2, tint: Color, caption: String) -> void:
	draw_circle(p,26,Color(tint.r,tint.g,tint.b,0.11))
	draw_arc(p,20,0,TAU,32,tint,1.8,true)
	draw_circle(p,3.0,tint)
	draw_string(ThemeDB.fallback_font,p+Vector2(-42,-27),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,11,tint)
