extends Control
## Native Godot 4.4 HUD map, fixed chevron and rotating world.
## Everything is drawn in screen space inside the ornamental round opening.
var avatar: Node2D
var world: Node2D
var chapter: String = "upper_ridge"
const BRONZE := Color("#a7856a")
const MAP_BG := Color("#171b25")
const MAP_ROAD := Color("#55545b")
const MAP_WALL := Color("#938174")

func configure(player: Node2D, stage_world: Node2D, chapter_id: String) -> void:
	avatar = player
	world = stage_world
	chapter = chapter_id
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _physics_process(_delta: float) -> void:
	if is_instance_valid(avatar):
		queue_redraw()

func _draw() -> void:
	var center := size / 2.0
	var r := minf(size.x, size.y) * 0.475
	draw_circle(center, r, MAP_BG)
	if not is_instance_valid(avatar):
		_draw_chevron(center)
		return
	# These original game scenes use Y-down coordinates and the Actor.facing
	# field is its current direction. Turn the WORLD, not the fixed arrow.
	var world_rotation: float = -float(avatar.get("facing")) - PI / 2.0
	var zoom := minf(size.x, size.y) / 460.0
	var perimeter := PackedVector2Array()
	for i in range(48):
		perimeter.append(center + Vector2.from_angle(TAU * float(i) / 48.0) * r)
	var road: Rect2
	if chapter == "upper_ridge":
		road = Rect2(0,382,2320,270)
	elif chapter == "barricaded_house":
		road = Rect2(0,405,2320,274)
	else:
		road = Rect2(0,208,2320,284)
	_world_rect(road, MAP_ROAD, center, zoom, world_rotation, perimeter)
	# Tinted roadside boundaries and the actual authored building footprints.
	if chapter == "upper_ridge":
		for p in [Vector2(168,93),Vector2(642,91),Vector2(1284,92),Vector2(1864,91),Vector2(340,740),Vector2(955,740),Vector2(1570,740)]:
			_world_rect(Rect2(p + Vector2(38,37),Vector2(238,148)),Color("#6d726d"),center,zoom,world_rotation,perimeter)
	elif chapter == "barricaded_house":
		_world_rect(Rect2(1048,75,515,208),Color("#797c7d"),center,zoom,world_rotation,perimeter)
	if is_instance_valid(world):
		# Obstacle arrays belong to the current Godot world, not copied HUD art.
		for property_name in ["parked", "fixed_obstacles", "obstacles", "solid"]:
			var objects: Variant = world.get(property_name)
			if objects is Array:
				for item in objects:
					if item is Rect2:
						_world_rect(item, MAP_WALL, center,zoom,world_rotation,perimeter)
	# Subtle compass centre halo and the unrotated chevron. Never transform the
	# chevron with world_rotation; its apex stays at twelve o'clock.
	draw_circle(center, 8.5, Color(0.06,0.07,0.11,0.65))
	_draw_chevron(center)

func _world_rect(rect: Rect2, tint: Color, center: Vector2, zoom: float, spin: float, circle: PackedVector2Array) -> void:
	var outline := PackedVector2Array()
	for point in [rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)]:
		outline.append(center + (point - avatar.position).rotated(spin) * zoom)
	# Polygon clipping keeps scenery inside the circular compass aperture.
	for clipped in Geometry2D.intersect_polygons(outline, circle):
		if clipped.size() >= 3:
			draw_colored_polygon(clipped,tint)

func _draw_chevron(at: Vector2) -> void:
	var shape := PackedVector2Array([
		at + Vector2(0,-12),at + Vector2(8,8),at + Vector2(0,3),at + Vector2(-8,8)
	])
	draw_colored_polygon(shape,Color("#f0bfa7"))
	draw_polyline(PackedVector2Array([shape[0],shape[1],shape[2],shape[3],shape[0]]),Color("#30212a"),1.3,true)
	draw_line(at+Vector2(0,-10),at+Vector2(0,2),Color("#fff2cf"),1.2,true)
