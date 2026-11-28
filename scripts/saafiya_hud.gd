extends CanvasLayer
## Native full-bleed 16:9 Saafiya HUD, wired to the existing Godot encounter.
## The artwork is decoration only. Hearts, minimap, equipped icons and ammunition
## are drawn separately, from current game state. No fabricated ammunition.
const HUD_ART := preload("res://assets/ui/saafiya_hud_overlay.png")
const MiniMap := preload("res://scripts/saafiya_minimap.gd")
const AmmoDisplay := preload("res://scripts/saafiya_ammo_display.gd")
const HEARTS := [
	preload("res://assets/ui/vitality/empty.png"),
	preload("res://assets/ui/vitality/half.png"),
	preload("res://assets/ui/vitality/full.png"),
]
const ANKH := preload("res://assets/ui/vitality/ankh.png")
const QUICK_ART := [
	preload("res://assets/ui/icons/beretta_84fs.png"),
	preload("res://assets/ui/nameplates/cz75_p07.png"),
	preload("res://assets/ui/icons/norinco_akm.png")
]
const EQUIPPED_NAMEPLATES := [
	preload("res://assets/ui/nameplates/beretta_84fs.png"),
	preload("res://assets/ui/nameplates/cz75_p07.png"),
	preload("res://assets/ui/nameplates/norinco_akm.png"),
]
const SOURCE_SIZE := Vector2(2048, 1152)
const STORY_RECT := Rect2(874, 24, 794, 135)
const SUBTITLE_RECT := Rect2(331, 949, 1182, 115)
const HELP_RECT := Rect2(331, 1091, 1182, 47)
const SELECTOR_RECTS := [
	Rect2(114,882,92,80), # up
	Rect2(205,960,89,82), # right
	Rect2(114,1042,92,83), # down
	Rect2(23,960,89,83) # left
]
var avatar: Node2D
var stage_world: Node2D
var encounter
var chapter: String = "upper_ridge"
var layer_root: Control
var minimap
var ammo_display
var artwork: TextureRect
var weapon_nameplate: TextureRect
var hearts: Array[TextureRect] = []
var story_panel: PanelContainer
var story_objective: Label
var story_status: Label
var story_subtitle: Label
var notice: Label
var slot_buttons: Array[TextureButton] = []
var previous_quick := []
var previous_equipped := -99
var previous_health := -1.0
var previous_reload := false
var previous_unlocks := []
var last_counts := Vector2i(-100,-100)

func configure(hero: Node2D, chapter_world: Node2D, battle: Node2D, chapter_id: String) -> void:
	avatar = hero
	stage_world = chapter_world
	encounter = battle
	chapter = chapter_id
	layer = 3

# All bounds are fractions of the entire original 2048×1152 art. No hardcoded
# screen-edge padding; the art covers the complete 16:9 viewport to all corners.
func _set_art_rect(element: Control, art_rect: Rect2) -> void:
	element.anchor_left = art_rect.position.x / SOURCE_SIZE.x
	element.anchor_top = art_rect.position.y / SOURCE_SIZE.y
	element.anchor_right = art_rect.end.x / SOURCE_SIZE.x
	element.anchor_bottom = art_rect.end.y / SOURCE_SIZE.y
	element.offset_left = 0.0
	element.offset_top = 0.0
	element.offset_right = 0.0
	element.offset_bottom = 0.0

func _ready() -> void:
	layer_root = Control.new()
	layer_root.name = "Saafiya16x9HUD"
	layer_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(layer_root)
	layer_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# Draw scene-relative map first, through a real transparent hole in the ring.
	minimap = MiniMap.new()
	minimap.name = "RotatingWorldMapFixedChevron"
	layer_root.add_child(minimap)
	_set_art_rect(minimap,Rect2(1752,45,252,252))
	minimap.configure(avatar,stage_world,chapter)

	artwork = TextureRect.new()
	artwork.name = "OrnamentalFrameFullBleed"
	artwork.texture = HUD_ART
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_root.add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_sprite("PortraitAnkh", ANKH, Rect2(141, 81, 28, 38))
	_sprite("SelectorAnkh", ANKH, Rect2(124, 970, 68, 76))
	for i in range(3):
		var heart := _sprite("VitalityHeart%d" % (i + 1), HEARTS[2], Rect2(445 + i * 107, 83, 78, 73))
		hearts.append(heart)

	weapon_nameplate = _sprite("CurrentEquipment", EQUIPPED_NAMEPLATES[0], Rect2(1597, 976, 172, 105))

	ammo_display = AmmoDisplay.new()
	ammo_display.name = "FittedBronzeDigitalAmmo"
	ammo_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_root.add_child(ammo_display)
	# Right panel has decorative slashes near x=1990: leave these visible.
	_set_art_rect(ammo_display,Rect2(1814,985,151,84))

	for i in range(4):
		var b := TextureButton.new()
		b.name = "QuickDirection%d" % i
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		b.pressed.connect(_on_quick_pressed.bind(i))
		layer_root.add_child(b)
		_set_art_rect(b,SELECTOR_RECTS[i])
		slot_buttons.append(b)
		var number := _label(str(i + 1), 11, Color("#d9b19a"))
		layer_root.add_child(number)
		var bounds := Rect2(SELECTOR_RECTS[i])
		_set_art_rect(number, Rect2(bounds.position + Vector2(3, 3), Vector2(25, 25)))
	notice = _label("", 25, Color("#f3dcc0"))
	notice.add_theme_constant_override("outline_size", 6)
	layer_root.add_child(notice)
	_set_art_rect(notice, Rect2(548, 430, 952, 192))
	_refresh_data()

func _sprite(sprite_name: String, texture: Texture2D, bounds: Rect2) -> TextureRect:
	var sprite := TextureRect.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_root.add_child(sprite)
	_set_art_rect(sprite, bounds)
	return sprite

func _label(copy: String, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = copy
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_outline_color", Color("#201719"))
	label.add_theme_constant_override("outline_size", 3)
	return label

func configure_story(title: String, objective: String, subtitle: String, controls: String) -> void:
	story_panel = PanelContainer.new()
	story_panel.name = "ChapterText"
	story_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color("#201b21e8")
	frame.border_color = Color("#886952")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(5)
	frame.content_margin_left = 14
	frame.content_margin_right = 14
	frame.content_margin_top = 6
	frame.content_margin_bottom = 6
	story_panel.add_theme_stylebox_override("panel", frame)
	layer_root.add_child(story_panel)
	_set_art_rect(story_panel, STORY_RECT)

	var column := VBoxContainer.new()
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_theme_constant_override("separation", 1)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	story_panel.add_child(column)
	column.add_child(_label(title, 19, Color("#f4dfbe")))
	story_objective = _label(objective, 15, Color("#ead5b6"))
	column.add_child(story_objective)
	story_status = _label("", 12, Color("#cbbab1"))
	column.add_child(story_status)

	story_subtitle = _label(subtitle, 16, Color("#f6e8ca"))
	story_subtitle.name = "StorySubtitle"
	story_subtitle.add_theme_constant_override("outline_size", 6)
	layer_root.add_child(story_subtitle)
	_set_art_rect(story_subtitle, SUBTITLE_RECT)
	var help := _label(controls, 12, Color("#e6d9c8"))
	help.name = "ChapterControls"
	layer_root.add_child(help)
	_set_art_rect(help, HELP_RECT)

func show_encounter_notice(message: String) -> void:
	notice.text = message

func set_vitality(hp: float) -> void:
	if is_equal_approx(hp, previous_health):
		return
	previous_health = hp
	for i in range(hearts.size()):
		var fill := clampf(hp - float(i), 0.0, 1.0)
		var state := 2 if is_equal_approx(fill, 1.0) else (1 if fill > 0.0 else 0)
		hearts[i].texture = HEARTS[state]

func _process(_delta: float) -> void:
	_refresh_data()

func _refresh_data() -> void:
	if not is_instance_valid(encounter):
		return
	set_vitality(float(encounter.player_hp))
	var choice: int = encounter.slot
	var counts := Vector2i(int(encounter.rounds[choice]), int(encounter.spares[choice]))
	var reload_now: bool = encounter.reload_clock > 0.0
	if choice != previous_equipped or counts != last_counts or reload_now != previous_reload:
		last_counts = counts
		previous_reload = reload_now
		ammo_display.set_values(counts.x, counts.y, reload_now, true)
	if choice != previous_equipped or encounter.unlocked != previous_unlocks or encounter.inventory.quick_slots != previous_quick:
		previous_equipped = choice
		previous_unlocks = encounter.unlocked.duplicate()
		previous_quick = encounter.inventory.quick_slots.duplicate()
		weapon_nameplate.texture = EQUIPPED_NAMEPLATES[choice]
		_update_quick_slots()

func _update_quick_slots() -> void:
	for i in range(slot_buttons.size()):
		var equipment_slot: int = encounter.inventory.quick_slots[i]
		var b := slot_buttons[i]
		var available: bool = equipment_slot >= 0 and bool(encounter.unlocked[equipment_slot])
		b.texture_normal = QUICK_ART[equipment_slot] if available else null
		b.disabled = not available
		b.tooltip_text = "%d · %s" % [i + 1, encounter.KIT[equipment_slot].name if available else "Empty"]
		b.modulate = Color("#ffd1bc") if available and equipment_slot == int(encounter.slot) else Color.WHITE

func _on_quick_pressed(direction: int) -> void:
	encounter.equip_quick(direction)
	_refresh_data()

func run_hud_smoke() -> void:
	assert(is_instance_valid(minimap))
	assert(is_instance_valid(ammo_display))
	assert(slot_buttons.size()==4)
	assert(layer_root.anchor_right==1.0 and layer_root.anchor_bottom==1.0)
	assert(artwork.anchor_left == 0.0 and artwork.anchor_top == 0.0)
	assert(artwork.anchor_right == 1.0 and artwork.anchor_bottom == 1.0)
	assert(artwork.offset_right == 0.0 and artwork.offset_bottom == 0.0)
	assert(weapon_nameplate.anchor_right < ammo_display.anchor_left)
	assert(not story_panel.get_rect().intersects(minimap.get_rect()))
	assert(story_panel.get_rect().position.x > 849.0 / SOURCE_SIZE.x * layer_root.size.x)
	set_vitality(1.5)
	assert(hearts[0].texture == HEARTS[2] and hearts[1].texture == HEARTS[1] and hearts[2].texture == HEARTS[0])
	_refresh_data()
	assert(weapon_nameplate.texture == EQUIPPED_NAMEPLATES[encounter.slot])
	assert(ammo_display.current_rounds == encounter.rounds[encounter.slot])
	assert(ammo_display.magazine_reserve == encounter.spares[encounter.slot])
	assert(ammo_display.counter_bounds(Vector2(1, 50), "01", "99").size.x <= 1.0)
	var available := Vector2(94, 52)
	assert(Rect2(Vector2.ZERO, available).encloses(ammo_display.counter_bounds(available, "123456", "987654")))
	assert(minimap.world_rotation(PI / 2.0) == -PI)
	assert(Vector2.RIGHT.rotated(minimap.world_rotation(0)).is_equal_approx(Vector2.UP))
	assert(slot_buttons[0].texture_normal == QUICK_ART[0])
	assert(slot_buttons[3].disabled)
	print("Saafiya HUD smoke: fullscreen 16:9 corners, 4 quick slots, live ammo and rotating map ready.")
