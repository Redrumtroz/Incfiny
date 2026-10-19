extends PanelContainer
class_name GenericToolbar

signal tool_selected(tool_id: String)

var button_container: BoxContainer
var buttons: Dictionary = {}
var button_group: ButtonGroup

func setup(config: Dictionary) -> void:
	# Options paramétrables avec des valeurs par défaut
	var placement = config.get("placement", "bottom") # "bottom", "top", "left", "right"
	var bg_color = config.get("bg_color", Color(0.15, 0.16, 0.18, 0.90))
	var padding = config.get("padding", 10)
	var spacing = config.get("spacing", 10)
	var scroll_size = config.get("scroll_size", 600)
	
	# Style visuel (fond transparent et coins arrondis)
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(10)
	add_theme_stylebox_override("panel", style)
	
	# Gestion dynamique du placement
	match placement:
		"bottom":
			set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
			position.y -= 20
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical = Control.GROW_DIRECTION_BEGIN
		"top":
			set_anchors_preset(Control.PRESET_CENTER_TOP)
			position.y += 20
			grow_horizontal = Control.GROW_DIRECTION_BOTH
			grow_vertical = Control.GROW_DIRECTION_END
		"left":
			set_anchors_preset(Control.PRESET_CENTER_LEFT)
			position.x += 20
			grow_horizontal = Control.GROW_DIRECTION_END
			grow_vertical = Control.GROW_DIRECTION_BOTH
		"right":
			set_anchors_preset(Control.PRESET_CENTER_RIGHT)
			position.x -= 20
			grow_horizontal = Control.GROW_DIRECTION_BEGIN
			grow_vertical = Control.GROW_DIRECTION_BOTH

	# Marges internes
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", padding)
	margin.add_theme_constant_override("margin_right", padding)
	margin.add_theme_constant_override("margin_top", padding)
	margin.add_theme_constant_override("margin_bottom", padding)
	add_child(margin)
	
	# Conteneur défilant
	var scroll = ScrollContainer.new()
	if placement in ["bottom", "top"]:
		scroll.custom_minimum_size = Vector2(scroll_size, 120)
		scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		button_container = HBoxContainer.new()
	else:
		scroll.custom_minimum_size = Vector2(120, scroll_size)
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		button_container = VBoxContainer.new()
		
	button_container.add_theme_constant_override("separation", spacing)
	scroll.add_child(button_container)
	margin.add_child(scroll)
	
	# Groupe de boutons pour forcer la sélection unique
	button_group = ButtonGroup.new()
	button_group.allow_unpress = true

# Permet aux modules d'ajouter leurs propres boutons
func add_tool(id: String, text: String, icon_text: String, size: Vector2 = Vector2(100, 100)) -> Button:
	var btn = Button.new()
	btn.custom_minimum_size = size
	btn.toggle_mode = true
	btn.button_group = button_group
	
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var icon_lbl = Label.new()
	icon_lbl.text = icon_text
	icon_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_lbl.add_theme_font_size_override("font_size", 32)
	
	var name_lbl = Label.new()
	name_lbl.text = text
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 12)
	
	vbox.add_child(icon_lbl)
	vbox.add_child(name_lbl)
	btn.add_child(vbox)
	
	btn.pressed.connect(func():
		tool_selected.emit(id if btn.button_pressed else "")
	)
	
	button_container.add_child(btn)
	buttons[id] = btn
	return btn

func get_tool(id: String) -> Button:
	return buttons.get(id, null)

func deselect_all() -> void:
	var pressed_btn = button_group.get_pressed_button()
	if pressed_btn:
		pressed_btn.button_pressed = false
		tool_selected.emit("")
