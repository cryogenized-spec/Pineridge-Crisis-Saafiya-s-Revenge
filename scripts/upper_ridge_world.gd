extends Node2D

const Art = preload("res://scripts/environment_art.gd")
const Traffic = preload("res://scripts/ambient_traffic.gd")
const RIDGE_TREE := preload("res://assets/environment/roadside/jacobs_tree.png")
const RIDGE_HOUSE := preload("res://assets/environment/architecture/jacobs_house.png")
var traffic: Traffic
# Upper Pineridge: a fictional residential approach in overhead projection.
# One world unit = one display pixel. Approximate scale is 24 px / metre.
const SIZE := Vector2(2320.0, 1024.0)
const ROAD_TOP := 382.0
const ROAD_BOTTOM := 652.0
const EXIT_POINT := Vector2(2180.0, 522.0)
const PLAYER_CAR := Rect2(213.0,457.0,108.0,43.0)
const TRUNK_POINT := Vector2(202.0,512.0)
const CAR_LENGTH := 108.0
const CAR_WIDTH := 43.0
const LOTS := [Vector2(168,93),Vector2(642,91),Vector2(1284,92),Vector2(1864,91)]
const JACOBS_LAWN := Rect2(1859, 39, 359, 351)
const JACOBS_ROOF := Rect2(1902, 128, 238, 148)
const TREE_POINT := Vector2(2064, 77)
const PARKED_ART := ["saafiya_car", "hatchback_russet", "sedan_silver", "utility_ivory"]
var parked: Array[Rect2] = [
	PLAYER_CAR,
	Rect2(350,326,CAR_LENGTH,CAR_WIDTH),
	Rect2(1110,657,CAR_LENGTH,CAR_WIDTH),
	Rect2(1740,328,CAR_LENGTH,CAR_WIDTH)
]
var fixed_obstacles: Array[Rect2] = []
var vehicle_marks := {}

func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for r in parked:
		fixed_obstacles.append(r)
	fixed_obstacles.append_array([JACOBS_ROOF, Rect2(1859, 325, 63, 11), Rect2(2015, 325, 171, 11),
		Rect2(TREE_POINT - Vector2(6, 5), Vector2(12, 10))])
	queue_redraw()

func blocked(p: Vector2, radius: float = 7.0) -> bool:
	if is_instance_valid(traffic) and traffic.blocked(p,radius):
		return true
	if p.x < radius or p.x > SIZE.x-radius:
		return true
	var on_verge := p.y >= ROAD_TOP - 49.0 + radius and p.y <= ROAD_BOTTOM + 63.0 - radius
	if not on_verge and not JACOBS_LAWN.grow(-radius).has_point(p):
		var accessible := false
		for i in range(1, LOTS.size()):
			var lot: Vector2 = LOTS[i]
			var yard := Rect2(lot + Vector2(7, 188), Vector2(311, 54))
			var drive := Rect2(lot + Vector2(64, 217), Vector2(75, ROAD_TOP - lot.y - 205))
			if yard.grow(-radius).has_point(p) or drive.grow(-radius).has_point(p):
				accessible = true
				break
		if not accessible:
			return true
	for r in fixed_obstacles:
		if r.grow(radius).has_point(p):
			return true
	return false

func impact_vehicle(at: Vector2, _heading: Vector2) -> bool:
	if is_instance_valid(traffic) and traffic.impact_vehicle(at):
		return true
	if Traffic.mark_parked(at, parked, vehicle_marks):
		queue_redraw()
		return true
	return false

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,SIZE),Color("#34483f"))
	draw_rect(Rect2(0,0,SIZE.x,ROAD_TOP-26),Color("#52604e"))
	draw_rect(Rect2(0,ROAD_BOTTOM+25,SIZE.x,SIZE.y-ROAD_BOTTOM-25),Color("#4b5c4b"))
	for i in range(16):
		var x := float(i)*155.0
		# Diagonal retaining / contour bands suggest elevation without a
		# physically incorrect pseudo-3D vanishing point.
		draw_line(Vector2(x,16),Vector2(x+70,ROAD_TOP-47),Color(0.85,0.77,0.63,0.045),1.0)
		draw_line(Vector2(x+44,ROAD_BOTTOM+50),Vector2(x+140,SIZE.y),Color(0.87,0.79,0.68,0.04),1.0)
	draw_rect(Rect2(0,ROAD_TOP-24,SIZE.x,ROAD_BOTTOM-ROAD_TOP+48),Color("#9b9892"))
	draw_rect(Rect2(0,ROAD_TOP,SIZE.x,ROAD_BOTTOM-ROAD_TOP),Color("#46474e"))
	draw_texture_rect(Art.ASPHALT_GRAIN, Rect2(0, ROAD_TOP, SIZE.x, ROAD_BOTTOM - ROAD_TOP), true)
	draw_rect(Rect2(0,ROAD_TOP-19,SIZE.x,16),Color("#b2a9a0"))
	draw_rect(Rect2(0,ROAD_BOTTOM+3,SIZE.x,16),Color("#b2a9a0"))
	Art.curb(self, ROAD_TOP, int(SIZE.x))
	Art.curb(self, ROAD_BOTTOM, int(SIZE.x))
	for x in range(24,2280,105):
		draw_rect(Rect2(x,516,53,2),Color("#c7bb9e"))
	# North and south residential allotments; comparable architectural scale.
	for i in range(LOTS.size()):
		draw_lot(LOTS[i],i,true)
	for i in range(3):
		draw_lot(Vector2(340.0+float(i)*615.0,740.0),i+1,false)
	for i in range(44):
		var x := 50.0+float(i)*52.0
		draw_shrub(Vector2(x,350.0+float((i*7)%13)),i)
		draw_shrub(Vector2(x+15,702.0+float((i*5)%13)),i+11)
	for i in range(parked.size()):
		Art.vehicle(self, parked[i], PARKED_ART[i], -1 if i == 2 else 1)
		Traffic.draw_marks(self, parked[i], vehicle_marks.get(i, []))
	draw_string(ThemeDB.fallback_font,TRUNK_POINT+Vector2(-18,-21),"SAAFIYA'S MUSTANG",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("#f1dfc3"))
	# Environmental signposting, not tactical markers.
	draw_sign(Vector2(192,390),"UPPER RIDGE")
	draw_sign(Vector2(1960,666),"MALL DISTRICT")
	draw_exit()
	for x in range(105,2200,340):
		if x < 1900:
			draw_tree(Vector2(float(x),48.0+float((x*3)%45)),x)
		draw_tree(Vector2(float(x)+92,960.0+float(x%31)),x+19)
	draw_rect(Rect2(1955, 278, 38, 24), Color("#a49784"))
	draw_rect(Rect2(2094, 108, 32, 20), Color("#a49784"))
	draw_texture_rect(RIDGE_TREE, Rect2(TREE_POINT - Vector2(66, 79), Vector2(132, 121)), false)

func draw_lot(at: Vector2, index: int, north: bool) -> void:
	var w := 327.0
	var depth := 245.0
	var shadow := Rect2(at+Vector2(9,11),Vector2(w,depth))
	draw_rect(shadow,Color(0.09,0.11,0.14,0.31))
	draw_rect(Rect2(at,Vector2(w,depth)),Color("#687760"))
	draw_rect(Rect2(at+Vector2(5,6),Vector2(w-10,depth-12)),Color("#7b8570"))
	var open_drive := north and index > 0
	if open_drive:
		var paved := Rect2(at + Vector2(65, 189), Vector2(73, ROAD_TOP - at.y - 188))
		draw_rect(paved, Color("#8a8276"))
		for y in range(int(paved.position.y) + 8, int(paved.end.y), 9):
			draw_line(Vector2(paved.position.x + 3, y), Vector2(paved.end.x - 3, y), Color("#69685e"))
	var roof := Rect2(at+Vector2(38,37),Vector2(238,148))
	var facade: Texture2D = RIDGE_HOUSE if north and index == LOTS.size() - 1 else Art.HOUSES[index % Art.HOUSES.size()]
	Art.building(self, roof, facade)
	var garden_y := at.y+210 if north else at.y+10
	for j in range(4):
		if open_drive and j == 1:
			continue
		draw_shrub(Vector2(at.x+23.0+float(j)*81.0,garden_y),index*10+j)
	# The three boundary pieces preserve the driveway opening and the lot positions.
	var boundary_y := at.y + depth - 6.0 if north else at.y + 6.0
	draw_texture_rect(Art.WALL, Rect2(at.x - 3, boundary_y - 9, 61, 20), false)
	draw_texture_rect(Art.GATE_OPEN if open_drive else Art.GATE, Rect2(at.x + 54, boundary_y - 14, 96, 30), false)
	Art.fence_run(self, at.x + 151, at.x + w - 5, boundary_y)
	draw_texture_rect(Art.BIN, Rect2(at.x + 4, at.y + 10, 22, 24), false)
	draw_texture_rect(Art.CRATE, Rect2(at.x + 296, at.y + 12, 22, 22), false)
	if index == 2:
		draw_texture_rect(Art.PARKING, Rect2(at + Vector2(275, 48), Vector2(48, 87)), false)

func draw_tree(p: Vector2, seed: int) -> void:
	var shift := float(seed%7)
	draw_circle(p+Vector2(8,9),27,Color(0.07,0.09,0.12,0.25))
	draw_circle(p,24,Color("#344f43"))
	draw_circle(p+Vector2(-6,3),16,Color("#597355"))
	draw_circle(p+Vector2(7,-6),13,Color("#668560"))
	draw_circle(p+Vector2(shift-3,8),10,Color("#415e4b"))

func draw_shrub(p: Vector2, seed: int) -> void:
	Art.shrub(self, p, seed, 26.0)

func draw_sign(p: Vector2, words: String) -> void:
	draw_line(p+Vector2(0,4),p+Vector2(0,24),Color("#d1c7ac"),3)
	draw_rect(Rect2(p-Vector2(14,12),Vector2(113,24)),Color("#263f40"))
	draw_rect(Rect2(p-Vector2(12,10),Vector2(109,20)),Color("#44605a"),false,1.0)
	draw_string(ThemeDB.fallback_font,p+Vector2(-7,4),words,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#e8e6d4"))

func draw_exit() -> void:
	var p := EXIT_POINT
	draw_circle(p,30,Color(0.44,0.68,0.59,0.1))
	draw_arc(p,21,0,TAU,32,Color("#a8ddca"),2.2,true)
	draw_string(ThemeDB.fallback_font,p+Vector2(-28,-33),"TO MALL ROAD",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#e7e1cb"))
	draw_line(p+Vector2(7,0),p+Vector2(-7,0),Color("#c1e3d0"),2)
	draw_line(p+Vector2(4,-6),p+Vector2(12,0),Color("#c1e3d0"),2)
	draw_line(p+Vector2(4,6),p+Vector2(12,0),Color("#c1e3d0"),2)
