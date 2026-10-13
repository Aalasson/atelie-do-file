extends Node
## Tons PCM gerados localmente: não há arquivo de terceiros nem microfone.
var muted := false
var played_count := 0
var click_sound: AudioStreamWAV
var success_sound: AudioStreamWAV
@onready var player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	click_sound = synthesize([480.0])
	success_sound = synthesize([523.25,659.25,783.99])
	player.volume_db = -17

func synthesize(notes: Array) -> AudioStreamWAV:
	const RATE := 22050
	const NOTE_SECONDS := 0.16
	var samples_per_note := int(RATE*NOTE_SECONDS)
	var data := PackedByteArray()
	data.resize(samples_per_note*notes.size()*2)
	for n in range(notes.size()):
		for i in range(samples_per_note):
			var t := float(i)/RATE
			var envelope := minf(t/0.008,1.0)*pow(1.0-t/NOTE_SECONDS,2)
			var sample := int(sin(TAU*float(notes[n])*t)*envelope*19000)
			data.encode_s16((n*samples_per_note+i)*2,sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream

func play_feedback(success: bool = false) -> void:
	if muted:
		return
	player.stream = success_sound if success else click_sound
	player.play()
	played_count += 1

func set_muted(value: bool) -> void:
	muted = value
	if muted:
		player.stop()
