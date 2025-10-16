# Revenge of the Dead - FPS Template

## Project Overview

**Revenge of the Dead** is a First Person Shooter base defense game built in Godot 4. Players defend their base against waves of attacking zombies using a variety of weapons and strategic positioning. The project evolved from an FPS template into a focused base defense experience with wave-based gameplay.

### Engine & Platform
- **Engine**: Godot 4.5
- **Platform**: Windows (PowerShell development environment)
- **Project Name**: RevengeOfTheDead
- **Main Scene**: `res://Example World/Objects/World/world.tscn`
- **Game Mode**: Single-player base defense (multiplayer planned for future)
- **Game Type**: FPS + Tower Defense hybrid

---

## 🏗️ Project Structure

### Core Directories

```
D:\Games\revenge-of-the-dead\
├── .godot/                     # Godot editor files and cache
├── AI_System/                  # Performance-optimized AI enemies
├── Example World/              # Demo level and world objects
├── Player_Controller/          # Main player system and weapons
├── media/                      # Documentation images and assets
├── project.godot              # Main project configuration
├── README.md                  # Original template documentation
└── Title.png                  # Project icon
```

### Detailed Structure

#### 🎮 Player_Controller/
The heart of the FPS system containing all player-related functionality:

```
Player_Controller/
├── scripts/
│   ├── Player_Character/       # Core player movement and camera
│   ├── Projectiles/           # Bullet and projectile systems
│   └── Weapon_State_Machine/  # Weapon management system
├── Spawnable_Objects/         # Instantiable game objects
│   ├── Clips/                 # Weapon ammunition clips
│   ├── Projectiles_To_Load/   # Different projectile types
│   ├── SprayProfiles/         # Weapon spread patterns
│   └── Weapons/               # Individual weapon instances
└── player_character.tscn      # Main player scene
```

#### 🤖 AI_System/
Performance-optimized AI enemies with simplified weapon mechanics:

```
AI_System/
├── scripts/
│   ├── ai_enemy_base.gd       # Base AI class with core behavior
│   ├── ai_weapon_controller.gd # Streamlined weapon controller
│   ├── ai_weapon_resource.gd   # Simplified weapon resources
│   ├── ai_rifle_soldier.gd     # Medium-range rifle AI
│   ├── ai_shotgun_rusher.gd    # Close-range aggressive AI
│   ├── ai_melee_brute.gd       # Melee charging AI
│   └── ai_spawner.gd           # Enemy spawning system
├── scenes/
│   ├── rifle_soldier.tscn      # Rifle AI scene
│   ├── shotgun_rusher.tscn     # Shotgun AI scene
│   └── melee_brute.tscn        # Melee AI scene
└── resources/
    ├── rifle_ai_weapon.tres    # Rifle weapon config
    └── shotgun_ai_weapon.tres  # Shotgun weapon config
```

#### 🌍 Example World/
Demo level showcasing the FPS system:

```
Example World/
├── Objects/
│   └── World/
│       ├── WorldMesh/         # Level geometry
│       ├── box_1.tscn         # Interactive objects
│       ├── target.tscn        # Shooting targets
│       └── world.tscn         # Main world scene
└── Scripts/
    ├── physic_objects/        # Physics-based object scripts
    └── target.gd              # Target interaction logic
```

---

---

## 🤖 AI System

The AI System is a performance-optimized enemy framework that uses simplified weapon mechanics derived from the player's weapon system. Each AI enemy uses a single weapon type and specialized behavior patterns.

### AI Architecture

**Key Principles:**
- **Performance First**: Simplified state machines without complex animations
- **One Weapon Per AI**: Each enemy specializes in a single weapon type
- **Modular Design**: Easy to create new AI types by extending base classes
- **Memory Efficient**: Object pooling and optimized update cycles

### AI Weapon System
**Location**: `AI_System/scripts/ai_weapon_controller.gd`

**Simplified Features:**
- **No Animation Dependencies**: Direct projectile spawning
- **Projectile Pooling**: Reuse projectiles for performance
- **Burst Fire Support**: Configurable burst patterns
- **Range-Based Engagement**: Smart distance management
- **Spread Patterns**: Accuracy simulation without complex calculations

### Advanced Damage System
**Location**: `Player_Controller/scripts/damage_system.gd`

The game features a comprehensive damage calculation system that handles all damage types, friendly fire, armor, and special mechanics.

**Core Features:**
- **Damage Type System**: Bullet, Explosive, Melee, Environmental
- **Source Detection**: Automatically identifies Player, AI Enemy, or Environment sources
- **Friendly Fire Reduction**: Players deal only 10% damage to other players
- **Full Damage**: AI ↔ Player interactions deal 100% damage
- **No AI Friendly Fire**: AI enemies cannot damage each other (0% damage)
- **Armor System**: Optional armor with diminishing returns and type effectiveness
- **Critical Hits**: 5% chance for 2x damage
- **Headshot Multiplier**: 2.5x damage for headshots

**Damage Modifiers:**
```gdscript
# Full damage scenarios
AI → Player: 100% damage
Player → AI: 100% damage
Environment → All: 100% damage

# Reduced damage scenarios  
Player → Player: 10% damage (friendly fire protection)
AI → AI: 0% damage (no AI friendly fire)
```

**Armor Effectiveness by Damage Type:**
- **Bullet Damage**: 100% armor effectiveness
- **Melee Damage**: 70% armor effectiveness  
- **Explosive Damage**: 50% armor effectiveness
- **Environmental Damage**: 30% armor effectiveness

**Usage Example:**
```gdscript
# Apply damage through the damage system
DamageSystem.apply_damage_to_target(
    target,                           # Target node
    50.0,                             # Base damage
    self,                             # Source node
    DamageSystem.DamageType.BULLET,   # Damage type
    direction,                        # Hit direction
    position,                         # Hit position
    true                              # Is headshot
)

# Or calculate damage manually
var final_damage = DamageSystem.calculate_damage(
    50.0,                             # Base damage
    source_node,                      # Source
    target_node,                      # Target
    DamageSystem.DamageType.EXPLOSIVE # Damage type
)
```

### Enemy-Player Combat System

**Damage Compatibility:**
The game uses a unified damage system compatible between enemies and the player:

**Player Requirements:**
- Must be in both "Player" and "Target" groups
- Must implement `Hit_Successful(damage, Direction, Position)` method
- Must implement `take_damage(damage, source)` method
- Optional: `apply_knockback(knockback_vector)` method for knockback effects
- Optional: `get_armor_value()` method for armor system integration

**Enemy Damage Types:**
1. **Ranged Weapons**: AI uses weapon controller with projectiles that call damage system
2. **Melee Attacks**: Melee brutes call damage system directly when in range
3. **Explosions**: Death explosions and area damage use explosive damage type
4. **All damage** is processed through `DamageSystem` for proper modifiers

**How It Works:**
- All projectiles track their source (player or AI enemy)
- When hitting a target, projectiles call `DamageSystem.apply_damage_to_target()`
- `DamageSystem` calculates final damage based on:
  - Source type (Player/AI/Environment)
  - Target type (Player/AI)
  - Damage type (Bullet/Melee/Explosive/Environmental)
  - Target armor (if present)
  - Special modifiers (headshot, critical hit)
- Applies friendly fire reduction (10% for player-to-player)
- Prevents AI friendly fire (0% damage)
- Calls `Hit_Successful()` or `take_damage()` with calculated damage
- Results in health reduction, knockback, and potential death

### Available AI Types

#### 🎯 Rifle Soldier (`AIRifleSoldier`)
- **Role**: Medium-range precision combat
- **Behavior**: Maintains optimal distance, uses cover
- **Weapon**: Burst-fire rifle with 40m range
- **Tactics**: Strafing movement, suppressive fire

#### 🔫 Shotgun Rusher (`AIShotgunRusher`)
- **Role**: Aggressive close-range assault
- **Behavior**: Rushes target, double-tap attacks
- **Weapon**: High-damage shotgun with 12m range
- **Tactics**: Fast approach, circle strafing

#### ⚔️ Melee Brute (`AIMeleeBrute`)
- **Role**: Tank and close-combat specialist
- **Behavior**: Charges at targets, high health
- **Weapon**: Melee attacks with knockback
- **Tactics**: Charging attacks, death explosion

### AI Spawning System
**Location**: `AI_System/scripts/ai_spawner.gd`

**Features:**
- **Performance Management**: Max enemy limits
- **Object Pooling**: Reuse enemy instances
- **Smart Positioning**: Distance-based spawn validation
- **Wave System**: Coordinated enemy spawning
- **Weighted Selection**: Configurable enemy type probabilities

### Wave Management System
**Location**: `AI_System/scripts/wave_manager.gd`, `AI_System/scenes/wave_system.tscn`

**Features:**
- **Wave Configuration**: Resource-based wave definitions (`WaveConfig`)
- **Progressive Difficulty**: Configurable wave progression with multipliers
- **UI Integration**: Real-time wave progress and enemy count display
- **Flexible Spawning**: Support for timed spawns, burst spawning, and enemy limits
- **Boss Wave Support**: Special wave types with enhanced rewards and modifiers

**Wave Configuration Resources:**
- `wave_1_config.tres` - First Contact: 5 enemies (3 rifle, 2 shotgun)
- `wave_2_config.tres` - The Horde: 8 enemies (4 rifle, 3 shotgun, 1 brute)
- `wave_boss_config.tres` - Boss Wave: 5 enemies (3 brute, 2 rifle) with special modifiers

---

## 🔧 Core Systems

### Player Character System
**Location**: `Player_Controller/scripts/Player_Character/player_character.gd`

**Features**:
- **Movement**: WASD movement with physics-based acceleration
- **Camera**: Mouse look with clamped vertical rotation
- **Crouch System**: Toggle/hold crouch with collision detection
- **Lean System**: Q/E leaning with collision prevention
- **Sprint System**: Stamina-based sprinting with cooldown
- **Jump System**: Calculated jump physics with coyote time
- **Health System**: Damage, death, and optional regeneration

**Key Parameters**:
- Sprint speed: 2.0x normal
- Walk speed: 0.5x normal
- Jump height: 2.0 units
- Lean speed: 0.2 seconds
- Max health: 100 HP
- Health regeneration: Optional (disabled by default)
- Regeneration rate: 5 HP/second
- Regeneration delay: 5 seconds after taking damage

**Health System Methods**:
- `take_damage(damage: float, source: Node)`: Reduce player health
- `Hit_Successful(damage, Direction, Position)`: Compatibility method for weapon systems
- `apply_knockback(knockback_vector: Vector3)`: Apply knockback force to player
- `heal(amount: float)`: Restore player health
- `get_health_percentage()`: Returns health as 0.0-1.0 value
- `is_alive()`: Check if player is still alive

**Health System Signals**:
- `player_died`: Emitted when player health reaches zero
- `player_damaged(current_health, max_health)`: Emitted when player takes damage

### Weapon State Machine
**Location**: `Player_Controller/scripts/Weapon_State_Machine/Weapon_State_Machine.gd`

**Architecture**:
- **Resource-Based**: All weapons defined via `WeaponResource` files
- **Component System**: Modular projectiles, spray patterns, and behaviors
- **State Management**: Handles weapon switching, shooting, reloading
- **Animation Integration**: Seamless animation system integration
- **Dual Shooting System**: Separate functions for manual shots and auto-fire
  - `shoot()`: Manual shooting with fire rate timer control
  - `auto_fire_shoot()`: Auto-fire that relies on animation timing

**Supported Weapon Types**:
- **Hitscan**: Instant-hit weapons (rifles, pistols)
- **Projectile**: Physics-based projectiles (rockets, grenades)
- **Melee**: Close-combat weapons with hitbox detection
- **Shotgun**: Spread-pattern weapons with multiple projectiles

### Weapon Resource System
**Location**: `Player_Controller/scripts/Weapon_State_Machine/weapon_resource.gd`

**Configuration Options**:
```gdscript
# Weapon Animations
- pick_up_animation: String
- shoot_animation: String
- reload_animation: String
- change_animation: String
- melee_animation: String

# Weapon Stats
- magazine: int (clip size)
- max_ammo: int (reserve ammo)
- damage: int (base damage)
- fire_range: int (effective range)
- fire_rate: float (rounds per minute - RPM)
- melee_damage: float (melee attack damage)
- auto_fire: bool (full-auto capability)

# Weapon Behavior
- can_be_dropped: bool
- weapon_spray: PackedScene (spread pattern)
- projectile_to_load: PackedScene (bullet type)
- incremental_reload: bool (shotgun-style reload)
```

### Weapon Stats Modifier System
**Location**: `Player_Controller/scripts/Weapon_State_Machine/weapon_stats_modifier.gd`

**Features**:
- **Additive & Multiplicative Modifiers**: Support for both flat bonuses and percentage increases
- **Real-time Stat Calculation**: Cached values updated only when modifiers change
- **Fire Rate Animation Scaling**: Smart animation speed scaling (30 RPM = 1.0x, 120+ RPM = 2.0x max)
- **Performance Optimized**: Timer-based fire rate limiting instead of per-frame calculations

**Available Stats**:
- **Damage**: Base weapon damage with modifiers
- **Fire Rate**: Rounds per minute with smart animation scaling
- **Magazine Size**: Clip capacity with modifiers
- **Max Ammo**: Reserve ammunition capacity
- **Fire Range**: Maximum effective range
- **Melee Damage**: Close-combat damage
- **Reload Time**: Time to reload weapon

**Usage Example**:
```gdscript
# Add +10 damage and +50% fire rate
weapon_state_machine.add_stat_modifier("damage", 10.0, 1.0)
weapon_state_machine.add_stat_modifier("fire_rate", 0.0, 1.5)
```

---

## 🎯 Available Weapons

### Current Weapon Arsenal
The template includes several pre-configured weapons:

1. **Blaster I** - Basic energy weapon
2. **Blaster L** - Long-range precision weapon
3. **Blaster M** - Medium-range assault weapon
4. **Blaster N** - High-rate-of-fire weapon
5. **Blaster Q** - Special weapon variant
6. **Melee Weapon** - Close-combat option

### Weapon Assets
All weapon models use Kenny's Blaster Kit assets:
- **Source**: [Kenny Blaster Kit](https://www.kenney.nl/assets/blaster-kit)
- **Format**: .glb 3D models
- **License**: Creative Commons (for assets), MIT (for code)

---

## 🎮 Controls

### Movement Controls
| Action | Key/Mouse | Description |
|--------|-----------|-------------|
| Move | WASD | Character movement |
| Look | Mouse | Camera control |
| Jump | Space | Jump action |
| Sprint | Shift | Run faster (stamina-based) |
| Walk | Alt | Walk slower |
| Crouch | C | Crouch/uncrouch |
| Lean Left | Q | Lean left |
| Lean Right | E | Lean right |

### Combat Controls
| Action | Key/Mouse | Description |
|--------|-----------|-------------|
| Shoot | Left Mouse | Primary fire |
| Secondary Fire | Right Mouse | Alternative fire mode |
| Reload | R | Reload weapon |
| Melee | F | Melee attack |
| Drop Weapon | G | Drop current weapon |
| Weapon Up | Mouse Wheel Up | Next weapon |
| Weapon Down | Mouse Wheel Down | Previous weapon |
| Select Weapon | 1-4 | Direct weapon selection |

### System Controls
| Action | Key | Description |
|--------|-----|-------------|
| Menu | Escape | Toggle mouse capture |

---

## ⚡ Performance Optimizations

### AI System Optimizations

The AI system is designed with performance as a primary concern:

**Update Cycle Optimization:**
- **Staggered Updates**: Different AI systems update on different frames
- **Distance-Based LOD**: Reduce update frequency for distant enemies
- **Pooled Objects**: Reuse enemy and projectile instances
- **Batch Operations**: Group similar AI operations together

**Memory Management:**
- **Object Pooling**: Pre-instantiate enemies and projectiles
- **Cleanup Systems**: Automatic cleanup of inactive projectiles
- **Simplified State**: Minimal state tracking per AI
- **Efficient Pathfinding**: Simple direct movement instead of complex navigation

**Weapon System Optimizations:**
- **No Animation Dependencies**: Direct projectile spawning
- **Reduced Calculations**: Simplified spread and accuracy systems
- **Limited Active Projectiles**: Configurable limits per weapon type
- **Fast Collision Checks**: Optimized raycasting for line-of-sight

**Projectile Performance Optimizations:**
- **Automatic Cleanup Timers**: Rigid body projectiles self-destruct after configurable time (default 8 seconds)
- **No Infinite Travel**: Prevents performance issues from projectiles traveling indefinitely
- **Memory Management**: Automatic removal from tracking arrays when projectiles are cleaned up

**Weapon Stats Performance Optimizations:**
- **Timer-Based Fire Rate**: Uses efficient Timer nodes instead of per-frame calculations
- **Cached Stat Calculations**: Stats only recalculated when modifiers change, not every shot
- **Animation Speed Capping**: Prevents extremely fast animations (max 2.0x speed) for high fire rates
- **Meta Data Storage**: Weapon stats stored as metadata to avoid unnecessary object creation

---

## 📊 Physics & Collision Layers

The project uses a organized physics layer system:

1. **World** - Static environment geometry
2. **Player** - Player character collision
3. **Objects** - Interactive objects
4. **Weapons** - Weapon pickups and drops
5. **Rigid Body Projectiles** - Physics-based projectiles
6. **Enemies** - NPC collision layer

---

## 🛠️ Development Features

### Modular Design Benefits

1. **Rapid Prototyping**: Quickly create new weapons using resources
2. **Asset Swapping**: Easy model/animation replacement
3. **Component Reuse**: Share projectiles/spray patterns between weapons
4. **Scalable Architecture**: Add new weapon types without core changes

### Debugging Tools

- **Hit Visualization**: Debug markers for projectile hits
- **Performance Monitoring**: Sprint stamina bar
- **Console Logging**: Weapon state warnings and errors

### Animation System Integration

- **AnimationTree**: Sophisticated blending for movement states
- **State Blending**: Crouch, lean, and movement combinations
- **Weapon Animations**: Seamless weapon state transitions

---

## 📁 Important Files

### Core Scripts
- `player_character.gd` - Main player controller
- `Weapon_State_Machine.gd` - Weapon management system
- `weapon_resource.gd` - Weapon configuration resource
- `WeaponSlot.gd` - Individual weapon slot management
- `Projectile.gd` - Base projectile class

### AI System Scripts
- `ai_enemy_base.gd` - Base AI enemy class
- `ai_weapon_controller.gd` - Simplified AI weapon controller
- `ai_weapon_resource.gd` - Performance-optimized weapon resources
- `ai_rifle_soldier.gd` - Medium-range rifle AI
- `ai_shotgun_rusher.gd` - Aggressive close-range AI
- `ai_melee_brute.gd` - Melee charging AI
- `ai_spawner.gd` - Enemy spawning and management

### Scene Files
- `player_character.tscn` - Main player scene
- `world.tscn` - Demo level
- `*.tscn` (weapons) - Individual weapon scenes

### Resource Files
- `*.tres` - Weapon configuration files
- `world_environment.tres` - Environmental settings

---

## 🚀 Getting Started

### For Developers

1. **Open Project**: Load `project.godot` in Godot 4.5+
2. **Run Demo**: Press F5 to play the example world
3. **Customize Weapons**: Edit weapon resources in `Player_Controller/scripts/Weapon_State_Machine/Weapon_Resources/`
4. **Add New Weapons**: Create new `WeaponResource` files and corresponding scenes
5. **Add AI Enemies**: Use `AI_System/scripts/ai_spawner.gd` to spawn enemies
6. **Create Custom AI**: Extend `AIEnemyBase` class for new enemy types

### For Game Designers

1. **Weapon Tuning**: Modify weapon stats in resource files
2. **Animation Setup**: Reference animations by string name in resources
3. **Level Design**: Use provided components to build custom levels
4. **Asset Integration**: Replace placeholder models with final art

---

## 📚 Additional Resources

### Documentation
- **Official Docs**: [FPS Template Documentation](https://docs.chaffgames.com/docs/fpstemplate/table_of_contents/)
- **Discord Community**: [Chaff Games Discord](https://discord.gg/Exzd8QmKrU)
- **Support**: [Patreon](https://patreon.com/ChaffGames)

### Credits
- **Developer**: Isaac from Chaff Games
- **Website**: [ChaffGames.com](https://chaffgames.com)
- **Assets**: Kenny's Blaster Kit
- **License**: MIT (code), Creative Commons (assets)

---

## 🔄 Version History

- **Current**: Godot 4.5 compatible version with AI System
- **Latest Addition**: Git repository initialized with complete project tracking
- **Previous Addition**: Wave management system with resource-based configuration
- **Recent Fix**: Resolved WaveConfig class loading issues and resource preload errors
- **Features**: Complete weapon system, advanced player controller, specialized AI enemies, wave system
- **AI Types**: Rifle soldiers, shotgun rushers, melee brutes
- **Status**: Active development template with AI support, wave management, and version control

### Recent Updates (2025-10-15)

**AI System Critical Bug Fixes:**
- Fixed AI enemies floating to the sky - added proper gravity application
- Fixed AI enemies not shooting - multiple issues resolved:
  - Fixed rifle_ai_weapon.tres UID mismatch (scene expected different UID than resource file)
  - Added auto-find logic for WeaponController and DetectionArea child nodes
  - Fixed _ready() call order in shotgun_rusher and melee_brute (must call super._ready() first)
  - Added null checks for weapon_controller and weapon_resource in all methods
- Fixed all AI types (Rifle Soldier, Shotgun Rusher, Melee Brute) movement bugs
- All AI enemies now properly affected by gravity and move correctly on ground
- Velocity now properly separated into x/z (horizontal) and y (vertical) components

**Pathfinding System:**
- No pathfinding currently implemented - AI uses direct movement toward player
- Simple approach is sufficient for open areas and maintains good performance
- For future implementation with hundreds of enemies:
  - Stagger pathfinding updates across multiple frames
  - Use simplified paths for distant enemies
  - Only use full pathfinding when direct line-of-sight is blocked
  - Consider NavigationAgent3D with async pathfinding for large enemy counts
  - Update paths every 0.5-1.0 seconds instead of every frame

### Recent Updates (2025-10-13)

**Repository Reset (Latest):**
- Performed hard reset to latest GitHub version (commit bac3163)
- All local changes reverted to restore working state
- Cleaned up untracked files and modified files
- Repository now matches remote origin/master exactly
- Commit message: "Weapon Stats added. Some Hit to ai issues fixed. 2 Different hitbox for each bullet be careful"

**Previous Weapon System Fixes:**
- Fixed double shooting issues caused by conflicting timer and animation logic
- Separated manual shooting and auto-fire systems for proper functionality
- Resolved auto-fire problems where weapons wouldn't fire continuously
- Added missing fire_rate property to blasterN weapon (60.0 RPM)
- Improved fire rate timer implementation to prevent shooting conflicts
- Animation and shooting logic are now properly separated as intended

**Previous Updates (2025-10-11)**

**Git Repository Initialized:**
- Initialized git repository in project directory
- Added all 589 project files to version control
- Created initial commit with message "Initial commit: Revenge of the Dead game project"
- Repository includes all game assets, AI system, player controller, and documentation
- Ready for collaborative development and feature branching

**Previous Bug Fixes:**

**Fixed Resource Loading Issues:**
- Corrected `preload()` syntax in .tres resource files to use proper `ExtResource` format
- Fixed WaveConfig class recognition issues in wave configuration resources
- Resolved AI weapon resource loading errors for projectile scenes
- Updated ai_spawner.tscn scene file to use proper resource references

**Files Fixed:**
- `AI_System/resources/wave_1_config.tres`
- `AI_System/resources/wave_2_config.tres` 
- `AI_System/resources/wave_boss_config.tres`
- `AI_System/resources/rifle_ai_weapon.tres`
- `AI_System/resources/shotgun_ai_weapon.tres`
- `AI_System/scenes/ai_spawner.tscn`

---

*This WARP.md file provides a comprehensive overview of the Revenge of the Dead FPS template. For technical implementation details, refer to the individual script files and the official documentation.*