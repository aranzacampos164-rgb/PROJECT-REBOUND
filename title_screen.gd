extends Control

signal start_pressed(slot: int)

const PixelFont = preload("res://pixel_font.gd")
const UiKit = preload("res://ui_kit.gd")
const SpriteUtil = preload("res://sprite_util.gd")

const BG := "res://backgrounds/title.png"
const HERO_SHEET := "res://sprites/hero.png"
const LEDGE_CAP := "res://tiles/astra_cap.png"
const LEDGE_FILL := "res://tiles/astra_fill.png"
const TITLE := "PROJECT: REBOUND"

const ROW_W := 560.0
const ROW_H := 64.0
const ROW_GAP := 14.0
const BTN_W := 320.0
const BTN_H := 66.0
const SLOTS := 3
const HERO_FRAME := 128
const HERO_SCALE := 7.0
const LEDGE_SCALE := 3.0

const WHITE := Color(1.0, 1.0, 1.0)
const GREY := Color(0.74, 0.74, 0.74)
const DIM := Color(0.52, 0.52, 0.52)

var stage := 0
var focus := 0
var hover := -1
var confirm_delete := -1
var t := 0.0
var summaries: Array = []

var _bg: TextureRect
var _hero: AnimatedSprite2D
var _ledge_cap: Texture2D
var _ledge_fill: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if ResourceLoader.exists(BG):
		_bg = TextureRect.new()
		_bg.texture = load(BG)
		_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		_bg.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_bg.show_behind_parent = true
		add_child(_bg)
		_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists(LEDGE_CAP) and ResourceLoader.exists(LEDGE_FILL):
		_ledge_cap = load(LEDGE_CAP)
		_ledge_fill = load(LEDGE_FILL)
	_build_hero()
	_refresh_summaries()
	resized.connect(_on_resized)
	_on_resized()


func _build_hero() -> void:
	if not ResourceLoader.exists(HERO_SHEET):
		return
	var frames := SpriteUtil.new_frames()
	SpriteUtil.add_anim(frames, "idle", load(HERO_SHEET), HERO_FRAME, HERO_FRAME, 1, 10, 10.0, true)
	_hero = AnimatedSprite2D.new()
	_hero.sprite_frames = frames
	_hero.scale = Vector2(HERO_SCALE, HERO_SCALE)
	add_child(_hero)
	_hero.play("idle")


func _refresh_summaries() -> void:
	summaries.clear()
	for i in SLOTS:
		summaries.append(GameState.slot_summary(i))


func _on_resized() -> void:
	_place_hero()
	queue_redraw()


func _hero_feet() -> Vector2:
	return Vector2(size.x * 0.2, size.y * 0.86)


func _place_hero() -> void:
	if _hero == null:
		return
	var feet := _hero_feet()
	_hero.position = feet + Vector2(2.0 * HERO_SCALE, -16.0 * HERO_SCALE)
	_hero.visible = stage == 0


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _layout() -> Dictionary:
	var h := size.y
	var cx := size.x * 0.5
	var rows_top := h * 0.40
	var rows: Array = []
	for i in SLOTS:
		rows.append(Rect2(cx - ROW_W * 0.5, rows_top + float(i) * (ROW_H + ROW_GAP), ROW_W, ROW_H))
	var back_y := rows_top + float(SLOTS) * (ROW_H + ROW_GAP) + 6.0
	return {
		"rows": rows,
		"start": Rect2(cx - BTN_W * 0.5, h * 0.52, BTN_W, BTN_H),
		"back": Rect2(cx - BTN_W * 0.5, back_y, BTN_W, BTN_H),
		"title_y": h * 0.13,
		"head_y": h * 0.335,
		"hint_y": h * 0.93,
	}


func _draw() -> void:
	var lay := _layout()
	var full := Rect2(Vector2.ZERO, size)
	draw_rect(full, Color(0.01, 0.01, 0.04, 0.42))
	UiKit.scanlines(self, full, 4.0, Color(0.0, 0.0, 0.0, 0.16))

	var cx := size.x * 0.5
	PixelFont.draw_centered(self, PackedStringArray([TITLE]), cx, float(lay.title_y), 9.0, WHITE, true, Color(0.05, 0.05, 0.1, 0.85))

	if stage == 0:
		_draw_ledge()
		_draw_button(lay.start as Rect2, "START", 0)
		PixelFont.draw_centered(self, PackedStringArray(["ENTER: START"]), cx, float(lay.hint_y), 2.0, GREY)
	else:
		draw_rect(Rect2(cx - 220.0, float(lay.head_y) - 26.0, 440.0, 3.0), Color(0.5, 0.5, 0.5, 0.6))
		PixelFont.draw_centered(self, PackedStringArray(["SAVES"]), cx, float(lay.head_y), 3.0, WHITE)
		var rows: Array = lay.rows
		for i in SLOTS:
			_draw_slot(rows[i] as Rect2, i)
		_draw_button(lay.back as Rect2, "BACK", 3)
		PixelFont.draw_centered(self, PackedStringArray(["UP / DOWN: SELECT    ENTER: PLAY    DEL: ERASE    ESC: BACK"]), cx, float(lay.hint_y), 2.0, GREY)


func _draw_ledge() -> void:
	if _ledge_cap == null or _ledge_fill == null:
		return
	var feet := _hero_feet()
	var w := 380.0
	var origin := Vector2(feet.x - w * 0.5, feet.y)
	draw_set_transform(origin, 0.0, Vector2(LEDGE_SCALE, LEDGE_SCALE))
	var cap_h := float(_ledge_cap.get_height())
	draw_texture_rect(_ledge_cap, Rect2(0.0, 0.0, w / LEDGE_SCALE, cap_h), true)
	draw_texture_rect(_ledge_fill, Rect2(0.0, cap_h, w / LEDGE_SCALE, 16.0), true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_slot(r: Rect2, i: int) -> void:
	var info: Dictionary = summaries[i]
	var exists := bool(info.get("exists", false))
	var active := i == focus
	var hot := hover == i
	var lit := Color(0.9, 0.9, 0.9) if active else Color(0.4, 0.4, 0.45) if not hot else Color(0.65, 0.65, 0.7)
	if confirm_delete == i:
		lit = Color(1.0, 0.35, 0.3)
	var fill := Color(0.12, 0.12, 0.16, 0.94) if active else Color(0.03, 0.03, 0.06, 0.82)
	UiKit.frame(self, r, 4.0, fill, lit, lit.darkened(0.5))

	PixelFont.draw_text(self, "SLOT %d" % (i + 1), r.position + Vector2(24, 12), 3.0, WHITE if active else GREY)

	var status := "SHARDS %d/3" % int(info.get("shards", 0)) if exists else "EMPTY"
	var status_w := PixelFont.text_width(status, 2.0)
	PixelFont.draw_text(self, status, Vector2(r.end.x - 24.0 - status_w, r.position.y + 16.0), 2.0, WHITE if exists else DIM)

	if confirm_delete == i:
		PixelFont.draw_text(self, "PRESS DEL AGAIN TO ERASE", r.position + Vector2(24, 40), 2.0, Color(1.0, 0.45, 0.4))
	else:
		var detail := "NEW GAME - PRESS ENTER TO CRASH LAND" if not exists else "%s  //  %s" % [str(info.get("level", "centura")).to_upper(), str(info.get("when", ""))]
		PixelFont.draw_text(self, detail, r.position + Vector2(24, 40), 2.0, GREY)

	if active:
		var blink := 0.55 + 0.45 * sin(t * 5.0)
		PixelFont.draw_text(self, ">", Vector2(r.position.x - 28.0, r.position.y + 22.0), 3.0, Color(1.0, 1.0, 1.0, blink))


func _draw_button(r: Rect2, label: String, idx: int) -> void:
	var active := focus == idx
	var hot := hover == idx
	var lit := Color(0.95, 0.95, 0.95) if active else Color(0.42, 0.42, 0.48) if not hot else Color(0.7, 0.7, 0.76)
	var fill := Color(0.14, 0.14, 0.2, 0.95) if active else Color(0.03, 0.03, 0.06, 0.85)
	UiKit.frame(self, r, 5.0, fill, lit, lit.darkened(0.5))
	var px := 5.0
	PixelFont.draw_centered(self, PackedStringArray([label]), r.get_center().x, r.position.y + (r.size.y - PixelFont.line_height(px)) * 0.5, px, WHITE if active else GREY, active, Color(0.0, 0.0, 0.0, 0.5) if active else Color(0, 0, 0, 0))
	if active and int(t * 4.0) % 2 == 0:
		PixelFont.draw_text(self, ">", Vector2(r.position.x - 28.0, r.position.y + 24.0), 3.0, WHITE)


func _max_focus() -> int:
	return 0 if stage == 0 else SLOTS


func _move_to(i: int) -> void:
	var was := focus
	focus = clampi(i, 0, _max_focus())
	if focus != was:
		confirm_delete = -1
	queue_redraw()


func _go_slots() -> void:
	stage = 1
	focus = 0
	hover = -1
	confirm_delete = -1
	_refresh_summaries()
	_place_hero()
	queue_redraw()


func _go_title() -> void:
	stage = 0
	focus = 0
	hover = -1
	confirm_delete = -1
	_place_hero()
	queue_redraw()


func _confirm() -> void:
	if stage == 0:
		_go_slots()
	elif focus < SLOTS:
		if confirm_delete >= 0:
			confirm_delete = -1
			queue_redraw()
		else:
			start_pressed.emit(focus)
	else:
		_go_title()


func _try_delete() -> void:
	if focus >= SLOTS:
		return
	var info: Dictionary = summaries[focus]
	if not bool(info.get("exists", false)):
		return
	if confirm_delete != focus:
		confirm_delete = focus
		queue_redraw()
		return
	GameState.delete_slot(focus)
	confirm_delete = -1
	_refresh_summaries()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W:
				_move_to(focus - 1)
			KEY_DOWN, KEY_S:
				_move_to(focus + 1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_confirm()
				accept_event()
			KEY_DELETE, KEY_BACKSPACE:
				if stage == 1:
					_try_delete()
					accept_event()
			KEY_ESCAPE:
				if stage == 1:
					if confirm_delete >= 0:
						confirm_delete = -1
						queue_redraw()
					else:
						_go_title()
					accept_event()


func _hit_test(pos: Vector2) -> int:
	var lay := _layout()
	if stage == 0:
		return 0 if (lay.start as Rect2).has_point(pos) else -1
	var rows: Array = lay.rows
	for i in SLOTS:
		if (rows[i] as Rect2).has_point(pos):
			return i
	if (lay.back as Rect2).has_point(pos):
		return 3
	return -1


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var found := _hit_test(event.position)
		if found != hover:
			hover = found
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit := _hit_test(event.position)
		if hit >= 0:
			focus = hit
			_confirm()
			accept_event()
