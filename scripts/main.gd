extends Control

var state := PetState.new()
var store := SaveStore.new()
var status_label: Label
var energy_label: Label
var mood_label: Label
var file_callback: JavaScriptObject

func _ready() -> void:
	_build_ui()
	var result := store.load(state)
	if not result.ok:
		status_label.text = result.message
	_refresh()
	if OS.has_feature("web"):
		_setup_web_file_bridge()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		state.advance_offline(int(Time.get_unix_time_from_system()))
		store.save(state)
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		state.advance_offline(int(Time.get_unix_time_from_system()))
		store.save(state)
		_refresh()

func _build_ui() -> void:
	var background := ColorRect.new()
	background.color = Color("#171427")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 300
	column.add_theme_constant_override("separation", 14)
	center.add_child(column)
	var title := Label.new()
	title.text = "TAMAGUMI"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	var note := Label.new()
	note.text = "網頁技術薄片・佔位介面"
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(note)
	var pet_card := PanelContainer.new()
	column.add_child(pet_card)
	var pet_column := VBoxContainer.new()
	pet_column.add_theme_constant_override("separation", 10)
	pet_card.add_child(pet_column)
	var bird := Label.new()
	bird.text = "🐦"
	bird.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bird.add_theme_font_size_override("font_size", 76)
	pet_column.add_child(bird)
	energy_label = Label.new()
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pet_column.add_child(energy_label)
	mood_label = Label.new()
	mood_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pet_column.add_child(mood_label)
	_add_button(column, "一起玩", func(): _act("play"))
	_add_button(column, "休息一下", func(): _act("rest"))
	_add_button(column, "匯出備份檔", _export_backup)
	_add_button(column, "匯入備份檔", _import_backup)
	status_label = Label.new()
	status_label.text = "存檔留在本機瀏覽器；請定期匯出備份。"
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(status_label)

func _add_button(parent: Control, text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 48
	button.pressed.connect(callback)
	parent.add_child(button)

func _act(action: String) -> void:
	var result := state.apply_action(action)
	if result.ok:
		state.advance_offline(int(Time.get_unix_time_from_system()))
	var saved := store.save(state)
	status_label.text = saved.message if saved.ok else saved.message
	_refresh()

func _refresh() -> void:
	energy_label.text = "體力　%.1f / 100" % state.energy
	mood_label.text = "情緒　%.1f / 100" % state.mood

func _export_backup() -> void:
	var json_text := store.export_json(state)
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(json_text.to_utf8_buffer(), "tamagumi-backup.json", "application/json")
		status_label.text = "備份檔已交給瀏覽器下載；請確認下載完成。"
	else:
		var file := FileAccess.open("user://tamagumi-backup.json", FileAccess.WRITE)
		if file != null:
			file.store_string(json_text)
			file.flush()
			status_label.text = "備份已存入 App 私有空間。"

func _import_backup() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.tamagumiChooseBackup && window.tamagumiChooseBackup()")
	else:
		status_label.text = "桌面原型請使用 Web 匯入流程；Android 將接系統文件選擇器。"

func _setup_web_file_bridge() -> void:
	file_callback = JavaScriptBridge.create_callback(_on_file_selected)
	var window := JavaScriptBridge.get_interface("window")
	window.tamagumiReceiveBackup = file_callback

func _on_file_selected(args: Array) -> void:
	if args.is_empty():
		return
	var result := store.import_json(str(args[0]), state)
	status_label.text = result.message
	_refresh()
