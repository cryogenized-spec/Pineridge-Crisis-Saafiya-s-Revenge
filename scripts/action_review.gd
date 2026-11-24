extends Node2D
const Actor = preload("res://scripts/actor.gd")
const Props = preload("res://scripts/prop_library.gd")
const Feedback = preload("res://scripts/character_feedback.gd")
const Audio = preload("res://scripts/preview_audio.gd")
var actor: Actor
var feedback: Feedback
var audio: Audio
var accessory := Sprite2D.new()
var prop_index := 0
var wardrobe := 0
var fall_backward := false
var heading := 0.0
var status: Label
var smoke := false
var clock := 0.0
var test_step := 0
const CARRY_IDS := ["carton","bag","phone","brick","bottle"]
const CENTER := Vector2(410,350)

func _ready() -> void:
	smoke = "--action-smoke" in OS.get_cmdline_user_args()
	feedback = Feedback.new()
	feedback.position = CENTER
	feedback.scale = Vector2.ONE*6.0
	add_child(feedback)
	feedback.z_index = 2
	audio = Audio.new()
	add_child(audio)
	make_actor()
	add_child(accessory)
	accessory.z_index = 3
	status = Label.new()
	status.position = Vector2(34,85)
	status.add_theme_font_size_override("font_size",19)
	add_child(status)
	refresh()

func make_actor() -> void:
	if is_instance_valid(actor):
		actor.queue_free()
	actor = Actor.new()
	actor.wardrobe_index = wardrobe
	actor.fall_backward = fall_backward
	actor.position = CENTER
	actor.scale = Vector2.ONE*6.0
	add_child(actor)
	actor.z_index = 1

func refresh() -> void:
	status.text = "Look %02d   |   %s   |   Prop: %s   |   Fall: %s   |   Decals: %s" % [wardrobe+1,Feedback.State.keys()[feedback.state],Props.ITEMS[prop_index].label,"BACK" if fall_backward else "FRONT","ON" if feedback.blood_enabled else "OFF"]
	queue_redraw()

func change_state(next: Feedback.State, cue: String = "") -> void:
	feedback.select(next)
	if not cue.is_empty():
		audio.play_cue(cue)
	refresh()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: change_state(Feedback.State.IDLE)
		KEY_2: change_state(Feedback.State.WALK)
		KEY_3: change_state(Feedback.State.RUN)
		KEY_4:
			if Props.ITEMS[prop_index].id in CARRY_IDS:
				change_state(Feedback.State.PICKUP,"pickup")
		KEY_5:
			if feedback.carried:
				change_state(Feedback.State.SET_DOWN,"set_down")
		KEY_6:
			feedback.show_alert("?")
			change_state(Feedback.State.STARTLED,"alert")
		KEY_7:
			feedback.show_alert("!")
			change_state(Feedback.State.STUMBLE,"reaction")
		KEY_8:
			feedback.marked = true
			change_state(Feedback.State.DOWN,"reaction")
		KEY_B: feedback.blood_enabled = not feedback.blood_enabled
		KEY_N:
			fall_backward = not fall_backward
			actor.fall_backward = fall_backward
			if feedback.state==Feedback.State.DOWN:
				feedback.select(Feedback.State.DOWN)
		KEY_R:
			feedback.reset()
			audio.play_cue("reset")
		KEY_LEFT: heading -= PI/4.0
		KEY_RIGHT: heading += PI/4.0
		KEY_UP:
			wardrobe = posmod(wardrobe+1,12)
			make_actor()
		KEY_DOWN:
			wardrobe = posmod(wardrobe-1,12)
			make_actor()
		KEY_P:
			prop_index = posmod(prop_index+1,Props.ITEMS.size())
			feedback.carried = false
			feedback.select(Feedback.State.IDLE)
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	refresh()

func _physics_process(delta: float) -> void:
	clock += delta
	feedback.advance(delta)
	var moving := feedback.state in [Feedback.State.WALK,Feedback.State.RUN]
	var running := feedback.state == Feedback.State.RUN
	var speed := 148.0 if running else 91.0
	actor.animate(delta,Vector2.from_angle(heading)*speed*delta if moving else Vector2.ZERO,heading,false,running)
	var pose := feedback.pose()
	actor.set_down_progress(feedback.progress() if feedback.state==Feedback.State.DOWN else -1.0)
	if feedback.state==Feedback.State.DOWN and (actor.npc_down!=null or actor.npc_down_back!=null):
		actor.scale=Vector2.ONE*6.0
		actor.rotation=0.0
		actor.position=CENTER
	else:
		actor.scale = Vector2.ONE*6.0*float(pose.scale)
		actor.rotation = float(pose.rotation)
		actor.position = CENTER+Vector2(pose.offset)*6.0
	var item: Dictionary = Props.ITEMS[prop_index]
	accessory.visible = item.id in CARRY_IDS
	accessory.texture = item.texture
	accessory.scale = Vector2.ONE*0.34
	var ground := CENTER+Vector2(100,90)
	var held := CENTER+Vector2(0,46).rotated(heading)
	var t := feedback.progress()
	if feedback.state == Feedback.State.PICKUP:
		accessory.position = ground.lerp(held,smoothstep(0.35,0.8,t))
	elif feedback.state == Feedback.State.SET_DOWN:
		accessory.position = held.lerp(ground,smoothstep(0.2,0.65,t))
	else:
		accessory.position = held if feedback.carried else ground
	if smoke:
		if test_step == 0:
			prop_index = 4
			change_state(Feedback.State.PICKUP)
			test_step = 1
		elif test_step == 1 and feedback.state == Feedback.State.CARRY:
			change_state(Feedback.State.SET_DOWN)
			test_step = 2
		elif test_step == 2 and feedback.state == Feedback.State.IDLE:
			feedback.show_alert("!")
			change_state(Feedback.State.STUMBLE)
			test_step = 3
		elif test_step == 3 and feedback.state == Feedback.State.IDLE:
			change_state(Feedback.State.DOWN)
			test_step = 4
		elif test_step == 4 and feedback.progress() >= 1.0:
			assert(not feedback.carried)
			assert(feedback.state == Feedback.State.DOWN)
			assert(actor.npc_down_back != null)
			print("Action review: pickup, carry, set down, alert, stumble and down states exercised.")
			get_tree().quit()
	refresh()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#1b1d27"))
	draw_string(ThemeDB.fallback_font,Vector2(34,46),"PINE RIDGE / ANIMATION WORKBENCH",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("#eee4dc"))
	draw_rect(Rect2(32,124,740,540),Color("#353943"))
	draw_rect(Rect2(32,124,740,540),Color("#64616a"),false,1.0)
	draw_rect(Rect2(796,124,452,540),Color("#272a35"))
	for x in range(48,764,32):
		draw_line(Vector2(x,140),Vector2(x,648),Color(1,1,1,0.035),1)
	for y in range(140,648,32):
		draw_line(Vector2(48,y),Vector2(756,y),Color(1,1,1,0.035),1)
	var item: Dictionary = Props.ITEMS[prop_index]
	draw_texture_rect(item.texture,Rect2(944,140,150,150),false)
	draw_string(ThemeDB.fallback_font,Vector2(818,316),item.label,HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("#eee4dc"))
	var lines := ["1 / 2 / 3   Idle / Walk / Run","4 / 5   Pick up / Set down (objects)","6 / 7 / 8   Startled / Stumble / Down","B   Toggle decals  ·  N   Change fall direction","P   Next prop display","Arrows   Rotate / Change wardrobe","R   Reset       Esc   Return"]
	for i in range(lines.size()):
		draw_string(ThemeDB.fallback_font,Vector2(818,356+i*37),lines[i],HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#c6bfca"))
