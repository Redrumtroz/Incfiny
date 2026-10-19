extends Control

@onready var main_vbox = $MainVBox
@onready var top_menu_bar = $MainVBox/TopMenuBar
@onready var left_panel = $MainVBox/WorkspaceSplit/LeftPanel
@onready var resource_list = $MainVBox/WorkspaceSplit/LeftPanel/ResourceList
@onready var city_map = $MainVBox/WorkspaceSplit/RightWorkspace/CityMap
@onready var build_menu_scroll = $MainVBox/WorkspaceSplit/RightWorkspace/BuildMenuScroll
@onready var build_list = $MainVBox/WorkspaceSplit/RightWorkspace/BuildMenuScroll/BuildList

var ui: CityUI
var camera_ctrl: CameraController
var spawner: ResourceSpawner

var map_content: Control
var selected_building_tool = ""
var placed_buildings_count = 0
var is_resource_panel_open = true

func _ready() -> void:
	ScreenManager.register_hub(self)
	
	# 1. CRÉATION DU CALQUE DE JEU
	map_content = Control.new()
	map_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	city_map.add_child(map_content)
	
	# 2. INITIALISATION DE LA CAMÉRA GÉNÉRIQUE
	camera_ctrl = CameraController.new()
	add_child(camera_ctrl)
	camera_ctrl.setup(city_map, map_content)
	camera_ctrl.map_clicked.connect(_try_place_building)
	
	# 3. INITIALISATION DE L'INTERFACE (UI)
	ui = CityUI.new()
	add_child(ui)
	ui.setup(top_menu_bar, resource_list, city_map, build_menu_scroll, build_list)
	
	ui.building_tool_selected.connect(func(b_id):
		selected_building_tool = b_id
		city_map.mouse_default_cursor_shape = Control.CURSOR_CROSS if b_id != "" else Control.CURSOR_ARROW
	)
	ui.toggle_resource_panel_requested.connect(func():
		is_resource_panel_open = !is_resource_panel_open
		left_panel.visible = is_resource_panel_open
	)
	ui.building_destroyed.connect(_on_building_destroyed)
	
	# 4. INITIALISATION DE L'APPARITION DES ARBRES
	spawner = ResourceSpawner.new()
	add_child(spawner)
	spawner.setup(city_map, map_content)
	
	# Branchement des signaux de l'économie
	SignalBus.resources_updated.connect(_on_resources_updated)
	_on_resources_updated()

func _process(_delta: float) -> void:
	pass

func _on_resources_updated() -> void:
	ui.update_ui(placed_buildings_count)

func _try_place_building(local_pos: Vector2) -> void:
	if selected_building_tool == "": return
	
	var current_tool = selected_building_tool 
	var b_data = EconomyManager.buildings_data[current_tool]
	var current_cost = ui.calculate_current_cost(b_data)
	
	if EconomyManager.can_afford(current_cost):
		for res_id in current_cost.keys():
			EconomyManager.add_resource(res_id, -current_cost[res_id])
		
		if not b_data.has("owned"): b_data["owned"] = 0
		b_data["owned"] += 1
		placed_buildings_count += 1
		
		_spawn_building_visual(current_tool, local_pos)
		
		_on_resources_updated()
		ui.show_build_tooltip(current_tool)

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
		var text = "[b]" + b_data.get("name", "Bâtiment") + "[/b]\n[color=#aaaaaa]Cliquez pour interagir[/color]"
		if b_data.has("production") and b_data["production"].size() > 0:
			text += "\nProduit " + str(b_data["production"].keys()[0]).replace("MAT_", "")
		TooltipManager.show_tooltip(text)
	)
	building.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
	
	building.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected_building_tool == "":
				building.accept_event()
				ui.open_building_popup(b_id, building)
	)
	
	map_content.add_child(building)

func _on_building_destroyed(b_id: String, building_node: Control) -> void:
	building_node.queue_free()
	var b_data = EconomyManager.buildings_data[b_id]
	b_data["owned"] = max(0, b_data.get("owned", 1) - 1)
	placed_buildings_count -= 1
	_on_resources_updated()
