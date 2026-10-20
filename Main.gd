extends Node

@onready var world_container = $WorldContainer
@onready var top_menu = $UILayer/TopMenu
@onready var toolbar = $UILayer/GenericToolbar
@onready var popup = $UILayer/GenericPopUp

var loaded_modules: Dictionary = {}
var current_module: Control = null

func _ready() -> void:
	# 1. SÉCURITÉ : Forcer le conteneur du monde à prendre tout l'écran
	world_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_container.size = get_viewport().get_visible_rect().size

	# 2. Setup de la toolbar générique
	toolbar.setup({
		"placement": "bottom",
		"bg_color": Color(0.15, 0.16, 0.18, 0.90),
		"padding": 10,
		"spacing": 10,
		"scroll_size": 600
	})
	
	_setup_top_menu()
	
	# Lancement du module par défaut
	open_module("res://Modules/CityBuilder/CityBuilder.tscn")

func _setup_top_menu() -> void:
	var modules = {
		"🏙️ Ville": "res://Modules/CityBuilder/CityBuilder.tscn",
		"🚜 Ferme": "res://Modules/Farm/Farm.tscn"
	}
	for mod_name in modules.keys():
		var btn = Button.new()
		btn.text = mod_name
		btn.pressed.connect(func(): open_module(modules[mod_name]))
		top_menu.add_child(btn)

func open_module(scene_path: String) -> void:
	if current_module != null:
		current_module.hide()

	_clear_toolbar()

	if loaded_modules.has(scene_path):
		current_module = loaded_modules[scene_path]
		current_module.show()
	else:
		var scene_resource = load(scene_path)
		if scene_resource:
			var instance = scene_resource.instantiate()
			
			# --- LE SECRET EST ICI : FORCER LA TAILLE DE LA SCÈNE ---
			if instance is Control:
				instance.set_anchors_preset(Control.PRESET_FULL_RECT)
				instance.size = world_container.size
				
			world_container.add_child(instance)
			loaded_modules[scene_path] = instance
			current_module = instance
		else:
			print("Erreur : Impossible de charger le module -> ", scene_path)
			return

	# On demande au module de remplir la toolbar
	if current_module.has_method("setup_module_ui"):
		current_module.setup_module_ui(toolbar, popup)

func _clear_toolbar() -> void:
	# Sécurité pour éviter les bugs si la toolbar est vide
	if toolbar and toolbar.button_container:
		for child in toolbar.button_container.get_children():
			child.queue_free()
		toolbar.buttons.clear()
