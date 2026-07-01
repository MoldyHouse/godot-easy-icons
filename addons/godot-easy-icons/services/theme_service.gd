extends RefCounted


static func get_signature() -> String:
	var settings := EditorInterface.get_editor_settings()
	if settings == null:
		return ""

	var base_color := Color.BLACK
	var preset := ""

	if settings.has_setting("interface/theme/base_color"):
		base_color = settings.get_setting("interface/theme/base_color")

	if settings.has_setting("interface/theme/preset"):
		preset = String(settings.get_setting("interface/theme/preset"))

	return "%s|%s" % [preset, base_color.to_html(false)]


static func is_light() -> bool:
	var settings := EditorInterface.get_editor_settings()
	if settings == null:
		return false

	var base_color := Color.BLACK

	if settings.has_setting("interface/theme/base_color"):
		base_color = settings.get_setting("interface/theme/base_color")

	var luminance := 0.2126 * base_color.r + 0.7152 * base_color.g + 0.0722 * base_color.b
	return luminance > 0.5
