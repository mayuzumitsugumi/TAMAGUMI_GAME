class_name PetState
extends RefCounted

const MAX_STAT := 100.0
const SAVE_FORMAT := "tamagumi-save"
const SCHEMA_VERSION := 1

var energy := 60.0
var mood := 70.0
var name := "TAMAGUMI"
var revision := 0
var last_simulated_at := 0

func apply_action(action: String) -> Dictionary:
	var delta := 0.0
	match action:
		"play":
			delta = 8.0
			energy -= 5.0
		"rest":
			delta = 4.0
			energy += 5.0
		_:
			return {"ok": false, "message": "未知的互動"}
	mood = clampf(mood + delta, 0.0, MAX_STAT)
	energy = clampf(energy, 0.0, MAX_STAT)
	revision += 1
	return {"ok": true, "message": "狀態已更新並保存"}

func advance_offline(now_utc: int) -> void:
	if last_simulated_at > 0 and now_utc > last_simulated_at:
		var elapsed_minutes := mini((now_utc - last_simulated_at) / 60, 1440)
		energy = clampf(energy - float(elapsed_minutes) * 0.05, 0.0, MAX_STAT)
		mood = clampf(mood - float(elapsed_minutes) * 0.025, 0.0, MAX_STAT)
	last_simulated_at = now_utc

func to_backup() -> Dictionary:
	return {
		"format": SAVE_FORMAT,
		"schema_version": SCHEMA_VERSION,
		"app_version": "prototype-0.1",
		"save_id": "local-save",
		"revision": revision,
		"exported_at_utc": int(Time.get_unix_time_from_system()),
		"last_simulated_at_utc": last_simulated_at,
		"payload": {"name": name, "energy": energy, "mood": mood}
	}

func load_backup(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return {"ok": false, "message": "備份格式錯誤"}
	if data.get("format", "") != SAVE_FORMAT:
		return {"ok": false, "message": "這不是 TAMAGUMI 備份檔"}
	if int(data.get("schema_version", -1)) != SCHEMA_VERSION:
		return {"ok": false, "message": "不支援此備份版本"}
	var payload: Variant = data.get("payload")
	if typeof(payload) != TYPE_DICTIONARY:
		return {"ok": false, "message": "備份內容缺失"}
	for key in ["energy", "mood"]:
		if typeof(payload.get(key)) not in [TYPE_INT, TYPE_FLOAT]:
			return {"ok": false, "message": "備份數值無效"}
	var new_energy := float(payload.energy)
	var new_mood := float(payload.mood)
	if not is_finite(new_energy) or not is_finite(new_mood) or new_energy < 0.0 or new_energy > MAX_STAT or new_mood < 0.0 or new_mood > MAX_STAT:
		return {"ok": false, "message": "備份數值超出範圍"}
	name = str(payload.get("name", "TAMAGUMI"))
	energy = new_energy
	mood = new_mood
	revision = int(data.get("revision", 0))
	last_simulated_at = int(data.get("last_simulated_at_utc", 0))
	return {"ok": true, "message": "備份已匯入"}
