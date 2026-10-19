extends Node

# ==========================================
# BUS DE SIGNAUX GLOBAUX (EVENT BUS)
# ==========================================
# C'est la centrale de communication. Tous les événements majeurs passent par ici.

# --- ÉCONOMIE ---
@warning_ignore("unused_signal")
signal resources_updated
@warning_ignore("unused_signal")
signal resource_gained(res_id: String, amount: float)
@warning_ignore("unused_signal")
signal resource_spent(res_id: String, amount: float)

# --- MODULES ET NAVIGATION ---
@warning_ignore("unused_signal")
signal module_opened(module_name: String)
@warning_ignore("unused_signal")
signal module_closed(module_name: String)

# --- SAUVEGARDE ET SYSTÈME ---
@warning_ignore("unused_signal")
signal game_saved
@warning_ignore("unused_signal")
signal game_loaded
@warning_ignore("unused_signal")
signal offline_time_calculated(seconds_passed: int)
