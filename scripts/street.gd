extends Node2D

const SIZE := Vector2(2320, 700)
const ROOFS := [Color("#8b7773"), Color("#797480"), Color("#7e7771")]
const AWNINGS := [Color("#85534f"), Color("#526e70"), Color("#9e7858")]
const SHOP_NAMES := ["HOME & MORE", "PINE RIDGE", "BAKERY", "RECORDS", "PHARMACY"]
var obstacles: Array[Rect2] = []

func _ready() -> void:
	# Scenic architecture is a backdrop, not an explorable building plan.
	obstacles.append(Rect2(0, 0, SIZE.x, 140))
	obstacles.append(Rect2(0, 550, SIZE.x, 150))
	for x in range(330, 2240, 342):
		obstacles.append(Rect2(x - 22, (460 if x >= 1000 or x % 2 else 239) - 13, 44, 26))
	queue_redraw()

func blocked(p: Vector2, radius: float = 7.0) -> bool:
	if p.x < radius or p.y < radius or p.x > SIZE.x - radius or p.y > SIZE.y - radius:
		return true
	for r in obstacles:
		if r.grow(radius).has_point(p):
			return true
	return false

func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 123456
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color("#625c64"))
	draw_rect(Rect2(0, 208, SIZE.x, 284), Color("#43434d"))
	for i in range(17000):
		var p := Vector2(rng.randf_range(0, SIZE.x), rng.randf_range(0, SIZE.y))
		var c := Color(0.8, 0.74, 0.69, rng.randf_range(0.025, 0.10))
		if i % 2 == 0:
			c = Color(0.12, 0.10, 0.15, rng.randf_range(0.03, 0.13))
		draw_line(p, p + Vector2(rng.randf_range(0.6, 3.8), 0), c, 0.65, true)
	for x in range(0, 2320, 24):
		draw_rect(Rect2(x, 204, 23, 4), Color("#b0a297"))
		draw_rect(Rect2(x, 492, 23, 4), Color("#b0a297"))
		if x % 48 == 0:
			draw_rect(Rect2(x, 349, 22, 2), Color("#b6a580"))
	# Fictional retail district: distant architecture and a landscaped foreground.
	retail_backdrop(rng)
	draw_rect(Rect2(0, 550, SIZE.x, 150), Color("#344943"))
	draw_rect(Rect2(0, 553, SIZE.x, 8), Color("#819083"))
	draw_rect(Rect2(0, 680, SIZE.x, 20), Color("#293d38"))
	for x in range(0, 2320, 24):
		var p := Vector2(x + rng.randf_range(-9, 9), rng.randf_range(573, 675))
		draw_circle(p + Vector2(5, 4), rng.randf_range(10, 18), Color(0.08,0.14,0.13,0.30), true, -1, true)
		draw_circle(p, rng.randf_range(8, 16), Color("#536e53").lightened(rng.randf_range(-0.20, 0.15)), true, -1, true)
	for x in range(90, 2320, 117):
		tree(Vector2(x, 600 + rng.randf_range(-15, 40)), rng)
	for x in range(330, 2240, 342):
		car(Vector2(x, 460 if x >= 1000 or x % 2 else 239), [Color("#ab6758"), Color("#919497"), Color("#758580")][int(x / 342) % 3])
	for x in range(80, 2320, 218):
		tree(Vector2(x, 181), rng)
		tree(Vector2(x + 30, 519), rng)

func retail_backdrop(rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(0, 0, SIZE.x, 146), Color("#4d515b"))
	for i in range(9):
		var x := i * 267.0
		var top := -15.0 + rng.randf_range(0, 15)
		draw_rect(Rect2(x + 8, top + 8, 257, 115), Color("#33353f"))
		draw_rect(Rect2(x, top, 257, 115), Color("#8b8583"))
		draw_rect(Rect2(x + 5, top + 5, 247, 100), Color("#626c78"))
		# Broad skylight forms, deliberately non-navigable architectural scenery.
		draw_rect(Rect2(x + 32, top + 19, 192, 50), Color("#394a58"))
		for j in range(9):
			draw_rect(Rect2(x + 34 + j * 21, top + 21, 18, 46), Color("#6a8593").lightened(rng.randf_range(-0.10, 0.13)))
		draw_rect(Rect2(x + 5, top + 101, 247, 10), Color("#a89e91"))
	draw_rect(Rect2(0, 142, SIZE.x, 19), Color("#546b55"))
	for x in range(0, 2320, 13):
		draw_circle(Vector2(x, 150 + rng.randf_range(-4, 4)), 6, Color("#63785e").darkened(rng.randf_range(0, 0.18)), true, -1, true)
	draw_line(Vector2(0, 165), Vector2(SIZE.x, 165), Color("#a49b8b"), 3)

func roof(r: Rect2, index: int, top: bool) -> void:
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color("#39343e"))
	draw_rect(r, Color("#5f535a"))
	var inner := r.grow(-3)
	draw_rect(inner, ROOFS[index % ROOFS.size()])
	for i in range(10, 139, 8):
		draw_line(r.position + Vector2(i, 5), r.position + Vector2(i, r.size.y - 5), Color(0.22,0.16,0.21,0.30), 0.7, true)
		draw_line(r.position + Vector2(i+1, 5), r.position + Vector2(i+1, r.size.y - 5), Color(0.95,0.82,0.71,0.12), 0.7, true)
	var vent := r.position + Vector2(16,23)
	draw_rect(Rect2(vent + Vector2(3,4),Vector2(32,22)),Color("#57515a"))
	draw_rect(Rect2(vent,Vector2(32,22)),Color("#a0948c"))
	draw_circle(vent+Vector2(16,11),8,Color("#605b63"),true,-1,true)
	for j in range(4):
		draw_line(vent+Vector2(9,6+j*3),vent+Vector2(23,6+j*3),Color("#938781"),1,true)
	var ay := r.end.y - 14 if top else r.position.y
	draw_rect(Rect2(r.position.x+5,ay,138,14),AWNINGS[index%3])
	draw_string(ThemeDB.fallback_font,Vector2(r.position.x+14,ay+11),SHOP_NAMES[index%5],HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("#efdfbb"))

func barrier(r: Rect2) -> void:
	draw_rect(Rect2(r.position+Vector2(3,4),r.size),Color("#39343e"))
	draw_rect(r,Color("#867e7a"))
	draw_line(r.position+Vector2(1,1),r.position+Vector2(r.size.x-1,1),Color("#c1afa0"),1.5,true)
	for i in range(4,int(r.size.x)-4,12):
		draw_rect(Rect2(r.position+Vector2(i,r.size.y-4),Vector2(6,2)),Color("#d4a25b"))

func car(p: Vector2,c: Color) -> void:
	draw_set_transform(p)
	draw_rect(Rect2(-21,-9,46,25),Color(0.08,0.07,0.1,0.4))
	for x in [-14,13]:
		for y in [-12,10]:
			draw_rect(Rect2(x,y,7,3),Color("#22202a"))
	draw_rect(Rect2(-22,-11,44,22),c.darkened(0.25))
	draw_rect(Rect2(-19,-13,37,26),c)
	draw_rect(Rect2(-13,-10,7,20),Color("#343c4a"))
	draw_rect(Rect2(6,-10,9,20),Color("#343c4a"))
	draw_rect(Rect2(-6,-9,12,18),c.lightened(0.12))
	draw_line(Vector2(-18,-11),Vector2(17,-11),c.lightened(0.45),1,true)
	draw_line(Vector2(8,-9),Vector2(8,8),Color("#919eaa"),0.8,true)
	for y in [-8,5]:
		draw_rect(Rect2(20,y,2,4),Color("#ffdb99"))
		draw_rect(Rect2(-22,y,2,4),Color("#b85d61"))
	draw_set_transform(Vector2.ZERO)

func tree(p:Vector2,rng:RandomNumberGenerator) -> void:
	draw_rect(Rect2(p-Vector2(9,9),Vector2(19,18)),Color("#93877b"))
	draw_circle(p+Vector2(6,7),13,Color(0.12,0.10,0.16,0.35),true,-1,true)
	draw_circle(p,12,Color("#475c54"),true,-1,true)
	for i in range(12):
		var off := Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(1,9)
		draw_circle(p+off,rng.randf_range(3,6),Color("#687961").lightened(rng.randf_range(-0.2,0.18)),true,-1,true)
