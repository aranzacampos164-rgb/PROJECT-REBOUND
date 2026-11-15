extends Area2D


signal taken

const SHARD_TEX := preload("res://sprites/shard.png")
const ART_SCALE := 0.26

var _sprite: Sprite2D
var _glow: Sprite2D
var _t := 0.0
var _picked := false


func _ready() -> void:
	z_index = 6
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 34.0
	cs.shape = shape
	add_child(cs)

	_glow = Sprite2D.new()
	_glow.texture = SHARD_TEX
	_glow.scale = Vector2(ART_SCALE * 1.5, ART_SCALE * 1.5)
	_glow.modulate = Color(0.35, 0.8, 1.0, 0.3)
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	add_child(_glow)

	_sprite = Sprite2D.new()
	_sprite.texture = SHARD_TEX
	_sprite.scale = Vector2(ART_SCALE, ART_SCALE)
	_sprite.rotation = -0.35
	add_child(_sprite)

	var bob := create_tween().set_loops()
	bob.tween_property(_sprite, "position:y", -6.0, 1.1).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_sprite, "position:y", 3.0, 1.1).set_trans(Tween.TRANS_SINE)

	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	var pulse := 0.5 + 0.5 * sin(_t * 2.8)
	_glow.modulate.a = 0.18 + 0.24 * pulse
	var g := ART_SCALE * (1.35 + 0.2 * pulse)
	_glow.scale = Vector2(g, g)
	_sprite.rotation = -0.35 + 0.08 * sin(_t * 1.6)


func _on_body_entered(body: Node) -> void:
	if _picked or not body.is_in_group("player"):
		return
	_picked = true
	taken.emit()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.25)
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.chain().tween_callback(queue_free)
