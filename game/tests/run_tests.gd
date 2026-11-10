class_name TestRunner
extends SceneTree
## Test runner and assertion helpers.
## Run: GODOT --headless --path game -s res://tests/run_tests.gd
## Test files extend RefCounted and call TestRunner.assert_*().

static var pass_count: int = 0
static var fail_count: int = 0
static var current_test: String = ""


static func assert_eq(a: Variant, b: Variant, msg: String = "") -> void:
	if a == b:
		pass_count += 1
	else:
		_fail("assert_eq expected %s got %s %s" % [str(b), str(a), msg])


static func assert_true(v: bool, msg: String = "") -> void:
	if v:
		pass_count += 1
	else:
		_fail("assert_true failed %s" % msg)


static func assert_near(a: float, b: float, rel_tol: float, msg: String = "") -> void:
	var scale: float = maxf(absf(a), absf(b))
	var diff: float = absf(a - b)
	if diff <= rel_tol * scale or diff == 0.0:
		pass_count += 1
	else:
		_fail("assert_near expected %s got %s (rel_tol %s) %s" % [str(b), str(a), str(rel_tol), msg])


static func _fail(text: String) -> void:
	fail_count += 1
	print("FAIL [%s] %s" % [current_test, text])


func _init() -> void:
	var files: Array[String] = _find_test_files("res://tests")
	files.sort()
	for path: String in files:
		var script: GDScript = load(path) as GDScript
		if script == null:
			_fail_load(path)
			continue
		var methods: Array[String] = []
		for m: Dictionary in script.get_script_method_list():
			var mname: String = m["name"]
			if mname.begins_with("test_"):
				methods.append(mname)
		methods.sort()
		for mname: String in methods:
			current_test = "%s::%s" % [path.get_file(), mname]
			var inst: Object = script.new()
			inst.call(mname)
	print("PASS %d / FAIL %d" % [pass_count, fail_count])
	quit(1 if fail_count > 0 else 0)


func _fail_load(path: String) -> void:
	fail_count += 1
	print("FAIL could not load %s" % path)


func _find_test_files(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.begins_with("test_") and entry.ends_with(".gd"):
			result.append(dir_path.path_join(entry))
		entry = dir.get_next()
	dir.list_dir_end()
	return result
