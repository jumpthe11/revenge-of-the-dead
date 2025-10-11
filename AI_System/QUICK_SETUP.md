# Quick AI Setup Guide

## ✅ Fixes Applied

### 1. **Damage System Integration**
- AI enemies now implement `Hit_Successful(damage, direction, position)` method
- Added to "Target" group automatically so player weapons can hit them
- Health bars update properly when damaged
- Compatible with existing `target.gd` and `targetable_objects.gd` damage system

### 2. **Collision Layers Fixed**
- AI enemies set to collision layer 64 (Enemies layer)
- AI enemies can collide with World (layer 1) and Player (layer 2)
- Player weapons should now detect and damage AI enemies

### 3. **Scene Integration**
- All AI scenes properly connected (weapon controllers, detection areas)
- Fire points correctly referenced for projectile spawning

## 🚀 How to Test

### Option 1: Quick Test Scene
1. **Open** `AI_System/scenes/ai_test.tscn`
2. **Add** your player character to the scene
3. **Run** the scene and test shooting the AI enemies

### Option 2: Add to Existing Level  
1. **Drag** AI enemy scenes into your existing level:
   - `AI_System/scenes/rifle_soldier.tscn`
   - `AI_System/scenes/shotgun_rusher.tscn`  
   - `AI_System/scenes/melee_brute.tscn`
2. **Make sure** your player character is in the "Player" group:
   ```gdscript
   # In your player script's _ready() function:
   add_to_group("Player")
   ```
3. **Test** by shooting the enemies

## 🔧 Integration Steps

### For Player Character:
```gdscript
# In your player script _ready() function:
func _ready():
    add_to_group("Player")  # This is required for AI to target you
```

### For Wave System:
1. **Use the complete wave system** (`AI_System/scenes/wave_system.tscn`):
   - Drag into your level
   - Add spawners to the level
   - Connect spawners to wave manager

2. **Manual setup**:
   ```gdscript
   # Example integration
   var spawner = preload("res://AI_System/scenes/ai_spawner.tscn").instantiate()
   add_child(spawner)
   spawner.spawn_enemy()  # Spawns a random enemy
   ```

## 🎯 Expected Behavior

### ✅ **What Should Work Now:**
- AI enemies take damage from player weapons
- Health bars decrease when damaged
- Enemies die when health reaches 0
- Rifle soldiers engage at medium range with burst fire
- Shotgun rushers charge the player aggressively  
- Melee brutes charge and attack up close
- All enemies can pathfind and target the player

### 🔍 **Testing Checklist:**
- [ ] Player can damage AI enemies
- [ ] AI enemies chase and attack player
- [ ] Health bars update correctly
- [ ] Different AI types behave distinctly
- [ ] Enemies die when health reaches 0

## 🐛 Troubleshooting

### "AI enemies don't take damage"
- Ensure player is in "Player" group
- Check that weapons are targeting collision layer 64
- Verify AI enemies are in "Target" group (automatic)

### "AI enemies don't move"
- Ensure AI scenes have proper collision setup  
- Check that detection areas are connected
- Player must be in "Player" group for targeting

### "Melee enemies don't attack"
- They need to get within 3m range first
- Check collision layers between AI and player

## 📋 Next Steps

1. **Test the basic AI** in your existing level
2. **Try the wave system** for coordinated spawning
3. **Customize AI stats** in the enemy scene files
4. **Create custom waves** using the WaveConfig resources

The AI system is now fully compatible with your existing damage system and should work seamlessly with your player weapons!