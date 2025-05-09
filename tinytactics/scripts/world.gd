extends Node2D

enum TILEID {
	NOT_PASSABLE = 0,
	COVER,
	PLAYER_SPAWN,
	ENEMY_SPAWN_FIGHTER,
	ENEMY_SPAWN_MAGE,
	ENEMY_SPAWN_ARCHER
	ENEMY_SPAWN,
	PASSABLE,
	CHEST
}

var tile_meta
var world_map
var game_over = false
var current_turn = Game.CONTROL.PLAYER
var player_spawns = []
onready var selector = $select
onready var gui = get_tree().get_root().get_node("World/gui")
#onready var ai = NaiveAI.new(self)
var ai

var current = {
	Game.CONTROL.AI: [],
	Game.CONTROL.PLAYER: []
}

var current_character = 0
var map = []
var turns = 0
var map_size = { "width": 10, "height": 10 }
var cell_size = 16

func load_level(level_name):
	print("Loading level " + level_name)
	var level = load("res://scenes/levels/" + level_name + ".tscn").instance()
	print(level.editor_description)
	add_child_below_node($map_anchor, level)
	tile_meta = level.get_node("navigation/tile_meta") #$level/navigation/tile_meta
	world_map = level.get_node("map") # $level/map
	var used_rect = tile_meta.get_used_rect()
	map_size.width = used_rect.size.x
	map_size.height = used_rect.size.y
	$select/camera.limit_bottom = map_size.height * cell_size
	$select/camera.limit_right = map_size.width * cell_size
	tile_meta.hide() # meta data should not be visible to the player	
	selector.disable()

func get_current():
	current_character = clamp(current_character, 0, current[current_turn].size() - 1)
	return current[current_turn][current_character]

func entity_at_vector2(v2):
	return entity_at(v2.x, v2.y)

func entity_at(x, y):
	var characters = get_tree().get_nodes_in_group ("characters")
	for character in characters:
		if character.tile.x == x and character.tile.y == y and not character.is_dead:
			return character
	return null

func as_world_position(tile):
	return Vector2(tile.x * cell_size, tile.y * cell_size)

func make_tile(tile_id):
	return {
		"cover": tile_id == TILEID.COVER,
		"passable": tile_id != TILEID.NOT_PASSABLE and tile_id != TILEID.COVER
	}

func is_cover_between(start, end):
	var current_position = start
	while not current_position.is_equal_approx(end):
		current_position = current_position.move_toward(end, 1)
		if tile_meta.get_cellv(current_position) == TILEID.COVER: 
			return true
	return false
	
func spawn_chest(x, y, level = 0):
	var chest = load("res://scenes/chest.tscn").instance()
#	character.init(type, control)
	chest.teleport(x, y)
#	chest.level = Game.level + 1
	chest.add_to_group("characters")
	world_map.add_child(chest)
	print("Spawned chest")
	return chest

func spawn_character(x, y, type = Game.TYPE.MAGE, control = Game.CONTROL.PLAYER):
	var character:Node = load("res://scenes/character_controller.tscn").instance()
	character.init(type, control)
	character.teleport(x, y)
	character.add_to_group("characters")
	world_map.add_child(character)
	return character

func advance_turn():
	current_character += 1
	if current_character >= current[current_turn].size():
		print("End turn")
		end_turn()		
	else:
		print("Advance turn")
		selector.disable()
		yield(get_tree().create_timer(1.0), "timeout")
		selector.set_origin(get_current())
		if current_turn  == Game.CONTROL.AI:
			ai.play()
		else:
			selector.enable()
	current_character = clamp(current_character, 0, current[current_turn].size() -1)


func end_turn():
#	current[current_turn][current_character]
	current_turn = Game.CONTROL.AI if current_turn == Game.CONTROL.PLAYER else Game.CONTROL.PLAYER
	for character in current[current_turn]:
		character.end_turn()
	current_character = 0
#	selector.set_origin(get_current())
	gui.turn(current_turn)
	selector.disable()


func action():
	print ("world action")
	var current_path = selector.get_path()
	var target = entity_at(selector.tile.x, selector.tile.y)
	
	if not current_path.empty() and not target:
		var path_length = current_path.size() - 1 # don't count start node
		if path_length <= get_current().character.turn_limits.move_distance:
			get_current().move(current_path)
		else:
			gui.error("PATH TOO LONG")
	if target:
		if !target.is_loot and target.character.control != current_turn:
			if get_current().character.turn_limits.actions != 0 and target.can_recruit() and is_adjacent(get_current(), target):
				gui.attack(target.can_recruit())
			else:
				_on_attack()
		elif !target.is_loot and target == get_current():
			if get_current().character.turn_limits.actions == 0:
				_on_end()
			else:
				gui.guard(get_current().character.has_ability(Game.ABILITY.HEAL))
		elif !target.is_loot and get_current().character.has_ability(Game.ABILITY.HEAL):
			_on_heal()
		elif target.is_loot:
			if is_adjacent(target, get_current()):
				var loot = target.open(get_current().character.type)
				if loot:
					print(loot.name)
					yield(get_tree().create_timer(1.0), "timeout")				
					gui.loot(get_current().character.item, loot)
			else:
				gui.error("TOO FAR")

func is_adjacent(one, two):
	return abs(one.tile.x - two.tile.x) <= 1 and abs(one.tile.y - two.tile.y) <= 1

func _ready():
	print(Game.team)
	randomize()
	
	load_level(Game.get_level())
	current[Game.CONTROL.PLAYER] = []
	current[Game.CONTROL.AI] = []
	player_spawns = []
	for x in range(map_size.width):
		map.append([])		
		for y in range(map_size.height):
			var tile_id = tile_meta.get_cell(x, y)
			map[x].append(make_tile(tile_id))
			if tile_id == TILEID.PLAYER_SPAWN:
				player_spawns.append(Vector2(x, y))
#				var character = spawn_character(x, y)
#				current[Game.CONTROL.PLAYER].append(character)
			if tile_id == TILEID.ENEMY_SPAWN_MAGE:
				current[Game.CONTROL.AI].append(spawn_character(x, y, Game.TYPE.MAGE, Game.CONTROL.AI))
				current[Game.CONTROL.AI].back().connect("death", self, "_on_death")
			if tile_id == TILEID.ENEMY_SPAWN_FIGHTER:
				current[Game.CONTROL.AI].append(spawn_character(x, y, Game.TYPE.FIGHTER, Game.CONTROL.AI))
				current[Game.CONTROL.AI].back().connect("death", self, "_on_death")
			if tile_id == TILEID.ENEMY_SPAWN_ARCHER:
				current[Game.CONTROL.AI].append(spawn_character(x, y, Game.TYPE.ARCHER, Game.CONTROL.AI))
				current[Game.CONTROL.AI].back().connect("death", self, "_on_death")
			if tile_id == TILEID.CHEST:
				var chest = spawn_chest(x, y)
	ai = NaiveAI.new(self)
#	selector.set_origin(get_current())
	print("Attach attack event")
	gui.get_node("attack").connect("attack", self, "_on_attack")
	gui.get_node("attack").connect("recruit", self, "_on_recruit")
	gui.get_node("guard").connect("guard", self, "_on_guard")
	gui.get_node("guard").connect("end", self, "_on_end")
	gui.get_node("guard").connect("heal", self, "_on_heal")
	gui.get_node("playerturn").connect("done", self, "_initiate_turn")
	gui.get_node("enemyturn").connect("done", self, "_initiate_turn")
#	gui.get_node("intro").connect("closed", self, "_initiate_turn")
	gui.get_node("intro").connect("closed", self, "select_team")
	gui.get_node("weaponswap").connect("swap", self, "_accept_loot")
	gui.get_node("weaponswap").connect("dont_swap", self, "_destroy_loot")
	gui.get_node("characterselect").connect("character_selected", self, "_on_select_team_member")
	gui.get_node("characterselect").connect("library_exhausted", self, "_on_team_select_done")
	gui.get_node("teamconfirm").connect("start_lvl", self, "_on_start_level")
	gui.get_node("teamconfirm").connect("check_map", self, "_on_check_map")
	gui.get_node("teamconfirm").connect("edit_team", self, "_on_edit_team")
	gui.get_node("win").connect("next", self, "_on_next_level")
	gui.get_node("win").connect("retry", self, "_on_replay")
	gui.get_node("lose").connect("retry", self, "_on_replay")
#	gui.get_node("lose").connect("quit", self, "_on_quit") # gui is listening for this

#	select_team()
	selector._world_ready()
	if $level.editor_description and $level.editor_description != "":
		gui.intro($level.editor_description)
	else:
		select_team()
	$music.get_node(Game.get_theme()).play()
#	$music/start.connect("finished", $music/loop, "play")	

func select_team():
	for member in Game.team:
		member.hp = member.max_hp
		member.end_turn() # reset actions and moves
	gui.team_select(Game.team)
	selector.teleport(player_spawns[0])
#
#	if Game.team.size() > 1:
#		gui.team_select(Game.team)
#		selector.teleport(player_spawns[0])
#	else:
#		var character = spawn_character(player_spawns[0].x, player_spawns[0].y)
#		current[Game.CONTROL.PLAYER].append(character)
#		selector.teleport(player_spawns[0])
#		_on_team_select_done()

func _on_team_select_done():
	gui.back()
	gui.team_confirm()
#	selector.set_origin(get_current())
#	selector.call_deferred("enable")

func _on_check_map():
	gui.back()
	gui.get_node("sfx/select").play()
	selector.mode = selector.MODE.CHECK_MAP
	selector.call_deferred("enable")

func _on_edit_team():
	# rediscover player spawns
	player_spawns = []
	for x in range(map_size.width):
		for y in range(map_size.height):
			var tile_id = tile_meta.get_cell(x, y)
			if tile_id == TILEID.PLAYER_SPAWN:
				player_spawns.append(Vector2(x, y))
	# clear previously selected team
	for character in current[Game.CONTROL.PLAYER]:
		world_map.remove_child(character)
	current[Game.CONTROL.PLAYER].resize(0)
	# and start over
	gui.back()
	gui.get_node("sfx/select").play()
	call_deferred("select_team")
#	select_team()

func _on_start_level():
	gui.modal = false
	gui.back()
	gui.get_node("sfx/select").play()
	selector.mode = selector.MODE.PLAY
	selector.set_origin(get_current())
	selector.call_deferred("enable")

func check_end_game():
	for control in [ Game.CONTROL.AI, Game.CONTROL.PLAYER ]:
		if current[control].size() == 0:
			game_over = true
			selector.disable()
			if control == Game.CONTROL.AI:
				gui.win()
				$music/win.play()
				print("End game: WIN")
			else:
				gui.lose()
				print("End game: LOSE")
				$music/lose.play()
			$music.get_node(Game.get_theme()).stop()
			return true
	return false

func _on_death(character):
	character.hide()
	var control = character.character.control
	current[control].erase(character)	
	if not check_end_game():
		advance_turn()

func _on_replay():
	get_tree().reload_current_scene()

func _on_next_level():
	if Game.level + 1 < Game.get_level_count():
		Game.level += 1
		get_tree().reload_current_scene()
	else:
		# All levels completed?
		gui.back()
		gui.credits()
		$music.get_node(Game.get_theme()).stop()
		$music/win.play()
#		gui.error("ALL LEVELS COMPLETED")

func _on_select_team_member(team_member):
	var character:Node = load("res://scenes/character_controller.tscn").instance()
	var spawn = player_spawns.pop_front()
	character.from_library(team_member)
	character.teleport(spawn.x, spawn.y)
	character.add_to_group("characters")
	world_map.add_child(character)
	current[Game.CONTROL.PLAYER].append(character)
	character.connect("death", self, "_on_death")
	if player_spawns.size() > 0:
		selector.teleport(player_spawns[0])
	else:
		_on_team_select_done()

func _initiate_turn():
	# in case a signal triggers this after the level is won/lost
	if current[Game.CONTROL.AI].size() == 0 or current[Game.CONTROL.PLAYER].size() == 0:
		return
	if selector.disabled:
		print("initiate turn")
		gui.back()
		selector.enable()
		selector.set_origin(get_current())
	if current_turn == Game.CONTROL.AI:
		print("Control turned over to AI")
		ai.play()
	
func _on_attack():
	print("attack option selected in menu")
	gui.close_stats()
	$ranged.hide()	
	if get_current().character.turn_limits.actions != 0:
		var target = entity_at(selector.tile.x, selector.tile.y)
		var attack_distance = get_current().position.distance_to(target.position)
		# block ranged attacks if cover is between attacker and target
		if get_current().character.type != Game.TYPE.FIGHTER and is_cover_between(get_current().tile, target.tile):
			gui.error("BLOCKED LINE OF SIGHT")
			gui.call_deferred("back")
			return
		if attack_distance > get_current().character.attack_range:
			gui.error("OUT OF RANGE")
			gui.call_deferred("back")
			return
		var damage = get_current().attack(target)
		var damage_feedback:Node = load("res://scenes/damage_feedback.tscn").instance()
		damage_feedback.position.x = target.position.x
		damage_feedback.position.y = target.position.y - 3
		if damage == 0:
			damage_feedback.get_node("damage").text = "miss"
		else:
			damage_feedback.get_node("damage").text = str("-", damage)	
		add_child(damage_feedback)
		gui.call_deferred("close_attack")
		gui.health(get_current(), target)
	else:
		gui.error("NO MORE ACTIONS")
		gui.call_deferred("back")
#		pass # play no go noise

func _on_recruit():
	print("recruit option selected in menu")
	var target = entity_at(selector.tile.x, selector.tile.y)
	if get_current().character.turn_limits.actions != 0 and is_adjacent(get_current(), target):
		get_current().character.turn_limits.actions -= 1
		if target.recruit(get_current()):
			target.character.control = Game.CONTROL.PLAYER
			Game.team.append(target.character)
			current[Game.CONTROL.AI].erase(target)
		else:
			gui.error("FAILED TO RECRUIT")
		selector.go_home()
	else:
		print("not recruited, no actions (" + str(get_current().character.turn_limits.actions) + ") or out of range")
	gui.call_deferred("back")

func _on_guard():
	if get_current().character.turn_limits.actions != 0:
		get_current().guard()
	gui.call_deferred("back")

func _on_heal():
	var target = entity_at(selector.tile.x, selector.tile.y)	
	if get_current().character.turn_limits.actions != 0:
		var healed = get_current().heal(target)
		var damage_feedback:Node = load("res://scenes/damage_feedback.tscn").instance()
		damage_feedback.position.x = target.position.x
		damage_feedback.position.y = target.position.y - 3
		damage_feedback.get_node("damage").text = "+" + str(healed)
		add_child(damage_feedback)
		target.get_node("vfx/heal").emitting = true
		print("healed")
	gui.call_deferred("back")

func _on_end():
	gui.call_deferred("back")
	print("explicit end request, advancing turn")
	advance_turn()

func _accept_loot(item):
	get_current().character.item = item
	gui.back()

func _destroy_loot():
	gui.back()

# DEBUG INPUT
#func _input(event):
#	if event.is_action("ui_focus_next") && !event.is_echo() && event.is_pressed():
#		_on_next_level()
#	if event.is_action("ui_home") && !event.is_echo() && event.is_pressed():
#		_on_replay()
