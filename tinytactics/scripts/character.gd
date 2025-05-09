extends Object
class_name Character

var type
var control
var abilities
var attack_range
var attack_damage
var defense
var max_hp
var hp
var heal
var weakness
var strength
var name
var item

var turn_limits = {
	"move_distance": 64,
	"actions": 1 # attack, heal, guard
}

func end_turn():
	turn_limits.move_distance = Game.class_stats.move_range[type]
	turn_limits.actions = Game.class_stats.actions[type]

func _init(request_type, request_control):
	item = Item.new()
	item.generate(Game.level, request_type)
	type = request_type
	control = request_control
	
	abilities = Game.class_stats.abilities[type]
	max_hp = floor(Game.class_stats.hp[type] + rand_range((Game.level + 1) * 4, (Game.level + 1) * 5) - 15)
	hp = floor(Game.class_stats.hp[type] + rand_range((Game.level + 1) * 4, (Game.level + 1) * 5) - 15)
	turn_limits.move_distance = Game.class_stats.move_range[type]
	turn_limits.actions = Game.class_stats.actions[type]
	attack_range = Game.class_stats.attack_range[type]
	#attack_damage = Game.class_stats.damage[type]	
	
	if control == Game.CONTROL.AI:
		match Game.level:
			0:
				attack_damage = Game.class_stats.damage[type]
			1:
				attack_damage = Game.class_stats.damage[type]
			2:
				attack_damage = Game.class_stats.damage[type]
			3:
				attack_damage = Game.class_stats.damage[type] * 0.8
			4:
				attack_damage = Game.class_stats.damage[type] * 0.6
			5:
				attack_damage = Game.class_stats.damage[type] * 0.4
			6:
				attack_damage = Game.class_stats.damage[type] * 0.3			
	else: 
		attack_damage = Game.class_stats.damage[type]
				
	defense = Game.class_stats.defense[type]
	heal = Game.class_stats.heal[type]
	weakness = Game.class_stats.weakness[type]
	strength = Game.class_stats.strength[type]
	name = Game.class_names[type][rand_range(0, Game.class_names[type].size() - 1)]
	# don't want to take for ever to test death and level progression
	if Game.sudden_death and control == Game.CONTROL.AI:
		hp = 1
		max_hp = 1

func has_ability(ability):
	return abilities.has(ability)
