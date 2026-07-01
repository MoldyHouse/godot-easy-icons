@tool
extends RefCounted

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
