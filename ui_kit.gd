extends RefCounted


static func frame(ci: CanvasItem, r: Rect2, u: float, fill: Color, lit: Color, dark: Color) -> void:
	ci.draw_rect(r, fill)
	ci.draw_rect(Rect2(r.position.x + u, r.position.y, r.size.x - u * 2.0, u), lit)
	ci.draw_rect(Rect2(r.position.x, r.position.y + u, u, r.size.y - u * 2.0), lit)
	ci.draw_rect(Rect2(r.position.x + u, r.end.y - u, r.size.x - u * 2.0, u), dark)
	ci.draw_rect(Rect2(r.end.x - u, r.position.y + u, u, r.size.y - u * 2.0), dark)


static func scanlines(ci: CanvasItem, r: Rect2, step: float, color: Color) -> void:
	var y := r.position.y
	while y < r.end.y:
		ci.draw_rect(Rect2(r.position.x, y, r.size.x, 1.0), color)
		y += step


static func bar(ci: CanvasItem, r: Rect2, frac: float, fill: Color, back: Color) -> void:
	ci.draw_rect(r, back)
	ci.draw_rect(Rect2(r.position, Vector2(r.size.x * clampf(frac, 0.0, 1.0), r.size.y)), fill)
