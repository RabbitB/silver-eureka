extends Node


const DEFAULT_REFRESH_TIME: float = 0.5

var _last_modified_time: int
var _last_read_byte: int
var _current_refresh_time: float = DEFAULT_REFRESH_TIME
var _file: File = File.new()

onready var log_text: RichTextLabel = get_node("RichTextLabel")
onready var refresh_timer: Timer = get_node("RefreshTimer")


func _ready() -> void:
	refresh_timer.wait_time = DEFAULT_REFRESH_TIME
	refresh_from_file()


func refresh_from_file() -> void:
	if not log_file_exists():
		return

	var log_file_path: String = get_log_file_path()
	var modified_time: int = _file.get_modified_time(log_file_path)

	if _last_modified_time == modified_time:
		_current_refresh_time += 1.0
	else:
		_current_refresh_time = DEFAULT_REFRESH_TIME

	_last_modified_time = modified_time
	refresh_timer.start(_current_refresh_time)

	display_changes_from_file()


func display_changes_from_file() -> void:
	if not log_file_exists():
		return

	var err: int = _file.open(get_log_file_path(), File.READ)
	if err:
		printerr("Could not open log file, encountered error: %d" % err)
		return

	var file_len: int = _file.get_len()
	# No changes
	if file_len == _last_read_byte:
		_file.close()
		return
	# Read the entire file, as it has been reset at some point.
	elif file_len < _last_read_byte:
		log_text.text = log_text.text + _file.get_as_text()
	# Read only the new content.
	else:
		var remaining_bytes: int = file_len - _last_read_byte
		_file.seek(_last_read_byte)
		log_text.text = log_text.text + _file.get_buffer(remaining_bytes).get_string_from_utf8()

	_file.close()

#	print("Updated Time: %d" % _last_modified_time);


func get_log_file_path() -> String:
	return ProjectSettings.get_setting("logging/file_logging/log_path")


func log_file_exists() -> bool:
	return _file.file_exists(get_log_file_path())


func _on_Timer_timeout() -> void:
	refresh_from_file()

