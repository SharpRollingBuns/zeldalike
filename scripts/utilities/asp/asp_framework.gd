class_name ASPFramework
extends Resource
"""
Обёртка над консольным clingo.
– Записывает ASP-программу во временный файл (user://).
– Вызывает clingo и получает JSON-вывод (--outf=2).
– Разбирает модели через JSON.parse_string.
"""

# ────────── настраиваемые параметры ──────────
@export var solver_cmd : String = "res://bin/clingo.exe" # имя в PATH или абсолютный путь
@export var models     : int    = 1          # -n N
@export var time_limit : int    = 5          # --time-limit (сек)
@export var keep_tmp   : bool   = false      # оставлять .lp для отладки

# ────────── публичное API ──────────
func solve(program_text : String) -> Array:
	# 1) Записываем во временный .lp
	var dir := "user://asp_temp"
	DirAccess.make_dir_recursive_absolute(dir)
	var tmp_file := "%s/%d.lp" % [dir, Time.get_ticks_usec()]
	var f := FileAccess.open(tmp_file, FileAccess.WRITE)
	if f == null:
		push_error("ASPFramework: can't write %s" % tmp_file)
		return []
	f.store_string(program_text)
	f.close()

	# 2) Готовим аргументы clingo
	var abs_tmp := ProjectSettings.globalize_path(tmp_file)
	var args : PackedStringArray = [
		abs_tmp,
		"-n", str(models),
		"--outf=2",
		"--time-limit=%d" % time_limit
	]

	var output : Array = []         # stdout (+stderr, см. ниже)
	solver_cmd = ProjectSettings.globalize_path(solver_cmd)
	var exit_code := OS.execute(
		solver_cmd,       # ищется через PATH, как указано в доках OS.execute
		args,
		output,
		true,             # читаем stderr тоже
		false             # без отдельной консоли
	)

	if not keep_tmp:
		DirAccess.remove_absolute(tmp_file)

	# 3) Анализируем код возврата
	if exit_code != 0:
		var stdout = "" if output.is_empty() else output[0]
		push_error("clingo exit code %d:\n%s" % [exit_code, stdout])
		return []

	if output.is_empty():
		push_error("clingo produced no output")
		return []

	# 4) Парсим JSON-строку
	var json_result = JSON.parse_string(output[0])
	if json_result == null:
		push_error("JSON parse error")
		return []

	# 5) Достаём список моделей
	if json_result.has("Call") and json_result["Call"].size() > 0:
		var witnesses = json_result["Call"][0].get("Witnesses", [])
		return witnesses    # массив моделей; каждую трактует ASPGenerator
	return []
