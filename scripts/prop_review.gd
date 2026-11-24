extends Node2D
const Props = preload("res://scripts/prop_library.gd")

func _ready() -> void:
	if "--prop-smoke" in OS.get_cmdline_user_args():
		for item in Props.ITEMS:
			assert(item.texture != null)
			assert(item.texture.get_size() == Vector2(128,128))
		print("Prop review: all ", Props.ITEMS.size(), " textures loaded.")
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func _draw() -> void:
	draw_rect(Rect2(0,0,1280,720),Color("#1a1d26"))
	draw_string(ThemeDB.fallback_font,Vector2(32,46),"PINE RIDGE / PROP LIBRARY",HORIZONTAL_ALIGNMENT_LEFT,-1,27,Color("#e0d9d6"))
	draw_string(ThemeDB.fallback_font,Vector2(32,76),"Visual assets only · Esc returns to the street",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#aaa6af"))
	for i in range(Props.ITEMS.size()):
		var item: Dictionary = Props.ITEMS[i]
		var p := Vector2(32+(i%5)*245,104+floori(float(i)/5.0)*190)
		draw_rect(Rect2(p,Vector2(232,174)),Color("#343843"))
		draw_rect(Rect2(p,Vector2(232,174)),Color("#65616b"),false,1)
		draw_texture_rect(item.texture,Rect2(p+Vector2(52,8),Vector2(128,128)),false)
		draw_string(ThemeDB.fallback_font,p+Vector2(12,156),item.label,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("#e0d9d6"))
