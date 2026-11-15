extends Node2D


signal collected

const SpriteUtil = preload("res://sprite_util.gd")
const ShardPickup = preload("res://shard_pickup.gd")

const SHEET := preload("res://sprites/chest_sheet.png")
const FRAME_W := 53
const FRAME_H := 32
const OPEN_FRAMES := 21
const SCALE := 2.6

var sprite: AnimatedSprite2D
var shard
var opened := false


func _ready() -> void:
	var frames := SpriteUtil.new_frames()
	SpriteUtil.add_anim(frames, "closed", SHEET, FRAME_W, FRAME_H, 0, 1, 1.0, true)
	SpriteUtil.add_anim(frames, "open", SHEET, FRAME_W, FRAME_H, 0, OPEN_FRAMES, 13.0, false)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(SCALE, SCALE)
	sprite.flip_h = true
	sprite.position = Vector2(0, -float(FRAME_H) * SCALE * 0.5)
	add_child(sprite)
	sprite.play("closed")
	sprite.animation_finished.connect(_on_animation_finished)
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		open()


func open() -> void:
	if opened:
		return
	opened = true
	sprite.play("open")


func _on_animation_finished() -> void:
	if opened and sprite.animation == "open":
		_release_shard()


func _release_shard() -> void:
	shard = ShardPickup.new()
	shard.position = Vector2(0, -52.0)
	shard.scale = Vector2(0.4, 0.4)
	add_child(shard)
	shard.taken.connect(_on_shard_taken)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(shard, "position", Vector2(0, -140.0), 0.95).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(shard, "scale", Vector2.ONE, 0.95).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_shard_taken() -> void:
	collected.emit()
