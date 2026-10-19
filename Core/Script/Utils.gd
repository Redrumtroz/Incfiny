class_name Utils

# ==========================================
# FONCTIONS UTILITAIRES GLOBALES
# ==========================================

# ATTENTION : On change "value: int" par "value: float" pour accepter les nombres géants !
static func format_number(value: float) -> String:
	if value < 1000.0:
		return str(int(value)) # On affiche sans virgule si c'est petit
		
	var suffixes = ["", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc"]
	var suffix_index = 0
	
	while value >= 1000.0 and suffix_index < suffixes.size() - 1:
		value /= 1000.0
		suffix_index += 1
		
	# Arrondi à 2 décimales (ex: 1.52M)
	var formatted_value = snapped(value, 0.01)
	return str(formatted_value) + suffixes[suffix_index]
