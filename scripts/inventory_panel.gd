extends CanvasLayer
# RPG-inspired equipment view and interactive car storage.
const Model=preload("res://scripts/inventory_model.gd")
var model: Model
var open := false
var at_car := false
var taking: Callable
var contents: Array[Dictionary] = []
var root: Control
var headline: Label
var money: Label
var hint: Label
var equip_col: VBoxContainer
var bag_col: VBoxContainer
var boot_col: VBoxContainer

func configure(source: Model) -> void:
	model=source

func _ready() -> void:
	layer=20
	root=Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter=Control.MOUSE_FILTER_STOP
	add_child(root)
	var panel:=PanelContainer.new()
	panel.position=Vector2(125,42)
	panel.custom_minimum_size=Vector2(1030,630)
	var style:=StyleBoxFlat.new()
	style.bg_color=Color("#171820")
	style.border_color=Color("#a99781")
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left=18
	style.content_margin_top=14
	style.content_margin_right=18
	style.content_margin_bottom=14
	panel.add_theme_stylebox_override("panel",style)
	root.add_child(panel)
	var stack:=VBoxContainer.new()
	stack.add_theme_constant_override("separation",11)
	panel.add_child(stack)
	headline=Label.new()
	headline.add_theme_font_size_override("font_size",23)
	headline.modulate=Color("#f0d7ac")
	stack.add_child(headline)
	money=Label.new()
	money.add_theme_font_size_override("font_size",17)
	stack.add_child(money)
	var row:=HBoxContainer.new()
	row.add_theme_constant_override("separation",18)
	stack.add_child(row)
	equip_col=VBoxContainer.new()
	equip_col.custom_minimum_size=Vector2(318,0)
	row.add_child(equip_col)
	bag_col=VBoxContainer.new()
	bag_col.custom_minimum_size=Vector2(280,0)
	row.add_child(bag_col)
	boot_col=VBoxContainer.new()
	boot_col.custom_minimum_size=Vector2(260,0)
	row.add_child(boot_col)
	hint=Label.new()
	hint.add_theme_font_size_override("font_size",13)
	hint.modulate=Color("#c4bcaf")
	stack.add_child(hint)
	root.visible=false

func clear_box(parent: VBoxContainer) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()

func caption(parent: Node,value: String,size: int=13) -> void:
	var lbl:=Label.new()
	lbl.text=value
	lbl.add_theme_font_size_override("font_size",size)
	lbl.modulate=Color("#d8d1c6")
	parent.add_child(lbl)

func action(parent: Node,label_text: String,callback: Callable,disabled: bool=false) -> Button:
	var b:=Button.new()
	b.text=label_text
	b.disabled=disabled
	b.custom_minimum_size=Vector2(0,26)
	b.add_theme_font_size_override("font_size",12)
	if callback.is_valid():
		b.pressed.connect(callback)
	parent.add_child(b)
	return b

func show_inventory(car_access: bool=false) -> void:
	taking = Callable()
	contents = []
	at_car=car_access
	open=true
	root.visible=true
	refresh()

func close_inventory() -> void:
	open=false
	at_car=false
	taking = Callable()
	contents = []
	root.visible=false

func show_loot(items: Array[Dictionary], transfer: Callable) -> void:
	contents = items
	taking = transfer
	at_car = false
	open = true
	root.visible = true
	refresh()

func toggle() -> void:
	if open:
		close_inventory()
	else:
		show_inventory()

func refresh() -> void:
	if not open or model==null:
		return
	headline.text="SAAFIYA  /  CAR BOOT" if at_car else "SAAFIYA  /  EQUIPMENT & INVENTORY"
	hint.text="I or Esc to close   •   E by parked car to open boot"
	if taking.is_valid():
		headline.text = "SEARCH  /  SAAFIYA'S INVENTORY"
		hint.text = "Click an item to take it   •   I, E or Esc to close"
	money.text="WALLET  R%d     |     BACKPACK %s     |     ITEMS %d / %d" % [
		model.cash_rand,"EQUIPPED" if model.backpack_equipped else "NOT EQUIPPED",model.bag.size(),model.capacity()]
	for col in [equip_col,bag_col,boot_col]:
		clear_box(col)
	caption(equip_col,"EQUIPMENT",17)
	for slot in Model.EQUIPMENT_SLOTS:
		var value: String=str(model.equipment.get(slot,""))
		caption(equip_col,"%s  •  %s" % [slot,value if value!="" else "Empty"],12)
	caption(bag_col,"POCKETS / BACKPACK",17)
	if model.bag.is_empty():
		caption(bag_col,"Empty")
	for i in range(model.bag.size()):
		var name: String=str(Model.ITEM_NAMES.get(model.bag[i],model.bag[i]))
		if at_car:
			action(bag_col,name+"  → BOOT",_deposit.bind(i))
		else:
			caption(bag_col,"• "+name)
	if not model.backpack_equipped and model.bag.has("backpack"):
		action(bag_col,"Equip backpack",_equip_pack)
	elif model.backpack_equipped:
		action(bag_col,"Remove backpack",_remove_pack,model.bag.size()>=Model.BASE_CAPACITY)
	caption(boot_col,"DOWNED OPPONENT" if taking.is_valid() else ("CAR BOOT" if at_car else "STORAGE"),17)
	if taking.is_valid():
		loot_buttons()
	elif at_car:
		caption(boot_col,"Stored money: R%d" % model.boot_cash_rand)
		for i in range(model.boot.size()):
			action(boot_col,str(Model.ITEM_NAMES.get(model.boot[i],model.boot[i]))+"  → BAG",_withdraw.bind(i),model.bag.size()>=model.capacity())
		action(boot_col,"Deposit R50",_put_cash,model.cash_rand<50)
		action(boot_col,"Withdraw R50",_take_cash,model.boot_cash_rand<50)
	else:
		caption(boot_col,"Return to Saafiya's car")
		caption(boot_col,"to move items and cash.")

func loot_buttons() -> void:
	if contents.is_empty():
		caption(boot_col, "Empty")
	for entry in contents:
		var button := action(boot_col, entry.label, Callable(),
			entry.item not in ["cash", "magazine"] and model.bag.size() >= model.capacity()
			and not (entry.item == "pistol" and model.equipment["Backup"].is_empty()))
		button.pressed.connect(_take_loot.bind(entry, button))

func _take_loot(entry: Dictionary, button: Button) -> void:
	if not open or not taking.is_valid():
		return
	var start := button.global_position
	var destination: String = taking.call(entry)
	if destination.is_empty():
		return
	refresh()
	var target := bag_col.global_position + Vector2(12, 25)
	if destination == "equipment":
		target = equip_col.global_position + Vector2(12, 210)
	elif destination == "wallet":
		target = money.global_position
	var token := Label.new()
	token.text = entry.label
	token.mouse_filter = Control.MOUSE_FILTER_IGNORE
	token.add_theme_color_override("font_color", Color("#ffdf9e"))
	token.add_theme_color_override("font_shadow_color", Color("#141018"))
	token.add_theme_constant_override("shadow_offset_x", 2)
	token.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(token)
	token.global_position = start
	var tween := create_tween()
	tween.tween_property(token, "global_position", start.lerp(target, 0.46) - Vector2(0, 34),
		0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(token, "global_position", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(token, "modulate:a", 0.0, 0.22)
	tween.tween_callback(token.queue_free)

func _deposit(index: int) -> void:
	if at_car and model.store_in_boot(index):
		refresh()

func _withdraw(index: int) -> void:
	if at_car and model.take_from_boot(index):
		refresh()

func _equip_pack() -> void:
	if model.equip_backpack():
		refresh()

func _remove_pack() -> void:
	if model.unequip_backpack():
		refresh()

func _put_cash() -> void:
	if at_car and model.deposit_cash(50):
		refresh()

func _take_cash() -> void:
	if at_car and model.withdraw_cash(50):
		refresh()
