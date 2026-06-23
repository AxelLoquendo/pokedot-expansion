@tool
extends ConfirmationDialog

class_name CreatorWindow

@onready var name_edit: LineEdit = $VBoxContainer/LineEdit
@onready var generation: OptionButton = $VBoxContainer/OptionButton

@onready var generation_label = $VBoxContainer/GenerationLabel
@onready var generation_button = $VBoxContainer/OptionButton

func show_generation_selector(ver: bool):
	generation_label.visible = ver
	generation_button.visible = ver

func _ready():
	generation.clear()

	generation.add_item("Gen1")
	generation.add_item("Gen2")
	generation.add_item("Gen3")
	generation.add_item("Gen4")
	generation.add_item("Gen5")
	generation.add_item("Gen6")
	generation.add_item("Gen7")
	generation.add_item("Gen8")
	generation.add_item("Gen9")

func get_resource_name() -> String:
	return name_edit.text

func get_generation() -> String:
	return generation.get_item_text(
		generation.selected
	)
