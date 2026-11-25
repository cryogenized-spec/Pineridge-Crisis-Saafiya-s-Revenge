extends Node2D
# First playable story segment: uphill residential approach before the mall road.
const World = preload("res://scripts/upper_ridge_world.gd")
const Actor = preload("res://scripts/actor.gd")
const Encounter = preload("res://scripts/encounter.gd")
const Traffic = preload("res://scripts/ambient_traffic.gd")
const Effects = preload("res://scripts/visual_effects.gd")
const ChapterState = preload("res://scripts/chapter_state.gd")
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
var title_label: Label
var objective: Label
var status: Label
var subtitle: Label
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
	player.position = START
	add_child(player)
	traffic=Traffic.new()
	traffic.configure(player,429.0,585.0)
	add_child(traffic)
	world.traffic=traffic
	encounter = Encounter.new()
	encounter.level_id = "upper_ridge"
	encounter.configure(player,world)
	add_child(encounter)
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
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var stack := VBoxContainer.new()
	stack.position = Vector2(22,20)
	stack.add_theme_constant_override("separation",5)
	overlay.add_child(stack)
	title_label = Label.new()
	title_label.text = "01  /  UPPER PINERIDGE"
	title_label.add_theme_font_size_override("font_size",27)
	title_label.modulate=Color("#f4dfbe")
	stack.add_child(title_label)
	objective = Label.new()
	objective.text = "Follow the downhill road toward the mall district."
	objective.add_theme_font_size_override("font_size",17)
	objective.modulate=Color("#e5d2ae")
	stack.add_child(objective)
	status = Label.new()
	status.add_theme_font_size_override("font_size",13)
	status.modulate=Color("#c9bcb1")
	stack.add_child(status)
	subtitle = Label.new()
	subtitle.text = "Saafiya left her car uphill. The shopping district lies further along the road."
	subtitle.position=Vector2(24,627)
	subtitle.add_theme_font_size_override("font_size",16)
	subtitle.modulate=Color("#e9dec7")
	overlay.add_child(subtitle)
	var controls := Label.new()
	controls.text = "WASD: move  |  Q: run  |  C: crouch  |  I: inventory  |  Click: action  |  R: reload  |  E: continue  |  Esc: restart"
	controls.position=Vector2(24,690)
	controls.add_theme_font_size_override("font_size",14)
	controls.modulate=Color("#b9c2ba")
	overlay.add_child(controls)

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
	match event.keycode:
		KEY_ESCAPE:
			if encounter.inventory_open():
				encounter.inventory_ui.close_inventory()
			else:
				get_tree().reload_current_scene()
		KEY_Q: running = not running
		KEY_C: crouching = not crouching
		KEY_R: encounter.refill()
		KEY_1: encounter.equip(0)
		KEY_2: encounter.equip(1)
		KEY_3: encounter.equip(2)
		KEY_I: encounter.toggle_inventory()
		KEY_E:
			if encounter.inventory_open():
				return
			if player.position.distance_to(World.TRUNK_POINT)<47.0:
				encounter.show_car_boot()
				return
			if encounter.collect_nearby():
				return
			advance_stage()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		encounter.fire_player()

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
	if encounter.inventory_open():
		movement=Vector2.ZERO
	if encounter.player_hp <= 0:
		movement=Vector2.ZERO
	var before: Vector2=player.position
	var attempt := before+Vector2(movement.x,0)
	if not world.blocked(attempt):
		player.position.x=attempt.x
	attempt=player.position+Vector2(0,movement.y)
	if not world.blocked(attempt):
		player.position.y=attempt.y
	var moved := player.position-before
	player.animate(delta,moved,(get_global_mouse_position()-player.position).angle(),low,run)
	if run and moved.length()>0.01:
		phase=fposmod(phase+delta/RUN_CYCLE,1.0)
		player.gait_phase=phase
	else:
		phase=player.gait_phase
	camera.position=player.position
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
	objective.text="E  ·  Continue to the barricaded house" if ready else "Follow the downhill road toward the residential block."
	status.text="Distance to junction: %d m    •    %d FPS" % [roundi(player.position.distance_to(World.EXIT_POINT)/24.0),Engine.get_frames_per_second()]
	subtitle.modulate.a=maxf(0.0,1.0-elapsed/9.0)

func run_smoke() -> void:
	assert(World.CAR_LENGTH==108.0)
	assert(World.CAR_WIDTH==43.0)
	assert(not world.blocked(World.TRUNK_POINT))
	assert(encounter.inventory.boot.has("backpack"))
	assert(encounter.inventory.bag.has("keys"))
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
	assert(player.has_approved_atlases())
	assert(walkers.size()==11)
	assert(encounter.actors.size()==5)
	assert(world.blocked(Vector2(200,180)))
	assert(not world.blocked(START))
	assert(not can_advance())
	player.position=World.EXIT_POINT
	assert(can_advance())
	assert(ResourceLoader.exists(NEXT_SCENE))
	print("Upper Ridge smoke: residential map, NPC flow, arcade encounters, player visuals and scene transition verified.")
	get_tree().quit()
