extends CharacterBody2D

@export_category("移动参数")
@export var double_press_interval := 0.3
@export var move_speed: float = 85.0
@export var acceleration: float = 600.0
@export var deceleration: float = 800.0
@export var jump_velocity: float = -200.0

@export_group("冲刺技能 (Dash)")
@export var dash_speed: float = 240.0
@export var dash_duration: float = 0.35 # 冲刺持续时间
@export var dash_cooldown: float = 0.6  # 冲刺冷却时间

@export_group("战斗技能 (Attack & Skill)")
@export var skill_e_speed: float = 180.0
@export var skill_e_duration: float = 0.4
@export var skill_e_cooldown: float = 1.2

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var legacy_sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

var is_dashing: bool = false
var can_dash: bool = true
var dash_direction: Vector2 = Vector2.ZERO

var is_attacking: bool = false
var is_using_skill: bool = false
var can_skill_e: bool = true

var flying: bool = false
var last_space_press_time := -1000
var spawn_position: Vector2 = Vector2.ZERO
var coins_collected: int = 0

func _ready() -> void:
	spawn_position = global_position
	
	# 连接互动区域信号 (如果有 InteractionArea)
	if has_node("InteractionArea"):
		var area: Area2D = $InteractionArea
		area.area_entered.connect(_on_interaction_area_entered)

func _physics_process(delta: float) -> void:
	# 跌落悬崖自动重生
	if global_position.y > 320.0:
		respawn()
		return

	# 1. 冲刺状态
	if is_dashing:
		velocity = dash_direction * dash_speed
		update_visuals()
		move_and_slide()
		return

	# 2. 技能释放状态
	if is_using_skill:
		velocity.x = (1.0 if not is_facing_left() else -1.0) * skill_e_speed
		apply_gravity(delta)
		update_visuals()
		move_and_slide()
		return

	# 3. 普攻状态
	if is_attacking:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)
		apply_gravity(delta)
		update_visuals()
		move_and_slide()
		return

	# 4. 常规移动与飞行
	if !flying:
		apply_gravity(delta)
		handle_jump()
	else:
		handle_vertical_movement(delta)

	handle_horizontal_movement(delta)
	handle_dash_input()
	handle_combat_input()
	update_visuals()
	move_and_slide()

func is_facing_left() -> bool:
	if animated_sprite:
		return animated_sprite.flip_h
	elif legacy_sprite:
		return legacy_sprite.flip_h
	return false

func set_facing_left(face_left: bool) -> void:
	if animated_sprite:
		animated_sprite.flip_h = face_left
	if legacy_sprite:
		legacy_sprite.flip_h = face_left

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_vertical_movement(delta: float) -> void:
	var direction := Input.get_axis("squat", "jump")
	var target_speed := direction * jump_velocity

	if direction != 0.0:
		velocity.y = move_toward(velocity.y, target_speed, acceleration * delta)
	else:
		velocity.y = move_toward(velocity.y, 0.0, acceleration * delta)

func handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * move_speed

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, target_speed, acceleration * delta)
		set_facing_left(direction < 0.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

func handle_dash_input() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()

func start_dash() -> void:
	is_dashing = true
	can_dash = false

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		dash_direction = Vector2(direction, 0).normalized()
		set_facing_left(direction < 0.0)
	else:
		dash_direction = Vector2.LEFT if is_facing_left() else Vector2.RIGHT

	await get_tree().create_timer(dash_duration).timeout
	is_dashing = false

	await get_tree().create_timer(dash_cooldown).timeout
	can_dash = true

func handle_combat_input() -> void:
	# E 技能 (翔风剑 / 灵剑武装)
	if Input.is_action_just_pressed("skill_e") and can_skill_e and not is_using_skill and not is_dashing:
		start_skill_e()
	# 平 A 普攻 (J 键)
	elif Input.is_action_just_pressed("attack") and not is_attacking and not is_using_skill and not is_dashing:
		start_attack()

func start_skill_e() -> void:
	is_using_skill = true
	can_skill_e = false
	if animated_sprite and animated_sprite.sprite_frames.has_animation("skill_e"):
		animated_sprite.play("skill_e")

	await get_tree().create_timer(skill_e_duration).timeout
	is_using_skill = false

	await get_tree().create_timer(skill_e_cooldown).timeout
	can_skill_e = true

func start_attack() -> void:
	is_attacking = true
	if animated_sprite and animated_sprite.sprite_frames.has_animation("attack"):
		animated_sprite.play("attack")

	await get_tree().create_timer(0.35).timeout
	is_attacking = false

func update_visuals() -> void:
	if not animated_sprite:
		return

	# 优先级动画状态机
	if is_dashing:
		if animated_sprite.animation != "dash":
			animated_sprite.play("dash")
	elif is_using_skill:
		if animated_sprite.animation != "skill_e":
			animated_sprite.play("skill_e")
	elif is_attacking:
		if animated_sprite.animation != "attack":
			animated_sprite.play("attack")
	elif flying:
		if animated_sprite.animation != "fly":
			animated_sprite.play("fly")
	elif not is_on_floor():
		if animated_sprite.animation != "fly":
			animated_sprite.play("fly")
	elif abs(velocity.x) > 5.0:
		if animated_sprite.animation != "run":
			animated_sprite.play("run")
	else:
		if animated_sprite.animation != "idle":
			animated_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fly") and !event.is_echo():
		handle_space_pressed()

func handle_space_pressed() -> void:
	var current_time := Time.get_ticks_msec()
	var elapsed_time := current_time - last_space_press_time

	if elapsed_time <= double_press_interval * 1000.0:
		flying = not flying
		last_space_press_time = -1000
	else:
		last_space_press_time = current_time

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector2.ZERO
	flying = false
	is_dashing = false
	is_using_skill = false
	is_attacking = false

func _on_interaction_area_entered(area: Area2D) -> void:
	if area.is_in_group("hazard"):
		respawn()
	elif area.is_in_group("collectible"):
		coins_collected += 1
		area.queue_free()
	elif area.is_in_group("spring"):
		velocity.y = jump_velocity * 1.5
		flying = false
