extends Node2D
# Arcade-style fictional action gameplay. All health, cooldown and movement
# values are game abstractions rather than real-world weapon performance.
const Actor = preload("res://scripts/actor.gd")
const Feedback = preload("res://scripts/character_feedback.gd")
const Props = preload("res://scripts/prop_library.gd")
const Audio = preload("res://scripts/preview_audio.gd")
const KIT := [
	{"name":"Sidearm","size":12,"interval":0.24,"travel":420.0},
	{"name":"Backup","size":10,"interval":0.31,"travel":400.0},
	{"name":"Long arm","size":24,"interval":0.14,"travel":490.0}
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
var rng := RandomNumberGenerator.new()
var actors: Array[Dictionary] = []
var shots: Array[Dictionary] = []
var motes: Array[Dictionary] = []
var ground_marks: Array[Dictionary] = []
const MAX_GROUND_MARKS := 72
var loot: Array[Dictionary] = []
var player_hp := 3
var player_invincible := 0.0
var cooldown := 0.0
var reload_clock := 0.0
var slot := 0
var rounds := [12,10,24]
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

func _ready() -> void:
	rng.seed = 4872011
	audio = Audio.new()
	add_child(audio)
	spawn_group(false)
	make_hud()
	smoke_test = "--encounter-smoke" in OS.get_cmdline_user_args()
	if smoke_test:
		run_test()

func spawn_group(return_wave: bool) -> void:
	var descriptions := [
		[Vector2(626,382),"knife",0],
		[Vector2(810,282),"pistol",1],
		[Vector2(1035,420),"brick",2],
		[Vector2(1330,290),"cudgel",4],
		[Vector2(1650,416),"slingshot",6],
		[Vector2(2060,350),"pistol",9],
		[Vector2(1180,420),"runner",11]
	]
	if return_wave:
		descriptions = [
			[Vector2(1680,260),"brick",7],
			[Vector2(1220,424),"cudgel",3],
			[Vector2(900,280),"slingshot",5],
			[Vector2(660,430),"pistol",8]
		]
	for desc in descriptions:
		spawn_character(desc[0],desc[1],int(desc[2]))

func spawn_character(at: Vector2, kind: String, look: int) -> void:
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
		"origin":at,"down":false,"visible_prop":true
	})

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
		if not bool(item["down"]):
			remaining += 1
	hud.text="HEALTH  %s   |   %s  %02d / %02d\nACTIVE  %d    DOWN  %d    HITS  %d/%d" % [
		"♥".repeat(player_hp)+"♡".repeat(3-player_hp),
		active["name"],rounds[slot],spares[slot],remaining,defeated,shots_hit,shots_fired]
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
	reload_clock = 0.0
	audio.play_cue("pickup")
	update_hud()

func refill() -> void:
	if player_hp <= 0:
		get_tree().reload_current_scene()
		return
	if reload_clock > 0.0 or spares[slot] <= 0 or rounds[slot] >= int(KIT[slot]["size"]):
		return
	reload_clock = 1.0
	audio.play_cue("pickup")

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
	add_shot(avatar.position+heading*10.0,heading,true,"spark",float(KIT[slot]["travel"]))
	audio.play_cue("fire")
	update_hud()

func add_shot(start: Vector2, direction: Vector2, friendly: bool, kind: String, velocity: float) -> void:
	shots.append({"point":start,"prior":start,"vector":direction.normalized()*velocity,
	"friendly":friendly,"kind":kind,"life":1.05,"rotation":rng.randf_range(0,TAU)})
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
	# Small, capped visual-only decals, batched in the encounter CanvasItem.
	for i in range(4):
		var origin := at + Vector2.from_angle(rng.randf_range(0.0, TAU)) * rng.randf_range(1.0,9.0)
		ground_marks.append({
			"point":origin,
			"size":rng.randf_range(1.0,3.6)*strength,
			"alpha":rng.randf_range(0.22,0.48)
		})
	while ground_marks.size()>MAX_GROUND_MARKS:
		ground_marks.pop_front()

func hit_enemy(target: Dictionary, amount: int) -> void:
	if bool(target["down"]):
		return
	target["hp"] = maxi(0,int(target["hp"])-amount)
	var feedback = target["feedback"]
	target["reaction"]=0.28
	feedback.marked=true
	add_ground_mark(target["body"].position,1.3 if int(target["hp"]) <= 0 else 0.8)
	if int(target["hp"]) <= 0:
		target["down"]=true
		target["attachment"].visible=false
		feedback.select(Feedback.State.DOWN)
		defeated+=1
		if defeated%2 == 0:
			loot.append({"point":target["body"].position+Vector2(13,9),"age":0.0})
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
	audio.play_cue("reaction")
	if player_hp <= 0:
		audio.play_cue("down")
	update_hud()

func update_character(target: Dictionary, delta: float) -> void:
	var body: Node2D = target["body"]
	var accessory: Sprite2D = target["attachment"]
	var feedback: Node2D = target["feedback"]
	target["reaction"]=maxf(0.0,float(target["reaction"])-delta)
	feedback.advance(delta)
	feedback.position=body.position
	if bool(target["down"]):
		var p: Dictionary = feedback.pose()
		body.rotation=float(p["rotation"])
		body.scale=Vector2.ONE*float(p["scale"])
		body.position+=Vector2(p["offset"])*delta*0.08
		return
	target["cooldown"]=maxf(0.0,float(target["cooldown"])-delta)
	target["attack"]=maxf(0.0,float(target["attack"])-delta)
	var to_avatar := avatar.position-body.position
	var distance := to_avatar.length()
	var motion := Vector2.ZERO
	var heading := to_avatar.angle()
	if distance<240.0 and player_hp>0:
		if not bool(target["alerted"]):
			target["alerted"]=true
			feedback.show_alert("?")
			audio.play_cue("alert")
		elif feedback.alert_time<=0.0 and feedback.alert=="?":
			feedback.show_alert("!")
		if target["kind"] == "runner":
			if distance < 95.0:
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
		audio.play_cue("fire")

func step_shots(delta: float) -> void:
	for i in range(shots.size()-1,-1,-1):
		var s: Dictionary=shots[i]
		s["prior"]=s["point"]
		s["point"]+=s["vector"]*delta
		s["rotation"]+=delta*9.0
		s["life"]-=delta
		var p: Vector2=s["point"]
		var remove: bool = float(s["life"])<=0.0 or street.blocked(p,2.0)
		if not remove:
			if bool(s["friendly"]):
				for enemy in actors:
					if not bool(enemy["down"]) and enemy["body"].position.distance_to(p) < 12.0:
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

func _physics_process(delta: float) -> void:
	if avatar != null:
		avatar.modulate = Color(1.0,0.55,0.55) if player_invincible>0.0 and (int(elapsed*14.0)%2)==0 else Color.WHITE
	if smoke_test:
		return
	elapsed+=delta
	cooldown=maxf(0.0,cooldown-delta)
	player_invincible=maxf(0.0,player_invincible-delta)
	if reload_clock>0:
		reload_clock=maxf(0.0,reload_clock-delta)
		if reload_clock<=0:
			rounds[slot]=int(KIT[slot]["size"])
			spares[slot]-=1
			audio.play_cue("reset")
			update_hud()
	if player_hp>0 and not finished:
		for item in actors:
			update_character(item,delta)
		step_shots(delta)
	queue_redraw()

func _draw() -> void:
	for mark in ground_marks:
		var p: Vector2 = mark["point"]
		var radius: float = mark["size"]
		var alpha: float = mark["alpha"]
		draw_circle(p+Vector2(0.7,1.0),radius+0.7,Color(0.12,0.06,0.09,alpha*0.32),true,-1,true)
		draw_circle(p,radius,Color(0.34,0.075,0.11,alpha),true,-1,true)
	for s in shots:
		var p: Vector2 = s["point"]
		var prev: Vector2 = s["prior"]
		var color := Color("#f4ce8a") if bool(s["friendly"]) else Color("#e3a4a0")
		draw_line(prev,p,color,1.3,true)
		draw_circle(p,2.1,color,true,-1,true)
	for spark in motes:
		var strength := float(spark["life"])/0.28
		draw_circle(spark["point"],3.0*(1.0-strength)+1.0,Color(0.96,0.77,0.52,strength*0.55),false,0.9,true)
	for item in loot:
		var p: Vector2 = item["point"]
		draw_circle(p,8.5,Color(0.95,0.83,0.48,0.24),false,1.2,true)
		draw_circle(p,3.0,Color("#f3da96"),true,-1,true)

func run_test() -> void:
	assert(actors.size()==7)
	assert(player_hp==3)
	var foe: Dictionary=actors[0]
	hit_enemy(foe,1)
	assert(int(foe["hp"])==1)
	hit_enemy(foe,1)
	assert(bool(foe["down"]))
	assert(defeated==1)
	assert(ground_marks.size()>0 and ground_marks.size()<=MAX_GROUND_MARKS)
	hurt_player()
	assert(player_hp==2)
	assert(collect_nearby()==false)
	equip(0)
	refill()
	set_phase(1)
	assert(actors.size()==11)
	assert(unlocked[2])
	add_shot(Vector2(400,300),Vector2.RIGHT,true,"spark",350.0)
	assert(shots.size()==1)
	print("Encounter smoke: actors, arcade damage, defeat, pickup, return wave and projectiles initialized.")
	get_tree().quit()
