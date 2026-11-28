extends Node2D
## An optional story visit whose floors share the chapter's player and inventory.
signal moved_floor(destination: Vector2)

const Actor := preload("res://scripts/actor.gd")
const Model := preload("res://scripts/inventory_model.gd")
const Dialogue := preload("res://scripts/house_dialogue.gd")
const OWNER_PORTRAIT := preload("res://assets/ui/jacobs_house/jacobs.png")
const LOOTER_PORTRAIT := preload("res://assets/ui/jacobs_house/looter.png")
const KNOCK := preload("res://assets/audio/jacobs_door_knock.wav")
const KNOCK_ATLAS := preload("res://assets/characters/reactions/knock_07.png")
const HANDS_UP := preload("res://assets/characters/reactions/hands_up_07.png")
const VIEW := Rect2(2590, 26, 900, 506)
const BUILDING := Rect2(92, 116, 716, 310)
const PATIO := Rect2(308, 40, 280, 103)
const FRONT := Vector2(1972, 286)
const BACK := Vector2(2110, 116)
const OWNER_AT := Vector2(2137, 84)
const ENTRY := Vector2(448, 394)
const PATIO_EXIT := Vector2(448, 64)
const STAIR := Vector2(746, 367)
const LOOTER_AT := Vector2(607, 312)
const LOCKED_DOOR := Vector2(607, 286)
const PARLOR := [Rect2(122, 178, 56, 122), Rect2(225, 221, 107, 56), Rect2(200, 331, 121, 35)]
const KITCHEN := [Rect2(530, 138, 233, 44), Rect2(691, 183, 72, 57), Rect2(546, 226, 103, 57)]
const BEDROOM := [Rect2(142, 149, 114, 76), Rect2(353, 143, 54, 102), Rect2(143, 242, 74, 26)]
const DOWN_WALLS := [
	Rect2(92, 110, 331, 14), Rect2(475, 110, 333, 14),
	Rect2(413, 140, 12, 137), Rect2(470, 270, 12, 104)
]
const UP_WALLS := [
	Rect2(92, 279, 181, 14), Rect2(327, 279, 481, 14),
	Rect2(446, 117, 14, 170)
]
const GOLD := Color("#edc88f")
const PAPER := Color("#e9d7b9")
const WALL := Color("#322934")

var floor_number := 0
var inventory: Model
var hero: Actor
var dialogue: Dialogue
var resident: Actor
var upstairs_looter: Actor
var knock_audio: AudioStreamPlayer2D
var elapsed := 0.0
var raised := -1.0
var resolved := false
var quest_notice := ""
var notice_left := 0.0

func configure(player: Actor, player_inventory: Model) -> void:
	hero = player
	inventory = player_inventory

func _ready() -> void:
	resident = Actor.new()
	resident.wardrobe_index = 2
	resident.position = OWNER_AT
	resident.z_index = 2
	add_child(resident)
	upstairs_looter = Actor.new()
	upstairs_looter.wardrobe_index = 7
	upstairs_looter.position = VIEW.position + LOOTER_AT
	upstairs_looter.z_index = 2
	upstairs_looter.hide()
	add_child(upstairs_looter)
	dialogue = Dialogue.new()
	add_child(dialogue)
	knock_audio = AudioStreamPlayer2D.new()
	knock_audio.position = VIEW.position + LOCKED_DOOR
	knock_audio.stream = KNOCK
	knock_audio.volume_db = -13
	knock_audio.max_distance = 440.0
	add_child(knock_audio)

func indoors() -> bool:
	return floor_number > 0

func destination() -> Vector2:
	return VIEW.get_center()

func interact() -> bool:
	var point := hero.position
	if floor_number == 0:
		if point.distance_to(OWNER_AT) <= 38.0:
			talk_to_owner()
			return true
		if point.distance_to(FRONT) <= 28.0 or point.distance_to(BACK) <= 27.0:
			if inventory.ridge_house_key:
				change_floor(1, ENTRY if point.distance_to(FRONT) <= 28.0 else PATIO_EXIT)
			else:
				notify("The house is locked. Someone is behind it.")
			return true
		return false
	var local := point - VIEW.position
	if floor_number == 1:
		if local.distance_to(ENTRY) <= 27.0:
			change_floor(0, FRONT)
		elif local.distance_to(PATIO_EXIT) <= 26.0:
			change_floor(0, BACK)
		elif local.distance_to(STAIR) <= 30.0:
			change_floor(2, STAIR)
		else:
			return false
	elif local.distance_to(STAIR) <= 30.0:
		change_floor(1, STAIR)
	elif raised >= 0.0 and local.distance_to(LOOTER_AT) <= 46.0:
		talk_to_looter()
	elif local.distance_to(LOCKED_DOOR) <= 28.0:
		notify("The upstairs room is locked.")
	else:
		return false
	return true

func change_floor(next_floor: int, point: Vector2) -> void:
	floor_number = next_floor
	elapsed = 0.0
	quest_notice = ""
	upstairs_looter.visible = floor_number == 2
	knock_audio.stop()
	moved_floor.emit(point + VIEW.position if indoors() else point)
	queue_redraw()

func talk_to_owner() -> void:
	if resolved:
		dialogue.show_dialogue("Mr. Jacobs", OWNER_PORTRAIT, [
			{"text":"Thank you, Saafiya. I’ll stay here and let the police know what happened."}
		])
	elif inventory.ridge_house_key:
		dialogue.show_dialogue("Mr. Jacobs", OWNER_PORTRAIT, [
			{"text":"You have the key. I’ll wait here for the police."}
		])
	else:
		dialogue.show_dialogue("Mr. Jacobs", OWNER_PORTRAIT, [
			{"text":"Saafiya? I’m Jacobs. Some looters got into my house. I slipped out and locked them inside."},
			{"hero":true, "text":"Did you call the police?"},
			{"text":"I did. They said someone would come, but who knows how long it’ll take. Here’s the key. Could you check upstairs?"}
		], "Take the house key", accept_request)

func accept_request() -> void:
	inventory.ridge_house_key = true
	notify("Jacobs house key added to your key ring.")

func talk_to_looter() -> void:
	if resolved:
		dialogue.show_dialogue("Looter", LOOTER_PORTRAIT, [{"text":"I’ll stay here and wait."}])
	else:
		dialogue.show_dialogue("Looter", LOOTER_PORTRAIT, [
			{"text":"Okay, okay. I’m done. I thought that door led out, but it won’t open."},
			{"hero":true, "text":"That’s another room. Mr. Jacobs is outside, and the police are on their way."},
			{"text":"I came in with someone else. We got separated. I’ll wait here."}
		], "Ask him to wait for police", resolve_request)

func resolve_request() -> void:
	resolved = true
	notify("Jacobs house · the upstairs looter agreed to wait.")

func notify(message: String) -> void:
	quest_notice = message
	notice_left = 3.8
	queue_redraw()

func blocked(world_point: Vector2, radius: float = 7.0) -> bool:
	var point := world_point - VIEW.position
	if not BUILDING.grow(-radius).has_point(point) and not (
			floor_number == 1 and PATIO.grow(-radius).has_point(point)):
		return true
	var solids := PARLOR + KITCHEN + DOWN_WALLS if floor_number == 1 else BEDROOM + UP_WALLS
	for area in solids:
		if area.grow(radius).has_point(point):
			return true
	return floor_number == 2 and point.distance_to(LOOTER_AT) < radius + 10.0

func objective() -> String:
	var point := hero.position
	if not quest_notice.is_empty():
		return quest_notice
	if floor_number == 1:
		var local := point - VIEW.position
		if local.distance_to(ENTRY) <= 27:
			return "E  ·  Front door to Upper Pineridge"
		if local.distance_to(PATIO_EXIT) <= 26:
			return "E  ·  Back gate to the lawn"
		if local.distance_to(STAIR) <= 30:
			return "E  ·  Go upstairs"
		return "Jacobs house  ·  Lounge, kitchen and patio"
	if floor_number == 2:
		var local := point - VIEW.position
		if local.distance_to(STAIR) <= 30:
			return "E  ·  Go downstairs"
		if raised >= 0 and local.distance_to(LOOTER_AT) <= 46:
			return "E  ·  Speak to the looter"
		return "Jacobs house  ·  Upstairs room secured" if resolved else "Find who’s knocking upstairs"
	if point.distance_to(OWNER_AT) <= 44:
		return "E  ·  Speak to Mr. Jacobs"
	if point.distance_to(FRONT) <= 34 or point.distance_to(BACK) <= 34:
		return "E  ·  Enter the Jacobs house" if inventory.ridge_house_key else "E  ·  Check the door"
	if point.y < 383 and point.x > 1850 and not inventory.ridge_house_key:
		return "Someone is sheltering behind the Jacobs house."
	return ""

func _process(delta: float) -> void:
	notice_left = maxf(0.0, notice_left - delta)
	if notice_left <= 0.0:
		quest_notice = ""
	if floor_number == 0:
		if hero.position.distance_squared_to(OWNER_AT) < 42000:
			resident.animate(delta, Vector2.ZERO, (hero.position - OWNER_AT).angle())
		return
	if floor_number == 1 or dialogue.open:
		return
	var local := hero.position - VIEW.position
	if raised < 0 and local.y >= 298 and local.distance_to(LOOTER_AT) <= 129:
		raised = 0.0
		knock_audio.stop()
	if raised >= 0:
		raised = minf(1.0, raised + delta * 1.65)
		upstairs_looter.action_atlas = HANDS_UP
		upstairs_looter.action_phase = raised
		upstairs_looter.animate(delta, Vector2.ZERO, (local - LOOTER_AT).angle())
	else:
		var before := elapsed
		elapsed = fmod(elapsed + delta, 2.5)
		if before < .20 and elapsed >= .20:
			knock_audio.play()
		upstairs_looter.action_atlas = KNOCK_ATLAS
		upstairs_looter.action_phase = clampf(elapsed - .16, 0.0, 1.0)
		upstairs_looter.animate(delta, Vector2.ZERO, Vector2.UP.angle())
	queue_redraw()

func _draw() -> void:
	if floor_number == 0:
		if not inventory.ridge_house_key:
			world_marker(OWNER_AT + Vector2(0, -24), "MR. JACOBS")
		return
	draw_set_transform(VIEW.position)
	draw_rect(Rect2(Vector2.ZERO, VIEW.size), Color("#24222b"))
	draw_rect(Rect2(14, 14, VIEW.size.x - 28, VIEW.size.y - 28), Color("#3d323c"), false, 1)
	if floor_number == 1:
		draw_lower()
	else:
		draw_upper()
	draw_set_transform(Vector2.ZERO)

func draw_lower() -> void:
	draw_rect(PATIO.grow(9), WALL)
	draw_rect(PATIO, Color("#7d7d69"))
	for y in range(50, 143, 16):
		draw_line(Vector2(308, y), Vector2(588, y), Color("#666957"))
	for x in range(316, 589, 22):
		draw_line(Vector2(x, 40), Vector2(x, 143), Color("#96927a"))
	for point in [Vector2(331, 66), Vector2(565, 66), Vector2(551, 102)]:
		draw_circle(point + Vector2(3, 4), 11, Color("#4c463d"), true, -1, true)
		draw_circle(point, 10, Color("#63785b"), true, -1, true)
	planks(BUILDING)
	var tiles := Rect2(493, 124, 307, 293)
	draw_rect(tiles, Color("#8b8679"))
	for y in range(130, 414, 21):
		for x in range(499, 785, 21):
			var light := (x + y) / 21
			var tint := Color("#aaa397") if floori(light) % 2 == 0 else Color("#969183")
			draw_rect(Rect2(x, y, 20, 20), tint)
	for item in DOWN_WALLS:
		wall(item)
	rug(Rect2(188, 189, 193, 138), Color("#764d53"))
	furniture(PARLOR[0], Color("#5b6867"))
	for y in range(187, 285, 31):
		draw_rect(Rect2(133, y, 36, 23), Color("#7d8c83"))
	furniture(PARLOR[1], Color("#755243"))
	draw_circle(Vector2(268, 249), 12, Color("#b39879"))
	furniture(PARLOR[2], Color("#5b4444"))
	furniture(KITCHEN[0], Color("#646658"))
	furniture(KITCHEN[1], Color("#6c786b"))
	furniture(KITCHEN[2], Color("#725846"))
	draw_rect(Rect2(556, 145, 44, 29), Color("#a5aaa0"))
	draw_rect(Rect2(562, 151, 32, 17), Color("#5b6e6c"))
	for x in [654, 675]:
		for y in [150, 165]:
			draw_circle(Vector2(x, y), 5, Color("#252832"), false, 2, true)
	for x in [574, 615]:
		draw_circle(Vector2(x, 253), 9, Color("#d8c9a3"), true, -1, true)
	stairs()
	room_label(Vector2(214, 152), "LOUNGE")
	room_label(Vector2(557, 205), "KITCHEN")
	world_marker(PATIO_EXIT, "BACK GATE")
	world_marker(ENTRY, "FRONT DOOR")
	world_marker(STAIR, "UPSTAIRS")

func draw_upper() -> void:
	planks(BUILDING)
	for item in UP_WALLS:
		wall(item)
	rug(Rect2(275, 162, 62, 110), Color("#5d696c"))
	furniture(BEDROOM[0], Color("#667776"))
	draw_rect(Rect2(149, 156, 29, 56), Color("#cfbca6"))
	draw_rect(Rect2(183, 155, 68, 62), Color("#7d9793"))
	furniture(BEDROOM[1], Color("#6b4b40"))
	for y in range(149, 235, 25):
		draw_line(Vector2(360, y+6), Vector2(397, y+6), Color("#aa8b6d"), 1)
	furniture(BEDROOM[2], Color("#5c4545"))
	draw_rect(Rect2(460, 119, 345, 160), Color("#312c32"))
	draw_rect(Rect2(471, 129, 324, 137), Color("#39333b"), false, 2)
	draw_rect(Rect2(580, 277, 54, 17), Color("#886856"))
	var clock := clampf(elapsed - .16, 0.0, 1.0)
	if raised < 0 and (absf(clock - .24) < .055 or absf(clock - .46) < .055):
		draw_line(Vector2(593, 275), Vector2(586, 266), GOLD, 1.8, true)
		draw_line(Vector2(618, 275), Vector2(626, 267), GOLD, 1.8, true)
	room_label(Vector2(270, 153), "OPEN ROOM")
	room_label(Vector2(563, 199), "LOCKED ROOM")
	stairs()
	world_marker(STAIR, "DOWNSTAIRS")

func planks(rect: Rect2) -> void:
	draw_rect(rect.grow(9), WALL)
	draw_rect(rect, Color("#846653"))
	for x in range(int(rect.position.x) + 11, int(rect.end.x), 14):
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), Color("#6b5147"))
		var splice := fposmod(x * 2.37, rect.size.y - 15)
		draw_line(Vector2(x, rect.position.y + splice), Vector2(x+14, rect.position.y+splice), Color("#705647"))
	draw_rect(rect.grow(-3), Color("#a8876b"), false, 2)

func wall(area: Rect2) -> void:
	draw_rect(Rect2(area.position + Vector2(3, 5), area.size), Color("#4c3d3f"))
	draw_rect(area, WALL)
	draw_line(area.position, Vector2(area.end.x, area.position.y), Color("#b29984"), 2)

func rug(area: Rect2, color: Color) -> void:
	draw_rect(area, color)
	draw_rect(area.grow(-6), color.lightened(.30), false, 2)
	draw_rect(area.grow(-11), color.darkened(.19), false, 1)

func furniture(area: Rect2, color: Color) -> void:
	draw_rect(Rect2(area.position + Vector2(5, 6), area.size), Color("#554443"))
	draw_rect(area, color)
	draw_rect(area.grow(-4), color.lightened(.21), false, 2)

func stairs() -> void:
	var area := Rect2(STAIR + Vector2(-38, -24), Vector2(78, 56))
	draw_rect(area, Color("#675347"))
	for x in range(int(area.position.x)+6, int(area.end.x), 8):
		draw_line(Vector2(x, area.position.y), Vector2(x, area.end.y), Color("#a48b70"))
	draw_rect(area, Color("#3c3030"), false, 2)

func room_label(point: Vector2, words: String) -> void:
	draw_string(ThemeDB.fallback_font, point, words, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, PAPER)

func world_marker(point: Vector2, words: String) -> void:
	var width := ThemeDB.fallback_font.get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_circle(point, 3.2, GOLD, true, -1, true)
	draw_rect(Rect2(point + Vector2(-width*.5-5, -23), Vector2(width+10, 17)), Color("#26202b"))
	draw_string(ThemeDB.fallback_font, point + Vector2(-width*.5, -10), words,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, GOLD)
