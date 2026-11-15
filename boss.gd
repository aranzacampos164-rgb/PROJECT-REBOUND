extends Area2D

signal defeated(pos: Vector2)

const Projectile = preload("res://projectile.gd")
const SpriteUtil = preload("res://sprite_util.gd")

const FRAME := 64
const SPRITE_ROW := 3
const SPRITE_SCALE := 6.5
const ART_BOTTOM := 42.0
const HALF_W := 110.0
const MUZZLE_Y := -120.0
const SLIME_SHEETS := {"centura": "slime1", "astra": "slime2", "ventura": "slime3"}
const BODY_SIZES := {
	"centura": Vector2(205.0, 165.0),
	"astra": Vector2(218.0, 218.0),
	"ventura": Vector2(218.0, 250.0),
}

var kind := "centura"
var max_hp := 10
var hp := 10
var left_x := 0.0
var right_x := 0.0
var dir := 1
var fire_cd := 2.0
var flash := 0.0
var dead := false
var sprite: AnimatedSprite2D
var body_size := Vector2(210, 200)


func setup(k: String, pos: Vector2, lx: float, rx: float, health: int) -> void:
	kind = k
	position = pos
	left_x = lx
	right_x = rx
	max_hp = health
	hp = health


func _ready() -> void:
	add_to_group("boss")
	body_size = BODY_SIZES.get(kind, body_size)
	var cs := CollisionShape2D.new()
	var r := RectangleShape2D.new()
	r.size = body_size
	cs.shape = r
	cs.position = Vector2(0, -body_size.y * 0.5)
	add_child(cs)

	var sheet: String = SLIME_SHEETS.get(kind, "slime1")
	var frames := SpriteUtil.new_frames()
	SpriteUtil.add_anim(frames, "walk", load("res://sprites/%s_walk.png" % sheet), FRAME, FRAME, SPRITE_ROW, 8, 8.0, true)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.position = Vector2(0, (FRAME * 0.5 - ART_BOTTOM) * SPRITE_SCALE)
	add_child(sprite)
	sprite.play("walk")


func _speed() -> float:
	match kind:
		"astra":
			return 130.0
		"ventura":
			return 110.0
	return 80.0


func _fire_interval() -> float:
	match kind:
		"astra":
			return 1.4
		"ventura":
			return 1.1
	return 1.8


func _physics_process(delta: float) -> void:
	if dead:
		return
	flash = max(flash - delta, 0.0)

	position.x += dir * _speed() * delta
	if position.x > right_x - HALF_W:
		position.x = right_x - HALF_W
		dir = -1
	elif position.x < left_x + HALF_W:
		position.x = left_x + HALF_W
		dir = 1
	if sprite:
		sprite.modulate = Color(3.0, 3.0, 3.0) if flash > 0.0 else Color.WHITE
		sprite.flip_h = dir < 0

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player and absf(player.global_position.x - global_position.x) < 1000.0:
		fire_cd -= delta
		if fire_cd <= 0.0:
			fire_cd = _fire_interval()
			_shoot(player)

	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			b.hurt(1, global_position.x)

	queue_redraw()


func _shoot(player: Node2D) -> void:
	var muzzle := global_position + Vector2(0, MUZZLE_Y)
	var aim := (player.global_position + Vector2(0, -24) - muzzle).normalized()
	var angles: Array = [0.0]
	var spd := 300.0
	if kind != "centura":
		angles = [-0.25, 0.0, 0.25]
		spd = 340.0
	Sfx.play("explosion", -6.0)
	for a in angles:
		var p := Projectile.new()
		get_parent().add_child(p)
		p.setup(muzzle, aim.rotated(a) * spd, false)


func hit(dmg: int) -> void:
	if dead:
		return
	hp -= dmg
	flash = 0.1
	if hp <= 0:
		dead = true
		defeated.emit(global_position)
		queue_free()


func _draw() -> void:
	var frac := float(hp) / float(max_hp)
	var bar_y := -body_size.y - 20.0
	draw_rect(Rect2(-120, bar_y, 240, 14), Color(0.1, 0.1, 0.1, 0.85))
	draw_rect(Rect2(-120, bar_y, 240.0 * frac, 14), Color(0.9, 0.2, 0.2))
