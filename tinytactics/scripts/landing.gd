extends Node2D

var text_color = Color(.64, .53, .47)
var selected_color = Color(1, .95, .91)

var readytoselect = true
var is_web = OS.get_name() == "HTML5"
var menu = []
var selected = 0

var file = File.new()
var player_data
var save_path = "user://save.dat"

func _new_save():
	player_data = {
		#data
		"placeholder": 0,
		#settings
		"input_type": 0,
		"music": 3,
		"sfx": 3
	}
	file.open(save_path, File.WRITE)
	file.store_var(player_data)
	file.close()
func _load():
	file.open(save_path, File.READ)
	player_data = file.get_var()
	file.close()

func _unhandled_input(event):
	if get_node("indexer/Options").visible == true:
		return
	if get_node("credits").visible == true:
		if event.is_action_pressed("ui_accept"):
			$sfx/select.play()
			$credits.visible = false
		return
	if event.is_action("ui_down") && !event.is_echo() && event.is_pressed():
		select_menu_item(selected + 1)
		$sfx/open.play()
	if event.is_action("ui_up") && !event.is_echo() && event.is_pressed():
		select_menu_item(selected - 1)
		$sfx/open.play()
	if event.is_action("ui_accept") && !event.is_echo() && event.is_pressed():
		action(menu[selected].name)	
		$sfx/select.play()
		

func _ready():
	if !file.file_exists(save_path):
		_new_save()
		print(player_data)
	else:
		_load()
		print(player_data)
	spawn_map()
	spawn_menu()
	select_menu_item(0)
	$music/theme.play()
#	$music/start.connect("finished", $music/loop, "play")

func action(name):
	if get_node("indexer/Options").visible == true:
		return
	if get_node("credits").visible == true:
		return
	if name == "quit":
		yield(get_tree().create_timer(0.2), "timeout")
		$sfx/select.play()
		get_tree().quit()
	if name == "play":
		yield(get_tree().create_timer(0.3), "timeout")		
		print("Load world")
# warning-ignore:return_value_discarded
		#$sfx/select.play()
		get_tree().change_scene("res://scenes/world.tscn")
	if name == "credits":
		$credits.visible = true
	if name == "options":
		if get_node("indexer/Options").visible == false:
			if readytoselect == true:
				get_node("indexer/Options").visible = true
				print(get_node("indexer/Options").visible)
				readytoselect = false

func select_menu_item(item):
	menu[selected].set("custom_colors/font_color", text_color)
	selected = clamp(item, 0, menu.size() - 1)
	menu[selected].set("custom_colors/font_color", selected_color)

func spawn_map():
	var map:Node = load("res://scenes/map.tscn").instance()
	get_node("Background").add_child(map)

func spawn_menu():
	var menu_parent:Node = load("res://scenes/menu.tscn").instance()
	get_node("Background").add_child(menu_parent)
	if is_web:
		var quit = menu_parent.get_node("quit")
		menu_parent.remove_child(quit)
		quit.call_deferred("free")
	menu = menu_parent.get_children()
