extends SceneTree
## Verifica a cena real e amostras do mix, não apenas flags dos players.
var game
var mixer
var capture_effect: AudioEffectCapture
var failures: Array[String] = []
var checks := 0
var folder := "res://evidence/audio/sonoro"
var long_session := false
var measurements: Dictionary = {}

func _initialize() -> void:
    call_deferred("run")

func check(ok: bool, message: String) -> void:
    checks += 1
    if ok:
        print("PASS: " + message)
    else:
        failures.append(message)
        push_error(message)

func frames(count: int = 6) -> void:
    for i in range(count):
        await process_frame
        await physics_frame

func peak_window(seconds: float = 0.20) -> float:
    capture_effect.clear_buffer()
    await create_timer(seconds).timeout
    var samples := capture_effect.get_buffer(capture_effect.get_frames_available())
    var peak := 0.0
    for sample in samples:
        peak = maxf(peak, maxf(absf(sample.x), absf(sample.y)))
    measurements["captured_frames"] = int(measurements.get("captured_frames", 0)) + samples.size()
    return peak

func key(code: Key) -> void:
    var event := InputEventKey.new()
    event.keycode = code
    event.pressed = true
    root.push_input(event, true)
    event = event.duplicate()
    event.pressed = false
    root.push_input(event, true)
    await frames(2)

func run() -> void:
    for argument in OS.get_cmdline_user_args():
        if argument.begins_with("--evidence-dir="):
            folder = argument.trim_prefix("--evidence-dir=")
        if argument == "--long-session":
            long_session = true
    DirAccess.make_dir_recursive_absolute(folder)
    root.unfocusable = true
    root.mouse_passthrough = true
    await frames()
    game = load("res://scenes/main.tscn").instantiate()
    root.add_child(game)
    current_scene = game
    await frames(12)
    mixer = game.audio
    capture_effect = AudioEffectCapture.new()
    capture_effect.buffer_length = 0.5
    AudioServer.add_bus_effect(0, capture_effect)
    var music_id: int = mixer.music_player.get_instance_id()
    check(mixer.suspended and not mixer.music_player.has_stream_playback(), "Abertura silenciosa até iniciar")
    check(await peak_window() < 0.00001, "Mix inicial contém silêncio")
    check(mixer.music_player.stream.loop and mixer.music_player.stream.get_length() > 120, "Faixa local válida, completa e em loop")
    game.handle_action("start")
    await create_timer(0.15).timeout
    check(mixer.music_player.volume_linear > 0 and mixer.music_player.volume_db < mixer.MUSIC_EXPLORE_DB, "Entrada gradual da música")
    await create_timer(0.85).timeout
    check(is_equal_approx(mixer.music_player.volume_db, mixer.MUSIC_EXPLORE_DB), "Volume contextual de exploração alcançado")
    measurements["music_peak"] = await peak_window()
    check(measurements.music_peak > 0.0001, "A música produz amostras no mix de saída")
    var before: float = mixer.music_player.get_playback_position()
    game.player.position = Vector3(0, 0.03, 1.68)
    game.player.velocity = Vector3.ZERO
    await frames(12)
    game.enter_work()
    await create_timer(1.4).timeout
    check(game.mode == game.Mode.WORK and mixer.working, "Entrar na bancada altera o contexto sonoro")
    check(absf(mixer.music_player.volume_db - mixer.MUSIC_WORK_DB) < 0.1, "Música fica 6 dB mais baixa no bastidor")
    check(mixer.music_player.get_playback_position() > before + 1.0 and mixer.music_player.get_instance_id() == music_id, "Transição preserva player e progresso da faixa")
    game.leave_work()
    await create_timer(1.4).timeout
    check(absf(mixer.music_player.volume_db - mixer.MUSIC_EXPLORE_DB) < 0.1, "Retorno à exploração restaura o volume gradualmente")
    game.pause_game()
    await create_timer(0.15).timeout
    before = mixer.music_player.get_playback_position()
    check(mixer.music_player.stream_paused, "Pausa suspende o stream após saída curta")
    check(await peak_window() < 0.00001, "Nenhum áudio permanece na pausa")
    check(absf(mixer.music_player.get_playback_position() - before) < 0.06, "Posição musical permanece congelada")
    game.handle_action("sound_menu")
    game.hud.music_slider.value = 0.40
    game.volume_slider.value = 0
    check(is_equal_approx(mixer.music_level, 0.4) and mixer.level == 0, "Menu controla música e efeitos independentemente")
    game.hud.music_slider.grab_focus()
    await key(KEY_RIGHT)
    check(is_equal_approx(mixer.music_level, 0.45) and "45%" in game.hud.music_label.text, "Slider de música aceita teclado e atualiza o texto")
    await key(KEY_TAB)
    check(game.hud.pages.sound.is_ancestor_of(root.gui_get_focus_owner()), "Tab permanece no menu de som")
    check(mixer.music_player.stream_paused, "Ajustar volumes na pausa não inicia reprodução")
    if DisplayServer.get_name() != "headless":
        await RenderingServer.frame_post_draw
        root.get_texture().get_image().save_png(folder + "/menu-som.png")
    game.handle_action("sound_back")
    game.handle_action("resume")
    await create_timer(0.95).timeout
    check(mixer.music_player.get_playback_position() > before + 0.65, "Retomar continua do ponto guardado")
    var steps: int = mixer.steps_played
    mixer.play_step()
    check(mixer.steps_played == steps and not mixer.ambience.playing, "Efeitos zerados bloqueiam passos e ambiente")
    check(await peak_window() > 0.0001, "Música continua com efeitos zerados")
    game.handle_action("music_volume", 0)
    game.handle_action("volume", 0.75)
    before = mixer.music_player.get_playback_position()
    check(mixer.music_player.stream_paused and mixer.ambience.playing, "Música zerada preserva ambiente e posição da faixa")
    mixer.play_feedback()
    measurements["thread_peak"] = await peak_window(0.16)
    check(measurements.thread_peak > 0.001, "Som de tecer continua com música zerada")
    game.handle_action("sound")
    check(await peak_window() < 0.00001, "Silêncio global corta todas as saídas")
    game.handle_action("music_volume", 0.6)
    check(mixer.music_player.stream_paused, "Alterar música com silêncio global não a reativa")
    game.handle_action("sound")
    await create_timer(0.9).timeout
    check(mixer.music_player.get_playback_position() > before + 0.5, "Desligar silêncio global preserva continuidade")
    game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
    check(game.paused and mixer.music_player.stream_paused, "Perda de foco suspende música imediatamente")
    await create_timer(0.12).timeout
    check(await peak_window() < 0.00001, "Janela sem foco não mantém áudio")
    game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_IN)
    check(game.paused and mixer.music_player.stream_paused, "Voltar ao foco exige Continuar")
    for i in range(3):
        game.resume_game()
        await create_timer(0.025).timeout
        game.pause_game()
        await create_timer(0.025).timeout
    game.resume_game()
    await create_timer(0.95).timeout
    check(not mixer.music_player.stream_paused and absf(mixer.music_player.volume_db - mixer.MUSIC_EXPLORE_DB) < 0.1, "Pausas rápidas não deixam fades antigos suspenderem a retomada")
    game.player.position = Vector3(0, 0.03, 1.68)
    await frames(8)
    game.enter_work()
    game.pause_game()
    await create_timer(1.4).timeout
    check(game.paused and mixer.music_player.stream_paused and mixer.working, "Pausa durante transição preserva destino e silêncio")
    game.resume_game()
    await create_timer(1.0).timeout
    for row in range(8):
        for column in range(4, 8):
            game.model.paint(row, column, game.model.expected(row, column))
    game.refresh()
    var played: int = mixer.played_count
    game.verify()
    check(mixer.played_count == played + 1 and game.hud.modal_kind == "success", "Conquista emite o efeito uma única vez")
    await create_timer(0.16).timeout
    check(mixer.music_player.volume_db < mixer.MUSIC_WORK_DB - 7, "Trilha reduz o volume para destacar a conquista")
    measurements["success_peak"] = await peak_window()
    check(measurements.success_peak > 0.001, "Conquista tem saída sonora real")
    await create_timer(2.1).timeout
    check(absf(mixer.music_player.volume_db - mixer.MUSIC_WORK_DB) < 0.1, "Volume retorna após a conquista")
    game.notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
    await create_timer(0.12).timeout
    check(mixer.suspended and await peak_window() < 0.00001, "Perder foco na conclusão também silencia tudo")
    game.handle_action("success_close")
    await create_timer(0.9).timeout
    mixer.music_player.seek(mixer.music_player.stream.get_length() - 0.25)
    await create_timer(0.7).timeout
    var after_loop: float = mixer.music_player.get_playback_position()
    check(after_loop > 0.20 and after_loop < 1.1 and mixer.music_player.has_stream_playback(), "Final da faixa volta ao início sem interromper o player")
    if long_session:
        print("ENSAIO LONGO: reprodução de um ciclo completo da faixa")
        var duration: float = mixer.music_player.stream.get_length()
        var start: float = mixer.music_player.get_playback_position()
        await create_timer(duration + 0.4).timeout
        var end: float = mixer.music_player.get_playback_position()
        check(end > start and end < start + 1.2, "Ciclo completo de 2min10s reproduzido sem reiniciar o player")
        check(await peak_window() > 0.0001, "Há áudio depois do ciclo completo")
    mixer.thread_sounds[0].save_to_wav(folder + "/tecer.wav")
    mixer.floor_steps[0].save_to_wav(folder + "/passo-piso.wav")
    mixer.rug_steps[0].save_to_wav(folder + "/passo-tapete.wav")
    mixer.success_sound.save_to_wav(folder + "/conquista.wav")
    check(int(measurements.get("captured_frames", 0)) > 10000, "Captura analisou amostras reais do mixer")
    var report := {"checks": checks, "failures": failures, "measurements": measurements, "long_session": long_session, "music_seconds": mixer.music_player.stream.get_length(), "audio_driver": AudioServer.get_driver_name(), "executable": OS.get_executable_path(), "resource_root": ProjectSettings.globalize_path("res://")}
    var file := FileAccess.open(folder + "/results.json", FileAccess.WRITE)
    file.store_string(JSON.stringify(report, "\t"))
    file.close()
    AudioServer.remove_bus_effect(0, AudioServer.get_bus_effect_count(0) - 1)
    game.queue_free()
    await frames()
    Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
    print("AUDIO: " + JSON.stringify(report))
    quit(0 if failures.is_empty() else 1)
