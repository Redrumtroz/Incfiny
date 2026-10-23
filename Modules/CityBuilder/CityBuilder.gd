extends Control

@onready var ui = $CityUI
@onready var organic_map = $MainVBox/WorkspaceSplit/RightWorkspace/CityMap
@onready var resource_list = $MainVBox/WorkspaceSplit/LeftPanel/ResourceList
@onready var pop_label = $MainVBox/WorkspaceSplit/RightWorkspace/StatsPanel/PopLabel
@onready var bld_label = $MainVBox/WorkspaceSplit/RightWorkspace/StatsPanel/BldLabel

# 1. Assure-toi que cette variable est bien déclarée ici
var global_popup: GenericPopUp 

func setup_module_ui(main_toolbar: GenericToolbar, main_popup: GenericPopUp) -> void:
	# 2. Assure-toi que la variable est bien assignée au démarrage
	global_popup = main_popup 
	
	if ui.has_method("setup"):
		ui.setup(main_toolbar, main_popup, resource_list, pop_label, bld_label)
		
	if not ui.building_tool_selected.is_connected(_on_building_tool_selected):
		ui.building_tool_selected.connect(_on_building_tool_selected)
		
	if not organic_map.building_clicked.is_connected(_on_map_building_clicked):
		organic_map.building_clicked.connect(_on_map_building_clicked)

func _on_building_tool_selected(b_id: String) -> void:
	organic_map.current_tool_id = b_id

func _on_map_building_clicked(b_id: String, influence: String) -> void:
	var b_data = EconomyManager.buildings_data.get(b_id, {})
	var b_name = b_data.get("name", "Bâtiment inconnu")
	var b_desc = b_data.get("description", "")
	
	var content = b_desc + "\n\n[color=#aaaaaa]Type de quartier :[/color] " + influence.capitalize()
	
	var rich_text = RichTextLabel.new()
	rich_text.bbcode_enabled = true
	rich_text.text = content
	rich_text.fit_content = true
	rich_text.custom_minimum_size = Vector2(260, 0)
	
	# 3. La vérification de sécurité qui empêche le plantage
	if is_instance_valid(global_popup):
		global_popup.clear_content()
		global_popup.add_element(rich_text)
		global_popup.open(b_name)
	else:
		print("Erreur : Le PopUp n'a pas été trouvé. Clic sur : ", b_name)
