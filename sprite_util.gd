extends RefCounted


static func new_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	return frames


static func add_anim(frames: SpriteFrames, anim: String, tex: Texture2D, fw: int, fh: int, row: int, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2(i * fw, row * fh, fw, fh)
		frames.add_frame(anim, at)


static func add_grid_anim(frames: SpriteFrames, anim: String, tex: Texture2D, fw: int, fh: int, cols: int, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, loop)
	for i in count:
		var at := AtlasTexture.new()
		at.atlas = tex
		at.region = Rect2((i % cols) * fw, (i / cols) * fh, fw, fh)
		frames.add_frame(anim, at)
