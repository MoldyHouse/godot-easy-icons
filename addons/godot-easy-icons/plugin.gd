@tool
extends EditorPlugin

const Config := preload("res://addons/godot-easy-icons/config/config.gd")
const SceneContextMenu := preload("res://addons/godot-easy-icons/context/scene_context_menu.gd")
const IconPickerDialog := preload("res://addons/godot-easy-icons/ui/icon_picker_dialog.gd")
const SvgColorizer := preload("res://addons/godot-easy-icons/services/svg_colorizer.gd")
const ScriptIconService := preload("res://addons/godot-easy-icons/services/script_icon_service.gd")
const ThemeService := preload("res://addons/godot-easy-icons/services/theme_service.gd")
const FileSystemService := preload("res://addons/godot-easy-icons/services/filesystem_service.gd")
const SETTINGS_FILE := "user://godot_easy_icons_settings.cfg"

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
var _project_folder_dialog: EditorFileDialog
var _pending_project_icon_data := { }
var _project_icon_dir := Config.DEFAULT_PROJECT_ICON_DIR


func _enter_tree() -> void:
	_load_settings()
	_create_static_dialogs()

	_last_theme_signature = ThemeService.get_signature()

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
	add_tool_menu_item("Godot Easy Icons: Change Project Icon Folder", _change_project_icon_folder)
	set_process_shortcut_input(true)

	print("Godot Easy Icons enabled.")


func _exit_tree() -> void:
	var editor_settings := EditorInterface.get_editor_settings()
	if editor_settings != null and editor_settings.settings_changed.is_connected(_on_editor_settings_changed):
		editor_settings.settings_changed.disconnect(_on_editor_settings_changed)

	remove_tool_menu_item("Godot Easy Icons Browser")
	set_process_shortcut_input(false)

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
	_free_window(_project_folder_dialog)
	_project_folder_dialog = null

	remove_tool_menu_item("Godot Easy Icons Browser")
	remove_tool_menu_item("Godot Easy Icons: Change Project Icon Folder")

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

	if not ScriptIconService.is_supported_script(script):
		_show_alert("Only GDScript and C# scripts are supported.")
		return

	if String(script.resource_path).is_empty():
		_show_alert("This node has a built-in script. Save it as an external file first.")
		return

	_open_icon_picker(node, false)


func _change_project_icon_folder() -> void:
	_pending_project_icon_data.clear()
	_project_folder_dialog.current_dir = _project_icon_dir if not _project_icon_dir.is_empty() else "res://"
	_project_folder_dialog.popup_centered_ratio(0.5)


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

	picker.open_for_node(node, should_attach_script, ThemeService.is_light())
	picker.popup_centered_clamped(Vector2i(760, 560), 0.85)


func _open_icon_browser() -> void:
	var picker := _get_icon_picker()

	if picker == null:
		return

	picker.open_browser(ThemeService.is_light())
	picker.popup_centered_clamped(Vector2i(760, 560), 0.85)


func _get_icon_picker() -> AcceptDialog:
	if is_instance_valid(_icon_picker):
		return _icon_picker

	_icon_picker = IconPickerDialog.new()
	_icon_picker.icon_chosen.connect(_on_icon_chosen)
	_icon_picker.reveal_in_filesystem_requested.connect(_on_reveal_in_filesystem_requested)
	_icon_picker.add_to_project_requested.connect(_on_add_to_project_requested)
	add_child(_icon_picker)

	return _icon_picker


func _on_reveal_in_filesystem_requested(path: String) -> void:
	var dock := EditorInterface.get_file_system_dock()

	if dock == null:
		return

	dock.navigate_to_path(path)


func _on_add_to_project_requested(
		icon_source_path: String,
		role: String,
		custom_color: Color,
		use_custom_color: bool,
) -> void:
	_pending_project_icon_data = {
		"icon_source_path": icon_source_path,
		"role": role,
		"custom_color": custom_color,
		"use_custom_color": use_custom_color,
	}

	if _project_icon_dir.is_empty() or _project_icon_dir == Config.DEFAULT_PROJECT_ICON_DIR:
		_project_folder_dialog.current_dir = "res://"
		_project_folder_dialog.popup_centered_ratio(0.5)
		return

	_add_pending_icon_to_project()


func _on_project_icon_folder_selected(path: String) -> void:
	_project_icon_dir = path
	_save_settings()
	_add_pending_icon_to_project()


func _add_pending_icon_to_project() -> void:
	if _pending_project_icon_data.is_empty():
		return

	var icon_source_path := String(_pending_project_icon_data["icon_source_path"])
	var role := String(_pending_project_icon_data["role"])
	var custom_color := _pending_project_icon_data["custom_color"] as Color
	var use_custom_color := bool(_pending_project_icon_data["use_custom_color"])

	var target_path := FileSystemService.get_project_icon_path(
		_project_icon_dir,
		icon_source_path,
		role,
		custom_color,
		use_custom_color,
	)

	FileSystemService.ensure_dir(target_path.get_base_dir())

	var generated_path := SvgColorizer.create_or_reuse_svg(
		icon_source_path,
		role,
		custom_color,
		use_custom_color,
		ThemeService.is_light(),
		target_path,
	)

	_pending_project_icon_data.clear()

	if generated_path.is_empty():
		_show_alert("Could not add icon to project.")
		return

	var editor_fs := EditorInterface.get_resource_filesystem()
	editor_fs.update_file(generated_path)
	editor_fs.scan()

	FileSystemService.reveal(generated_path)


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
		ThemeService.is_light(),
	)

	if icon_path.is_empty():
		_show_alert("Could not generate or reuse the SVG.")
		return

	var script_path := ""

	if should_attach:
		script_path = ScriptIconService.create_script_for_node(node, icon_path)

		if script_path.is_empty():
			_show_alert("Could not create and attach a script.")
			return

		await ScriptIconService.attach_script_to_node(node, script_path)
	else:
		var script := node.get_script() as Script

		if script == null:
			_show_alert("The selected node no longer has a valid script.")
			return

		script_path = script.resource_path

		if script_path.is_empty():
			_show_alert("This script has no file path.")
			return

		if not ScriptIconService.apply_icon_to_script(script, icon_path):
			_show_alert("Could not write the icon annotation.")
			return

	_pending_node = null
	_pending_attach_script = false

	_finalize_after_icon_apply(script_path, icon_path)
	await _reload_current_saved_scene()

	print("Icon applied to node: ", node_name)


func _create_static_dialogs() -> void:
	_confirm_attach_dialog = ConfirmationDialog.new()
	_confirm_attach_dialog.title = "Attach Script?"
	_confirm_attach_dialog.confirmed.connect(_on_attach_confirmed)
	_confirm_attach_dialog.max_size = Vector2(600, 200)
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
	_alert_dialog.max_size = Vector2(400, 200)
	add_child(_alert_dialog)

	_project_folder_dialog = EditorFileDialog.new()
	_project_folder_dialog.title = "Choose Project Icon Folder"
	_project_folder_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_DIR
	_project_folder_dialog.access = EditorFileDialog.ACCESS_RESOURCES
	_project_folder_dialog.dir_selected.connect(_on_project_icon_folder_selected)
	add_child(_project_folder_dialog)


func _finalize_after_icon_apply(script_path: String, icon_path: String) -> void:
	var editor_fs := EditorInterface.get_resource_filesystem()

	editor_fs.update_file(icon_path)
	editor_fs.update_file(script_path)
	editor_fs.scan()


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
	await get_tree().create_timer(Config.WAITING_TIME).timeout

	_theme_rebuild_queued = false

	var new_signature := ThemeService.get_signature()

	if new_signature == _last_theme_signature:
		return

	_last_theme_signature = new_signature

	await _rebuild_theme_icons_after_theme_change()


func _rebuild_theme_icons_after_theme_change() -> void:
	var changed_files := SvgColorizer.rebuild_theme_managed_icons(ThemeService.is_light())

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


func _free_window(window: Window) -> void:
	if is_instance_valid(window):
		window.queue_free()


func _show_alert(message: String) -> void:
	if not is_instance_valid(_alert_dialog):
		return

	_alert_dialog.dialog_text = message
	_alert_dialog.popup_centered(Vector2i(960, 150))


func _load_settings() -> void:
	var config := ConfigFile.new()

	if config.load(Config.SETTINGS_FILE) != OK:
		_ask_before_attach = true
		_project_icon_dir = Config.DEFAULT_PROJECT_ICON_DIR
		return

	_ask_before_attach = bool(config.get_value("behavior", "ask_before_attach", true))
	_project_icon_dir = String(config.get_value("paths", "project_icon_dir", Config.DEFAULT_PROJECT_ICON_DIR))


func _save_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("behavior", "ask_before_attach", _ask_before_attach)
	config.set_value("paths", "project_icon_dir", _project_icon_dir)

	config.save(Config.SETTINGS_FILE)
