extends Node2D
# Arcade-style fictional action gameplay. All health, cooldown and movement
# values are game abstractions rather than real-world weapon performance.
signal gunfire(at: Vector2)

const Actor = preload("res://scripts/actor.gd")
const Feedback = preload("res://scripts/character_feedback.gd")
const Props = preload("res://scripts/prop_library.gd")
const GroundDecals = preload("res://scripts/ground_decals.gd")
const ChapterState = preload("res://scripts/chapter_state.gd")
const Audio = preload("res://scripts/preview_audio.gd")
const WeaponVisual = preload("res://scripts/weapon_visual.gd")
const InventoryModel = preload("res://scripts/inventory_model.gd")
const InventoryPanel = preload("res://scripts/inventory_panel.gd")
const OrnateHud = preload("res://scripts/saafiya_hud.gd")
const SpriteKitReview := preload("res://scenes/sprite_kit_review.tscn")
const KIT := [
	{"name":"Beretta 84FS","size":13,"interval":0.24,"travel":2400.0},
	{"name":"CZ 75 P-07","size":12,"interval":0.31,"travel":2200.0},
	{"name":"AKM","size":24,"interval":0.14,"travel":490.0}
]
const ROLES := {
	"knife":{"life":2,"speed":132.0,"reach":23.0,"prop":"blade_icon"},
	"cudgel":{"life":3,"speed":112.0,"reach":26.0,"prop":"club_icon"},
	"brick":{"life":2,"speed":66.0,"reach":156.0,"prop":"brick"},
	"slingshot":{"life":2,"speed":68.0,"reach":185.0,"prop":"slingshot_icon"},
	"pistol":{"life":3,"speed":72.0,"reach":330.0,"prop":"compact_icon"},
	"runner":{"life":2,"speed":112.0,"reach":20.0,"prop":"bottle"}
}
var avatar: Node2D
var street: Node2D
var audio: Node
var held_visual: WeaponVisual
var stage_decals: GroundDecals
var shout_cooldown := 0.0
var gunfire_events := 0
var escaped_count := 0
const HEARING_RADIUS := 850.0
const ESCAPE_MARGIN := 45.0
const LEVEL_WIDTH := 2320.0
const PANIC_CAPTIONS := ["Baleka!", "Awu…", "Baleka!"]

var male_death_take := 0
var rng := RandomNumberGenerator.new()
var actors: Array[Dictionary] = []
var bystanders: Array[Dictionary] = []
const ACTION_REACH := 480.0
const CHARACTER_HIT_RADIUS := 18.0
const LOOT_REACH := 42.0
const PISTOL_VOLLEY := [0.28, 0.16]
var shots: Array[Dictionary] = []
var motes: Array[Dictionary] = []
var loot: Array[Dictionary] = []
var inventory: InventoryModel = InventoryModel.new()
var inventory_ui: InventoryPanel
var player_hp := 3
var player_invincible := 0.0
var cooldown := 0.0
var reload_clock := 0.0
var slot := 0
var rounds := [14,0,24]
var spares := [3,0,1]
var unlocked := [true,false,false]
var shots_fired := 0
var shots_hit := 0
var defeated := 0
var phase := 0
var elapsed := 0.0
var finished := false
var smoke_test := false
var level_id := "feeder"
var ornate_hud
var kit_review: CanvasLayer

func configure(main_actor: Node2D, world: Node2D) -> void:
	avatar = main_actor
	street = world

func register_bystanders(characters: Array[Actor]) -> void:
	for character in characters:
		var reaction := Feedback.new()
		reaction.position = character.position
		reaction.z_index = 4
		add_child(reaction)
		bystanders.append({
			"body":character,"feedback":reaction,"down":false,"fall_variant":bystanders.size()%6,
			"panicked":false,"escaped":false,"hesitation":0.0,"escape_x":0.0,
			"escape_lane":character.position.y,"escape_speed":118.0,
			"panic_personality":bystanders.size()%4
		})


func _ready() -> void:
	rng.seed = 4872011
	audio = Audio.new()
	add_child(audio)
	stage_decals = GroundDecals.new()
	stage_decals.configure(ChapterState.stage_decals(get_tree(), level_id), level_id)
	street.add_child(stage_decals)
	held_visual = WeaponVisual.new()
	held_visual.configure(avatar as Actor)
	held_visual.z_index = 6
	add_child(held_visual)
	spawn_group(false)
	make_hud()
	inventory_ui=InventoryPanel.new()
	inventory_ui.configure(inventory)
	add_child(inventory_ui)
	smoke_test = "--encounter-smoke" in OS.get_cmdline_user_args()
	if smoke_test:
		call_deferred("run_test")

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode in [KEY_K, KEY_F7]:
		kit_review = SpriteKitReview.instantiate()
		kit_review.close_requested.connect(close_sprite_kit)
		add_child(kit_review)
		get_tree().paused = true
		get_viewport().set_input_as_handled()

func close_sprite_kit() -> void:
	kit_review.queue_free()
	kit_review = null
	get_tree().paused = false

func spawn_group(return_wave: bool) -> void:
	if level_id == "barricaded_house":
		# Story staging outside the secured property. Avoid procedural
		# entry routes: the family remains inaccessible indoors.
		var house_group := [
			[Vector2(950,530),"runner",0],
			[Vector2(1225,371),"brick",2],
			[Vector2(1470,343),"cudgel",4],
			[Vector2(1605,491),"slingshot",6],
			[Vector2(1760,543),"knife",7],
			[Vector2(1955,552),"pistol",9]
		]
		for item in house_group:
			spawn_character(item[0],item[1],int(item[2]),bool(item[1] in ["pistol","knife","cudgel"]))
		return
	if level_id == "upper_ridge":
		# Opening chapter: compact, abstract arcade encounter, with most
		# residential movement portrayed through neutral passersby.
		var opening := [
			[Vector2(565,519),"runner",0],
			[Vector2(815,456),"brick",3],
			[Vector2(1078,570),"knife",7],
			[Vector2(1136,476),"pistol",9],
			[Vector2(1920,587),"cudgel",5]
		]
		for item in opening:
			spawn_character(item[0],item[1],int(item[2]),bool(item[1] in ["pistol","knife"]))
		return
	var descriptions := [
		[Vector2(626,382),"knife",0,true],
		[Vector2(492,369),"pistol",5,true],
		[Vector2(810,282),"pistol",1,true],
		[Vector2(1035,420),"brick",2],
		[Vector2(1330,290),"cudgel",4,true],
		[Vector2(1650,416),"slingshot",6],
		[Vector2(2060,350),"pistol",9,true],
		[Vector2(1180,420),"runner",11]
	]
	if return_wave:
		descriptions = [
			[Vector2(1680,260),"brick",7,true],
			[Vector2(1220,424),"cudgel",3],
			[Vector2(900,280),"slingshot",5,true],
			[Vector2(660,430),"pistol",8]
		]
	for desc in descriptions:
		spawn_character(desc[0],desc[1],int(desc[2]),bool(desc[3]) if desc.size()>3 else false)

func spawn_character(at: Vector2, kind: String, look: int, male_voice: bool = false) -> void:
	var character := Actor.new()
	character.position = at
	character.wardrobe_index = look
	character.z_index = 2
	add_child(character)
	var attachment: Node2D
	if kind == "pistol":
		var firearm := WeaponVisual.new()
		firearm.configure(character, false)
		firearm.choose_slot(1)
		attachment = firearm
	else:
		var prop := Sprite2D.new()
		prop.texture = Props.texture(ROLES[kind]["prop"])
		prop.scale = Vector2.ONE * (0.105 if kind in ["slingshot", "cudgel"] else 0.095)
		prop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		attachment = prop
		position_held_prop(character, prop, false, 0.0)
	attachment.z_index = 1
	character.add_child(attachment)
	var feedback := Feedback.new()
	feedback.position = at
	feedback.z_index = 4
	add_child(feedback)
	actors.append({
		"body":character,"attachment":attachment,"feedback":feedback,
		"kind":kind,"hp":int(ROLES[kind]["life"]),
		"max":int(ROLES[kind]["life"]),"alerted":false,
		"cooldown":rng.randf_range(0.4,1.3),"attack":0.0,
		"windup":0.0,"volley":0,"aim":0.0,
		"reaction":0.0,"wander":rng.randf_range(0,TAU),
		"origin":at,"down":false,"visible_prop":true,"flee_said":false,"male_voice":male_voice,
		"fall_variant":(look+actors.size())%6,
		"startle":0.0,"fleeing":false,"escaped":false,
		"escape_x":0.0,"escape_lane":at.y,"escape_speed":110.0,
		"cash_rand":([0,35,0,0,80,0,20,0,0,50,0,0][actors.size()%12])
	})

# The alarm propagates through the fictional level without requiring line of sight.
# It deliberately uses simplified stage reactions rather than tactical sensing.
func on_gunfire(at: Vector2) -> void:
	gunfire_events += 1
	gunfire.emit(at)
	var alarms := 0
	for person in bystanders:
		if bool(person["down"]) or bool(person["escaped"]):
			continue
		var body: Actor = person["body"]
		var distance := body.position.distance_to(at)
		if distance <= HEARING_RADIUS:
			start_bystander_escape(person)
			alarms += 1
	for enemy in actors:
		if bool(enemy["down"]) or bool(enemy["escaped"]):
			continue
		var body: Actor = enemy["body"]
		if body.position.distance_to(at) > HEARING_RADIUS:
			continue
		var feedback: Node2D = enemy["feedback"]
		var first_alarm: bool = not bool(enemy["alerted"])
		enemy["alerted"] = true
		# A second or third gunshot cannot indefinitely freeze an enemy.
		if first_alarm:
			enemy["startle"] = rng.randf_range(0.18,0.36)
			var kind: String = enemy["kind"]
			var runs: bool = kind == "runner" or ((kind == "brick" or kind == "slingshot") and rng.randf() < 0.55) or (kind == "knife" and rng.randf() < 0.22)
			if runs:
				start_enemy_escape(enemy)
			else:
				feedback.show_alert("!")
				feedback.show_caption("Nangu!")
		alarms += 1
	if alarms > 0 and shout_cooldown <= 0.0:
		audio.play_cue("crowd_shout")
		shout_cooldown = 2.5

func escape_parameters(state: Dictionary) -> void:
	var body: Actor = state["body"]
	var towards_west: bool = body.position.x < LEVEL_WIDTH * 0.5
	state["escape_x"] = -ESCAPE_MARGIN if towards_west else LEVEL_WIDTH + ESCAPE_MARGIN
	state["escape_lane"] = 184.0 if body.position.y < 335.0 else 520.0
	state["escape_speed"] = rng.randf_range(108.0,155.0)

func start_bystander_escape(person: Dictionary) -> void:
	if bool(person["panicked"]):
		return
	person["panicked"] = true
	person["hesitation"] = [0.0,0.17,0.42,0.08][int(person["panic_personality"])]
	escape_parameters(person)
	var body: Actor = person["body"]
	body.set_meta("panic_run",true)
	var feedback: Node2D = person["feedback"]
	feedback.show_alert("!")
	feedback.show_caption(PANIC_CAPTIONS[int(person["panic_personality"])%PANIC_CAPTIONS.size()])

func start_enemy_escape(enemy: Dictionary) -> void:
	if bool(enemy["fleeing"]):
		return
	enemy["fleeing"] = true
	enemy["startle"] = rng.randf_range(0.14,0.35)
	escape_parameters(enemy)
	var feedback: Node2D = enemy["feedback"]
	feedback.show_alert("!")
	feedback.show_caption("Baleka!")

func advance_escape(state: Dictionary, delta: float) -> void:
	if bool(state["escaped"]):
		return
	var body: Actor = state["body"]
	var feedback: Node2D = state["feedback"]
	if float(state.get("hesitation",0.0)) > 0.0:
		state["hesitation"] = maxf(0.0,float(state["hesitation"])-delta)
		body.animate(delta,Vector2.ZERO,body.facing)
		feedback.position = body.position
		return
	var start := body.position
	var speed: float = state["escape_speed"]
	var x_target: float = state["escape_x"]
	var lane: float = state["escape_lane"]
	var lateral := clampf(lane-body.position.y,-speed*0.42*delta,speed*0.42*delta)
	var next_y := body.position+Vector2(0,lateral)
	# Some legacy pedestrian starting positions overlap scenic car blockers.
	# Let them step out of an existing overlap towards the open escape lane.
	var trapped: bool = street.blocked(start,5.0)
	if not street.blocked(next_y,5.0) or (trapped and absf(lane-next_y.y) < absf(lane-start.y)):
		body.position = next_y
	var x_step := clampf(x_target-body.position.x,-speed*delta,speed*delta)
	var next_x := body.position+Vector2(x_step,0)
	# Escape remains simulated all the way to the actual ends of the stage.
	var beyond: bool = next_x.x < 5.0 or next_x.x > LEVEL_WIDTH-5.0
	if beyond or not street.blocked(next_x,5.0):
		body.position = next_x
	var displacement := body.position-start
	body.animate(delta,displacement,displacement.angle() if displacement.length_squared()>0.001 else body.facing,false,true)
	feedback.position = body.position
	if body.position.x < -28.0 or body.position.x > LEVEL_WIDTH+28.0:
		state["escaped"] = true
		body.visible = false
		feedback.visible = false
		if state.has("attachment"):
			state["attachment"].visible = false
		escaped_count += 1
		update_hud()

func make_hud() -> void:
	ornate_hud = OrnateHud.new()
	ornate_hud.configure(avatar, street, self, level_id)
	add_child(ornate_hud)
	update_hud()

func update_hud() -> void:
	if not is_instance_valid(ornate_hud):
		return
	var message := ""
	if finished:
		message = "ROUTE COMPLETE\nEsc to restart"
	elif player_hp <= 0 and avatar.defeat_elapsed >= Actor.DEFEAT_DURATION:
		message = "SAAFIYA DOWN\nPress R to restart"
	ornate_hud.show_encounter_notice(message)

func set_phase(next: int) -> void:
	if next == phase:
		return
	phase = next
	if next == 1:
		# Equipment does not appear automatically at a waypoint.
		spawn_group(true)
		audio.play_cue("alert")
	elif next == 2:
		finished = true
	update_hud()

func equip(number: int) -> void:
	if player_hp <= 0 or number < 0 or number >= KIT.size() or not unlocked[number]:
		return
	slot = number
	if is_instance_valid(held_visual):
		held_visual.choose_slot(slot)
	reload_clock = 0.0
	audio.play_cue("pickup")
	update_hud()

func refill() -> void:
	if player_hp <= 0:
		restart_stage()
		return
	if reload_clock > 0.0 or spares[slot] <= 0 or rounds[slot] >= int(KIT[slot]["size"]):
		return
	var cue := "akm_reload" if slot == 2 else ("beretta_reload" if slot == 0 else "cz75_reload")
	# Stay in the reload state while this project's replacement clip plays.
	# Avoid completing early and layering a synthesized 'reset' tone over it.
	var stream: AudioStream = audio.stream_for(cue)
	reload_clock = clampf(stream.get_length(),0.65,4.0)
	held_visual.begin_service(reload_clock)
	audio.play_cue(cue)

func restart_stage() -> void:
	ChapterState.clear_stage_decals(get_tree(), level_id)
	get_tree().reload_current_scene()

func fire_player() -> void:
	if finished or player_hp <= 0 or cooldown > 0.0 or reload_clock > 0.0 or inventory_open():
		return
	if rounds[slot] <= 0:
		audio.play_cue("reset")
		return
	rounds[slot] -= 1
	cooldown = float(KIT[slot]["interval"])
	shots_fired += 1
	var heading := (get_global_mouse_position()-avatar.position).normalized()
	if heading.length_squared() < 0.01:
		heading=Vector2.RIGHT
	resolve_player_action(avatar.position, heading)
	stage_decals.eject(held_visual.burst(heading))
	audio.play_cue("beretta_84fs_shot" if slot == 0 else ("cz75_shot" if slot == 1 else "akm_shot"))
	on_gunfire(avatar.position)
	update_hud()

func resolve_player_action(origin: Vector2, direction: Vector2) -> void:
	# Immediate fictional arcade collision: no tracer or projectile rendering.
	var reach_end := stage_trace(origin, origin + direction * ACTION_REACH)
	var nearest := ACTION_REACH + 1.0
	var candidate: Dictionary = {}
	var ambient := false
	for item in actors:
		if bool(item["down"]) or bool(item.get("escaped",false)):
			continue
		var body: Actor = item["body"]
		var point := Geometry2D.get_closest_point_to_segment(body.position,origin,reach_end)
		var along := origin.distance_to(point)
		if body.position.distance_to(point) <= CHARACTER_HIT_RADIUS and along < nearest \
			and not street.blocked(point, 2.0) and stage_trace(point, body.position) == body.position:
			nearest = along
			candidate = item
			ambient = false
	for item in bystanders:
		if bool(item["down"]) or bool(item.get("escaped",false)):
			continue
		var body: Actor = item["body"]
		var point := Geometry2D.get_closest_point_to_segment(body.position,origin,reach_end)
		var along := origin.distance_to(point)
		if body.position.distance_to(point) <= CHARACTER_HIT_RADIUS and along < nearest \
			and stage_trace(point, body.position) == body.position:
			nearest = along
			candidate = item
			ambient = true
	if candidate.is_empty():
		return
	if ambient:
		affect_bystander(candidate, direction)
	else:
		hit_enemy(candidate, 1, direction)
	shots_hit += 1
	update_hud()

func stage_trace(from: Vector2, to: Vector2) -> Vector2:
	var steps := maxi(1, ceili(from.distance_to(to) / 6.0))
	for i in range(1, steps + 1):
		if street.blocked(from.lerp(to, float(i) / steps), 2.0):
			return from.lerp(to, float(i - 1) / steps)
	return to

func register_character_impact(feedback: Node2D) -> void:
	# A distinct local mark per character and per hit, not a fixed stamp.
	var local := Vector2(rng.randf_range(-4.8,4.8),rng.randf_range(-4.8,4.8))
	feedback.register_impact(local,rng.randf_range(0.7,1.55))

func begin_collapse(target: Dictionary) -> void:
	var body: Actor = target["body"]
	var style := posmod(int(target.get("fall_variant", 0)), Actor.COLLAPSE_NAMES.size())
	target["fall_clock"] = 0.0
	target["fall_duration"] = Actor.COLLAPSE_TIMES[style] * (0.94 + 0.025 * posmod(body.wardrobe_index, 6))
	body.start_collapse(style)
	var lean := Vector2.from_angle(body.collapse_facing)
	var rest_offset: Vector2 = [lean * 3.0, -lean * 3.0, lean.orthogonal() * 3.0,
		-lean.orthogonal() * 3.0, lean * 2.0, -lean * 2.0][style]
	stage_decals.pool(body.global_position + rest_offset, body.collapse_facing, float(target["fall_duration"]) * 0.55)

func advance_collapse(target: Dictionary, delta: float) -> void:
	var body: Actor = target["body"]
	var duration: float = target["fall_duration"]
	target["fall_clock"] = minf(float(target["fall_clock"]) + delta, duration)
	body.set_down_progress(float(target["fall_clock"]) / duration)

func affect_bystander(target: Dictionary, direction: Vector2 = Vector2.ZERO) -> void:
	if bool(target["down"]):
		return
	target["down"] = true
	var person: Actor = target["body"]
	var feedback: Node2D = target["feedback"]
	register_character_impact(feedback)
	feedback.show_caption("Awu…")
	feedback.select(Feedback.State.DOWN)
	begin_collapse(target)
	stage_decals.impact(person.global_position, direction, 0.83)
	audio.play_cue("reaction")

func add_shot(start: Vector2, direction: Vector2, friendly: bool, kind: String, velocity: float) -> void:
	shots.append({"point":start,"prior":start,"vector":direction.normalized()*velocity,
	"friendly":friendly,"kind":kind,"life":0.32 if friendly else 1.05,"rotation":rng.randf_range(0,TAU)})
	if shots.size()>90:
		shots.pop_front()

func nearby_loot() -> Dictionary:
	var nearest: Dictionary = {}
	var reach := LOOT_REACH
	for pile in loot:
		var distance := avatar.position.distance_to(pile.point)
		if distance < reach and not pile.items.is_empty():
			nearest = pile
			reach = distance
	return nearest

func open_nearby_loot() -> bool:
	if player_hp <= 0 or inventory_open():
		return false
	var pile := nearby_loot()
	if pile.is_empty():
		return false
	inventory_ui.show_loot(pile.items, take_loot.bind(pile))
	return true

func take_loot(entry: Dictionary, pile: Dictionary) -> String:
	if player_hp <= 0 or not inventory_open() or avatar.position.distance_to(pile.point) >= LOOT_REACH:
		return ""
	var items: Array[Dictionary] = pile.items
	var index := items.find(entry)
	if index == -1:
		return ""
	var destination := "bag"
	match entry.item:
		"cash":
			inventory.add_cash(entry.amount)
			destination = "wallet"
		"magazine":
			spares[1] += 1
			destination = "equipment"
		"pistol":
			if not unlocked[1]:
				unlocked[1] = true
				rounds[1] = int(KIT[1]["size"])
				inventory.equipment["Backup"] = KIT[1]["name"]
				destination = "equipment"
			elif not inventory.stow(entry.item):
				return ""
		_:
			if not inventory.stow(entry.item):
				return ""
	items.remove_at(index)
	if items.is_empty():
		loot.erase(pile)
	audio.play_cue("pickup")
	update_hud()
	return destination

func toggle_inventory() -> void:
	if player_hp > 0 and is_instance_valid(inventory_ui):
		inventory_ui.toggle()

func show_car_boot() -> void:
	if player_hp > 0 and is_instance_valid(inventory_ui):
		inventory_ui.show_inventory(true)

func inventory_open() -> bool:
	return is_instance_valid(inventory_ui) and inventory_ui.open

func hit_enemy(target: Dictionary, amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if bool(target["down"]):
		return
	target["hp"] = maxi(0,int(target["hp"])-amount)
	var feedback = target["feedback"]
	target["reaction"]=0.28
	register_character_impact(feedback)
	feedback.show_caption("Awu…")
	stage_decals.impact(target["body"].global_position, direction, 1.14 if int(target["hp"]) <= 0 else 0.82)
	if int(target["hp"]) <= 0:
		target["down"]=true
		target["attachment"].visible=false
		feedback.select(Feedback.State.DOWN)
		begin_collapse(target)
		defeated+=1
		var kind: String = target.kind
		var items: Array[Dictionary] = [{"item":kind, "label":InventoryModel.ITEM_NAMES[kind]}]
		if kind == "pistol":
			items.append({"item":"magazine", "label":"P-07 spare magazine"})
		var notes: int=int(target.get("cash_rand",0))
		if notes > 0:
			items.append({"item":"cash", "label":"Wallet · R%d" % notes, "amount":notes})
		loot.append({"point":target["body"].position, "items":items})
		if bool(target.get("male_voice",false)):
			var id := "male_looter_death_1" if male_death_take%2==0 else "male_looter_death_2"
			male_death_take+=1
			audio.play_cue(id)
		else:
			audio.play_cue("down")
	else:
		feedback.select(Feedback.State.STUMBLE)
		target["body"].start_reaction(float(target["reaction"]))
		audio.play_cue("reaction")
	update_hud()

func hurt_player(direction: Vector2 = Vector2.ZERO) -> void:
	if player_invincible > 0.0 or player_hp <= 0:
		return
	player_hp = maxi(0,player_hp-1)
	player_invincible = 0.82
	stage_decals.impact(avatar.global_position, direction, 0.78)
	audio.play_cue("reaction")
	if player_hp <= 0:
		avatar.start_defeat()
		avatar.modulate = Color.WHITE
		held_visual.hide()
		inventory_ui.close_inventory()
		stage_decals.pool(avatar.global_position, float(avatar.facing), 0.18, 0.87)
		audio.play_cue("saafiya_death")
	update_hud()

func update_character(target: Dictionary, delta: float) -> void:
	var body: Actor = target["body"]
	var accessory: Node2D = target["attachment"]
	var feedback: Node2D = target["feedback"]
	target["reaction"]=maxf(0.0,float(target["reaction"])-delta)
	feedback.advance(delta)
	feedback.position=body.position
	if bool(target["escaped"]):
		return
	if bool(target["down"]):
		advance_collapse(target,delta)
		feedback.position=body.position
		return
	target["cooldown"]=maxf(0.0,float(target["cooldown"])-delta)
	target["attack"]=maxf(0.0,float(target["attack"])-delta)
	target["startle"]=maxf(0.0,float(target["startle"])-delta)
	if bool(target["fleeing"]):
		if float(target["startle"])>0.0:
			body.animate(delta,Vector2.ZERO,body.facing)
		else:
			advance_escape(target,delta)
		return
	if float(target["startle"])>0.0:
		body.animate(delta,Vector2.ZERO,body.facing)
		return
	var to_avatar := avatar.position-body.position
	var distance := to_avatar.length()
	var kind: String = target.kind
	var melee := kind in ["knife", "cudgel"]
	var clear_lane := distance <= 475.0 and stage_trace(body.position, avatar.position) == avatar.position
	var motion := Vector2.ZERO
	var heading := to_avatar.angle()
	var notice_radius := 385.0 if kind == "pistol" else 250.0
	var alerted_radius := 475.0 if kind == "pistol" else 380.0
	if float(target.windup) > 0.0:
		heading = target.aim
		target.windup = maxf(0.0, float(target.windup) - delta)
		if target.windup == 0.0:
			if kind == "pistol":
				fire_volley(target)
			elif melee:
				target.attack = 0.38
				target.cooldown = 0.58
				if distance < float(ROLES[kind].reach) + 4.0 and clear_lane:
					hurt_player(to_avatar.normalized())
	elif (distance < notice_radius or (bool(target.alerted) and distance < alerted_radius)) and player_hp > 0:
		if not bool(target["alerted"]):
			target["alerted"]=true
			feedback.show_alert("?")
			feedback.show_caption("Nangu!")
			if shout_cooldown <= 0.0:
				audio.play_cue("crowd_shout")
				shout_cooldown = 3.2
			else:
				audio.play_cue("alert")
		elif feedback.alert_time<=0.0 and feedback.alert=="?":
			feedback.show_alert("!")
		if kind == "runner":
			if distance < 95.0:
				if not bool(target["flee_said"]):
					target["flee_said"] = true
					feedback.show_caption("Baleka!")
				motion = -to_avatar.normalized()*float(ROLES["runner"]["speed"])*delta
		elif melee:
			if float(target.cooldown) <= 0.0:
				if distance <= float(ROLES[kind].reach) and clear_lane:
					target.windup = 0.37
					target.aim = heading
				else:
					motion = to_avatar.normalized() * float(ROLES[kind].speed) * delta
		elif kind == "pistol":
			if distance > float(ROLES[kind].reach) or not clear_lane:
				motion = to_avatar.normalized() * float(ROLES[kind].speed) * delta
			elif float(target.cooldown) <= 0.0:
				target.aim = heading
				target.volley = 0
				target.windup = PISTOL_VOLLEY[0]
		else:
			if distance>125.0:
				motion = to_avatar.normalized()*float(ROLES[target["kind"]]["speed"])*delta
			if float(target["cooldown"])<=0 and distance<float(ROLES[target["kind"]]["reach"]):
				attack_character(target,to_avatar)
	else:
		var t := elapsed*0.47+float(target["wander"])
		motion=Vector2(sin(t),cos(t*0.77))*delta*7.0
		heading = motion.angle()
	var step := Vector2.ZERO
	if not motion.is_zero_approx():
		step.x = motion.x if not street.blocked(body.position + Vector2(motion.x, 0), 8) else 0.0
		step.y = motion.y if not street.blocked(body.position + Vector2(step.x, motion.y), 8) else 0.0
		body.position += step
	body.animate(delta,step,heading,false,(melee or kind == "runner") and not step.is_zero_approx())
	if float(target["reaction"])>0.0:
		body.modulate=Color(1.0,0.61,0.61)
	else:
		body.modulate=Color.WHITE
	if accessory is Sprite2D:
		position_held_prop(body, accessory, float(target["attack"]) > 0.0, float(target["attack"]))
	feedback.position=body.position

func position_held_prop(body: Actor, accessory: Sprite2D, gesturing: bool, attack_clock: float) -> void:
	var angle := body.travel if body.gait_moving else body.facing
	var motion := sin(body.gait_phase * TAU) * 1.6 if body.gait_moving else 0.0
	var gesture := sin(clampf(1.0 - attack_clock / 0.38, 0.0, 1.0) * PI) if gesturing else 0.0
	var pivot := Vector2(8.0 + gesture * 4.0, 5.0 + motion + gesture * 4.0)
	accessory.position = pivot.rotated(angle - PI / 2.0)
	# Rendered props point up in their source texture. Follow the same facing
	# as the body atlas while keeping the grip at the near hand.
	accessory.rotation = angle + PI / 2.0 + gesture * 0.55

func attack_character(target: Dictionary, to_avatar: Vector2) -> void:
	var kind: String = target["kind"]
	target["cooldown"] = 1.75
	target["attack"] = 0.38
	var direction := Vector2.from_angle(to_avatar.angle() + rng.randf_range(-0.32, 0.32))
	add_shot(target["body"].position + direction * 10.0, direction, false, kind, 230.0)

func fire_volley(target: Dictionary) -> void:
	var body: Actor = target.body
	if target.volley + 1 < PISTOL_VOLLEY.size():
		target.volley += 1
		target.windup = PISTOL_VOLLEY[target.volley]
	else:
		target.cooldown = rng.randf_range(1.02, 1.35)
	var direction := Vector2.from_angle(float(target.aim) + rng.randf_range(-0.023, 0.023))
	add_shot(body.position + direction * 10.0, direction, false, "pistol", 680.0)
	var weapon: WeaponVisual = target.attachment
	stage_decals.eject(weapon.burst(direction))
	audio.play_cue("cz75_shot", -4.0)
	on_gunfire(body.position)

func step_shots(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var s: Dictionary=shots[i]
		s["prior"]=s["point"]
		s["point"]+=s["vector"]*delta
		s["rotation"]+=delta*9.0
		s["life"]-=delta
		var p: Vector2=s["point"]
		var previous: Vector2=s["prior"]
		var stop := stage_trace(previous, p)
		var remove := float(s.life) <= 0.0
		if not remove:
			if bool(s["friendly"]):
				for enemy in actors:
					if not bool(enemy["down"]) and Geometry2D.get_closest_point_to_segment(enemy["body"].position,previous,stop).distance_to(enemy["body"].position) < 12.0:
						hit_enemy(enemy, 1, Vector2(s["vector"]).normalized())
						shots_hit+=1
						remove=true
						break
			elif player_hp > 0 and Geometry2D.get_closest_point_to_segment(avatar.position, previous, stop).distance_to(avatar.position) < 11.0:
				hurt_player(Vector2(s["vector"]).normalized())
				remove=true
		if remove or stop != p:
			motes.append({"point":stop,"life":0.28})
			shots.remove_at(i)
	for i in range(motes.size()-1,-1,-1):
		motes[i]["life"]-=delta
		if float(motes[i]["life"])<=0:
			motes.remove_at(i)
func _physics_process(delta: float) -> void:
	for item in bystanders:
		if bool(item["escaped"]):
			continue
		var feedback: Node2D = item["feedback"]
		feedback.position = item["body"].position
		feedback.advance(delta)
		if bool(item["down"]):
			advance_collapse(item,delta)
			feedback.position=item["body"].position
		elif bool(item["panicked"]):
			advance_escape(item,delta)
	if avatar != null and player_hp > 0:
		avatar.modulate = Color(1.0,0.55,0.55) if player_invincible>0.0 and (int(elapsed*14.0)%2)==0 else Color.WHITE
	if smoke_test:
		return
	elapsed+=delta
	cooldown=maxf(0.0,cooldown-delta)
	player_invincible=maxf(0.0,player_invincible-delta)
	shout_cooldown=maxf(0.0,shout_cooldown-delta)
	if player_hp <= 0:
		if avatar.defeat_elapsed < Actor.DEFEAT_DURATION:
			avatar.advance_defeat(delta)
			update_hud()
		shots.clear()
		queue_redraw()
		return
	if reload_clock>0:
		reload_clock=maxf(0.0,reload_clock-delta)
		if reload_clock<=0:
			rounds[slot]=int(KIT[slot]["size"])
			spares[slot]-=1
			update_hud()
	if player_hp>0 and not finished:
		for item in actors:
			update_character(item,delta)
		step_shots(delta)
	queue_redraw()

func _draw() -> void:
	for s in shots:
		var kind: String = s["kind"]
		if kind == "brick" or kind == "slingshot":
			var point: Vector2 = s["point"]
			var size := 3.0 if kind == "brick" else 1.4
			draw_circle(point,size,Color("#ab9181") if kind == "brick" else Color("#8a888b"),true,-1,true)
		elif kind == "pistol":
			draw_line(s.prior, s.point, Color("#e5a366"), 1.35, true)
			draw_circle(s.point, 1.4, Color("#fff0c3"), true, -1, true)
	for target in actors:
		if not target.down and not target.escaped and float(target.windup) > 0.0:
			var tint := Color("#ef9c71") if target.kind == "pistol" else Color("#e66b77")
			draw_arc(target.body.position, 20.0, -PI / 2.0, TAU * (1.0 - float(target.windup) / 0.4) - PI / 2.0, 24, tint, 1.5, true)
	for spark in motes:
		var strength := float(spark["life"])/0.28
		draw_circle(spark["point"],3.0*(1.0-strength)+1.0,Color(0.96,0.77,0.52,strength*0.55),false,0.9,true)
	if player_hp > 0 and not inventory_open():
		var pile := nearby_loot()
		if not pile.is_empty():
			var p: Vector2 = pile.point + Vector2(-29, -32)
			draw_rect(Rect2(p, Vector2(58, 17)), Color("#1a161e"))
			draw_string(ThemeDB.fallback_font, p + Vector2(6, 12), "E · LOOT",
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("#ffdf9e"))

func run_test() -> void:
	for clip in ["saafiya_death.ogg","beretta_84fs_shot.ogg","cz75_shot.ogg","akm_reload.ogg","akm_shot.mp3","crowd_shout.ogg","shotgun_12ga_shot.ogg","shotgun_pump.ogg","beretta_reload.mp3","cz75_reload.ogg","male_looter_death_1.ogg","male_looter_death_2.ogg"]:
		assert(ResourceLoader.exists("res://assets/audio/" + clip), "Missing audio import: " + clip)
	assert(actors.size()==8)
	assert(actors[0]["body"].npc_down != null)
	assert(actors[0]["body"].npc_down_back != null)
	assert(player_hp==3)
	assert(bystanders.size() > 0)
	on_gunfire(avatar.position)
	assert(gunfire_events == 1)
	assert(bool(bystanders[0]["panicked"]))
	assert(bool(actors[0]["alerted"]))
	var first_startle: float = actors[0]["startle"]
	on_gunfire(avatar.position)
	assert(is_equal_approx(float(actors[0]["startle"]),first_startle))
	var escaping: Dictionary = bystanders[0]
	escaping["hesitation"] = 0.0
	escaping["body"].position = Vector2(12,184)
	escaping["escape_x"] = -ESCAPE_MARGIN
	advance_escape(escaping,1.0)
	assert(bool(escaping["escaped"]))
	assert(escaping["body"].position.x < 0.0)
	assert(escaped_count >= 1)
	# Even pedestrians placed inside an old car obstacle can exit its bounds.
	var obstructed: Dictionary = bystanders[6]
	var obstructed_body: Actor = obstructed["body"]
	assert(street.blocked(obstructed_body.position,5.0))
	start_bystander_escape(obstructed)
	obstructed["hesitation"]=0.0
	var starting_y: float=obstructed_body.position.y
	advance_escape(obstructed,0.2)
	assert(obstructed_body.position.y > starting_y)
	var foe: Dictionary=actors[0]
	hit_enemy(foe,1)
	assert(int(foe["hp"])==1)
	assert(foe["body"].reaction_phase == 0.0)
	hit_enemy(foe,1)
	assert(bool(foe["down"]))
	assert(defeated==1)
	assert(male_death_take==1)
	assert(stage_decals.records.any(func(record: Dictionary) -> bool: return record.kind == "pool"))
	assert(foe["feedback"].impact_marks.size()==2)
	assert(foe.has("fall_variant") and foe.has("fall_duration"))
	var downed: Actor = foe["body"]
	var fall_origin := downed.position
	assert(downed.npc_reactions != null and downed.down_phase == 0.0)
	for i in range(90):
		advance_collapse(foe,1.0/60.0)
	assert(downed.down_phase == 1.0 and downed.position == fall_origin)
	assert(downed.rotation == 0.0 and downed.scale == Vector2.ONE)
	assert(audio.stream_for("fire") == null)
	assert(audio.stream_for("beretta_84fs_shot") != null)
	var next_enemy: Dictionary = actors[1]
	var health_before := int(next_enemy["hp"])
	var center: Vector2 = next_enemy["body"].position
	resolve_player_action(center-Vector2(32,0),Vector2.RIGHT)
	assert(int(next_enemy["hp"])==health_before-1)
	var person_state: Dictionary = bystanders[1]
	var person_center: Vector2 = person_state["body"].position
	resolve_player_action(person_center-Vector2(32,0),Vector2.RIGHT)
	assert(bool(person_state["down"]))
	hurt_player()
	assert(player_hp==2)
	assert(not open_nearby_loot())
	equip(0)
	refill()
	set_phase(1)
	assert(actors.size()==12)
	assert(not unlocked[2])
	assert(inventory.bag.size()==2)
	assert(inventory.cash_rand==0)
	# An optional wallet is physical currency; it cannot refill ammunition.
	var reserve_before: Array=spares.duplicate()
	var wallet_owner: Dictionary=actors[4]
	for j in range(int(wallet_owner["max"])):
		hit_enemy(wallet_owner,1)
	assert(bool(wallet_owner["down"]))
	var previous_position: Vector2=avatar.position
	avatar.position=wallet_owner["body"].position+Vector2(12,8)
	assert(open_nearby_loot())
	assert(inventory.cash_rand == 0)
	var wallet_button: Button = inventory_ui.boot_col.get_child(2)
	wallet_button.pressed.emit()
	assert(inventory.cash_rand==80)
	wallet_button.pressed.emit()
	assert(inventory.cash_rand==80)
	assert(inventory_ui.contents.size() == 1)
	var cudgel_button: Button = inventory_ui.boot_col.get_child(1)
	cudgel_button.pressed.emit()
	assert(inventory.bag.has("cudgel") and inventory_ui.contents.is_empty())
	inventory_ui.close_inventory()
	assert(not open_nearby_loot())
	assert(spares==reserve_before)
	avatar.position=previous_position
	add_shot(Vector2(400,300),Vector2.RIGHT,true,"spark",350.0)
	assert(shots.size()==1)
	ornate_hud.run_hud_smoke()
	print("Encounter smoke: actors, arcade damage, defeat, pickup, return wave and projectiles initialized.")
	get_tree().quit()
