extends Control
class_name OrganicMap

signal building_clicked(b_id: String, influence: String)

var cell_size: int = 32
var influence_radius_pixels: float = 160.0 
var building_spacing: float = 45.0 
var building_solid_radius: float = 30.0 
var building_push_radius: float = 55.0  

var grid: Dictionary = {} 
var buildings: Array = []
var decors: Array = []

var current_tool_id: String = ""
var hovered_world_pos: Vector2 = Vector2.ZERO 
var show_debug_grid: bool = false
var default_font = ThemeDB.fallback_font

var building_styles = {
	"bld_park": {"color": Color("#22c55e"), "influence": "nature"},
	"bld_barracks": {"color": Color("#ef4444"), "influence": "militaire"},
	"bld_market": {"color": Color("#eab308"), "influence": "commerce"},
	"bld_mine": {"color": Color("#3b82f6"), "influence": "industrie"},
	"bld_tavern": {"color": Color("#a855f7"), "influence": "divertissement"}
}

var all_influences = ["nature", "militaire", "commerce", "industrie", "divertissement", "neutre"]
var evolution_timer: Timer

func _ready() -> void:
	focus_mode = FOCUS_ALL 
	evolution_timer = Timer.new()
	evolution_timer.wait_time = 5.0
	evolution_timer.autostart = true
	evolution_timer.timeout.connect(_on_evolution_tick)
	add_child(evolution_timer)

func _process(delta: float) -> void:
	var needs_redraw = false
	
	for i in range(decors.size() - 1, -1, -1):
		var d = decors[i]
		
		# 1. Déplacement fluide des objets repoussés
		if d.has("target_pos") and d.pos.distance_to(d.target_pos) > 1.0:
			d.pos = d.pos.move_toward(d.target_pos, 150.0 * delta)
			needs_redraw = true
			
		# 2. Animation fluide de la hauteur des murs
		if d.has("is_wall"):
			# Utilisation de .get() qui est 100% sécurisé
			var current = d.get("current_state", 1.0)
			var target = d.get("target_state", 1.0)
			
			if current != target:
				current = move_toward(current, target, 0.5 * delta) 
				d["current_state"] = current # On force la création de la clé proprement
				needs_redraw = true
				
			# UTILISE 'current' ICI, pas d["current_state"] !
			if current <= 0.0 and target == 0.0:
				decors.remove_at(i)
				
	if needs_redraw: 
		queue_redraw()

# --- CONVERSIONS ISOMÉTRIQUES ---
func iso_to_world(iso: Vector2) -> Vector2: return Vector2((iso.x / 2.0) + iso.y, iso.y - (iso.x / 2.0))
func world_to_iso(world_pos: Vector2) -> Vector2: return Vector2(world_pos.x - world_pos.y, (world_pos.x + world_pos.y) / 2.0)

# --- ENTRÉES JOUEUR & FANTÔME ---
func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_G:
		show_debug_grid = !show_debug_grid
		queue_redraw()
		
	if event is InputEventMouseMotion:
		hovered_world_pos = iso_to_world(get_local_mouse_position())
		if current_tool_id != "": queue_redraw() 
		
	if event is InputEventMouseButton and event.pressed:
		grab_focus() 
		var mouse_pos = get_local_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			if current_tool_id != "": _try_build_current_tool(mouse_pos)
			else: _try_select_building(mouse_pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			current_tool_id = "" 
			queue_redraw()

func _can_build_at(w_pos: Vector2) -> bool:
	for b in buildings:
		if b.pos.distance_to(w_pos) < building_spacing: return false
	return true

func _try_build_current_tool(mouse_pos: Vector2) -> void:
	var world_pos = iso_to_world(mouse_pos)
	if not _can_build_at(world_pos): return 
			
	var b_data = EconomyManager.buildings_data.get(current_tool_id, {})
	if b_data.is_empty(): return
	var cost = b_data.get("base_cost", {})
	if not EconomyManager.can_afford(cost): return
		
	for res_id in cost.keys(): EconomyManager.add_resource(res_id, -float(cost[res_id]))
	b_data["owned"] = b_data.get("owned", 0) + 1
		
	var style = building_styles.get(current_tool_id, {"color": Color.WHITE, "influence": "neutre"})
	buildings.append({"pos": world_pos, "color": style.color, "influence_type": style.influence, "type_id": current_tool_id})
	
	_react_to_new_building(world_pos)
	_apply_influence(world_pos, style.influence)
	_spawn_decors(world_pos)
	
	queue_redraw()

func _try_select_building(mouse_pos: Vector2) -> void:
	var world_pos = iso_to_world(mouse_pos)
	var clicked_b = null
	var min_dist = 25.0 
	for b in buildings:
		var dist = b.pos.distance_to(world_pos)
		if dist < min_dist:
			clicked_b = b
			min_dist = dist
	if clicked_b != null:
		building_clicked.emit(clicked_b.type_id, clicked_b.influence_type)

# --- ANALYSE DE CASE ET MÉLANGE DE COULEURS ---
func _get_cell_state(cell: Vector2i) -> Dictionary:
	if not grid.has(cell): return {"type": "neutre", "color": Color.TRANSPARENT, "total": 0.0, "dominant": "neutre"}
	var inf = grid[cell]
	var max_val = 0.0
	var dominant = "neutre"
	var total = 0.0
	var blended_color = Color(0, 0, 0)

	for key in inf.keys():
		if key == "neutre": continue
		var val = inf[key]
		if val > 0:
			total += val
			var c = _influence_to_color(key)
			blended_color.r += c.r * val
			blended_color.g += c.g * val
			blended_color.b += c.b * val
			if val > max_val:
				max_val = val
				dominant = key

	if total == 0: return {"type": "neutre", "color": Color.TRANSPARENT, "total": 0.0, "dominant": "neutre"}
	blended_color = Color(blended_color.r / total, blended_color.g / total, blended_color.b / total)

	# Seuil pour devenir un quartier "Pur"
	var final_type = "mixte"
	var final_color = blended_color
	if max_val >= 3.0 and (max_val / total) > 0.5:
		final_type = dominant
		final_color = _influence_to_color(dominant) 

	return {"type": final_type, "color": final_color, "total": total, "dominant": dominant}

# --- GESTION DES QUARTIERS (Culling, Pushing, Diffusion) ---
func _react_to_new_building(b_pos: Vector2) -> void:
	for i in range(decors.size() - 1, -1, -1):
		var d = decors[i]
		var dist = d.pos.distance_to(b_pos)
		
		# 1. Comportement des murs : Destruction s'ils sont sous le bâtiment
		if d.has("is_wall"):
			if dist < 40.0: # Même rayon de sécurité que pour la génération
				decors.remove_at(i)
			continue # On ignore la suite : on ne repousse jamais un mur !
			
		# 2. Comportement des décors normaux (arbres, caisses, etc.)
		if dist < building_solid_radius: 
			decors.remove_at(i) # Écrasement
		elif dist < building_push_radius:
			# Repoussement organique vers l'extérieur
			var push_dir = (d.pos - b_pos).normalized()
			d.target_pos = b_pos + (push_dir * building_push_radius) + Vector2(randf_range(-10, 10), randf_range(-10, 10))

func _apply_influence(world_pos: Vector2, influence_type: String) -> void:
	var center_cell = Vector2i(world_pos / cell_size)
	var radius_cells = int(influence_radius_pixels / cell_size)
	for x in range(-radius_cells, radius_cells + 1):
		for y in range(-radius_cells, radius_cells + 1):
			var cell_offset = Vector2i(x, y)
			if Vector2(cell_offset).length() <= radius_cells:
				var cell = center_cell + cell_offset
				if not grid.has(cell):
					grid[cell] = {}
					for inf in all_influences: grid[cell][inf] = 0.0
				var distance = Vector2(cell_offset).length()
				# Ajoute de l'influence, plafonnée à 100 maximum
				var strength = max(0, 50.0 - (distance * 10.0)) 
				grid[cell][influence_type] = min(100.0, grid[cell][influence_type] + strength)

func _spawn_decors(world_pos: Vector2) -> void:
	for i in range(25):
		var angle = randf() * TAU
		var distance = randf_range(building_solid_radius + 5, influence_radius_pixels - 10)
		var spawn_pos = world_pos + Vector2(cos(angle), sin(angle)) * distance
		var cell = Vector2i(spawn_pos / cell_size)
		if grid.has(cell):
			var state = _get_cell_state(cell)
			var type = state.dominant if state.total > 0 else "neutre"
			var color = _influence_to_color(type)
			decors.append({"pos": spawn_pos, "target_pos": spawn_pos, "color": color, "type": type})

func _generate_district_borders() -> void:
	var wall_threshold = 10.0 
	var valid_edges = {} 
	var orthogonals = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
	
	for cell in grid.keys():
		var state = _get_cell_state(cell)
		
		if state.type != "neutre":
			for n in orthogonals:
				var n_cell = cell + n
				var n_state = _get_cell_state(n_cell)
				
				var cell_center = (Vector2(cell) * cell_size) + (Vector2(cell_size, cell_size) / 2.0)
				var edge_center = cell_center + (Vector2(n) * (cell_size / 2.0))
				var overlaps_building = false
				for b in buildings:
					if b.pos.distance_to(edge_center) < 40.0:
						overlaps_building = true
						break
						
				if overlaps_building: continue
				
				var dir = Vector2(-n.y, n.x)
				var edge_key = str(snapped(edge_center.x, 0.1)) + "_" + str(snapped(edge_center.y, 0.1))
				var edge_hash = int(abs(edge_center.x * 3.1 + edge_center.y * 7.3)) % 10
				
				# 1. GROSSE ENCEINTE MILITAIRE (vers l'extérieur ou le neutre)
				var mil_val = grid[cell].get("militaire", 0.0)
				var n_mil_val = grid.get(n_cell, {}).get("militaire", 0.0)
				
				if state.type == "militaire" and mil_val > wall_threshold and n_mil_val <= wall_threshold:
					var wall_type = "mur_militaire"
					if edge_hash == 0 or edge_hash == 1: wall_type = "tour_militaire"
					elif edge_hash == 5: wall_type = "porte_militaire"
					valid_edges[edge_key] = {"pos": edge_center, "angle": dir.angle(), "type": wall_type}
					
				# 2. PETITS MURETS DE SÉPARATION (entre deux quartiers différents)
				elif n_state.type != "neutre" and state.type != n_state.type:
					# On compare les chaînes de caractères pour ne tracer le mur qu'une seule fois entre les deux cases
					if state.type > n_state.type: 
						var wall_type = "muret_separation"
						if edge_hash % 3 == 0: wall_type = "petit_passage" # 1 chance sur 3 d'avoir un passage
						valid_edges[edge_key] = {"pos": edge_center, "angle": dir.angle(), "type": wall_type}
						
	for d in decors:
		if d.has("is_wall"):
			var edge_key = str(snapped(d.pos.x, 0.1)) + "_" + str(snapped(d.pos.y, 0.1))
			if valid_edges.has(edge_key) and d.type == valid_edges[edge_key].type:
				d["target_state"] = 1.0 
				valid_edges.erase(edge_key) 
			else:
				d["target_state"] = 0.0 
					
	for edge_key in valid_edges.keys():
		var edge_data = valid_edges[edge_key]
		decors.append({
			"pos": edge_data.pos,
			"target_pos": edge_data.pos,
			"color": building_styles.get("bld_barracks", {"color": Color.RED}).color,
			"type": edge_data.type,
			"angle": edge_data.angle,
			"is_wall": true,
			"current_state": 0.0,
			"target_state": 1.0
		})

func _influence_to_color(influence: String) -> Color:
	for key in building_styles.keys():
		if building_styles[key].influence == influence: return building_styles[key].color
	return Color.DIM_GRAY

func _on_evolution_tick() -> void:
	var next_grid = grid.duplicate(true) 
	
	for cell in grid.keys():
		for inf in all_influences:
			if inf == "neutre": continue
			var val = grid[cell][inf]
			if val > 1.0:
				var transfer = val * 0.05 
				var neighbors = [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]
				for n_offset in neighbors:
					var neighbor_cell = cell + n_offset
					if not next_grid.has(neighbor_cell): 
						next_grid[neighbor_cell] = {}
						for inf_key in all_influences: next_grid[neighbor_cell][inf_key] = 0.0
					next_grid[neighbor_cell][inf] += transfer
				next_grid[cell][inf] = max(0.0, next_grid[cell][inf] - (transfer * 4) - 0.1)

	for b in buildings:
		var b_cell = Vector2i(b.pos / cell_size)
		if next_grid.has(b_cell):
			next_grid[b_cell][b.influence_type] = min(100.0, next_grid[b_cell][b.influence_type] + 25.0)
	grid = next_grid
	
# --- MISE À JOUR DES DÉCORS (L'animation des murs se fait dans _process) ---
	for i in range(decors.size() - 1, -1, -1):
		var d = decors[i]
		
		if d.has("is_wall"): 
			continue # On ignore les murs ici !
			
		var cell = Vector2i(d.pos / cell_size)
		var state = _get_cell_state(cell)
		var new_type = state.dominant if state.total > 0 else "neutre"
		
		if d.type != new_type:
			if new_type == "neutre": decors.remove_at(i)
			else:
				decors[i].type = new_type
				decors[i].color = _influence_to_color(new_type)
				
	_generate_district_borders()
	queue_redraw()

# --- RENDU VISUEL ---
func _draw_isometric_cube(w_pos: Vector2, color: Color) -> void:
	var s = 20.0
	var height = 40.0
	var base_top = world_to_iso(w_pos + Vector2(-s, -s))
	var base_right = world_to_iso(w_pos + Vector2(s, -s))
	var base_bottom = world_to_iso(w_pos + Vector2(s, s))
	var base_left = world_to_iso(w_pos + Vector2(-s, s))
	
	draw_colored_polygon(PackedVector2Array([base_left, base_bottom, base_bottom - Vector2(0, height), base_left - Vector2(0, height)]), color.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([base_bottom, base_right, base_right - Vector2(0, height), base_bottom - Vector2(0, height)]), color.darkened(0.5))
	draw_colored_polygon(PackedVector2Array([base_top - Vector2(0, height), base_right - Vector2(0, height), base_bottom - Vector2(0, height), base_left - Vector2(0, height)]), color)

func _draw() -> void:
	# 1. Dessin du sol
	for cell in grid.keys():
		var w_pos = Vector2(cell) * cell_size
		var p1 = world_to_iso(w_pos)
		var p2 = world_to_iso(w_pos + Vector2(cell_size, 0))
		var p3 = world_to_iso(w_pos + Vector2(cell_size, cell_size))
		var p4 = world_to_iso(w_pos + Vector2(0, cell_size))
		
		var state = _get_cell_state(cell)
		if state.total > 0:
			var c = state.color
			draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(c.r, c.g, c.b, min(state.total / 50.0, 0.5)))
		
		# --- AFFICHAGE COMPLET MULTI-VALEURS (Touche G) ---
		if show_debug_grid:
			draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), Color(1, 1, 1, 0.3), 1.0)
			
			var y_offset = -10
			for key in all_influences:
				if key == "neutre": continue
				var val = grid[cell].get(key, 0.0)
				if val > 0.5: # On masque les valeurs insignifiantes
					var c = _influence_to_color(key).lightened(0.2)
					var text = key.substr(0, 3).to_upper() + ":" + str(round(val)) # Ex: "MIL:45"
					draw_string(default_font, p1 + Vector2(0, y_offset), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 10, c)
					y_offset += 12 # Décale la ligne suivante vers le bas

	# 2. Y-Sorting
	var all_drawables = []
	for b in buildings: all_drawables.append({"type": "b", "data": b, "depth": b.pos.x + b.pos.y})
	for d in decors: all_drawables.append({"type": "d", "data": d, "depth": d.pos.x + d.pos.y})
	all_drawables.sort_custom(func(a, b): return a.depth < b.depth)

	# 3. Dessin des objets et murailles
	for item in all_drawables:
		if item.type == "b":
			_draw_isometric_cube(item.data.pos, item.data.color)
		elif item.type == "d":
			var d = item.data
			var iso_pos = world_to_iso(d.pos)
			var c = d.color
			
			if d.type in ["mur_militaire", "tour_militaire", "porte_militaire"]:
				var d_angle = d.get("angle", 0.0)
				var dir = Vector2(cos(d_angle), sin(d_angle))
				var w_left = d.pos - (dir * (cell_size / 2.0))
				var w_right = d.pos + (dir * (cell_size / 2.0))
				var i_left = world_to_iso(w_left)
				var i_right = world_to_iso(w_right)
				
				var state_val = d.get("current_state", 1.0)
				
				if d.type == "mur_militaire" and state_val > 0.05:
					var h = 30.0 * state_val 
					var top_left = i_left - Vector2(0, h)
					var top_right = i_right - Vector2(0, h)
					
					draw_colored_polygon(PackedVector2Array([i_left, top_left, top_right, i_right]), c.darkened(0.3))
					draw_polyline(PackedVector2Array([top_left, top_right]), c, 2.0)
					draw_polyline(PackedVector2Array([i_left, top_left]), c.darkened(0.5), 1.0)
					draw_polyline(PackedVector2Array([i_right, top_right]), c.darkened(0.5), 1.0)
					
				elif d.type in ["muret_separation", "petit_passage"] and state_val > 0.05:
					# Couleur neutre (pierre)
					var m_color = Color("#888888")
					var h = 8.0 * state_val # Beaucoup plus bas que les murs militaires
					
					if d.type == "muret_separation":
						var top_left = i_left - Vector2(0, h)
						var top_right = i_right - Vector2(0, h)
						draw_colored_polygon(PackedVector2Array([i_left, top_left, top_right, i_right]), m_color.darkened(0.3))
						draw_polyline(PackedVector2Array([top_left, top_right]), m_color, 1.0)
					
					elif d.type == "petit_passage":
						var pillar_w = (i_right - i_left) * 0.15
						# Poteau gauche
						draw_colored_polygon(PackedVector2Array([i_left, i_left - Vector2(0, h), i_left + pillar_w - Vector2(0, h), i_left + pillar_w]), m_color.darkened(0.4))
						# Poteau droit
						draw_colored_polygon(PackedVector2Array([i_right - pillar_w, i_right - pillar_w - Vector2(0, h), i_right - Vector2(0, h), i_right]), m_color.darkened(0.4))	
				
				elif d.type == "tour_militaire" and state_val > 0.05:
					var h = 45.0 * state_val # Tour plus haute
					var top_left = i_left - Vector2(0, h)
					var top_right = i_right - Vector2(0, h)
					
					draw_colored_polygon(PackedVector2Array([i_left, top_left, top_right, i_right]), c.darkened(0.15))
					draw_polyline(PackedVector2Array([top_left, top_right]), c.lightened(0.2), 4.0) # Créneaux éclairés
					draw_polyline(PackedVector2Array([i_left, top_left]), c.darkened(0.5), 2.0)
					draw_polyline(PackedVector2Array([i_right, top_right]), c.darkened(0.5), 2.0)
					
				elif d.type == "porte_militaire" and state_val > 0.05:
					var h = 25.0 * state_val
					var pillar_w = (i_right - i_left) * 0.25 # Les piliers prennent 25% de la case
					
					# Pilier Gauche
					var p1_top_left = i_left - Vector2(0, h)
					var p1_top_right = (i_left + pillar_w) - Vector2(0, h)
					draw_colored_polygon(PackedVector2Array([i_left, p1_top_left, p1_top_right, i_left + pillar_w]), c.darkened(0.4))
					
					# Pilier Droit
					var p2_top_left = (i_right - pillar_w) - Vector2(0, h)
					var p2_top_right = i_right - Vector2(0, h)
					draw_colored_polygon(PackedVector2Array([i_right - pillar_w, p2_top_left, p2_top_right, i_right]), c.darkened(0.4))
					
					# Poutre au dessus (Arche) visible quand la porte est bien construite
					if state_val > 0.8:
						draw_polyline(PackedVector2Array([p1_top_right, p2_top_left]), c.darkened(0.5), 4.0)
				
			elif d.type == "militaire":
				draw_rect(Rect2(iso_pos - Vector2(6, 4), Vector2(12, 8)), c.darkened(0.4))
				draw_line(iso_pos - Vector2(4, 4), iso_pos + Vector2(-4, -12), Color.LIGHT_GRAY, 2.0)
				draw_line(iso_pos - Vector2(-4, 4), iso_pos + Vector2(4, -12), Color.LIGHT_GRAY, 2.0)
			elif d.type == "nature":
				draw_line(iso_pos, iso_pos - Vector2(0, 10), Color("#5c4033"), 2.0)
				draw_circle(iso_pos - Vector2(0, 15), 8.0, c)
			elif d.type == "commerce":
				draw_colored_polygon(PackedVector2Array([iso_pos+Vector2(-8, 5), iso_pos+Vector2(8, -3), iso_pos+Vector2(8, -10), iso_pos+Vector2(-8, -2)]), Color("#8b5a2b"))
				draw_colored_polygon(PackedVector2Array([iso_pos+Vector2(-10, -2), iso_pos+Vector2(10, -12), iso_pos+Vector2(5, -20), iso_pos+Vector2(-15, -10)]), c)
			elif d.type == "industrie":
				draw_rect(Rect2(iso_pos - Vector2(8, 12), Vector2(16, 12)), c.darkened(0.3))
			elif d.type == "divertissement":
				draw_circle(iso_pos - Vector2(0, 5), 7.0, c.lightened(0.2))
			else:
				draw_colored_polygon(PackedVector2Array([iso_pos - Vector2(0, 10), iso_pos + Vector2(-5, 2), iso_pos + Vector2(5, 2)]), c)

	# 4. Fantôme de construction
	if current_tool_id != "":
		var valid = _can_build_at(hovered_world_pos)
		var style = building_styles.get(current_tool_id, {"color": Color.WHITE, "influence": "neutre"})
		_draw_isometric_cube(hovered_world_pos, Color(style.color.r, style.color.g, style.color.b, 0.6))
		
		var pts = PackedVector2Array()
		for i in range(33):
			var a = i * TAU / 32
			pts.append(world_to_iso(hovered_world_pos + Vector2(cos(a), sin(a)) * building_spacing))
		draw_polyline(pts, Color.GREEN if valid else Color.RED, 2.0)
