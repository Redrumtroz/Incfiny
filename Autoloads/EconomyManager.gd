extends Node

var inventory : Dictionary = {}
var buildings_data : Dictionary = {}
var economy_timer : Timer

func _ready() -> void:
	load_inventory_data()
	load_buildings_data()
	
	# Création du "Moteur" qui tourne toutes les secondes
	economy_timer = Timer.new()
	economy_timer.wait_time = 1.0
	economy_timer.autostart = true
	economy_timer.timeout.connect(_on_economy_tick)
	add_child(economy_timer)

# --- CHARGEMENT DES BASES DE DONNÉES JSON ---
func load_inventory_data() -> void:
	var file = FileAccess.open("res://Data/inventory.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			inventory = json.data
		file.close()
	else:
		inventory = {"RES_GOLD": 0.0, "MAT_WOOD": 1000.0, "MAT_STONE": 100.0}

func load_buildings_data() -> void:
	var file = FileAccess.open("res://Data/buildings.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			buildings_data = json.data
		file.close()

# --- LOGIQUE ÉCONOMIQUE ---

# Calcule la production globale de tous les bâtiments
func get_net_production() -> Dictionary:
	var prod = {}
	for b_id in buildings_data.keys():
		var b_data = buildings_data[b_id]
		var owned = b_data.get("owned", 0)
		
		if owned > 0:
			if b_data.has("production"):
				for res_id in b_data["production"].keys():
					prod[res_id] = prod.get(res_id, 0.0) + (float(b_data["production"][res_id]) * owned)
			if b_data.has("consumption"):
				for res_id in b_data["consumption"].keys():
					prod[res_id] = prod.get(res_id, 0.0) - (float(b_data["consumption"][res_id]) * owned)
	return prod

# S'exécute automatiquement toutes les secondes
func _on_economy_tick() -> void:
	var net_prod = get_net_production()
	var updated = false
	
	for res_id in net_prod.keys():
		var amount = net_prod[res_id]
		if amount != 0:
			add_resource(res_id, amount)
			updated = true
			
	# Si les ressources ont bougé, on prévient l'interface de se mettre à jour
	if updated:
		SignalBus.resources_updated.emit()

func add_resource(res_id: String, amount: float) -> void:
	if inventory.has(res_id):
		inventory[res_id] += amount
	else:
		inventory[res_id] = amount
		
	# Sécurité : on empêche une ressource de devenir négative
	if inventory[res_id] < 0:
		inventory[res_id] = 0.0
		
	if amount > 0:
		SignalBus.resource_gained.emit(res_id, amount)
	elif amount < 0:
		SignalBus.resource_spent.emit(res_id, abs(amount))
		
	# --- LA LIGNE MAGIQUE EST ICI ---
	# On force l'UI à se rafraîchir à chaque modification de l'inventaire
	SignalBus.resources_updated.emit()

func get_resource(res_id: String) -> float:
	return float(inventory.get(res_id, 0.0))

func can_afford(cost_dict: Dictionary) -> bool:
	for res_id in cost_dict.keys():
		if get_resource(res_id) < float(cost_dict[res_id]):
			return false
	return true
