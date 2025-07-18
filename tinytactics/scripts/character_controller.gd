extends Node2D

signal path_complete
signal idle
signal death
signal recruited
signal recruit_failed

var cell_size = Game.cell_size
var guarding = false
var character
var path = []
var avatar
# var item = Item.new(0, 0, 0) # dummy item, no buffs
var tile = Vector2(0, 0)
var is_loot = false
var is_dead = false
var healthbar
var last_target

var movement = {
	"start_position": Vector2(0, 0),
	"end_position": Vector2(0, 0),
	"start_time": 0,
	"speed": 400,
	"last_horizontal_direction": "left",
	"moving": false
}

func _ready():
	pass

func hit(type):
	match(type):
		Game.TYPE.ARCHER:
			print("arrow hit!")
			$vfx/arrow_hit.emitting = true
			pick_random_sfx($sfx/arrow_hit)
		Game.TYPE.FIGHTER:
			pick_random_sfx($sfx/sword_hit)
		Game.TYPE.MAGE:
			$vfx/magic_hit.emitting = true
			pick_random_sfx($sfx/magic_hit)
	avatar.play("hit-" + movement.last_horizontal_direction)
	if guarding:
		pick_random_sfx($sfx/defend)
	if character.hp != character.max_hp:
		healthbar.show()
	if character.hp <= 0:
		die()

func pick_random_sfx(audio_path):
	var effects = audio_path.get_children()
	effects[rand_range(0, effects.size() - 1)].play()

func stop_all_sfx(audio_path):
	var effects = audio_path.get_children()
	for effect in effects:
		effect.stop()

func select():
	pick_random_sfx($sfx/selected)

func teleport(x, y):
	tile.x = x
	tile.y = y
	position.x = x * cell_size
	position.y = y * cell_size

func heal(target):
	if character.turn_limits.actions < 1:
		return 0
	character.turn_limits.actions -= 1
	var healed_hp = character.heal + character.item.heal
	target.character.hp = clamp(target.character.hp + healed_hp, 0, target.character.max_hp)
	pick_random_sfx($sfx/heal)
	if target.character.hp == target.character.max_hp:
		healthbar.hide()
	return healed_hp

func guard():
	if character.has_ability(Game.ABILITY.GUARD):
		$guard.show()
		character.turn_limits.actions = 0
		character.turn_limits.move_distance = 0
		guarding = true

func end_turn():
	guarding = false
	character.end_turn()
	$guard.hide()

func attack(target):
	last_target = target
	if character.turn_limits.actions < 1:
		return 0
	character.turn_limits.actions -= 1
	var attack_range = character.attack_range + character.item.attack_range
	var damage = float(character.attack_damage + character.item.attack)
	if target.character.type == character.weakness:
		damage = damage * 0.7
	if target.character.type == character.strength:
		damage = damage * 1.3
	if target.guarding:
		damage = damage * 0.5
	damage -= ((target.character.defense + target.character.item.defense) * 1.5)
	damage = floor(damage)
	target.character.hp -= damage

	if character.type == Game.TYPE.MAGE:
		var projectile = load("res://scenes/projectile.tscn").instance()
		projectile.fire(position + Vector2(8, 8), target.position + Vector2(8, 8))
		projectile.connect("hit", target, "hit", [character.type])
		projectile.connect("hit", self, "attack_complete")
		projectile.get_node("sparkle").play("player" if character.control == Game.CONTROL.PLAYER else "ai")
		pick_random_sfx($sfx/magic_attack)
		get_parent().add_child(projectile)
	elif character.type == Game.TYPE.ARCHER:
		# move this to on animation complete 
		pass
	else:
		attack_complete()
		target.hit(character.type)
	if target.position.x < position.x:
		avatar.play("attack-left")
	if target.position.x > position.x:
		avatar.play("attack-right")
	if target.position.y < position.y:
		avatar.play("attack-up")
	if target.position.y > position.y:
		avatar.play("attack-down")
	return damage

func attack_complete():
	yield(get_tree().create_timer(1.0), "timeout")
	print("attack complete")
	emit_signal("idle")

func move(target_path:PoolVector2Array):
	if movement.moving:
		return
	path = target_path
	movement.start_time = OS.get_ticks_msec()
	movement.end_position = Vector2(path[0].x, path[0].y)
	movement.start_position = Vector2(position.x, position.y)
	movement.moving = true
	pick_random_sfx($sfx/walk)
	character.turn_limits.move_distance -= path.size()

func select_type():
	$archer.hide()
	$fighter.hide()
	$mage.hide()
	$ai_archer.hide()
	$ai_fighter.hide()
	$ai_mage.hide()
	if character.control == Game.CONTROL.PLAYER:
		match character.type:
			Game.TYPE.ARCHER:
				avatar = $archer
			Game.TYPE.FIGHTER:
				avatar = $fighter
			Game.TYPE.MAGE:
				avatar = $mage
	else:
		match character.type:
			Game.TYPE.ARCHER:
				avatar = $ai_archer
			Game.TYPE.FIGHTER:
				avatar = $ai_fighter
			Game.TYPE.MAGE:
				avatar = $ai_mage
	avatar.connect("animation_finished", self, '_on_animation_finished')
	#item = Item.new()
	
	# print("generated item: " + item.name)
	avatar.show()

func from_library(team_member):
	character = team_member
	# reset to max hp when deploying
	character.hp = character.max_hp
	select_type()
	init_common(team_member.control)

func can_recruit():
	if Game.sudden_death:
		return true 
	else:
		return character.hp <= character.max_hp / 3

func recruit(source):
	var chance_to_recruit = 0.5
	if randf() < chance_to_recruit:
		attack(source)
		emit_signal("recruit_failed")
		$sfx/recruit/fail.play()
		return false
	else:
		emit_signal("recruited")
		$sfx/recruit/success.play()
		die()
		return true

func die():
	is_dead = true
	pick_random_sfx($sfx/death)
	avatar.play("hit-" + movement.last_horizontal_direction)

func init_common(control):
	healthbar = load("res://scenes/healthbar.tscn").instance()
	healthbar.position.x = 0
	healthbar.position.y = -5
	healthbar.set_value(character.hp, character.max_hp)
	if control == Game.CONTROL.PLAYER:
		healthbar.get_node("level").color = Color(0.023529, 0.352941, 0.709804)
	healthbar.hide()
	add_child(healthbar)
	
func init(char_type, control = Game.CONTROL.PLAYER):	
	character = Character.new(char_type, control)
	select_type()
	init_common(control)

func fire_arrow(target):
		var projectile = load("res://scenes/arrow.tscn").instance()
		projectile.fire(position + Vector2(8, 8), target.position + Vector2(8, 8))
		projectile.connect("hit", target, "hit", [character.type])
		projectile.connect("hit", self, "attack_complete")
		pick_random_sfx($sfx/arrow_attack)
		get_parent().add_child(projectile)
		last_target = null
	
func _on_animation_finished():
	if avatar.animation.begins_with("attack") and character.type == Game.TYPE.ARCHER and last_target:
		fire_arrow(last_target)
	if is_dead and avatar.animation.begins_with("hit"):
		emit_signal("death", self)
		avatar.stop()
	if avatar.animation.begins_with("attack") or avatar.animation.begins_with("hit") :
		if avatar.animation.ends_with("up"):
			avatar.play("idle-left")
		if avatar.animation.ends_with("down"):
			avatar.play("idle-right")
		if avatar.animation.ends_with("left"):
			avatar.play("idle-left")
		if avatar.animation.ends_with("right"):
			avatar.play("idle-right")

func _process(delta):
	var now = OS.get_ticks_msec()
	healthbar.set_value(character.hp, character.max_hp)
	if avatar.playing and avatar.animation.begins_with("attack"):
		return
	if not path.empty():
		var progress = float(now - movement.start_time) / float(movement.speed)
		if position.is_equal_approx(movement.end_position) or progress >= 1.0:
			path.remove(0)
			position = movement.end_position
			tile.x = round(position.x / cell_size)
			tile.y = round(position.y / cell_size)			
			if not path.empty():
				movement.end_position = Vector2(path[0].x, path[0].y)
				movement.start_position = Vector2(position.x, position.y)
				movement.start_time = now
				var diff = movement.start_position - movement.end_position
				if abs(diff.x) > abs(diff.y):
					if diff.x > 0:
						avatar.play("walk-left")
						movement.last_horizontal_direction = "left"
					else:
						avatar.play("walk-right")
						movement.last_horizontal_direction = "right"
				else:
					if diff.y > 0:
						avatar.play("walk-up")
					else:
						avatar.play("walk-down")
			else:
				avatar.play("idle-" + movement.last_horizontal_direction)
				if movement.moving:
					print("path complete")
					emit_signal("path_complete")
					emit_signal("idle")
					movement.moving = false
				stop_all_sfx($sfx/walk)
		else:
			position = lerp(movement.start_position, movement.end_position, progress)
