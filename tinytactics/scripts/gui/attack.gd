extends Control

var text_color = Color(1, .47, .66)
var selected_color = Color(1, .95, .91)
var unselectable_color = Color(.37, .34, .31)

signal attack
signal recruit

var selected = 0
var recruit_enabled = false

func _ready():
	recruit_allowed(true)

func _input(event):
	var max_selected = 1 if recruit_enabled else 0
	if !visible:
		return
	if event.is_action("ui_accept") && !event.is_echo() && event.is_pressed():
		emit_signal("attack") if selected == 0 else emit_signal("recruit")
	if event.is_action("ui_down") && !event.is_echo() && event.is_pressed():
		selected += 1
		selected = clamp(selected, 0, max_selected)
	if event.is_action("ui_up") && !event.is_echo() && event.is_pressed():
		selected -= 1
		selected = clamp(selected, 0, max_selected)
	if selected == 0:
		$attack.text = ">ATTACK"
		$attack.set("custom_colors/font_color", selected_color)
		$recruit.text = " RECRUIT"
		$recruit.set("custom_colors/font_color", text_color)
	else:
		$attack.text = " ATTACK"
		$attack.set("custom_colors/font_color", text_color)
		$recruit.text = ">RECRUIT"
		$recruit.set("custom_colors/font_color", selected_color)

func recruit_allowed(allow_recruiting):
	var color = unselectable_color if allow_recruiting else text_color
	$recruit.set("custom_colors/font_color", color)
	recruit_enabled = allow_recruiting
	if not recruit_enabled: 
		selected = 0
