extends Control

signal resume
signal options
signal quit

var selected = 0

var text_color = Color(0.160784, 0.678431, 1)
var selected_color = Color(1, 0.945098, 0.909804)

func _ready():
	pass

func _process(delta):
	if selected == 0:
		$resume.text = ">RESUME"
		$resume.set("custom_colors/font_color", selected_color)
		$options.text = "OPTIONS"
		$options.set("custom_colors/font_color", text_color)
		$quit.text = "QUIT"
		$quit.set("custom_colors/font_color", text_color)
#	if selected == 1:
#		$resume.text = "RESUME"
#		$resume.set("custom_colors/font_color", text_color)
#		$options.text = ">OPTIONS"
#		$options.set("custom_colors/font_color", selected_color)
#		$quit.text = "QUIT"
#		$quit.set("custom_colors/font_color", text_color)
	if selected == 1:
		$resume.text = "RESUME"
		$resume.set("custom_colors/font_color", text_color)
		$options.text = "OPTIONS"
		$options.set("custom_colors/font_color", text_color)
		$quit.text = ">QUIT"
		$quit.set("custom_colors/font_color", selected_color)

func _input(event):
	if !visible:
		return
	if event.is_action("ui_down") && !event.is_echo() && event.is_pressed():
		selected += 1
	if event.is_action("ui_up") && !event.is_echo() && event.is_pressed():
		selected -= 1
	selected = clamp(selected, 0, 1)
	if event.is_action("ui_accept") && !event.is_echo() && event.is_pressed():
		if selected == 0:
			visible = false
			emit_signal("resume")
		elif selected == 1:
			emit_signal("quit")
		#elif selected == 2:
		#	emit_signal("quit")
