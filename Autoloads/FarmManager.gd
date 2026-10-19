extends Node

# ==========================================
# LE CERVEAU DE LA FERME (Données uniquement)
# ==========================================

# Notre fameuse grille 7x7. 
# On utilise un dictionnaire où la clé est une coordonnée (Vector2) 
# et la valeur est l'état de la case.
var farm_grid : Dictionary = {}

func _ready() -> void:
	_initialize_grid()

func _initialize_grid() -> void:
	# On crée une grille vide de 7 par 7
	for x in range(7):
		for y in range(7):
			var pos = Vector2(x, y)
			farm_grid[pos] = {
				"seed_id": "NONE", # Ce qu'il y a de planté (ex: "FARM_WHEAT")
				"time_planted": 0, # Quand ça a été planté
				"is_ready": false  # Si c'est prêt à récolter
			}
