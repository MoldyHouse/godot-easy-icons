extends RefCounted

const Config = preload("res://addons/godot-easy-icons/config/config.gd")


static func is_supported_script(script: Script) -> bool:
	if script is GDScript:
		return true

	# Avoid hard dependency errors if C# support is not available.
	return script.get_class() == "CSharpScript"


static func create_script_for_node(node: Node, icon_path: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(Config.GENERATED_SCRIPTS_DIR))

	var base_name := String(node.name).to_snake_case()
	if base_name.is_empty():
		base_name = "node_script"

	var script_path := _get_unique_script_path(Config.GENERATED_SCRIPTS_DIR.path_join(base_name + ".gd"))

	var content := ""
	content += "@icon(\"%s\")\n" % icon_path
	content += "extends %s\n\n" % node.get_class()

	var script := GDScript.new()
	script.source_code = content
	script.resource_path = script_path

	if ResourceSaver.save(script) != OK:
		return ""

	script.reload(true)

	return script_path


static func attach_script_to_node(node: Node, script_path: String) -> void:
	var script := ResourceLoader.load(
		script_path,
		"GDScript",
		ResourceLoader.CACHE_MODE_REPLACE,
	) as GDScript

	if script == null:
		return

	script.reload(true)
	node.set_script(script)

	EditorInterface.get_resource_filesystem().update_file(script_path)


static func apply_icon_to_script(script: Script, icon_path: String) -> bool:
	if script is GDScript:
		return _apply_icon_to_gdscript(script as GDScript, icon_path)

	if script.get_class() == "CSharpScript":
		return _apply_icon_to_csharp(script, icon_path)

	return false


static func _get_unique_script_path(base_path: String) -> String:
	if not FileAccess.file_exists(base_path):
		return base_path

	var dir := base_path.get_base_dir()
	var stem := base_path.get_file().get_basename()
	var ext := base_path.get_extension()
	var index := 2

	while true:
		var candidate := dir.path_join("%s_%d.%s" % [stem, index, ext])
		if not FileAccess.file_exists(candidate):
			return candidate

		index += 1

	return base_path


static func _apply_icon_to_gdscript(script: GDScript, icon_path: String) -> bool:
	var new_code := _build_gdscript_code_with_icon(script.source_code, icon_path)

	script.source_code = new_code

	if ResourceSaver.save(script) != OK:
		return false

	script.reload(true)
	_reload_open_code_edit(script, new_code)

	return true


static func _build_gdscript_code_with_icon(source_code: String, icon_path: String) -> String:
	var lines := source_code.split("\n", true)
	var cleaned: Array[String] = []

	for line in lines:
		if not line.strip_edges().begins_with("@icon("):
			cleaned.append(line)

	cleaned.insert(_find_icon_insert_index(cleaned), "@icon(\"%s\")" % icon_path)

	return "\n".join(cleaned)


static func _apply_icon_to_csharp(script: Script, icon_path: String) -> bool:
	var script_path := script.resource_path

	if script_path.is_empty():
		return false

	var file := FileAccess.open(script_path, FileAccess.READ)
	if file == null:
		return false

	var source_code := file.get_as_text()
	file.close()

	var new_code := _build_csharp_code_with_icon(source_code, icon_path)

	file = FileAccess.open(script_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(new_code)
	file.flush()
	file.close()

	var editor_fs := EditorInterface.get_resource_filesystem()
	editor_fs.update_file(script_path)
	editor_fs.scan()

	_reload_open_code_edit(script, new_code)

	return true


static func _build_csharp_code_with_icon(source_code: String, icon_path: String) -> String:
	var code := source_code

	# Remove standalone [Icon("...")] lines.
	code = _regex_sub(
		code,
		"(?m)^\\s*\\[\\s*Icon\\s*\\(\\s*@?\"[^\"]*\"\\s*\\)\\s*\\]\\s*\\n?",
		"",
	)

	# Remove Icon("...") from combined attribute lists.
	code = _regex_sub(
		code,
		"\\s*,\\s*Icon\\s*\\(\\s*@?\"[^\"]*\"\\s*\\)",
		"",
	)

	code = _regex_sub(
		code,
		"Icon\\s*\\(\\s*@?\"[^\"]*\"\\s*\\)\\s*,\\s*",
		"",
	)

	var icon_attribute := "Icon(\"%s\")" % icon_path

	# If [GlobalClass] exists, prefer [GlobalClass, Icon("...")].
	var global_class_regex := RegEx.new()
	global_class_regex.compile("\\[([^\\]]*\\bGlobalClass\\b[^\\]]*)\\]")

	var match_text := global_class_regex.search(code)

	if match_text != null:
		var existing_attrs := match_text.get_string(1).strip_edges()
		var replacement := "[%s, %s]" % [existing_attrs, icon_attribute]
		return global_class_regex.sub(code, replacement, false)

	# Otherwise insert [Icon("...")] before the class declaration.
	var class_regex := RegEx.new()
	class_regex.compile("(?m)^\\s*public\\s+partial\\s+class\\s+")

	match_text = class_regex.search(code)

	if match_text == null:
		return code

	var insert_at := match_text.get_start()
	return code.substr(0, insert_at) + "[%s]\n" % icon_attribute + code.substr(insert_at)


static func _regex_sub(text: String, pattern: String, replacement: String) -> String:
	var regex := RegEx.new()

	if regex.compile(pattern) != OK:
		return text

	return regex.sub(text, replacement, true)


static func _build_code_with_icon(source_code: String, icon_path: String) -> String:
	var lines := source_code.split("\n", true)
	var cleaned: Array[String] = []

	for line in lines:
		if not line.strip_edges().begins_with("@icon("):
			cleaned.append(line)

	cleaned.insert(_find_icon_insert_index(cleaned), "@icon(\"%s\")" % icon_path)

	return "\n".join(cleaned)


static func _find_icon_insert_index(lines: Array[String]) -> int:
	for i in range(lines.size()):
		var trimmed := lines[i].strip_edges()

		if trimmed.is_empty():
			continue

		if trimmed == "@tool":
			return i + 1

		return i

	return 0


static func _reload_open_code_edit(script: Script, new_code: String) -> void:
	var script_editor := EditorInterface.get_script_editor()
	if script_editor == null:
		return

	var open_scripts := script_editor.get_open_scripts()
	if not open_scripts.has(script):
		return

	var open_editors := script_editor.get_open_script_editors()

	if script_editor.get_current_script() == script:
		_reload_code_edit(script_editor.get_current_editor().get_base_editor(), new_code, true)
		return

	if open_scripts.size() != open_editors.size():
		return

	for i in range(open_scripts.size()):
		if open_scripts[i] == script:
			_reload_code_edit(open_editors[i].get_base_editor(), new_code, true)
			return


static func _reload_code_edit(code_edit: CodeEdit, new_text: String, tag_saved := false) -> void:
	if code_edit == null:
		return

	var caret_line := code_edit.get_caret_line()
	var caret_column := code_edit.get_caret_column()
	var scroll_horizontal := code_edit.scroll_horizontal
	var scroll_vertical := code_edit.scroll_vertical

	code_edit.text = new_text

	if tag_saved:
		code_edit.tag_saved_version()

	var line_count := code_edit.get_line_count()
	code_edit.set_caret_line(clamp(caret_line, 0, max(0, line_count - 1)))

	var max_column := code_edit.get_line(code_edit.get_caret_line()).length()
	code_edit.set_caret_column(clamp(caret_column, 0, max_column))

	code_edit.scroll_horizontal = scroll_horizontal
	code_edit.scroll_vertical = scroll_vertical
	code_edit.update_minimum_size()
	code_edit.text_changed.emit()


static func _finalize_after_icon_apply(script_path: String, icon_path: String) -> void:
	var editor_fs := EditorInterface.get_resource_filesystem()

	editor_fs.update_file(icon_path)
	editor_fs.update_file(script_path)
	editor_fs.scan()
