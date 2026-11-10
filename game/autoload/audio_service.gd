extends Node
## Plays sound effects and music. Owns the Music and SFX buses.
## Settings come from GameState.settings ("music", "sfx"). Missing files log once and do not crash.

const SFX_DIR: String = "res://assets/audio/"
const SFX_POOL_SIZE: int = 8
const SFX_RATE_LIMIT_MS: int = 60
const MUSIC_FADE_S: float = 1.0
const SILENT_DB: float = -80.0
const MUSIC_BUS: String = "Music"
const SFX_BUS: String = "SFX"

var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_next: int = 0
var _music_players: Array[AudioStreamPlayer] = []
var _music_current: AudioStreamPlayer = null
var _music_name: String = ""
var _music_tween: Tween = null
var _streams: Dictionary = {}
var _missing: Dictionary = {}
var _last_played_ms: Dictionary = {}


func _ready() -> void:
	_ensure_bus(MUSIC_BUS)
	_ensure_bus(SFX_BUS)
	for i: int in range(SFX_POOL_SIZE):
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx_players.append(player)
	for i: int in range(2):
		var music: AudioStreamPlayer = AudioStreamPlayer.new()
		music.bus = MUSIC_BUS
		music.volume_db = SILENT_DB
		add_child(music)
		_music_players.append(music)
	var bus: Node = get_node_or_null("/root/EventBus")
	if bus != null:
		bus.connect("state_loaded", Callable(self, "apply_settings"))
	apply_settings()


## Returns true when a sound may play again. last_ms < 0 means it never played.
static func can_play(last_ms: int, now_ms: int) -> bool:
	if last_ms < 0:
		return true
	return now_ms - last_ms >= SFX_RATE_LIMIT_MS


## Plays one sound effect from "res://assets/audio/sfx_<sound_name>.ogg".
func play_sfx(sound_name: String) -> void:
	var now_ms: int = Time.get_ticks_msec()
	var last_ms: int = int(_last_played_ms.get(sound_name, -1))
	if not can_play(last_ms, now_ms):
		return
	var stream: AudioStream = _load_stream(SFX_DIR + "sfx_" + sound_name + ".ogg")
	if stream == null:
		return
	_last_played_ms[sound_name] = now_ms
	var player: AudioStreamPlayer = _sfx_players[_sfx_next]
	_sfx_next = (_sfx_next + 1) % SFX_POOL_SIZE
	player.stream = stream
	player.play()


## Cross-fades to "res://assets/audio/music_<track_name>.ogg" over one second.
func play_music(track_name: String) -> void:
	if track_name == _music_name and _music_current != null:
		return
	var stream: AudioStream = _load_stream(SFX_DIR + "music_" + track_name + ".ogg")
	if stream == null:
		return
	_music_name = track_name
	var outgoing: AudioStreamPlayer = _music_current
	var incoming: AudioStreamPlayer = _music_players[0]
	if outgoing == _music_players[0]:
		incoming = _music_players[1]
	for p: AudioStreamPlayer in _music_players:
		if p != outgoing:
			p.stop()
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	incoming.stream = stream
	incoming.volume_db = SILENT_DB
	incoming.play()
	_music_current = incoming
	_music_tween = create_tween()
	_music_tween.set_parallel(true)
	_music_tween.tween_property(incoming, "volume_db", 0.0, MUSIC_FADE_S)
	if outgoing != null:
		_music_tween.tween_property(outgoing, "volume_db", SILENT_DB, MUSIC_FADE_S)
		_music_tween.chain().tween_callback(outgoing.stop)


## Applies GameState.settings as bus mute. Called at start and on EventBus.state_loaded.
func apply_settings() -> void:
	var gs: Node = get_node_or_null("/root/GameState")
	var settings: Variant = null
	if gs != null:
		settings = gs.get("settings")
	var music_on: bool = true
	var sfx_on: bool = true
	if typeof(settings) == TYPE_DICTIONARY:
		var dict: Dictionary = settings as Dictionary
		music_on = bool(dict.get("music", true))
		sfx_on = bool(dict.get("sfx", true))
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS), not music_on)
	AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS), not sfx_on)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx: int = AudioServer.get_bus_count() - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


## Loads a stream once and caches it. A missing file prints one line and returns null.
func _load_stream(path: String) -> AudioStream:
	if _streams.has(path):
		return _streams[path] as AudioStream
	if _missing.has(path):
		return null
	if not ResourceLoader.exists(path):
		_missing[path] = true
		print("AudioService: missing audio file " + path)
		return null
	var stream: AudioStream = load(path) as AudioStream
	_streams[path] = stream
	return stream
