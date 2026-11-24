extends Node2D
# Presentation-only character state player. No hit detection, target selection,
# weapon trajectories, damage tables, or coordinated attack logic.
enum State { IDLE, WALK, RUN, PICKUP, CARRY, SET_DOWN, STARTLED, STUMBLE, DOWN }
var state: State = State.IDLE
var time := 0.0
var alert := ""
var caption := ""
var caption_time := 0.0
var alert_time := 0.0
var marked := false
var blood_enabled := true
var carried := false
const LENGTHS := {State.PICKUP:0.8,State.SET_DOWN:0.8,State.STARTLED:0.48,State.STUMBLE:0.6,State.DOWN:0.85}

func select(next: State) -> void:
	state = next
	time = 0.0
	if next == State.PICKUP:
		carried = false
	elif next == State.CARRY or next == State.SET_DOWN:
		carried = true

func show_alert(symbol: String) -> void:
	alert = symbol if symbol in ["?","!"] else ""
	alert_time = 1.8 if not alert.is_empty() else 0.0

func show_caption(value: String) -> void:
	caption = value
	caption_time = 1.35
	queue_redraw()

func reset() -> void:
	select(State.IDLE)
	carried = false
	marked = false
	alert = ""
	alert_time = 0.0
	caption = ""
	caption_time = 0.0

func advance(delta: float) -> void:
	time += delta
	alert_time = maxf(0.0,alert_time-delta)
	caption_time = maxf(0.0,caption_time-delta)
	if state == State.PICKUP and time >= LENGTHS[State.PICKUP]:
		select(State.CARRY)
	elif state == State.SET_DOWN and time >= LENGTHS[State.SET_DOWN]:
		carried = false
		select(State.IDLE)
	elif state in [State.STARTLED,State.STUMBLE] and time >= float(LENGTHS[state]):
		select(State.CARRY if carried else State.IDLE)
	queue_redraw()

func progress() -> float:
	return clampf(time/float(LENGTHS.get(state,1.0)),0.0,1.0)

func pose() -> Dictionary:
	var t := progress()
	var factor := 1.0
	var tilt := 0.0
	var offset := Vector2.ZERO
	match state:
		State.PICKUP, State.SET_DOWN:
			factor = 1.0-0.22*sin(PI*t)
			offset = Vector2(0,3)*sin(PI*t)
		State.STARTLED:
			factor = 1.0+0.10*sin(PI*t)
			offset = Vector2(0,-2)*sin(PI*t)
		State.STUMBLE:
			tilt = 0.16*sin(TAU*t)*(1.0-t)
			offset = Vector2(2,1)*sin(PI*t)
		State.DOWN:
			var ease := smoothstep(0.0,1.0,t)
			tilt = ease*1.0
			factor = lerpf(1.0,0.72,ease)
			offset = Vector2(4,4)*ease
	return {"scale":factor,"rotation":tilt,"offset":offset}

func _draw() -> void:
	if marked and blood_enabled:
		# Small, non-graphic cinematic colour decal.
		draw_circle(Vector2(5,4),4,Color(0.38,0.10,0.16,0.36),true,-1,true)
		draw_circle(Vector2(8,6),1.8,Color(0.38,0.10,0.16,0.25),true,-1,true)
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
