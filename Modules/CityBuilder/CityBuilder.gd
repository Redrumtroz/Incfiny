extends Control

@onready var main_vbox = $MainVBox
@onready var left_panel = $MainVBox/WorkspaceSplit/LeftPanel
@onready var resource_list = $MainVBox/WorkspaceSplit/LeftPanel/ResourceList
@onready var city_map = $MainVBox/WorkspaceSplit/RightWorkspace/CityMap

var ui: CityUI
var camera_ctrl: CameraController
var spawner: ResourceSpawner
var map_content: Control

var selected_building_tool = ""
var placed_buildings_count = 0

func _ready() -> void:
	map_content = Control.new()
	map_content.set_anchors_preset(Control.PRESET_FULL_RECT)
	city_map.add_child(map_content)
	
	camera_ctrl = CameraController.new()
	add_child(camera_ctrl)
	camera_ctrl.setup(city_map, map_content)
	camera_ctrl.map_clicked.connect(_try_place_building)
	
	ui = CityUI.new()
	add_child(ui)
	ui.building_tool_selected.connect(func(b_id):
		selected_building_tool = b_id
		city_map.mouse_default_cursor_shape = Control.CURSOR_CROSS if b_id != "" else Control.CURSOR_ARROW
	)
	ui.building_destroyed.connect(_on_building_destroyed)
	
	spawner = ResourceSpawner.new()
	add_child(spawner)
	spawner.setup(city_map, map_content)
	
	SignalBus.resources_updated.connect(_on_resources_updated)

# --- APPELÉ PAR MAIN.GD ---
func setup_module_ui(main_toolbar: GenericToolbar, main_popup: GenericPopUp) -> void:
	ui.setup(main_toolbar, main_popup, resource_list, city_map)
	_on_resources_updated()

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
	
	var building = BuildingEntity.new()
	building.setup(b_id, {"color": Color(ui_data.get("color", "#888888")), "icon": ui_data.get("icon", "🏢"), "size": Vector2(ui_data.get("size", [50, 50])[0], ui_data.get("size", [50, 50])[1])})
	building.position = pos - (building.size / 2.0)
	
	building.mouse_entered.connect(func(): TooltipManager.show_tooltip("[b]" + b_data.get("name", "Bâtiment") + "[/b]\n[color=#aaaaaa]Cliquez pour interagir[/color]"))
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
	EconomyManager.buildings_data[b_id]["owned"] = max(0, EconomyManager.buildings_data[b_id].get("owned", 1) - 1)
	placed_buildings_count -= 1
	_on_resources_updated()
