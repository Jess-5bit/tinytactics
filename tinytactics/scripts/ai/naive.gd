extends Object
class_name NaiveAI

var world
var characters
var i_am = Game.CONTROL.AI

func _init(my_world):
	world = my_world
	characters = world.current[Game.CONTROL.AI]
	for character in characters:
		character.connect("idle", self, "play")
	
func play():
	if world.game_over:
		return
	var character = world.get_current()
	if character.character.control != Game.CONTROL.AI:
		print("Not my turn, skipping")
		return
	print("AI taking turn")
	var enemy = get_nearest_enemy(character.position)
	if enemy:
		var distance = character.position.distance_to(enemy.position)
		if distance < character.character.attack_range and character.character.turn_limits.actions > 0 and not world.is_cover_between(character.tile, enemy.tile):
			print("AI (" + character.character.name + ") says attack")
			character.attack(enemy)
			return
		if character.character.turn_limits.move_distance > 1 and distance > character.character.attack_range:
			var path = get_path_to(character.position, enemy.position, character.character.turn_limits.move_distance)
			if path and path.size() > 1:
				print("AI (" + character.character.name + ") says move")
				character.move(path)
				world.selector.teleport(path[path.size() - 1] / Vector2(Game.cell_size, Game.cell_size))
			else:
				print("AI (" + character.character.name + ") says wait (path too short)")
				world.advance_turn()
		else:
			print("AI (" + character.character.name + ") says wait (out of moves)")
			world.advance_turn()			
	else:
		print("AI (" + character.character.name + ") says wait (nothing to do)")
		world.advance_turn()

func get_path_length(points):
	if points.empty():
		return 0
	var last = points[0]
	var length = 0
	for point in points:
		length += point.distance_to(last)
		last = point
	return length

func get_path_to(start, end, max_length):
	var navigation = world.get_node("level/navigation")
	var path = navigation.get_simple_path(start, end, false)
	var fixed_path = normalize_path(path, max_length)
	# prevent landing on a tile that has someone on it
	while fixed_path.size() > 1 and world.entity_at_vector2(fixed_path[fixed_path.size() - 1] / Vector2(Game.cell_size, Game.cell_size)):
		fixed_path.resize(fixed_path.size() - 1)
	return fixed_path

func normalize_path(path, max_length):
	if path.size() == 0:
		return path
	path.resize(path.size() - 1)
	var normalized_path = PoolVector2Array()
	var index = 0
	var real_start = 0
	var real_end = Vector2(floor(path[path.size() -1].x / Game.cell_size), floor(path[path.size() -1].y / Game.cell_size))
	for point in path:
		var tile_position = Vector2(floor(point.x / Game.cell_size), floor(point.y / Game.cell_size))
		normalized_path.append(tile_position)
		if tile_position.is_equal_approx(real_end):
			break
		if tile_position.is_equal_approx(normalized_path[0]):
			real_start = index
		index += 1
	if real_start != 0:
		for r in range(real_start):
			normalized_path.remove(0)
	# re-multiply by cell_size for pixel positions
	var path_length = 0
	var last_point
	for point in range(normalized_path.size()):
		normalized_path[point].x *= Game.cell_size
		normalized_path[point].y *= Game.cell_size
#		if last_point:
#			path_length += last_point.distance_to(normalized_path[point])
#			last_point = normalized_path[point]
#			if path_length >= max_length:
#				return normalized_path
	if normalized_path.size() > max_length:
		normalized_path.resize(max_length)
	return normalized_path

func get_nearest_enemy(position):
	var enemies = world.current[Game.CONTROL.PLAYER]
	var shortest = 999
	var closest
	for enemy in enemies:
		var distance = position.distance_to(enemy.position)
		if distance < shortest:
			shortest = distance
			closest = enemy
	return closest
		
