extends CanvasLayer

@onready var current_weapon_label = $debug_hud/HBoxContainer/CurrentWeapon
@onready var current_ammo_label = $debug_hud/HBoxContainer2/CurrentAmmo
@onready var current_weapon_stack = $debug_hud/HBoxContainer3/WeaponStack
@onready var current_weapon_stats = $debug_hud/HBoxContainer4/WeaponStats
@onready var hit_sight = $HitSight
@onready var hit_sight_timer = $HitSight/HitSightTimer
@onready var overLay = $Overlay

func _on_weapons_manager_update_weapon_stack(WeaponStack):
	current_weapon_stack.text = ""
	for i in WeaponStack:
		current_weapon_stack.text += "\n"+i.weapon.weapon_name

func _on_weapons_manager_update_ammo(Ammo):
	current_ammo_label.set_text(str(Ammo[0])+" / "+str(Ammo[1]))

func _on_weapons_manager_weapon_changed(WeaponName):
	current_weapon_label.set_text(WeaponName)

func _on_hit_sight_timer_timeout():
	hit_sight.set_visible(false)

func _on_weapons_manager_add_signal_to_hud(_projectile):
	_projectile.Hit_Successfull.connect(_on_weapons_manager_hit_successfull)

func _on_weapons_manager_hit_successfull():
	hit_sight.set_visible(true)
	hit_sight_timer.start()

func load_over_lay_texture(Active:bool, txtr: Texture2D = null):
		overLay.set_texture(txtr)
		overLay.set_visible(Active)

func _on_weapons_manager_connect_weapon_to_hud(_weapon_resouce: WeaponResource):
	_weapon_resouce.update_overlay.connect(load_over_lay_texture)

func _on_weapons_manager_weapon_stats_updated(stats: WeaponStatsModifier) -> void:
	if not stats:
		current_weapon_stats.text = "No Stats"
		return
	
	var stats_text = ""
	stats_text += "Damage: %.1f (%.1f)\n" % [stats.final_damage, stats.base_damage]
	stats_text += "Fire Rate: %.1f RPM (%.1f)\n" % [stats.final_fire_rate, stats.base_fire_rate]
	stats_text += "Magazine: %d (%d)\n" % [stats.final_magazine, stats.base_magazine]
	stats_text += "Range: %.0f (%.0f)\n" % [stats.final_fire_range, stats.base_fire_range]
	stats_text += "Reload: %.2fs\n" % stats.final_reload_time
	stats_text += "Anim Speed: %.2fx" % stats.animation_speed_multiplier
	
	current_weapon_stats.text = stats_text
