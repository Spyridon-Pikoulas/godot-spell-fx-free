extends Node2D
## Pick an element and a spell, click to cast it: bolts fly from the caster and burst where you
## click, auras wrap the caster, the rest play at the click. Right click ends the loops. Left alone,
## it casts by itself.

const CASTER := Vector2(250, 560)
const SHAPES := ["bolt", "impact", "cast", "nova", "pillar", "area", "aura", "rune"]
const IDLE := 3.0

var element := ""
var shape := ""
var loops: Array[SpellFX] = []
var idle := IDLE
var elements: Array[String] = []
var shapes: Array[String] = []


func _ready() -> void:
	var have := SpellFX.effects()
	for fx_name in have:
		var el := fx_name.get_slice("_", 0)
		if el not in elements:
			elements.append(el)
	for s: String in SHAPES:
		if elements.any(func(el: String) -> bool: return (el + "_" + s) in have):
			shapes.append(s)
	element = elements[0]
	shape = shapes[0]
	var bar := VBoxContainer.new()
	bar.position = Vector2(16, 12)
	add_child(bar)
	bar.add_child(_choices(elements, func(v: String) -> void: element = v))
	bar.add_child(_choices(shapes, func(v: String) -> void: shape = v))
	var first: Dictionary = SpellFX.info(have[0])
	var sets := ["256", "128", "pixel"].filter(func(s: String) -> bool:  # the web build leaves 256 out
		return ResourceLoader.exists(SpellFX.sheets_dir.path_join(s).path_join(first.file)))
	SpellFX.default_set = sets[0]
	bar.add_child(_choices(sets, func(v: String) -> void: SpellFX.default_set = v))
	var hint := Label.new()
	hint.text = "Click to cast. Right click ends the loops."
	hint.add_theme_color_override("font_color", Color(0.75, 0.78, 0.9))
	bar.add_child(hint)


func _choices(values: Array, pick: Callable) -> HBoxContainer:
	var row := HBoxContainer.new()
	var group := ButtonGroup.new()
	for v: String in values:
		var b := Button.new()
		b.text = v
		b.toggle_mode = true
		b.button_group = group
		b.button_pressed = v == values[0]
		b.pressed.connect(pick.bind(v))
		row.add_child(b)
	return row


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed:
		return
	idle = IDLE
	if click.button_index == MOUSE_BUTTON_RIGHT:
		end_loops()
	elif click.button_index == MOUSE_BUTTON_LEFT:
		cast(element, shape, click.position)


func _process(delta: float) -> void:
	idle -= delta
	if idle > 0.0:
		return
	idle = 0.7
	var el: String = elements.pick_random()
	var s: String = shapes.pick_random()
	if loops.size() >= 3:
		end_loops()
	cast(el, s, Vector2(randf_range(560, 1180), randf_range(200, 600)))


func end_loops() -> void:
	for fx in loops:
		if is_instance_valid(fx):
			fx.finish()
	loops.clear()


func cast(el: String, what: String, at: Vector2) -> void:
	var fx_name := el + "_" + what
	if fx_name not in SpellFX.effects():
		return
	if what == "bolt":
		SpellFX.fly(self, el, CASTER + Vector2(30, -20), at)
		return
	if what == "aura":
		at = CASTER + Vector2(0, 40)
	elif what in ["pillar", "area"]:
		at.y = maxf(at.y, 420.0)
	var fx := SpellFX.spawn(self, fx_name, at)
	if fx.is_loop():
		loops.append(fx)


func _draw() -> void:
	draw_rect(Rect2(0, 600, 1280, 120), Color(0.1, 0.09, 0.15))
	# the caster, in flat shapes
	draw_colored_polygon(PackedVector2Array([CASTER + Vector2(-18, 40), CASTER + Vector2(0, -38),
		CASTER + Vector2(18, 40)]), Color(0.35, 0.3, 0.6))
	draw_circle(CASTER + Vector2(0, -26), 11, Color(0.85, 0.75, 0.6))
	draw_colored_polygon(PackedVector2Array([CASTER + Vector2(-14, -24), CASTER + Vector2(0, -60),
		CASTER + Vector2(14, -24)]), Color(0.3, 0.25, 0.55))
