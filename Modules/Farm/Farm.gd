extends Panel

@onready var farm_map = $FarmMap
@onready var map_content = $FarmMap/MapContent

var camera_ctrl: CameraController
var ui: FarmUI
var selected_tool: String = ""

func _ready() -> void:
	camera_ctrl = CameraController.new()
	camera_ctrl.min_zoom = 0.8
	camera_ctrl.max_zoom = 4.0
	add_child(camera_ctrl)
	camera_ctrl.setup(farm_map, map_content)
	camera_ctrl.map_clicked.connect(_on_map_clicked)

	ui = FarmUI.new()
	add_child(ui)
	ui.tool_selected.connect(func(t_id): selected_tool = t_id)
	ui.crop_harvested.connect(_on_crop_harvested)

# --- APPELÉ PAR MAIN.GD ---
func setup_module_ui(main_toolbar: GenericToolbar, main_popup: GenericPopUp) -> void:
	ui.setup(main_toolbar, main_popup)

func _on_map_clicked(local_pos: Vector2) -> void:
	if selected_tool == "seed_wheat":
		if EconomyManager.get_resource("MAT_WOOD") >= 1.0:
			EconomyManager.add_resource("MAT_WOOD", -1.0)
			_plant_crop(local_pos)
		else:
			TooltipManager.show_tooltip("[color=#ff0000]Pas assez de bois ![/color]")

func _plant_crop(pos: Vector2) -> void:
	var crop = BuildingEntity.new() 
	crop.setup("crop_wheat", {"color": Color("#e5c158"), "icon": "🌾", "size": Vector2(40, 40)})
	crop.position = pos - (crop.size / 2.0)
	
	crop.mouse_entered.connect(func(): TooltipManager.show_tooltip("[b]Plant de Blé[/b]\n[color=#55ffff]Cliquez pour récolter[/color]"))
	crop.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
	
	crop.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected_tool == "": 
				crop.accept_event()
				ui.open_crop_popup(crop)
	)
	map_content.add_child(crop)

func _on_crop_harvested(crop_node: Control) -> void:
	EconomyManager.add_resource("FARM_WHEAT", 5.0)
	crop_node.queue_free()
