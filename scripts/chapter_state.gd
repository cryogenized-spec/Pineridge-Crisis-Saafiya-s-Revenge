extends RefCounted
# Preserve arcade health and inventory across chapter scene changes.
const SAVE_KEY := "pineridge_chapter_state"
const DECAL_KEY := "pineridge_chapter_decals"

static func store(tree: SceneTree, battle: Node) -> void:
	tree.root.set_meta(SAVE_KEY,{
		"hp":int(battle.player_hp),
		"rounds":battle.rounds.duplicate(),
		"spares":battle.spares.duplicate(),
		"unlocked":battle.unlocked.duplicate(),
		"slot":int(battle.slot),
		"inventory":battle.inventory.snapshot()
	})

static func restore(tree: SceneTree, battle: Node) -> void:
	if not tree.root.has_meta(SAVE_KEY):
		return
	var saved: Dictionary=tree.root.get_meta(SAVE_KEY)
	battle.player_hp=clampi(int(saved.get("hp",3)),0,3)
	var ammo: Array=saved.get("rounds",[])
	var spare: Array=saved.get("spares",[])
	var unlocked: Array=saved.get("unlocked",[])
	for i in range(3):
		if ammo.size()>i:
			battle.rounds[i]=clampi(int(ammo[i]),0,int(battle.KIT[i]["size"]))
		if spare.size()>i:
			battle.spares[i]=maxi(0,int(spare[i]))
		if unlocked.size()>i:
			battle.unlocked[i]=bool(unlocked[i])
	battle.slot=clampi(int(saved.get("slot",0)),0,2)
	if not bool(battle.unlocked[battle.slot]):
		battle.slot=0
	if saved.has("inventory"):
		battle.inventory.restore(saved["inventory"])
	for i in range(battle.unlocked.size()):
		if battle.unlocked[i]:
			battle.inventory.unlock_quick(i)
	if is_instance_valid(battle.held_visual):
		battle.held_visual.choose_slot(battle.slot)
	battle.update_hud()

static func stage_decals(tree: SceneTree, chapter: String) -> Array[Dictionary]:
	var by_chapter: Dictionary = tree.root.get_meta(DECAL_KEY, {})
	if not by_chapter.has(chapter):
		var decals: Array[Dictionary] = []
		by_chapter[chapter] = decals
		tree.root.set_meta(DECAL_KEY, by_chapter)
	return by_chapter[chapter]

static func clear_stage_decals(tree: SceneTree, chapter: String) -> void:
	if tree.root.has_meta(DECAL_KEY):
		var by_chapter: Dictionary = tree.root.get_meta(DECAL_KEY)
		by_chapter.erase(chapter)

static func reset(tree: SceneTree) -> void:
	for key in [SAVE_KEY, DECAL_KEY]:
		if tree.root.has_meta(key):
			tree.root.remove_meta(key)
