## Gemini Added Memories
- This is a Godot 4.5 FPS base defense game called "Revenge of the Dead".

Key project structure and systems:
- Player: The core player controller is in 'Player_Controller/scripts/Player_Character/player_character.gd'. It handles movement, health, and abilities like crouching and leaning.
- Weapons: A sophisticated weapon state machine is managed by 'Player_Controller/scripts/Weapon_State_Machine/Weapon_State_Machine.gd'. Weapon stats and behaviors are defined using 'WeaponResource' .tres files, making the system highly modular.
- AI: The AI system is in the 'AI_System/' directory and is optimized for performance. It includes a wave manager ('wave_manager.gd') and spawner ('ai_spawner.gd'). Different AI types (rifle, shotgun, melee) are present with simplified weapon controllers.
- Damage: A centralized 'damage_system.gd' script manages all damage calculations, including damage types, source tracking (player vs. AI), friendly fire rules, armor, and critical hits.
- Main Scene: The main game world is 'Example World/Objects/World/world.tscn'.
