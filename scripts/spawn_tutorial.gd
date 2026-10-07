extends Label

@export var spawn_pos: Vector2 = Vector2(107, 139)
@export var fade_distance: float = 120.0

var player: Node2D = null
var is_visible_state: bool = false
var current_tween: Tween = null

func _ready() -> void:
	modulate.a = 0.0
	fade_in()

func _process(_delta: float) -> void:
	if not player:
		player = get_node_or_null("../ActorsAndCharacters/Player")
		if not player:
			return
			
	var dist = player.global_position.distance_to(spawn_pos)
	if dist <= fade_distance:
		if not is_visible_state:
			fade_in()
	else:
		if is_visible_state:
			fade_out()

func fade_in() -> void:
	is_visible_state = true
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(self, "modulate:a", 1.0, 0.4)

func fade_out() -> void:
	is_visible_state = false
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	current_tween = create_tween()
	current_tween.tween_property(self, "modulate:a", 0.0, 0.4)
