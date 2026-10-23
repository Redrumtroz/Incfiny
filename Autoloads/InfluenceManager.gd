extends Node
# Dans InfluenceManager.gd
var cell_size: int = 64 # Taille virtuelle d'une case (en pixels)
var grid: Dictionary = {} 

# Exemple de ce que contiendra la grille en mémoire :
# grid[Vector2i(2, 5)] = {"commerce": 15, "pauvrete": 0, "magie": 2}
