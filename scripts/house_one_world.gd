extends Node2D
# Segment 2: fictional house exterior near Pine Ridge mall.
# Orthographic overhead scenery, approximately 24 display pixels/metre.
const SIZE := Vector2(2320.0,1024.0)
const ROAD_TOP := 405.0
const ROAD_BOTTOM := 679.0
const GATE_POINT := Vector2(1365.0,427.0)
const EXIT_POINT := Vector2(2172.0,545.0)
const CAR_LENGTH := 108.0
const CAR_WIDTH := 43.0
const YARD := Rect2(958.0,278.0,714.0,131.0)
const ROOF := Rect2(1048.0,75.0,515.0,208.0)
const CAR_A := Rect2(1048.0,320.0,CAR_LENGTH,CAR_WIDTH)
const CAR_B := Rect2(1180.0,320.0,CAR_LENGTH,CAR_WIDTH)
const STREET_CAR := Rect2(475.0,684.0,CAR_LENGTH,CAR_WIDTH)
var road_texture: ImageTexture
var solid: Array[Rect2] = []

func _ready() -> void:
	create_road_texture()
	solid = [
		CAR_A,CAR_B,STREET_CAR,
		Rect2(958,393,375,11),
		Rect2(1400,393,272,11),
		Rect2(958,278,9,126),
		Rect2(1663,278,9,126)
	]
	queue_redraw()

func create_road_texture() -> void:
	var image := Image.create(128,128,false,Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var rng := RandomNumberGenerator.new()
	rng.seed = 814672
	for i in range(1680):
		var x := rng.randi_range(0,127)
		var y := rng.randi_range(0,127)
		var v := rng.randf_range(0.28,0.72)
		image.set_pixel(x,y,Color(v,v*0.95,v*0.90,rng.randf_range(0.04,0.15)))
	road_texture=ImageTexture.create_from_image(image)
	texture_repeat=CanvasItem.TEXTURE_REPEAT_ENABLED

func blocked(p: Vector2, radius: float = 7.0) -> bool:
	if p.x < radius or p.x > SIZE.x-radius:
		return true
	var on_street: bool = p.y >= ROAD_TOP-22.0+radius and p.y <= ROAD_BOTTOM+25.0-radius
	var in_yard: bool = YARD.grow(-radius).has_point(p)
	if not (on_street or in_yard):
		return true
	for r in solid:
		if r.grow(radius).has_point(p):
			return true
	return false

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO,SIZE),Color("#405646"))
	draw_rect(Rect2(0,0,SIZE.x,382),Color("#66765e"))
	draw_rect(Rect2(0,706,SIZE.x,318),Color("#617156"))
	draw_rect(Rect2(0,ROAD_TOP-23,SIZE.x,ROAD_BOTTOM-ROAD_TOP+48),Color("#a8a49c"))
	draw_rect(Rect2(0,ROAD_TOP,SIZE.x,ROAD_BOTTOM-ROAD_TOP),Color("#434650"))
	if road_texture!=null:
		draw_texture_rect(road_texture,Rect2(0,ROAD_TOP,SIZE.x,ROAD_BOTTOM-ROAD_TOP),true)
	draw_rect(Rect2(0,386,SIZE.x,15),Color("#c5beb3"))
	draw_rect(Rect2(0,682,SIZE.x,15),Color("#c5beb3"))
	for x in range(20,2260,102):
		draw_rect(Rect2(x,540,48,2),Color("#cfc3a6"))
	for i in range(17):
		var x := float(i)*146.0
		draw_line(Vector2(x,35),Vector2(x+60,302),Color(0.86,0.81,0.65,0.055),1)
		draw_line(Vector2(x+42,776),Vector2(x+105,995),Color(0.85,0.82,0.7,0.05),1)
	draw_decorative_home(Vector2(105,66),Color("#817477"),"RIDGE VIEW")
	draw_decorative_home(Vector2(520,83),Color("#7d8988"),"HILLSIDE")
	draw_decorative_home(Vector2(1790,64),Color("#9d8c7d"),"ROSE COTTAGE")
	draw_decorative_home(Vector2(300,765),Color("#7d8276"),"")
	draw_decorative_home(Vector2(1540,768),Color("#8d8586"),"")
	draw_primary_property()
	draw_car(STREET_CAR,Color("#8f8982"))
	draw_sign(Vector2(180,410),"PINE RIDGE")
	draw_sign(Vector2(1885,697),"MALL ROUTE")
	for i in range(46):
		var px := 25.0+float(i)*50.0
		shrub(Vector2(px,369),i)
		shrub(Vector2(px+16,720),i+17)
	for i in range(7):
		tree(Vector2(148.0+float(i)*330.0,912.0+float((i*7)%45)))
	draw_marker(GATE_POINT,Color("#edc57a"),"CHECK THE HOUSE")
	draw_marker(EXIT_POINT,Color("#a4dbc7"),"NEXT BLOCK")

func draw_primary_property() -> void:
	# Closed house, defensive shutters and family presence are told through
	# symbols, not a detailed route through private rooms.
	draw_rect(Rect2(947,65,739,350),Color(0.07,0.10,0.09,0.3))
	draw_rect(Rect2(951,67,725,340),Color("#6e7e63"))
	draw_rect(Rect2(964,82,700,315),Color("#80906f"))
	for j in range(9):
		var px := 975.0+float(j)*78.0
		shrub(Vector2(px,292),j+25)
		draw_line(Vector2(px,68),Vector2(px+24,68),Color("#b2b3a7"),2)
	draw_rect(Rect2(ROOF.position+Vector2(12,13),ROOF.size),Color("#2d353a"))
	draw_rect(ROOF,Color("#5f6872"))
	draw_rect(ROOF.grow(-6),Color("#7c8590"))
	# Roof planes and a large overhead ridge.
	draw_line(Vector2(ROOF.position.x+17,180),Vector2(ROOF.end.x-17,180),Color("#c0bec0"),3)
	for r in range(1,7):
		var py := ROOF.position.y+float(r)*27.0
		draw_line(Vector2(ROOF.position.x+12,py),Vector2(ROOF.end.x-12,py),Color(0.18,0.2,0.23,0.29),1)
	for win in [Rect2(1090,220,62,23),Rect2(1421,221,68,23)]:
		draw_rect(win,Color("#30373e"))
		draw_rect(win.grow(-3),Color("#adb5a5"))
		for j in range(4):
			draw_line(win.position+Vector2(6+j*14,2),win.position+Vector2(6+j*14,21),Color("#59635f"),2)
	draw_rect(Rect2(1250,259,72,19),Color("#4b5053"))
	draw_line(Vector2(1285,261),Vector2(1285,277),Color("#c9c7b8"),1)
	draw_rect(Rect2(1045,284,277,106),Color(0.58,0.59,0.55,0.23))
	# Two separately proportioned vehicles beneath an open steel carport.
	draw_rect(Rect2(1028,303,282,87),Color("#a4a99f"))
	for x in [1033.0,1296.0]:
		for y in [305.0,387.0]:
			draw_rect(Rect2(x,y,5,5),Color("#444b51"))
	draw_line(Vector2(1034,305),Vector2(1298,305),Color("#eaebdf"),2)
	draw_line(Vector2(1034,387),Vector2(1298,387),Color("#e1e2d8"),2)
	draw_line(Vector2(1078,305),Vector2(1078,387),Color("#bfc5ba"),1)
	draw_line(Vector2(1230,305),Vector2(1230,387),Color("#bfc5ba"),1)
	draw_car(CAR_A,Color("#a1a8ad"))
	draw_car(CAR_B,Color("#a06c62"))
	# A gate opening and loose domestic objects establish the story visually.
	draw_fence()
	draw_rect(Rect2(1482,351,24,21),Color("#66746e"))
	draw_rect(Rect2(1486,347,16,5),Color("#c6bda9"))
	draw_rect(Rect2(1535,355,22,19),Color("#39474a"))
	draw_rect(Rect2(1538,352,16,4),Color("#a8b5b5"))
	draw_rect(Rect2(1592,350,23,14),Color("#c09a76"))
	draw_rect(Rect2(1596,346,15,6),Color("#a77b68"))
	draw_line(Vector2(1556,365),Vector2(1588,361),Color("#d9c7a7"),1.5)
	draw_rect(Rect2(1592,286,20,14),Color("#667b67"))
	shrub(Vector2(1625,324),13)
	# Occupied-home sign is deliberately legible at steep top-down.
	draw_rect(Rect2(1402,294,172,26),Color("#414a44"))
	draw_string(ThemeDB.fallback_font,Vector2(1409,312),"FAMILY INSIDE",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("#e9dcbf"))
	draw_rect(Rect2(1407,276,163,12),Color("#d1c7ac"))
	draw_string(ThemeDB.fallback_font,Vector2(1413,286),"DO NOT ENTER",HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("#4b403f"))

func draw_fence() -> void:
	for x in range(956,1333,16):
		draw_line(Vector2(x,393),Vector2(x,404),Color("#c8c8ba"),1.4)
	for x in range(1400,1674,16):
		draw_line(Vector2(x,393),Vector2(x,404),Color("#c8c8ba"),1.4)
	draw_line(Vector2(957,400),Vector2(1332,400),Color("#bcbeb2"),2)
	draw_line(Vector2(1400,400),Vector2(1673,400),Color("#bcbeb2"),2)
	draw_rect(Rect2(1332,393,7,14),Color("#c3c6bb"))
	draw_rect(Rect2(1393,393,7,14),Color("#c3c6bb"))
	draw_line(Vector2(1339,405),Vector2(1372,394),Color("#a7b2a7"),1.3)
	draw_line(Vector2(1372,394),Vector2(1393,405),Color("#a7b2a7"),1.3)
	draw_line(Vector2(956,278),Vector2(956,405),Color("#d2ccbe"),3)
	draw_line(Vector2(1674,278),Vector2(1674,405),Color("#d2ccbe"),3)

func draw_decorative_home(at: Vector2, colour: Color, words: String) -> void:
	var footprint := Rect2(at+Vector2(11,9),Vector2(318,203))
	draw_rect(footprint,Color("#2c3536"))
	var roof := Rect2(at,Vector2(318,203))
	draw_rect(roof,colour.darkened(0.17))
	draw_rect(roof.grow(-6),colour)
	draw_line(Vector2(at.x+22,at.y+98),Vector2(at.x+294,at.y+98),colour.lightened(0.32),2)
	for i in range(3):
		var px := at.x+45.0+float(i)*93.0
		draw_rect(Rect2(px,at.y+134,55,25),Color("#454e54"))
		draw_rect(Rect2(px+5,at.y+138,45,16),Color("#7c9291"))
		draw_line(Vector2(px+27,at.y+136),Vector2(px+27,at.y+157),Color("#d2c7b9"),1)
	if words != "":
		draw_rect(Rect2(at.x+17,at.y+184,130,14),Color("#444b46"))
		draw_string(ThemeDB.fallback_font,at+Vector2(22,195),words,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#e6dac5"))
	for i in range(6):
		shrub(at+Vector2(16.0+float(i)*55.0,220),i+5)

func draw_car(rect: Rect2, colour: Color) -> void:
	var p := rect.position
	draw_rect(Rect2(p+Vector2(3,4),rect.size),Color(0.08,0.09,0.12,0.39))
	draw_rect(rect,colour.darkened(0.28))
	draw_rect(rect.grow(-3),colour)
	for x in [13.0,87.0]:
		for y in [-4.0,39.0]:
			draw_rect(Rect2(p+Vector2(x,y),Vector2(11,7)),Color("#222830"))
	draw_rect(Rect2(p+Vector2(28,5),Vector2(53,32)),Color("#38474c"))
	draw_rect(Rect2(p+Vector2(32,8),Vector2(45,25)),Color("#7f99a1"))
	draw_line(p+Vector2(77,7),p+Vector2(77,36),colour.lightened(0.34),1.4)
	draw_rect(Rect2(p+Vector2(2,10),Vector2(4,6)),Color("#eed2b5"))
	draw_rect(Rect2(p+Vector2(101,29),Vector2(4,6)),Color("#be6b65"))

func shrub(p: Vector2, index: int) -> void:
	var hue := Color("#6f8667") if index%3==0 else Color("#526f5b")
	draw_circle(p+Vector2(4,4),8,Color(0.11,0.16,0.14,0.22))
	draw_circle(p,7,hue)
	draw_circle(p+Vector2(-2,-2),3,hue.lightened(0.13))

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
