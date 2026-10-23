extends Node
class_name CityUI

signal building_tool_selected(b_id: String)

var resource_labels = {}
var stat_pop_label : Label
var stat_bld_label : Label
var toolbar: GenericToolbar
var popup: GenericPopUp
var is_initialized: bool = false

var resource_names = {
	"RES_GOLD": "Or", "MAT_WOOD": "Bois", "MAT_STONE": "Pierre", 
	"MAT_WATER": "Eau", "FARM_WHEAT": "Blé", "RES_SECURITY":"Sécurité", "RES_HAPPINESS":"Bonheur"
}

func setup(main_toolbar: GenericToolbar, main_popup: GenericPopUp, res_list: Control, pop_lbl: Label, bld_lbl: Label) -> void:
	toolbar = main_toolbar
	popup = main_popup
	stat_pop_label = pop_lbl
	stat_bld_label = bld_lbl
	
	if not is_initialized:
		_generate_resource_ui(res_list)
		
		# Connexion vitale : on écoute les changements de ressources
		if not SignalBus.resources_updated.is_connected(_update_resource_labels):
			SignalBus.resources_updated.connect(_update_resource_labels)
			
		is_initialized = true
	
	# On force l'affichage correct au chargement du module
	_update_resource_labels()
	
	if not toolbar.tool_selected.is_connected(_on_tool_selected):
		toolbar.tool_selected.connect(_on_tool_selected)
		
	_generate_build_menu()

func _generate_resource_ui(res_list: Control) -> void:
	for child in res_list.get_children():
		child.queue_free()
		
	for res_id in EconomyManager.inventory.keys():
		var lbl = Label.new()
		res_list.add_child(lbl)
		resource_labels[res_id] = lbl

func _update_resource_labels() -> void:
	for res_id in resource_labels.keys():
		if resource_labels.has(res_id) and is_instance_valid(resource_labels[res_id]):
			var friendly_name = resource_names.get(res_id, res_id)
			var amount = EconomyManager.get_resource(res_id)
			# Formatage propre (ex: "Bois : 1000")
			resource_labels[res_id].text = friendly_name + " : " + str(snapped(amount, 0.1))

func _generate_build_menu() -> void:
	toolbar.deselect_all()
	for b_id in EconomyManager.buildings_data.keys():
		var b_data = EconomyManager.buildings_data[b_id]
		var icon = b_data.get("ui", {}).get("icon", "🏗️")
		
		# On récupère le bouton créé par la toolbar
		var btn = toolbar.add_tool(b_id, b_data.get("name", b_id), icon)
		
		# --- CONSTRUCTION DU TEXTE DU TOOLTIP ---
		var tooltip_text = "[b]" + b_data.get("name", b_id) + "[/b]\n"
		tooltip_text += "[color=#aaaaaa]" + b_data.get("description", "") + "[/color]\n\n"
		
		if b_data.has("base_cost"):
			tooltip_text += "[color=#ff6666]Coût :[/color]\n"
			for res in b_data["base_cost"].keys():
				tooltip_text += "- " + resource_names.get(res, res) + " : " + str(b_data["base_cost"][res]) + "\n"
				
		if b_data.has("production"):
			tooltip_text += "\n[color=#66ff66]Production (/s) :[/color]\n"
			for res in b_data["production"].keys():
				tooltip_text += "+ " + resource_names.get(res, res) + " : " + str(b_data["production"][res]) + "\n"
		
		# --- CONNEXION DES SIGNAUX ---
		btn.mouse_entered.connect(func(): TooltipManager.show_tooltip(tooltip_text))
		btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())

func _on_tool_selected(tool_id: String) -> void:
	building_tool_selected.emit(tool_id)
