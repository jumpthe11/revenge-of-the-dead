# Damage System Integration Guide

## ✅ What Was Done

The advanced damage system has been **fully integrated** into your game! Here's what was changed:

### Files Modified:
1. **`Player_Controller/scripts/Projectiles/Projectile.gd`**
   - Added `projectile_source` and `damage_type` variables
   - Updated `Hit_Scan_damage()` to use DamageSystem
   - Updated `_on_body_entered()` to use DamageSystem

2. **`Player_Controller/scripts/Weapon_State_Machine/Weapon_State_Machine.gd`**
   - Sets `projectile_source` to player when firing
   - Sets `damage_type` to appropriate type
   - Updated melee attacks to use DamageSystem

3. **`AI_System/scripts/ai_weapon_controller.gd`**
   - Sets `projectile_source` to AI enemy when firing
   - Sets `damage_type` for AI projectiles
   - Both hitscan and physics projectiles now track source

4. **`AI_System/scripts/ai_melee_brute.gd`**
   - Melee attacks use DamageSystem with MELEE type
   - Death explosion uses DamageSystem with EXPLOSIVE type

5. **`WARP.md`**
   - Added comprehensive damage system documentation

### Files Created:
1. **`Player_Controller/scripts/damage_system.gd`**
   - Core damage calculation system
   - Handles all damage types and modifiers

---

## 🎮 How It Works Now

### Damage Flow:
```
Attacker fires weapon
    ↓
Projectile spawned with source = attacker
    ↓
Projectile hits target
    ↓
DamageSystem.apply_damage_to_target() called
    ↓
System checks:
  - Who is attacking? (Player/AI/Environment)
  - Who is being hit? (Player/AI)
  - What type of damage? (Bullet/Melee/Explosive/Environmental)
  - Does target have armor?
  - Is it a headshot or critical?
    ↓
Final damage calculated with all modifiers
    ↓
Target.Hit_Successful() or target.take_damage() called
    ↓
Target takes calculated damage
```

---

## 📊 Damage Modifiers

### Player vs AI: **100% damage** ✓
- Players deal full damage to enemies
- Enemies deal full damage to players
- This is the core combat mechanic

### Player vs Player: **10% damage** ⚠️
- Prevents griefing in multiplayer
- Friends can still damage each other slightly
- Encourages teamwork

### AI vs AI: **0% damage** 🚫
- Enemies cannot damage each other
- Prevents AI from killing themselves
- Keeps combat focused on player

### Environmental: **100% damage** 💥
- Fall damage, traps, hazards deal full damage to everyone

---

## 🛡️ Armor System (Optional)

To add armor to any character:

```gdscript
# In your player_character.gd or ai_enemy_base.gd
var armor_value: float = 50.0  # Add this variable

func get_armor_value() -> float:
    return armor_value
```

**How armor works:**
- Uses diminishing returns formula
- Different effectiveness vs different damage types:
  - **Bullets**: Full armor effectiveness
  - **Melee**: 70% armor effectiveness
  - **Explosives**: 50% armor effectiveness
  - **Environmental**: 30% armor effectiveness

**Example:** 50 armor = ~33% damage reduction from bullets

---

## 🎯 Advanced Features

### Headshots
To enable headshots, you need to detect head collisions:

```gdscript
# When detecting a hit
var is_headshot = false
if collision_body_part == "Head":
    is_headshot = true

DamageSystem.apply_damage_to_target(
    target,
    damage,
    self,
    DamageSystem.DamageType.BULLET,
    direction,
    position,
    is_headshot  # Pass headshot detection
)
```

**Headshot multiplier: 2.5x damage** 💀

### Critical Hits
- Automatically calculated by DamageSystem
- 5% chance
- 2x damage multiplier
- Only applies when NOT a headshot

---

## 🔧 Customization

### Change Friendly Fire Damage
Edit `damage_system.gd`:
```gdscript
const DAMAGE_MODIFIERS = {
    "player_to_player": 0.10,  # Change this (0.0 - 1.0)
    # 0.0 = no friendly fire
    # 0.5 = half damage
    # 1.0 = full damage
}
```

### Change Critical Hit Chance
```gdscript
const CRITICAL_HIT_CHANCE = 0.05  # 5% -> Change to 0.10 for 10%
const CRITICAL_HIT_MULTIPLIER = 2.0  # 2x damage -> Change as needed
```

### Change Headshot Multiplier
```gdscript
const HEADSHOT_MULTIPLIER = 2.5  # Change to 3.0 for 3x damage
```

### Add New Damage Types
```gdscript
enum DamageType {
    BULLET,
    EXPLOSIVE,
    MELEE,
    ENVIRONMENTAL,
    FIRE,        # Add new type
    POISON,      # Add new type
}
```

Then add armor effectiveness:
```gdscript
const ARMOR_EFFECTIVENESS = {
    DamageType.FIRE: 0.3,    # 30% effectiveness
    DamageType.POISON: 0.0,  # 0% effectiveness (bypasses armor)
}
```

---

## 🧪 Testing

### Test Friendly Fire:
1. Run the game with 2 players (or test with AI if you add them to "Player" group temporarily)
2. Shoot each other
3. Verify damage is only 10% of normal

### Test AI Friendly Fire:
1. Spawn multiple AI enemies close together
2. Have them shoot at you while positioned between them
3. Verify AI enemies don't damage each other

### Test Damage Types:
1. Get hit by bullets → Check damage
2. Get hit by melee → Check damage with armor effectiveness
3. Stand near death explosion → Check explosive damage

---

## 💡 Future Enhancements

### Headshot Detection
Add a collision shape to character heads:
```gdscript
# In your character scene
Area3D (Head hitbox)
  └─ CollisionShape3D (head_collision)

# In your projectile/hit detection
if collision_area.name == "Head":
    is_headshot = true
```

### Damage Numbers UI
```gdscript
# When damage is applied
var damage_text = DamageSystem.get_damage_display_text(
    final_damage,
    is_critical,
    is_headshot
)
# Display damage_text as floating combat text
```

### Damage Resistance Items
```gdscript
# Add to player inventory system
var damage_resistance = {
    DamageSystem.DamageType.BULLET: 0.2,  # 20% bullet resistance
    DamageSystem.DamageType.EXPLOSIVE: 0.5  # 50% explosive resistance
}

# Modify DamageSystem to check for resistance
```

---

## 🐛 Troubleshooting

### "DamageSystem not found" error
Make sure `damage_system.gd` is saved and Godot has registered the class. Try:
1. Close and reopen the project
2. Or add to autoload as a singleton

### Friendly fire not working
1. Check that players are in "Player" group
2. Check that `projectile_source` is set correctly
3. Add debug prints in `get_relationship_modifier()`

### AI still damaging each other
1. Verify AI enemies are in "Enemy" or "AI" group
2. Check that `projectile_source` is set to AI parent
3. Add debug prints to verify source/target types

---

## 📝 Summary

✅ **Fully Integrated** - All weapons and attacks use the damage system  
✅ **Friendly Fire** - 10% player-to-player damage  
✅ **AI Protection** - 0% AI-to-AI damage  
✅ **Armor Ready** - Optional armor system available  
✅ **Critical Hits** - 5% chance for 2x damage  
✅ **Headshots** - 2.5x damage multiplier ready  
✅ **Extensible** - Easy to add new damage types and modifiers  

The system is production-ready and will scale perfectly for multiplayer!
