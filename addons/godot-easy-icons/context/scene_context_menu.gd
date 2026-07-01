@tool
extends EditorContextMenuPlugin

const ADD = preload("res://addons/godot-easy-icons/config/icons/add.svg")

var shortcut = Shortcut.new()
var _owner_plugin: EditorPlugin = null


func _init():
	var event = InputEventKey.new()
	event.keycode = KEY_F3
	shortcut.events = [event]
	add_menu_shortcut(shortcut, _on_add_icon)


func setup(owner_plugin: EditorPlugin) -> void:
	_owner_plugin = owner_plugin


func _popup_menu(paths: PackedStringArray) -> void:
	if paths.is_empty():
		return

	add_context_menu_item_from_shortcut("Add Icon", shortcut, ADD)
	# In case shortcut causes some problem use origin
	# add_context_menu_item("Add Icon", _on_add_icon, ADD)


func _on_add_icon(selected_nodes: Array) -> void:
	if _owner_plugin == null:
		return

	_owner_plugin.handle_add_icon_from_scene_nodes(selected_nodes)
