extends Node

enum TYPE { ARCHER, MAGE, FIGHTER }
enum ABILITY { MOVE, ATTACK, GUARD, HEAL }
enum CONTROL { PLAYER, AI }

const cell_size = 16
const levels = {
	"level_1": "forest",
	"level_2": "forest",
	"level_3": "forest",
	"level_4": "cave",
	"level_5": "cave",
	"level_6": "city",
	"level_7": "city",
}

const class_names = {
	TYPE.FIGHTER: [
		"Silva",
		"Deal",
		"Amy",
		"Rina",
		"Lorre",
		"Tim"
	],
	TYPE.MAGE: [
		"Sage",
		"Flo",
		"Clyde",
		"Seth",
		"Laura",
		"Yava"
	],
	TYPE.ARCHER: [
		"Kara",
		"Joss",
		"Lota",
		"Rolf",
		"Jenna",
		"Marie"
	]
}
const class_stats = {
	"weakness": {
		TYPE.FIGHTER: TYPE.MAGE,
		TYPE.ARCHER: TYPE.FIGHTER,
		TYPE.MAGE: TYPE.ARCHER
	},
	"strength": {
		TYPE.MAGE: TYPE.FIGHTER,
		TYPE.FIGHTER: TYPE.ARCHER,
		TYPE.ARCHER: TYPE.MAGE
	},
	"hp": {
		TYPE.FIGHTER: 23,
		TYPE.ARCHER: 20,
		TYPE.MAGE: 17
	},
	"attack_range": {
		TYPE.FIGHTER: 32,
		TYPE.ARCHER: 96,
		TYPE.MAGE: 64
	},
	"move_range": {
		TYPE.FIGHTER: 8,
		TYPE.ARCHER: 6,
		TYPE.MAGE: 3
	},
	"actions": {
		TYPE.FIGHTER: 1,
		TYPE.ARCHER: 1,
		TYPE.MAGE: 1
	},
	"damage": {
		TYPE.FIGHTER: 4,
		TYPE.ARCHER: 4,
		TYPE.MAGE: 2
	},
	"defense": {
		TYPE.FIGHTER: 1,
		TYPE.ARCHER: 1,
		TYPE.MAGE: 0
	},
	"heal": {
		TYPE.FIGHTER: 0,
		TYPE.ARCHER: 0,
		TYPE.MAGE: 2
	},
	"abilities": {
		TYPE.ARCHER: [ ABILITY.MOVE, ABILITY.ATTACK, ABILITY.GUARD ],
		TYPE.FIGHTER: [ ABILITY.MOVE, ABILITY.ATTACK, ABILITY.GUARD ],
		TYPE.MAGE: [ ABILITY.MOVE, ABILITY.ATTACK, ABILITY.HEAL ]
	}
}

var team = []
var level = 0
var sudden_death = false

func get_level_count():
	return levels.keys().size()

func get_level():
	var names = levels.keys()
	return names[level]

func get_theme():
	var lvl = get_level()
	return levels[lvl]

func _ready():
	team.append(Character.new(TYPE.FIGHTER, CONTROL.PLAYER))
#	team.append(Character.new(TYPE.ARCHER, CONTROL.PLAYER))
