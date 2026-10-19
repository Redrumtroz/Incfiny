extends Node
class_name CityUI

signal building_tool_selected(b_id: String)
signal toggle_resource_panel_requested()

var resource_labels = {}
var building_buttons = {}
var stat_pop_label : Label
var stat_bld_label : Label

var resource_names = {
	"RES_GOLD": "Or", "MAT_WOOD": "Bois", "MAT_STONE": "Pierre", 
	"MAT_WATER": "Eau", "MAT_PLANK": "Planches", "MAT_CEMENT": "Ciment"
}

func setup(top_menu: Control, res_list: Control, map_node: Control, b_scroll: Control, b_list: Control) -> void:
	_setup_stats_overlay(map_node)
	_setup_top_bar(top_menu)
	_generate_resource_ui(res_list)
	_generate_build_menu(b_scroll, b_list)

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

func _setup_top_bar(top_menu: Control) -> void:
	var btn_toggle_res = Button.new()
	btn_toggle_res.text = "📦 Ressources"
	btn_toggle_res.pressed.connect(func(): toggle_resource_panel_requested.emit())
	top_menu.add_child(btn_toggle_res)
	
	top_menu.add_child(VSeparator.new())
	
	var modules = {"🚜 Aller à la Ferme": "res://Modules/Farm/Farm.tscn"}
	for mod_name in modules.keys():
		var btn = Button.new()
		btn.text = mod_name
		btn.pressed.connect(func(): ScreenManager.open_module(modules[mod_name]))
		top_menu.add_child(btn)

func _generate_resource_ui(res_list: Control) -> void:
	for res_id in EconomyManager.inventory.keys():
		var lbl = Label.new()
		lbl.mouse_filter = Control.MOUSE_FILTER_STOP
		lbl.mouse_entered.connect(func(): TooltipManager.show_tooltip("[b]" + resource_names.get(res_id, res_id) + "[/b]\nRessource globale."))
		lbl.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
		res_list.add_child(lbl)
		resource_labels[res_id] = lbl

func _generate_build_menu(b_scroll: Control, b_list: Control) -> void:
	b_scroll.custom_minimum_size.y = 120 
	
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
		
		btn.pressed.connect(func(): 
			_select_building_tool(b_id, btn)
			building_tool_selected.emit(b_id if btn.button_pressed else "")
		)
		btn.mouse_entered.connect(func(): show_build_tooltip(b_id))
		btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
		
		b_list.add_child(btn)
		building_buttons[b_id] = btn

func _select_building_tool(_b_id: String, active_btn: Button) -> void:
	for key in building_buttons:
		if building_buttons[key] != active_btn:
			building_buttons[key].button_pressed = false

func show_build_tooltip(b_id: String) -> void:
	var b_data = EconomyManager.buildings_data[b_id]
	var current_cost = calculate_current_cost(b_data)
	
	var text = "[b]" + b_data.get("name", "Bâtiment") + "[/b] (Possédés: " + str(b_data.get("owned", 0)) + ")\n"
	text += "[color=#aaaaaa]" + b_data.get("description", "Un bâtiment utile.") + "[/color]\n\n"
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
		var b_data = EconomyManager.buildings_data[b_id]
		var btn = building_buttons[b_id]
		var current_cost = calculate_current_cost(b_data)
		
		if not EconomyManager.can_afford(current_cost):
			btn.modulate = Color(1, 1, 1, 0.5)
			if btn.button_pressed:
				btn.button_pressed = false
				building_tool_selected.emit("")
		else:
			btn.modulate = Color(1, 1, 1, 1.0)

func calculate_current_cost(b_data: Dictionary) -> Dictionary:
	var actual_cost = {}
	var multiplier = pow(b_data.get("cost_mult", 1.15), b_data.get("owned", 0))
	if b_data.has("base_cost"):
		for res_id in b_data["base_cost"].keys():
			actual_cost[res_id] = float(b_data["base_cost"][res_id] * multiplier) * b_data.get("cost_discount", 1.0)
	return actual_cost
