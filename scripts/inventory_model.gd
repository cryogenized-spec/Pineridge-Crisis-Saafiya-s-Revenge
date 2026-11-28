extends RefCounted

const BAG_SIZE := Vector2i(6, 4)
const BOOT_SIZE := Vector2i(6, 8)
const BASE_CAPACITY := 8
const BACKPACK_CAPACITY := 18
const BOOT_CAPACITY := 40
const ITEM_NAMES := {
	"phone":"Mobile phone", "keys":"Car keys", "backpack":"Canvas backpack",
	"water":"Water bottle", "torch":"Battery torch", "jacket":"Spare jacket",
	"beretta":"Beretta 84FS", "pistol":"CZ 75 P-07", "rifle":"AKM",
	"knife":"Knife", "cudgel":"Cudgel", "brick":"Brick", "slingshot":"Slingshot",
	"runner":"Glass bottle", "glasses":"Sunglasses", "choker":"Choker",
	"lace":"Black lace top", "coat":"Black jacket", "skirt":"Pleated skirt",
	"chain":"Waist chain", "boots":"Black boots"
}
const ITEM_SIZES := {
	"phone":Vector2i(1, 2), "backpack":Vector2i(2, 2), "water":Vector2i(1, 2),
	"torch":Vector2i(1, 2), "jacket":Vector2i(2, 2), "coat":Vector2i(2, 2),
	"lace":Vector2i(2, 2), "skirt":Vector2i(2, 2), "boots":Vector2i(2, 2),
	"beretta":Vector2i(2, 1), "pistol":Vector2i(2, 1), "rifle":Vector2i(4, 2),
	"knife":Vector2i(1, 2), "cudgel":Vector2i(1, 3), "brick":Vector2i(2, 1),
	"slingshot":Vector2i(1, 2), "runner":Vector2i(1, 2)
}
const EQUIP_ITEMS := {
	"Head":["glasses"], "Neck":["choker"], "Torso":["lace"], "Arms":["jacket", "coat"],
	"Belt":["chain"], "Legs":["skirt"], "Boots":["boots"], "Back":["backpack"],
	"Sidearm":["beretta"], "Backup":["pistol"], "Primary":["rifle"], "Knife":["knife"]
}
const INITIAL_GEAR := {
	"Head":"glasses", "Neck":"choker", "Torso":"lace", "Arms":"coat", "Belt":"chain",
	"Legs":"skirt", "Boots":"boots", "Sidearm":"beretta"
}
const WEAPONS := ["beretta", "pistol", "rifle"]
const INVALID := Vector2i(-1, -1)

var cash_rand := 0
var bag: Array[String] = []
var boot: Array[String] = []
var bag_cells: Array[Vector2i] = []
var boot_cells: Array[Vector2i] = []
var backpack_equipped := false
var equipment: Dictionary = {}
var boot_cash_rand := 0
var quick_slots: Array[int] = [0, -1, -1, -1]

func _init() -> void:
	for slot in EQUIP_ITEMS:
		equipment[slot] = str(ITEM_NAMES.get(INITIAL_GEAR.get(slot, ""), ""))
	for item in ["phone", "keys"]:
		stow(item)
	for item in ["backpack", "water", "torch", "jacket"]:
		insert("boot", item)

func capacity() -> int:
	return BACKPACK_CAPACITY if backpack_equipped else BASE_CAPACITY

func items_at(location: String) -> Array[String]:
	return boot if location == "boot" else bag

func cells_at(location: String) -> Array[Vector2i]:
	return boot_cells if location == "boot" else bag_cells

static func footprint(item: String) -> Vector2i:
	return ITEM_SIZES.get(item, Vector2i.ONE)

func item_for_slot(slot: String) -> String:
	if slot == "Back":
		return "backpack" if backpack_equipped else ""
	var label: String = equipment.get(slot, "")
	for item in EQUIP_ITEMS.get(slot, []):
		if ITEM_NAMES[item] == label:
			return item
	return ""

func can_place(location: String, item: String, cell: Vector2i, ignore: int = -1) -> bool:
	var dimensions := BOOT_SIZE if location == "boot" else BAG_SIZE
	var area := Rect2i(cell, footprint(item))
	if not Rect2i(Vector2i.ZERO, dimensions).encloses(area):
		return false
	var items := items_at(location)
	var cells := cells_at(location)
	if ignore < 0 and items.size() >= (BOOT_CAPACITY if location == "boot" else capacity()):
		return false
	for i in range(items.size()):
		if i != ignore and area.intersects(Rect2i(cells[i], footprint(items[i]))):
			return false
	return true

func first_open(location: String, item: String) -> Vector2i:
	var dimensions := BOOT_SIZE if location == "boot" else BAG_SIZE
	for y in range(dimensions.y):
		for x in range(dimensions.x):
			var cell := Vector2i(x, y)
			if can_place(location, item, cell):
				return cell
	return INVALID

func insert(location: String, item: String, cell: Vector2i = INVALID) -> bool:
	if not ITEM_NAMES.has(item):
		return false
	if cell == INVALID:
		cell = first_open(location, item)
	if cell == INVALID or not can_place(location, item, cell):
		return false
	items_at(location).append(item)
	cells_at(location).append(cell)
	return true

func remove(location: String, index: int) -> void:
	items_at(location).remove_at(index)
	cells_at(location).remove_at(index)

func move_item(from: String, index: int, to: String, cell: Vector2i) -> bool:
	var items := items_at(from)
	if index < 0 or index >= items.size():
		return false
	var item := items[index]
	if from == to:
		if not can_place(to, item, cell, index):
			return false
		cells_at(to)[index] = cell
	else:
		if not insert(to, item, cell):
			return false
		remove(from, index)
	return true

func equip_item(location: String, index: int, slot: String) -> bool:
	var items := items_at(location)
	if index < 0 or index >= items.size():
		return false
	var item := items[index]
	if not item in EQUIP_ITEMS.get(slot, []) or item in WEAPONS:
		return false
	var previous := item_for_slot(slot)
	var original := cells_at(location)[index]
	if not previous.is_empty():
		if previous == item or not can_place(location, previous, original, index):
			return false
		items[index] = previous
	else:
		remove(location, index)
	equipment[slot] = ITEM_NAMES[item]
	if slot == "Back":
		backpack_equipped = true
	return true

func unequip_item(slot: String, location: String, cell: Vector2i = INVALID) -> bool:
	var item := item_for_slot(slot)
	if item.is_empty() or item in WEAPONS:
		return false
	if slot == "Back" and bag.size() + int(location == "bag") > BASE_CAPACITY:
		return false
	if not insert(location, item, cell):
		return false
	equipment[slot] = ""
	if slot == "Back":
		backpack_equipped = false
	return true

func assign_quick(index: int, weapon: int) -> void:
	if index < 0 or index >= quick_slots.size() or weapon < 0 or weapon >= WEAPONS.size():
		return
	var former := quick_slots.find(weapon)
	if former >= 0:
		quick_slots[former] = quick_slots[index]
	quick_slots[index] = weapon

func unlock_quick(weapon: int) -> void:
	if not quick_slots.has(weapon):
		assign_quick(quick_slots.find(-1), weapon)

func add_cash(value: int) -> void:
	cash_rand += maxi(0, value)

func stow(item: String) -> bool:
	return insert("bag", item)

func take_from_boot(index: int) -> bool:
	return index >= 0 and index < boot.size() and move_item("boot", index, "bag", first_open("bag", boot[index]))

func equip_backpack() -> bool:
	return equip_item("bag", bag.find("backpack"), "Back")

func deposit_cash(amount: int) -> bool:
	if amount <= 0 or cash_rand < amount:
		return false
	cash_rand -= amount
	boot_cash_rand += amount
	return true

func withdraw_cash(amount: int) -> bool:
	if amount <= 0 or boot_cash_rand < amount:
		return false
	boot_cash_rand -= amount
	cash_rand += amount
	return true

func snapshot() -> Dictionary:
	return {
		"cash_rand":cash_rand, "bag":bag.duplicate(), "bag_cells":bag_cells.duplicate(),
		"boot":boot.duplicate(), "boot_cells":boot_cells.duplicate(),
		"backpack_equipped":backpack_equipped, "quick_slots":quick_slots.duplicate(),
		"equipment":equipment.duplicate(), "boot_cash_rand":boot_cash_rand
	}

func restore(data: Dictionary) -> void:
	cash_rand = maxi(0, int(data.get("cash_rand", 0)))
	boot_cash_rand = maxi(0, int(data.get("boot_cash_rand", 0)))
	backpack_equipped = bool(data.get("backpack_equipped", false))
	for location in ["bag", "boot"]:
		var previous: Array = data.get(location, items_at(location).duplicate())
		var positions: Array = data.get(location + "_cells", [])
		items_at(location).clear()
		cells_at(location).clear()
		for i in range(previous.size()):
			var cell: Vector2i = positions[i] if i < positions.size() else INVALID
			var item := str(previous[i])
			if not insert(location, item, cell):
				insert(location, item)
	var next_equipment: Dictionary = data.get("equipment", {})
	for slot in EQUIP_ITEMS:
		if next_equipment.has(slot):
			equipment[slot] = str(next_equipment[slot])
	var saved_quick: Array = data.get("quick_slots", [])
	for i in range(mini(quick_slots.size(), saved_quick.size())):
		quick_slots[i] = clampi(int(saved_quick[i]), -1, WEAPONS.size() - 1)
