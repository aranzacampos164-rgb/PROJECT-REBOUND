extends Node

const LevelScript = preload("res://level.gd")
const TitleScreen = preload("res://title_screen.gd")
const Cutscene = preload("res://cutscene.gd")
const ShardToast = preload("res://shard_toast.gd")
const PauseMenu = preload("res://pause_menu.gd")
const AutosaveIndicator = preload("res://autosave_indicator.gd")

const PLANETS := ["centura", "astra", "ventura"]
const MUSIC_PATHS := ["res://music/menu.ogg", "res://music/theme.ogg", "res://music/theme.mp3", "res://music/theme.wav"]

var level
var hud_label: Label
var msg_label: Label
var ui_layer: CanvasLayer
var screen: Control
var pause_menu: Control
var music: AudioStreamPlayer
var msg_token := 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color(0.02, 0.02, 0.07))
	_build_hud()
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	var indicator_layer := CanvasLayer.new()
	indicator_layer.layer = 40
	add_child(indicator_layer)
	var indicator := AutosaveIndicator.new()
	indicator_layer.add_child(indicator)
	indicator.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_start_music()
	_show_title()


func _build_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	hud_label = Label.new()
	hud_label.position = Vector2(16, 10)
	hud_label.add_theme_font_size_override("font_size", 20)
	hud_label.visible = false
	hud.add_child(hud_label)
	msg_label = Label.new()
	hud.add_child(msg_label)
	msg_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	msg_label.offset_top = 96
	msg_label.offset_bottom = 156
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	msg_label.add_theme_font_size_override("font_size", 26)
	msg_label.visible = false


func _start_music() -> void:
	for path in MUSIC_PATHS:
		if not ResourceLoader.exists(path):
			continue
		var stream = load(path)
		if stream == null:
			continue
		if stream is AudioStreamOggVorbis or stream is AudioStreamMP3:
			stream.loop = true
		elif stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		music = AudioStreamPlayer.new()
		music.stream = stream
		music.volume_db = -12.0
		music.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(music)
		music.play()
		return


func _process(_delta: float) -> void:
	if level and is_instance_valid(level) and level.player:
		hud_label.text = "%s\nHP %d/5    Shards %d/3    ESC: MENU" % [level.data.title, level.player.health, GameState.shard_count()]
	else:
		hud_label.text = ""


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if level and is_instance_valid(level) and screen == null and pause_menu == null:
			_open_pause()
			get_viewport().set_input_as_handled()


func _open_pause() -> void:
	pause_menu = PauseMenu.new()
	pause_menu.resume_requested.connect(_close_pause)
	pause_menu.menu_requested.connect(_back_to_menu)
	ui_layer.add_child(pause_menu)
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	get_tree().paused = true


func _close_pause() -> void:
	get_tree().paused = false
	if pause_menu and is_instance_valid(pause_menu):
		pause_menu.queue_free()
	pause_menu = null


func _back_to_menu() -> void:
	GameState.save_active()
	_close_pause()
	_show_title()


func _show_title() -> void:
	_clear_level()
	_clear_screen()
	hud_label.visible = false
	msg_label.visible = false
	var title := TitleScreen.new()
	title.start_pressed.connect(_on_start_pressed)
	_show_screen(title)


func _show_screen(s: Control) -> void:
	ui_layer.add_child(s)
	s.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen = s


func _clear_screen() -> void:
	if screen and is_instance_valid(screen):
		screen.queue_free()
	screen = null


func _on_start_pressed(slot: int) -> void:
	var info: Dictionary = GameState.slot_summary(slot)
	GameState.active_slot = slot
	_clear_screen()
	if bool(info.get("exists", false)):
		GameState.read_slot(slot)
		var lvl := GameState.current_level
		if lvl == "hub":
			var next := _next_planet()
			lvl = next if next != "" else "centura"
			GameState.current_level = lvl
		_load_level(lvl)
	else:
		GameState.reset()
		GameState.current_level = "centura"
		_play_intro()


func _next_planet() -> String:
	for id in PLANETS:
		if not GameState.shards[id]:
			return id
	return ""


func _intro_pages() -> Array:
	return [
		"YEAR 2187. THE SUPPLY SHIP HAVEN DRIFTS THROUGH THE OUTER RIM, CARRYING ONE EXPERIMENTAL ENERGY CORE.",
		"A DEBRIS STORM TEARS THE HULL OPEN. THE ENGINES DIE. THE CORE CRACKS INTO THREE GLOWING SHARDS.",
		"THE HAVEN FALLS TOWARD CENTURA - A RUST WORLD OF CANYONS AND STONE GUARDIANS. THE WRECK BURNS ON ENTRY.",
		"YOU WAKE IN THE SMOKE. THE CORE IS GONE. FIND THE SHARDS, BEAT THE THREE GUARDIANS AND MAKE THE HAVEN FLY AGAIN.",
		"MOVE: A / D OR ARROWS\nJUMP: SPACE - TAP FOR A SHORT HOP\nFIRE: J\nBOUNCE PADS: HOLD JUMP WHEN YOU LAND",
		"PRESS ENTER. THE HAVEN GOES DOWN.",
	]


func _play_intro() -> void:
	var cs := Cutscene.new()
	cs.mode = "intro"
	cs.pages = _intro_pages()
	cs.finished.connect(_on_intro_finished)
	_show_screen(cs)


func _on_intro_finished() -> void:
	GameState.current_level = "centura"
	GameState.save_active()
	_load_level("centura")


func _show_ending() -> void:
	_clear_level()
	hud_label.visible = false
	msg_label.visible = false
	var cs := Cutscene.new()
	cs.mode = "ending"
	cs.pages = [
		"THE THREE SHARDS CLICK INTO THE CORE. LIGHT RUNS THROUGH THE WRECK OF THE HAVEN.",
		"THE ENGINES CATCH. CENTURA SHRINKS BELOW YOU UNTIL IT IS ONLY A RUSTY STAR.",
		"THE HAVEN UNIVERSE IS WHOLE AGAIN.\n\nTHE END",
	]
	cs.finished.connect(_show_title)
	_show_screen(cs)


func _travel() -> void:
	var next := _next_planet()
	if next == "":
		_show_ending()
		return
	_clear_level()
	_clear_screen()
	hud_label.visible = false
	msg_label.visible = false
	GameState.current_level = next
	var cs := Cutscene.new()
	cs.mode = "travel"
	cs.header = "HAVEN SKIFF > %s" % next.to_upper()
	cs.pages = _travel_pages(next)
	cs.finished.connect(_load_level.bind(next))
	_show_screen(cs)


func _travel_pages(next: String) -> Array:
	var pages: Array = [
		"SHARD %d OF 3 RECOVERED. THE CORE HUMS WEAKLY, AS IF IT KNOWS THE OTHERS ARE OUT THERE." % GameState.shard_count(),
		"YOU CLIMB INTO THE HAVEN ESCAPE SKIFF, STRAP IN AND LOCK THE NAV COMPUTER ONTO THE NEXT SIGNAL.",
	]
	if next == "astra":
		pages.append_array([
			"NEXT STOP: ASTRA. A FROZEN WORLD OF DRIFTING CRYSTAL, THIN AIR AND NO SECOND CHANCES.",
			"ITS GUARDIAN IS FAST AND FIRES IN SPREADS. USE THE BOUNCE PADS TO STAY ABOVE THE FIGHT.",
			"THE SKIFF SHAKES AS IT HITS THE UPPER ATMOSPHERE. ENTERING ORBIT. HOLD ON.",
		])
	else:
		pages.append_array([
			"NEXT STOP: VENTURA. A WORLD OF LAVA AND BLACK GLASS. ONE WRONG STEP AND IT IS OVER.",
			"THE INFERNO CORE HOVERS ABOVE ITS ARENA. SHOOT IT WHEN IT SWOOPS LOW.",
			"THIS IS THE LAST SHARD. THE SKIFF SCREAMS INTO ORBIT. HOLD ON.",
		])
	return pages


func _load_level(id: String) -> void:
	_clear_level()
	_clear_screen()
	level = LevelScript.new()
	level.level_id = id
	level.request_level.connect(_on_request_level)
	level.message.connect(_show_message)
	level.shard_collected.connect(_on_shard_collected)
	add_child(level)
	GameState.current_level = id
	GameState.save_active()
	hud_label.visible = true


func _clear_level() -> void:
	if level and is_instance_valid(level):
		remove_child(level)
		level.queue_free()
	level = null


func _on_request_level(id: String) -> void:
	call_deferred("_change_level", id)


func _change_level(id: String) -> void:
	if id == "ending":
		_show_ending()
	elif id == "travel":
		_travel()
	else:
		_load_level(id)


func _on_shard_collected(count: int) -> void:
	var toast := ShardToast.new()
	toast.count = count
	ui_layer.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _show_message(text: String, seconds: float = 3.0) -> void:
	msg_token += 1
	var tok := msg_token
	msg_label.text = text
	msg_label.visible = true
	await get_tree().create_timer(seconds).timeout
	if tok == msg_token:
		msg_label.visible = false
