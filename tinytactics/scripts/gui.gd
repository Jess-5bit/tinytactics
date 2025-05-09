extends CanvasLayer

var active = false
var modal = false

func _ready():
	get_node("pause").connect("resume", self, "back")
	get_node("pause").connect("options", self, "options")
	get_node("pause").connect("quit", self, "_on_quit")
	get_node("lose").connect("quit", self, "_on_quit")
	get_node("Options").connect("close", self, "close_options")

func _input(event):
	if not modal and event.is_action("ui_cancel") && !event.is_echo() && event.is_pressed():
		$sfx/close.play()
		back()
	if not modal and event.is_action("ui_end") && !event.is_echo() && event.is_pressed():
		pause()
	if active:
		if event.is_action("ui_down") && !event.is_echo() && event.is_pressed():
			$sfx/open.play()
		if event.is_action("ui_up") && !event.is_echo() && event.is_pressed():
			$sfx/open.play()
		if event.is_action("ui_accept") && !event.is_echo() && event.is_pressed():
			$sfx/select.play()
func _on_quit():
	get_tree().change_scene("res://scenes/landing.tscn")
	
func attack(recruit_allowed = false):
	active = true
	call_deferred("close_health")
	call_deferred("close_stats")
	$attack.show()
	$attack.recruit_allowed(recruit_allowed)

func turn(type):
#	call_deferred("back")
	active = true
	print("display next turn ui")
	match type:
		Game.CONTROL.PLAYER:
			$playerturn.reset()
			$playerturn.show()
		Game.CONTROL.AI:
			$enemyturn.reset()
			$enemyturn.show()

func credits():
	active = true
	$credits.show()

func close_attack():
	active = false
	$attack.hide()

func team_select(characters):
	modal = true
	$characterselect.set_characters(characters)
	$characterselect.show()

func intro(description):
	$intro.display(description)

func error(message):
	$error/denied.play()
	$error.notify(message)

func stats(friendly, enemy):
	if $healthpage.visible:
		return
	$stats.set_entities(friendly, enemy)
	$stats.show()

func loot(current, new):
	active = true
	$weaponswap.set_weapons(current, new)
	$weaponswap.show()

func health(friendly, enemy):
	print(enemy.character.hp)
	print(enemy.character.max_hp)
	$healthpage.set_entities(friendly.character, enemy.character)
	$healthpage.show()

func team_confirm():
	active = true
	$teamconfirm.show()

func win():
	active = true
	$win.reset()
	$win.show()

func lose():
	active = true
	$lose.show()

func close_health():
	$healthpage.hide()

func close_stats():
	$stats.hide()

func options():
	active = true
	$pause.visible = false
	$Options.visible = true

func close_options():
	yield(get_tree().create_timer(0.1), "timeout")
	back()

func guard(is_healer = false):
	active = true
	$guard.set_healer(is_healer)
	$guard.call_deferred("show")

func pause():
	$sfx/select.play()
	active = true
	$pause.show()

func close(dialog):
	active = false
	get_node(dialog).hide()

func back():
#	print("hide all the things")
	active = false
	var dialogs = get_children()
	for dialog in dialogs:
		if dialog != $error and dialog != $playerturn and dialog != $enemyturn and dialog.name != "sfx":
			dialog.hide()


