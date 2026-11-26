extends RefCounted
# Visual-only assets: no weapon mechanics or physical dimensions.
const ITEMS := [
	{"id":"brick","label":"Brick","texture":preload("res://assets/props/rendered/brick.png")},
	{"id":"rubble","label":"Rubble","texture":preload("res://assets/props/rubble.svg")},
	{"id":"tyre","label":"Discarded tyre","texture":preload("res://assets/props/tyre.svg")},
	{"id":"bottle","label":"Discarded bottle","texture":preload("res://assets/props/bottle.svg")},
	{"id":"carton","label":"Cardboard carton","texture":preload("res://assets/props/carton.svg")},
	{"id":"bag","label":"Shopping bag","texture":preload("res://assets/props/bag.svg")},
	{"id":"phone","label":"Phone","texture":preload("res://assets/props/phone.svg")},
	{"id":"compact_icon","label":"Compact sidearm","texture":preload("res://assets/props/compact_icon.svg")},
	{"id":"modern_icon","label":"Modern sidearm","texture":preload("res://assets/props/modern_icon.svg")},
	{"id":"revolver_icon","label":"Ornate sidearm","texture":preload("res://assets/props/revolver_icon.svg")},
	{"id":"longarm_icon","label":"Long-arm icon","texture":preload("res://assets/props/longarm_icon.svg")},
	{"id":"blade_icon","label":"Blade icon","texture":preload("res://assets/props/blade_icon.svg")},
	{"id":"club_icon","label":"Wooden club icon","texture":preload("res://assets/props/rendered/club_icon.png")},
	{"id":"slingshot_icon","label":"Slingshot icon","texture":preload("res://assets/props/rendered/slingshot_icon.png")}
]

static func texture(id: String) -> Texture2D:
	for item in ITEMS:
		if item.id == id:
			return item.texture
	return null
