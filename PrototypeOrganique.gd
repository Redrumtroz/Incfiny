extends Node2D

var cell_size: int = 64
var grid: Dictionary = {} 
var buildings: Array = []
var decors: Array = []

var current_color: Color = Color.RED
var influence_radius_pixels: float = 192.0 

# --- CONVERSIONS ISOMÉTRIQUES ---
# Convertit les coordonnées de l'écran (Iso) vers la logique interne (Cartésien)
func iso_to_world(iso: Vector2) -> Vector2:
	return Vector2((iso.x / 2.0) + iso.y, iso.y - (iso.x / 2.0))

# Convertit la logique interne (Cartésien) vers l'écran (Iso)
func world_to_iso(world_pos: Vector2) -> Vector2:
	return Vector2(world_pos.x - world_pos.y, (world_pos.x + world_pos.y) / 2.0)

# --- LOGIQUE DU JEU ---
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_1: current_color = Color.RED
		elif event.keycode == KEY_2: current_color = Color.GREEN
		elif event.keycode == KEY_3: current_color = Color.BLUE
		
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# On convertit le clic de la souris en coordonnée logique plate
		var world_mouse = iso_to_world(get_local_mouse_position())
		_place_building(world_mouse)

func _place_building(world_pos: Vector2) -> void:
	buildings.append({"pos": world_pos, "color": current_color})
	_apply_influence(world_pos, current_color)
	_spawn_decors(world_pos)
	queue_redraw()

func _apply_influence(world_pos: Vector2, color: Color) -> void:
	var center_cell = Vector2i(world_pos / cell_size)
	var radius_cells = int(influence_radius_pixels / cell_size)
	var color_key = _color_to_string(color)
	
	for x in range(-radius_cells, radius_cells + 1):
		for y in range(-radius_cells, radius_cells + 1):
			var cell_offset = Vector2i(x, y)
			if Vector2(cell_offset).length() <= radius_cells:
				var cell = center_cell + cell_offset
				if not grid.has(cell):
					grid[cell] = {"red": 0.0, "green": 0.0, "blue": 0.0}
				var distance = Vector2(cell_offset).length()
				grid[cell][color_key] += max(0, 10.0 - (distance * 3.0))

func _spawn_decors(world_pos: Vector2) -> void:
	for i in range(20):
		var angle = randf() * TAU
		var distance = randf_range(40, influence_radius_pixels - 20)
		var spawn_pos = world_pos + Vector2(cos(angle), sin(angle)) * distance
		
		var cell = Vector2i(spawn_pos / cell_size)
		if grid.has(cell):
			var dominant_color = _get_dominant_color(cell)
			decors.append({"pos": spawn_pos, "color": dominant_color})

func _color_to_string(c: Color) -> String:
	if c == Color.RED: return "red"
	if c == Color.GREEN: return "green"
	return "blue"

func _get_dominant_color(cell: Vector2i) -> Color:
	var inf = grid[cell]
	if inf.red >= inf.green and inf.red >= inf.blue: return Color.RED
	if inf.green >= inf.red and inf.green >= inf.blue: return Color.GREEN
	return Color.BLUE

# --- AFFICHAGE (RENDU) ---
func _draw() -> void:
	# 1. Dessiner la grille (Transformée en losanges)
	for cell in grid.keys():
		var w_pos = Vector2(cell) * cell_size
		var p1 = world_to_iso(w_pos)
		var p2 = world_to_iso(w_pos + Vector2(cell_size, 0))
		var p3 = world_to_iso(w_pos + Vector2(cell_size, cell_size))
		var p4 = world_to_iso(w_pos + Vector2(0, cell_size))
		
		var inf = grid[cell]
		var total = inf.red + inf.green + inf.blue
		if total > 0:
			var r = inf.red / total
			var g = inf.green / total
			var b = inf.blue / total
			draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(r, g, b, min(total / 30.0, 0.4)))
		
		# Contour de la case
		draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), Color(1, 1, 1, 0.1), 1.0)

	# 2. Y-Sorting (Tri par profondeur pour afficher les objets au premier plan devant)
	var all_drawables = []
	for b in buildings: all_drawables.append({"type": "b", "data": b, "depth": b.pos.x + b.pos.y})
	for d in decors: all_drawables.append({"type": "d", "data": d, "depth": d.pos.x + d.pos.y})
	
	all_drawables.sort_custom(func(a, b): return a.depth < b.depth)

	# 3. Dessiner les objets et bâtiments triés
	for item in all_drawables:
		if item.type == "d":
			# Objets (petits cristaux/pyramides)
			var d = item.data
			var iso_pos = world_to_iso(d.pos)
			var p_top = iso_pos - Vector2(0, 15)
			var p_left = iso_pos + Vector2(-6, 3)
			var p_right = iso_pos + Vector2(6, 3)
			draw_colored_polygon(PackedVector2Array([p_top, p_left, p_right]), d.color.lightened(0.2))
			
		elif item.type == "b":
			# Bâtiments (Cubes 3D isométriques)
			var b = item.data
			var s = 20.0
			var height = 40.0
			
			# Calcul des coins de la base en isométrique
			var base_top = world_to_iso(b.pos + Vector2(-s, -s))
			var base_right = world_to_iso(b.pos + Vector2(s, -s))
			var base_bottom = world_to_iso(b.pos + Vector2(s, s))
			var base_left = world_to_iso(b.pos + Vector2(-s, s))
			
			# Calcul des coins du toit
			var roof_top = base_top - Vector2(0, height)
			var roof_right = base_right - Vector2(0, height)
			var roof_bottom = base_bottom - Vector2(0, height)
			var roof_left = base_left - Vector2(0, height)
			
			# Face Gauche
			draw_colored_polygon(PackedVector2Array([base_left, base_bottom, roof_bottom, roof_left]), b.color.darkened(0.3))
			# Face Droite
			draw_colored_polygon(PackedVector2Array([base_bottom, base_right, roof_right, roof_bottom]), b.color.darkened(0.5))
			# Toit
			draw_colored_polygon(PackedVector2Array([roof_top, roof_right, roof_bottom, roof_left]), b.color)

			# Cercle d'influence (Ellipse en isométrique)
			var points = PackedVector2Array()
			var segments = 64
			for i in range(segments + 1):
				var angle = i * TAU / segments
				var circle_pt = b.pos + Vector2(cos(angle), sin(angle)) * influence_radius_pixels
				points.append(world_to_iso(circle_pt))
			draw_polyline(points, b.color, 2.0)
