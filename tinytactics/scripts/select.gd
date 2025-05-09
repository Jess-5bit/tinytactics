extends AnimatedSprite

onready var world = get_tree().get_root().get_node("World")
onready var navigation # = get_tree().get_root().get_node("World/level/navigation")
onready var path = get_tree().get_root().get_node("World/path")
onready var ranged = get_tree().get_root().get_node("World/ranged")
onready var gui = get_tree().get_root().get_node("World/gui")

enum MODE {
	PLAY,
	CHECK_MAP
}
var allowed_path_color = Color(0.160784, 0.678431, 1)
var disallowed_path_color = Color(1, 0, 0.301961, 1)

var mode = MODE.PLAY
var cell_size = 16
var tile = Vector2(0, 0)
var friendlies = []
#var origin = Vector2(0, 0)
var current_entity
var disabled = false
var current_path = []
var current_target = {
	"tile": Vector2(0, 0),
	"entity": null
}

func _ready():
	path.width = 2
	path.position.x = cell_size / 2
	path.position.y = cell_size / 2
	tile.x = position.x / cell_size
	tile.y = position.y / cell_size

func _world_ready():
	navigation = get_tree().get_root().get_node("World/level/navigation")

func disable():
	print("disable selector")
	disabled = true

func enable():
	print("enable selector")
	disabled = false

# set visual feedback for tile context
func update():
	if disabled: 
		return
	if world.current_turn == Game.CONTROL.AI:
		play("attack")
		return
	ranged.hide()
	var origin = current_entity.position
	var target_entity = world.entity_at(tile.x, tile.y)
	if target_entity and target_entity.is_loot:
		play("attack") # empty selector
		path.hide()
	else:
		if target_entity and target_entity.character.control != world.current_turn: #Game.CONTROL.AI:
			gui.stats(current_entity, target_entity)
			play("attack")
#			if current_entity.character.turn_limits.actions == 0 or 
			if current_entity.position.distance_to(target_entity.position) > current_entity.character.attack_range:
				play("cantmove")
			path.hide()
		if target_entity and target_entity.character.control == world.current_turn: #Game.CONTROL.PLAYER:
			gui.close_health()
			gui.close_stats()
			if current_entity.character.has_ability(Game.ABILITY.HEAL):
				play("heal")
			elif current_entity == target_entity:
				play("guard")
			else:
				play("attack") # not really attack, empty selector
			path.hide()
	if !target_entity:
		gui.close_health()
		gui.close_stats()
		# display path if the target tile is passable
		if current_entity and world.map[tile.x][tile.y].passable:
			if not current_entity.movement.moving:
				var path_preview = normalize_path(navigation.get_simple_path(origin, world.as_world_position(tile), false))
				path.points = path_preview
				path.show()
				current_path = path_preview
				var path_length = path_preview.size()  - 1 # don't count start node
				if path_length <= current_entity.character.turn_limits.move_distance:
					path.default_color = allowed_path_color
					play("default")
				else:
					path.default_color = disallowed_path_color
					print("path not allowed " + str(path_length) + "/" + str(current_entity.character.turn_limits.move_distance))
					play("cantmove")
				if path_length < 1:
					play("cantmove")
			else:
				play("attack") # not really attack, empty selector
				path.hide()
		else:
			play("cantmove")
			path.hide()

func draw_attack_path(from, to, color):
	ranged.show()
	ranged.default_color = color
	ranged.clear_points()
	ranged.add_point(from + Vector2(cell_size / 2, cell_size /2))
	ranged.add_point(to + Vector2(cell_size / 2, cell_size /2))

func get_target():
	var target = world.entity_at(tile.x, tile.y)
	return target

func get_current():
	return current_entity

func get_path():
	return current_path

func _input(event):
	if gui.active or disabled or world.current_turn == Game.CONTROL.AI:
		path.hide()
		play("attack")
		return
	if event.is_action("ui_down") && !event.is_echo() && event.is_pressed():
		tile.y += 1
	if event.is_action("ui_up") && !event.is_echo() && event.is_pressed():
		tile.y -= 1
	if event.is_action("ui_left") && !event.is_echo() && event.is_pressed():
		tile.x -= 1
	if event.is_action("ui_right") && !event.is_echo() && event.is_pressed():
		tile.x += 1
	var target_entity = world.entity_at(tile.x, tile.y)
	
	if mode == MODE.PLAY:
		if event.is_action("ui_accept") && !event.is_echo() && event.is_pressed():
			world.action()
		if event.is_action("ui_select") && !event.is_echo() && event.is_pressed():
			tile.x = floor(current_entity.position.x / cell_size)
			tile.y = floor(current_entity.position.y / cell_size)
			print("selector closes ui")
			gui.call_deferred("back")
	tile.x = clamp(tile.x, 0, world.map_size.width - 1)
	tile.y = clamp(tile.y, 0, world.map_size.height - 1)
	position.x = tile.x * cell_size
	position.y = tile.y * cell_size

	if mode == MODE.PLAY:
		if current_entity.character.turn_limits.move_distance <= 0 and current_entity.character.turn_limits.actions == 0:
			print("select says advance turn")
			world.advance_turn()
#	else:
#		print("character moves left: " + str(current_entity.character.turn_limits.move_distance) + ", actions: " + str(current_entity.character.turn_limits.actions))
		update()
	else:
		if event.is_action("ui_accept") && !event.is_echo() && event.is_pressed():
			gui.team_confirm()
			disable()
		if animation != "attack":
			play("attack")

func normalize_path(path):
	if path.size() == 0:
		return path
	var normalized_path = PoolVector2Array()
	var index = 0
	var real_start = 0
	var real_end = Vector2(floor(path[path.size() -1].x / cell_size), floor(path[path.size() -1].y / cell_size))
	for point in path:
		var tile_position = Vector2(floor(point.x / cell_size), floor(point.y / cell_size))
		normalized_path.append(tile_position)
		if tile_position.is_equal_approx(real_end):
			break
		if tile_position.is_equal_approx(normalized_path[0]):
			real_start = index
		index += 1
	if real_start != 0:
		for r in range(real_start):
			normalized_path.remove(0)
	# re-multiply by 8 for pixel positions
	for point in range(normalized_path.size()):
		normalized_path[point].x *= cell_size
		normalized_path[point].y *= cell_size
	return normalized_path

#func get_path_length(points):
#	if points.empty():
#		return 0
#	var last = points[0]
#	var length = 0
#	for point in points:
#		length += point.distance_to(last)
#		last = point
#	return length

func teleport(pos):
	position = pos * Vector2(cell_size, cell_size)
	tile = pos

func go_home():
	teleport(current_entity.tile)

func set_origin(entity):
	if current_entity:
		current_entity.disconnect("path_complete", self, "update")
		current_entity.disconnect("idle", self, "go_home")
	current_entity = entity
	position = entity.position
	tile = position / cell_size
	current_entity.select()
	current_entity.connect("path_complete", self, "update")
	current_entity.connect("idle", self, "go_home")
