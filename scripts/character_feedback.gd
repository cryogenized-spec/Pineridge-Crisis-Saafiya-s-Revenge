extends Node2D
# Presentation-only character state player. No hit detection, target selection,
# weapon trajectories, damage tables, or coordinated attack logic.
var alert := ""
var caption := ""
var caption_time := 0.0
var alert_time := 0.0
var impact_marks: Array[Dictionary] = []
const MAX_IMPACTS := 4
func show_alert(symbol: String) -> void:
	alert = symbol if symbol in ["?","!"] else ""
	alert_time = 1.8 if not alert.is_empty() else 0.0

func show_caption(value: String) -> void:
	caption = value
	caption_time = 1.35
	queue_redraw()

func register_impact(local_point: Vector2, size: float = 1.0) -> void:
	impact_marks.append({"point": local_point, "radius": clampf(size,0.5,2.4)})
	while impact_marks.size() > MAX_IMPACTS:
		impact_marks.pop_front()
	queue_redraw()

func advance(delta: float) -> void:
	if alert_time <= 0.0 and caption_time <= 0.0:
		return
	alert_time = maxf(0.0, alert_time - delta)
	caption_time = maxf(0.0, caption_time - delta)
	queue_redraw()

func _draw() -> void:
	for impact in impact_marks:
		var p: Vector2 = impact["point"]
		var r: float = impact["radius"]
		draw_circle(p,r+0.8,Color(0.36,0.065,0.09,0.41),true,-1,true)
		draw_circle(p+Vector2(0.22,0.28),r*0.57,Color(0.16,0.025,0.05,0.55),true,-1,true)
	if alert_time > 0.0:
		var alpha := minf(1.0,alert_time*4.0)
		var center := Vector2(0,-20)
		draw_circle(center,6.5,Color(0.10,0.11,0.15,0.92*alpha),true,-1,true)
		draw_arc(center,6.5,0,TAU,32,Color(0.87,0.74,0.47,alpha),0.7,true)
		draw_string(ThemeDB.fallback_font,center+Vector2(-3.2,3.5),alert,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(0.96,0.86,0.67,alpha))

	if caption_time > 0.0 and not caption.is_empty():
		var fade := clampf(caption_time * 2.8,0.0,1.0)
		var width := maxf(25.0,float(caption.length())*5.7)
		var pos := Vector2(-width*0.5,-38.0)
		draw_rect(Rect2(pos,Vector2(width,12)),Color(0.10,0.10,0.15,fade*0.86),true)
		draw_string(ThemeDB.fallback_font,pos+Vector2(3,9),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color(0.97,0.91,0.81,fade))
