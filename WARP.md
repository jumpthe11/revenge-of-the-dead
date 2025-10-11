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

**Key Parameters**:
- Sprint speed: 2.0x normal
- Walk speed: 0.5x normal
- Jump height: 2.0 units
- Lean speed: 0.2 seconds

### Weapon State Machine
**Location**: `Player_Controller/scripts/Weapon_State_Machine/Weapon_State_Machine.gd`

**Architecture**:
- **Resource-Based**: All weapons defined via `WeaponResource` files
- **Component System**: Modular projectiles, spray patterns, and behaviors
- **State Management**: Handles weapon switching, shooting, reloading
- **Animation Integration**: Seamless animation system integration

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
- auto_fire: bool (full-auto capability)

# Weapon Behavior
- can_be_dropped: bool
- weapon_spray: PackedScene (spread pattern)
- projectile_to_load: PackedScene (bullet type)
- incremental_reload: bool (shotgun-style reload)
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

### Recent Updates (2025-10-11)

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