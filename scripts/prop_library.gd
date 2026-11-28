extends RefCounted
## Props used by campaign scenery and character animations.
const ITEMS := {
	"brick":preload("res://assets/props/rendered/brick.png"),
	"rubble":preload("res://assets/props/rendered/rubble.png"),
	"tyre":preload("res://assets/props/rendered/tyre.png"),
	"bottle":preload("res://assets/props/rendered/bottle.png"),
	"carton":preload("res://assets/props/rendered/carton.png"),
	"blade_icon":preload("res://assets/props/rendered/blade.png"),
	"club_icon":preload("res://assets/props/rendered/club_icon.png"),
	"slingshot_icon":preload("res://assets/props/rendered/slingshot_icon.png"),
	"pebble":preload("res://assets/props/rendered/pebble.png")
}

static func texture(id: String) -> Texture2D:
	return ITEMS.get(id)
