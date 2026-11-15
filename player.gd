extends CharacterBody2D

signal died

const Projectile = preload("res://projectile.gd")
const SpriteUtil = preload("res://sprite_util.gd")

const SPEED := 260.0
const ACCEL := 1800.0
const GRAVITY := 1400.0
const JUMP_VELOCITY := -520.0
const COYOTE_TIME := 0.1
const JUMP_BUFFER := 0.12
const MAX_HEALTH := 5

const FRAME := 128
const SPRITE_SCALE := 2.0

var health := MAX_HEALTH
var facing := 1
var coyote := 0.0
var jump_buffer := 0.0
var invuln := 0.0
var shoot_cd := 0.0
var shoot_anim := 0.0
var pulse_flash := 0.0
var short_hop_allowed := false
var spawn_point := Vector2.ZERO
var fall_limit := 1000.0
var cam: Camera2D
var sprite: AnimatedSprite2D


func _ready() -> void:
	add_to_group("player")
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 68)
	cs.shape = rect
	cs.position = Vector2(0, -34)
	add_child(cs)

	var tex: Texture2D = load("res://sprites/hero.png")
	var frames := SpriteUtil.new_frames()
	SpriteUtil.add_anim(frames, "idle", tex, FRAME, FRAME, 1, 10, 10.0, true)
	SpriteUtil.add_anim(frames, "walk", tex, FRAME, FRAME, 2, 10, 14.0, true)
	SpriteUtil.add_anim(frames, "run", tex, FRAME, FRAME, 3, 10, 18.0, true)
	SpriteUtil.add_anim(frames, "jump", tex, FRAME, FRAME, 4, 6, 12.0, false)
	SpriteUtil.add_anim(frames, "fall", tex, FRAME, FRAME, 5, 3, 8.0, true)
	SpriteUtil.add_anim(frames, "slash", tex, FRAME, FRAME, 6, 3, 12.0, false)
	SpriteUtil.add_anim(frames, "shoot", tex, FRAME, FRAME, 7, 4, 16.0, false)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.position = Vector2(0, -32)
	add_child(sprite)
	sprite.play("idle")

	cam = Camera2D.new()
	cam.position = Vector2(0, -70)
	cam.position_smoothing_enabled = true
	add_child(cam)
	cam.make_current()


func set_limits(l: int, t: int, r: int, b: int) -> void:
	cam.limit_left = l
	cam.limit_top = t
	cam.limit_right = r
	cam.limit_bottom = b


func _physics_process(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		facing = 1 if dir > 0.0 else -1
	velocity.x = move_toward(velocity.x, dir * SPEED, ACCEL * delta)
	velocity.y += GRAVITY * delta

	if is_on_floor():
		coyote = COYOTE_TIME
	else:
		coyote -= delta

	if Input.is_action_just_pressed("jump"):
		jump_buffer = JUMP_BUFFER
	else:
		jump_buffer -= delta

	if jump_buffer > 0.0 and coyote > 0.0:
		velocity.y = JUMP_VELOCITY
		jump_buffer = 0.0
		coyote = 0.0
		short_hop_allowed = true

	if Input.is_action_just_released("jump") and short_hop_allowed and velocity.y < -200.0:
		velocity.y *= 0.5
		short_hop_allowed = false

	invuln = max(invuln - delta, 0.0)
	shoot_cd = max(shoot_cd - delta, 0.0)
	shoot_anim = max(shoot_anim - delta, 0.0)
	pulse_flash = max(pulse_flash - delta, 0.0)

	if Input.is_action_just_pressed("shoot") and shoot_cd <= 0.0:
		_fire()
		shoot_cd = 0.25

	move_and_slide()

	if global_position.y > fall_limit:
		_fell()

	_update_animation()
	queue_redraw()


func _update_animation() -> void:
	sprite.flip_h = facing < 0
	sprite.position.x = 4.0 * facing
	sprite.visible = not (invuln > 0.0 and int(invuln * 12.0) % 2 == 0)

	var want := "idle"
	if shoot_anim > 0.0:
		want = "shoot"
	elif not is_on_floor():
		want = "jump" if velocity.y < 0.0 else "fall"
	elif absf(velocity.x) > 180.0:
		want = "run"
	elif absf(velocity.x) > 20.0:
		want = "walk"
	if sprite.animation != want:
		sprite.play(want)


func pulse() -> void:
	pulse_flash = 0.4
	short_hop_allowed = false


func hurt(dmg: int, from_x: float) -> void:
	if invuln > 0.0:
		return
	health -= dmg
	invuln = 1.2
	velocity = Vector2(signf(global_position.x - from_x) * 280.0, -320.0)
	if health <= 0:
		health = MAX_HEALTH
		Sfx.play("lose_life", -4.0)
		_respawn()
		died.emit()
	else:
		Sfx.play("hurt", -6.0)


func _fell() -> void:
	health -= 1
	if health <= 0:
		health = MAX_HEALTH
		Sfx.play("lose_life", -4.0)
	invuln = 1.0
	_respawn()


func _respawn() -> void:
	global_position = spawn_point
	velocity = Vector2.ZERO


func _fire() -> void:
	shoot_anim = 0.25
	sprite.play("shoot")
	sprite.frame = 0
	Sfx.play("shoot", -10.0)
	var p := Projectile.new()
	get_parent().add_child(p)
	p.setup(global_position + Vector2(facing * 40, -34), Vector2(facing * 640.0, 0.0), true)


func _draw() -> void:
	if pulse_flash > 0.0:
		draw_circle(Vector2(0, -4), 26.0, Color(0.3, 0.9, 1.0, 0.35))
