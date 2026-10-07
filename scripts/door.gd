extends Area2D

@export_file("*.tscn") var next_scene_path: String = ""
@export var prompt_text: String = "[F] 进入下一关"

@onready var prompt_label: Label = $PromptLabel
@onready var sprite: Sprite2D = $Sprite2D

var player_in_range: bool = false
var prompt_base_y: float = 0.0
var time_elapsed: float = 0.0
var is_transitioning: bool = false

func _ready() -> void:
	# 连接进入和离开碰撞信号
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	if prompt_label:
		prompt_label.text = prompt_text
		prompt_label.visible = false
		prompt_base_y = prompt_label.position.y

func _process(delta: float) -> void:
	if player_in_range and not is_transitioning:
		if Input.is_action_just_pressed("interact") or Input.is_key_pressed(KEY_F):
			enter_next_level()
			return
		if prompt_label and prompt_label.visible:
			time_elapsed += delta * 4.0
			# 提示文字轻微上下浮动效果
			prompt_label.position.y = prompt_base_y + sin(time_elapsed) * 2.0

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_transitioning:
		return
		
	# 支持系统映射的 interact 动作以及直接按下 F 键，确保 100% 触发
	var f_pressed = false
	if event.is_action_pressed("interact") and not event.is_echo():
		f_pressed = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F or event.keycode == KEY_F:
			f_pressed = true
			
	if f_pressed:
		enter_next_level()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D or body.name == "Player":
		player_in_range = true
		if prompt_label:
			prompt_label.visible = true
			time_elapsed = 0.0

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D or body.name == "Player":
		player_in_range = false
		if prompt_label:
			prompt_label.visible = false

func enter_next_level() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	
	# 轻微的高亮闪烁反馈
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.1)
	
	if next_scene_path != "" and ResourceLoader.exists(next_scene_path):
		await get_tree().create_timer(0.15).timeout
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("未指定下一关场景或场景不存在: ", next_scene_path)
		is_transitioning = false
