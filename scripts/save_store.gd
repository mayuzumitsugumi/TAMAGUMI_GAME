class_name SaveStore
extends RefCounted

const SAVE_PATH := "user://save.json"
const BACKUP_PATH := "user://save.previous.json"

func save(state: PetState) -> Dictionary:
	var json := JSON.stringify(state.to_backup())
	var temp_path := "user://save.tmp"
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "message": "無法建立存檔"}
	file.store_string(json)
	file.flush()
	file.close()
	if FileAccess.file_exists(SAVE_PATH):
		var old := FileAccess.get_file_as_string(SAVE_PATH)
		var previous := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		if previous != null:
			previous.store_string(old)
			previous.flush()
			previous.close()
	var new_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if new_file == null:
		return {"ok": false, "message": "無法寫入存檔"}
	new_file.store_string(json)
	new_file.flush()
	new_file.close()
	return {"ok": true, "message": "本機存檔完成"}

func load(state: PetState) -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		state.last_simulated_at = int(Time.get_unix_time_from_system())
		return {"ok": true, "message": "建立新存檔"}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	var result := state.load_backup(parsed)
	if result.ok:
		state.advance_offline(int(Time.get_unix_time_from_system()))
	return result

func import_json(json_text: String, state: PetState) -> Dictionary:
	if json_text.length() > 2_000_000:
		return {"ok": false, "message": "備份檔過大"}
	var parsed: Variant = JSON.parse_string(json_text)
	var candidate := PetState.new()
	var result := candidate.load_backup(parsed)
	if not result.ok:
		return result
	# Preserve the currently valid save before replacing it.
	if FileAccess.file_exists(SAVE_PATH):
		var previous := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		if previous != null:
			previous.store_string(FileAccess.get_file_as_string(SAVE_PATH))
			previous.flush()
			previous.close()
	state.name = candidate.name
	state.energy = candidate.energy
	state.mood = candidate.mood
	state.revision = candidate.revision
	state.last_simulated_at = candidate.last_simulated_at
	return save(state)

func export_json(state: PetState) -> String:
	return JSON.stringify(state.to_backup(), "\t")
