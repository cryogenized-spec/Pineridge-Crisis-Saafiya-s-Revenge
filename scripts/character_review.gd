extends Node2D
const Actor = preload("res://scripts/actor.gd")
const Wardrobe = preload("res://scripts/crowd_wardrobe.gd")
var actors: Array[Actor] = []
var mode := 1
var heading := 0.0
var auto_turn := false
var enlarged := true
var timer := 0.0
var info: Label
var smoke := false

func _ready() -> void:
	smoke = "--review-smoke" in OS.get_cmdline_user_args()
	var title := Label.new()
	title.position = Vector2(32,20)
	title.text = "PINE RIDGE  /  CHARACTER WORKBENCH"
	title.add_theme_font_size_override("font_size",28)
	add_child(title)
	info = Label.new()
	info.position = Vector2(34,60)
	info.add_theme_font_size_override("font_size",16)
	add_child(info)
	for i in range(Wardrobe.LOOKS.size()):
		var x := 32.0 + float(i % 4) * 306.0
		var y := 112.0 + float(floori(float(i) / 4.0)) * 187.0
		var actor := Actor.new()
		actor.wardrobe_index = i
		actor.position = Vector2(x+150,y+73)
		actor.scale = Vector2(4,4)
		add_child(actor)
		actors.append(actor)
		var name_label := Label.new()
		name_label.position = Vector2(x+12,y+130)
		name_label.text = "%02d  %s" % [i+1,Wardrobe.look(i).name]
		name_label.add_theme_font_size_override("font_size",16)
		add_child(name_label)
	refresh()
	queue_redraw()

func refresh() -> void:
	info.text = "%s   |   %s   |   1 idle · 2 walk · 3 run · Left/Right rotate · T auto-turn · Z scale · Esc return" % [["IDLE","WALK","RUN"][mode],"4× world scale" if enlarged else "Gameplay scale (2×)"]
	for a in actors:
		a.scale = Vector2.ONE * (4.0 if enlarged else 2.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_1: mode = 0
		KEY_2: mode = 1
		KEY_3: mode = 2
		KEY_LEFT: heading -= PI/4.0
		KEY_RIGHT: heading += PI/4.0
		KEY_T: auto_turn = not auto_turn
		KEY_Z: enlarged = not enlarged
		KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	refresh()

func _physics_process(delta: float) -> void:
	timer += delta
	if smoke:
		mode = mini(2, floori(timer*3.0))
		heading = timer
	if auto_turn:
		heading += delta * 0.6
	var speed := [0.0,91.0,148.0][mode] as float
	var dir := Vector2.from_angle(heading)
	for a in actors:
		a.animate(delta,dir*speed*delta,heading,false,mode==2)
	if smoke and timer > 1.1:
		assert(actors.size()==Wardrobe.LOOKS.size())
		assert(actors[0].gait_running)
		print("Crowd review: all presets initialized; idle/walk/run exercised.")
		get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#1a1d26"))
	for i in range(Wardrobe.LOOKS.size()):
		var x := 32.0 + float(i%4)*306.0
		var y := 112.0 + float(floori(float(i)/4.0))*187.0
		var r := Rect2(x,y,294,174)
		draw_rect(r,Color("#353943"))
		draw_rect(r,Color("#64616a"),false,1.0)
		for j in range(12,282,24):
			draw_line(Vector2(x+j,y+8),Vector2(x+j,y+120),Color(1,1,1,0.035),1)
		for j in range(8,120,24):
			draw_line(Vector2(x+8,y+j),Vector2(x+286,y+j),Color(1,1,1,0.035),1)
		draw_line(Vector2(x+8,y+122),Vector2(x+286,y+122),Color("#51545e"),1)
