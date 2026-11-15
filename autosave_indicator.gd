extends Control

const PixelFont = preload("res://pixel_font.gd")
const UiKit = preload("res://ui_kit.gd")
const ICON := preload("res://sprites/save_icon.png")

const LIFE := 2.0
const ICON_PX := 3.0
const MARGIN := 28.0

var _t := LIFE


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.autosaved.connect(_on_autosaved)


func _on_autosaved() -> void:
	_t = 0.0
	visible = true


func _process(delta: float) -> void:
	if _t < LIFE:
		_t += delta
		queue_redraw()
	elif visible:
		visible = false


func _draw() -> void:
	if _t >= LIFE:
		return
	var a := minf(clampf(_t / 0.15, 0.0, 1.0), clampf((LIFE - _t) / 0.35, 0.0, 1.0))
	var px := 2.0
	var label := "AUTOSAVING" + ".".repeat(int(_t * 4.0) % 4)
	var full_label := "AUTOSAVING..."
	var text_w := PixelFont.text_width(full_label, px)
	var icon_size := float(ICON.get_width()) * ICON_PX
	var gap := 14.0
	var pad := 14.0
	var box_w := pad * 2.0 + icon_size + gap + text_w
	var box_h := pad * 2.0 + icon_size
	var box := Rect2(size.x - MARGIN - box_w, size.y - MARGIN - box_h, box_w, box_h)
	UiKit.frame(self, box, 3.0, Color(0.02, 0.03, 0.06, 0.88 * a), Color(0.85, 0.85, 0.9, a), Color(0.3, 0.3, 0.36, a))

	var center := (box.position + Vector2(pad + icon_size * 0.5, box_h * 0.5)).floor() + Vector2(0.5, 0.5)
	var turn := int(_t * 5.0) % 4
	draw_set_transform(center, float(turn) * PI * 0.5, Vector2.ONE)
	draw_texture_rect(ICON, Rect2(Vector2(-icon_size * 0.5, -icon_size * 0.5), Vector2(icon_size, icon_size)), false, Color(1.0, 1.0, 1.0, a))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	var ty := box.position.y + (box_h - PixelFont.line_height(px) + px * 2.0) * 0.5
	PixelFont.draw_text(self, label, Vector2(box.position.x + pad + icon_size + gap, ty), px, Color(1.0, 1.0, 1.0, a))
