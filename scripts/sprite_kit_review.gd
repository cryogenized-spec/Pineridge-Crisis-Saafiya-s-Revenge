extends CanvasLayer
## Sprite and equipment preview reused from a paused chapter or as a standalone scene.
signal close_requested

const Actor = preload("res://scripts/actor.gd")
const Art = preload("res://scripts/sprite_kit_art.gd")
const WeaponVisual = preload("res://scripts/weapon_visual.gd")
const GroundDecals = preload("res://scripts/ground_decals.gd")
const CREAM := Color("#f4ddc5")
const TEXT := Color("#cdbab7")
const COPPER := Color("#c7916f")
const BOARD := Color("#2a252e")

var root: Control
var cast_sprite: TextureRect
var cast_cell := AtlasTexture.new()
var preview_world: Node2D
var mannequin: Actor
var held: WeaponVisual
var cases: GroundDecals
var heading_index := 2
var gear_mode := false
var gear_index := 0
var cast_index := 0
var gait := 0
var gait_time := 0.0
var people_sheets := {}
var selection: ItemList
var caption: Label
var subtitle: Label
var movement: Label
var hint: Label
var preview_parts: Array[TextureRect] = []

func _ready() -> void:
	layer = 24
	process_mode = Node.PROCESS_MODE_ALWAYS
	root = Control.new()
	root.name = "SpriteKit"
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color("#1b1821")
	root.add_child(background)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label("Sprite kit", Rect2(44, 26, 590, 47), 36, CREAM)
	_button("Cast", Rect2(44, 83, 124, 34), show_mode.bind(false))
	_button("Equipment", Rect2(178, 83, 124, 34), show_mode.bind(true))
	_button("Close  Esc", Rect2(1084, 40, 150, 35), close)

	var board := Panel.new()
	board.position = Vector2(44, 130)
	board.size = Vector2(732, 510)
	board.clip_contents = true
	var panel := StyleBoxFlat.new()
	panel.bg_color = BOARD
	panel.border_color = Color("#735449")
	panel.set_border_width_all(1)
	panel.set_corner_radius_all(6)
	board.add_theme_stylebox_override("panel", panel)
	root.add_child(board)

	cast_sprite = TextureRect.new()
	cast_sprite.texture = cast_cell
	cast_sprite.position = Vector2(28, 6)
	cast_sprite.size = Vector2(676, 436)
	cast_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cast_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cast_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	board.add_child(cast_sprite)

	preview_world = Node2D.new()
	preview_world.position = Vector2(366, 194)
	preview_world.scale = Vector2.ONE * 7.5
	board.add_child(preview_world)
	cases = GroundDecals.new()
	var local_marks: Array[Dictionary] = []
	cases.configure(local_marks, "weapon_preview")
	preview_world.add_child(cases)
	mannequin = Actor.new()
	mannequin.hero = true
	preview_world.add_child(mannequin)
	held = WeaponVisual.new()
	held.configure(mannequin)
	held.z_index = 2
	preview_world.add_child(held)

	for column in range(3):
		var piece := TextureRect.new()
		piece.position = Vector2(191, 347)
		piece.size = Vector2(350, 126)
		piece.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		piece.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		piece.mouse_filter = Control.MOUSE_FILTER_IGNORE
		board.add_child(piece)
		preview_parts.append(piece)
	movement = _label("", Rect2(63, 598, 565, 23), 13, COPPER)

	caption = _label("", Rect2(804, 132, 424, 35), 24, CREAM)
	subtitle = _label("", Rect2(805, 173, 424, 33), 14, TEXT)
	selection = ItemList.new()
	selection.position = Vector2(804, 215)
	selection.size = Vector2(430, 425)
	selection.fixed_icon_size = Vector2i(26, 24)
	selection.add_theme_font_size_override("font_size", 16)
	selection.item_selected.connect(choose)
	root.add_child(selection)
	hint = _label("", Rect2(44, 658, 1190, 31), 15, TEXT)
	show_mode(false)

func _label(copy: String, bounds: Rect2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.position = bounds.position
	label.size = bounds.size
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	root.add_child(label)
	return label

func _button(copy: String, bounds: Rect2, action: Callable) -> void:
	var button := Button.new()
	button.text = copy
	button.position = bounds.position
	button.size = bounds.size
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	root.add_child(button)

func show_mode(equipment: bool) -> void:
	gear_mode = equipment
	cast_sprite.visible = not gear_mode
	preview_world.visible = gear_mode
	preview_world.process_mode = Node.PROCESS_MODE_INHERIT if gear_mode else Node.PROCESS_MODE_DISABLED
	for part in preview_parts:
		part.visible = gear_mode
	selection.clear()
	for row in Art.CATALOGUE if gear_mode else Art.PEOPLE:
		selection.add_item(row.label if gear_mode else row.name)
	choose(gear_index if gear_mode else cast_index)
	hint.text = ("← / → rotate   ·   ↑ / ↓ select   ·   Space cycle   ·   R service   ·   Esc close" if gear_mode
		else "← / → rotate   ·   ↑ / ↓ select   ·   1 idle   ·   2 walk   ·   3 run   ·   Esc close")

func choose(index: int) -> void:
	var active := posmod(index, selection.item_count)
	selection.select(active)
	selection.ensure_current_is_visible()
	if gear_mode:
		gear_index = active
		held.choose_catalog(active)
		var gear: Dictionary = Art.CATALOGUE[active]
		caption.text = gear.label
		var live := active in Art.LIVE_SLOTS
		subtitle.text = "Campaign prop and holding pose" if live else "Preview prop and holding pose"
		movement.text = "ALTERNATE SAAFIYA  /  %s" % str(gear.action).to_upper()
		for column in range(3):
			var part := AtlasTexture.new()
			part.atlas = gear.art
			part.region = Rect2(Vector2(column * Art.PROP_CELL.x, 0), Art.PROP_CELL)
			preview_parts[column].texture = part
	else:
		cast_index = active
		var person: Dictionary = Art.PEOPLE[active]
		caption.text = person.name
		subtitle.text = "%s body  ·  %s" % [str(person.body).capitalize(), str(person.hair).replace("_", " ").capitalize()]
		update_cast()

func update_cast() -> void:
	var person: Dictionary = Art.PEOPLE[cast_index]
	var key: String = person.key
	var static_pose := gait == 0 or key.begins_with("base_") or key.begins_with("saafiya")
	var animation: String = "turn" if static_pose else ["turn", "walk", "run"][gait]
	var path := Art.SPRITES + "%s_%s.png" % [key, animation]
	if not people_sheets.has(path):
		people_sheets[path] = load(path)
	var frame := heading_index if static_pose else floori(gait_time * (10.0 if gait == 1 else 15.0)) % 8
	cast_cell.atlas = people_sheets[path]
	cast_cell.region = Rect2((frame % 4) * Art.CELL, floori(float(frame) / 4.0) * Art.CELL, Art.CELL, Art.CELL)
	cast_sprite.rotation = 0.0 if static_pose else float(heading_index) * PI / 4.0
	cast_sprite.pivot_offset = cast_sprite.size * 0.5
	movement.text = "OVERHEAD  /  %s" % ("IDLE" if static_pose else animation.to_upper())

func _process(delta: float) -> void:
	if gear_mode:
		mannequin.facing = PI / 2.0 + float(heading_index) * PI / 4.0
		var gear: Dictionary = Art.CATALOGUE[gear_index]
		preview_parts[1].position.x = 191.0 + held.cycle_shift() * (350.0 / float(gear.width))
	elif gait > 0:
		gait_time += delta
		update_cast()

func _input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_ESCAPE, KEY_K, KEY_F7:
			close()
		KEY_LEFT, KEY_RIGHT:
			heading_index = posmod(heading_index + (-1 if event.keycode == KEY_LEFT else 1), 8)
			if not gear_mode:
				update_cast()
		KEY_UP, KEY_DOWN:
			choose((gear_index if gear_mode else cast_index) + (-1 if event.keycode == KEY_UP else 1))
		KEY_1, KEY_2, KEY_3:
			gait = event.keycode - KEY_1
			if not gear_mode:
				update_cast()
		KEY_SPACE:
			if gear_mode:
				cases.eject(held.burst(Vector2.from_angle(mannequin.facing)))
		KEY_R:
			if gear_mode:
				held.begin_service(1.2)
		_:
			return
	get_viewport().set_input_as_handled()

func close() -> void:
	if close_requested.get_connections().is_empty():
		get_tree().change_scene_to_file("res://scenes/upper_ridge.tscn")
	else:
		close_requested.emit()
