extends Node
class_name DamageSystem

## Damage System
## Manages all damage calculations, type modifiers, and friendly fire rules
## Integrates with existing player/AI health systems

# Damage type identifiers
enum DamageType {
	BULLET,        # Standard projectile damage
	EXPLOSIVE,     # Rockets, grenades, explosions
	MELEE,         # Close combat attacks
	ENVIRONMENTAL  # Fall damage, hazards, traps
}

# Source type identifiers
enum SourceType {
	PLAYER,        # Damage from player
	AI_ENEMY,      # Damage from AI enemies
	ENVIRONMENT    # Damage from world hazards
}

# Damage modifiers configuration
const DAMAGE_MODIFIERS = {
	# AI vs Player (Full damage)
	"ai_to_player": 1.0,
	
	# Player vs AI (Full damage)
	"player_to_ai": 1.0,
	
	# Player vs Player (10% damage - friendly fire reduction)
	"player_to_player": 0.10,
	
	# Environmental damage (Full damage to all)
	"environment_to_all": 1.0
}

# Armor/resistance multipliers by damage type
const ARMOR_EFFECTIVENESS = {
	DamageType.BULLET: 1.0,      # Full effectiveness against bullets
	DamageType.EXPLOSIVE: 0.5,   # 50% effectiveness against explosives
	DamageType.MELEE: 0.7,       # 70% effectiveness against melee
	DamageType.ENVIRONMENTAL: 0.3 # 30% effectiveness against environmental
}

# Critical hit configuration
const CRITICAL_HIT_CHANCE = 0.05  # 5% base chance
const CRITICAL_HIT_MULTIPLIER = 2.0  # 2x damage on critical hits
const HEADSHOT_MULTIPLIER = 2.5      # 2.5x damage for headshots

## Calculate final damage based on source, target, and damage type
## Returns the modified damage value after all calculations
static func calculate_damage(
	base_damage: float,
	source: Node,
	target: Node,
	damage_type: DamageType = DamageType.BULLET,
	is_headshot: bool = false
) -> float:
	if not source or not target:
		return base_damage
	
	var final_damage = base_damage
	
	# Determine source and target types
	var source_type = get_source_type(source)
	var target_type = get_source_type(target)
	
	# Apply relationship modifier (friendly fire, etc.)
	var relationship_modifier = get_relationship_modifier(source_type, target_type)
	final_damage *= relationship_modifier
	
	# Apply armor/resistance if target has armor
	if target.has_method("get_armor_value"):
		var armor_value = target.get_armor_value()
		var armor_effectiveness = ARMOR_EFFECTIVENESS.get(damage_type, 1.0)
		var damage_reduction = calculate_armor_reduction(armor_value, armor_effectiveness)
		final_damage *= (1.0 - damage_reduction)
	
	# Apply headshot multiplier
	if is_headshot:
		final_damage *= HEADSHOT_MULTIPLIER
	
	# Check for critical hit (only for non-headshots)
	elif should_apply_critical_hit():
		final_damage *= CRITICAL_HIT_MULTIPLIER
	
	return max(0.0, final_damage)  # Never return negative damage

## Determine the source type of a node
static func get_source_type(node: Node) -> SourceType:
	if not node:
		return SourceType.ENVIRONMENT
	
	# Check if it's a player
	if node.is_in_group("Player"):
		return SourceType.PLAYER
	
	# Check if it's an AI enemy
	if node.is_in_group("Enemy") or node.is_in_group("AI"):
		return SourceType.AI_ENEMY
	
	# Default to environment
	return SourceType.ENVIRONMENT

## Get the damage modifier based on relationship between source and target
static func get_relationship_modifier(source_type: SourceType, target_type: SourceType) -> float:
	# Environment damage is always full
	if source_type == SourceType.ENVIRONMENT:
		return DAMAGE_MODIFIERS["environment_to_all"]
	
	# AI attacking Player
	if source_type == SourceType.AI_ENEMY and target_type == SourceType.PLAYER:
		return DAMAGE_MODIFIERS["ai_to_player"]
	
	# Player attacking AI
	if source_type == SourceType.PLAYER and target_type == SourceType.AI_ENEMY:
		return DAMAGE_MODIFIERS["player_to_ai"]
	
	# Player attacking Player (friendly fire)
	if source_type == SourceType.PLAYER and target_type == SourceType.PLAYER:
		return DAMAGE_MODIFIERS["player_to_player"]
	
	# AI attacking AI (no friendly fire between AI)
	if source_type == SourceType.AI_ENEMY and target_type == SourceType.AI_ENEMY:
		return 0.0  # AI cannot damage other AI
	
	# Default to full damage
	return 1.0

## Calculate armor damage reduction (0.0 to 1.0)
static func calculate_armor_reduction(armor_value: float, effectiveness: float) -> float:
	# Formula: reduction = (armor * effectiveness) / (100 + armor * effectiveness)
	# This provides diminishing returns on armor
	var effective_armor = armor_value * effectiveness
	return effective_armor / (100.0 + effective_armor)

## Determine if a critical hit should occur
static func should_apply_critical_hit() -> bool:
	return randf() < CRITICAL_HIT_CHANCE

## Apply damage to a target with full damage system integration
static func apply_damage_to_target(
	target: Node,
	base_damage: float,
	source: Node,
	damage_type: DamageType = DamageType.BULLET,
	direction: Vector3 = Vector3.ZERO,
	position: Vector3 = Vector3.ZERO,
	is_headshot: bool = false
) -> bool:
	if not target or not target.is_in_group("Target"):
		return false
	
	# Calculate final damage
	var final_damage = calculate_damage(base_damage, source, target, damage_type, is_headshot)
	
	# Apply damage using the target's damage method
	if target.has_method("Hit_Successful"):
		target.Hit_Successful(final_damage, direction, position)
		return true
	elif target.has_method("take_damage"):
		target.take_damage(final_damage, source)
		return true
	
	return false

## Get a formatted damage display string (for UI)
static func get_damage_display_text(
	damage: float,
	is_critical: bool = false,
	is_headshot: bool = false
) -> String:
	var damage_text = str(int(damage))
	
	if is_headshot:
		return "💀 " + damage_text + " HEADSHOT!"
	elif is_critical:
		return "⚡ " + damage_text + " CRITICAL!"
	else:
		return damage_text

## Check if friendly fire warning should be shown
static func should_show_friendly_fire_warning(source: Node, target: Node) -> bool:
	var source_type = get_source_type(source)
	var target_type = get_source_type(target)
	
	return source_type == SourceType.PLAYER and target_type == SourceType.PLAYER
