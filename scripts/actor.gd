extends Node2D

const Art = preload("res://scripts/sprite_kit_art.gd")
const HERO_LOWER_WALK := preload("res://assets/characters/sprite_kit/saafiya_walk_lower.png")
const HERO_LOWER_RUN := preload("res://assets/characters/sprite_kit/saafiya_run_lower.png")
const HERO_LOWER_IDLE := preload("res://assets/characters/sprite_kit/saafiya_idle_lower.png")
const HERO_UPPER := preload("res://assets/characters/sprite_kit/saafiya_upper_poses.png")
const HERO_DEFEAT := preload("res://assets/characters/sprite_kit/saafiya_defeat.png")
const DEFEAT_TILE := 192
const DEFEAT_DURATION := 1.05
const TILE := 128
const COUNT := 16
const WALK_DISTANCE := 91.0 * 1.12
const RUN_DISTANCE := 148.0 * 0.64
const DISPLAY_SIZE := 42.0
const REACTION_TILE := 176
const REACTION_COLUMNS := 5
const REACTION_FRAMES := 10
const COLLAPSE_NAMES := ["FORWARD", "BACKWARD", "LEFT", "RIGHT", "KNEELING", "SEATED"]
const COLLAPSE_TIMES := [0.80, 0.91, 0.76, 0.82, 1.04, 1.16]
const STUMBLE := 6
var gait_phase := 0.0
var gait_running := false
var gait_moving := false
const Wardrobe = preload("res://scripts/crowd_wardrobe.gd")
var wardrobe_index := -1
var npc_idle: Texture2D
var npc_walk: Texture2D
var npc_run: Texture2D
var npc_down: Texture2D
var npc_down_back: Texture2D
var npc_down_side: Texture2D
var npc_reactions: Texture2D
var collapse_style := 0
var down_phase := -1.0
var collapse_facing := 0.0
var entry_atlas: Texture2D
var entry_frame := 0
var entry_reaction := -1
var entry_reaction_weight := 0.0
var reaction_phase := -1.0
var reaction_duration := 0.28
var cosmetic_accessory: Texture2D
var show_accessory := false
var hero := false
var defeat_elapsed := -1.0
var defeat_heading := 0.0
var gear_row := 0
var gear_frame := 0
var gear_heading := 0.0
var facing := 0.0
var travel := 0.0
var stride := 0.0
var motion := 0.0
var crouched := false
var jacket := Color("#55516a")
var skin := Color("#b68062")
var hair := Color("#392b34")

func _ready() -> void:
	if not hero and wardrobe_index >= 0:
		var prefix := "res://assets/characters/crowd/npc_%02d_" % posmod(wardrobe_index,12)
		npc_idle = load_npc_texture(prefix + "idle.png", Vector2(128,128))
		npc_walk = load_npc_texture(prefix + "walk.png", Vector2(512,256))
		npc_run = load_npc_texture(prefix + "run.png", Vector2(512,256))
		npc_down = load_npc_texture(prefix + "down.png", Vector2(512,256))
		npc_down_back = load_npc_texture(prefix + "down_back.png", Vector2(512,256))
		npc_down_side = load_npc_texture(prefix + "down_side.png", Vector2(512,256))
		npc_reactions = load_npc_texture(
			"res://assets/characters/reactions/npc_%02d.png" % posmod(wardrobe_index, 12),
			Vector2(REACTION_TILE * REACTION_COLUMNS, REACTION_TILE * 2 * (STUMBLE + 1))
		)
		cosmetic_accessory = load_npc_texture("res://assets/characters/accessories/backpack.png", Vector2(128,128))
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if hero:
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func start_defeat() -> void:
	defeat_elapsed = 0.0
	defeat_heading = gear_heading
	queue_redraw()

func advance_defeat(delta: float) -> void:
	defeat_elapsed = minf(DEFEAT_DURATION, defeat_elapsed + delta)
	queue_redraw()

func set_gear_pose(row: int, frame: int, heading: float) -> void:
	gear_row = row
	gear_frame = frame
	gear_heading = heading
	if hero:
		queue_redraw()

func draw_hero() -> void:
	var blend := smoothstep(0.0, 0.12, defeat_elapsed)
	if blend < 1.0:
		draw_hero_standing(1.0 - blend)
	if blend > 0.0:
		var frame := mini(COUNT - 1, floori(defeat_elapsed * COUNT / DEFEAT_DURATION))
		var tile := float(DEFEAT_TILE)
		var cell := Rect2((frame % 4) * tile, floori(frame / 4.0) * tile, tile, tile)
		draw_gait_layer(HERO_DEFEAT, cell, defeat_heading, Vector2.ONE * (DISPLAY_SIZE * tile / TILE), blend)

func draw_hero_standing(opacity: float) -> void:
	var size := Vector2(DISPLAY_SIZE, DISPLAY_SIZE * (0.82 if crouched else 1.0))
	var lower := HERO_LOWER_IDLE
	if gait_moving:
		lower = HERO_LOWER_RUN if gait_running else HERO_LOWER_WALK
	draw_gait_layer(lower, gait_cell(sprite_frame()), travel if gait_moving else gear_heading, size, opacity)
	var upper := Rect2(gear_frame * Art.CELL, gear_row * Art.CELL, Art.CELL, Art.CELL)
	draw_gait_layer(HERO_UPPER, upper, gear_heading, size, opacity)

func load_npc_texture(path: String, expected_size: Vector2) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var atlas := ResourceLoader.load(path) as Texture2D
	if atlas == null or atlas.get_size() != expected_size:
		push_warning("Invalid crowd asset: " + path)
		return null
	return atlas

func has_npc_atlases() -> bool:
	return npc_idle != null and npc_walk != null and npc_run != null

func sprite_frame() -> int:
	return int(floor(gait_phase * COUNT)) % COUNT if gait_moving else 0

func has_hero_atlases() -> bool:
	return hero and HERO_LOWER_IDLE.get_size() == Vector2(TILE, TILE) \
		and HERO_LOWER_WALK.get_size() == Vector2.ONE * TILE * 4 \
		and HERO_LOWER_RUN.get_size() == Vector2.ONE * TILE * 4 \
		and HERO_UPPER.get_size() == Vector2(Art.POSE_COLUMNS, Art.CATALOGUE.size()) * TILE \
		and HERO_DEFEAT.get_size() == Vector2.ONE * DEFEAT_TILE * 4

func draw_gait_layer(atlas: Texture2D, source: Rect2, angle: float, size: Vector2, opacity: float = 1.0) -> void:
	draw_set_transform(Vector2.ZERO, angle - PI / 2.0)
	draw_texture_rect_region(atlas, Rect2(-size / 2.0, size), source, Color(1, 1, 1, opacity), false, true)
	draw_set_transform(Vector2.ZERO)

func npc_gait_frame() -> int:
	return floori(gait_phase * 8.0) % 8 if gait_moving else 0

func npc_gait_atlas() -> Texture2D:
	return (npc_run if gait_running else npc_walk) if gait_moving else npc_idle

func gait_cell(frame: int) -> Rect2:
	return Rect2((frame % 4) * TILE, floori(float(frame) / 4.0) * TILE, TILE, TILE)

func reaction_frame(phase: float) -> int:
	return clampi(floori(phase * REACTION_FRAMES), 0, REACTION_FRAMES - 1)

func reaction_cell(style: int, frame: int) -> Rect2:
	return Rect2((frame % REACTION_COLUMNS) * REACTION_TILE,
		(style * 2 + floori(float(frame) / float(REACTION_COLUMNS))) * REACTION_TILE, REACTION_TILE, REACTION_TILE)

func reaction_opacity() -> float:
	if reaction_phase < 0.0:
		return 0.0
	return smoothstep(0.0, 0.24, reaction_phase) * (1.0 - smoothstep(0.67, 1.0, reaction_phase))

func start_reaction(duration: float) -> void:
	if npc_reactions != null and down_phase < 0.0:
		reaction_phase = 0.0
		reaction_duration = duration

func start_collapse(style: int) -> void:
	collapse_style = posmod(style, COLLAPSE_NAMES.size())
	collapse_facing = travel if gait_moving else facing
	entry_atlas = npc_gait_atlas()
	entry_frame = npc_gait_frame()
	entry_reaction = reaction_frame(reaction_phase) if reaction_phase >= 0.0 else -1
	entry_reaction_weight = reaction_opacity()
	reaction_phase = -1.0
	down_phase = 0.0
	queue_redraw()

func set_down_progress(value: float) -> void:
	var next := clampf(value, 0.0, 1.0) if value >= 0.0 else -1.0
	if not is_equal_approx(down_phase, next):
		down_phase = next
		queue_redraw()

func draw_reaction(style: int, frame: int, angle: float, opacity: float = 1.0) -> void:
	var sprite_size := DISPLAY_SIZE * float(REACTION_TILE) / float(TILE)
	draw_gait_layer(npc_reactions, reaction_cell(style, frame), angle, Vector2.ONE * sprite_size, opacity)

func draw_collapse() -> bool:
	if npc_reactions != null:
		var blend := smoothstep(0.0, 0.18, down_phase)
		if blend < 1.0:
			var remaining := 1.0 - blend
			if entry_atlas != null and entry_reaction_weight < 1.0:
				draw_gait_layer(entry_atlas, gait_cell(entry_frame), collapse_facing,
					Vector2.ONE * DISPLAY_SIZE, remaining * (1.0 - entry_reaction_weight))
			if entry_reaction_weight > 0.0:
				draw_reaction(STUMBLE, entry_reaction, collapse_facing, remaining * entry_reaction_weight)
		if blend > 0.0:
			draw_reaction(collapse_style, reaction_frame(down_phase), collapse_facing, blend)
		return true
	var legacy := npc_down
	if collapse_style == 1 or collapse_style == 5:
		legacy = npc_down_back if npc_down_back != null else legacy
	elif collapse_style == 2 or collapse_style == 3:
		legacy = npc_down_side if npc_down_side != null else legacy
	if legacy != null:
		draw_gait_layer(legacy, gait_cell(mini(7, floori(down_phase * 8.0))), collapse_facing, Vector2.ONE * DISPLAY_SIZE)
		return true
	return false

func animate(delta: float, displacement: Vector2, aim_angle: float, low: bool = false, running: bool = false) -> void:
	if reaction_phase >= 0.0:
		reaction_phase += delta / reaction_duration
		if reaction_phase >= 1.0:
			reaction_phase = -1.0
	var dist := displacement.length()
	gait_running = running and not low
	gait_moving = dist > 0.01
	if gait_moving:
		var cycle_distance := RUN_DISTANCE if gait_running else WALK_DISTANCE
		gait_phase = fposmod(gait_phase + dist / cycle_distance, 1.0)
	motion = move_toward(motion, 1.0 if dist > 0.01 else 0.0, delta * 8.0)
	if dist > 0.01:
		travel = lerp_angle(travel, displacement.angle(), 1.0-exp(-delta*18.0))
		stride = fmod(stride + dist * 0.23, TAU)
	facing = lerp_angle(facing,aim_angle,1.0-exp(-delta*17.0))
	crouched = low
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2(2,3),10,Color(0.09,0.07,0.12,0.27),true,-1,true)
	if hero:
		draw_hero()
		return
	if wardrobe_index >= 0 and down_phase >= 0.0 and draw_collapse():
		return
	if wardrobe_index >= 0 and has_npc_atlases():
		var angle := travel if gait_moving else facing
		var blend := reaction_opacity()
		draw_gait_layer(npc_gait_atlas(), gait_cell(npc_gait_frame()), angle, Vector2.ONE * DISPLAY_SIZE, 1.0 - blend)
		if blend > 0.0:
			draw_reaction(STUMBLE, reaction_frame(reaction_phase), angle, blend)
		if show_accessory and cosmetic_accessory != null:
			draw_set_transform(Vector2.ZERO, angle - PI / 2.0)
			draw_texture_rect(cosmetic_accessory, Rect2(-5,-8,10,10),false)
			draw_set_transform(Vector2.ZERO)
		return
	if wardrobe_index >= 0:
		Wardrobe.render(self, wardrobe_index, travel, facing, stride, motion, gait_running)
		return
	draw_set_transform(Vector2.ZERO,travel)
	for side in [-1,1]:
		var swing := sin(stride + (PI if side > 0 else 0.0))*motion*5.0
		var hip := Vector2(-2,side*3.2)
		var foot := Vector2(-4+swing,side*4.0)
		draw_line(hip,foot,Color("#34303d"),4,true)
		draw_line(foot-Vector2(1.4,0),foot+Vector2(3,0),Color("#211d29"),4,true)
	draw_set_transform(Vector2.ZERO,facing)
	var scale_y := 0.82 if crouched else 1.0
	draw_set_transform(Vector2.ZERO,facing,Vector2(scale_y,1))
	var cloth := jacket
	draw_circle(Vector2(-1,0),6.9,cloth.darkened(0.28),true,-1,true)
	draw_circle(Vector2(-1,0),6.0,cloth,true,-1,true)
	for side in [-1,1]:
		var shoulder := Vector2(-1,side*5.2)
		var hand := Vector2(3.7+sin(stride+side*PI*0.5)*motion*1.3,side*6.3)
		draw_line(shoulder,hand,cloth.lightened(0.10),3.8,true)
		draw_circle(hand,1.65,skin,true,-1,true)
	draw_circle(Vector2(2.5,0),4.5,skin,true,-1,true)
	draw_circle(Vector2(1,0),4.6,hair,true,-1,true)
	draw_set_transform(Vector2.ZERO)
