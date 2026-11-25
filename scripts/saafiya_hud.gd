extends CanvasLayer
## Native full-bleed 16:9 Saafiya HUD, wired to the existing Godot encounter.
## The artwork is decoration only. Hearts, minimap, equipped icons and ammunition
## are drawn separately, from current game state. No fabricated ammunition.
const HUD_ART := preload("res://assets/ui/saafiya_hud_overlay.png")
const MiniMap := preload("res://scripts/saafiya_minimap.gd")
const AmmoDisplay := preload("res://scripts/saafiya_ammo_display.gd")
const ITEMS := [
	{"id":"beretta_84fs","title":"Beretta 84FS","path":"res://assets/ui/icons/beretta_84fs.png","kit":0},
	{"id":"pump_shotgun","title":"Pump-action shotgun","path":"res://assets/ui/icons/pump_shotgun.png","kit":-1},
	{"id":"norinco_akm","title":"NORINCO AKM","path":"res://assets/ui/icons/norinco_akm.png","kit":2},
	{"id":"canik_tp9","title":"CANIK TP9","path":"res://assets/ui/icons/canik_tp9.png","kit":-1},
	{"id":"sw_revolver_engraved","title":"Engraved revolver","path":"res://assets/ui/icons/sw_revolver_engraved.png","kit":-1},
	{"id":"fairbairn_sykes","title":"Fairbairn–Sykes knife","path":"res://assets/ui/icons/fairbairn_sykes.png","kit":-1},
	{"id":"spetsnaz_sf","title":"Spetsnaz combat knife","path":"res://assets/ui/icons/spetsnaz_sf.png","kit":-1},
	{"id":"akm_bayonet","title":"AKM-pattern bayonet","path":"res://assets/ui/icons/akm_bayonet.png","kit":-1}
]
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
var weapon_label: Label
var heart_labels: Array[Label] = []
var slot_buttons: Array[TextureButton] = []
var icon_cache: Array[Texture2D] = []
var page_label: Label
var page := 0
var previous_equipped := -99
var previous_health := -99
var previous_reload := false
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
	element.anchor_left = art_rect.position.x / 2048.0
	element.anchor_top = art_rect.position.y / 1152.0
	element.anchor_right = art_rect.end.x / 2048.0
	element.anchor_bottom = art_rect.end.y / 1152.0
	element.offset_left = 0.0
	element.offset_top = 0.0
	element.offset_right = 0.0
	element.offset_bottom = 0.0

func _ready() -> void:
	layer_root = Control.new()
	layer_root.name = "Saafiya16x9HUD"
	layer_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(layer_root)

	# Draw scene-relative map first, through a real transparent hole in the ring.
	minimap = MiniMap.new()
	minimap.name = "RotatingWorldMapFixedChevron"
	layer_root.add_child(minimap)
	_set_art_rect(minimap,Rect2(1754,51,252,252))
	minimap.configure(avatar,stage_world,chapter)

	var artwork := TextureRect.new()
	artwork.name = "OrnamentalFrameFullBleed"
	artwork.texture = HUD_ART
	artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	artwork.stretch_mode = TextureRect.STRETCH_SCALE
	artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_root.add_child(artwork)
	artwork.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	for i in range(3):
		var heart := Label.new()
		heart.name = "VitalityHeart%d" % (i+1)
		heart.text = "♥"
		heart.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		heart.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		heart.add_theme_font_size_override("font_size",34)
		heart.add_theme_constant_override("outline_size",3)
		heart.add_theme_color_override("font_outline_color",Color("#32151c"))
		layer_root.add_child(heart)
		_set_art_rect(heart,Rect2(355 + i*89,61,74,77))
		heart_labels.append(heart)

	weapon_label = Label.new()
	weapon_label.name = "CurrentEquipment"
	weapon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	weapon_label.clip_text = true
	weapon_label.add_theme_color_override("font_color",Color("#edd0b6"))
	weapon_label.add_theme_color_override("font_outline_color",Color("#25191e"))
	weapon_label.add_theme_constant_override("outline_size",2)
	weapon_label.add_theme_font_size_override("font_size",14)
	layer_root.add_child(weapon_label)
	_set_art_rect(weapon_label,Rect2(1589,975,210,104))

	ammo_display = AmmoDisplay.new()
	ammo_display.name = "FittedBronzeDigitalAmmo"
	ammo_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer_root.add_child(ammo_display)
	# Right panel has decorative slashes near x=1990: leave these visible.
	_set_art_rect(ammo_display,Rect2(1802,982,167,98))

	for i in range(ITEMS.size()):
		var tex: Texture2D = load(str(ITEMS[i]["path"]))
		icon_cache.append(tex)
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
	page_label = Label.new()
	page_label.name = "EquipmentPage"
	page_label.text = "1/2"
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	page_label.add_theme_color_override("font_color",Color("#d9b19a"))
	page_label.add_theme_font_size_override("font_size",10)
	layer_root.add_child(page_label)
	_set_art_rect(page_label,Rect2(146,984,43,42))
	_update_page()
	_refresh_data()

func _process(_delta: float) -> void:
	_refresh_data()

func _refresh_data() -> void:
	if not is_instance_valid(encounter):
		return
	var hp: int = int(encounter.player_hp)
	if hp != previous_health:
		previous_health = hp
		for i in range(heart_labels.size()):
			heart_labels[i].add_theme_color_override("font_color",Color("#e54b5d") if i < hp else Color("#37242d"))
	var choice: int = int(encounter.slot)
	var active_kit: Dictionary = encounter.KIT[choice]
	var counts := Vector2i(int(encounter.rounds[choice]),int(encounter.spares[choice]))
	var reload_now: bool = float(encounter.reload_clock)>0.0
	if choice != previous_equipped or counts != last_counts or reload_now != previous_reload:
		previous_equipped=choice
		last_counts=counts
		previous_reload=reload_now
		weapon_label.text = str(active_kit["name"]).to_upper()
		ammo_display.set_values(counts.x,counts.y,reload_now,true)
		_update_page()

func _update_page() -> void:
	for i in range(slot_buttons.size()):
		var item_index := page*4+i
		var definition: Dictionary = ITEMS[item_index]
		var b: TextureButton = slot_buttons[i]
		b.texture_normal = icon_cache[item_index]
		var equipment_slot: int = int(definition["kit"])
		var available: bool = equipment_slot>=0 and equipment_slot<encounter.unlocked.size() and bool(encounter.unlocked[equipment_slot])
		b.disabled = not available
		b.tooltip_text = str(definition["title"]) if available else "%s · Not acquired" % str(definition["title"])
		if available and equipment_slot == int(encounter.slot):
			b.modulate=Color("#ffd1bc")
		elif available:
			b.modulate=Color(0.9,0.82,0.8,0.9)
		else:
			b.modulate=Color(0.48,0.41,0.43,0.36)
	page_label.text="%d/2" % (page+1)

func _on_quick_pressed(direction: int) -> void:
	var item_index := page*4+direction
	var equipment_slot: int = int(ITEMS[item_index]["kit"])
	if equipment_slot < 0 or not bool(encounter.unlocked[equipment_slot]):
		return
	encounter.equip(equipment_slot)
	_refresh_data()

func change_page(step: int) -> void:
	page=posmod(page+step,2)
	_update_page()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if event.keycode == KEY_BRACKETLEFT:
		change_page(-1)
	elif event.keycode == KEY_BRACKETRIGHT:
		change_page(1)

func run_hud_smoke() -> void:
	assert(is_instance_valid(minimap))
	assert(is_instance_valid(ammo_display))
	assert(slot_buttons.size()==4)
	assert(icon_cache.size()==8)
	assert(layer_root.anchor_right==1.0 and layer_root.anchor_bottom==1.0)
	assert(weapon_label.anchor_right <= 1.0)
	change_page(1)
	assert(page==1)
	change_page(1)
	assert(page==0)
	print("Saafiya HUD smoke: fullscreen 16:9 corners, 8 icons, live ammo and rotating map ready.")
