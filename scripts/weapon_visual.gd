extends Node2D
# A separate cosmetic overlay for the approved VTK Saafiya artwork.
# All dimensions below are display pixels, not physical measurements.
const BERETTA: Texture2D = preload("res://assets/weapons/beretta84fs_overhead.svg")
const BACKUP: Texture2D = preload("res://assets/props/modern_icon.svg")
const LONGARM: Texture2D = preload("res://assets/props/longarm_icon.svg")
const DISPLAY_SPAN := 13.0
const LEFT_OFFSET := 3.1
const FORWARD_OFFSET := 4.0
const FLASH_DURATION := 0.055
const HAZE_DURATION := 0.27
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

func _draw() -> void:
	if not is_instance_valid(wearer):
		return
	var forward := Vector2.from_angle(aim_angle)
	var left := Vector2.from_angle(aim_angle-PI*0.5)
	var held := forward*FORWARD_OFFSET + left*LEFT_OFFSET
	var texture: Texture2D = BERETTA if equipment_slot==0 else (BACKUP if equipment_slot==1 else LONGARM)
	var span := DISPLAY_SPAN if equipment_slot==0 else (DISPLAY_SPAN*1.1 if equipment_slot==1 else DISPLAY_SPAN*1.6)
	# Left-arm bias in front of the character, without hiding the approved torso mesh.
	var sleeve_start := forward*0.4 + left*5.0
	draw_line(sleeve_start, held-forward*2.2,Color("#2c2632"),2.8,true)
	draw_line(sleeve_start+left*0.3,held-forward*2.2,Color("#59425a"),0.65,true)
	draw_circle(held-forward*2.0,1.2,Color("#b58065"))
	draw_set_transform(held,aim_angle+PI*0.5)
	draw_texture_rect(texture,Rect2(-Vector2.ONE*span*0.5,Vector2.ONE*span),false)
	draw_set_transform(Vector2.ZERO)
	var tip := held+forward*(span*0.40)
	if reload_amount>0.0:
		draw_arc(held,5.0,0,TAU,20,Color(0.94,0.84,0.62,reload_amount*0.3),0.55,true)
	if flash_time>0.0:
		var alpha := clampf(flash_time/FLASH_DURATION,0.0,1.0)
		draw_set_transform(tip,aim_angle)
		var reach := 3.0 + float(visual_variant)*0.5
		draw_colored_polygon(PackedVector2Array([Vector2(0,-1.3),Vector2(reach*.55,-.65),Vector2(reach,0),Vector2(reach*.55,.65),Vector2(0,1.3)]),Color(1.0,0.77,0.43,alpha*.90))
		draw_set_transform(Vector2.ZERO)
	if haze_time>0.0:
		var p := 1.0-haze_time/HAZE_DURATION
		var point := tip + forward*(2.0+6.0*p)
		draw_circle(point,2.0+4.0*p,Color(.52,.52,.55,(1.0-p)*0.16),true,-1,true)
