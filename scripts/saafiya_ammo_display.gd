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

func _ready() -> void:
	resized.connect(queue_redraw)

func set_values(round_count: int, reserve_count: int, reloading: bool, has_ammo: bool) -> void:
	if current_rounds == round_count and magazine_reserve == reserve_count and is_reloading == reloading and firearm == has_ammo:
		return
	current_rounds = round_count
	magazine_reserve = reserve_count
	is_reloading = reloading
	firearm = has_ammo
	queue_redraw()

func counter_bounds(area: Vector2, rounds_text: String, reserve_text: String) -> Rect2:
	var cells := rounds_text.length() + reserve_text.length()
	var width_in_cells := 1.18 * float(cells - 2) + 2.0 + 0.72
	var unit := minf(area.x * 0.96 / width_in_cells, area.y * 0.56)
	var total := Vector2(unit * width_in_cells, unit * 1.5)
	return Rect2((area - total) * 0.5, total)

func _draw() -> void:
	if not firearm or size.x < 10 or size.y < 10:
		return
	var rounds_text := str(maxi(0, current_rounds)).pad_zeros(2)
	var reserve_text := str(maxi(0, magazine_reserve)).pad_zeros(2)
	var bounds := counter_bounds(size, rounds_text, reserve_text)
	var unit := bounds.size.y / 1.5
	var cursor := bounds.position
	var lit := GLOW if is_reloading else ON
	for digit in rounds_text:
		_draw_digit(digit, cursor, unit, bounds.size.y, lit)
		cursor.x += unit * 1.18
	var slash := cursor + Vector2(0.04 * unit, bounds.size.y * 0.5)
	draw_line(slash + Vector2(0, unit * 0.24), slash + Vector2(unit * 0.25, -unit * 0.24),
		Color("#b48e77"), unit * 0.08, true)
	cursor.x += unit * 0.54
	for digit in reserve_text:
		_draw_digit(digit, cursor, unit, bounds.size.y, lit)
		cursor.x += unit * 1.18

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
	var thick := w * 0.12
	for i in range(7):
		var one: Vector2 = p+start[i][0]*Vector2(w,h)
		var two: Vector2 = p+start[i][1]*Vector2(w,h)
		draw_line(one,two,OFF,thick,true)
		if i in active:
			draw_line(one,two,Color(GLOW.r,GLOW.g,GLOW.b,0.44),thick*2.0,true)
			draw_line(one,two,lit,thick*0.72,true)
