extends Node2D
# First playable story segment: uphill residential approach before the mall road.
const World = preload("res://scripts/upper_ridge_world.gd")
const Actor = preload("res://scripts/actor.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Traffic = preload("res://scripts/ambient_traffic.gd")
const Effects = preload("res://scripts/visual_effects.gd")
const ChapterState = preload("res://scripts/chapter_state.gd")
const JacobsHouse = preload("res://scripts/jacobs_house.gd")
const START := Vector2(126.0,519.0)
const NEXT_SCENE := "res://scenes/house_one.tscn"
var world: World
var player: Actor
var camera: Camera2D
var traffic: Traffic
var encounter: Encounter
var marker: Effects
var walkers: Array[Actor] = []
var heads: Array[Dictionary] = []
var elapsed := 0.0
var running := false
var crouching := false
var phase := 0.0
var finished := false
var objective: Label
var status: Label
var jacobs: JacobsHouse
const RUN_CYCLE := 0.64

func _ready() -> void:
	world = World.new()
	add_child(world)
	marker = Effects.new()
	marker.marker_visible = true
	marker.marker_position = World.EXIT_POINT
	add_child(marker)
	player = Actor.new()
	player.hero = true
	player.z_index = 2
	player.position = START
	add_child(player)
	traffic=Traffic.new()
	traffic.configure(player,399.0,585.0)
	add_child(traffic)
	world.traffic=traffic
	encounter = Encounter.new()
	encounter.level_id = "upper_ridge"
	encounter.configure(player,world)
	add_child(encounter)
	encounter.gunfire.connect(traffic.react_to_gunfire)
	jacobs = JacobsHouse.new()
	jacobs.configure(player, encounter.inventory)
	jacobs.moved_floor.connect(move_to_house_floor)
	add_child(jacobs)
	# A continuous stream of ordinary people travels along the road while
	# a smaller set lingers. These are NPCs, not collision or combat targets.
	for i in range(11):
		var npc := Actor.new()
		npc.wardrobe_index = i%12
		var west := (i%2)==0
		var from_x := 380.0+float(i)*157.0
		var lane_y := 402.0 if i%3==0 else (681.0 if i%3==1 else 573.0)
		npc.position = Vector2(from_x,lane_y)
		npc.show_accessory = i%4==0
		add_child(npc)
		npc.set_meta("panic_run",false)
		walkers.append(npc)
		heads.append({
			"home":npc.position,
			"clock":float(i)*0.57,
			"speed":(15.0+float(i%4)*4.0)*(1.0 if west else -1.0),
			"loiter":i%5==0
		})
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
	build_ui()
	if "--upper-ridge-smoke" in OS.get_cmdline_user_args():
		call_deferred("run_smoke")

func build_ui() -> void:
	encounter.ornate_hud.configure_story(
		"01  /  UPPER PINERIDGE",
		"Follow the downhill road toward the mall district.",
		"Saafiya left her car uphill. The shopping district lies further along the road.",
		"WASD MOVE  •  Q RUN  •  E INTERACT  •  I INVENTORY  •  R RELOAD  •  1–4 QUICK SLOTS  •  F FULLSCREEN"
	)
	objective = encounter.ornate_hud.story_objective
	status = encounter.ornate_hud.story_status

func can_advance() -> bool:
	return player.position.distance_to(World.EXIT_POINT) <= 48.0 and encounter.player_hp > 0

func advance_stage() -> void:
	if not can_advance() or finished:
		return
	finished = true
	ChapterState.store(get_tree(),encounter)
	get_tree().change_scene_to_file(NEXT_SCENE)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if jacobs.dialogue.open:
		if event.keycode == KEY_E:
			jacobs.dialogue.advance()
		elif event.keycode in [KEY_Q, KEY_ESCAPE]:
			jacobs.dialogue.close()
		get_viewport().set_input_as_handled()
		return
	if encounter.handle_inventory_shortcut(event.keycode):
		return
	match event.keycode:
		KEY_ESCAPE:
			if encounter.inventory_open():
				encounter.inventory_ui.close_inventory()
			else:
				encounter.restart_stage()
		KEY_Q: running = not running
		KEY_C: crouching = not crouching
		KEY_R: encounter.refill()
		KEY_1: encounter.equip_quick(0)
		KEY_2: encounter.equip_quick(1)
		KEY_3: encounter.equip_quick(2)
		KEY_4: encounter.equip_quick(3)
		KEY_I: encounter.toggle_inventory()
		KEY_F:
			var mode := DisplayServer.window_get_mode()
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if mode == DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_FULLSCREEN)
		KEY_E:
			if encounter.open_nearby_loot():
				return
			if encounter.player_hp > 0 and jacobs.interact():
				return
			if player.position.distance_to(World.TRUNK_POINT)<47.0:
				encounter.show_car_boot()
				return
			advance_stage()

func _unhandled_input(event: InputEvent) -> void:
	if not jacobs.indoors() and not jacobs.dialogue.open and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		encounter.fire_player()

func move_to_house_floor(point: Vector2) -> void:
	player.position = point
	var inside := jacobs.indoors()
	var frame := JacobsHouse.VIEW if inside else Rect2(Vector2.ZERO, World.SIZE)
	camera.limit_left = int(frame.position.x)
	camera.limit_top = int(frame.position.y)
	camera.limit_right = int(frame.end.x)
	camera.limit_bottom = int(frame.end.y)
	camera.zoom = Vector2.ONE * (1.43 if inside else 1.85)
	camera.position = frame.get_center() if inside else point
	camera.position_smoothing_enabled = not inside
	camera.reset_smoothing()
	encounter.ornate_hud.minimap.visible = not inside
	encounter.ornate_hud.story_subtitle.visible = not inside
	encounter.street_suspended = inside

func movement_blocked(point: Vector2) -> bool:
	return jacobs.blocked(point) if jacobs.indoors() else world.blocked(point)

func _physics_process(delta: float) -> void:
	elapsed += delta
	var axis := Vector2(
		float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
		float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP))
	)
	var low := crouching
	var run := running and not low
	var speed := 53.0 if low else (148.0 if run else 91.0)
	var cadence := 1.0
	if run and axis.length_squared()>0.0:
		cadence=1.0-0.48*cos((phase+delta/RUN_CYCLE*0.5)*TAU*2.0)
	var movement := axis.normalized()*speed*cadence*delta
	encounter.street_suspended = jacobs.indoors() or jacobs.dialogue.open
	if encounter.inventory_open() or jacobs.dialogue.open:
		movement=Vector2.ZERO
	if encounter.player_hp <= 0:
		movement=Vector2.ZERO
	var before: Vector2=player.position
	var attempt := before+Vector2(movement.x,0)
	if not movement_blocked(attempt):
		player.position.x=attempt.x
	attempt=player.position+Vector2(0,movement.y)
	if not movement_blocked(attempt):
		player.position.y=attempt.y
	var moved := player.position-before
	player.animate(delta,moved,(get_global_mouse_position()-player.position).angle(),low,run)
	if run and moved.length()>0.01:
		phase=fposmod(phase+delta/RUN_CYCLE,1.0)
		player.gait_phase=phase
	else:
		phase=player.gait_phase
	camera.position = jacobs.destination() if jacobs.indoors() else player.position
	if jacobs.indoors():
		objective.text = jacobs.objective()
		status.text = "Jacobs house  •  " + ("Ground floor" if jacobs.floor_number == 1 else "Upper floor")
		return
	for i in range(walkers.size()):
		var npc: Actor = walkers[i]
		if npc.down_phase>=0 or bool(npc.get_meta("panic_run",false)):
			continue
		var profile: Dictionary=heads[i]
		var home: Vector2=profile["home"]
		var prev: Vector2=npc.position
		var offset := sin(elapsed*0.48+float(profile["clock"]))*27.0 if bool(profile["loiter"]) else sin(elapsed*0.22+float(profile["clock"]))*73.0
		var wanted := home+Vector2(offset,0)
		if not world.blocked(wanted,5):
			npc.position=wanted
		var walked := npc.position-prev
		npc.animate(delta,walked,walked.angle() if walked.length_squared()>0.005 else npc.facing,false,false)
	marker.marker_position=World.EXIT_POINT
	var ready := can_advance()
	var side_objective := jacobs.objective()
	if not side_objective.is_empty():
		objective.text = side_objective
	else:
		objective.text = "E  ·  Continue to the barricaded house" if ready else "Follow the downhill road toward the residential block."
	status.text="Distance to junction: %d m    •    %d FPS" % [roundi(player.position.distance_to(World.EXIT_POINT)/24.0),Engine.get_frames_per_second()]
	encounter.ornate_hud.story_subtitle.modulate.a=maxf(0.0,1.0-elapsed/9.0)

func run_smoke() -> void:
	assert(World.CAR_LENGTH==108.0)
	assert(World.CAR_WIDTH==43.0)
	assert(not world.blocked(World.TRUNK_POINT))
	assert(encounter.inventory.boot.has("backpack"))
	assert(encounter.inventory.bag.has("keys"))
	assert(encounter.spares[0] == 3)
	var spare_index := encounter.inventory.bag.find("beretta_mag")
	assert(encounter.inventory.move_item("bag", spare_index, "boot", Vector2i(5, 7)))
	assert(encounter.spares[0] == 2)
	assert(encounter.inventory.take_from_boot(encounter.inventory.boot.find("beretta_mag")))
	assert(encounter.spares[0] == 3)
	assert(encounter.inventory.take_from_boot(0))
	assert(encounter.inventory.equip_backpack())
	assert(encounter.inventory.capacity()==18)
	encounter.inventory.add_cash(125)
	assert(encounter.inventory.deposit_cash(50))
	assert(encounter.inventory.cash_rand==75)
	assert(encounter.inventory.boot_cash_rand==50)
	assert(encounter.inventory.withdraw_cash(50))
	assert(encounter.inventory.cash_rand==125)
	assert(traffic!=null)
	traffic.spawn_car()
	assert(traffic.cars.size()==1)
	encounter.show_car_boot()
	assert(encounter.inventory_open())
	encounter.inventory_ui.close_inventory()
	assert(player.has_hero_atlases())
	assert(walkers.size()==11)
	assert(encounter.actors.size()==7)
	assert(world.blocked(Vector2(200,180)))
	assert(not world.blocked(Vector2(742, 337)))
	assert(not world.blocked(Vector2(742, 300)))
	assert(world.blocked(Vector2(742, 230)))
	assert(not world.blocked(START))
	assert(not world.blocked(Vector2(567, 690)))
	run_house_smoke()
	assert(not can_advance())
	player.position=World.EXIT_POINT
	assert(can_advance())
	assert(ResourceLoader.exists(NEXT_SCENE))
	print("Upper Ridge smoke: residential map, inventory keys, Jacobs grounds, two floors, dialogue and chapter transition verified.")
	get_tree().quit()

func run_house_smoke() -> void:
	var e := InputEventKey.new()
	e.keycode = KEY_E
	e.pressed = true
	var q := InputEventKey.new()
	q.keycode = KEY_Q
	q.pressed = true
	player.position = JacobsHouse.FRONT
	_unhandled_key_input(e)
	assert(not jacobs.indoors() and not encounter.inventory.ridge_house_key)
	for point in [Vector2(1972, 346), Vector2(1972, 302), Vector2(2149, 286),
			Vector2(2158, 240), Vector2(2158, 161), Vector2(2158, 104), JacobsHouse.OWNER_AT]:
		assert(not world.blocked(point))
	player.position = JacobsHouse.OWNER_AT + Vector2(13, 13)
	_unhandled_key_input(e)
	assert(jacobs.dialogue.open and not encounter.inventory.ridge_house_key)
	_unhandled_key_input(q)
	assert(not jacobs.dialogue.open and not encounter.inventory.ridge_house_key)
	_unhandled_key_input(e)
	for page in range(3):
		_unhandled_key_input(e)
	assert(encounter.inventory.ridge_house_key and not jacobs.dialogue.open)
	player.position = JacobsHouse.FRONT
	_unhandled_key_input(e)
	assert(jacobs.floor_number == 1 and encounter.street_suspended)
	assert(player.position == JacobsHouse.VIEW.position + JacobsHouse.ENTRY)
	assert(not movement_blocked(JacobsHouse.VIEW.position + JacobsHouse.PATIO_EXIT))
	assert(not movement_blocked(JacobsHouse.VIEW.position + Vector2(448, 128)))
	player.position = JacobsHouse.VIEW.position + JacobsHouse.STAIR
	_unhandled_key_input(e)
	assert(jacobs.floor_number == 2 and not encounter.ornate_hud.minimap.visible)
	assert(movement_blocked(JacobsHouse.VIEW.position + JacobsHouse.LOCKED_DOOR))
	assert(not movement_blocked(JacobsHouse.VIEW.position + Vector2(298, 262)))
	jacobs._process(.24)
	assert(jacobs.raised < 0.0 and jacobs.knock_audio.playing)
	player.position = JacobsHouse.VIEW.position + JacobsHouse.LOOTER_AT + Vector2(0, 32)
	jacobs._process(.30)
	assert(jacobs.raised > 0.0 and not jacobs.knock_audio.playing)
	_unhandled_key_input(e)
	assert(jacobs.dialogue.open)
	for page in range(3):
		_unhandled_key_input(e)
	assert(jacobs.resolved and not jacobs.dialogue.open)
	player.position = JacobsHouse.VIEW.position + JacobsHouse.STAIR
	_unhandled_key_input(e)
	player.position = JacobsHouse.VIEW.position + JacobsHouse.PATIO_EXIT
	_unhandled_key_input(e)
	assert(player.position == JacobsHouse.BACK and not jacobs.indoors())
	assert(encounter.ornate_hud.minimap.visible and not encounter.street_suspended)
	encounter.toggle_inventory()
	_unhandled_key_input(q)
	assert(not encounter.inventory_open() and not running)
