extends Node2D
# Presentation-only particles. No ballistic or hit simulation is performed here.
var motes: Array[Dictionary] = []
var decals: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var pulse_time := 0.0
var pulse_origin := Vector2.ZERO
var marker_visible := true
var marker_position := Vector2(2060,350)

func burst(origin: Vector2) -> void:
	pulse_origin = origin
	pulse_time = 0.14
	for i in range(18):
		motes.append({"p":origin,"v":Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(12,66),"life":rng.randf_range(0.15,0.4),"max":0.4,"kind":0,"angle":rng.randf_range(0,TAU)})
	for i in range(5):
		motes.append({"p":origin,"v":Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(8,24),"life":0.85,"max":0.85,"kind":1,"angle":rng.randf_range(0,TAU)})
	for i in range(4):
		motes.append({"p":origin,"v":Vector2.from_angle(rng.randf_range(0,TAU))*rng.randf_range(10,24),"life":1.1,"max":1.1,"kind":2,"angle":rng.randf_range(0,TAU)})
	decals.append({"p":origin+Vector2(0,9),"r":rng.randf_range(2,4)})
	if decals.size()>80:
		decals.pop_front()

func _process(delta:float) -> void:
	pulse_time=maxf(0,pulse_time-delta)
	for i in range(motes.size()-1,-1,-1):
		var m := motes[i]
		m.life-=delta
		if m.life<=0:
			motes.remove_at(i)
			continue
		m.p+=m.v*delta
		m.v*=exp(-delta*3)
		m.angle+=delta*5
	if pulse_time > 0.0 or not motes.is_empty():
		queue_redraw()

func _draw() -> void:
	if marker_visible:
		draw_arc(marker_position,18,0,TAU,48,Color(0.96,0.78,0.47,0.85),1.4,true)
		draw_circle(marker_position,4,Color(0.96,0.78,0.47,0.85),true,-1,true)
	for mark in decals:
		draw_circle(mark.p,mark.r,Color(0.36,0.10,0.19,0.30),true,-1,true)
	if pulse_time>0:
		var alpha := pulse_time/0.14
		draw_circle(pulse_origin,13*(1-alpha)+3,Color(1,0.62,0.22,alpha*0.12),true,-1,true)
		draw_circle(pulse_origin,3.5,Color(1,0.90,0.65,alpha),true,-1,true)
	for m in motes:
		var a:float=clampf(m.life/m.max,0,1)
		match m.kind:
			0:
				draw_line(m.p,m.p-m.v*0.045,Color(1,0.75,0.35,a),1,true)
			1:
				draw_circle(m.p,2.5+(1-a)*5,Color(0.52,0.49,0.57,a*0.20),true,-1,true)
			2:
				draw_set_transform(m.p,m.angle)
				draw_rect(Rect2(-1.8,-0.65,3.6,1.3),Color(0.83,0.63,0.28,a))
				draw_line(Vector2(-1.4,-0.4),Vector2(1.4,-0.4),Color(1,0.86,0.52,a),0.5,true)
				draw_set_transform(Vector2.ZERO)
