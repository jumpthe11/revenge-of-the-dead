extends Control

## Simple UI controller for the wave system
## Connects buttons to wave manager functions

@onready var wave_manager: WaveManager = get_parent()
@onready var start_button: Button = $Controls/StartButton
@onready var next_wave_button: Button = $Controls/NextWaveButton
@onready var stop_button: Button = $Controls/StopButton

func _ready() -> void:
	# Connect UI buttons
	if start_button:
		start_button.pressed.connect(_on_start_waves)
	if next_wave_button:
		next_wave_button.pressed.connect(_on_skip_wave)
	if stop_button:
		stop_button.pressed.connect(_on_stop_waves)
	
	# Connect wave manager signals for UI feedback
	if wave_manager:
		wave_manager.wave_started.connect(_on_wave_started)
		wave_manager.wave_completed.connect(_on_wave_completed)
		wave_manager.all_waves_completed.connect(_on_all_waves_completed)

func _on_start_waves() -> void:
	if wave_manager:
		wave_manager.start_waves()
		start_button.disabled = true

func _on_skip_wave() -> void:
	if wave_manager:
		wave_manager.skip_to_next_wave()

func _on_stop_waves() -> void:
	if wave_manager:
		wave_manager.stop_waves()
		start_button.disabled = false

func _on_wave_started(wave_number: int, wave_name: String) -> void:
	print("UI: Wave started - ", wave_name)

func _on_wave_completed(wave_number: int, reward: int) -> void:
	print("UI: Wave completed! Reward: ", reward)

func _on_all_waves_completed() -> void:
	print("UI: All waves completed!")
	start_button.disabled = false