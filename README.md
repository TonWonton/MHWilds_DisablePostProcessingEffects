## Description
A REFramework script that lets you disable different filters and post processing effects that make the game blurry/unclear and washed out

This script lets you disable/enable all the options included in the script through the REFramework UI under the "Script Generated UI", which lets you customize the visuals of the game to your liking. It also allows you to save your configuration by clicking "Save settings" at the bottom, and will load those settings automatically after that.

By default, the script disables lens distortion and blurred luminance, which disables two of the filters that contribute the most to making the game look blurry and washed out.

This script also lets you disable the color correction which makes the game more vibrant and improves dynamic range and contrast (disabling color correction will make the game significantly darker. Turn on local exposure or increase the brightness from the script if you want to disable color correction.


## Features
- Customize and save settings through REFramework UI
- Lets you enable/disable all of the options included in the script
- Disable TAA and TAA jitter
- Disable color correction
- Disable lens distortion
- Disable local exposure
﻿- Disable the sharpening filter tied to local exposure
- Set custom contrast
- Set custom brightness for game and UI separately
- Toggle volumetric fog


## Prerequisites
- REFramework [Nexus](https://www.nexusmods.com/monsterhunterwilds/mods/93) | [GitHub](https://github.com/praydog/REFramework)


## Installation
- Install REFramework
- Download the script [Nexus](https://www.nexusmods.com/monsterhunterwilds/mods/221) | [GitHub](https://github.com/TonWonton/MHWilds_DisablePostProcessingEffects/releases) and extract the reframework folder into the game folder(where MonsterHunterWilds.exe is located)
﻿- mhwilds_disable_postprocessing.lua and utility folder should be placed into \(game folder)\reframework\autorun\

### Uninstall
- Open the game folder and go into: \(game folder)\reframework\autorun\
- Then delete "mhwilds_disable_postprocessing.lua"

### Reset settings
- Open the game folder and go into: \(game folder)\reframework\data\
- Then delete "mhwi_remove_postprocessing.json"


## Notes
- Disabling color correction will make the game significantly darker
﻿- If it is too dark you can try enabling local exposure
﻿- Or enable custom gamma & contrast, then increase brightness and/or gamma
﻿﻿- For HDR: increase the brightness from the in game options menu instead

- Some of the settings seem to have no effect (fog, film grain, lens flare, godray)


## Known issues
- Flickering might occur if you have frame gen (maybe only DLSS FG) and local exposure ON + blurred luminance OFF when doing specific actions (entering tent, cooking, fast traveling, talking to some NPCs)
- Disabling lens distortion might make the UI misaligned. More noticable on ultrawide monitors. Try to use the REFramework UI > graphics, and change the ultrawide options there


## Changelog
### v1.3.3
- Made function GenerateEnum() local in order to avoid potential issues

### v1.3.2
- Possible fix for mod not working for some after latest update/no file error
    - Code from utility/Statics.lua moved into main file. Utility folder and Statics.lua no longer included or required

### v1.3.1
- Improved load settings buttons to prevent overriding game brightness if SDR custom gamma & brightness hasn't been enabled yet

### v1.3.0
- Added buttons for loading settings
    - Saved settings
    - Script defaults
    - Game defaults
- Settings will now auto save at the same time as REFramework (when closing REF window etc.)
- Changed UI

### v1.2.1
- Changed TAA strength to the game default "Manual" instead of "Strong" if you have TAA enabled in the script
- Added global mod header for better compatibility with Lite Environment and future mods

### v1.2.0
- Added options for SDR brightness
    - Gamma
    - Max and min brightness
    - UI gamma
    - UI max and min brightness
- Removed HDR brightness options due to problems (use in game brightness options instead for now)
- Changed script UI
- Changed defaults to local exposure ON + blurred luminance OFF, since black flicker bug cause is known

### v1.1.3
- Fixed brightness issue during specific frenzy phase and apex monster's super attack if color correct was disabled
- Fixed lua error on startup
- Fixed ultrawide fix not working
- Fixed settings not applying for some

### v1.1.2
- Fixed bright screen that happend during a specific frenzy phase and apex monster's super attack if you had color correction disabled

### v1.1.1
- Changed local exposure to be disabled by default and blurred luminance to be on by default, due to possible potential flickering problem with local exposure ON + blurred luminance OFF during specific actions (entering tent, cooking, talking to some NPCs, fast traveling, some menus, etc.)
﻿- The problem doesn't seem to affect everyone, so you can still use local exposure ON + blurred luminance OFF
﻿but keep in mind that it might cause this issue
﻿- Blurred luminance is a sharpening filter that is tied to local exposure, which means it will have no effect if local exposure is disabled

### v1.1.0
- Previously bundled settings can now be toggled separately (color correction, lens distortion, local exposure)
- Added option to disable sharpness/blur from local exposure
- Distortion effects (monster roars, attacks, weapon attacks, blocking, etc.) will work with all the settings
- Added apply button for graphics settings
- Lens distortion is now turned off by default

### V1.0.3
- Fixed contrast slider not working

### V1.0.2
- Update due to a bug in the game
- Bug sets ambient lighting to high if graphic settings are changed in game or from a script
- Some settings will now apply instantly
- Some settings will now apply when returning to title screen due to bug

### V1.0.1
- Changed lens distortion to be on by default

### V1.0.0
- Custom settings set through the REFramework UI under the Script Generated tab can now be saved. The saved settings will be placed into \reframework\data\
- Lens distortion and film grain can now be toggled off separately from "Color correct + various filters". It is still required to have color correct + various filters enabled for lens distortion and film grain to have an effect
- Added option to disable (but it seems like only lens distortion and volumetric fog has an effect in game):
﻿- Lens distortion
﻿- Fog
﻿- Volumetric fog
﻿- Film grain
﻿- Lens flare
﻿- Godray
