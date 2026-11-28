extends CanvasLayer
## Paired portrait dialogue for the optional house story.
const HERO := preload("res://assets/ui/jacobs_house/saafiya.png")
const WIDTH := 1164
const HEIGHT := 322
const PHOTO_SIZE := Vector2(218, 251)

var open := false
var shade: ColorRect
var card: Panel
var left: TextureRect
var right: TextureRect
var counterpart: Label
var speaker: Label
var line: Label
var next_button: Button
var close_button: Button
var pages: Array[Dictionary] = []
var index := 0
var choice := ""
var complete: Callable

func _ready() -> void:
	layer = 29
	shade = ColorRect.new()
	add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color("#100e18b0")
	card = Panel.new()
	shade.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	card.offset_left = -WIDTH * .5
	card.offset_right = WIDTH * .5
	card.offset_top = -HEIGHT - 37
	card.offset_bottom = -37
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#1c1721")
	frame.border_color = Color("#a27c62")
	frame.set_border_width_all(2)
	frame.set_corner_radius_all(6)
	card.add_theme_stylebox_override("panel", frame)
	left = portrait_at(Vector2(19, 18))
	left.texture = HERO
	right = portrait_at(Vector2(WIDTH - 237, 18))
	var hero_name := put_label(Rect2(19, 273, 218, 31), "SAAFIYA", 15, Color("#ecc39c"))
	hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counterpart = put_label(Rect2(WIDTH - 237, 273, 218, 31), "", 15, Color("#ecc39c"))
	counterpart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speaker = put_label(Rect2(262, 53, 632, 32), "", 17, Color("#dfad89"))
	line = put_label(Rect2(262, 98, 635, 115), "", 24, Color("#f1e4db"))
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	next_button = make_button(Rect2(262, 243, 413, 45), advance)
	close_button = make_button(Rect2(687, 243, 210, 45), close)
	shade.hide()

func portrait_at(point: Vector2) -> TextureRect:
	var field := ColorRect.new()
	field.position = point
	field.size = PHOTO_SIZE
	field.color = Color("#332633")
	field.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(field)
	var face := TextureRect.new()
	face.position = point + Vector2(4, 5)
	face.size = PHOTO_SIZE - Vector2(8, 10)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(face)
	return face

func put_label(area: Rect2, text_value: String, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.position = area.position
	label.size = area.size
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(label)
	return label

func make_button(area: Rect2, action: Callable) -> Button:
	var button := Button.new()
	button.position = area.position
	button.size = area.size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 16)
	for state in ["normal", "hover", "pressed"]:
		var fill := StyleBoxFlat.new()
		fill.bg_color = Color("#332632") if state == "normal" else Color("#4a3440")
		fill.border_color = Color("#8d6755") if state == "normal" else Color("#e1aa81")
		fill.set_border_width_all(1)
		fill.set_corner_radius_all(4)
		button.add_theme_stylebox_override(state, fill)
	button.pressed.connect(action)
	card.add_child(button)
	return button

func show_dialogue(name_value: String, photo: Texture2D, lines: Array[Dictionary],
		option: String = "Close", on_choose: Callable = Callable()) -> void:
	if lines.is_empty():
		return
	counterpart.text = name_value.to_upper()
	right.texture = photo
	pages = lines
	index = 0
	choice = option
	complete = on_choose
	open = true
	shade.show()
	redraw_page()

func redraw_page() -> void:
	var current := pages[index]
	var hero_speaks: bool = current.get("hero", false)
	speaker.text = "SAAFIYA" if hero_speaks else counterpart.text
	line.text = current.text
	left.modulate = Color.WHITE if hero_speaks else Color("#c4a8ac")
	right.modulate = Color("#c4a8ac") if hero_speaks else Color.WHITE
	next_button.text = "E  ·  " + (choice if index == pages.size() - 1 else "Continue")
	close_button.text = "Q  ·  " + ("Leave" if complete.is_valid() else "Close")

func advance() -> void:
	if not open:
		return
	if index < pages.size() - 1:
		index += 1
		redraw_page()
		return
	var action := complete
	close()
	if action.is_valid():
		action.call()

func close() -> void:
	open = false
	complete = Callable()
	pages = []
	shade.hide()
