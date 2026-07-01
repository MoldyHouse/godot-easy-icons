@tool
extends RefCounted

const Config := preload("res://addons/godot-easy-icons/config/config.gd")


static func ensure_dir(path: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path))


static func reveal(path: String) -> void:
	var dock := EditorInterface.get_file_system_dock()

	if dock != null:
		dock.navigate_to_path(path)


static func copy_path(path: String) -> void:
	DisplayServer.clipboard_set(path)


static func get_project_icon_path(
		base_dir: String,
		source_path: String,
		role: String,
		custom_color: Color,
		use_custom_color: bool,
) -> String:
	var safe_name := source_path.get_file().get_basename().to_snake_case()
	var suffix := custom_color.to_html(false) if use_custom_color else role

	return base_dir.path_join("%s_%s.svg" % [safe_name, suffix])
