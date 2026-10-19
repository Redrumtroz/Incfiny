extends Control
class_name BuildingEntity

# ==========================================
# CLASSE DE BASE POUR TOUS LES BÂTIMENTS SUR LA CARTE
# ==========================================

var building_id: String = ""
var visual_data: Dictionary = {}

var bg_rect: ColorRect
var shadow: ColorRect
var icon_label: Label

func setup(b_id: String, v_data: Dictionary) -> void:
	building_id = b_id
	visual_data = v_data
	
	size = visual_data.get("size", Vector2(60, 60))
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	_create_visuals()
	gui_input.connect(_on_gui_input)

func _create_visuals() -> void:
	shadow = ColorRect.new()
	shadow.color = Color(0, 0, 0, 0.3)
	shadow.size = size
	shadow.position = Vector2(0, 10)
	shadow.show_behind_parent = true
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shadow)
	
	bg_rect = ColorRect.new()
	bg_rect.color = visual_data.get("color", Color.GRAY)
	bg_rect.size = size
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg_rect)
	
	icon_label = Label.new()
	icon_label.text = visual_data.get("icon", "🏢")
	icon_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon_label.add_theme_font_size_override("font_size", int(size.y * 0.5))
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_label)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_on_clicked()
			accept_event()

func _on_clicked() -> void:
	# DÉTECTEUR D'ERREUR
	if building_id == "":
		print("⚠️ ERREUR : Le script BuildingEntity est attaché au nœud [", name, "] mais la fonction setup() n'a pas été appelée !")
		return
		
	var b_data = EconomyManager.buildings_data.get(building_id, {})
	var b_name = b_data.get("name", "Bâtiment inconnu")
	
	print("Bâtiment cliqué : ", b_name)
	
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)
