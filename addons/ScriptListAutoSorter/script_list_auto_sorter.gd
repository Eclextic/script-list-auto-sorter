@tool
extends EditorPlugin

func _enter_tree() -> void:
	EditorInterface.get_script_editor().connect(&"editor_script_changed", _on_script_changed)
	
	var editor_settings := EditorInterface.get_editor_settings()
	editor_settings.settings_changed.connect(_on_script_changed)
	
	editor_settings.set_setting(&"script_list_auto_sorter/sort_by", 0)
	editor_settings.add_property_info({
		"name": &"script_list_auto_sorter/sort_by",
		"type": TYPE_INT,
		"hint": PROPERTY_HINT_ENUM,
		"hint_string": "Path,Name"
	})
	
	editor_settings.set_setting(&"script_list_auto_sorter/invert_order", false)
	editor_settings.add_property_info({
		"name": &"script_list_auto_sorter/invert_order",
		"type": TYPE_BOOL,
		"hint": PROPERTY_HINT_NONE,
		"hint_string": ""
	})
	
	_on_script_changed()

func _exit_tree() -> void:
	EditorInterface.get_script_editor().disconnect(&"editor_script_changed", _on_script_changed)
	EditorInterface.get_editor_settings().settings_changed.disconnect(_on_script_changed)
	
	EditorInterface.get_editor_settings().erase(&"script_list_auto_sorter/sort_by")
	EditorInterface.get_editor_settings().erase(&"script_list_auto_sorter/invert_order")


func _on_script_changed(_script: Script = null) -> void:
	var editor := EditorInterface.get_script_editor()
	var open_scripts := editor.get_open_scripts()
	var open_script_editors := editor.get_open_script_editors()
	var parent := open_script_editors[0].get_parent_control()
	
	var script_to_editor_relations: Array[ScriptToEditorRelation]
	for idx in open_scripts.size():
		var script_to_editor_relation := ScriptToEditorRelation.new(open_scripts[idx], open_script_editors[idx])
		script_to_editor_relations.append(script_to_editor_relation)
	
	script_to_editor_relations.sort_custom(_choose_sorting_algorithm())
	
	for idx in script_to_editor_relations.size():
		parent.move_child(script_to_editor_relations[idx].related_editor, idx)

func _choose_sorting_algorithm() -> Callable:
	var sort_by := EditorInterface.get_editor_settings().get_setting(&"script_list_auto_sorter/sort_by")
	var invert_order := EditorInterface.get_editor_settings().get_setting(&"script_list_auto_sorter/invert_order")
	
	var sorting_algorithm: Callable
	match sort_by:
		0: sorting_algorithm = _path_sort
		1: sorting_algorithm = _name_sort
	
	if invert_order:
		return func(a: ScriptToEditorRelation, b: ScriptToEditorRelation) -> bool: return !sorting_algorithm.call(a, b)
	return sorting_algorithm


func _path_sort(a: ScriptToEditorRelation, b: ScriptToEditorRelation) -> bool:
	return a.open_script.resource_path.naturalnocasecmp_to(b.open_script.resource_path) <= 0

func _name_sort(a: ScriptToEditorRelation, b: ScriptToEditorRelation) -> bool:
	return a.open_script.resource_path.get_file().naturalnocasecmp_to(b.open_script.resource_path.get_file()) <= 0


class ScriptToEditorRelation:
	var open_script: Script
	var related_editor: ScriptEditorBase
	
	func _init(open_script: Script, related_editor: ScriptEditorBase) -> void:
		self.open_script = open_script
		self.related_editor = related_editor
