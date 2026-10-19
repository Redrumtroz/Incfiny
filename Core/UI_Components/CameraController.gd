extends Node
class_name CameraController

# Ce signal renvoie la position cliquée, peu importe le contenu
signal map_clicked(local_pos: Vector2)

var viewport_node: Control
var target_node: Control
var is_dragging: bool = false

# Paramètres modifiables de l'extérieur pour chaque module
var min_zoom: float = 0.5
var max_zoom: float = 3.0

func setup(_viewport: Control, _target: Control) -> void:
	viewport_node = _viewport
	target_node = _target
	
	# Configuration automatique des Control
	viewport_node.clip_contents = true
	viewport_node.mouse_filter = Control.MOUSE_FILTER_PASS
	target_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# Connexion sécurisée
	if not viewport_node.gui_input.is_connected(_on_gui_input):
		viewport_node.gui_input.connect(_on_gui_input)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging = event.pressed
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var local_pos = (event.position - target_node.position) / target_node.scale
			map_clicked.emit(local_pos)
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.1, event.position)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(0.9, event.position)
			
	elif event is InputEventMouseMotion:
		if is_dragging:
			target_node.position += event.relative

func _zoom(factor: float, mouse_pos: Vector2) -> void:
	var old_zoom = target_node.scale
	var new_zoom = old_zoom * factor
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)
	
	if new_zoom == old_zoom: return
	var mouse_world_pos = (mouse_pos - target_node.position) / old_zoom
	target_node.scale = new_zoom
	target_node.position = mouse_pos - mouse_world_pos * new_zoom
