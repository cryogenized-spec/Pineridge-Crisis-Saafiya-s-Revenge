extends Node2D
# Occasional background vehicles. No combat or hostile AI.
const CAR_SIZE := Vector2(108.0,43.0)
const LEVEL_WIDTH := 2320.0
var avatar: Node2D
var top_lane := 451.0
var bottom_lane := 608.0
var cars: Array[Dictionary] = []
var elapsed := 0.0
var next_spawn := 13.0
var count := 0

func configure(actor: Node2D, first_lane: float, second_lane: float) -> void:
	avatar=actor
	top_lane=first_lane
	bottom_lane=second_lane

func _process(delta: float) -> void:
	elapsed+=delta
	if elapsed>=next_spawn:
		next_spawn=elapsed+22.0+float(count%3)*4.0
		if cars.size()<2:
			spawn_car()
	for i in range(cars.size()-1,-1,-1):
		var car: Dictionary=cars[i]
		var center: Vector2=car["pos"]+CAR_SIZE*0.5
		var close: bool = is_instance_valid(avatar) and center.distance_to(avatar.position)<67.0
		# Give the player space. Vehicles are scene atmosphere rather than hazards.
		if not close:
			car["pos"]=Vector2(car["pos"])+Vector2(float(car["direction"])*float(car["speed"])*delta,0)
		if float(Vector2(car["pos"]).x)<-170.0 or float(Vector2(car["pos"]).x)>LEVEL_WIDTH+170.0:
			cars.remove_at(i)
	queue_redraw()

func spawn_car() -> void:
	var heading: int=1 if count%2==0 else -1
	var y: float=top_lane if heading==1 else bottom_lane
	var x: float=-145.0 if heading==1 else LEVEL_WIDTH+30.0
	var colours := [Color("#839aa2"),Color("#968980"),Color("#6e7b75"),Color("#e1dfd4")]
	cars.append({
		"pos":Vector2(x,y),"direction":heading,
		"speed":float(49+(count%4)*7),
		"colour":colours[count%colours.size()],"security":count%5==4
	})
	count+=1

func blocked(p: Vector2, radius: float=7.0) -> bool:
	for car in cars:
		var rect:=Rect2(Vector2(car["pos"]),CAR_SIZE)
		if rect.grow(radius).has_point(p):
			return true
	return false

func _draw() -> void:
	for car in cars:
		var pos: Vector2=car["pos"]
		var colour: Color=car["colour"]
		var shape:=Rect2(pos,CAR_SIZE)
		draw_rect(Rect2(pos+Vector2(4,5),CAR_SIZE),Color(0.05,0.08,0.1,0.25))
		draw_rect(shape,colour.darkened(0.32))
		draw_rect(shape.grow(-3.0),colour)
		for xx in [12.0,88.0]:
			draw_rect(Rect2(pos+Vector2(xx,-4),Vector2(12,7)),Color("#262a2c"))
			draw_rect(Rect2(pos+Vector2(xx,40),Vector2(12,7)),Color("#262a2c"))
		draw_rect(Rect2(pos+Vector2(30,5),Vector2(48,33)),Color("#344751"))
		draw_rect(Rect2(pos+Vector2(33,8),Vector2(42,27)),Color("#779096"))
		draw_line(pos+Vector2(77,7),pos+Vector2(77,36),colour.lightened(0.25),2.0)
		if bool(car["security"]):
			draw_rect(Rect2(pos+Vector2(9,15),Vector2(16,9)),Color("#263b4b"))
			draw_string(ThemeDB.fallback_font,pos+Vector2(10,22),"S",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color.WHITE)
