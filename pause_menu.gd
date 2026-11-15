extends Control

signal resume_requested
signal menu_requested

const PixelFont = preload("res://pixel_font.gd")
const UiKit = preload("res://ui_kit.gd")

const ITEMS := ["RESUME", "BACK TO MENU"]
const PANEL_W := 620.0
const PANEL_H := 380.0
const BTN_W := 440.0
const BTN_H := 66.0
const BTN_GAP := 22.0

const WHITE := Color(1.0, 1.0, 1.0)
const GREY := Color(0.74, 0.74, 0.74)

var focus := 0
var hover := -1
var t := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _panel() -> Rect2:
	return Rect2((size - Vector2(PANEL_W, PANEL_H)) * 0.5, Vector2(PANEL_W, PANEL_H))


func _button(i: int) -> Rect2:
	var p := _panel()
	return Rect2(p.position.x + (PANEL_W - BTN_W) * 0.5, p.position.y + 150.0 + float(i) * (BTN_H + BTN_GAP), BTN_W, BTN_H)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.62))
	var p := _panel()
	UiKit.frame(self, p, 6.0, Color(0.02, 0.03, 0.06, 0.96), Color(0.85, 0.85, 0.9), Color(0.3, 0.3, 0.36))
	PixelFont.draw_centered(self, PackedStringArray(["PAUSED"]), p.get_center().x, p.position.y + 52.0, 7.0, WHITE, true, Color(0, 0, 0, 0.7))
	for i in ITEMS.size():
		var r := _button(i)
		var active := focus == i
		var hot := hover == i
		var lit := Color(0.95, 0.95, 0.95) if active else Color(0.42, 0.42, 0.48) if not hot else Color(0.7, 0.7, 0.76)
		var fill := Color(0.14, 0.14, 0.2, 0.95) if active else Color(0.03, 0.03, 0.06, 0.85)
		UiKit.frame(self, r, 5.0, fill, lit, lit.darkened(0.5))
		var px := 4.0
		PixelFont.draw_centered(self, PackedStringArray([ITEMS[i]]), r.get_center().x, r.position.y + (r.size.y - PixelFont.line_height(px)) * 0.5, px, WHITE if active else GREY)
		if active and int(t * 4.0) % 2 == 0:
			PixelFont.draw_text(self, ">", Vector2(r.position.x - 28.0, r.position.y + 22.0), 3.0, WHITE)
	PixelFont.draw_centered(self, PackedStringArray(["PROGRESS IS SAVED WHEN YOU LEAVE"]), p.get_center().x, p.end.y - 40.0, 2.0, GREY)


func _confirm() -> void:
	if focus == 0:
		resume_requested.emit()
	else:
		menu_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_UP, KEY_W:
				focus = clampi(focus - 1, 0, ITEMS.size() - 1)
			KEY_DOWN, KEY_S:
				focus = clampi(focus + 1, 0, ITEMS.size() - 1)
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				_confirm()
				accept_event()
			KEY_ESCAPE:
				resume_requested.emit()
				accept_event()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var found := -1
		for i in ITEMS.size():
			if _button(i).has_point(event.position):
				found = i
		hover = found
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in ITEMS.size():
			if _button(i).has_point(event.position):
				focus = i
				_confirm()
				accept_event()
				return
