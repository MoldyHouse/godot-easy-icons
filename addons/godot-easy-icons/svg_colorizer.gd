@tool
extends RefCounted

const IconRoles := preload("res://addons/godot-easy-icons/icon_roles.gd")
const SOURCE_ICON_DIR := "res://addons/godot-easy-icons/icons"
const IN_USE_DIR := "res://addons/godot-easy-icons/node_icons"
const MANIFEST_PATH := "res://addons/godot-easy-icons/node_icons/manifest.cfg"


static func create_or_reuse_svg(
		source_svg_path: String,
		role: String,
		custom_color: Color,
		use_custom_color: bool,
		is_light_theme: bool,
) -> String:
	if use_custom_color:
		return _create_custom(source_svg_path, custom_color)

	return _create_semantic(source_svg_path, role, is_light_theme)


static func rebuild_theme_managed_icons(is_light_theme: bool) -> Array[String]:
	var changed: Array[String] = []
	var config := ConfigFile.new()

	if config.load(MANIFEST_PATH) != OK:
		return changed

	for target_path in config.get_sections():
		if not bool(config.get_value(target_path, "theme_managed", false)):
			continue

		var source_path := String(config.get_value(target_path, "source", ""))
		var role := String(config.get_value(target_path, "role", IconRoles.NODE))

		if not FileAccess.file_exists(source_path):
			continue

		if _write_recolored_svg(source_path, target_path, IconRoles.color(role, is_light_theme)):
			changed.append(target_path)

	return changed


static func _create_semantic(source_path: String, role: String, is_light_theme: bool) -> String:
	if not _can_use_source(source_path) or not IconRoles.is_semantic(role):
		return ""

	_ensure_dir()

	var target_path := IN_USE_DIR.path_join("%s_%s.svg" % [_safe_name(source_path), role])
	var color := IconRoles.color(role, is_light_theme)

	if not _write_recolored_svg(source_path, target_path, color):
		return ""

	_save_manifest(target_path, source_path, role, "", true)
	return target_path


static func _create_custom(source_path: String, color: Color) -> String:
	if not _can_use_source(source_path):
		return ""

	_ensure_dir()

	var hex := color.to_html(false)
	var target_path := IN_USE_DIR.path_join("%s_custom_%s.svg" % [_safe_name(source_path), hex])

	if not FileAccess.file_exists(target_path):
		if not _write_recolored_svg(source_path, target_path, color):
			return ""

	_save_manifest(target_path, source_path, IconRoles.CUSTOM, hex, false)
	return target_path


static func _can_use_source(path: String) -> bool:
	return path.get_extension().to_lower() == "svg" and FileAccess.file_exists(path)


static func _ensure_dir() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(IN_USE_DIR))


static func _safe_name(source_path: String) -> String:
	var name := source_path.trim_prefix(SOURCE_ICON_DIR).trim_prefix("/").get_basename()
	return name.replace("/", "__").replace("\\", "__").replace("-", "_").replace(" ", "_").to_snake_case()


static func _write_recolored_svg(source_path: String, target_path: String, color: Color) -> bool:
	var file := FileAccess.open(source_path, FileAccess.READ)
	if file == null:
		return false

	var svg := file.get_as_text()
	file.close()

	svg = _replace_fill(svg, "#" + color.to_html(false))

	file = FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(svg)
	file.close()

	return true


static func _replace_fill(svg: String, hex: String) -> String:
	var original := svg

	svg = _sub(svg, "fill=\"[^\"]*\"", "fill=\"%s\"" % hex)
	svg = _sub(svg, "fill='[^']*'", "fill='%s'" % hex)
	svg = _sub(svg, "fill:\\s*#[0-9a-fA-F]{3,8}", "fill:%s" % hex)
	svg = svg.replace("#ffffff", hex)

	if svg != original:
		return svg

	return _sub(svg, "<path ", "<path fill=\"%s\" " % hex, false)


static func _sub(text: String, pattern: String, replacement: String, all := true) -> String:
	var regex := RegEx.new()

	if regex.compile(pattern) != OK:
		return text

	if regex.search(text) == null:
		return text

	return regex.sub(text, replacement, all)


static func _save_manifest(
		target_path: String,
		source_path: String,
		role: String,
		custom_hex: String,
		theme_managed: bool,
) -> void:
	var config := ConfigFile.new()
	config.load(MANIFEST_PATH)

	config.set_value(target_path, "source", source_path)
	config.set_value(target_path, "role", role)
	config.set_value(target_path, "custom_hex", custom_hex)
	config.set_value(target_path, "theme_managed", theme_managed)

	config.save(MANIFEST_PATH)
