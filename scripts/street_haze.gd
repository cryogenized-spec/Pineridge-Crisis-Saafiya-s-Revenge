extends Node2D
## Cull and update the browser haze independently of the road scenery.
const SMOKE := preload("res://assets/fx/weapon_art/smoke.png")
var origins := PackedVector2Array()
var avatar: Node2D
var clock := 0.0
var last_draw := 0.0

func _process(delta: float) -> void:
	if not visible:
		return
	clock += delta
	if clock - last_draw >= 1.0 / 24.0:
		last_draw = clock
		queue_redraw()

func _draw() -> void:
	if not is_instance_valid(avatar):
		return
	for j in range(origins.size()):
		var origin := origins[j]
		if absf(origin.x - avatar.position.x) > 430.0:
			continue
		for i in range(4):
			var t := fposmod(clock * .26 + float(i) * .25 + float(j) * .13, 1.0)
			var drift := Vector2(22.0*t + sin(t*8.0 + float(j))*9.0*t, -74.0*t)
			var size := Vector2.ONE * (19.0 + 65.0*t)
			draw_texture_rect(SMOKE, Rect2(origin + drift - size * .5, size), false,
				Color(.30, .29, .29, sin(PI*t) * .42))
