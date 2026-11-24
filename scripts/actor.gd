extends Node2D

const WALK_ATLAS := "res://assets/characters/saafiya/walk_atlas.png"
const RUN_ATLAS := "res://assets/characters/saafiya/run_atlas.png"
const TILE := 128
const COUNT := 16
const WALK_DISTANCE := 91.0 * 1.12
const RUN_DISTANCE := 148.0 * 0.64
const DISPLAY_SIZE := 42.0
var walk_lower: Texture2D
var walk_upper: Texture2D
var run_lower: Texture2D
var run_upper: Texture2D
var walk_texture: Texture2D
var run_texture: Texture2D
var gait_phase := 0.0
var gait_running := false
var gait_moving := false
const Wardrobe = preload("res://scripts/crowd_wardrobe.gd")
var wardrobe_index := -1
var hero := false
var facing := 0.0
var travel := 0.0
var stride := 0.0
var motion := 0.0
var crouched := false
var jacket := Color("#55516a")
var skin := Color("#b68062")
var hair := Color("#392b34")

func _ready() -> void:
	if hero:
		walk_texture = load_atlas(WALK_ATLAS)
		run_texture = load_atlas(RUN_ATLAS)
		walk_lower = load_atlas("res://assets/characters/saafiya/walk_lower_atlas.png")
		walk_upper = load_atlas("res://assets/characters/saafiya/walk_upper_atlas.png")
		run_lower = load_atlas("res://assets/characters/saafiya/run_lower_atlas.png")
		run_upper = load_atlas("res://assets/characters/saafiya/run_upper_atlas.png")
		texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func load_atlas(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	var atlas := ResourceLoader.load(path) as Texture2D
	if atlas == null or atlas.get_size() != Vector2(512, 512):
		push_warning("Invalid Saafiya atlas: " + path)
		return null
	return atlas

func sprite_frame() -> int:
	return int(floor(gait_phase * COUNT)) % COUNT if gait_moving else 0

func has_approved_atlases() -> bool:
	return walk_texture != null and run_texture != null

func has_layered_atlases() -> bool:
	return walk_lower != null and walk_upper != null and run_lower != null and run_upper != null

func draw_gait_layer(atlas: Texture2D, source: Rect2, angle: float, size: Vector2) -> void:
	draw_set_transform(Vector2.ZERO, angle - PI / 2.0)
	draw_texture_rect_region(atlas, Rect2(-size / 2.0, size), source)
	draw_set_transform(Vector2.ZERO)

func animate(delta: float, displacement: Vector2, aim_angle: float, low: bool = false, running: bool = false) -> void:
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
	if not hero and wardrobe_index >= 0:
		Wardrobe.render(self, wardrobe_index, travel, facing, stride, motion, gait_running)
		return
	if hero and has_layered_atlases():
		var is_run := gait_running and gait_moving
		var frame := sprite_frame()
		var source := Rect2((frame % 4) * TILE, floori(float(frame) / 4.0) * TILE, TILE, TILE)
		var size := Vector2(DISPLAY_SIZE, DISPLAY_SIZE * (0.82 if crouched else 1.0))
		# Independent unarmed visual orientation; shared center and animation phase.
		draw_gait_layer(run_lower if is_run else walk_lower, source, travel, size)
		draw_gait_layer(run_upper if is_run else walk_upper, source, facing, size)
		return
	if hero and has_approved_atlases():
		var atlas := run_texture if gait_running and gait_moving else walk_texture
		var frame := sprite_frame()
		var source := Rect2((frame % 4) * TILE, floori(float(frame) / 4.0) * TILE, TILE, TILE)
		# V8 faces screen-down. The atlas pivot remains at the center of every cell.
		var angle := travel if gait_moving else facing
		draw_set_transform(Vector2.ZERO, angle - PI / 2.0)
		var size := Vector2(DISPLAY_SIZE, DISPLAY_SIZE * (0.82 if crouched else 1.0))
		draw_texture_rect_region(atlas, Rect2(-size / 2.0, size), source)
		draw_set_transform(Vector2.ZERO)
		return
	draw_set_transform(Vector2.ZERO,travel)
	for side in [-1,1]:
		var swing := sin(stride + (PI if side > 0 else 0.0))*motion*5.0
		var hip := Vector2(-2,side*3.2)
		var foot := Vector2(-4+swing,side*4.0)
		draw_line(hip,foot,Color("#34303d"),4,true)
		draw_line(foot-Vector2(1.4,0),foot+Vector2(3,0),Color("#211d29"),4,true)
		if hero:
			draw_line(foot,foot+Vector2(1.6,0),Color("#93858d"),0.8,true)
	draw_set_transform(Vector2.ZERO,facing)
	var scale_y := 0.82 if crouched else 1.0
	draw_set_transform(Vector2.ZERO,facing,Vector2(scale_y,1))
	var cloth := Color("#25202e") if hero else jacket
	draw_circle(Vector2(-1,0),6.9,cloth.darkened(0.28),true,-1,true)
	draw_circle(Vector2(-1,0),6.0,cloth,true,-1,true)
	for side in [-1,1]:
		var shoulder := Vector2(-1,side*5.2)
		var hand := Vector2(3.7+sin(stride+side*PI*0.5)*motion*1.3,side*6.3)
		draw_line(shoulder,hand,cloth.lightened(0.10),3.8,true)
		draw_circle(hand,1.65,skin,true,-1,true)
		if hero:
			draw_line(shoulder,hand,Color(0.57,0.46,0.57,0.42),0.65,true)
	draw_circle(Vector2(2.5,0),4.5,skin,true,-1,true)
	draw_circle(Vector2(1,0),4.6,hair,true,-1,true)
	if hero:
		for i in range(9):
			var a := i*TAU/9.0
			var p := Vector2(-0.5,0)+Vector2.from_angle(a)*3.1
			draw_circle(p,2.5,Color("#422739").lightened(0.09 if i%2==0 else 0.0),true,-1,true)
		draw_circle(Vector2(-3.0,0),2.5,Color("#592c45"),true,-1,true)
		for side in [-1,1]:
			draw_arc(Vector2(3.1,side*3.6),1.2,0,TAU,12,Color("#d6bd9a"),0.7,true)
		draw_line(Vector2(1.7,-3.2),Vector2(1.7,3.2),Color("#211c29"),1.1,true)
	draw_set_transform(Vector2.ZERO)
