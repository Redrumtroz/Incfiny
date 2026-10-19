extends Node

# ==========================================
# GESTIONNAIRE D'ÉCRANS (ONGLÉTS PERSISTANTS)
# ==========================================

var hub_node : Control = null
var loaded_modules : Dictionary = {}

func register_hub(node: Control) -> void:
	hub_node = node

func open_module(scene_path: String) -> void:
	if hub_node:
		hub_node.hide()
	
	if loaded_modules.has(scene_path):
		var mod = loaded_modules[scene_path]
		mod.show()
		# On prévient le module qu'il vient de s'ouvrir pour qu'il s'anime
		if mod.has_method("on_module_opened"):
			mod.on_module_opened()
	else:
		var new_module = load(scene_path).instantiate()
		add_child(new_module) 
		loaded_modules[scene_path] = new_module
		# On le prévient aussi la première fois
		if new_module.has_method("on_module_opened"):
			new_module.on_module_opened()

func return_to_hub(module_node: Control) -> void:
	module_node.hide()
	# On prévient le module qu'il est caché (pour qu'il détruise ses visuels lourds)
	if module_node.has_method("on_module_closed"):
		module_node.on_module_closed()
		
	if hub_node:
		hub_node.show()
