class_name BattleFxCanvas
extends Control

var flashes: Array[Dictionary] = []
var blooms: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var paths: Array[Dictionary] = []
var auras: Dictionary = {}

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive

func flash(at: Vector2, radius: float = 190.0, duration := 0.22, delay := 0.0) -> void:
	flashes.append({"at": at, "radius": radius, "start": _now() + delay, "duration": duration})
	set_process(true)

func bloom(at: Vector2, color: Color, radius: float = 300.0, duration := 0.55, delay := 0.0) -> void:
	blooms.append({"at": at, "color": color, "radius": radius, "start": _now() + delay, "duration": duration})
	set_process(true)

func shock(at: Vector2, color: Color, radius: float = 300.0, duration := 0.38, delay := 0.0) -> void:
	rings.append({"at": at, "color": color, "radius": radius, "start": _now() + delay, "duration": duration})
	set_process(true)

func burst(at: Vector2, color: Color, count := 56, speed_min := 180.0, speed_max := 720.0,
		duration := 0.62, gravity := 320.0, delay := 0.0) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = int(at.x * 31.0 + at.y * 17.0 + _now() * 1000.0) & 0x7fffffff
	var start := _now() + delay
	for i in count:
		var angle := random.randf_range(0.0, TAU)
		var speed := lerpf(speed_min, speed_max, pow(random.randf(), 0.7))
		particles.append({
			"at": at, "velocity": Vector2.from_angle(angle) * speed, "gravity": gravity,
			"color": Color.WHITE if random.randf() < 0.35 else color,
			"size": random.randf_range(3.2, 7.2), "start": start,
			"duration": duration * random.randf_range(0.55, 1.0),
		})
	set_process(true)

func orb(from: Vector2, to: Vector2, color: Color, duration := 0.56, arc := 120.0,
		size := 9.0, delay := 0.0) -> void:
	var direction := to - from
	var normal := Vector2(-direction.y, direction.x).normalized()
	var side := -1.0 if (paths.size() % 2 == 0) else 1.0
	var control := (from + to) * 0.5 + normal * arc * side - Vector2(0, arc * 0.35)
	paths.append({"kind": "orb", "from": from, "to": to, "control": control, "color": color,
		"size": size, "start": _now() + delay, "duration": duration})
	set_process(true)

func streak(from: Vector2, to: Vector2, color: Color, duration := 0.30, delay := 0.0) -> void:
	paths.append({"kind": "streak", "from": from, "to": to, "color": color,
		"start": _now() + delay, "duration": duration})
	set_process(true)

func set_aura(key: String, at: Vector2, color: Color, level := 1.0) -> void:
	auras[key] = {"at": at, "color": color, "level": level, "start": _now()}
	set_process(true)

func move_aura(key: String, at: Vector2) -> void:
	if auras.has(key):
		auras[key]["at"] = at

func clear_aura(key: String) -> void:
	auras.erase(key)

func clear_all() -> void:
	flashes.clear()
	blooms.clear()
	rings.clear()
	particles.clear()
	paths.clear()
	auras.clear()
	queue_redraw()

func _process(_delta: float) -> void:
	var now := _now()
	_prune(flashes, now)
	_prune(blooms, now)
	_prune(rings, now)
	_prune(particles, now)
	_prune(paths, now)
	queue_redraw()
	if flashes.is_empty() and blooms.is_empty() and rings.is_empty() and particles.is_empty() and paths.is_empty() and auras.is_empty():
		set_process(false)

func _prune(items: Array[Dictionary], now: float) -> void:
	for i in range(items.size() - 1, -1, -1):
		if now > float(items[i].start) + float(items[i].duration):
			items.remove_at(i)

func _draw() -> void:
	var now := _now()
	for aura in auras.values():
		_draw_aura(aura, now)
	for effect in blooms:
		var p := _progress(effect, now)
		if p >= 0.0:
			var pulse := sin(p * PI)
			_draw_soft_bloom(effect.at, effect.radius * (0.72 + 0.28 * _cubic_out(p)), effect.color, pulse * 0.72)
	for effect in flashes:
		var p := _progress(effect, now)
		if p >= 0.0:
			var strength := pow(1.0 - p, 1.6)
			var radius: float = lerpf(effect.radius * 0.35, effect.radius, _cubic_out(p))
			_draw_soft_bloom(effect.at, radius, Color.WHITE, strength * 1.15)
			draw_circle(effect.at, maxf(4.0, radius * 0.075), Color(1,1,1,strength*0.72))
	for effect in rings:
		var p := _progress(effect, now)
		if p >= 0.0:
			var radius: float = lerpf(24.0, effect.radius, _cubic_out(p))
			draw_arc(effect.at, radius, 0.0, TAU, 72, Color(effect.color, 1.0 - p), maxf(0.4, 14.0 * (1.0 - p)), true)
			draw_arc(effect.at, radius * 0.78, 0.0, TAU, 72, Color(1,1,1,(1.0-p)*0.6), maxf(0.3, 4.5 * (1.0-p)), true)
	for particle in particles:
		var p := _progress(particle, now)
		if p >= 0.0:
			var seconds: float = p * float(particle.duration)
			var at: Vector2 = particle.at + particle.velocity * seconds + Vector2(0, 0.5 * float(particle.gravity) * seconds * seconds)
			_draw_glow(at, float(particle.size) * (0.5 + 0.5 * (1.0-p)), particle.color, (1.0-p)*0.95)
	for path in paths:
		var p := _progress(path, now)
		if p < 0.0:
			continue
		if path.kind == "orb":
			_draw_orb(path, _cubic_in_out(p))
		else:
			_draw_streak(path, p)

func _draw_aura(aura: Dictionary, now: float) -> void:
	var strength := clampf((now - float(aura.start)) / 0.25, 0.0, 1.0) * float(aura.level)
	var at: Vector2 = aura.at
	var color: Color = aura.color
	draw_set_transform(at, 0.0, Vector2(1.0, 0.46))
	for i in range(12, 0, -1):
		var ratio := i / 12.0
		draw_circle(Vector2.ZERO, 118.0 * ratio, Color(color, 0.040 * strength * (1.0-ratio+0.22)))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in 9:
		var phase := fposmod((now * (0.45 + (i % 3) * 0.12)) + i / 9.0, 1.0)
		var angle := i * 2.399 + now / 1.4
		var mote := at + Vector2(cos(angle) * 82.0 * (1.0-phase*0.4), -phase * 170.0)
		_draw_glow(mote, 6.0 + (i % 2) * 2.0, color, sin(phase * PI) * strength)

func _draw_orb(path: Dictionary, progress: float) -> void:
	for i in range(12, -1, -1):
		var u := maxf(0.0, progress - 0.20 * (i / 12.0))
		var point := _quadratic(path.from, path.control, path.to, u)
		var fade := (1.0 - i / 12.0) * 0.75
		_draw_glow(point, float(path.size) * (1.0-i/12.0*0.75), path.color, fade)

func _draw_streak(path: Dictionary, progress: float) -> void:
	var head_u := progress * progress
	var tail_u := maxf(0.0, head_u - 0.28)
	var head: Vector2 = path.from.lerp(path.to, head_u)
	var tail: Vector2 = path.from.lerp(path.to, tail_u)
	draw_line(tail, head, Color(path.color, 0.95), 7.0, true)
	_draw_glow(head, 9.0, path.color, 1.0)

func _draw_glow(at: Vector2, radius: float, color: Color, alpha: float) -> void:
	for i in range(6, 0, -1):
		var ratio := i / 6.0
		draw_circle(at, radius * (0.35 + ratio * 0.65), Color(color, alpha * 0.012 * (1.0-ratio+0.2)))
	draw_circle(at, maxf(1.5, radius * 0.08), Color(1,1,1,alpha*0.85))

func _draw_soft_bloom(at: Vector2, radius: float, color: Color, alpha: float) -> void:
	for i in range(18, 0, -1):
		var ratio := i / 18.0
		var falloff := pow(1.0 - ratio, 1.8)
		draw_circle(at, radius * ratio, Color(color, alpha * 0.050 * falloff))
	draw_circle(at, radius * 0.18, Color(color, alpha * 0.090))

func _quadratic(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var inv := 1.0 - t
	return inv * inv * a + 2.0 * inv * t * b + t * t * c

func _progress(effect: Dictionary, now: float) -> float:
	if now < float(effect.start):
		return -1.0
	return clampf((now - float(effect.start)) / float(effect.duration), 0.0, 1.0)

func _now() -> float:
	return Time.get_ticks_msec() / 1000.0

func _cubic_out(t: float) -> float:
	return 1.0 - pow(1.0-t, 3.0)

func _cubic_in_out(t: float) -> float:
	return 4.0*t*t*t if t < 0.5 else 1.0-pow(-2.0*t+2.0, 3.0)/2.0
