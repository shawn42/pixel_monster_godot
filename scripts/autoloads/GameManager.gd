extends Node

const LEVEL_COUNT := 36
const SCORES_PATH := "user://scores.cfg"

var current_level_index: int = 0
var _scores := ConfigFile.new()
var _music_player: AudioStreamPlayer = null

func _ready() -> void:
	_scores.load(SCORES_PATH)
	_music_player = AudioStreamPlayer.new()
	add_child(_music_player)
	# Window setup — done in code since project.godot settings get stripped by the editor
	var win := get_window()
	win.mode = Window.MODE_MAXIMIZED
	win.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	var start_level := 22 if OS.is_debug_build() else 0
	call_deferred("load_level", start_level)

func load_level(index: int) -> void:
	current_level_index = index
	var path := "res://levels/level%d.png" % (index + 1)
	var level := LevelLoader.load_level(path)
	_play_music_for_level(level)
	get_node("/root/Game").load_level(level)

func complete_level(elapsed_ms: float) -> void:
	var key := "level%d" % (current_level_index + 1)
	var best: float = _scores.get_value("scores", key, INF)
	if elapsed_ms < best:
		_scores.set_value("scores", key, elapsed_ms)
		_scores.save(SCORES_PATH)
	var next := (current_level_index + 1) % LEVEL_COUNT
	load_level(next)

func reload_level() -> void:
	load_level(current_level_index)

func skip_level() -> void:
	complete_level(INF)  # skip doesn't save a score

func prev_level() -> void:
	load_level((current_level_index - 1 + LEVEL_COUNT) % LEVEL_COUNT)

func best_ms(level_index: int) -> Variant:
	var key := "level%d" % (level_index + 1)
	var val: Variant = _scores.get_value("scores", key, null)
	return val

## Music selection: map level hue (0.0–1.0) to one of available music files.
func _play_music_for_level(level: Node2D) -> void:
	var hue := ColorUtils.color_hue(level.average_color)
	var music_index := int(hue * 16.0) % 16
	var music_files := _get_music_files()
	if music_files.is_empty():
		return
	var path := music_files[music_index % music_files.size()]
	if _music_player.stream and _music_player.playing:
		if _music_player.stream.resource_path == path:
			return  # same track, keep playing
	_music_player.stream = load(path)
	_music_player.volume_db = linear_to_db(0.1)
	_music_player.play()

func _get_music_files() -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open("res://music/")
	if dir:
		dir.list_dir_begin()
		var fname := dir.get_next()
		while fname != "":
			if fname.ends_with(".mp3") or fname.ends_with(".ogg"):
				files.append("res://music/" + fname)
			fname = dir.get_next()
	files.sort()
	return files
