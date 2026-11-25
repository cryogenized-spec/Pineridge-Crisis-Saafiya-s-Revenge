extends RefCounted
# Fictional RPG inventory: belongings are finite and carried across scenes.
const BASE_CAPACITY := 8
const BACKPACK_CAPACITY := 18
const BOOT_CAPACITY := 40
const ITEM_NAMES := {
	"phone":"Mobile phone","keys":"Car keys","backpack":"Canvas backpack",
	"water":"Water bottle","torch":"Battery torch","jacket":"Spare jacket"
}
const EQUIPMENT_SLOTS := [
	"Head","Neck","Torso","Arms","Belt","Boots","Left hand","Right hand",
	"Sidearm","Primary","Backup","Knife",
	"Ring L1","Ring L2","Ring L3","Ring L4","Ring L5",
	"Ring R1","Ring R2","Ring R3","Ring R4","Ring R5"
]
var cash_rand := 0
var bag: Array[String] = ["phone","keys"]
var boot: Array[String] = ["backpack","water","torch","jacket"]
var backpack_equipped := false
var equipment: Dictionary = {}
var boot_cash_rand := 0

func _init() -> void:
	for slot in EQUIPMENT_SLOTS:
		equipment[slot]=""
	equipment["Torso"]="Black lace top"
	equipment["Belt"]="Waist chain"
	equipment["Boots"]="Black boots"
	equipment["Sidearm"]="Beretta 84FS"
	equipment["Left hand"]="Left-handed"

func capacity() -> int:
	return BACKPACK_CAPACITY if backpack_equipped else BASE_CAPACITY

func add_cash(value: int) -> void:
	cash_rand+=maxi(0,value)

func take_from_boot(index: int) -> bool:
	if index<0 or index>=boot.size() or bag.size()>=capacity():
		return false
	bag.append(boot[index])
	boot.remove_at(index)
	return true

func store_in_boot(index: int) -> bool:
	if index<0 or index>=bag.size() or boot.size()>=BOOT_CAPACITY:
		return false
	boot.append(bag[index])
	bag.remove_at(index)
	return true

func equip_backpack() -> bool:
	if backpack_equipped or not bag.has("backpack"):
		return false
	bag.erase("backpack")
	backpack_equipped=true
	return true

func unequip_backpack() -> bool:
	if not backpack_equipped or bag.size()>=BASE_CAPACITY:
		return false
	backpack_equipped=false
	bag.append("backpack")
	return true

func deposit_cash(amount: int) -> bool:
	if amount<=0 or cash_rand<amount:
		return false
	cash_rand-=amount
	boot_cash_rand+=amount
	return true

func withdraw_cash(amount: int) -> bool:
	if amount<=0 or boot_cash_rand<amount:
		return false
	boot_cash_rand-=amount
	cash_rand+=amount
	return true

func snapshot() -> Dictionary:
	return {
		"cash_rand":cash_rand,"bag":bag.duplicate(),
		"boot":boot.duplicate(),"backpack_equipped":backpack_equipped,
		"equipment":equipment.duplicate(true),"boot_cash_rand":boot_cash_rand
	}

func restore(data: Dictionary) -> void:
	cash_rand=maxi(0,int(data.get("cash_rand",0)))
	boot_cash_rand=maxi(0,int(data.get("boot_cash_rand",0)))
	backpack_equipped=bool(data.get("backpack_equipped",false))
	var next_bag: Array=data.get("bag",["phone","keys"])
	var next_boot: Array=data.get("boot",["backpack","water","torch","jacket"])
	bag.clear()
	boot.clear()
	for value in next_bag:
		var item: String=str(value)
		if ITEM_NAMES.has(item) and bag.size()<capacity():
			bag.append(item)
	for value in next_boot:
		var item: String=str(value)
		if ITEM_NAMES.has(item) and boot.size()<BOOT_CAPACITY:
			boot.append(item)
	var next_equipment: Dictionary=data.get("equipment",{})
	for slot in EQUIPMENT_SLOTS:
		if next_equipment.has(slot):
			equipment[slot]=str(next_equipment[slot])
