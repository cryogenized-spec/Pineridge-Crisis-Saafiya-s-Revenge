extends Node2D
# A separate cosmetic overlay for the approved VTK Saafiya artwork.
# All dimensions below are display pixels, not physical measurements.
const BERETTA: Texture2D = preload("res://assets/weapons/beretta84fs_overhead.svg")
const BACKUP: Texture2D = preload("res://assets/props/modern_icon.svg")
const LONGARM: Texture2D = preload("res://assets/props/longarm_icon.svg")
const DISPLAY_SPAN := 10.4
const BACKUP_SPAN := 14.3
const LONGARM_SPAN := 20.8
const LEFT_OFFSET := 2.8
const FORWARD_OFFSET := 8.0
const FLASH_DURATION := 0.048
const HAZE_DURATION := 0.19
var wearer: Node2D
var equipment_slot := 0
var flash_time := 0.0
var haze_time := 0.0
var aim_angle := 0.0
var reload_amount := 0.0
var visual_variant := 0

func configure(actor: Node2D) -> void:
	wearer = actor

func choose_slot(index: int) -> void:
	equipment_slot = clampi(index,0,2)
	queue_redraw()

func burst() -> void:
	flash_time = FLASH_DURATION
	haze_time = HAZE_DURATION
	visual_variant=(visual_variant+1)%3
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(wearer):
		return
	position=wearer.position
	aim_angle=float(wearer.get("facing"))
	flash_time=maxf(0.0,flash_time-delta)
	haze_time=maxf(0.0,haze_time-delta)
	queue_redraw()

func draw_sleeved_arm(shoulder: Vector2, elbow: Vector2, hand: Vector2, left_side: bool) -> void:
	# Gothic fabric, cuff, skin and highlight layers at overhead sprite scale.
	var dark := Color("#1b1723")
	var fabric := Color("#342a3a")
	var shine := Color("#5b495d")
	var skin := Color("#ac7963")
	draw_line(shoulder,elbow,dark,5.1,true)
	draw_line(shoulder,elbow,fabric,3.6,true)
	draw_circle(elbow,2.5,dark,true,-1,true)
	draw_circle(elbow,1.9,fabric,true,-1,true)
	var cuff := elbow.lerp(hand,0.69)
	draw_line(elbow,cuff,dark,4.4,true)
	draw_line(elbow,cuff,fabric,3.0,true)
	draw_line(shoulder.lerp(elbow,0.20),elbow,shine,0.75,true)
	draw_line(elbow.lerp(cuff,0.12),cuff,shine,0.60,true)
	draw_line(cuff,hand,skin.darkened(0.22),2.9,true)
	draw_line(cuff,hand,skin,2.1,true)
	draw_circle(cuff,1.6,Color("#201925"),true,-1,true)
	draw_circle(hand,1.9,skin,true,-1,true)
	# Small dark glove/nail detail; no mechanical grip simulation.
	draw_circle(hand+Vector2(0.6,0.2),0.55,Color("#211b24"),true,-1,true)

func _draw() -> void:
	if not is_instance_valid(wearer):
		return
	var forward := Vector2.from_angle(aim_angle)
	var left := Vector2.from_angle(aim_angle-PI*0.5)
	var held := forward*FORWARD_OFFSET + left*LEFT_OFFSET
	var texture: Texture2D = BERETTA if equipment_slot==0 else (BACKUP if equipment_slot==1 else LONGARM)
	var span := DISPLAY_SPAN if equipment_slot==0 else (BACKUP_SPAN if equipment_slot==1 else LONGARM_SPAN)
	# Independent, deliberately left-biased overhead costume/arm overlay.
	# The detailed 3D torso atlas remains unchanged underneath these layers.
	var left_shoulder := -forward*1.0 + left*5.8
	var left_elbow := forward*2.6 + left*5.1
	var left_hand := held-forward*2.6
	var right_shoulder := -forward*1.0-left*5.7
	var right_elbow := forward*2.1-left*4.1
	var right_hand := held-forward*2.7-left*0.7
	draw_sleeved_arm(right_shoulder,right_elbow,right_hand,false)
	draw_sleeved_arm(left_shoulder,left_elbow,left_hand,true)
	draw_set_transform(held,aim_angle+PI*0.5)
	draw_texture_rect(texture,Rect2(-Vector2.ONE*span*0.5,Vector2.ONE*span),false)
	draw_set_transform(Vector2.ZERO)
	var tip := held+forward*(span*0.40)
	if reload_amount>0.0:
		draw_arc(held,5.0,0,TAU,20,Color(0.94,0.84,0.62,reload_amount*0.3),0.55,true)
	if flash_time>0.0:
		var alpha := clampf(flash_time/FLASH_DURATION,0.0,1.0)
		draw_set_transform(tip,aim_angle)
		var reach := 2.35 + float(visual_variant)*0.25
		draw_colored_polygon(PackedVector2Array([Vector2(0,-1.3),Vector2(reach*.55,-.65),Vector2(reach,0),Vector2(reach*.55,.65),Vector2(0,1.3)]),Color(1.0,0.86,0.60,alpha*.85))
		draw_set_transform(Vector2.ZERO)
	if haze_time>0.0:
		var p := 1.0-haze_time/HAZE_DURATION
		var point := tip + forward*(1.2+3.5*p)
		draw_circle(point,1.5+2.3*p,Color(.54,.54,.57,(1.0-p)*0.105),true,-1,true)
