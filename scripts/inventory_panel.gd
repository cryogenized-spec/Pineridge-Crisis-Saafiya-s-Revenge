extends CanvasLayer
## One drag surface keeps overlapping item footprints and equipment targets in sync.
const Model := preload("res://scripts/inventory_model.gd")
const PORTRAIT := preload("res://assets/ui/inventory/saafiya.png")
const OUTFIT_MASKS := {
	"Head":preload("res://assets/ui/inventory/doll_glasses.png"),
	"Neck":preload("res://assets/ui/inventory/doll_choker.png"),
	"Torso":preload("res://assets/ui/inventory/doll_lace.png"),
	"Arms":preload("res://assets/ui/inventory/doll_coat.png"),
	"Legs":preload("res://assets/ui/inventory/doll_skirt.png"),
	"Belt":preload("res://assets/ui/inventory/doll_chain.png"),
	"Boots":preload("res://assets/ui/inventory/doll_boots.png")
}
const INK := Color("#15131a")
const PANEL := Color("#201c26")
const TRIM := Color("#725749")
const GOLD := Color("#e5b991")
const TEXT := Color("#ede0d6")
const MUTED := Color("#b2a19f")
const BOARD := Vector2(1172, 634)
const BAG := Vector2(502, 142)
const BOOT := Vector2(878, 142)
const CELL := 48
const BOOT_CELL := 39
const SLOTS := {
	"Head":Rect2(36,145,77,63), "Neck":Rect2(36,231,77,63),
	"Back":Rect2(36,317,77,63), "Belt":Rect2(36,403,77,63),
	"Torso":Rect2(366,145,77,63), "Arms":Rect2(366,231,77,63),
	"Legs":Rect2(366,317,77,63), "Boots":Rect2(366,403,77,63),
	"Sidearm":Rect2(58,513,74,63), "Backup":Rect2(156,513,74,63),
	"Primary":Rect2(254,513,74,63), "Knife":Rect2(352,513,74,63)
}
const QUICK := [Rect2(618, 395, 56, 49), Rect2(686, 448, 56, 49),
	Rect2(618, 501, 56, 49), Rect2(550, 448, 56, 49)]
const LOOT_START := Vector2(872, 146)
const CASH_IN := Rect2(878, 495, 112, 34)
const CASH_OUT := Rect2(1000, 495, 112, 34)
const CLOSE := Rect2(1106, 28, 38, 34)
const ICONS := {
	"beretta":"res://assets/ui/icons/beretta_84fs.png",
	"pistol":"res://assets/ui/nameplates/cz75_p07.png",
	"rifle":"res://assets/ui/icons/norinco_akm.png",
	"knife":"res://assets/ui/icons/fairbairn_sykes.png",
	"cudgel":"res://assets/props/rendered/club_icon.png",
	"brick":"res://assets/props/rendered/brick.png",
	"slingshot":"res://assets/props/rendered/slingshot_icon.png",
	"runner":"res://assets/props/bottle.svg"
}

class Surface extends Control:
	func _draw() -> void:
		get_parent().get_parent().paint(self)

	func _gui_input(event: InputEvent) -> void:
		if get_parent().get_parent().point_input(event):
			accept_event()

	func _get_tooltip(at_position: Vector2) -> String:
		return get_parent().get_parent().item_tooltip(at_position)

var model: Model
var open := false
var at_car := false
var taking: Callable
var active_weapon: Callable
var contents: Array[Dictionary] = []
var root: Control
var board: Surface
var icons: Dictionary = {}
var pointer := Vector2(-100, -100)
var pressed_at := Vector2.ZERO
var grab_offset := Vector2i.ZERO
var grabbed: Dictionary = {}
var dragging := false
var feedback := ""
var flights: Array[Dictionary] = []

func configure(source: Model, selected: Callable) -> void:
	model = source
	active_weapon = selected

func _ready() -> void:
	layer = 20
	root = Control.new()
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	board = Surface.new()
	root.add_child(board)
	board.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	board.offset_left = -BOARD.x * 0.5
	board.offset_top = -BOARD.y * 0.5
	board.offset_right = BOARD.x * 0.5
	board.offset_bottom = BOARD.y * 0.5
	board.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	board.mouse_exited.connect(_mouse_exit)
	for item in Model.ITEM_NAMES:
		var image_item: String = "coat" if item == "jacket" else item
		var path: String = ICONS.get(image_item, "res://assets/ui/inventory/%s.png" % image_item)
		icons[item] = load(path)
	root.hide()
	set_process(false)

func show_inventory(car_access: bool = false) -> void:
	contents = []
	taking = Callable()
	at_car = car_access
	show_board()

func show_loot(items: Array[Dictionary], transfer: Callable) -> void:
	contents = items
	taking = transfer
	at_car = false
	show_board()

func show_board() -> void:
	open = true
	feedback = ""
	root.show()
	board.queue_redraw()

func close_inventory() -> void:
	open = false
	at_car = false
	taking = Callable()
	contents = []
	grabbed.clear()
	flights.clear()
	dragging = false
	root.hide()
	set_process(false)

func toggle() -> void:
	if open:
		close_inventory()
	else:
		show_inventory()

func paint(canvas: Control) -> void:
	canvas.draw_rect(Rect2(Vector2.ZERO, BOARD), INK)
	canvas.draw_rect(Rect2(Vector2.ONE, BOARD - Vector2(2, 2)), TRIM, false, 2)
	canvas.draw_rect(Rect2(10, 10, BOARD.x - 20, BOARD.y - 20), Color("#3c3038"), false, 1)
	canvas.draw_rect(Rect2(19, 19, BOARD.x - 38, 60), Color("#211a22"))
	text_at(canvas, Vector2(35, 51), "SAAFIYA   /   INVENTORY", GOLD, 25)
	text_at(canvas, Vector2(879, 49), "WALLET   R %d" % model.cash_rand, TEXT, 16)
	box(canvas, CLOSE, CLOSE.has_point(pointer))
	center_text(canvas, CLOSE, "×", 23, GOLD)
	for x in [472, 841]:
		canvas.draw_line(Vector2(x, 93), Vector2(x, 583), Color("#493640"), 1)
	text_at(canvas, Vector2(36, 116), "EQUIPPED", GOLD, 15)
	text_at(canvas, Vector2(502, 116), "CARRIED", GOLD, 15)
	text_at(canvas, Vector2(639, 116), "%d / %d ITEMS" % [model.bag.size(), model.capacity()], MUTED, 12)
	canvas.draw_rect(Rect2(121, 132, 236, 352), Color("#201a23"))
	for i in range(8):
		canvas.draw_arc(Vector2(239, 292), 38.0 + i * 10, 0, TAU, 56, Color(0.46, 0.27, 0.31, .11), 1, true)
	canvas.draw_line(Vector2(239, 137), Vector2(239, 476), Color("#433138"))
	var portrait := Rect2(128, 133, 222, 347)
	draw_icon(canvas, PORTRAIT, portrait, Color("#e0caca"))
	for slot in OUTFIT_MASKS:
		if model.item_for_slot(slot).is_empty():
			draw_icon(canvas, OUTFIT_MASKS[slot], portrait)
	for slot in SLOTS:
		var bounds: Rect2 = SLOTS[slot]
		var item := model.item_for_slot(slot)
		box(canvas, bounds, drop_slot(slot) or bounds.has_point(pointer), item != "")
		if item != "":
			draw_icon(canvas, icons[item], bounds.grow(-6))
		center_text(canvas, Rect2(bounds.position + Vector2(0, 63), Vector2(bounds.size.x, 17)), slot.to_upper(), 11, MUTED)
	paint_grid(canvas, "bag", BAG, CELL)
	text_at(canvas, Vector2(502, 379), "QUICK SLOTS", GOLD, 15)
	text_at(canvas, Vector2(632, 379), "DRAG A WEAPON HERE", MUTED, 11)
	canvas.draw_arc(Vector2(646, 472), 60, 0, TAU, 40, TRIM, 1, true)
	center_text(canvas, Rect2(628, 453, 36, 36), "◈", 20, TRIM)
	for i in range(QUICK.size()):
		var bounds: Rect2 = QUICK[i]
		var weapon := model.quick_slots[i]
		box(canvas, bounds, bounds.has_point(pointer) or (weapon >= 0 and weapon == int(active_weapon.call())), weapon >= 0)
		if weapon >= 0:
			draw_icon(canvas, icons[Model.WEAPONS[weapon]], bounds.grow(-8))
		text_at(canvas, bounds.position + Vector2(4, 13), str(i + 1), GOLD, 11)
	if at_car:
		text_at(canvas, Vector2(878, 116), "MUSTANG BOOT", GOLD, 15)
		paint_grid(canvas, "boot", BOOT, BOOT_CELL)
		text_at(canvas, Vector2(878, 478), "STORED CASH   R %d" % model.boot_cash_rand, TEXT, 14)
		box(canvas, CASH_IN, CASH_IN.has_point(pointer) and model.cash_rand >= 50)
		box(canvas, CASH_OUT, CASH_OUT.has_point(pointer) and model.boot_cash_rand >= 50)
		center_text(canvas, CASH_IN, "Store R50", 13, MUTED)
		center_text(canvas, CASH_OUT, "Take R50", 13, MUTED)
	elif taking.is_valid():
		paint_loot(canvas)
	else:
		paint_inspection(canvas)
	canvas.draw_line(Vector2(31, 593), Vector2(1142, 593), TRIM)
	var hint := "Drag to move or equip  ·  I / Esc to close"
	if taking.is_valid():
		hint = "Click a loot item to take it  ·  E / I / Esc to close"
	text_at(canvas, Vector2(36, 615), hint, MUTED, 13)
	if not feedback.is_empty():
		text_at(canvas, Vector2(577, 615), feedback, GOLD, 13)
	if dragging and not grabbed.is_empty():
		var offset := Vector2(grab_offset) * CELL + Vector2.ONE * CELL * 0.5
		var drag_size := Vector2(Model.footprint(grabbed.item)) * CELL
		var preview := Rect2(pointer - offset, drag_size)
		canvas.draw_rect(preview, Color("#33273acc"))
		canvas.draw_rect(preview, GOLD, false, 1)
		draw_icon(canvas, icons[grabbed.item], preview.grow(-5))
	for flight in flights:
		var t := float(flight.age) / 0.38
		var point: Vector2 = flight.start.lerp(flight.end, t) - Vector2(0, 47 * sin(t * PI))
		var fade := Color(1, 1, 1, 1.0 - smoothstep(.62, 1.0, t))
		if icons.has(flight.item):
			draw_icon(canvas, icons[flight.item], Rect2(point - Vector2(24, 24), Vector2(48, 48)), fade)
		else:
			text_at(canvas, point, flight.label, GOLD * fade, 14)

func paint_grid(canvas: Control, location: String, origin: Vector2, step: int) -> void:
	var dimensions := Model.BOOT_SIZE if location == "boot" else Model.BAG_SIZE
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var area := Rect2(origin + Vector2(x, y) * step, Vector2.ONE * (step - 1))
			canvas.draw_rect(area, Color("#211b26") if (x + y) % 2 == 0 else Color("#241d29"))
			canvas.draw_rect(area, Color("#493940"), false, 1)
	var cells := model.cells_at(location)
	var items := model.items_at(location)
	for i in range(items.size()):
		var area := Rect2(origin + Vector2(cells[i]) * step, Vector2(Model.footprint(items[i])) * step).grow(-2)
		var picked: bool = dragging and grabbed.get("from") == location and grabbed.get("index") == i
		box(canvas, area, area.has_point(pointer), true)
		draw_icon(canvas, icons[items[i]], area.grow(-4), Color(1, 1, 1, .28 if picked else 1.0))
	if dragging:
		var cell := grid_cell(pointer, location) - grab_offset
		if cell.x < 0 or cell.y < 0 or not Rect2i(Vector2i.ZERO, dimensions).has_point(cell):
			return
		var area := Rect2(origin + Vector2(cell) * step, Vector2(Model.footprint(grabbed.item)) * step)
		var valid := grid_drop_ok(location, cell)
		canvas.draw_rect(area, Color("#93bd9d44") if valid else Color("#d96a7344"))
		canvas.draw_rect(area, Color("#93bd9d") if valid else Color("#c8757b"), false, 2)

func paint_loot(canvas: Control) -> void:
	text_at(canvas, Vector2(872, 116), "ON THE GROUND", GOLD, 15)
	if contents.is_empty():
		text_at(canvas, LOOT_START + Vector2(6, 27), "Empty", MUTED, 15)
	for i in range(contents.size()):
		var bounds := loot_bounds(i)
		var entry := contents[i]
		box(canvas, bounds, bounds.has_point(pointer), true)
		if icons.has(entry.item):
			draw_icon(canvas, icons[entry.item], Rect2(bounds.position + Vector2(8, 8), Vector2(42, 41)))
		else:
			center_text(canvas, Rect2(bounds.position + Vector2(7, 8), Vector2(43, 40)), "R" if entry.item == "cash" else "▥", 19, GOLD)
		text_at(canvas, bounds.position + Vector2(58, 32), entry.label, TEXT, 13)

func paint_inspection(canvas: Control) -> void:
	var inspected := item_at(pointer)
	var selected := int(active_weapon.call())
	var item: String = inspected.get("item", Model.WEAPONS[selected])
	var size := Model.footprint(item)
	text_at(canvas, Vector2(878, 116), "ITEM DETAILS" if not inspected.is_empty() else "IN HAND", GOLD, 15)
	var display := Rect2(878, 145, 234, 154)
	box(canvas, display, false)
	draw_icon(canvas, icons[item], display.grow(-21))
	text_at(canvas, Vector2(878, 329), Model.ITEM_NAMES[item], TEXT, 21)
	text_at(canvas, Vector2(878, 354), "%d × %d cells" % [size.x, size.y], MUTED, 13)
	canvas.draw_line(Vector2(878, 422), Vector2(1112, 422), TRIM)
	text_at(canvas, Vector2(878, 452), "E by the Mustang to open its boot.", MUTED, 13)
	text_at(canvas, Vector2(878, 479), "E by a downed opponent to search.", MUTED, 13)

func box(canvas: Control, area: Rect2, highlighted: bool, filled: bool = false) -> void:
	canvas.draw_rect(area, Color("#342735") if filled else PANEL)
	var border := GOLD if highlighted else TRIM
	canvas.draw_rect(area, border, false, 1)
	if filled:
		canvas.draw_line(area.position + Vector2(3, 3), area.position + Vector2(area.size.x - 3, 3), Color("#63454d"))
	for corner in [area.position + Vector2(2, 2), area.end - Vector2(4, 4)]:
		canvas.draw_rect(Rect2(corner, Vector2.ONE * 2), border)

func draw_icon(canvas: Control, texture: Texture2D, area: Rect2, tint: Color = Color.WHITE) -> void:
	if texture == null:
		return
	var art_size := texture.get_size()
	var fitted := art_size * minf(area.size.x / art_size.x, area.size.y / art_size.y)
	canvas.draw_texture_rect(texture, Rect2(area.get_center() - fitted * .5, fitted), false, tint)

func text_at(canvas: Control, at: Vector2, message: String, tint: Color, pixels: int) -> void:
	canvas.draw_string(ThemeDB.fallback_font, at, message, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels, tint)

func center_text(canvas: Control, area: Rect2, message: String, pixels: int, tint: Color) -> void:
	var wide := ThemeDB.fallback_font.get_string_size(message, HORIZONTAL_ALIGNMENT_LEFT, -1, pixels).x
	text_at(canvas, area.get_center() + Vector2(-wide * 0.5, pixels * 0.33), message, tint, pixels)

func loot_bounds(index: int) -> Rect2:
	return Rect2(LOOT_START + Vector2(0, index * 67), Vector2(260, 56))

func grid_cell(at: Vector2, location: String) -> Vector2i:
	var origin := BOOT if location == "boot" else BAG
	var step := BOOT_CELL if location == "boot" else CELL
	var raw := ((at - origin) / step).floor()
	var dimensions := Model.BOOT_SIZE if location == "boot" else Model.BAG_SIZE
	return Vector2i(raw) if Rect2(Vector2.ZERO, Vector2(dimensions)).has_point(raw) else Model.INVALID

func item_at(at: Vector2) -> Dictionary:
	for slot in SLOTS:
		if SLOTS[slot].has_point(at):
			var item := model.item_for_slot(slot)
			return {} if item.is_empty() else {"from":"gear", "slot":slot, "item":item}
	for i in range(QUICK.size()):
		if QUICK[i].has_point(at) and model.quick_slots[i] >= 0:
			return {"from":"quick", "index":i, "item":Model.WEAPONS[model.quick_slots[i]]}
	for location in (["bag", "boot"] if at_car else ["bag"]):
		var cell := grid_cell(at, location)
		if cell == Model.INVALID:
			continue
		var cells := model.cells_at(location)
		var items := model.items_at(location)
		for i in range(items.size()):
			var item := items[i]
			if Rect2i(cells[i], Model.footprint(item)).has_point(cell):
				return {"from":location, "index":i, "item":item, "offset":cell - cells[i]}
	return {}

func item_tooltip(at: Vector2) -> String:
	var entry := item_at(at)
	if entry.is_empty():
		return ""
	var item: String = entry.item
	var dimensions := Model.footprint(item)
	return "%s  ·  %d×%d" % [Model.ITEM_NAMES[item], dimensions.x, dimensions.y]

func point_input(event: InputEvent) -> bool:
	if not open:
		return false
	if event is InputEventMouseMotion:
		pointer = event.position
		if not grabbed.is_empty() and pointer.distance_to(pressed_at) >= 5.0:
			dragging = true
		board.queue_redraw()
		return true
	if not (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		return false
	pointer = event.position
	feedback = ""
	if event.pressed:
		pressed_at = pointer
		grabbed = item_at(pointer)
		grab_offset = grabbed.get("offset", Vector2i.ZERO)
	else:
		if dragging:
			if not finish_drag():
				feedback = "That item cannot go there."
		elif pointer.distance_to(pressed_at) < 6.0:
			click_at(pointer)
		grabbed = {}
		dragging = false
	board.queue_redraw()
	return true

func _mouse_exit() -> void:
	if not dragging:
		pointer = Vector2(-100, -100)
		board.queue_redraw()

func drop_slot(slot: String) -> bool:
	return dragging and SLOTS[slot].has_point(pointer) \
		and grabbed.from in ["bag", "boot"] and grabbed.item in Model.EQUIP_ITEMS[slot]

func grid_drop_ok(location: String, cell: Vector2i) -> bool:
	if grabbed.from == "quick" or (grabbed.from == "gear" and grabbed.item in Model.WEAPONS):
		return false
	var ignore: int = grabbed.index if grabbed.from == location else -1
	return model.can_place(location, grabbed.item, cell, ignore)

func finish_drag() -> bool:
	var weapon := Model.WEAPONS.find(grabbed.item)
	if weapon >= 0 and not model.item_for_slot(["Sidearm", "Backup", "Primary"][weapon]).is_empty():
		for i in range(QUICK.size()):
			if QUICK[i].has_point(pointer):
				model.assign_quick(i, weapon)
				return true
	for slot in SLOTS:
		if drop_slot(slot):
			return model.equip_item(grabbed.from, grabbed.index, slot)
	for location in (["bag", "boot"] if at_car else ["bag"]):
		var cell := grid_cell(pointer, location) - grab_offset
		if cell.x < 0 or cell.y < 0 or not grid_drop_ok(location, cell):
			continue
		if grabbed.from == "gear":
			return model.unequip_item(grabbed.slot, location, cell)
		return model.move_item(grabbed.from, grabbed.index, location, cell)
	return false

func click_at(at: Vector2) -> void:
	if CLOSE.has_point(at):
		close_inventory()
	elif at_car and CASH_IN.has_point(at):
		model.deposit_cash(50)
	elif at_car and CASH_OUT.has_point(at):
		model.withdraw_cash(50)
	elif taking.is_valid():
		for i in range(contents.size()):
			if loot_bounds(i).has_point(at):
				take_entry(i)
				break

func take_entry(index: int) -> void:
	if not open or not taking.is_valid() or index < 0 or index >= contents.size():
		return
	var entry := contents[index]
	var destination: String = taking.call(entry)
	if destination.is_empty():
		feedback = "Make room in the grid to take this item."
	else:
		var end := BAG + Vector2(29, 27)
		if destination == "equipment":
			end = SLOTS["Backup"].get_center()
		elif destination == "wallet":
			end = Vector2(912, 45)
		flights.append({"item":entry.item, "label":entry.label,
			"start":loot_bounds(index).get_center(), "end":end, "age":0.0})
		set_process(true)
	board.queue_redraw()

func _process(delta: float) -> void:
	for i in range(flights.size() - 1, -1, -1):
		flights[i].age += delta
		if flights[i].age >= 0.38:
			flights.remove_at(i)
	board.queue_redraw()
	if flights.is_empty():
		set_process(false)
