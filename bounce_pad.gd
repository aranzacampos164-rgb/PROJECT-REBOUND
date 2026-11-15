extends Area2D

const POWER := 1000.0
const BOOST := 260.0

var squish := 0.0


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var s := RectangleShape2D.new()
	s.size = Vector2(64, 16)
	cs.shape = s
	add_child(cs)
	body_entered.connect(_on_body)


func _on_body(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var p := POWER
	if Input.is_action_pressed("jump"):
		p += BOOST
	body.velocity.y = -p
	body.pulse()
	squish = 0.25


func _process(delta: float) -> void:
	squish = max(squish - delta, 0.0)
	queue_redraw()


func _draw() -> void:
	var h := 14.0 - squish * 20.0
	draw_rect(Rect2(-32, 8.0 - h, 64, h), Color(0.2, 0.9, 1.0))
	draw_rect(Rect2(-32, 8.0 - h, 64, 4), Color(0.85, 1.0, 1.0))
