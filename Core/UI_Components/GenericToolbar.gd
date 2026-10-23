extends PanelContainer
class_name GenericToolbar

signal tool_selected(tool_id: String)

# On va chercher le HBoxContainer qu'on a créé dans l'éditeur !
@onready var button_container = $MarginContainer/ScrollContainer/HBoxContainer

var buttons: Dictionary = {}

func add_tool(tool_id: String, tool_name: String, icon_text: String = "", custom_size: Vector2 = Vector2(60, 60)) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = custom_size
	btn.text = icon_text
	
	btn.pressed.connect(func():
		_on_button_pressed(tool_id)
	)
	
	button_container.add_child(btn)
	buttons[tool_id] = btn
	return btn

func _on_button_pressed(t_id: String) -> void:
	for b_id in buttons.keys():
		buttons[b_id].button_pressed = (b_id == t_id)
	tool_selected.emit(t_id)

func get_tool(tool_id: String) -> Button:
	return buttons.get(tool_id, null)

func deselect_all() -> void:
	for b in buttons.values():
		b.button_pressed = false
	tool_selected.emit("")
