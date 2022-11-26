/* This mod is developed as a standalone mod for Half-Life
This plugin wants to replicate as good as possible the real mod
Official link for the mod: https://www.moddb.com/mods/cold-ice-remastered

All credit for the ideas go the the authors

 Cvar settings for effects 
		weapons_spin_on_off "1"
		weapons_spin_speed "150.0"
		weapons_effects_on_off "1"
		weapons_effects_mode "4"

		//mode 1: Hologram.
		//mode 2: Explode models will be big.
		//mode 3: Glow Shell random rgb colors.
		//mode 4: Glow Shell manual color with "weapons_glows_color" cvar.
		//mode 5: Glow Shell transparent
	
		weapons_glows_color "0 255 255" // ice blue
		weapons_glows_thickness "128"

*/


#include <amxmodx>
#include <engine>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>

#define PLUGIN	"Cold Ice Remastered"
#define VERSION	"1.0"
#define AUTHOR	"teylo"

#define MAX_SOUNDS	50
#define MAX_p_MODELS	50
#define MAX_v_MODELS	50
#define MAX_w_MODELS	50

#define MAP_CONFIGS	1

new new_sounds[MAX_SOUNDS][48]
new old_sounds[MAX_SOUNDS][48]
new sounds_team[MAX_SOUNDS]
new soundsnum

new new_p_models[MAX_p_MODELS][48]
new old_p_models[MAX_p_MODELS][48]
new p_models_team[MAX_p_MODELS]
new p_modelsnum

new new_v_models[MAX_v_MODELS][48]
new old_v_models[MAX_v_MODELS][48]
new v_models_team[MAX_p_MODELS]
new v_modelsnum

new new_w_models[MAX_w_MODELS][48]
new old_w_models[MAX_w_MODELS][48]
new w_models_team[MAX_p_MODELS]
new w_modelsnum


// Entities for floating, spinning and glow effect
// Also used for replacing models
new const HalfLifeWeaponsEntities[][] = 
{
"ammo_357", "ammo_9mmAR", "ammo_9mmbox", "ammo_9mmclip", "ammo_ARgrenades",
"ammo_buckshot", "ammo_crossbow", "ammo_egonclip", "ammo_gaussclip", "ammo_glockclip",
"ammo_mp5clip", "ammo_mp5grenades", "ammo_rpgclip", "weaponbox", "weapon_357", 
"weapon_9mmAR", "weapon_9mmhandgun", "weapon_crossbow", "weapon_egon", "weapon_gauss",
"weapon_glock", "weapon_handgrenade", "weapon_hornetgun", "weapon_mp5", "weapon_python",
"weapon_rpg", "weapon_satchel", "weapon_shotgun", "weapon_snark", "weapon_tripmine"
}

new const hldmitems[][] = 
{ 
"item_battery", 
"item_healthkit", 
"item_longjump",
"item_suit" 
}

//cvars for w_ weapons effects and items
new
weapons_spin_on_off,
weapons_spin_speed,
weapons_effects_on_off,
weapons_effects_mode,
weapons_glows_color,
weapons_glows_thickness


public plugin_init()
{
	register_plugin(
		PLUGIN,		//: Cold Ice Remastered Mod
		VERSION,	//: 1.0
		AUTHOR		//: teylo
	);

	// Sound and model change area
	register_forward(FM_EmitSound,"Sound_Hook")
	register_event("CurWeapon","Changeweapon_Hook","be","1=1")


	// Weapon effects
	for(new i = 0; i < sizeof(HalfLifeWeaponsEntities); i++)
	{
		register_touch(HalfLifeWeaponsEntities[i],"worldspawn","WeaponsTouchTheGround")
	}
	// Item effects
	set_task(0.25,"Item_Task")

	weapons_spin_on_off = register_cvar("weapons_spin_on_off","1")
	weapons_spin_speed = register_cvar("weapons_spin_speed","150.0")
	weapons_effects_on_off = register_cvar("weapons_effects_on_off","1")
	weapons_effects_mode = register_cvar("weapons_effects_mode","4")
	weapons_glows_color = register_cvar("weapons_glows_color","0 255 255")
	weapons_glows_thickness = register_cvar("weapons_glows_thickness","128")

}

public plugin_precache()
{
	// precaching cold ice remastered weapons

	new configfile[200]
	new configsdir[200]
	new map[32]
	get_configsdir(configsdir,199)
	get_mapname(map,31)
	format(configfile,199,"%s/cir_weapons_%s.ini",configsdir,map)
	if(file_exists(configfile))
	{
		Load_models(configfile)
	}
	else
	{
		format(configfile,199,"%s/cir_weapons.ini",configsdir)
		Load_models(configfile)
	}
}

// Check the file content 
// Format : "old model" "new model" "team to apply"  - team in mandatory
public Load_models(configfile[])
{
	if(file_exists(configfile))
	{
		new read[96], left[48], right[48], right2[32], trash, team
		for(new i=0;i<file_size(configfile,1);i++)
		{
			read_file(configfile,i,read,95,trash)
			if(containi(read,";")!=0 && containi(read," ")!=-1)
			{
				argbreak(read,left,47,right,47)
				team=0
				if(containi(right," ")!=-1)
				{
					argbreak(right,right,47,right2,31)
					replace_all(right2,31,"^"","")
					if(
					equali(right2,"T") ||
					equali(right2,"Terrorist") ||
					equali(right2,"Terrorists") ||
					equali(right2,"Blue") ||
					equali(right2,"B") ||
					equali(right2,"Allies") ||
					equali(right2,"1")
					) team=1
					else if(
					equali(right2,"CT") ||
					equali(right2,"Counter") ||
					equali(right2,"Counter-Terrorist") ||
					equali(right2,"Counter-Terrorists") ||
					equali(right2,"CounterTerrorists") ||
					equali(right2,"CounterTerrorist") ||
					equali(right2,"Red") ||
					equali(right2,"R") ||
					equali(right2,"Axis") ||
					equali(right2,"2")
					) team=2
					else if(
					equali(right2,"Yellow") ||
					equali(right2,"Y") ||
					equali(right2,"3")
					) team=3
					else if(
					equali(right2,"Green") ||
					equali(right2,"G") ||
					equali(right2,"4")
					) team=4
				}
				replace_all(right,47,"^"","")
				if(file_exists(right))
				{
					if(containi(right,".mdl")==strlen(right)-4)
					{
						if(!precache_model(right))
						{
							log_amx("Error attempting to precache model: ^"%s^" (Line %d of cir_weapons.ini)",right,i+1)
						}
						else if(containi(left,"models/p_")==0)
						{
							format(new_p_models[p_modelsnum],47,right)
							format(old_p_models[p_modelsnum],47,left)
							p_models_team[p_modelsnum]=team
							p_modelsnum++
						}
						else if(containi(left,"models/v_")==0)
						{
							format(new_v_models[v_modelsnum],47,right)
							format(old_v_models[v_modelsnum],47,left)
							v_models_team[v_modelsnum]=team
							v_modelsnum++
						}
						else if(containi(left,"models/w_")==0)
						{
							format(new_w_models[w_modelsnum],47,right)
							format(old_w_models[w_modelsnum],47,left)
							w_models_team[w_modelsnum]=team
							w_modelsnum++
						}
						else
						{
							log_amx("Model type(p_ / v_ / w_) unknown for model: ^"%s^" (Line %d of cir_weapons.ini)",right,i+1)
						}
					}
					else if(containi(right,".wav")==strlen(right)-4 || containi(right,".mp3")==strlen(right)-4)
					{
						replace(right,47,"sound/","")
						replace(left,47,"sound/","")
						if(!precache_sound(right))
						{
							log_amx("Error attempting to precache sound: ^"%s^" (Line %d of cir_weapons.ini)",right,i+1)
						}
						else
						{
							format(new_sounds[soundsnum],47,right)
							format(old_sounds[soundsnum],47,left)
							sounds_team[soundsnum]=team
							soundsnum++
						}
					}
					else
					{
						log_amx("Invalid File: ^"%s^" (Line %d of cir_weapons.ini)",right,i+1)
					}
				}
				else
				{
					log_amx("File Inexistent: ^"%s^" (Line %d of cir_weapons.ini)",right,i+1)
				}
			}
		}
	}
}

// change the player model (v_ and p_ )when he changes his weapon
public Changeweapon_Hook(id)
{
	if(!is_user_alive(id))
	{
		return PLUGIN_CONTINUE
	}
	static model[32], i, team

	team = get_user_team(id)

	pev(id,pev_viewmodel2,model,31)
	for(i=0;i<v_modelsnum;i++)
	{
		if(equali(model,old_v_models[i]))
		{
			if(v_models_team[i]==team || !v_models_team[i])
			{
				set_pev(id, pev_body, 2)
				set_pev(id,pev_viewmodel2,new_v_models[i])
				break;
			}
		}
	}

	pev(id,pev_weaponmodel2,model,31)
	for(i=0;i<p_modelsnum;i++)
	{
		if(equali(model,old_p_models[i]))
		{
			if(p_models_team[i]==team || !p_models_team[i])
			{
				set_pev(id,pev_weaponmodel2,new_p_models[i])
				break;
			}
		}
	}
	return PLUGIN_CONTINUE
}

// Change the sound emited
public Sound_Hook(id,channel,sample[])
{
	if(!is_user_alive(id))
	{
		return FMRES_IGNORED
	}
	if(channel!=CHAN_WEAPON && channel!=CHAN_ITEM)
	{
		return FMRES_IGNORED
	}

	static i, team

	team = get_user_team(id)

	for(i=0;i<soundsnum;i++)
	{
		if(equali(sample,old_sounds[i]))
		{
			if(sounds_team[i]==team || !sounds_team[i])
			{
				engfunc(EngFunc_EmitSound,id,CHAN_WEAPON,new_sounds[i],1.0,ATTN_NORM,0,PITCH_NORM)
				return FMRES_SUPERCEDE
			}
		}
	}
	return FMRES_IGNORED
}

// Task to add efects to items and change their model
public Item_Task(ent)
{
	for(new i = 0; i < sizeof(hldmitems); i++)
		while((ent = find_ent_by_class(ent,hldmitems[i])) > 0)
		{
			W_Model_Hook(ent)
			WeaponsSpinAndEffects(ent)
		}
	return PLUGIN_CONTINUE
}

// Function to hook weapons when touching the ground
// Change model
public WeaponsTouchTheGround(ent) 
{
  if (is_valid_ent(ent)) {
	W_Model_Hook(ent)
	WeaponsSpinAndEffects(ent)
  }
  return PLUGIN_CONTINUE
}

public W_Model_Hook(ent)
{
	new models[55]
	pev(ent, pev_model, models, charsmax(models))  

	if(!pev_valid(ent))
	{
		return PLUGIN_HANDLED
	}
	static i
	for(i=0;i<w_modelsnum;i++)
	{
		if(equali(models,old_w_models[i]))
		{
			engfunc(EngFunc_SetModel,ent,new_w_models[i])
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_HANDLED
}

// Add effects 
public WeaponsSpinAndEffects(ent) 
{
  new Float: WeaponOrigin[3]

  entity_get_vector(ent, EV_VEC_origin, WeaponOrigin)

  WeaponOrigin[2] += 30.0

  entity_set_origin(ent, WeaponOrigin)

  entity_set_int(ent, EV_INT_movetype, MOVETYPE_NOCLIP)

  set_task(0.25, "WeaponSpinGoGo", ent)

  static red, green, blue,
  r, g, b, thickness

  r = random(255)
  g = random(0)
  b = random(0)

  Get_glow_color(red, green, blue)

  thickness = get_pcvar_num(weapons_glows_thickness)

  if (get_pcvar_num(weapons_effects_on_off)) {
	switch (get_pcvar_num(weapons_effects_mode)) {
	case 1: {
	  fm_set_rendering(ent, kRenderFxHologram, 0, 0, 0, kRenderTransAdd)
	}
	case 2: {
	  fm_set_rendering(ent, kRenderFxExplode, 0, 0, 0, kRenderNormal)
	}
	case 3: {
	  fm_set_rendering(ent, kRenderFxGlowShell, r, g, b, kRenderNormal, thickness)
	}
	case 4: {
	  fm_set_rendering(ent, kRenderFxGlowShell, red, green, blue, kRenderNormal, thickness)
	}
	case 5: {
	  fm_set_rendering(ent, kRenderFxGlowShell, red, green, green, kRenderTransColor, 1)
	}
	}
  }
  return PLUGIN_CONTINUE
}

public Get_glow_color(&r, &g, &b) 
{
	static color[20], red[5], green[5], blue[5]
	get_pcvar_string(weapons_glows_color,color,charsmax(color))
	parse(color,red,charsmax(red),green,charsmax(green),blue,charsmax(blue))
	r = str_to_num(red)
	g = str_to_num(green)
	b = str_to_num(blue)
	return PLUGIN_CONTINUE
}

public WeaponSpinGoGo(ent)
{
	if(get_pcvar_num(weapons_spin_on_off) && is_valid_ent(ent))
	{
		new Float:Avelocity[3]

		// spinning only on z axis
		Avelocity[0] = 0.0 //get_pcvar_float(weapons_spin_speed)
		Avelocity[1] = get_pcvar_float(weapons_spin_speed)
		Avelocity[2] = 0.0 //get_pcvar_float(weapons_spin_speed)

		entity_set_vector(ent,EV_VEC_avelocity,Avelocity)
	}
	return PLUGIN_CONTINUE
}

