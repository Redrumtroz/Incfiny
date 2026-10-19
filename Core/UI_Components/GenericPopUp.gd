extends Control
class_name GenericPopUp

var window_panel : PanelContainer
var title_label : Label
var content_vbox : VBoxContainer

func _init() -> void:
	# 1. Le fond sombre qui prend tout l'écran
	set_anchors_preset(Control.PRESET_FULL_RECT)
	z_index = 100 # S'assure que le popup est au-dessus de tout le reste
	hide() # Caché par défaut
	
	var overlay_bg = ColorRect.new()
	overlay_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay_bg.color = Color(0, 0, 0, 0.6) # Noir à 60% d'opacité
	# Bloque les clics pour ne pas jouer en arrière-plan
	overlay_bg.mouse_filter = Control.MOUSE_FILTER_STOP 
	add_child(overlay_bg)
	
	# Fermer le popup si on clique dans le vide (sur le fond noir)
	overlay_bg.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			close()
	)

	# 2. La fenêtre principale au centre
	window_panel = PanelContainer.new()
	window_panel.set_anchors_preset(Control.PRESET_CENTER)
	window_panel.custom_minimum_size = Vector2(300, 150)
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#222426")
	style.set_corner_radius_all(10)
	style.set_border_width_all(2)
	style.border_color = Color("#444648")
	window_panel.add_theme_stylebox_override("panel", style)
	add_child(window_panel)

	# 3. Les marges internes
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	window_panel.add_child(margin)

	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 15)
	margin.add_child(main_vbox)

	# 4. L'En-tête (Titre + Bouton Fermer)
	var header_hbox = HBoxContainer.new()
	main_vbox.add_child(header_hbox)

	title_label = Label.new()
	title_label.text = "Titre du PopUp"
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_label.add_theme_font_size_override("font_size", 18)
	header_hbox.add_child(title_label)

	var close_btn = Button.new()
	close_btn.text = "  X  "
	close_btn.pressed.connect(close)
	header_hbox.add_child(close_btn)

	main_vbox.add_child(HSeparator.new())

	# 5. Le conteneur vide où les modules injecteront leur contenu
	content_vbox = VBoxContainer.new()
	content_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_vbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(content_vbox)

# --- FONCTIONS UTILITAIRES POUR LES MODULES ---

func open(title: String) -> void:
	title_label.text = title
	show()

func close() -> void:
	hide()
	clear_content() # Nettoie le popup quand on le ferme

func clear_content() -> void:
	for child in content_vbox.get_children():
		child.queue_free()

func add_element(node: Control) -> void:
	content_vbox.add_child(node)
