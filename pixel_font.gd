extends RefCounted


const GLYPH_W := 5
const GLYPH_H := 7
const TRACKING := 1
const LINE_HEIGHT := 9

const GLYPHS := {
	" ": "00000 00000 00000 00000 00000 00000 00000",
	"A": "01110 10001 10001 11111 10001 10001 10001",
	"B": "11110 10001 10001 11110 10001 10001 11110",
	"C": "01110 10001 10000 10000 10000 10001 01110",
	"D": "11110 10001 10001 10001 10001 10001 11110",
	"E": "11111 10000 10000 11110 10000 10000 11111",
	"F": "11111 10000 10000 11110 10000 10000 10000",
	"G": "01110 10001 10000 10111 10001 10001 01111",
	"H": "10001 10001 10001 11111 10001 10001 10001",
	"I": "11111 00100 00100 00100 00100 00100 11111",
	"J": "00111 00010 00010 00010 00010 10010 01100",
	"K": "10001 10010 10100 11000 10100 10010 10001",
	"L": "10000 10000 10000 10000 10000 10000 11111",
	"M": "10001 11011 10101 10101 10001 10001 10001",
	"N": "10001 11001 10101 10011 10001 10001 10001",
	"O": "01110 10001 10001 10001 10001 10001 01110",
	"P": "11110 10001 10001 11110 10000 10000 10000",
	"Q": "01110 10001 10001 10001 10101 10010 01101",
	"R": "11110 10001 10001 11110 10100 10010 10001",
	"S": "01111 10000 10000 01110 00001 00001 11110",
	"T": "11111 00100 00100 00100 00100 00100 00100",
	"U": "10001 10001 10001 10001 10001 10001 01110",
	"V": "10001 10001 10001 10001 10001 01010 00100",
	"W": "10001 10001 10001 10101 10101 11011 10001",
	"X": "10001 10001 01010 00100 01010 10001 10001",
	"Y": "10001 10001 01010 00100 00100 00100 00100",
	"Z": "11111 00001 00010 00100 01000 10000 11111",
	"0": "01110 10001 10011 10101 11001 10001 01110",
	"1": "00100 01100 00100 00100 00100 00100 01110",
	"2": "01110 10001 00001 00010 00100 01000 11111",
	"3": "11111 00010 00100 00010 00001 10001 01110",
	"4": "00010 00110 01010 10010 11111 00010 00010",
	"5": "11111 10000 11110 00001 00001 10001 01110",
	"6": "00110 01000 10000 11110 10001 10001 01110",
	"7": "11111 00001 00010 00100 01000 01000 01000",
	"8": "01110 10001 10001 01110 10001 10001 01110",
	"9": "01110 10001 10001 01111 00001 00010 01100",
	".": "00000 00000 00000 00000 00000 01100 01100",
	",": "00000 00000 00000 00000 00110 00110 01100",
	":": "00000 01100 01100 00000 01100 01100 00000",
	";": "00000 01100 01100 00000 00110 00110 01100",
	"!": "00100 00100 00100 00100 00100 00000 00100",
	"?": "01110 10001 00001 00010 00100 00000 00100",
	"'": "00100 00100 00000 00000 00000 00000 00000",
	"\"": "01010 01010 00000 00000 00000 00000 00000",
	"-": "00000 00000 00000 11111 00000 00000 00000",
	"+": "00000 00100 00100 11111 00100 00100 00000",
	"=": "00000 00000 11111 00000 11111 00000 00000",
	"/": "00001 00010 00010 00100 01000 01000 10000",
	"\\": "10000 01000 01000 00100 00010 00010 00001",
	"(": "00010 00100 01000 01000 01000 00100 00010",
	")": "01000 00100 00010 00010 00010 00100 01000",
	"[": "01110 01000 01000 01000 01000 01000 01110",
	"]": "01110 00010 00010 00010 00010 00010 01110",
	"%": "11001 11010 00010 00100 01000 01011 10011",
	"&": "01100 10010 10100 01000 10101 10010 01101",
	"*": "00000 10101 01110 11111 01110 10101 00000",
	"#": "01010 01010 11111 01010 11111 01010 01010",
	"<": "00010 00100 01000 10000 01000 00100 00010",
	">": "01000 00100 00010 00001 00010 00100 01000",
	"_": "00000 00000 00000 00000 00000 00000 11111",
	"|": "00100 00100 00100 00100 00100 00100 00100",
	"@": "01110 10001 10111 10101 10111 10000 01110",
}

static var _atlas: ImageTexture
static var _cells := {}


static func _ensure() -> void:
	if _atlas != null:
		return
	var keys := GLYPHS.keys()
	var img := Image.create_empty(keys.size() * (GLYPH_W + TRACKING), GLYPH_H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	for i in keys.size():
		var key: String = keys[i]
		var rows: PackedStringArray = str(GLYPHS[key]).split(" ")
		for y in mini(rows.size(), GLYPH_H):
			var row: String = rows[y]
			for x in mini(row.length(), GLYPH_W):
				if row[x] == "1":
					img.set_pixel(i * (GLYPH_W + TRACKING) + x, y, Color.WHITE)
		_cells[key] = i
	_atlas = ImageTexture.create_from_image(img)


static func advance(px: float) -> float:
	return float(GLYPH_W + TRACKING) * px


static func text_width(text: String, px: float) -> float:
	if text.is_empty():
		return 0.0
	return float(text.length()) * advance(px) - float(TRACKING) * px


static func line_height(px: float) -> float:
	return float(LINE_HEIGHT) * px


static func draw_char(ci: CanvasItem, ch: String, pos: Vector2, px: float, color: Color, bold: bool = false) -> void:
	_ensure()
	var idx: int = _cells.get(ch.to_upper(), -1)
	if idx < 0:
		return
	var src := Rect2(idx * (GLYPH_W + TRACKING), 0, GLYPH_W, GLYPH_H)
	var dst := Rect2(pos, Vector2(GLYPH_W, GLYPH_H) * px)
	ci.draw_texture_rect_region(_atlas, dst, src, color)
	if bold:
		ci.draw_texture_rect_region(_atlas, Rect2(pos + Vector2(px, 0.0), Vector2(GLYPH_W, GLYPH_H) * px), src, color)


static func draw_text(ci: CanvasItem, text: String, pos: Vector2, px: float, color: Color, bold: bool = false, shadow: Color = Color(0, 0, 0, 0)) -> void:
	var x := pos.x
	for i in text.length():
		var ch := text[i]
		if ch != " ":
			if shadow.a > 0.0:
				draw_char(ci, ch, Vector2(x + px, pos.y + px), px, shadow, bold)
			draw_char(ci, ch, Vector2(x, pos.y), px, color, bold)
		x += advance(px)


static func draw_centered(ci: CanvasItem, lines: PackedStringArray, center_x: float, top: float, px: float, color: Color, bold: bool = false, shadow: Color = Color(0, 0, 0, 0)) -> void:
	for i in lines.size():
		var w := text_width(lines[i], px)
		draw_text(ci, lines[i], Vector2(center_x - w * 0.5, top + float(i) * line_height(px)), px, color, bold, shadow)


static func draw_block(ci: CanvasItem, lines: PackedStringArray, origin: Vector2, px: float, color: Color, reveal: float = -1.0, bold: bool = false, shadow: Color = Color(0, 0, 0, 0)) -> void:
	var adv := advance(px)
	var budget := int(reveal)
	var used := 0
	for li in lines.size():
		var line: String = lines[li]
		var y := origin.y + float(li) * line_height(px)
		var x := origin.x
		for i in line.length():
			if reveal >= 0.0 and used >= budget:
				return
			var ch := line[i]
			if ch != " ":
				if shadow.a > 0.0:
					draw_char(ci, ch, Vector2(x + px, y + px), px, shadow, bold)
				draw_char(ci, ch, Vector2(x, y), px, color, bold)
			x += adv
			used += 1


static func char_count(lines: PackedStringArray) -> int:
	var n := 0
	for l in lines:
		n += l.length()
	return n


static func wrap(text: String, px: float, max_width: float) -> PackedStringArray:
	var out := PackedStringArray()
	var adv := advance(px)
	var max_chars := maxi(int(floor(max_width / adv)), 8)
	for para in text.to_upper().split("\n"):
		var line := ""
		for word in para.split(" ", false):
			var word_len := word.length()
			var candidate := word if line.is_empty() else line + " " + word
			if candidate.length() <= max_chars or line.is_empty():
				line = candidate
			else:
				out.append(line)
				line = word
				while line.length() > max_chars:
					out.append(line.substr(0, max_chars))
					line = line.substr(max_chars)
		out.append(line)
	return out
