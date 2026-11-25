extends Node2D
# Upper Pineridge: a fictional residential approach in overhead projection.
# One world unit = one display pixel. Approximate scale is 24 px / metre.
const SIZE := Vector2(2320.0, 1024.0)
const ROAD_TOP := 382.0
const ROAD_BOTTOM := 652.0
const EXIT_POINT := Vector2(2180.0, 522.0)
const CAR_LENGTH := 108.0
const CAR_WIDTH := 43.0
const LOTS := [Vector2(168,93),Vector2(642,91),Vector2(1284,92),Vector2(1864,91)]
const PALETTE := [
	Color("#867c77"),Color("#6b7880"),Color("#958678"),Color("#7a776b")
]
var road_texture: Texture2D
var parked: Array[Rect2] = [
	Rect2(350,326,CAR_LENGTH,CAR_WIDTH),
	Rect2(1110,657,CAR_LENGTH,CAR_WIDTH),
	Rect2(1740,328,CAR_LENGTH,CAR_WIDTH)
]
var fixed_obstacles: Array[Rect2] = []

func _ready() -> void:
	prepare_texture()
	for r in parked:
		fixed_obstacles.append(r)
	queue_redraw()

func prepare_texture() -> void:
	var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var random := RandomNumberGenerator.new()
	random.seed = 91731
	for i in range(1800):
		var x := random.randi_range(0,127)
		var y := random.randi_range(0,127)
		image.set_pixel(x,y,Color(0.63,0.61,0.57,random.randf_range(0.025,0.15)))
	road_texture = ImageTexture.create_from_image(image)
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED

func blocked(p: Vector2, radius: float = 7.0) -> bool:
	# Segment-one houses are exterior scenery, not explorable interiors.
	if p.x < radius or p.x > SIZE.x-radius or p.y < ROAD_TOP-22.0+radius or p.y > ROAD_BOTTOM+22.0-radius:
		return true
	for r in fixed_obstacles:
		if r.grow(radius).has_point(p):
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
	if road_texture != null:
		draw_texture_rect(road_texture,Rect2(0,ROAD_TOP,SIZE.x,ROAD_BOTTOM-ROAD_TOP),true)
	draw_rect(Rect2(0,ROAD_TOP-19,SIZE.x,16),Color("#b2a9a0"))
	draw_rect(Rect2(0,ROAD_BOTTOM+3,SIZE.x,16),Color("#b2a9a0"))
	draw_line(Vector2(0,ROAD_TOP),Vector2(SIZE.x,ROAD_TOP),Color("#dbd1b7"),2.0)
	draw_line(Vector2(0,ROAD_BOTTOM),Vector2(SIZE.x,ROAD_BOTTOM),Color("#dbd1b7"),2.0)
	for x in range(24,2280,105):
		draw_rect(Rect2(x,516,53,2),Color("#c7bb9e"))
	for x in range(0,2320,174):
		draw_line(Vector2(x,ROAD_TOP-15),Vector2(x+45,ROAD_TOP-15),Color("#dbd4c4"),1.0)
		draw_line(Vector2(x,ROAD_BOTTOM+12),Vector2(x+45,ROAD_BOTTOM+12),Color("#dbd4c4"),1.0)
	# North and south residential allotments; comparable architectural scale.
	for i in range(LOTS.size()):
		draw_lot(LOTS[i],i,true)
	for i in range(3):
		draw_lot(Vector2(340.0+float(i)*615.0,740.0),i+1,false)
	for r in parked:
		draw_car(r,Color("#9b7770") if r.position.x<1000 else Color("#819496"))
	for i in range(44):
		var x := 50.0+float(i)*52.0
		draw_shrub(Vector2(x,350.0+float((i*7)%13)),i)
		draw_shrub(Vector2(x+15,702.0+float((i*5)%13)),i+11)
	# Environmental signposting, not tactical markers.
	draw_sign(Vector2(192,390),"UPPER RIDGE")
	draw_sign(Vector2(1960,666),"MALL DISTRICT")
	draw_exit()
	for x in range(105,2200,340):
		draw_tree(Vector2(float(x),48.0+float((x*3)%45)),x)
		draw_tree(Vector2(float(x)+92,960.0+float(x%31)),x+19)

func draw_lot(at: Vector2, index: int, north: bool) -> void:
	var w := 327.0
	var depth := 245.0
	var shadow := Rect2(at+Vector2(9,11),Vector2(w,depth))
	draw_rect(shadow,Color(0.09,0.11,0.14,0.31))
	draw_rect(Rect2(at,Vector2(w,depth)),Color("#687760"))
	draw_rect(Rect2(at+Vector2(5,6),Vector2(w-10,depth-12)),Color("#7b8570"))
	var roof := Rect2(at+Vector2(38,37),Vector2(238,148))
	draw_rect(Rect2(roof.position+Vector2(10,10),roof.size),Color("#292f36"))
	var colour: Color = PALETTE[index%PALETTE.size()]
	draw_rect(roof,colour.darkened(0.22))
	draw_rect(roof.grow(-5),colour)
	# Raised roof ridge and repeated tile lines keep top-down buildings legible.
	draw_line(Vector2(roof.position.x+12,roof.get_center().y),Vector2(roof.end.x-12,roof.get_center().y),colour.lightened(0.32),2.0)
	for r in range(5):
		draw_line(Vector2(roof.position.x+14,roof.position.y+18+r*24),Vector2(roof.end.x-14,roof.position.y+18+r*24),colour.darkened(0.12),1.0)
	draw_rect(Rect2(roof.position+Vector2(17,15),Vector2(60,31)),Color("#3e4d53"))
	draw_rect(Rect2(roof.position+Vector2(21,18),Vector2(52,25)),Color("#6e858d"))
	draw_rect(Rect2(roof.end-Vector2(57,52),Vector2(39,26)),Color("#b4aaa0"))
	draw_line(roof.position+Vector2(38,37),roof.end-Vector2(38,37),Color(1,1,1,0.13),1.0)
	var garden_y := at.y+210 if north else at.y+10
	for j in range(4):
		draw_shrub(Vector2(at.x+23.0+float(j)*81.0,garden_y),index*10+j)
	# Repeated boundary panels with an open driveway gap.
	var boundary_y := at.y+depth-6 if north else at.y+6
	for j in range(11):
		if j>=2 and j<=4:
			continue
		var start := at.x+float(j)*29.0
		draw_rect(Rect2(start,boundary_y,25,3),Color("#c7c5b5"))
	var gate_x := at.x+55
	draw_line(Vector2(gate_x,boundary_y-4),Vector2(gate_x+94,boundary_y-4),Color("#bbb09e"),1.5)
	draw_rect(Rect2(at.x+12,at.y+14,9,12),Color("#3e4d48"))
	draw_rect(Rect2(at.x+305,at.y+18,7,12),Color("#3e4d48"))
	# One carport silhouette, separated from the house roof.
	if index==2:
		var parking := Rect2(at+Vector2(278,45),Vector2(42,91))
		draw_rect(parking,Color("#3c444d"))
		draw_rect(parking.grow(-3),Color("#b0ada1"))
		draw_line(parking.position+Vector2(3,5),parking.end-Vector2(3,5),Color("#e2dfcf"),1.0)

func draw_car(r: Rect2, paint: Color) -> void:
	var p := r.position
	draw_rect(Rect2(p+Vector2(4,5),r.size),Color(0.07,0.08,0.11,0.40))
	for x in [15.0,79.0]:
		for y in [-5.0,40.0]:
			draw_rect(Rect2(p+Vector2(x,y),Vector2(14,8)),Color("#1c2229"))
	draw_rect(r,paint.darkened(0.3))
	draw_rect(r.grow(-3),paint)
	draw_rect(Rect2(p+Vector2(29,5),Vector2(47,33)),Color("#394750"))
	draw_rect(Rect2(p+Vector2(33,8),Vector2(36,27)),Color("#68818a"))
	draw_line(p+Vector2(77,6),p+Vector2(77,36),paint.lightened(0.36),1.5)
	draw_line(p+Vector2(6,6),p+Vector2(104,6),Color(1,1,1,0.22),1)
	draw_rect(Rect2(p+Vector2(1,7),Vector2(4,7)),Color("#d9b4a2"))
	draw_rect(Rect2(p+Vector2(103,29),Vector2(3,7)),Color("#e9dcc2"))

func draw_tree(p: Vector2, seed: int) -> void:
	var shift := float(seed%7)
	draw_circle(p+Vector2(8,9),27,Color(0.07,0.09,0.12,0.25))
	draw_circle(p,24,Color("#344f43"))
	draw_circle(p+Vector2(-6,3),16,Color("#597355"))
	draw_circle(p+Vector2(7,-6),13,Color("#668560"))
	draw_circle(p+Vector2(shift-3,8),10,Color("#415e4b"))

func draw_shrub(p: Vector2, seed: int) -> void:
	var hue := Color("#607c57") if seed%3==0 else Color("#526e50")
	draw_circle(p+Vector2(3,3),8,Color("#293d37"))
	draw_circle(p,7,hue)
	draw_circle(p+Vector2(-2,-2),3,hue.lightened(0.16))

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
