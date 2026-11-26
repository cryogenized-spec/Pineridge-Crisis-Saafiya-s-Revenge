extends Node2D
# Segment 2 — residential exterior. An occupied house is barricaded.
# The scene uses abstract arcade NPC behaviour and visual storytelling.
const World = preload("res://scripts/house_one_world.gd")
const Actor = preload("res://scripts/actor.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Traffic = preload("res://scripts/ambient_traffic.gd")
const Effects = preload("res://scripts/visual_effects.gd")
const ChapterState = preload("res://scripts/chapter_state.gd")
const START := Vector2(128.0,539.0)
const NEXT_SCENE := "res://scenes/main.tscn"
const RUN_CYCLE := 0.64
var world: World
var player: Actor
var camera: Camera2D
var traffic: Traffic
var encounter: Encounter
var marker: Effects
var walkers: Array[Actor] = []
var profiles: Array[Dictionary] = []
var elapsed := 0.0
var phase := 0.0
var running := false
var crouching := false
var checked_house := false
var leaving := false
var objective: Label
var status: Label
var dialogue: Label
var dialogue_timer := 0.0

func _ready() -> void:
	world=World.new()
	add_child(world)
	marker=Effects.new()
	marker.marker_position=World.GATE_POINT
	add_child(marker)
	player=Actor.new()
	player.hero=true
	player.position=START
	add_child(player)
	traffic=Traffic.new()
	traffic.configure(player,450.0,625.0)
	add_child(traffic)
	world.traffic=traffic
	encounter=Encounter.new()
	encounter.level_id="barricaded_house"
	encounter.configure(player,world)
	add_child(encounter)
	ChapterState.restore(get_tree(),encounter)
	var locations := [
		Vector2(230,481),Vector2(450,683),Vector2(708,475),
		Vector2(881,685),Vector2(1478,465),Vector2(1802,686),
		Vector2(2048,485),Vector2(1945,640)
	]
	for i in range(locations.size()):
		var person:=Actor.new()
		person.wardrobe_index=i+2
		person.position=locations[i]
		person.show_accessory=i%3==1
		person.set_meta("home",locations[i])
		person.set_meta("panic_run",false)
		add_child(person)
		walkers.append(person)
		profiles.append({"clock":float(i)*1.19,"roaming":i%4!=0})
	encounter.register_bystanders(walkers)
	camera=Camera2D.new()
	camera.zoom=Vector2(1.85,1.85)
	camera.position=START
	camera.limit_left=0
	camera.limit_top=0
	camera.limit_right=int(World.SIZE.x)
	camera.limit_bottom=int(World.SIZE.y)
	camera.position_smoothing_enabled=true
	camera.position_smoothing_speed=7.0
	add_child(camera)
	camera.make_current()
	make_hud()
	if "--house-one-smoke" in OS.get_cmdline_user_args():
		call_deferred("run_smoke")

func make_hud() -> void:
	encounter.ornate_hud.configure_story(
		"02  /  THE BARRICADED HOUSE",
		"Find the occupied house and check on the family at the front gate.",
		"",
		"WASD MOVE  •  Q RUN  •  E INTERACT  •  I INVENTORY  •  R RELOAD  •  [ / ] EQUIPMENT  •  F FULLSCREEN"
	)
	objective = encounter.ornate_hud.story_objective
	status = encounter.ornate_hud.story_status
	dialogue = encounter.ornate_hud.story_subtitle

func check_gate() -> bool:
	return player.position.distance_to(World.GATE_POINT)<=55.0 and encounter.player_hp>0

func can_continue() -> bool:
	return checked_house and player.position.distance_to(World.EXIT_POINT)<=48.0 and encounter.player_hp>0

func speak_with_residents() -> void:
	if checked_house or not check_gate():
		return
	checked_house=true
	dialogue.text="VOICE BEHIND THE SHUTTERS: We're safe inside. Please warn the neighbours."
	dialogue_timer=9.0
	marker.marker_position=World.EXIT_POINT
	objective.text="The household is secure. Continue down the road toward the mall."
	# Residents speak through text until a matching dialogue recording exists.

func continue_story() -> void:
	if leaving or not can_continue():
		return
	leaving=true
	ChapterState.store(get_tree(),encounter)
	get_tree().change_scene_to_file(NEXT_SCENE)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ESCAPE:
			if encounter.inventory_open():
				encounter.inventory_ui.close_inventory()
			else:
				encounter.restart_stage()
		KEY_Q: running=not running
		KEY_C: crouching=not crouching
		KEY_R: encounter.refill()
		KEY_1: encounter.equip(0)
		KEY_2: encounter.equip(1)
		KEY_3: encounter.equip(2)
		KEY_I: encounter.toggle_inventory()
		KEY_F:
			var mode := DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_E:
			if encounter.inventory_open():
				return
			if encounter.collect_nearby():
				return
			if not checked_house:
				speak_with_residents()
			else:
				continue_story()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		encounter.fire_player()

func _physics_process(delta: float) -> void:
	elapsed+=delta
	dialogue_timer=maxf(0.0,dialogue_timer-delta)
	if dialogue_timer<=0.0 and dialogue.text!="":
		dialogue.text=""
	var input_vector:=Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT))-
		float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN))-
		float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	)
	var low:=crouching
	var fast:=running and not low
	var speed:=53.0 if low else (148.0 if fast else 91.0)
	var cadence:=1.0
	if fast and input_vector.length_squared()>0.0:
		cadence=1.0-0.48*cos((phase+delta/RUN_CYCLE*0.5)*TAU*2.0)
	var delta_move:=input_vector.normalized()*speed*cadence*delta
	if encounter.inventory_open():
		delta_move=Vector2.ZERO
	if encounter.player_hp<=0:
		delta_move=Vector2.ZERO
	var previous: Vector2=player.position
	var next:=player.position+Vector2(delta_move.x,0)
	if not world.blocked(next):
		player.position.x=next.x
	next=player.position+Vector2(0,delta_move.y)
	if not world.blocked(next):
		player.position.y=next.y
	var walked: Vector2=player.position-previous
	player.animate(delta,walked,(get_global_mouse_position()-player.position).angle(),low,fast)
	if fast and walked.length()>0.01:
		phase=fposmod(phase+delta/RUN_CYCLE,1.0)
		player.gait_phase=phase
	else:
		phase=player.gait_phase
	camera.position=player.position
	for i in range(walkers.size()):
		var person: Actor=walkers[i]
		if person.down_phase>=0.0 or bool(person.get_meta("panic_run",false)):
			continue
		var data: Dictionary=profiles[i]
		var home: Vector2=person.get_meta("home")
		var off:=sin(elapsed*(0.24 if bool(data["roaming"]) else 0.42)+float(data["clock"]))*36.0
		var destination:=home+Vector2(off,0)
		var last: Vector2=person.position
		if not world.blocked(destination,5.0):
			person.position=destination
		var movement: Vector2=person.position-last
		person.animate(delta,movement,movement.angle() if movement.length_squared()>0.002 else person.facing,false,false)
	marker.marker_position=World.EXIT_POINT if checked_house else World.GATE_POINT
	if not checked_house and check_gate():
		objective.text="E  ·  Speak to the occupants from outside the gate."
	elif not checked_house:
		objective.text="Find the occupied house and check on the family at the front gate."
	elif can_continue():
		objective.text="E  ·  Continue to the mall approach road."
	else:
		objective.text="The household is secure. Continue east to the next block."
	status.text="Segment 2  •  %d FPS  •  Distance: %d m" % [
		Engine.get_frames_per_second(),
		roundi(player.position.distance_to(marker.marker_position)/24.0)
	]

func run_smoke() -> void:
	assert(player.has_approved_atlases())
	assert(world.CAR_LENGTH==108.0)
	assert(world.CAR_WIDTH==43.0)
	assert(walkers.size()==8)
	assert(encounter.actors.size()==6)
	traffic.spawn_car()
	assert(traffic.cars.size()==1)
	assert(not world.blocked(START))
	assert(world.blocked(Vector2(1075,323)))
	assert(world.blocked(Vector2(1130,190)))
	assert(not world.blocked(World.GATE_POINT))
	assert(not checked_house)
	assert(not can_continue())
	player.position=World.GATE_POINT
	assert(check_gate())
	speak_with_residents()
	assert(checked_house)
	player.position=World.EXIT_POINT
	assert(can_continue())
	var health_before: int=encounter.player_hp
	encounter.inventory.add_cash(175)
	var wallet_before: int=encounter.inventory.cash_rand
	ChapterState.store(get_tree(),encounter)
	encounter.player_hp=1
	encounter.inventory.cash_rand=0
	ChapterState.restore(get_tree(),encounter)
	assert(encounter.player_hp==health_before)
	assert(encounter.inventory.cash_rand==wallet_before)
	assert(encounter.inventory.bag.has("keys"))
	assert(ResourceLoader.exists(NEXT_SCENE))
	print("House One smoke: residential exterior, car scale, occupied-house objective, six NPCs and story transition verified.")
	get_tree().quit()
