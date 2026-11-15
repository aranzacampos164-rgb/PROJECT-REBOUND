extends Node

signal shards_changed
signal autosaved

const SLOT_COUNT := 3

var shards := {"centura": false, "astra": false, "ventura": false}
var hub_spawn_x := 150.0
var seen_intro := false
var active_slot := -1
var current_level := "centura"


func _ready() -> void:
	_bind("move_left", [KEY_A, KEY_LEFT])
	_bind("move_right", [KEY_D, KEY_RIGHT])
	_bind("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_bind("shoot", [KEY_J, KEY_X, KEY_Z])


func shard_count() -> int:
	var n := 0
	for k in shards:
		if shards[k]:
			n += 1
	return n


func has_all() -> bool:
	return shard_count() == 3


func collect(planet: String) -> void:
	shards[planet] = true
	shards_changed.emit()
	save_active()


func reset() -> void:
	for k in shards:
		shards[k] = false
	hub_spawn_x = 150.0
	seen_intro = false
	current_level = "centura"


func slot_path(i: int) -> String:
	return "user://rebound_slot_%d.json" % i


func slot_summary(i: int) -> Dictionary:
	var info := {"exists": false, "shards": 0, "level": "centura", "when": ""}
	var d := _read_slot(i)
	if d.is_empty():
		return info
	info.exists = true
	info.level = str(d.get("level", "centura"))
	var at := int(d.get("at", 0))
	if at > 0:
		info.when = Time.get_date_string_from_unix_time(at).replace("-", ".")
	var saved = d.get("shards", {})
	if typeof(saved) == TYPE_DICTIONARY:
		var n := 0
		for k in shards:
			if bool(saved.get(k, false)):
				n += 1
		info.shards = n
	return info


func read_slot(i: int) -> bool:
	var d := _read_slot(i)
	if d.is_empty():
		return false
	var saved = d.get("shards", {})
	if typeof(saved) == TYPE_DICTIONARY:
		for k in shards:
			shards[k] = bool(saved.get(k, false))
	hub_spawn_x = float(d.get("hub_spawn_x", 150.0))
	current_level = str(d.get("level", "centura"))
	active_slot = i
	shards_changed.emit()
	return true


func write_slot(i: int) -> void:
	var f := FileAccess.open(slot_path(i), FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"shards": shards,
		"hub_spawn_x": hub_spawn_x,
		"level": current_level,
		"at": int(Time.get_unix_time_from_system()),
	}))


func save_active() -> void:
	if active_slot >= 0:
		write_slot(active_slot)
		autosaved.emit()


func delete_slot(i: int) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		return
	var name := "rebound_slot_%d.json" % i
	if dir.file_exists(name):
		dir.remove(name)
	if active_slot == i:
		active_slot = -1
		reset()


func _read_slot(i: int) -> Dictionary:
	var path := slot_path(i)
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _bind(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)
