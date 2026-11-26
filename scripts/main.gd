extends Node2D

const Street = preload("res://scripts/street.gd")
const Actor = preload("res://scripts/actor.gd")
const Effects = preload("res://scripts/visual_effects.gd")
const Haze = preload("res://scripts/street_haze.gd")
const Encounter = preload("res://scripts/encounter.gd")
const ChapterState = preload("res://scripts/chapter_state.gd")
const START := Vector2(132,358)
const WAYPOINT := Vector2(2060,350)
var street: Street
var player: Actor
var camera: Camera2D
var effects: Effects
var haze: Node2D
var low_fx := false
var encounters
var pedestrians: Array[Actor] = []
var status: Label
var objective: Label
var elapsed := 0.0
var phase := 0
var preview_timer := 0.0
var run_phase := 0.0
var run_enabled := false
var crouch_enabled := false
const RUN_CYCLE_SECONDS := 0.64
const FOOTFALL_VARIATION := 0.48

func _ready() -> void:
	street=Street.new()
	add_child(street)
	haze = Haze.new()
	haze.origins = street.haze_origins
	add_child(haze)
	effects=Effects.new()
	add_child(effects)
	var positions := [Vector2(235,177),Vector2(316,511),Vector2(484,185),Vector2(561,474),Vector2(717,515),Vector2(890,180),Vector2(998,464),Vector2(1268,149),Vector2(1620,191),Vector2(1845,507),Vector2(353,189),Vector2(1510,513),Vector2(1977,178)]
	for i in range(positions.size()):
		var person:=Actor.new()
		person.position=positions[i]
		person.wardrobe_index = i
		person.jacket=[Color("#907343"),Color("#686685"),Color("#466776"),Color("#874857"),Color("#61735d")][i%5]
		person.skin=[Color("#a36c52"),Color("#c88d6b"),Color("#8f5846")][i%3]
		person.set_meta("home",positions[i])
		person.set_meta("offset",float(i)*1.31)
		add_child(person)
		pedestrians.append(person)
	player=Actor.new()
	player.hero=true
	player.position=START
	add_child(player)
	encounters=Encounter.new()
	encounters.configure(player,street)
	add_child(encounters)
	ChapterState.restore(get_tree(),encounters)
	encounters.register_bystanders(pedestrians)
	camera=Camera2D.new()
	camera.zoom=Vector2(2,2)
	camera.position=START
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=2320
	camera.limit_bottom=700
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=8
	add_child(camera)
	camera.make_current()
	make_hud()

func make_hud() -> void:
	encounters.ornate_hud.configure_story(
		"03  /  MALL APPROACH",
		"Explore the street · reach the east marker",
		"",
		"WASD MOVE  •  Q RUN  •  C CROUCH  •  E INTERACT  •  I INVENTORY  •  R RELOAD  •  [ / ] EQUIPMENT  •  F FULLSCREEN"
	)
	objective = encounters.ornate_hud.story_objective
	status = encounters.ornate_hud.story_status

func _unhandled_key_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_F6:
				low_fx = not low_fx
				if is_instance_valid(haze):
					haze.visible = not low_fx
			KEY_F4:
				get_tree().change_scene_to_file("res://scenes/action_review.tscn")
			KEY_F3:
				get_tree().change_scene_to_file("res://scenes/prop_review.tscn")
			KEY_F2:
				get_tree().change_scene_to_file("res://scenes/character_review.tscn")
			KEY_ESCAPE:
				if encounters.inventory_open():
					encounters.inventory_ui.close_inventory()
				else:
					get_tree().reload_current_scene()
			KEY_F:
				var mode:=DisplayServer.window_get_mode()
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode==DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
			KEY_R:
				encounters.refill()
			KEY_1:
				encounters.equip(0)
			KEY_2:
				encounters.equip(1)
			KEY_3:
				encounters.equip(2)
			KEY_Q:
				run_enabled = not run_enabled
			KEY_C:
				crouch_enabled = not crouch_enabled
			KEY_I: encounters.toggle_inventory()
			KEY_E:
				if encounters.inventory_open():
					return
				if encounters.collect_nearby():
					return
				if phase==0 and player.position.distance_to(WAYPOINT)<36:
					phase=1
					encounters.set_phase(1)
					objective.text="Marker checked · return to the west marker"
				elif phase==1 and player.position.distance_to(START)<36:
					phase=2
					encounters.set_phase(2)
					objective.text="Route complete · Esc to restart"
			KEY_V:
				if preview_timer<=0:
					effects.burst(player.position+Vector2(0,-19))
					preview_timer=0.3

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		encounters.fire_player()

func _physics_process(delta:float) -> void:
	elapsed+=delta
	preview_timer=maxf(0,preview_timer-delta)
	var direction:=Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	var low := crouch_enabled
	var running := run_enabled and not low
	var speed:=53.0 if low else (148.0 if running else 91.0)
	# Two gentle footfall pulses per gait cycle; mean multiplier remains 1.
	# A positive minimum preserves responsiveness through each footfall.
	var cadence := 1.0
	if running and direction.length_squared() > 0.0:
		var midpoint := run_phase + delta / RUN_CYCLE_SECONDS * 0.5
		cadence = 1.0 - FOOTFALL_VARIATION * cos(midpoint * TAU * 2.0)
	var motion:=direction.normalized()*speed*cadence*delta
	if encounters.inventory_open():
		motion=Vector2.ZERO
	if encounters.player_hp<=0 or encounters.finished:
		motion=Vector2.ZERO
	var old:Vector2=player.position
	var next:=old+Vector2(motion.x,0)
	if not street.blocked(next):
		player.position.x=next.x
	next=player.position+Vector2(0,motion.y)
	if not street.blocked(next):
		player.position.y=next.y
	var displacement := player.position - old
	player.animate(delta,displacement,(get_global_mouse_position()-player.position).angle(),low,running)
	if running and displacement.length() > 0.01:
		var achieved := clampf(displacement.length() / maxf(motion.length(), 0.001), 0.0, 1.0)
		run_phase = fposmod(run_phase + delta / RUN_CYCLE_SECONDS * achieved, 1.0)
		player.gait_phase = run_phase
	elif not running:
		run_phase = player.gait_phase
	camera.position=player.position
	for person in pedestrians:
		if person.down_phase >= 0.0 or bool(person.get_meta("panic_run",false)):
			continue
		var p:Vector2=person.get_meta("home")
		var t:float=elapsed*(0.45 + 0.08 * float(person.wardrobe_index % 5))+float(person.get_meta("offset"))
		var desired:=p+Vector2(sin(t)*15,0)
		var previous:Vector2=person.position
		if not street.blocked(desired,5):
			person.position=desired
		var movement:Vector2=person.position-previous
		person.animate(delta,movement,0.0 if cos(t)>0 else PI, false, false)
	status.text="%s  ·  %03d:%03d  ·  %d FPS  ·  Smoke: %s" % ["CROUCH" if low else ("RUN" if running else "WALK"),int(player.position.x),int(player.position.y),Engine.get_frames_per_second(),"OFF" if low_fx else "ON"]
	# Child actors redraw themselves; this node draws no animated geometry.

func _draw() -> void:
	# Marker visuals are drawn by the dedicated overlay below street rendering.
	pass

func _process(_delta:float) -> void:
	effects.marker_visible=phase<2
	if phase<2 and is_instance_valid(player):
		var target:=WAYPOINT if phase==0 else START
		effects.marker_position=target
		if player.position.distance_to(target)<36:
			objective.text="E · Check east marker" if phase==0 else "E · Complete return"
		else:
			objective.text="Explore the street · reach the east marker" if phase==0 else "Marker checked · return to the west marker"
