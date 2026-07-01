@tool
extends EditorPlugin

const SceneContextMenu := preload("res://addons/godot-easy-icons/scene_context_menu.gd")
const IconPickerDialog := preload("res://addons/godot-easy-icons/icon_picker_dialog.gd")
const SvgColorizer := preload("res://addons/godot-easy-icons/svg_colorizer.gd")
const SETTINGS_FILE := "user://godot_easy_icons_settings.cfg"
const GENERATED_SCRIPT_DIR := "res://addons/godot-easy-icons/generated_scripts"
# IMPORTANT
# About WAITING_TIME
# As the theme_changed signal changed when select but doesn't have another signal
# for when the theme finalized changing, I had to create this work around to make
# it work as intended without major problems.
# IN CASE your computer takes more time to refresh the theme than 2s and the colors doesn't update
# it means that the plugin updated before the `base_color` inside the theme changed
# In order to fix eventual problem due to your hardware, simple increase this value
# until it's good for you. In my case, 1.5 is perfect but I decided to put 2.0 for safety rule.
const WAITING_TIME := 2.0

var _scene_context_menu: EditorContextMenuPlugin
var _icon_picker: AcceptDialog
var _confirm_attach_dialog: ConfirmationDialog
var _dont_ask_attach_check: CheckBox
var _alert_dialog: AcceptDialog
var _pending_node: Node = null
var _pending_attach_script := false
var _ask_before_attach := true
var _last_theme_signature := ""
var _theme_rebuild_queued := false


func _enter_tree() -> void:
	_load_settings()
	_create_static_dialogs()

	_last_theme_signature = _get_theme_signature()

	var editor_settings := EditorInterface.get_editor_settings()
	if editor_settings != null and not editor_settings.settings_changed.is_connected(_on_editor_settings_changed):
		editor_settings.settings_changed.connect(_on_editor_settings_changed)

	_scene_context_menu = SceneContextMenu.new()
	_scene_context_menu.setup(self)

	add_context_menu_plugin(
		EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE,
		_scene_context_menu,
	)
	add_tool_menu_item("Godot Easy Icons Browser", _open_icon_browser)
	set_process_shortcut_input(true)
	print("Godot Easy Icons enabled.")
	#_test_csharp_icon_builder()


func _exit_tree() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	if editor_settings != null and editor_settings.settings_changed.is_connected(_on_editor_settings_changed):
		editor_settings.settings_changed.disconnect(_on_editor_settings_changed)

	if _scene_context_menu != null:
		remove_context_menu_plugin(_scene_context_menu)
		_scene_context_menu = null

	_free_window(_icon_picker)
	_free_window(_confirm_attach_dialog)
	_free_window(_alert_dialog)

	_icon_picker = null
	_confirm_attach_dialog = null
	_alert_dialog = null
	_pending_node = null
	set_process_shortcut_input(false)
	print("Godot Easy Icons disabled.")


func handle_add_icon_from_scene_nodes(selected_nodes: Array) -> void:
	if selected_nodes.is_empty():
		return

	if selected_nodes.size() > 1:
		_show_alert("For now, select only one node at a time.")
		return

	var node := selected_nodes[0] as Node
	if node == null:
		_show_alert("The selected item is not a valid node.")
		return

	var script := node.get_script()

	if script == null:
		_pending_node = node
		_pending_attach_script = true

		if _ask_before_attach:
			_dont_ask_attach_check.button_pressed = false
			_confirm_attach_dialog.popup_centered(Vector2i(520, 190))
		else:
			_open_icon_picker(node, true)

		return

	if not _is_supported_script(script):
		_show_alert("Only GDScript and C# scripts are supported.")
		return

	if String(script.resource_path).is_empty():
		_show_alert("This node has a built-in script. Save it as an external .gd file first.")
		return

	_open_icon_picker(node, false)


func _shortcut_input(event: InputEvent) -> void:
	var key := event as InputEventKey

	if key == null:
		return

	if not key.pressed or key.echo:
		return

	if not key.ctrl_pressed or key.keycode != KEY_PERIOD:
		return

	var selected_nodes := EditorInterface.get_selection().get_selected_nodes()

	if selected_nodes.size() != 1:
		_show_alert("Select one node in the Scene Tree first.")
		return

	get_viewport().set_input_as_handled()
	handle_add_icon_from_scene_nodes(selected_nodes)


# Using this to text if C# update is running okay even when you don't have it
# Add to _entry_tree for a quick test and tweak the input as much as you want.
func _test_csharp_icon_builder() -> void:
	var input := """using Godot;

[GlobalClass, Icon("res://old.svg")] // This should be replaced
public partial class MyNode : Node
{
	something inside here // This should not be touched
}
"""

	var output := _build_csharp_code_with_icon(
		input,
		"res://addons/godot-easy-icons/in_use/bunny_node.svg",
	)

	print(output)


func _is_supported_script(script: Script) -> bool:
	if script is GDScript:
		return true

	# Avoid hard dependency errors if C# support is not available.
	return script.get_class() == "CSharpScript"


func _on_attach_confirmed() -> void:
	if _dont_ask_attach_check.button_pressed:
		_ask_before_attach = false
		_save_settings()

	if not is_instance_valid(_pending_node):
		_show_alert("The selected node is no longer valid.")
		return

	_open_icon_picker(_pending_node, true)


func _open_icon_picker(node: Node, should_attach_script: bool) -> void:
	if not is_instance_valid(node):
		_show_alert("The selected node is no longer valid.")
		return

	var picker := _get_icon_picker()
	if picker == null:
		_show_alert("Could not create the icon picker.")
		return

	_pending_node = node
	_pending_attach_script = should_attach_script

	picker.open_for_node(node, should_attach_script, _is_light_editor_theme())
	picker.popup_centered_clamped(Vector2i(760, 560), 0.85)


func _get_icon_picker() -> AcceptDialog:
	if is_instance_valid(_icon_picker):
		return _icon_picker

	_icon_picker = IconPickerDialog.new()
	_icon_picker.icon_chosen.connect(_on_icon_chosen)
	_icon_picker.reveal_in_filesystem_requested.connect(_on_reveal_in_filesystem_requested)
	add_child(_icon_picker)

	return _icon_picker


func _open_icon_browser() -> void:
	var picker := _get_icon_picker()

	if picker == null:
		return

	picker.open_browser(_is_light_editor_theme())
	picker.popup_centered_clamped(Vector2i(760, 560), 0.85)


func _on_reveal_in_filesystem_requested(path: String) -> void:
	var dock := EditorInterface.get_file_system_dock()

	if dock == null:
		return

	dock.navigate_to_path(path)


func _on_icon_chosen(
		icon_source_path: String,
		role: String,
		custom_color: Color,
		use_custom_color: bool,
) -> void:
	if not is_instance_valid(_pending_node):
		_show_alert("The selected node is no longer valid.")
		return

	var node := _pending_node
	var node_name := String(node.name)
	var should_attach := _pending_attach_script

	var icon_path := SvgColorizer.create_or_reuse_svg(
		icon_source_path,
		role,
		custom_color,
		use_custom_color,
		_is_light_editor_theme(),
	)

	if icon_path.is_empty():
		_show_alert("Could not generate or reuse the SVG.")
		return

	var script_path := ""

	if should_attach:
		script_path = _create_script_for_node(node, icon_path)
		if script_path.is_empty():
			_show_alert("Could not create and attach a script.")
			return

		await _attach_script_to_node(node, script_path)
	else:
		var script := node.get_script() as GDScript
		if script == null:
			_show_alert("The selected node no longer has a valid GDScript.")
			return

		script_path = script.resource_path
		if script_path.is_empty():
			_show_alert("This script has no file path.")
			return

		if not _apply_icon_to_script(script, icon_path):
			_show_alert("Could not write the icon annotation.")
			return

	_pending_node = null
	_pending_attach_script = false

	await _finalize_after_icon_apply(script_path, icon_path)

	print("Icon applied to node: ", node_name)


func _create_static_dialogs() -> void:
	_confirm_attach_dialog = ConfirmationDialog.new()
	_confirm_attach_dialog.title = "Attach Script?"
	_confirm_attach_dialog.confirmed.connect(_on_attach_confirmed)
	add_child(_confirm_attach_dialog)

	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(420, 80)

	var label := Label.new()
	label.text = "This node does not have a script. To use @icon, Godot Easy Icons needs to create and attach a GDScript file first."
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(label)

	_dont_ask_attach_check = CheckBox.new()
	_dont_ask_attach_check.text = "Don't ask again"
	box.add_child(_dont_ask_attach_check)

	_confirm_attach_dialog.add_child(box)

	_alert_dialog = AcceptDialog.new()
	_alert_dialog.title = "Godot Easy Icons"
	add_child(_alert_dialog)


func _free_window(window: Window) -> void:
	if is_instance_valid(window):
		window.queue_free()


func _show_alert(message: String) -> void:
	if not is_instance_valid(_alert_dialog):
		return

	_alert_dialog.dialog_text = message
	_alert_dialog.popup_centered(Vector2i(460, 150))


func _create_script_for_node(node: Node, icon_path: String) -> String:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(GENERATED_SCRIPT_DIR))

	var base_name := String(node.name).to_snake_case()
	if base_name.is_empty():
		base_name = "node_script"

	var script_path := _get_unique_script_path(GENERATED_SCRIPT_DIR.path_join(base_name + ".gd"))

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


func _get_unique_script_path(base_path: String) -> String:
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


func _attach_script_to_node(node: Node, script_path: String) -> void:
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


func _apply_icon_to_script(script: Script, icon_path: String) -> bool:
	if script is GDScript:
		return _apply_icon_to_gdscript(script as GDScript, icon_path)

	if script.get_class() == "CSharpScript":
		return _apply_icon_to_csharp(script, icon_path)

	return false


func _apply_icon_to_gdscript(script: GDScript, icon_path: String) -> bool:
	var new_code := _build_gdscript_code_with_icon(script.source_code, icon_path)

	script.source_code = new_code

	if ResourceSaver.save(script) != OK:
		return false

	script.reload(true)
	_reload_open_code_edit(script, new_code)

	return true


func _build_gdscript_code_with_icon(source_code: String, icon_path: String) -> String:
	var lines := source_code.split("\n", true)
	var cleaned: Array[String] = []

	for line in lines:
		if not line.strip_edges().begins_with("@icon("):
			cleaned.append(line)

	cleaned.insert(_find_icon_insert_index(cleaned), "@icon(\"%s\")" % icon_path)

	return "\n".join(cleaned)


func _apply_icon_to_csharp(script: Script, icon_path: String) -> bool:
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


func _build_csharp_code_with_icon(source_code: String, icon_path: String) -> String:
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


func _regex_sub(text: String, pattern: String, replacement: String) -> String:
	var regex := RegEx.new()

	if regex.compile(pattern) != OK:
		return text

	return regex.sub(text, replacement, true)


func _build_code_with_icon(source_code: String, icon_path: String) -> String:
	var lines := source_code.split("\n", true)
	var cleaned: Array[String] = []

	for line in lines:
		if not line.strip_edges().begins_with("@icon("):
			cleaned.append(line)

	cleaned.insert(_find_icon_insert_index(cleaned), "@icon(\"%s\")" % icon_path)

	return "\n".join(cleaned)


func _find_icon_insert_index(lines: Array[String]) -> int:
	for i in range(lines.size()):
		var trimmed := lines[i].strip_edges()

		if trimmed.is_empty():
			continue

		if trimmed == "@tool":
			return i + 1

		return i

	return 0


func _reload_open_code_edit(script: Script, new_code: String) -> void:
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


func _reload_code_edit(code_edit: CodeEdit, new_text: String, tag_saved := false) -> void:
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


func _finalize_after_icon_apply(script_path: String, icon_path: String) -> void:
	var editor_fs := EditorInterface.get_resource_filesystem()

	editor_fs.update_file(icon_path)
	editor_fs.update_file(script_path)
	editor_fs.scan()

	await _reload_current_saved_scene()


func _reload_current_saved_scene() -> void:
	var root := EditorInterface.get_edited_scene_root()
	if root == null:
		_show_alert("Icon applied, but no edited scene was found to reload.")
		return

	var scene_path := root.scene_file_path
	if scene_path.is_empty():
		_show_alert("Icon applied, but the current scene must be saved before it can be reloaded.")
		return

	if EditorInterface.save_scene() != OK:
		_show_alert("Icon applied, but the scene could not be saved before reload.")
		return

	await get_tree().process_frame
	EditorInterface.reload_scene_from_path(scene_path)


func _on_editor_settings_changed() -> void:
	if _theme_rebuild_queued:
		return

	_theme_rebuild_queued = true
	_check_theme_change_after_delay()


func _check_theme_change_after_delay() -> void:
	await get_tree().create_timer(WAITING_TIME).timeout

	_theme_rebuild_queued = false

	var new_signature := _get_theme_signature()
	if new_signature == _last_theme_signature:
		return

	_last_theme_signature = new_signature

	await _rebuild_theme_icons_after_theme_change()


func _rebuild_theme_icons_after_theme_change() -> void:
	var changed_files := SvgColorizer.rebuild_theme_managed_icons(_is_light_editor_theme())
	if changed_files.is_empty():
		return

	var editor_fs := EditorInterface.get_resource_filesystem()

	for path in changed_files:
		editor_fs.update_file(path)

	editor_fs.reimport_files(PackedStringArray(changed_files))
	editor_fs.scan()

	await _wait_for_editor_filesystem_idle()

	var root := EditorInterface.get_edited_scene_root()
	if root == null or root.scene_file_path.is_empty():
		return

	EditorInterface.reload_scene_from_path(root.scene_file_path)


func _wait_for_editor_filesystem_idle() -> void:
	var editor_fs := EditorInterface.get_resource_filesystem()
	if editor_fs == null:
		return

	while editor_fs.is_scanning():
		await get_tree().process_frame


func _is_light_editor_theme() -> bool:
	var settings := EditorInterface.get_editor_settings()
	if settings == null:
		return false

	var base_color := Color.BLACK

	if settings.has_setting("interface/theme/base_color"):
		base_color = settings.get_setting("interface/theme/base_color")

	var luminance := 0.2126 * base_color.r + 0.7152 * base_color.g + 0.0722 * base_color.b
	return luminance > 0.5


func _get_theme_signature() -> String:
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


func _load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(SETTINGS_FILE) != OK:
		_ask_before_attach = true
		return

	_ask_before_attach = bool(config.get_value("behavior", "ask_before_attach", true))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("behavior", "ask_before_attach", _ask_before_attach)
	config.save(SETTINGS_FILE)
