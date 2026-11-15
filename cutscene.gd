extends Control

signal finished

const PixelFont = preload("res://pixel_font.gd")
const UiKit = preload("res://ui_kit.gd")
const SpriteUtil = preload("res://sprite_util.gd")

const ROCKET_SHEET := "res://sprites/rocket_sheet.png"
const ROCKET_COLS := 6
const ROCKET_COUNT := 52
const ROCKET_CELL := Vector2(500.0, 250.0)
const TEXT_PX := 4.0
const TYPE_SPEED := 48.0
const TRAVEL_HOLD := 1.7

const WHITE := Color(1.0, 1.0, 1.0)
const GREY := Color(0.75, 0.75, 0.75)

var pages: Array = []
var mode := "intro"
var header := ""

var _page := 0
var _lines := PackedStringArray()
var _chars := 0
var _reveal := 0.0
var _t := 0.0
var _phase := 0
var _phase_t := 0.0
var _hold := 0.0
var _flash := 0.0
var _done := false
var _zoom := 1.0
var _spin := 0.0
var _shake := 0.0
var _rocket: AnimatedSprite2D
var _ui: Control


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if pages.is_empty():
		pages = [""]
	if mode != "ending":
		_build_rocket()
	_ui = Control.new()
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.draw.connect(_draw_ui)
	_show_page(0)
	resized.connect(_on_resized)
	_fit_rocket()


func _on_resized() -> void:
	_show_page(_page)
	_fit_rocket()


func _build_rocket() -> void:
	if not ResourceLoader.exists(ROCKET_SHEET):
		return
	var frames := SpriteUtil.new_frames()
	SpriteUtil.add_grid_anim(frames, "fly", load(ROCKET_SHEET), int(ROCKET_CELL.x), int(ROCKET_CELL.y), ROCKET_COLS, ROCKET_COUNT, 30.0, true)
	_rocket = AnimatedSprite2D.new()
	_rocket.sprite_frames = frames
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_rocket.material = mat
	add_child(_rocket)
	_rocket.play("fly")


func _fit_rocket() -> void:
	if _rocket == null:
		return
	var view := size
	if view.x <= 0.0 or view.y <= 0.0:
		view = get_viewport_rect().size
	var fill := maxf(view.x / ROCKET_CELL.x, view.y / ROCKET_CELL.y)
	var s := fill * _zoom
	var off := Vector2(randf_range(-_shake, _shake), randf_range(-_shake, _shake))
	_rocket.position = view * 0.5 + off
	_rocket.scale = Vector2(s, s)
	_rocket.rotation = _spin


func _box() -> Rect2:
	var w := size.x * 0.86
	var h := size.y * 0.30
	return Rect2((size.x - w) * 0.5, size.y - h - size.y * 0.045, w, h)


func _show_page(i: int) -> void:
	_page = i
	_lines = PixelFont.wrap(str(pages[i]), TEXT_PX, _box().size.x - 60.0)
	_chars = PixelFont.char_count(_lines)
	_reveal = 0.0
	_hold = 0.0


func _progress() -> float:
	var typed := minf(_reveal / maxf(float(_chars), 1.0), 1.0)
	return clampf((float(_page) + typed) / float(pages.size()), 0.0, 1.0)


func _process(delta: float) -> void:
	_t += delta
	_flash = maxf(_flash - delta * 2.2, 0.0)
	if _phase == 0:
		_reveal += TYPE_SPEED * delta
		if _rocket:
			if mode == "travel":
				_rocket.speed_scale = 1.0 + _progress() * 1.6
				_zoom = 1.0 + 0.02 * sin(_t * 0.9)
			else:
				_zoom = 1.0 + 0.012 * sin(_t * 0.8)
		if mode == "travel" and _reveal >= float(_chars):
			_hold += delta
			if _hold > TRAVEL_HOLD:
				_next_or_warp()
	elif _phase == 1:
		_phase_t += delta
		var p := clampf(_phase_t / 2.3, 0.0, 1.0)
		_zoom = 1.0 + p * p * 0.55
		_spin = sin(_phase_t * 3.0) * 0.05 * p + p * 0.12
		_shake = p * 14.0
		if _rocket:
			_rocket.speed_scale = 1.0 + p * 2.0
			_rocket.modulate = Color(1.0, 1.0 - p * 0.55, 1.0 - p * 0.75)
		if _phase_t > 2.3:
			_impact()
	elif _phase == 3:
		_phase_t += delta
		_zoom = 1.0 + _phase_t * 0.9
		if _rocket:
			_rocket.speed_scale = 3.5
		if _phase_t > 0.7 and not _done:
			_finish()
	else:
		_phase_t += delta
		if _phase_t > 2.6 and not _done:
			_finish()
	_fit_rocket()
	_ui.queue_redraw()


func _next_or_warp() -> void:
	if _page + 1 < pages.size():
		_show_page(_page + 1)
	else:
		_begin_warp()


func _advance() -> void:
	if _phase != 0:
		return
	if _reveal < float(_chars):
		_reveal = float(_chars)
		return
	if mode == "travel":
		_next_or_warp()
		return
	if _page + 1 < pages.size():
		_show_page(_page + 1)
	elif mode == "intro":
		_begin_crash()
	else:
		_finish()


func _begin_crash() -> void:
	_phase = 1
	_phase_t = 0.0


func _begin_warp() -> void:
	if _phase == 3:
		return
	_phase = 3
	_phase_t = 0.0
	_flash = 1.0


func _impact() -> void:
	_phase = 2
	_phase_t = 0.0
	_flash = 1.0
	_shake = 0.0
	if _rocket:
		_rocket.visible = false
		_rocket.stop()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()


func _draw_ui() -> void:
	var full := Rect2(Vector2.ZERO, _ui.size)
	UiKit.scanlines(_ui, full, 4.0, Color(0.0, 0.0, 0.0, 0.18))
	if _flash > 0.0:
		var tint := Color(1.0, 1.0, 1.0, _flash * 0.85) if mode == "travel" else Color(1.0, 0.93, 0.78, _flash * 0.85)
		_ui.draw_rect(full, tint)
		if mode != "travel":
			for i in 7:
				var y := fmod(_t * 900.0 + float(i) * 137.0, _ui.size.y)
				_ui.draw_rect(Rect2(0, y, _ui.size.x, 2.0), Color(1.0, 0.6, 0.3, _flash * 0.5))
	if _phase == 0:
		if mode == "travel":
			_draw_travel_header()
		_draw_box()
	elif _phase == 2:
		_draw_impact_card()


func _draw_travel_header() -> void:
	var left := 60.0
	var width := _ui.size.x - 120.0
	PixelFont.draw_text(_ui, header, Vector2(left, 44.0), 3.0, WHITE, false, Color(0, 0, 0, 0.7))
	var pct := "%d%%" % int(_progress() * 100.0)
	PixelFont.draw_text(_ui, pct, Vector2(left + width - PixelFont.text_width(pct, 3.0), 44.0), 3.0, WHITE, false, Color(0, 0, 0, 0.7))
	var bar := Rect2(left, 84.0, width, 16.0)
	UiKit.bar(_ui, bar, _progress(), Color(1.0, 1.0, 1.0, 0.9), Color(0.0, 0.0, 0.0, 0.6))
	UiKit.frame(_ui, Rect2(bar.position - Vector2(4, 4), bar.size + Vector2(8, 8)), 2.0, Color(0, 0, 0, 0), Color(0.75, 0.75, 0.75), Color(0.35, 0.35, 0.35))


func _draw_box() -> void:
	var b := _box()
	UiKit.frame(_ui, b, 6.0, Color(0.02, 0.03, 0.06, 0.93), Color(0.85, 0.85, 0.9), Color(0.3, 0.3, 0.36))
	PixelFont.draw_block(_ui, _lines, b.position + Vector2(30, 30), TEXT_PX, WHITE, _reveal, false, Color(0.0, 0.0, 0.0, 0.65))

	var counter := "%d/%d" % [_page + 1, pages.size()]
	PixelFont.draw_text(_ui, counter, Vector2(b.end.x - 30.0 - PixelFont.text_width(counter, 2.0), b.position.y - 22.0), 2.0, GREY, false, Color(0, 0, 0, 0.6))

	if _reveal >= float(_chars):
		var tip := Vector2(b.end.x - 44.0, b.end.y - 26.0 + sin(_t * 6.0) * 3.0)
		if int(_t * 3.0) % 2 == 0:
			_ui.draw_colored_polygon(PackedVector2Array([tip, tip + Vector2(18, 0), tip + Vector2(9, 10)]), WHITE)
		PixelFont.draw_text(_ui, "ENTER", Vector2(b.position.x + 30.0, b.end.y - 30.0), 2.0, GREY)


func _draw_impact_card() -> void:
	var fade := clampf(_phase_t / 0.3, 0.0, 1.0)
	var cx := _ui.size.x * 0.5
	PixelFont.draw_centered(_ui, PackedStringArray(["CENTURA"]), cx, _ui.size.y * 0.34, 11.0, Color(1.0, 0.86, 0.64, fade), true, Color(0.4, 0.09, 0.02, fade))
	PixelFont.draw_centered(_ui, PackedStringArray(["IMPACT SITE // HULL BREACH"]), cx, _ui.size.y * 0.54, 3.0, Color(0.95, 0.6, 0.35, fade))
	PixelFont.draw_centered(_ui, PackedStringArray(["SURFACE TEMP 41C // CORE SIGNAL LOST"]), cx, _ui.size.y * 0.60, 2.0, Color(0.7, 0.45, 0.35, fade))


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_advance()
			accept_event()
		elif event.keycode == KEY_ESCAPE and mode == "travel":
			_begin_warp()
			accept_event()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance()
		accept_event()
