extends Node2D

signal request_level(id: String)
signal message(text: String, seconds: float)
signal shard_collected(count: int)

const Player = preload("res://player.gd")
const BouncePad = preload("res://bounce_pad.gd")
const Boss = preload("res://boss.gd")
const Enemy = preload("res://enemy.gd")
const Chest = preload("res://chest.gd")

const CUSTOM_BG := "res://sprites/background.png"
const CHECK_SIZE := 64
const TILE_SCALE := 2.0
const TILE_THEMES := {"centura": "centura", "astra": "astra", "ventura": "ventura", "hub": "centura"}

var level_id := "hub"
var data := {}
var player
var shard_taken := false
var ending_started := false


func _ready() -> void:
	data = _data(level_id)
	_build_background()
	for r in data.platforms:
		_add_platform(r)
	_add_platform(Rect2(-40, -600, 40, 1600))
	_add_platform(Rect2(data.width, -600, 40, 1600))
	for p in data.pads:
		_add_pad(p)
	_build_enemies()
	if level_id == "hub":
		_build_hub()
	else:
		if level_id == "centura":
			_build_crash_site()
		_build_boss()
	_spawn_player()
	if level_id == "hub":
		if not GameState.seen_intro:
			GameState.seen_intro = true
			message.emit("Pulse boots online. Find the 3 planet portals and recover the energy shards.", 5.0)
	else:
		message.emit(data.intro, 4.0)


func _planet_color(id: String) -> Color:
	match id:
		"centura":
			return Color(0.95, 0.55, 0.2)
		"astra":
			return Color(0.45, 0.8, 1.0)
		"ventura":
			return Color(1.0, 0.25, 0.2)
	return Color.WHITE


func _data(id: String) -> Dictionary:
	match id:
		"centura":
			return {
				"title": "Centura",
				"intro": "CENTURA - You wake in the wreckage. Cross the canyon; the Stone Guardian holds your shard.",
				"width": 3300, "bg": Color(0.22, 0.1, 0.07), "bg2": Color(0.28, 0.14, 0.1), "slime": "slime1", "ground": Color(0.62, 0.33, 0.16),
				"lava": false, "spawn": Vector2(100, 600),
				"platforms": [
					Rect2(0, 600, 800, 300),
					Rect2(900, 540, 120, 24),
					Rect2(1080, 480, 120, 24),
					Rect2(1260, 420, 500, 480),
					Rect2(1780, 120, 300, 24),
					Rect2(2150, 420, 1150, 480),
				],
				"pads": [Vector2(1600, 420)],
				"enemies": [
					Vector4(350, 600, 240, 470), Vector4(620, 600, 540, 760),
					Vector4(910, 540, 905, 1015), Vector4(1085, 480, 1082, 1194),
					Vector4(1450, 420, 1300, 1500), Vector4(1620, 420, 1520, 1730),
					Vector4(1850, 120, 1790, 2070),
				],
				"boss": {"kind": "centura", "pos": Vector2(2800, 370), "left": 2300.0, "right": 3200.0, "hp": 10},
			}
		"astra":
			return {
				"title": "Astra",
				"intro": "ASTRA - Bounce through the frozen sky and defeat the Ice Crystal.",
				"width": 3600, "bg": Color(0.05, 0.08, 0.2), "bg2": Color(0.09, 0.13, 0.28), "slime": "slime2", "ground": Color(0.45, 0.65, 0.85),
				"lava": false, "spawn": Vector2(100, 600),
				"platforms": [
					Rect2(0, 600, 600, 300),
					Rect2(700, 320, 200, 24),
					Rect2(1000, 300, 140, 24),
					Rect2(1250, 340, 140, 24),
					Rect2(1530, 100, 260, 24),
					Rect2(1900, 260, 140, 24),
					Rect2(2150, 380, 140, 24),
					Rect2(2400, 500, 1200, 400),
				],
				"pads": [Vector2(520, 600), Vector2(1320, 340)],
				"enemies": [
					Vector4(300, 600, 150, 450), Vector4(480, 600, 380, 560),
					Vector4(800, 320, 720, 880), Vector4(1030, 300, 1005, 1135),
					Vector4(1280, 340, 1255, 1385), Vector4(1650, 100, 1550, 1770),
					Vector4(1920, 260, 1905, 2035), Vector4(2600, 500, 2450, 2800),
				],
				"boss": {"kind": "astra", "pos": Vector2(3000, 450), "left": 2550.0, "right": 3500.0, "hp": 14},
			}
		"ventura":
			return {
				"title": "Ventura",
				"intro": "VENTURA - Don't fall in the lava! Defeat the Inferno Core.",
				"width": 4000, "bg": Color(0.12, 0.03, 0.04), "bg2": Color(0.18, 0.06, 0.07), "slime": "slime3", "ground": Color(0.3, 0.2, 0.22),
				"lava": true, "spawn": Vector2(100, 600),
				"platforms": [
					Rect2(0, 600, 500, 300),
					Rect2(620, 560, 120, 24),
					Rect2(820, 520, 120, 24),
					Rect2(1020, 480, 120, 24),
					Rect2(1250, 200, 200, 24),
					Rect2(1550, 260, 120, 24),
					Rect2(1770, 320, 120, 24),
					Rect2(1990, 380, 120, 24),
					Rect2(2200, 440, 200, 24),
					Rect2(2520, 160, 260, 24),
					Rect2(2900, 480, 1100, 420),
				],
				"pads": [Vector2(1080, 480), Vector2(2300, 440)],
				"enemies": [
					Vector4(300, 600, 150, 450), Vector4(680, 560, 625, 735),
					Vector4(1080, 480, 1025, 1135), Vector4(1300, 200, 1255, 1445),
					Vector4(2260, 440, 2205, 2395), Vector4(2650, 160, 2540, 2760),
					Vector4(3100, 480, 2950, 3300),
				],
				"boss": {"kind": "ventura", "pos": Vector2(3450, 355), "left": 3050.0, "right": 3900.0, "hp": 18},
			}
	return {
		"title": "Haven Universe - Crash Site",
		"intro": "",
		"width": 2700, "bg": Color(0.04, 0.05, 0.12), "bg2": Color(0.08, 0.09, 0.18), "slime": "slime1", "ground": Color(0.28, 0.3, 0.42),
		"lava": false, "spawn": Vector2(GameState.hub_spawn_x, 600),
		"platforms": [
			Rect2(0, 600, 2700, 300),
			Rect2(800, 380, 240, 24),
		],
		"pads": [Vector2(640, 600)],
		"enemies": [],
	}


func _find_background() -> Texture2D:
	var names: Array = [level_id]
	if level_id == "hub":
		names.append("centura")
	for n in names:
		for ext in ["png", "jpg", "jpeg", "webp"]:
			var path := "res://backgrounds/%s.%s" % [n, ext]
			if ResourceLoader.exists(path):
				return load(path)
	return null


func _build_background() -> void:
	var tex := _find_background()
	if tex:
		var layer := CanvasLayer.new()
		layer.layer = -10
		add_child(layer)
		var rect := TextureRect.new()
		rect.texture = tex
		rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		layer.add_child(rect)
	else:
		var ctex: Texture2D
		if ResourceLoader.exists(CUSTOM_BG):
			ctex = load(CUSTOM_BG)
		else:
			ctex = _checker_texture(data.bg, data.bg2)
		var bg := Sprite2D.new()
		bg.texture = ctex
		bg.centered = false
		bg.region_enabled = true
		bg.region_rect = Rect2(0, 0, data.width + 3000, 4000)
		bg.position = Vector2(-1500, -1500)
		bg.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		bg.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		bg.z_index = -100
		add_child(bg)
	if data.lava:
		var lava := ColorRect.new()
		lava.position = Vector2(-200, 820)
		lava.size = Vector2(data.width + 400, 600)
		lava.color = Color(1.0, 0.35, 0.05)
		lava.z_index = -5
		add_child(lava)


func _checker_texture(c1: Color, c2: Color) -> Texture2D:
	var n := CHECK_SIZE
	var img := Image.create(n * 2, n * 2, false, Image.FORMAT_RGBA8)
	img.fill(c1)
	img.fill_rect(Rect2i(0, 0, n, n), c2)
	img.fill_rect(Rect2i(n, n, n, n), c2)
	return ImageTexture.create_from_image(img)


func _build_enemies() -> void:
	for e in data.enemies:
		var en := Enemy.new()
		en.setup(data.slime, Vector2(e.x, e.y), e.z, e.w)
		add_child(en)


func _add_platform(r: Rect2) -> void:
	var col: Color = data.ground
	var body := StaticBody2D.new()
	body.position = r.position + r.size / 2.0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	body.add_child(cs)
	var theme: String = TILE_THEMES.get(level_id, "centura")
	var fill_path := "res://tiles/%s_fill.png" % theme
	var cap_path := "res://tiles/%s_cap.png" % theme
	if ResourceLoader.exists(fill_path) and ResourceLoader.exists(cap_path):
		_add_tile_visual(body, r, load(fill_path), load(cap_path))
	else:
		var vis := ColorRect.new()
		vis.size = r.size
		vis.position = -r.size / 2.0
		vis.color = col
		body.add_child(vis)
		var top := ColorRect.new()
		top.size = Vector2(r.size.x, 6)
		top.position = Vector2(-r.size.x / 2.0, -r.size.y / 2.0)
		top.color = col.lightened(0.35)
		body.add_child(top)
	add_child(body)


func _add_tile_visual(body: Node2D, r: Rect2, fill: Texture2D, cap: Texture2D) -> void:
	var base := Sprite2D.new()
	base.texture = fill
	base.centered = false
	base.region_enabled = true
	base.region_rect = Rect2(0, 0, r.size.x / TILE_SCALE, r.size.y / TILE_SCALE)
	base.scale = Vector2(TILE_SCALE, TILE_SCALE)
	base.position = -r.size / 2.0
	base.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(base)
	var lip := Sprite2D.new()
	lip.texture = cap
	lip.centered = false
	lip.region_enabled = true
	lip.region_rect = Rect2(0, 0, r.size.x / TILE_SCALE, float(cap.get_height()))
	lip.scale = Vector2(TILE_SCALE, TILE_SCALE)
	lip.position = -r.size / 2.0
	lip.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	lip.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(lip)


func _add_pad(p: Vector2) -> void:
	var pad := BouncePad.new()
	pad.position = p + Vector2(0, -8)
	add_child(pad)


func _spawn_player() -> void:
	player = Player.new()
	add_child(player)
	player.position = data.spawn
	player.spawn_point = data.spawn
	player.set_limits(0, -300, int(data.width), 820)


func _build_hub() -> void:
	var ship_pos := Vector2(380, 600)
	var hull := Polygon2D.new()
	hull.polygon = PackedVector2Array([Vector2(-100, 0), Vector2(-70, -55), Vector2(0, -85), Vector2(85, -55), Vector2(110, 0)])
	hull.color = Color(0.45, 0.47, 0.55)
	hull.position = ship_pos
	add_child(hull)
	var window := Polygon2D.new()
	window.polygon = PackedVector2Array([Vector2(-15, -55), Vector2(15, -55), Vector2(15, -35), Vector2(-15, -35)])
	window.color = Color(0.3, 0.8, 0.95)
	window.position = ship_pos
	add_child(window)

	var ship_label := Label.new()
	ship_label.text = "YOUR SHIP (energy core broken)"
	ship_label.position = ship_pos + Vector2(-110, -165)
	add_child(ship_label)

	var i := 0
	for id in ["centura", "astra", "ventura"]:
		var slot := ColorRect.new()
		slot.size = Vector2(22, 22)
		slot.position = ship_pos + Vector2(-55 + i * 36, -135)
		slot.color = _planet_color(id) if GameState.shards[id] else Color(0.15, 0.15, 0.2)
		add_child(slot)
		i += 1

	var zone := Area2D.new()
	zone.position = ship_pos + Vector2(0, -60)
	var zcs := CollisionShape2D.new()
	var zshape := RectangleShape2D.new()
	zshape.size = Vector2(240, 140)
	zcs.shape = zshape
	zone.add_child(zcs)
	zone.body_entered.connect(_on_ship_touched)
	add_child(zone)

	var tip := Label.new()
	tip.text = "Pulse pad: hold JUMP when you land"
	tip.position = Vector2(540, 520)
	add_child(tip)

	var planets := ["centura", "astra", "ventura"]
	for n in planets.size():
		var id: String = planets[n]
		var x := 1100.0 + n * 500.0
		var done: bool = GameState.shards[id]
		var area := Area2D.new()
		area.position = Vector2(x, 530)
		var cs := CollisionShape2D.new()
		var rs := RectangleShape2D.new()
		rs.size = Vector2(90, 140)
		cs.shape = rs
		area.add_child(cs)
		var vis := ColorRect.new()
		vis.size = Vector2(90, 140)
		vis.position = Vector2(-45, -70)
		var c := _planet_color(id)
		c.a = 0.25 if done else 0.7
		vis.color = c
		area.add_child(vis)
		var lbl := Label.new()
		lbl.text = id.capitalize() + ("\n(shard collected)" if done else "")
		lbl.position = Vector2(-50, -120)
		area.add_child(lbl)
		area.body_entered.connect(_on_portal.bind(id, x))
		add_child(area)


func _on_portal(body: Node, id: String, x: float) -> void:
	if not body.is_in_group("player"):
		return
	if GameState.shards[id]:
		return
	GameState.hub_spawn_x = x - 150.0
	request_level.emit(id)


func _on_ship_touched(body: Node) -> void:
	if not body.is_in_group("player") or ending_started:
		return
	if GameState.has_all():
		ending_started = true
		message.emit("The shards fuse with the core... the ship is repaired!", 3.0)
		await get_tree().create_timer(2.5).timeout
		request_level.emit("ending")
	else:
		message.emit("The energy core is shattered. Shards: %d/3" % GameState.shard_count(), 3.0)


func _build_crash_site() -> void:
	var base := Vector2(215, 600)
	var hull := Polygon2D.new()
	hull.polygon = PackedVector2Array([
		Vector2(-130, 0), Vector2(-104, -44), Vector2(-24, -74),
		Vector2(64, -52), Vector2(128, -14), Vector2(118, 0),
	])
	hull.color = Color(0.34, 0.32, 0.37)
	hull.position = base
	hull.rotation = 0.14
	add_child(hull)
	var window := Polygon2D.new()
	window.polygon = PackedVector2Array([Vector2(-24, -66), Vector2(18, -58), Vector2(10, -40), Vector2(-28, -46)])
	window.color = Color(0.18, 0.32, 0.4)
	window.position = base
	window.rotation = 0.14
	add_child(window)
	var wing := Polygon2D.new()
	wing.polygon = PackedVector2Array([Vector2(-6, -8), Vector2(74, -46), Vector2(96, -10), Vector2(30, 4)])
	wing.color = Color(0.28, 0.26, 0.3)
	wing.position = base + Vector2(30, -22)
	wing.rotation = 0.5
	add_child(wing)
	var scorch := Polygon2D.new()
	scorch.polygon = PackedVector2Array([
		Vector2(-190, 0), Vector2(-120, -16), Vector2(-30, -10),
		Vector2(70, -18), Vector2(180, -4), Vector2(190, 0),
	])
	scorch.color = Color(0.08, 0.05, 0.05, 0.55)
	scorch.position = base + Vector2(0, 2)
	scorch.z_index = -1
	add_child(scorch)
	var label := Label.new()
	label.text = "THE HAVEN // WRECK"
	label.position = base + Vector2(-96, -130)
	add_child(label)


func _build_boss() -> void:
	var b: Dictionary = data.boss
	var boss := Boss.new()
	boss.setup(b.kind, Vector2(b.pos.x, _boss_floor()), b.left, b.right, b.hp)
	add_child(boss)
	boss.defeated.connect(_on_boss_defeated)


func _on_boss_defeated(_pos: Vector2) -> void:
	message.emit("Guardian defeated! Something is opening...", 3.0)
	call_deferred("_spawn_chest")


func _spawn_chest() -> void:
	var b: Dictionary = data.boss
	var pos := Vector2(clampf(player.global_position.x + 130.0, b.left, b.right), _boss_floor())
	var chest := Chest.new()
	chest.position = pos
	add_child(chest)
	chest.collected.connect(_on_chest_collected)


func _boss_floor() -> float:
	var last: Rect2 = data.platforms[data.platforms.size() - 1]
	return last.position.y


func _on_chest_collected() -> void:
	if shard_taken:
		return
	shard_taken = true
	GameState.collect(level_id)
	shard_collected.emit(GameState.shard_count())
	await get_tree().create_timer(2.2).timeout
	request_level.emit("travel")
