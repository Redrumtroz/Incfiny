extends CanvasLayer

# ==========================================
# GESTIONNAIRE GLOBAL D'INFOBULLES (TOOLTIPS)
# ==========================================

var panel : PanelContainer
var label : RichTextLabel

func _ready() -> void:
	# On s'assure que le Tooltip est TOUJOURS au-dessus du reste (même des autres menus)
	layer = 128
	
	panel = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.hide()
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.95)
	
	# CORRECTION : Utilisation des "setters" spécifiques de Godot 4
	style.set_border_width_all(2)
	style.border_color = Color(0.3, 0.3, 0.3)
	style.set_corner_radius_all(6)
	
	panel.add_theme_stylebox_override("panel", style)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	label = RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	margin.add_child(label)
	panel.add_child(margin)
	add_child(panel)

func _input(event: InputEvent) -> void:
	# L'infobulle suit la souris à l'échelle globale de l'écran
	if event is InputEventMouseMotion and panel.visible:
		# CORRECTION : On renomme en "mouse_offset" pour ne pas écraser la variable native "offset"
		var mouse_offset = Vector2(15, 15)
		var target_pos = event.global_position + mouse_offset
		
		# On évite que l'infobulle ne sorte de l'écran
		var screen_size = get_viewport().get_visible_rect().size
		if target_pos.x + panel.size.x > screen_size.x:
			target_pos.x = screen_size.x - panel.size.x
		if target_pos.y + panel.size.y > screen_size.y:
			target_pos.y = screen_size.y - panel.size.y
			
		panel.position = target_pos

func show_tooltip(bbcode_text: String) -> void:
	label.text = bbcode_text
	panel.show()
	panel.reset_size() # Force l'ajustement immédiat de la boîte noire

func hide_tooltip() -> void:
	panel.hide()
