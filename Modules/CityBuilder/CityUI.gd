extends Node
class_name CityUI

# --- LES SIGNAUX MANQUANTS SONT LÀ ---
signal building_tool_selected(b_id: String)
signal toggle_resource_panel_requested()
signal building_destroyed(b_id: String, building_node: Control)

# --- TES VARIABLES ---
var resource_labels = {}
var stat_pop_label : Label
var stat_bld_label : Label

var popup: GenericPopUp
var toolbar: GenericToolbar

var is_initialized: bool = false

var resource_names = {
	"RES_GOLD": "Or", "MAT_WOOD": "Bois", "MAT_STONE": "Pierre", 
	"MAT_WATER": "Eau", "MAT_PLANK": "Planches", "MAT_CEMENT": "Ciment"
}

func setup(main_toolbar: GenericToolbar, main_popup: GenericPopUp, res_list: Control, map_node: Control) -> void:
	toolbar = main_toolbar
	popup = main_popup
	
	# 1. CRÉATION LOCALE (Une seule fois !)
	if not is_initialized:
		_setup_stats_overlay(map_node)
		_generate_resource_ui(res_list)
		is_initialized = true
	
	# 2. ABONNEMENT AU SIGNAL (Sécurisé)
	if not toolbar.tool_selected.is_connected(_on_tool_selected):
		toolbar.tool_selected.connect(_on_tool_selected)
		
	# 3. RECONSTRUCTION DES OUTILS (À chaque fois qu'on ouvre la ville)
	_generate_build_menu()

func _on_tool_selected(t_id: String) -> void:
	building_tool_selected.emit(t_id)

func _setup_stats_overlay(map_node: Control) -> void:
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
	map_node.add_child(stats_panel)

func _generate_resource_ui(res_list: Control) -> void:
	for res_id in EconomyManager.inventory.keys():
		var lbl = Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.mouse_entered.connect(func(): TooltipManager.show_tooltip("[b]" + resource_names.get(res_id, res_id) + "[/b]\nRessource globale."))
		lbl.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
		res_list.add_child(lbl)
		resource_labels[res_id] = lbl

func _generate_build_menu() -> void:
	for b_id in EconomyManager.buildings_data.keys():
		var b_data = EconomyManager.buildings_data[b_id]
		var ui_data = b_data.get("ui", {})
		
		var btn = toolbar.add_tool(b_id, b_data.get("name", "Bâtiment"), ui_data.get("icon", "🏗️"))
		btn.mouse_entered.connect(func(): show_build_tooltip(b_id))
		btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())

func show_build_tooltip(b_id: String) -> void:
	var b_data = EconomyManager.buildings_data[b_id]
	var current_cost = calculate_current_cost(b_data)
	var text = "[b]" + b_data.get("name", "Bâtiment") + "[/b] (Possédés: " + str(b_data.get("owned", 0)) + ")\n"
	text += "[color=#aaaaaa]" + b_data.get("description", "Un bâtiment utile.") + "[/color]\n\nCoût :\n"
	for res_id in current_cost.keys():
		var color = "#ff5555" if EconomyManager.get_resource(res_id) < current_cost[res_id] else "#55ff55"
		text += "[color=" + color + "]- " + str(current_cost[res_id]) + " " + resource_names.get(res_id, res_id) + "[/color]\n"
	TooltipManager.show_tooltip(text)

func open_building_popup(b_id: String, building_node: Control) -> void:
	var b_data = EconomyManager.buildings_data[b_id]
	TooltipManager.hide_tooltip()
	popup.open("Gérer : " + b_data.get("name", "Bâtiment"))
	
	var btn_destroy = Button.new()
	btn_destroy.text = "Détruire (Irréversible)"
	btn_destroy.add_theme_color_override("font_color", Color("#ff5555"))
	btn_destroy.pressed.connect(func():
		building_destroyed.emit(b_id, building_node)
		popup.close()
	)
	popup.add_element(btn_destroy)

func update_ui(placed_buildings_count: int) -> void:
	stat_bld_label.text = str(placed_buildings_count)
	stat_pop_label.text = str(placed_buildings_count * 4)
	
	var net_prod = EconomyManager.get_net_production()
	for res_id in resource_labels.keys():
		var amount = EconomyManager.get_resource(res_id)
		var prod_sec = net_prod.get(res_id, 0.0)
		var text = resource_names.get(res_id, res_id) + " : " + Utils.format_number(amount)
		if prod_sec > 0: text += " (+%s/s)" % Utils.format_number(prod_sec)
		elif prod_sec < 0: text += " (%s/s)" % Utils.format_number(prod_sec)
		resource_labels[res_id].text = text

	for b_id in EconomyManager.buildings_data.keys():
		var btn = toolbar.get_tool(b_id)
		if not btn: continue
		var current_cost = calculate_current_cost(EconomyManager.buildings_data[b_id])
		if not EconomyManager.can_afford(current_cost):
			btn.modulate = Color(1, 1, 1, 0.5)
			if btn.button_pressed: toolbar.deselect_all()
		else:
			btn.modulate = Color(1, 1, 1, 1.0)

func calculate_current_cost(b_data: Dictionary) -> Dictionary:
	var actual_cost = {}
	var multiplier = pow(b_data.get("cost_mult", 1.15), b_data.get("owned", 0))
	if b_data.has("base_cost"):
		for res_id in b_data["base_cost"].keys():
			actual_cost[res_id] = float(b_data["base_cost"][res_id] * multiplier) * b_data.get("cost_discount", 1.0)
	return actual_cost
