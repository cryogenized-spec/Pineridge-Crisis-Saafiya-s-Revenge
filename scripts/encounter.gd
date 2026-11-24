extends Node2D
# Arcade-style fictional action gameplay. All health, cooldown and movement
# values are game abstractions rather than real-world weapon performance.
const Actor = preload("res://scripts/actor.gd")
const Feedback = preload("res://scripts/character_feedback.gd")
const Props = preload("res://scripts/prop_library.gd")
const BLOOD_STAIN = preload("res://assets/fx/blood_stain.svg")
const Audio = preload("res://scripts/preview_audio.gd")
const WeaponVisual = preload("res://scripts/weapon_visual.gd")
const KIT := [
	{"name":"Beretta 84FS","size":13,"interval":0.24,"travel":2400.0},
	{"name":"CZ 75 P-07","size":12,"interval":0.31,"travel":2200.0},
	{"name":"AKM","size":24,"interval":0.14,"travel":490.0}
]
const ROLES := {
	"knife":{"life":2,"speed":83.0,"reach":24.0,"prop":"blade_icon"},
	"cudgel":{"life":3,"speed":70.0,"reach":26.0,"prop":"club_icon"},
	"brick":{"life":2,"speed":66.0,"reach":156.0,"prop":"brick"},
	"slingshot":{"life":2,"speed":68.0,"reach":185.0,"prop":"slingshot_icon"},
	"pistol":{"life":3,"speed":62.0,"reach":205.0,"prop":"compact_icon"},
	"runner":{"life":2,"speed":112.0,"reach":20.0,"prop":"bottle"}
}
var avatar: Node2D
var street: Node2D
var audio: Node
var held_visual: Node2D
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
var shots: Array[Dictionary] = []
var motes: Array[Dictionary] = []
var contact_splashes: Array[Dictionary] = []
const MAX_CONTACT_SPLASHES := 48
var ground_marks: Array[Dictionary] = []
const MAX_GROUND_MARKS := 72
var loot: Array[Dictionary] = []
var player_hp := 3
var player_invincible := 0.0
var cooldown := 0.0
var reload_clock := 0.0
var slot := 0
var rounds := [14,12,24]
var spares := [3,1,1]
var unlocked := [true,false,false]
var shots_fired := 0
var shots_hit := 0
var defeated := 0
var phase := 0
var elapsed := 0.0
var finished := false
var smoke_test := false
var hud: Label
var notice: Label

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
	held_visual = WeaponVisual.new()
	held_visual.configure(avatar)
	held_visual.z_index = 6
	add_child(held_visual)
	spawn_group(false)
	make_hud()
	smoke_test = "--encounter-smoke" in OS.get_cmdline_user_args()
	if smoke_test:
		call_deferred("run_test")

func spawn_group(return_wave: bool) -> void:
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
	var attachment := Sprite2D.new()
	attachment.texture = Props.texture(ROLES[kind]["prop"])
	attachment.scale = Vector2.ONE * 0.115
	attachment.z_index = 1
	attachment.position = Vector2(0,9)
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
		"reaction":0.0,"wander":rng.randf_range(0,TAU),
		"origin":at,"down":false,"visible_prop":true,"flee_said":false,"male_voice":male_voice,
		"fall_variant":(look+actors.size())%6,
		"startle":0.0,"fleeing":false,"escaped":false,
		"escape_x":0.0,"escape_lane":at.y,"escape_speed":110.0
	})

# The alarm propagates through the fictional level without requiring line of sight.
# It deliberately uses simplified stage reactions rather than tactical sensing.
func on_gunfire(at: Vector2) -> void:
	gunfire_events += 1
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
	var overlay := CanvasLayer.new()
	add_child(overlay)
	var backdrop := PanelContainer.new()
	backdrop.position = Vector2(919,16)
	backdrop.custom_minimum_size = Vector2(342,0)
	var style := StyleBoxFlat.new()
	style.bg_color=Color(0.09,0.10,0.14,0.91)
	style.border_color=Color("#ac9180")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left=12
	style.content_margin_right=12
	style.content_margin_top=10
	style.content_margin_bottom=10
	backdrop.add_theme_stylebox_override("panel",style)
	overlay.add_child(backdrop)
	var column := VBoxContainer.new()
	backdrop.add_child(column)
	hud=Label.new()
	hud.add_theme_font_size_override("font_size",18)
	hud.modulate=Color("#f3dbb8")
	column.add_child(hud)
	var help := Label.new()
	help.text="Click: action  •  R: refill  •  1–3: equipment  •  E: collect"
	help.add_theme_font_size_override("font_size",12)
	help.modulate=Color("#d3c3b1")
	column.add_child(help)
	notice=Label.new()
	notice.position=Vector2(450,312)
	notice.add_theme_font_size_override("font_size",29)
	notice.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	notice.custom_minimum_size=Vector2(380,100)
	notice.modulate=Color("#f3dcc0")
	overlay.add_child(notice)
	update_hud()

func update_hud() -> void:
	if not is_instance_valid(hud):
		return
	var active: Dictionary = KIT[slot]
	var remaining := 0
	for item in actors:
		if not bool(item["down"]) and not bool(item.get("escaped",false)):
			remaining += 1
	hud.text="HEALTH  %s   |   %s  %02d / %02d\nACTIVE  %d    DOWN  %d    ESCAPED  %d    HITS  %d/%d" % [
		"♥".repeat(player_hp)+"♡".repeat(3-player_hp),
		active["name"],rounds[slot],spares[slot],remaining,defeated,escaped_count,shots_hit,shots_fired]
	if finished:
		notice.text="ROUTE COMPLETE\nEsc to restart"
	elif player_hp <= 0:
		notice.text="SAAFIYA DOWN\nPress R to restart"
	else:
		notice.text=""

func set_phase(next: int) -> void:
	if next == phase:
		return
	phase = next
	if next == 1:
		unlocked[2] = true
		spawn_group(true)
		audio.play_cue("alert")
	elif next == 2:
		finished = true
	update_hud()

func equip(number: int) -> void:
	if number < 0 or number >= KIT.size() or not unlocked[number]:
		return
	slot = number
	if is_instance_valid(held_visual):
		held_visual.choose_slot(slot)
	reload_clock = 0.0
	audio.play_cue("pickup")
	update_hud()

func refill() -> void:
	if player_hp <= 0:
		get_tree().reload_current_scene()
		return
	if reload_clock > 0.0 or spares[slot] <= 0 or rounds[slot] >= int(KIT[slot]["size"]):
		return
	var cue := "akm_reload" if slot == 2 else ("beretta_reload" if slot == 0 else "cz75_reload")
	# Stay in the reload state while this project's replacement clip plays.
	# Avoid completing early and layering a synthesized 'reset' tone over it.
	var stream: AudioStream = audio.stream_for(cue)
	reload_clock = clampf(stream.get_length(),0.65,4.0)
	audio.play_cue(cue)

func fire_player() -> void:
	if finished or player_hp <= 0 or cooldown > 0.0 or reload_clock > 0.0:
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
	if is_instance_valid(held_visual):
		held_visual.burst()
	audio.play_cue("beretta_84fs_shot" if slot == 0 else ("cz75_shot" if slot == 1 else "akm_shot"))
	on_gunfire(avatar.position)
	update_hud()

func resolve_player_action(origin: Vector2, direction: Vector2) -> void:
	# Immediate fictional arcade collision: no tracer or projectile rendering.
	var reach_end := origin + direction * ACTION_REACH
	var nearest := ACTION_REACH + 1.0
	var candidate: Dictionary = {}
	var ambient := false
	for item in actors:
		if bool(item["down"]) or bool(item.get("escaped",false)):
			continue
		var body: Actor = item["body"]
		var point := Geometry2D.get_closest_point_to_segment(body.position,origin,reach_end)
		var along := origin.distance_to(point)
		if body.position.distance_to(point) <= CHARACTER_HIT_RADIUS and along < nearest:
			nearest = along
			candidate = item
			ambient = false
	for item in bystanders:
		if bool(item["down"]) or bool(item.get("escaped",false)):
			continue
		var body: Actor = item["body"]
		var point := Geometry2D.get_closest_point_to_segment(body.position,origin,reach_end)
		var along := origin.distance_to(point)
		if body.position.distance_to(point) <= CHARACTER_HIT_RADIUS and along < nearest:
			nearest = along
			candidate = item
			ambient = true
	if candidate.is_empty():
		return
	if ambient:
		affect_bystander(candidate)
	else:
		hit_enemy(candidate,1)
	shots_hit += 1
	update_hud()

func register_character_impact(feedback: Node2D) -> void:
	# A distinct local mark per character and per hit, not a fixed stamp.
	var local := Vector2(rng.randf_range(-4.8,4.8),rng.randf_range(-4.8,4.8))
	feedback.register_impact(local,rng.randf_range(0.7,1.55))

func begin_collapse(target: Dictionary) -> void:
	var body: Actor = target["body"]
	var style: int = int(target.get("fall_variant",0))
	target["fall_clock"] = 0.0
	target["fall_duration"] = 0.65 + float(style%3)*0.14 + rng.randf_range(-0.07,0.07)
	target["fall_origin"] = body.position
	target["fall_offset"] = Vector2.from_angle(float(style)*1.7 + rng.randf_range(-0.4,0.4)) * rng.randf_range(1.2,4.7)
	target["fall_tilt"] = (1.0 if style%2==0 else -1.0) * rng.randf_range(0.055,0.18)
	target["fall_flip"] = style >= 4
	body.fall_backward = (style%2)==1
	body.fall_sideways = (style%3)==2
	body.set_down_progress(0.0)

func advance_collapse(target: Dictionary, delta: float) -> void:
	var body: Actor = target["body"]
	target["fall_clock"] = float(target["fall_clock"]) + delta
	var raw := clampf(float(target["fall_clock"])/maxf(0.1,float(target["fall_duration"])),0.0,1.0)
	var style: int = int(target["fall_variant"])
	var frame_progress := raw
	match style%3:
		0: frame_progress = smoothstep(0.0,1.0,raw)
		1: frame_progress = pow(raw,0.75)
		2: frame_progress = pow(raw,1.45)
	var settle := smoothstep(0.0,1.0,raw)
	body.position = Vector2(target["fall_origin"]) + Vector2(target["fall_offset"])*settle
	if body.npc_down != null or body.npc_down_back != null or body.npc_down_side != null:
		body.set_down_progress(frame_progress)
		body.rotation = float(target["fall_tilt"])*settle
		body.scale = Vector2(-1.0,1.0) if bool(target["fall_flip"]) else Vector2.ONE
	else:
		body.set_down_progress(-1.0)
		body.rotation = float(target["fall_tilt"])*settle
		body.scale = Vector2.ONE * lerpf(1.0,0.78,settle)

func affect_bystander(target: Dictionary) -> void:
	if bool(target["down"]):
		return
	target["down"] = true
	var person: Actor = target["body"]
	var feedback: Node2D = target["feedback"]
	register_character_impact(feedback)
	feedback.show_caption("Awu…")
	feedback.select(Feedback.State.DOWN)
	begin_collapse(target)
	add_ground_mark(person.position,0.8)
	show_contact_splash(person.position)
	audio.play_cue("reaction")

func add_shot(start: Vector2, direction: Vector2, friendly: bool, kind: String, velocity: float) -> void:
	shots.append({"point":start,"prior":start,"vector":direction.normalized()*velocity,
	"friendly":friendly,"kind":kind,"life":0.32 if friendly else 1.05,"rotation":rng.randf_range(0,TAU)})
	if shots.size()>90:
		shots.pop_front()

func collect_nearby() -> bool:
	if avatar == null or player_hp <= 0:
		return false
	for i in range(loot.size()):
		if avatar.position.distance_to(loot[i]["point"]) < 30.0:
			loot.remove_at(i)
			if not unlocked[1]:
				unlocked[1]=true
				slot=1
			else:
				spares[slot]+=1
			audio.play_cue("pickup")
			update_hud()
			return true
	return false

func add_ground_mark(at: Vector2, strength: float = 1.0) -> void:
	# Pre-rendered stain texture: one prominent soft mark and a few satellites.
	# Store only descriptors in a capped list; don't allocate sprite nodes.
	for i in range(5):
		var offset := Vector2.ZERO if i==0 else Vector2.from_angle(rng.randf_range(0.0,TAU))*rng.randf_range(5.0,13.0)
		ground_marks.append({
			"point":at+offset,
			"size":(13.0 if i==0 else rng.randf_range(2.5,6.0))*strength,
			"angle":rng.randf_range(0,TAU),
			"alpha":(0.80 if i==0 else rng.randf_range(0.35,0.65))
		})
	while ground_marks.size()>MAX_GROUND_MARKS:
		ground_marks.pop_front()

func show_contact_splash(at: Vector2) -> void:
	# Transient two-dimensional stage effect, placed at the contact point.
	for i in range(5):
		var direction := Vector2.from_angle(rng.randf_range(0,TAU))
		contact_splashes.append({
			"point":at + direction*rng.randf_range(1.0,3.0),
			"velocity":direction*rng.randf_range(10.0,28.0),
			"life":rng.randf_range(0.12,0.24),
			"max":0.24,
			"radius":rng.randf_range(1.1,2.4)
		})
	while contact_splashes.size()>MAX_CONTACT_SPLASHES:
		contact_splashes.pop_front()

func hit_enemy(target: Dictionary, amount: int) -> void:
	if bool(target["down"]):
		return
	target["hp"] = maxi(0,int(target["hp"])-amount)
	var feedback = target["feedback"]
	target["reaction"]=0.28
	register_character_impact(feedback)
	feedback.show_caption("Awu…")
	add_ground_mark(target["body"].position,1.3 if int(target["hp"]) <= 0 else 0.8)
	show_contact_splash(target["body"].position)
	if int(target["hp"]) <= 0:
		target["down"]=true
		target["attachment"].visible=false
		feedback.select(Feedback.State.DOWN)
		begin_collapse(target)
		defeated+=1
		if defeated%2 == 0:
			loot.append({"point":target["body"].position+Vector2(13,9),"age":0.0})
		if bool(target.get("male_voice",false)):
			var id := "male_looter_death_1" if male_death_take%2==0 else "male_looter_death_2"
			male_death_take+=1
			audio.play_cue(id)
		else:
			audio.play_cue("down")
	else:
		feedback.select(Feedback.State.STUMBLE)
		audio.play_cue("reaction")
	update_hud()

func hurt_player() -> void:
	if player_invincible > 0.0 or player_hp <= 0:
		return
	player_hp = maxi(0,player_hp-1)
	player_invincible = 0.82
	add_ground_mark(avatar.position,0.6)
	show_contact_splash(avatar.position)
	audio.play_cue("reaction")
	if player_hp <= 0:
		audio.play_cue("saafiya_death")
	update_hud()

func update_character(target: Dictionary, delta: float) -> void:
	var body: Actor = target["body"]
	var accessory: Sprite2D = target["attachment"]
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
	var motion := Vector2.ZERO
	var heading := to_avatar.angle()
	if (distance<240.0 or (bool(target["alerted"]) and distance<380.0)) and player_hp>0:
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
		if target["kind"] == "runner":
			if distance < 95.0:
				if not bool(target["flee_said"]):
					target["flee_said"] = true
					feedback.show_caption("Baleka!")
				motion = -to_avatar.normalized()*float(ROLES["runner"]["speed"])*delta
		elif target["kind"] in ["knife","cudgel"]:
			if distance>float(ROLES[target["kind"]]["reach"]):
				motion = to_avatar.normalized()*float(ROLES[target["kind"]]["speed"])*delta
			elif float(target["cooldown"])<=0:
				attack_character(target,to_avatar,distance)
		else:
			if distance>125.0:
				motion = to_avatar.normalized()*float(ROLES[target["kind"]]["speed"])*delta
			if float(target["cooldown"])<=0 and distance<float(ROLES[target["kind"]]["reach"]):
				attack_character(target,to_avatar,distance)
	else:
		var t := elapsed*0.47+float(target["wander"])
		motion=Vector2(sin(t),cos(t*0.77))*delta*7.0
		heading = motion.angle()
	if motion.length()>0.0 and not street.blocked(body.position+motion,8):
		body.position+=motion
	body.animate(delta,motion,heading,false,target["kind"]=="runner" and motion.length()>0.0)
	if float(target["reaction"])>0.0:
		body.modulate=Color(1.0,0.61,0.61)
	else:
		body.modulate=Color.WHITE
	var pose_progress := 1.0-float(target["attack"])/0.38
	var angle := heading + sin(clampf(pose_progress,0.0,1.0)*PI)*0.85 if float(target["attack"])>0 else heading
	accessory.rotation = angle - PI*0.5
	accessory.position = Vector2(0,9).rotated(angle)
	feedback.position=body.position

func attack_character(target: Dictionary, to_avatar: Vector2, distance: float) -> void:
	var kind: String = target["kind"]
	target["cooldown"] = 1.15 if kind in ["knife","cudgel"] else 1.75
	target["attack"] = 0.38
	if kind in ["knife","cudgel"]:
		if distance<27.0:
			hurt_player()
	else:
		var angle := to_avatar.angle()+rng.randf_range(-0.32,0.32)
		var direction := Vector2.from_angle(angle)
		var speed := 230.0 if kind in ["brick","slingshot"] else 350.0
		add_shot(target["body"].position+direction*10.0,direction,false,kind,speed)
		if kind == "pistol":
			audio.play_cue("cz75_shot",-4.0)
			on_gunfire(target["body"].position)

func step_shots(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var s: Dictionary=shots[i]
		s["prior"]=s["point"]
		s["point"]+=s["vector"]*delta
		s["rotation"]+=delta*9.0
		s["life"]-=delta
		var p: Vector2=s["point"]
		var previous: Vector2=s["prior"]
		var remove: bool = float(s["life"])<=0.0 or street.blocked(p,2.0)
		if not remove:
			if bool(s["friendly"]):
				for enemy in actors:
					if not bool(enemy["down"]) and Geometry2D.get_closest_point_to_segment(enemy["body"].position,previous,p).distance_to(enemy["body"].position) < 12.0:
						hit_enemy(enemy,1)
						shots_hit+=1
						remove=true
						break
			elif player_hp>0 and p.distance_to(avatar.position) < 10.0:
				hurt_player()
				remove=true
		if remove:
			motes.append({"point":p,"life":0.28})
			shots.remove_at(i)
	for i in range(motes.size()-1,-1,-1):
		motes[i]["life"]-=delta
		if float(motes[i]["life"])<=0:
			motes.remove_at(i)
	for i in range(contact_splashes.size()-1,-1,-1):
		var splash: Dictionary = contact_splashes[i]
		splash["point"] += splash["velocity"]*delta
		splash["velocity"] *= exp(-delta*8.0)
		splash["life"] -= delta
		if float(splash["life"]) <= 0.0:
			contact_splashes.remove_at(i)

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
	if avatar != null:
		avatar.modulate = Color(1.0,0.55,0.55) if player_invincible>0.0 and (int(elapsed*14.0)%2)==0 else Color.WHITE
	if smoke_test:
		return
	elapsed+=delta
	cooldown=maxf(0.0,cooldown-delta)
	player_invincible=maxf(0.0,player_invincible-delta)
	shout_cooldown=maxf(0.0,shout_cooldown-delta)
	if is_instance_valid(held_visual):
		held_visual.reload_amount = clampf(reload_clock,0.0,1.0)
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
	for splash in contact_splashes:
		var alpha := clampf(float(splash["life"])/float(splash["max"]),0.0,1.0)
		var point: Vector2 = splash["point"]
		draw_circle(point,float(splash["radius"])*alpha,Color(0.55,0.075,0.10,alpha*0.80),true,-1,true)
	for mark in ground_marks:
		var p: Vector2 = mark["point"]
		var size: float = mark["size"]
		var alpha: float = mark["alpha"]
		var angle: float = mark["angle"]
		draw_set_transform(p,angle)
		draw_texture_rect(BLOOD_STAIN,Rect2(-size*0.5,-size*0.5,size,size),false,Color(1,1,1,alpha))
	draw_set_transform(Vector2.ZERO)
	# Firearm actions have no visible beam, tracer or bullet sprite.
	# Only visibly thrown objects remain rendered as tiny, unlit props.
	for s in shots:
		var kind: String = s["kind"]
		if kind == "brick" or kind == "slingshot":
			var point: Vector2 = s["point"]
			var size := 3.0 if kind == "brick" else 1.4
			draw_circle(point,size,Color("#ab9181") if kind == "brick" else Color("#8a888b"),true,-1,true)
	for spark in motes:
		var strength := float(spark["life"])/0.28
		draw_circle(spark["point"],3.0*(1.0-strength)+1.0,Color(0.96,0.77,0.52,strength*0.55),false,0.9,true)
	for item in loot:
		var p: Vector2 = item["point"]
		draw_circle(p,8.5,Color(0.95,0.83,0.48,0.24),false,1.2,true)
		draw_circle(p,3.0,Color("#f3da96"),true,-1,true)

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
	hit_enemy(foe,1)
	assert(bool(foe["down"]))
	assert(defeated==1)
	assert(male_death_take==1)
	assert(ground_marks.size()>0 and ground_marks.size()<=MAX_GROUND_MARKS)
	assert(foe["feedback"].impact_marks.size()==2)
	assert(foe.has("fall_variant") and foe.has("fall_offset"))
	for i in range(90):
		advance_collapse(foe,1.0/60.0)
	assert(foe["body"].down_phase>=0.99)
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
	assert(collect_nearby()==false)
	equip(0)
	refill()
	set_phase(1)
	assert(actors.size()==12)
	assert(unlocked[2])
	add_shot(Vector2(400,300),Vector2.RIGHT,true,"spark",350.0)
	assert(shots.size()==1)
	print("Encounter smoke: actors, arcade damage, defeat, pickup, return wave and projectiles initialized.")
	get_tree().quit()
