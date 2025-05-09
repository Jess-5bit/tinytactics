extends Control

var player
var enemy

func _ready():
	if not player:
		return
	if player.type == Game.TYPE.FIGHTER:
		if enemy.type == Game.TYPE.FIGHTER:
			$PlayerType.frame = 32
			$EnemyType.frame = 32
		elif enemy.type == Game.TYPE.MAGE:
			$PlayerType.frame = 32
			$EnemyType.frame = 34
		elif enemy.type == Game.TYPE.ARCHER:
			$PlayerType.frame = 32
			$EnemyType.frame = 33
	elif player.type == Game.TYPE.MAGE:
		if enemy.type == Game.TYPE.FIGHTER:
			$PlayerType.frame = 34
			$EnemyType.frame = 32
		elif enemy.type == Game.TYPE.MAGE:
			$PlayerType.frame = 34
			$EnemyType.frame = 34
		elif enemy.type == Game.TYPE.ARCHER:
			$PlayerType.frame = 34
			$EnemyType.frame = 33
	elif player.type == Game.TYPE.ARCHER:
		if enemy.type == Game.TYPE.FIGHTER:
			$PlayerType.frame = 33
			$EnemyType.frame = 32
		elif enemy.type == Game.TYPE.MAGE:
			$PlayerType.frame = 33
			$EnemyType.frame = 34
		elif enemy.type == Game.TYPE.ARCHER:
			$PlayerType.frame = 33
			$EnemyType.frame = 33

func set_entities(player_character, enemy_character):
	player = player_character
	enemy = enemy_character
	_ready()
	#playerhealth = player.hp
	#playermaxhealth = player.max_hp
	#enemyhealth = enemy.hp
	#enemymaxhealth = enemy.max_hp
	#playertype = player.type
	#enemytype = enemy.type

func _process(delta):
	if not visible or not player:
		return
	$playerhealthbar.set_value(player.hp, player.max_hp)
	$enemyhealthbar.set_value(enemy.hp, enemy.max_hp)
	$playerhealth.text = "%02d" % clamp(player.hp, 0, player.max_hp)
	$playermaxhealth.text = "%02d" % player.max_hp
	$enemyhealth.text = "%02d" % clamp(enemy.hp, 0, enemy.max_hp)
	$enemymaxhealth.text = "%02d" % enemy.max_hp
