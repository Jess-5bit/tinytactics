extends Control

signal check_map
signal edit_team
signal start_lvl

var selected = 0

var text_color = Color(0.160784, 0.678431, 1)
var selected_color = Color(1, 0.945098, 0.909804)

func _ready():
	pass

func _process(delta):
	if selected == 0:
		$checkmap.text = ">CHECK MAP"
		$checkmap.set("custom_colors/font_color", selected_color)
		$editteam.text = "EDIT TEAM"
		$editteam.set("custom_colors/font_color", text_color)
		$startlvl.text = "START LVL"
		$startlvl.set("custom_colors/font_color", text_color)
	if selected == 1:
		$checkmap.text = "CHECK MAP"
		$checkmap.set("custom_colors/font_color", text_color)
		$editteam.text = ">EDIT TEAM"
		$editteam.set("custom_colors/font_color", selected_color)
		$startlvl.text = "START LVL"
		$startlvl.set("custom_colors/font_color", text_color)
	if selected == 2:
		$checkmap.text = "CHECK MAP"
		$checkmap.set("custom_colors/font_color", text_color)
		$editteam.text = "EDIT TEAM"
		$editteam.set("custom_colors/font_color", text_color)
		$startlvl.text = ">START LVL"
		$startlvl.set("custom_colors/font_color", selected_color)

func _input(event):
	if !visible:
		return
	if event.is_action("ui_cancel") && !event.is_echo() && event.is_pressed():
		emit_signal("start_lvl")
	if event.is_action("ui_down") && !event.is_echo() && event.is_pressed():
		selected += 1
		selected = clamp(selected, 0, 2)
	if event.is_action("ui_up") && !event.is_echo() && event.is_pressed():
		selected -= 1
		selected = clamp(selected, 0, 2)
	if event.is_action("ui_accept") && !event.is_echo() && event.is_pressed():
		if selected == 0:
			visible = false
			emit_signal("check_map")
		elif selected == 1:
			visible = false
			emit_signal("edit_team")
		elif selected == 2:
			visible = false
			emit_signal("start_lvl")
