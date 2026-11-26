extends Node2D

const Art = preload("res://scripts/environment_art.gd")
# Occasional background vehicles. No combat or hostile AI.
const CAR_SIZE := Vector2(108.0,43.0)
const LEVEL_WIDTH := 2320.0
const MODELS := ["sedan_silver", "hatchback_sage", "sedan_ochre", "utility_ivory"]
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
	cars.append({
		"pos":Vector2(x,y),"direction":heading,
		"speed":float(49+(count%4)*7),
		"model":"security" if count % 5 == 4 else MODELS[count % MODELS.size()]
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
		Art.vehicle(self, Rect2(car["pos"], CAR_SIZE), car["model"], car["direction"])
