extends CharacterBody2D

@export_category("移动参数")
@export var double_press_interval := 0.3
@export var move_speed: float = 75.0
@export var acceleration: float = 600.0
@export var deceleration: float = 800.0
@export var jump_velocity: float = -190.0


@onready var sprite: Sprite2D = $Sprite2D

@export_group("冲刺技能")
@export var dash_speed: float = 200.0
@export var dash_doration:float = 0.5 #冲刺持时间
@export var dash_cooltime:float = 1.0 

var is_dashing : bool = false
var can_dash : bool = true #是否冷却
var dash_direction: Vector2 = Vector2.ZERO # 冲刺朝向

var flying : bool = false
var last_space_press_time := -1000

func _physics_process(delta: float) -> void:
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
		return
	
	if !flying:
		apply_gravity(delta)
		handle_jump()
	else:
		handle_vertical_movement(delta)
	
	handle_horizontal_movement(delta)
	handle_shift_pressed()
	update_sprite_direction()
	move_and_slide()

func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

func handle_vertical_movement(delta:float) -> void:
	var direction := Input.get_axis("squat", "jump")
	var target_speed := direction * jump_velocity
	
	if direction != 0.0:
		velocity.y = move_toward(
				velocity.y,
				target_speed,
				acceleration * delta
		)
	else:
		velocity.y = move_toward(
				velocity.y,
				0.0,
				acceleration * delta
		)
	
func handle_horizontal_movement(delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	var target_speed := direction * move_speed

	if direction != 0.0:
		velocity.x = move_toward(
				velocity.x,
				target_speed,
				acceleration * delta
		)
	else:
		velocity.x = move_toward(
				velocity.x,
				0.0,
				deceleration * delta
		)

func handle_jump() -> void:
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

func update_sprite_direction() -> void:
	if velocity.x != 0.0:
		sprite.flip_h = velocity.x < 0.0
		
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

func handle_shift_pressed() -> void:
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()
		
func start_dash():
	is_dashing = true
	can_dash = false
	
	var diraction: = Input.get_axis("move_left","move_right")
	if diraction != 0:
		dash_direction = Vector2(diraction, 0).normalized()
	else:
		#转向翻转
		dash_direction = Vector2.LEFT if sprite.flip_h else Vector2.RIGHT
	await get_tree().create_timer(dash_doration).timeout
	is_dashing = false
	
	await get_tree().create_timer(dash_cooltime).timeout
	can_dash = true
