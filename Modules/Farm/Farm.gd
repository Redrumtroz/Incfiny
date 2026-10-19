extends ModuleBase

# ==========================================
# INTERFACE DE LA FERME (Visuel uniquement)
# ==========================================

# ATTENTION : N'utilise jamais _ready() ici, sinon tu casses le bouton de retour !
func _module_ready() -> void:
	# On lit les données du Cerveau pour s'afficher
	print("La ferme s'ouvre ! Nombre de cases à dessiner : ", FarmManager.farm_grid.size())
