extends Area2D

const SpriteUtil = preload("res://sprite_util.gd")

const FRAME := 64
const RIGHT_ROW := 3
const SCALE := 2.0

var kind := "slime1"
var left_x := 0.0
var right_x := 0.0
var dir := 1
var speed := 55.0
var dead := false
var sprite: AnimatedSprite2D
var cs: CollisionShape2D


func setup(k: String, pos: Vector2, lx: float, rx: float) -> void:
	kind = k
	position = pos
	left_x = lx
	right_x = rx


func _ready() -> void:
	add_to_group("enemy")
	cs = CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = Vector2(44, 36)
	cs.shape = r
	cs.position = Vector2(0, -18)
	add_child(cs)

	var prefix := "res://sprites/%s_" % kind
	var frames := SpriteUtil.new_frames()
	SpriteUtil.add_anim(frames, "walk", load(prefix + "walk.png"), FRAME, FRAME, RIGHT_ROW, 8, 10.0, true)
	SpriteUtil.add_anim(frames, "death", load(prefix + "death.png"), FRAME, FRAME, RIGHT_ROW, 10, 14.0, false)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(SCALE, SCALE)
	sprite.position = Vector2(-5.0, -20.0)
	sprite.animation_finished.connect(_on_anim_finished)
	add_child(sprite)
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if dead:
		return
	position.x += dir * speed * delta
	if position.x > right_x:
		position.x = right_x
		dir = -1
	elif position.x < left_x:
		position.x = left_x
		dir = 1
	sprite.flip_h = dir < 0
	sprite.position.x = -5.0 * dir

	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			if b.velocity.y > 0.0 and b.global_position.y < global_position.y - 18.0:
				b.velocity.y = -420.0
				b.short_hop_allowed = false
				kill()
				return
			b.hurt(1, global_position.x)


func hit(_dmg: int) -> void:
	kill()


func kill() -> void:
	if dead:
		return
	dead = true
	remove_from_group("enemy")
	cs.set_deferred("disabled", true)
	sprite.play("death")


func _on_anim_finished() -> void:
	if dead:
		queue_free()
