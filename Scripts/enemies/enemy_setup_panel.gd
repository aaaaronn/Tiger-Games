extends Control

signal generation_requested(descriptions: Array[String], api_key: String)
signal offline_requested

var description_inputs: Array[LineEdit] = []
var api_key_input: LineEdit
var status_label: Label
var generate_button: Button
var offline_button: Button

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	build_interface()
	api_key_input.text = OS.get_environment("GEMINI_API_KEY")

func build_interface() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.025, 0.04, 0.035, 0.96)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(620.0, 0.0)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("101b17")
	panel_style.border_color = Color("648273")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margins := MarginContainer.new()
	for margin_name in ["margin_left", "margin_top", "margin_right", "margin_bottom"]:
		margins.add_theme_constant_override(margin_name, 24)
	panel.add_child(margins)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	margins.add_child(content)

	var heading := Label.new()
	heading.text = "BUILD YOUR ENEMY ROSTER"
	heading.add_theme_font_size_override("font_size", 28)
	heading.add_theme_color_override("font_color", Color("e4f1df"))
	content.add_child(heading)

	var intro := Label.new()
	intro.text = "Describe three creatures. Gemini will generate one sprite for each strength tier before the first wave."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", Color("a9b9ac"))
	content.add_child(intro)

	_add_description_input(content, "TIER 1  |  COMMON", "e.g. a quick, wiry swamp crawler")
	_add_description_input(content, "TIER 2  |  DANGEROUS", "e.g. an armored creature with a glowing core")
	_add_description_input(content, "TIER 3  |  ELITE", "e.g. a towering fungal boss")

	var key_label := Label.new()
	key_label.text = "GEMINI API KEY"
	key_label.add_theme_color_override("font_color", Color("d5e2d7"))
	content.add_child(key_label)

	api_key_input = LineEdit.new()
	api_key_input.placeholder_text = "Read from GEMINI_API_KEY if left blank"
	api_key_input.secret = true
	api_key_input.custom_minimum_size.y = 40.0
	content.add_child(api_key_input)

	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.add_theme_color_override("font_color", Color("f0c975"))
	content.add_child(status_label)

	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_END
	actions.add_theme_constant_override("separation", 10)
	content.add_child(actions)

	offline_button = Button.new()
	offline_button.text = "USE CURRENT SPRITES"
	offline_button.pressed.connect(func(): offline_requested.emit())
	actions.add_child(offline_button)

	generate_button = Button.new()
	generate_button.text = "GENERATE AND START"
	generate_button.pressed.connect(_on_generate_pressed)
	actions.add_child(generate_button)

func _add_description_input(parent: VBoxContainer, label_text: String, placeholder: String) -> void:
	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", Color("d5e2d7"))
	parent.add_child(label)

	var input := LineEdit.new()
	input.placeholder_text = placeholder
	input.custom_minimum_size.y = 40.0
	parent.add_child(input)
	description_inputs.append(input)

func _on_generate_pressed() -> void:
	var descriptions: Array[String] = []
	for input in description_inputs:
		var description := input.text.strip_edges()
		if description.is_empty():
			set_status("Enter a description for all three tiers.")
			return
		descriptions.append(description)
	var api_key := api_key_input.text.strip_edges()
	if api_key.is_empty():
		api_key = OS.get_environment("GEMINI_API_KEY")
	if api_key.is_empty():
		set_status("Enter a Gemini API key or set GEMINI_API_KEY to generate sprites.")
		return
	set_generating(true)
	set_status("Generating tier 1 of 3...")
	api_key_input.clear()
	generation_requested.emit(descriptions, api_key)

func set_generating(is_generating: bool) -> void:
	generate_button.disabled = is_generating
	offline_button.disabled = is_generating
	for input in description_inputs:
		input.editable = not is_generating
	api_key_input.editable = not is_generating

func set_status(message: String) -> void:
	status_label.text = message
