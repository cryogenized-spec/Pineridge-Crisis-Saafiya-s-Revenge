extends Control
## A custom-scaled bronze digital counter. The two numeric groups always fit
## inside the ornamental HUD's right inset; it needs no external font file.
var current_rounds := 0
var magazine_reserve := 0
var is_reloading := false
var firearm := true
const ON := Color("#f7d4a5")
const GLOW := Color("#c77e51")
const OFF := Color(0.23,0.15,0.16,0.63)
const SEGMENTS := {
	"0": [0,1,2,3,4,5], "1": [1,2], "2": [0,1,6,4,3],
	"3": [0,1,6,2,3], "4": [5,6,1,2], "5": [0,5,6,2,3],
	"6": [0,5,6,4,3,2], "7": [0,1,2],
	"8": [0,1,2,3,4,5,6], "9": [0,1,2,3,5,6],
	"-": [6]
}

func set_values(round_count: int, reserve_count: int, reloading: bool, has_ammo: bool) -> void:
	if current_rounds == round_count and magazine_reserve == reserve_count and is_reloading == reloading and firearm == has_ammo:
		return
	current_rounds = round_count
	magazine_reserve = reserve_count
	is_reloading = reloading
	firearm = has_ammo
	queue_redraw()

func _draw() -> void:
	if not firearm:
		return
	var area := size
	if area.x < 10 or area.y < 10:
		return
	var rounds_text := str(maxi(0,current_rounds)).pad_zeros(2)
	var mags_text := str(maxi(0,magazine_reserve)).pad_zeros(2)
	# Compact groups are dimensioned from the real available drawing width.
	var cells := rounds_text.length() + mags_text.length()
	var unit := minf(area.x / (float(cells) * 1.18 + 0.95),area.y * 0.53)
	var height := unit * 1.5
	var gap := unit * 0.18
	var separator_width := unit * 0.65
	var total := float(cells) * unit + float(cells - 2) * gap + separator_width + unit * 0.32
	var x := (area.x - total) / 2.0
	var y := (area.y - height) * 0.38
	var lit := GLOW if is_reloading else ON
	for digit in rounds_text:
		_draw_digit(digit, Vector2(x,y),unit,height,lit)
		x += unit + gap
	x += separator_width * 0.28
	var mid_y := y + height * 0.5
	draw_line(Vector2(x,mid_y+unit*0.12),Vector2(x+unit*0.35,mid_y-unit*0.12),Color("#b48e77"),maxf(1.2,unit*0.08),true)
	x += separator_width
	for digit in mags_text:
		_draw_digit(digit,Vector2(x,y),unit,height,lit)
		x += unit + gap

func _draw_digit(number: String, p: Vector2, w: float, h: float, lit: Color) -> void:
	var start := [
		[Vector2(.21,.07),Vector2(.79,.07)],
		[Vector2(.86,.12),Vector2(.86,.44)],
		[Vector2(.86,.56),Vector2(.86,.88)],
		[Vector2(.21,.93),Vector2(.79,.93)],
		[Vector2(.14,.56),Vector2(.14,.88)],
		[Vector2(.14,.12),Vector2(.14,.44)],
		[Vector2(.21,.50),Vector2(.79,.50)]
	]
	var active: Array = SEGMENTS.get(number, [])
	var thick := maxf(1.1,w*0.13)
	for i in range(7):
		var one: Vector2 = p+start[i][0]*Vector2(w,h)
		var two: Vector2 = p+start[i][1]*Vector2(w,h)
		draw_line(one,two,OFF,thick,true)
		if i in active:
			draw_line(one,two,Color(GLOW.r,GLOW.g,GLOW.b,0.44),thick*2.0,true)
			draw_line(one,two,lit,thick*0.72,true)
