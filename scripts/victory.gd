extends Control

@onready var restart_button: Button = $VBoxContainer/RestartButton
@onready var quit_button: Button = $VBoxContainer/QuitButton
@onready var character_anim: AnimatedSprite2D = $CenterContainer/CharacterAnim

func _ready() -> void:
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	if character_anim and character_anim.sprite_frames:
		if character_anim.sprite_frames.has_animation("idle"):
			character_anim.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R or event.keycode == KEY_R:
			_on_restart_pressed()
		elif event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			_on_quit_pressed()

func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
