extends Control


const PixelFont = preload("res://pixel_font.gd")
const UiKit = preload("res://ui_kit.gd")
const SHARD_TEX := preload("res://sprites/shard.png")

const LIFE := 2.1

var count := 1
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var appear := clampf(_t / 0.22, 0.0, 1.0)
	var gone := clampf((LIFE - _t) / 0.3, 0.0, 1.0)
	var a := minf(appear, gone)
	var eased := 1.0 - pow(1.0 - appear, 3.0)
	var w := 540.0
	var h := 100.0
	var r := Rect2((size.x - w) * 0.5, size.y * 0.15 - 26.0 * (1.0 - eased), w, h)
	UiKit.frame(self, r, 5.0, Color(0.03, 0.09, 0.14, 0.94 * a), Color(0.55, 0.95, 1.0, a), Color(0.1, 0.35, 0.5, a))

	draw_texture_rect(SHARD_TEX, Rect2(r.position + Vector2(20, 20), Vector2(60, 60)), false, Color(1, 1, 1, a))
	PixelFont.draw_text(self, "SHARD ACQUIRED", r.position + Vector2(98, 20), 4.0, Color(1.0, 1.0, 1.0, a))

	var frac := "%d / 3" % count
	PixelFont.draw_text(self, frac, Vector2(r.end.x - 28.0 - PixelFont.text_width(frac, 5.0), r.position.y + 18.0), 5.0, Color(1.0, 0.85, 0.35, a))

	for i in 3:
		var pip := Rect2(r.position + Vector2(98 + i * 26, 64), Vector2(16, 16))
		var filled := i < count
		draw_rect(pip, Color(1.0, 0.85, 0.35, a) if filled else Color(0.18, 0.3, 0.38, a))
