extends Control

# ==========================================
# ÉCRAN TITRE ET MENU DE PRESTIGE
# ==========================================

func _ready() -> void:
	# On va créer une interface très simple pour commencer
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER) # On centre au milieu de l'écran
	
	var title = Label.new()
	title.text = "=== INCFINY ==="
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	
	var btn_new_run = Button.new()
	btn_new_run.text = "Démarrer une nouvelle boucle"
	btn_new_run.custom_minimum_size = Vector2(300, 60)
	
	var btn_prestige = Button.new()
	btn_prestige.text = "Arbre des Destinées (Prestige)"
	btn_prestige.custom_minimum_size = Vector2(300, 60)
	
	# Action du bouton Démarrer : On quitte le Menu et on charge la Ville !
	btn_new_run.pressed.connect(_on_start_game)
	
	vbox.add_child(title)
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)
	
	vbox.add_child(btn_new_run)
	vbox.add_child(btn_prestige)
	
	add_child(vbox)

func _on_start_game() -> void:
	# On utilise la fonction classique de Godot car on détruit le menu principal 
	# pour lancer la boucle de jeu principale.
	get_tree().change_scene_to_file("res://Modules/CityBuilder/CityBuilder.tscn")
