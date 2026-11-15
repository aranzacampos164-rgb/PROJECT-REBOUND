extends Area2D

var vel := Vector2.ZERO
var from_player := true
var life := 2.5


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 7.0
	cs.shape = c
	add_child(cs)
	body_entered.connect(_on_body)
	area_entered.connect(_on_area)


func setup(pos: Vector2, v: Vector2, player_owned: bool) -> void:
	global_position = pos
	vel = v
	from_player = player_owned
	queue_redraw()


func _physics_process(delta: float) -> void:
	global_position += vel * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_body(body: Node) -> void:
	if body.is_in_group("player"):
		if not from_player:
			body.hurt(1, global_position.x)
			queue_free()
	elif body is StaticBody2D:
		queue_free()


func _on_area(area: Area2D) -> void:
	if from_player and (area.is_in_group("boss") or area.is_in_group("enemy")):
		area.hit(1)
		queue_free()


func _draw() -> void:
	var c := Color(0.4, 0.95, 1.0) if from_player else Color(1.0, 0.5, 0.15)
	draw_circle(Vector2.ZERO, 8.0, c)
	draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
