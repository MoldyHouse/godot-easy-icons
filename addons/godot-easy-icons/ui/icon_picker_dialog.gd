@tool
extends AcceptDialog

signal icon_chosen(
		icon_source_path: String,
		role: String,
		custom_color: Color,
		use_custom_color: bool,
)
signal add_to_project_requested(
		icon_source_path: String,
		role: String,
		custom_color: Color,
		use_custom_color: bool,
)
signal reveal_in_filesystem_requested(icon_source_path: String)

const ADD = preload("res://addons/godot-easy-icons/config/icons/add.svg")
const CODE_ANALYSIS = preload("res://addons/godot-easy-icons/config/icons/code-analysis.svg")
const COPY_PASTE = preload("res://addons/godot-easy-icons/config/icons/copy-paste.svg")
const SIGN_AT = preload("res://addons/godot-easy-icons/config/icons/sign-at.svg")
const Config := preload("res://addons/godot-easy-icons/config/config.gd")

var _target_node: Node = null
var _should_attach_script := false
var _all_icons: Array[String] = []
var _filtered_icons: Array[String] = []
var _generated_icons: Dictionary = { }
var _search_edit: LineEdit
var _item_list: ItemList
var _color_picker: ColorPickerButton
var _info_label: Label
var _selected_icon_path := ""
var _selected_role := "node"
var _use_custom_color := false
var _is_light_theme := false
var _role_buttons: Dictionary = { }
var _copy_path_button: Button
var _reveal_button: Button
var _loading_label: Label
var _add_to_project_button: Button


func _ready() -> void:
	print_debug(ThemeDB.get_default_theme())

	title = "Add Icon"
	min_size = Vector2i(760, 560)

	confirmed.connect(_on_confirmed)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(panel)

	var margin_c = MarginContainer.new()
	margin_c.add_theme_constant_override("margin_*", 24)
	panel.add_child(margin_c)

	var root := VBoxContainer.new()
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin_c.add_child(root)

	_info_label = Label.new()
	_info_label.text = "Choose an icon and color."
	root.add_child(_info_label)

	_loading_label = Label.new()
	_loading_label.text = "Loading icons..."
	_loading_label.visible = false
	root.add_child(_loading_label)

	_search_edit = LineEdit.new()
	_search_edit.placeholder_text = "Search icons..."
	_search_edit.text_changed.connect(_on_search_changed)
	root.add_child(_search_edit)

	_item_list = ItemList.new()

	_item_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_list.allow_reselect = true
	_item_list.item_selected.connect(_on_item_selected)
	root.add_child(_item_list)

	# ------------------
	var separator := HSeparator.new()
	root.add_child(separator)

	var color_row := HBoxContainer.new()
	root.add_child(color_row)

	for role in Config.LABELS.keys():
		var button := Button.new()
		button.text = Config.LABELS[role]

		button.pressed.connect(
			func(bound_role: String = role) -> void:
				_select_role(bound_role)
		)

		color_row.add_child(button)
		_role_buttons[role] = button

	var custom_button := Button.new()
	custom_button.text = "Custom"
	custom_button.pressed.connect(
		func() -> void:
			_selected_role = Config.CUSTOM
			_use_custom_color = true
	)
	color_row.alignment = BoxContainer.ALIGNMENT_CENTER
	color_row.add_child(custom_button)

	_color_picker = ColorPickerButton.new()
	_color_picker.custom_minimum_size = Vector2(160, 32)
	_color_picker.color_changed.connect(
		func(_new_color: Color) -> void:
			_selected_role = Config.CUSTOM
			_use_custom_color = true
	)
	color_row.add_child(_color_picker)

	# ---------------
	root.add_child(separator.duplicate())

	var action_row := HBoxContainer.new()
	root.add_child(action_row)

	action_row.alignment = BoxContainer.ALIGNMENT_CENTER

	_copy_path_button = Button.new()
	_copy_path_button.text = "Copy Path"
	_copy_path_button.icon = COPY_PASTE
	_copy_path_button.disabled = true
	_copy_path_button.pressed.connect(_on_copy_path_pressed)
	action_row.add_child(_copy_path_button)

	_add_to_project_button = Button.new()
	_add_to_project_button.text = "Add to Project"
	_add_to_project_button.icon = ADD
	_add_to_project_button.disabled = true
	_add_to_project_button.pressed.connect(_on_add_to_project_pressed)
	action_row.add_child(_add_to_project_button)

	_reveal_button = Button.new()
	_reveal_button.text = "In FileSystem"
	_reveal_button.icon = CODE_ANALYSIS
	_reveal_button.disabled = true
	_reveal_button.pressed.connect(_on_reveal_pressed)
	action_row.add_child(_reveal_button)

	get_ok_button().text = "Add to Script"
	get_ok_button().disabled = true
	get_ok_button().icon = SIGN_AT


func open_browser(is_light_theme: bool) -> void:
	_target_node = null
	_should_attach_script = false
	_is_light_theme = is_light_theme
	_selected_icon_path = ""

	_select_role(Config.NODE)
	_refresh_role_button_colors()

	_search_edit.text = ""
	_info_label.text = "Choose an icon."

	_scan_icons()
	await _refresh_list("")
	_update_action_buttons()


func open_for_node(node: Node, should_attach_script: bool, is_light_theme: bool) -> void:
	_target_node = node
	_should_attach_script = should_attach_script
	_is_light_theme = is_light_theme
	_selected_icon_path = ""

	var default_role := Config.from_node(node)
	_select_role(default_role)
	_refresh_role_button_colors()

	_search_edit.text = ""
	_info_label.text = "Node: %s" % String(node.name)

	if should_attach_script:
		_info_label.text += "  —  A script will be created."

	_scan_icons()
	_refresh_list("")
	_update_action_buttons()


func _refresh_role_button_colors() -> void:
	for role in _role_buttons.keys():
		var button := _role_buttons[role] as Button
		var color := Config.color(role, _is_light_theme)

		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_hover_color", color)
		button.add_theme_color_override("font_pressed_color", color)


func _select_role(role: String) -> void:
	_selected_role = role
	_use_custom_color = false
	_color_picker.color = Config.color(role, _is_light_theme)


func _scan_icons() -> void:
	_all_icons.clear()
	_generated_icons.clear()

	_scan_dir_for_svgs(Config.ICONS_DIR, _all_icons)
	_scan_generated_icons()


func _scan_generated_icons() -> void:
	var generated_paths: Array[String] = []
	_scan_dir_for_svgs(Config.GENERATED_ICONS_DIR, generated_paths)

	for path in generated_paths:
		_generated_icons[path] = true


func _scan_dir_for_svgs(path: String, output: Array[String]) -> void:
	var dir := DirAccess.open(path)

	if dir == null:
		push_error("Could not open icon directory: " + path)
		return

	dir.list_dir_begin()

	var file_name := dir.get_next()

	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue

		var full_path := path.path_join(file_name)

		if dir.current_is_dir():
			_scan_dir_for_svgs(full_path, output)
		else:
			if file_name.get_extension().to_lower() == "svg":
				output.append(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()


func _on_search_changed(new_text: String) -> void:
	await _refresh_list(new_text)


func _refresh_list(query: String) -> void:
	_loading_label.visible = true
	_item_list.visible = false

	await get_tree().process_frame

	_item_list.clear()
	_filtered_icons.clear()

	var scored: Array[Dictionary] = []

	for icon_path in _all_icons:
		var file_name := icon_path.get_file().get_basename()
		var score := _fuzzy_score(query, file_name)

		if score >= 0:
			scored.append(
				{
					"path": icon_path,
					"score": score,
				},
			)

	scored.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a["score"]) > int(b["score"])
	)

	for entry in scored:
		var icon_path := String(entry["path"])
		_filtered_icons.append(icon_path)

		var display_name := icon_path.get_file().get_basename()
		var texture: Texture2D = load(icon_path)

		var index := _item_list.add_item(display_name, texture)
		_item_list.set_item_metadata(index, icon_path)

	_item_list.sort_items_by_text()

	_loading_label.visible = false
	_item_list.visible = true


func _fuzzy_score(query: String, candidate: String) -> int:
	query = query.strip_edges().to_lower()
	candidate = candidate.to_lower()

	if query.is_empty():
		return 1

	var query_index := 0
	var score := 0
	var consecutive_bonus := 0
	var last_match_index := -2

	for i in range(candidate.length()):
		if query_index >= query.length():
			break

		var candidate_char := candidate.substr(i, 1)
		var query_char := query.substr(query_index, 1)

		if candidate_char == query_char:
			score += 10

			if i == last_match_index + 1:
				consecutive_bonus += 5
				score += consecutive_bonus
			else:
				consecutive_bonus = 0

			if i == query_index:
				score += 3

			last_match_index = i
			query_index += 1

	if query_index < query.length():
		return -1

	score -= candidate.length()
	return score


func _on_item_selected(index: int) -> void:
	_selected_icon_path = String(_item_list.get_item_metadata(index))
	_update_action_buttons()


func _on_add_to_project_pressed() -> void:
	if _selected_icon_path.is_empty():
		return

	add_to_project_requested.emit(
		_selected_icon_path,
		_selected_role,
		_color_picker.color,
		_use_custom_color,
	)


func _update_action_buttons() -> void:
	var has_icon := not _selected_icon_path.is_empty()

	get_ok_button().disabled = not has_icon or _target_node == null
	_copy_path_button.disabled = not has_icon
	_reveal_button.disabled = not has_icon
	_add_to_project_button.disabled = not has_icon


func _on_copy_path_pressed() -> void:
	if _selected_icon_path.is_empty():
		return

	DisplayServer.clipboard_set(_selected_icon_path)


func _on_reveal_pressed() -> void:
	if _selected_icon_path.is_empty():
		return

	reveal_in_filesystem_requested.emit(_selected_icon_path)


func _on_confirmed() -> void:
	if _selected_icon_path.is_empty():
		return

	if _target_node == null:
		return

	get_ok_button().disabled = true
	hide()

	icon_chosen.emit(
		_selected_icon_path,
		_selected_role,
		_color_picker.color,
		_use_custom_color,
	)
