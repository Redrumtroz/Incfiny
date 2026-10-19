extends Control

# ==========================================
# INTERFACE DE LA VILLE (HUB) - VERSION FINALE
# ==========================================

@onready var main_vbox = $MainVBox
@onready var top_menu_bar = $MainVBox/TopMenuBar
@onready var workspace_split = $MainVBox/WorkspaceSplit
@onready var left_panel = $MainVBox/WorkspaceSplit/LeftPanel
@onready var resource_list = $MainVBox/WorkspaceSplit/LeftPanel/ResourceList
@onready var right_workspace = $MainVBox/WorkspaceSplit/RightWorkspace
@onready var city_map = $MainVBox/WorkspaceSplit/RightWorkspace/CityMap
@onready var build_menu_scroll = $MainVBox/WorkspaceSplit/RightWorkspace/BuildMenuScroll
@onready var build_list = $MainVBox/WorkspaceSplit/RightWorkspace/BuildMenuScroll/BuildList

var resource_labels = {}
var building_buttons = {}
var is_resource_panel_open = true

var map_camera : Control
var is_dragging_map = false
var selected_building_tool = ""

var stat_pop_label : Label
var stat_bld_label : Label
var placed_buildings_count = 0

var max_clickables_on_map = 15
var tree_timer : Timer
var rock_timer : Timer

var resource_names = {
	"RES_GOLD": "Or", "MAT_WOOD": "Bois", "MAT_STONE": "Pierre", 
	"MAT_WATER": "Eau", "MAT_PLANK": "Planches", "MAT_CEMENT": "Ciment"
}

func _ready() -> void:
	ScreenManager.register_hub(self)
	SignalBus.resources_updated.connect(update_ui)
	
	setup_map_camera()
	setup_stats_overlay()
	setup_top_bar()
	
	generate_resource_ui()
	generate_build_menu()
	
	setup_spawners()
	update_ui()

# Efface l'avertissement jaune sur le paramètre "delta"
func _process(_delta: float) -> void:
	pass

# ==========================================
# INITIALISATION DE L'INTERFACE
# ==========================================

func setup_map_camera() -> void:
	city_map.clip_contents = true
	city_map.mouse_filter = Control.MOUSE_FILTER_PASS
	
	map_camera = Control.new()
	map_camera.set_anchors_preset(Control.PRESET_FULL_RECT)
	map_camera.mouse_filter = Control.MOUSE_FILTER_IGNORE
	city_map.add_child(map_camera)
	
	city_map.gui_input.connect(_on_map_gui_input)

func setup_stats_overlay() -> void:
	var stats_panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#ffffff")
	style.set_border_width(SIDE_BOTTOM, 3)
	style.border_color = Color("#2f3130")
	style.set_corner_radius_all(12)
	stats_panel.add_theme_stylebox_override("panel", style)
	
	stats_panel.position = Vector2(20, 20)
	stats_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	
	var pop_vbox = VBoxContainer.new()
	stat_pop_label = Label.new()
	stat_pop_label.add_theme_color_override("font_color", Color("#1f2937"))
	stat_pop_label.add_theme_font_size_override("font_size", 20)
	pop_vbox.add_child(Label.new())
	pop_vbox.get_child(0).text = "POPULATION"
	pop_vbox.add_child(stat_pop_label)
	
	var bld_vbox = VBoxContainer.new()
	stat_bld_label = Label.new()
	stat_bld_label.add_theme_color_override("font_color", Color("#1f2937"))
	stat_bld_label.add_theme_font_size_override("font_size", 20)
	bld_vbox.add_child(Label.new())
	bld_vbox.get_child(0).text = "BÂTIMENTS"
	bld_vbox.add_child(stat_bld_label)
	
	hbox.add_child(pop_vbox)
	hbox.add_child(bld_vbox)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_child(hbox)
	stats_panel.add_child(margin)
	city_map.add_child(stats_panel)

func setup_top_bar() -> void:
	var btn_toggle_res = Button.new()
	btn_toggle_res.text = "📦 Ressources"
	btn_toggle_res.pressed.connect(_toggle_resource_panel)
	top_menu_bar.add_child(btn_toggle_res)
	
	var separator = VSeparator.new()
	top_menu_bar.add_child(separator)
	
	var modules = {"🚜 Aller à la Ferme": "res://Modules/Farm/Farm.tscn"}
	for mod_name in modules.keys():
		var btn = Button.new()
		btn.text = mod_name
		btn.pressed.connect(func(): ScreenManager.open_module(modules[mod_name]))
		top_menu_bar.add_child(btn)

func generate_resource_ui() -> void:
	for res_id in EconomyManager.inventory.keys():
		var lbl = Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		
		# Connexion au TooltipManager global
		lbl.mouse_entered.connect(func(): 
			var text = "[b]" + resource_names.get(res_id, res_id) + "[/b]\nRessource globale."
			TooltipManager.show_tooltip(text)
		)
		lbl.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
		
		resource_list.add_child(lbl)
		resource_labels[res_id] = lbl

func _toggle_resource_panel() -> void:
	is_resource_panel_open = !is_resource_panel_open
	left_panel.visible = is_resource_panel_open

func generate_build_menu() -> void:
	build_menu_scroll.custom_minimum_size.y = 120 
	
	for b_id in EconomyManager.buildings_data.keys():
		var b_data = EconomyManager.buildings_data[b_id]
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(100, 100)
		btn.toggle_mode = true
		
		var vbox = VBoxContainer.new()
		vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
		vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		
		var ui_data = b_data.get("ui", {})
		var icon_lbl = Label.new()
		icon_lbl.text = ui_data.get("icon", "🏗️")
		icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_lbl.add_theme_font_size_override("font_size", 32)
		
		var name_lbl = Label.new()
		name_lbl.text = b_data.get("name", "Bâtiment")
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_font_size_override("font_size", 12)
		
		vbox.add_child(icon_lbl)
		vbox.add_child(name_lbl)
		btn.add_child(vbox)
		
		btn.pressed.connect(func(): _select_building_tool(b_id, btn))
		
		btn.mouse_entered.connect(func(): _show_build_tooltip(b_id))
		btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
		
		build_list.add_child(btn)
		building_buttons[b_id] = btn

# ==========================================
# INTERACTIONS ET LOGIQUE DE CONSTRUCTION
# ==========================================

func _show_build_tooltip(b_id: String) -> void:
	var b_data = EconomyManager.buildings_data[b_id]
	var current_cost = calculate_current_cost(b_data)
	
	var b_name = b_data.get("name", "Bâtiment")
	var owned_count = b_data.get("owned", 0)
	var desc = b_data.get("description", "Un bâtiment utile.")
	
	var text = "[b]" + b_name + "[/b] (Possédés: " + str(owned_count) + ")\n"
	text += "[color=#aaaaaa]" + desc + "[/color]\n\n"
	
	text += "Coût de construction :\n"
	for res_id in current_cost.keys():
		var color = "#ff5555" if EconomyManager.get_resource(res_id) < current_cost[res_id] else "#55ff55"
		text += "[color=" + color + "]- " + str(current_cost[res_id]) + " " + resource_names.get(res_id, res_id) + "[/color]\n"
	
	if b_data.has("production") and b_data["production"].size() > 0:
		text += "\nProduit par seconde :\n"
		for res_id in b_data["production"].keys():
			text += "[color=#55ffff]+ " + str(b_data["production"][res_id]) + " " + resource_names.get(res_id, res_id) + "[/color]\n"
			
	if b_data.has("consumption") and b_data["consumption"].size() > 0:
		text += "\nConsomme par seconde :\n"
		for res_id in b_data["consumption"].keys():
			text += "[color=#ffaa00]- " + str(b_data["consumption"][res_id]) + " " + resource_names.get(res_id, res_id) + "[/color]\n"
	
	TooltipManager.show_tooltip(text)

func _select_building_tool(b_id: String, active_btn: Button) -> void:
	for key in building_buttons:
		if building_buttons[key] != active_btn:
			building_buttons[key].button_pressed = false
			
	if active_btn.button_pressed:
		selected_building_tool = b_id
		city_map.mouse_default_cursor_shape = Control.CURSOR_CROSS
	else:
		selected_building_tool = ""
		city_map.mouse_default_cursor_shape = Control.CURSOR_ARROW

func _on_map_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging_map = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected_building_tool != "":
				_try_place_building(event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom_map(1.1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom_map(0.9, event.position)
	elif event is InputEventMouseMotion:
		if is_dragging_map:
			map_camera.position += event.relative

func _zoom_map(factor: float, mouse_pos: Vector2) -> void:
	var old_zoom = map_camera.scale
	var new_zoom = old_zoom * factor
	new_zoom.x = clamp(new_zoom.x, 0.5, 3.0)
	new_zoom.y = clamp(new_zoom.y, 0.5, 3.0)
	
	if new_zoom == old_zoom: return
	var mouse_world_pos = (mouse_pos - map_camera.position) / old_zoom
	map_camera.scale = new_zoom
	map_camera.position = mouse_pos - mouse_world_pos * new_zoom

func _try_place_building(click_pos: Vector2) -> void:
	var current_tool = selected_building_tool 
	var b_data = EconomyManager.buildings_data[current_tool]
	var current_cost = calculate_current_cost(b_data)
	
	if EconomyManager.can_afford(current_cost):
		for res_id in current_cost.keys():
			EconomyManager.add_resource(res_id, -current_cost[res_id])
		
		# --- CORRECTION FINALE : On initialise "owned" s'il n'existe pas ---
		if not b_data.has("owned"):
			b_data["owned"] = 0
		b_data["owned"] += 1
		
		placed_buildings_count += 1
		stat_bld_label.text = str(placed_buildings_count)
		stat_pop_label.text = str(placed_buildings_count * 4)
		
		var local_pos = (click_pos - map_camera.position) / map_camera.scale
		_spawn_building_visual(current_tool, local_pos)
		
		update_ui()
		_show_build_tooltip(current_tool)

func _spawn_building_visual(b_id: String, pos: Vector2) -> void:
	var b_data = EconomyManager.buildings_data[b_id]
	var ui_data = b_data.get("ui", {})
	
	var visual_data = {
		"color": Color(ui_data.get("color", "#888888")),
		"icon": ui_data.get("icon", "🏢"),
		"size": Vector2(ui_data.get("size", [50, 50])[0], ui_data.get("size", [50, 50])[1])
	}
	
	var building = BuildingEntity.new()
	building.setup(b_id, visual_data)
	building.position = pos - (building.size / 2.0)
	
	building.mouse_entered.connect(func():
		var b_name = b_data.get("name", "Bâtiment")
		var text = "[b]" + b_name + "[/b]\n[color=#aaaaaa]Cliquez pour interagir[/color]"
		if b_data.has("production") and b_data["production"].size() > 0:
			text += "\nProduit " + str(b_data["production"].keys()[0]).replace("MAT_", "")
		
		TooltipManager.show_tooltip(text) # <-- Correction de la variable "text" non utilisée
	)
	building.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
	
	map_camera.add_child(building)

# ==========================================
# APPARITIONS ARBRES / ROCHERS ET GESTION DES COÛTS
# ==========================================

func setup_spawners() -> void:
	tree_timer = Timer.new()
	tree_timer.timeout.connect(_on_spawn_tick.bind("tree"))
	add_child(tree_timer)
	_start_random_timer(tree_timer, 2.0, 4.0)
	
	rock_timer = Timer.new()
	rock_timer.timeout.connect(_on_spawn_tick.bind("rock"))
	add_child(rock_timer)
	_start_random_timer(rock_timer, 5.0, 8.0)

func _start_random_timer(timer: Timer, min_time: float, max_time: float) -> void:
	timer.start(randf_range(min_time, max_time))

func _on_spawn_tick(type: String) -> void:
	var clickables_count = 0
	for child in map_camera.get_children():
		if child is Button: clickables_count += 1
		
	if clickables_count >= max_clickables_on_map:
		_restart_timer_for(type)
		return
		
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(40, 40)
	
	var res_id = ""
	var friendly_name = ""
	if type == "tree":
		btn.text = "🌲"
		res_id = "MAT_WOOD"
		friendly_name = "Arbre (Bois)"
	elif type == "rock":
		btn.text = "🪨"
		res_id = "MAT_STONE"
		friendly_name = "Rocher (Pierre)"
		
	call_deferred("_place_clickable_on_map", btn, res_id, friendly_name)
	_restart_timer_for(type)

func _restart_timer_for(type: String) -> void:
	if type == "tree": _start_random_timer(tree_timer, 2.0, 4.0)
	elif type == "rock": _start_random_timer(rock_timer, 5.0, 8.0)

func _place_clickable_on_map(btn: Button, res_id: String, friendly_name: String) -> void:
	var view_size = city_map.size / map_camera.scale
	var offset = -map_camera.position / map_camera.scale
	
	var random_x = randf_range(offset.x + 50, offset.x + view_size.x - 50)
	var random_y = randf_range(offset.y + 50, offset.y + view_size.y - 50)
	
	btn.position = Vector2(random_x, random_y)
	btn.pressed.connect(func():
		EconomyManager.add_resource(res_id, 1.0)
		TooltipManager.hide_tooltip()
		btn.queue_free() 
	)
	
	btn.mouse_entered.connect(func(): TooltipManager.show_tooltip("[b]" + friendly_name + "[/b]\n[color=#55ffff]Cliquer pour récolter +1[/color]"))
	btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
	
	map_camera.add_child(btn)
	
	
func update_ui() -> void:
	# C'EST CETTE LIGNE QU'IL FAUT CHANGER :
	var net_prod = EconomyManager.get_net_production()
	
	for res_id in resource_labels.keys():
		var amount = EconomyManager.get_resource(res_id)
		var prod_sec = net_prod.get(res_id, 0.0)
		
		# Texte de base (ex: "Bois : 472")
		var text = resource_names.get(res_id, res_id) + " : " + Utils.format_number(amount)
		
		# Ajout de la production par seconde si elle n'est pas nulle
		if prod_sec > 0:
			text += " (+%s/s)" % Utils.format_number(prod_sec)
		elif prod_sec < 0:
			text += " (%s/s)" % Utils.format_number(prod_sec) # Le format_number gardera le signe moins
			
		resource_labels[res_id].text = text

	for b_id in EconomyManager.buildings_data.keys():
		var b_data = EconomyManager.buildings_data[b_id]
		var btn = building_buttons[b_id]
		var current_cost = calculate_current_cost(b_data)
		
		if not EconomyManager.can_afford(current_cost):
			btn.modulate = Color(1, 1, 1, 0.5)
			if btn.button_pressed:
				btn.button_pressed = false
				_select_building_tool(b_id, btn)
		else:
			btn.modulate = Color(1, 1, 1, 1.0)

func calculate_current_cost(b_data: Dictionary) -> Dictionary:
	var actual_cost = {}
	var owned_count = b_data.get("owned", 0)
	var cost_mult = b_data.get("cost_mult", 1.15)
	var multiplier = pow(cost_mult, owned_count)
	
	if b_data.has("base_cost"):
		for res_id in b_data["base_cost"].keys():
			actual_cost[res_id] = float(b_data["base_cost"][res_id] * multiplier) * b_data.get("cost_discount", 1.0)
			
	return actual_cost
