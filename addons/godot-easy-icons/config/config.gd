extends RefCounted

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
const ADDON_DIR: String = "res://addons/godot-easy-icons"
const ICONS_DIR := ADDON_DIR + "/icons"
const GENERATED_DIR := ADDON_DIR + "/generated"
const GENERATED_SCRIPTS_DIR := GENERATED_DIR + "/scripts"
const GENERATED_ICONS_DIR := GENERATED_DIR + "/node_icons"
const NODES_MANIFEST_PATH := GENERATED_ICONS_DIR + "/manifest.cfg"
# ---
const SETTINGS_FILE := "user://godot_easy_icons_settings.cfg"
const SETTING_PROJECT_ICON_DIR := "paths/project_icon_dir"
const DEFAULT_PROJECT_ICON_DIR := "res://easy_icons"
# NOTE:
# Icon roles are stored as strings instead of enum integers because they are
# persisted in filenames and manifest.cfg. This keeps generated icon paths
# stable, readable, and easier for future backward-compatibility across addon versions.
const NODE := "node"
const NODE2D := "node2d"
const CONTROL := "control"
const NODE3D := "node3d"
const DISABLED := "disabled"
const CUSTOM := "custom"
const LABELS := {
	NODE: "Node",
	NODE2D: "Node2D",
	CONTROL: "Control",
	NODE3D: "Node3D",
	DISABLED: "Disabled",
}
const DARK := {
	NODE: Color("#b3b3b3"),
	DISABLED: Color("#b3b3b3"),
	NODE3D: Color("#fc7f7f"),
	NODE2D: Color("#8da5f3"),
	CONTROL: Color("#8eef97"),
}
const LIGHT := {
	NODE: Color("#363636"),
	DISABLED: Color("#363636"),
	NODE3D: Color("#cd3838"),
	NODE2D: Color("#3d64dd"),
	CONTROL: Color("#2fa139"),
}


static func from_node(node: Node) -> String:
	if node is Control:
		return CONTROL

	if node is Node2D:
		return NODE2D

	if node is Node3D:
		return NODE3D

	return NODE


static func color(role: String, is_light_theme: bool) -> Color:
	var palette := LIGHT if is_light_theme else DARK
	return palette.get(role, palette[NODE])


static func is_semantic(role: String) -> bool:
	return role in LABELS
