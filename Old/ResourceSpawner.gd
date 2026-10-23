extends Node
class_name ResourceSpawner

var city_map: Control
var map_camera: Control
var max_clickables = 15
var tree_timer: Timer
var rock_timer: Timer

func setup(_city_map: Control, _map_camera: Control) -> void:
	city_map = _city_map
	map_camera = _map_camera
	
	tree_timer = Timer.new()
	tree_timer.timeout.connect(_on_spawn_tick.bind("tree"))
	add_child(tree_timer)
	_start_random_timer(tree_timer, 2.0, 4.0)
	
	rock_timer = Timer.new()
	rock_timer.timeout.connect(_on_spawn_tick.bind("rock"))
	add_child(rock_timer)
	_start_random_timer(rock_timer, 5.0, 8.0)

func _start_random_timer(timer: Timer, min_time: float, max_time: float) -> void:
	timer.start(randf_range(min_time, max_time))

func _on_spawn_tick(type: String) -> void:
	var clickables_count = 0
	for child in map_camera.get_children():
		if child is Button: clickables_count += 1
		
	if clickables_count >= max_clickables:
		_restart_timer_for(type)
		return
		
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(40, 40)
	
	var res_id = ""
	var friendly_name = ""
	if type == "tree":
		btn.text = "🌲"
		res_id = "MAT_WOOD"
		friendly_name = "Arbre (Bois)"
	elif type == "rock":
		btn.text = "🪨"
		res_id = "MAT_STONE"
		friendly_name = "Rocher (Pierre)"
		
	call_deferred("_place_clickable_on_map", btn, res_id, friendly_name)
	_restart_timer_for(type)

func _restart_timer_for(type: String) -> void:
	if type == "tree": _start_random_timer(tree_timer, 2.0, 4.0)
	elif type == "rock": _start_random_timer(rock_timer, 5.0, 8.0)

func _place_clickable_on_map(btn: Button, res_id: String, friendly_name: String) -> void:
	var view_size = city_map.size / map_camera.scale
	var offset = -map_camera.position / map_camera.scale
	
	var random_x = randf_range(offset.x + 50, offset.x + view_size.x - 50)
	var random_y = randf_range(offset.y + 50, offset.y + view_size.y - 50)
	
	btn.position = Vector2(random_x, random_y)
	btn.pressed.connect(func():
		EconomyManager.add_resource(res_id, 1.0)
		TooltipManager.hide_tooltip()
		btn.queue_free() 
	)
	
	btn.mouse_entered.connect(func(): TooltipManager.show_tooltip("[b]" + friendly_name + "[/b]\n[color=#55ffff]Cliquer pour récolter +1[/color]"))
	btn.mouse_exited.connect(func(): TooltipManager.hide_tooltip())
	
	map_camera.add_child(btn)
