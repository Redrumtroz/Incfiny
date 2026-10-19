extends Control
class_name ModuleBase

# ==========================================
# SCRIPT DE BASE POUR TOUS LES MODULES
# ==========================================

func _ready() -> void:
	setup_generic_module_ui()
	_module_ready()

func setup_generic_module_ui() -> void:
	var btn_back = Button.new()
	btn_back.text = "🏠 Retour à la Ville"
	btn_back.custom_minimum_size = Vector2(200, 50)
	
	btn_back.pressed.connect(func(): ScreenManager.return_to_hub(self))
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_left", 20)
	margin.z_index = 100 
	
	margin.add_child(btn_back)
	add_child(margin)

# ==========================================
# FONCTIONS VIRTUELLES (À utiliser dans les sous-scripts)
# ==========================================

# Appelée une seule fois à la création de la scène
func _module_ready() -> void:
	pass

# Appelée AUTOMATIQUEMENT par le ScreenManager quand on affiche l'onglet
func on_module_opened() -> void:
	pass

# Appelée AUTOMATIQUEMENT par le ScreenManager quand on cache l'onglet
func on_module_closed() -> void:
	pass
