# Talent Tree
For DotA 2 Custom Game developers.

**Library by Kirill Zaharenko, simplified and improved by Roman Avondale(me)**

## Features
* Talent tree with any number of branches and unique talents(and upgrade levels) for each hero.
* Talent is a hidden ability that hero recievs.
* Only one talent can be selected of all branches on same level.
* Points issuing can be customized for your needs.
* 'Reset Talents' button can be disabled.
* Talents can be used for modifying Lua abilities.

![alt text](https://github.com/TheProma/talent_tree/blob/main/Screenshot_2.png?raw=true)

## Instalation
### Drop Files:
* game folder into 'dota 2 beta/game/dota_addons/YOUR_ADDON_NAME' directory
* content folder into 'dota 2 beta/content/dota_addons/YOUR_ADDON_NAME' directory

### addon_game_mode.lua:
```Lua
require("talent_tree")
```

### npc/npc_abilities_custom.txt:
```KV
#base "npc_hero_talents.txt"
```

### resource/addon_english.txt:
```KV
"talent_tree_column_0_title"            "Required Level"
"talent_tree_column_1_title"            "Magical Damage"
"talent_tree_column_2_title"            "Physical Damage"
"talent_tree_current_talent_points"     "Current Points: %POINTS%"
"talent_tree_reset_talents"             "Reset Talents"
```

### panorama/layout/custom_game/custom_ui_manifest.xml:
```xml
<CustomUIElement type="Hud" layoutfile="file://{resources}/layout/custom_game/talent_tree/window.xml" />
```

## Customization/Usage
### Points issuing and hero talents:
'scripts/kv/hero_talents.txt', examples are there.

### Talents abilities:
'scripts/npc/npc_hero_talents'

### Button:
* Button placement can be changed in 'panorama/layout/custom_game/talent_tree/talent_tree.css', class #TalentTreeWindowButton
* Images stored in 'panorama/images/custom_game/ui/talents/icons' directory

### Talent Reset Button:
'panorama/layout/custom_game/talent_tree/talent_tree.js'
```javascript
var DISABLE_RESET_TALENTS_BTN = false
```
