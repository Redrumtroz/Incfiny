extends Node
class_name FarmUI

signal tool_selected(t_id: String)
signal crop_harvested(crop_node: Control)

var toolbar: GenericToolbar
var popup: GenericPopUp

func setup(main_toolbar: GenericToolbar, main_popup: GenericPopUp) -> void:
	toolbar = main_toolbar
	popup = main_popup
	
	if not toolbar.tool_selected.is_connected(_on_tool_selected):
		toolbar.tool_selected.connect(_on_tool_selected)
	
	# Ajout de l'outil Graine
	var seed_btn = toolbar.add_tool("seed_wheat", "Blé", "🌾", Vector2(80, 80))
	seed_btn.mouse_entered.connect(func(): TooltipManager.show_tooltip("[b]Graine de Blé[/b]\n[color=#aaaaaa]Cliquez sur la terre pour planter.[/color]\nCoût : [color=#ff5555]-1 Bois[/color]"))
	seed_btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())

func _on_tool_selected(t_id: String) -> void:
	tool_selected.emit(t_id)

func open_crop_popup(crop_node: Control) -> void:
	TooltipManager.hide_tooltip()
	popup.open("Récolte : Blé")
	
	var info = Label.new()
	info.text = "Le blé a poussé et est prêt à être récolté !"
	popup.add_element(info)
	
	var btn_harvest = Button.new()
	btn_harvest.text = "Récolter (+5 Blé)"
	btn_harvest.add_theme_color_override("font_color", Color("#55ff55"))
	btn_harvest.pressed.connect(func():
		crop_harvested.emit(crop_node)
		popup.close()
	)
	popup.add_element(btn_harvest)
