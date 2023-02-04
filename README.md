![CIR ModX](https://repository-images.githubusercontent.com/570977077/56b8eeb1-df75-44a5-bf1c-be09cd41ba47)
# Cold Ice Remastered-ModX

This project is a modern open-sourced rebuild of Cold Ice 1.75, a popular Half-Life mod back in 1999. Set in a winter scene, its philosophy is to deliver deathmatch that doesn't take itself seriously. Only in this mod will you find voiceover cameos from Samuel L. Jackson, Hans Gruber, and "Leeroy Jenkins" by Ben Schulz. Its ethos delivers an explosively frantic fast-paced gameplay that was and always will be Cold Ice.

This mod is developed as a standalone mod for Half-Life
This plugin wants to replicate as good as possible the real mod.

All credit for the ideas go the the authors


## Author of the plugin

- [@teylo](https://github.com/andreiseverin)

## Author of the rebuild mod 
- [@surreal](https://github.com/solidi)



## Installation

Copy all the files in your valve folder. Then go to `valve\addons\amxmodx\configs\plugins.ini` and add a new line with : 

```bash
  cir.amxx
```
In the `cir_maps.ini` file you need to add all the maps where do you want the plugin to work.
In the `cir_weapon.ini` file you cann use your own custom models by following the model:

```bash
  "models/old_model.mdl" "models/new_model.mdl"
```
Pay attention: only the models starting with `p_ v_ and w_` work.

You can set up the following cvars in the `server.cfg` file :

```bash

// ===== cvars for the effect =======

weapons_spin_on_off "1" 
weapons_spin_speed "150.0" 
weapons_effects_on_off "1" 
weapons_glows_thickness "128"

//mode 1: Hologram. 
//mode 2: Explode models will be big. 
//mode 3: Glow Shell random rgb colors. 
//mode 4: Glow Shell manual color with "weapons_glows_color" cvar. 
//mode 5: Glow Shell transparent 
weapons_effects_mode "4"

// ===== cvars crowbar power ======= cir_crowbar_speed 1300 cir_crowbar_trail 1 cir_crowbar_damage 240.0 freeze_duration 2.0

// ===== cvars crowbar power =======
cir_crowbar_speed 1300
cir_crowbar_trail 1
cir_crowbar_damage 240.0
freeze_duration 2.0

// ===== cvars weapons ======= (1-on 0-off)
sv_cir_crowbar 1
sv_cir_9mmhandgun 1
sv_cir_gauss 1
sv_cir_egon 1
sv_cir_crossbow 1
sv_cir_rpg 1
sv_cir_satchel 1
sv_cir_hornetgun 1
sv_cir_357 1
sv_cir_shotgun 1
sv_cir_9mmAR 1
sv_cir_handgrenade 1
sv_cir_snark 1
sv_cir_tripmine 1

// ===== cvars ammo ======= (add ammo value)
sv_cir_ammo_crossbow 250
sv_cir_ammo_buckshot 200
sv_cir_ammo_gaussclip 9999
sv_cir_ammo_rpgclip 50
sv_cir_ammo_9mmAR 250
sv_cir_ammo_ARgrenades 20
sv_cir_ammo_357 250
sv_cir_ammo_glock 250
sv_cir_ammo_satchel 10
sv_cir_ammo_tripmine 5
sv_cir_ammo_hgrenade 20
sv_cir_ammo_snark 15
sv_cir_ammo_hornetgun 100

// ====== cvars start ammo ===== (add weapon ammo value)
sv_cir_start_ammo_crossbow 50
sv_cir_start_ammo_buckshot 100
sv_cir_start_ammo_rpgclip 5
sv_cir_start_ammo_9mmAR 100
sv_cir_start_ammo_357 50
sv_cir_start_ammo_glock 100

// ===== cvars items ======= (add armour and health start value)
sv_cir_health 100
sv_cir_armour 0
sv_cir_longjump 1 // (1-on 0-off)

// ===== cvar activate wings (1-on 0-off)==========
sv_cir_wings 1 

// ====== cvar lighting (from a -darkest to z - brightest ==================
sv_cir_light h
```

## Thanks to:

- Surreal for developping the rebuild mod
- Napoleon for constant helping and ideas
- Cold Ice Remastered community for constant support and ideas
- All the map creators from the original mod
- GameBanana for "the" archive of models, effects, and everything https://gamebanana.com/
- AlliedModder community for all the documentation,plugins and debugging tips https://forums.alliedmods.net/
- Chat GPT for some algorithms ideas and code explanation



