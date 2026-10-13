extends "res://scripts/audio_base.gd"
## Música contínua em canal separado dos contatos e do ambiente espacial.
const MUSIC = preload("res://audio/music/etirwer-loop.ogg")
const MUSIC_EXPLORE_DB := -8.0
const MUSIC_WORK_DB := -14.0
const DUCK_DB := -8.0
var step_player: AudioStreamPlayer3D
var ambience: AudioStreamPlayer3D
var transition_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
var music_fade: Tween
var suspended := true
var steps_played := 0
var level := 0.75 # Efeitos e ambiente; mantido para os controles existentes.
var music_level := 0.60
var working := false
var duck_remaining := 0.0
var last_surface := "piso"
var floor_steps: Array[AudioStreamWAV] = []
var rug_steps: Array[AudioStreamWAV] = []
var thread_sounds: Array[AudioStreamWAV] = []
var transitions: Array[AudioStreamWAV] = []

func _ready() -> void:
    super._ready()
    player.bus = &"Efeitos"
    player.volume_db = -10
    success_sound = melody_stream([523.25, 659.25, 783.99], 0.18, 0.48)
    for index in range(4):
        thread_sounds.append(thread_stream(785 + index))
        floor_steps.append(contact_stream(0.19, 1200 + index, false))
        rug_steps.append(contact_stream(0.15, 1400 + index, true))
    click_sound = thread_sounds[0]
    step_player = AudioStreamPlayer3D.new()
    step_player.name = "Passos"
    step_player.bus = &"Efeitos"
    step_player.volume_db = -12
    step_player.unit_size = 3.0
    step_player.max_distance = 15.0
    step_player.max_polyphony = 2
    add_child(step_player)
    ambience = AudioStreamPlayer3D.new()
    ambience.name = "AmbienteDaJanela"
    ambience.bus = &"Efeitos"
    ambience.volume_db = -30
    ambience.unit_size = 5.0
    ambience.max_distance = 18.0
    ambience.panning_strength = 0.65
    ambience.stream = air_stream()
    add_child(ambience)
    ambience.global_position = Vector3(-2.45, 2.0, -4.2)
    transition_player = AudioStreamPlayer.new()
    transition_player.name = "Transicoes"
    transition_player.bus = &"Efeitos"
    transition_player.volume_db = -22
    add_child(transition_player)
    transitions.assign([melody_stream([392.0, 523.25], 0.13, 0.25), melody_stream([523.25, 392.0], 0.13, 0.25)])
    music_player = AudioStreamPlayer.new()
    music_player.name = "MusicaDoAtelie"
    music_player.bus = &"Musica"
    music_player.stream = MUSIC.duplicate()
    music_player.stream.loop = true
    music_player.stream.loop_offset = 0.0
    music_player.volume_linear = 0.0
    add_child(music_player)
    update_streams()

func _process(delta: float) -> void:
    if suspended or muted or duck_remaining <= 0:
        return
    duck_remaining = maxf(0.0, duck_remaining - delta)
    if duck_remaining == 0:
        update_music(0.8)

func wave(bytes: PackedByteArray, looping: bool = false) -> AudioStreamWAV:
    var stream := AudioStreamWAV.new()
    stream.format = AudioStreamWAV.FORMAT_16_BITS
    stream.mix_rate = 22050
    stream.data = bytes
    if looping:
        stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
        stream.loop_end = bytes.size() / 2
    return stream

func contact_stream(seconds: float, seed_value: int, soft: bool) -> AudioStreamWAV:
    var count := int(seconds * 22050)
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var smooth := 0.0
    for i in range(count):
        var t := float(i) / 22050.0
        smooth = lerpf(smooth, rng.randf_range(-1, 1), 0.065 if soft else 0.28)
        var attack := smoothstep(0.0, 0.005, t)
        var heel := exp(-t * (36.0 if soft else 43.0))
        var toe := exp(-maxf(t - 0.058, 0.0) * 64.0) * smoothstep(0.048, 0.064, t) * 0.30
        var end := smoothstep(0.0, 0.018, seconds - t)
        # Contato grave curto com dois modos amortecidos; tecido recebe menos ressonância.
        var body := (sin(t * TAU * (127 + seed_value % 17)) + 0.35 * sin(t * TAU * 247)) * exp(-t * 55.0)
        var value := smooth * (0.78 if soft else 0.92) * (heel + toe) + body * (0.055 if soft else 0.16)
        value *= attack * end
        bytes.encode_s16(i * 2, int(clampf(value, -0.90, 0.90) * 30000))
    return wave(bytes)

func thread_stream(seed_value: int) -> AudioStreamWAV:
    const SECONDS := 0.10
    var bytes := PackedByteArray()
    bytes.resize(int(SECONDS * 22050) * 2)
    var rng := RandomNumberGenerator.new()
    rng.seed = seed_value
    var smooth := 0.0
    for i in range(bytes.size() / 2):
        var t := float(i) / 22050.0
        smooth = lerpf(smooth, rng.randf_range(-1, 1), 0.24)
        var envelope := smoothstep(0.0, 0.005, t) * exp(-t * 42.0) * smoothstep(0.0, 0.018, SECONDS - t)
        var pluck := sin(TAU * (680 + seed_value % 43) * t) * exp(-t * 85.0) * 0.11
        bytes.encode_s16(i * 2, int(clampf((smooth * 0.72 + pluck) * envelope, -0.9, 0.9) * 30000))
    return wave(bytes)

func melody_stream(notes: Array, spacing: float, tail: float) -> AudioStreamWAV:
    var seconds := (notes.size() - 1) * spacing + tail
    var bytes := PackedByteArray()
    bytes.resize(int(seconds * 22050) * 2)
    for i in range(bytes.size() / 2):
        var t := float(i) / 22050.0
        var value := 0.0
        for n in range(notes.size()):
            var local_t := t - n * spacing
            if local_t < 0 or local_t >= tail:
                continue
            var frequency := float(notes[n])
            var envelope := smoothstep(0.0, 0.010, local_t) * exp(-local_t * 11.0) * smoothstep(0.0, 0.05, tail - local_t)
            value += (sin(TAU * frequency * local_t) + 0.18 * sin(TAU * frequency * 2 * local_t)) * envelope * 0.44
        bytes.encode_s16(i * 2, int(clampf(value, -0.9, 0.9) * 30000))
    return wave(bytes)

func air_stream() -> AudioStreamWAV:
    const SECONDS := 10.0
    var count := int(SECONDS * 22050)
    var bytes := PackedByteArray()
    bytes.resize(count * 2)
    var rng := RandomNumberGenerator.new()
    rng.seed = 6120
    var smooth := 0.0
    for i in range(count):
        var t := float(i) / 22050.0
        smooth = lerpf(smooth, rng.randf_range(-1, 1), 0.02)
        var envelope := smoothstep(0.0, 0.12, t) * smoothstep(0.0, 0.12, SECONDS - t)
        var breeze := smooth * (0.45 + 0.12 * sin(TAU * t / SECONDS))
        # Sinal distante sintetizado, sem atribuição a espécie ou tradição musical.
        var chirp_time := t - 3.1
        var chirp := sin(TAU * (1700 * chirp_time + 600 * chirp_time * chirp_time)) * exp(-pow((chirp_time - 0.10) / 0.055, 2)) * 0.018
        bytes.encode_s16(i * 2, int(clampf((breeze + chirp) * envelope, -0.9, 0.9) * 28000))
    return wave(bytes, true)

func play_step(at: Vector3 = Vector3.ZERO) -> void:
    if muted or suspended or level <= 0:
        return
    last_surface = "tapete" if Rect2(-1.3, 1.325, 2.6, 1.45).has_point(Vector2(at.x, at.z)) else "piso"
    step_player.global_position = at + Vector3.UP * 0.10
    step_player.stream = rug_steps[steps_played % 4] if last_surface == "tapete" else floor_steps[steps_played % 4]
    step_player.pitch_scale = 0.98 + float(steps_played % 3) * 0.02
    step_player.play()
    steps_played += 1

func play_transition(entering: bool) -> void:
    if not muted and not suspended and level > 0:
        transition_player.stream = transitions[0 if entering else 1]
        transition_player.play()

func play_feedback(success: bool = false) -> void:
    if muted or suspended or level <= 0:
        return
    click_sound = thread_sounds[played_count % thread_sounds.size()]
    if success:
        duck_remaining = 1.3
        update_music(0.12)
    super.play_feedback(success)

func set_working(value: bool) -> void:
    if working == value:
        return
    working = value
    update_music(1.2)

func set_level(value: float) -> void:
    level = clampf(value, 0, 1)
    update_effects()

func set_music_level(value: float) -> void:
    music_level = clampf(value, 0, 1)
    update_music(0.8)

func set_muted(value: bool) -> void:
    super.set_muted(value)
    update_streams(true)

func suspend(value: bool, immediate: bool = false) -> void:
    suspended = value
    if value:
        duck_remaining = 0.0
    update_streams(immediate)

func update_streams(immediate: bool = false) -> void:
    update_effects()
    update_music(0.8, immediate)

func update_effects() -> void:
    var quiet := muted or suspended or level <= 0
    var bus := AudioServer.get_bus_index(&"Efeitos")
    AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(level, 0.0001)))
    AudioServer.set_bus_mute(bus, quiet)
    if quiet:
        player.stop()
        step_player.stop()
        transition_player.stop()
        ambience.stop()
    elif not ambience.playing:
        ambience.play()

func update_music(seconds: float = 0.8, immediate: bool = false) -> void:
    if music_fade and music_fade.is_valid():
        music_fade.kill()
    var bus := AudioServer.get_bus_index(&"Musica")
    AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(music_level, 0.0001)))
    AudioServer.set_bus_mute(bus, muted or music_level <= 0)
    if suspended or muted or music_level <= 0:
        if immediate or muted or music_level <= 0 or music_player.volume_linear < 0.0001:
            pause_music()
        else:
            music_fade = create_tween()
            music_fade.tween_property(music_player, "volume_linear", 0.0, 0.08)
            music_fade.tween_callback(pause_music)
        return
    # stream_paused preserva a posição. Não atribuir stream nem chamar play de novo.
    if not music_player.has_stream_playback():
        music_player.play()
    music_player.stream_paused = false
    var target_db := MUSIC_WORK_DB if working else MUSIC_EXPLORE_DB
    if duck_remaining > 0:
        target_db += DUCK_DB
    music_fade = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    music_fade.tween_property(music_player, "volume_linear", db_to_linear(target_db), seconds)

func pause_music() -> void:
    music_player.stream_paused = true
    music_player.volume_linear = 0.0
