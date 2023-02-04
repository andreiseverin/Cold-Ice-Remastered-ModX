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
#include <fun>
#include <hlstocks>



#define PLUGIN	"Cold Ice Remastered"
#define VERSION	"1.0"
#define AUTHOR	"teylo"

#define MAX_SOUNDS	50
#define MAX_p_MODELS	50
#define MAX_v_MODELS	50
#define MAX_w_MODELS	50

#define MAP_CONFIGS	1


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

//cvars for w_ weapons effects and items
new
weapons_spin_on_off,
weapons_spin_speed,
weapons_effects_on_off,
weapons_effects_mode,
weapons_glows_color,
weapons_glows_thickness


// Flying crowbar settings and freeze power variables
#define CROW "fly_crowbar"	
#define message_begin_fl(%1,%2,%3,%4) engfunc(EngFunc_MessageBegin, %1, %2, %3, %4)
#define write_coord_fl(%1) engfunc(EngFunc_WriteCoord, %1)
#define FROST_RADIUS		240.0
#define TASK_REMOVE_FREEZE	200
#define BREAK_GLASS		0x01

new const MODELPOWER[ ]     = "sprites/hl_xmas/power2.spr";
new const SPRITE_SMOKE[]	= "sprites/hl_xmas/ice_explode2.spr";
new const SOUND_EXPLODE[]	= "hl_xmas/x_shoot1.wav";
new const MODEL_FROZEN[]	= "models/hl_xmas/dd_iceblock.mdl";
new const MODEL_GLASSGIBS[]	= "models/glassgibs.mdl";
new const SOUND_FROZEN[]	= "hl_xmas/glass1.wav";
new const SOUND_UNFROZEN[]	= "hl_xmas/glass3.wav";
new const SPRITE_EXPLO[]	= "sprites/shockwave.spr";
new const W_GRENADE[ ]      = "models/grenade.mdl" 
new const W_NEW_GRENADE[ ]  = "models/cir/grenade.mdl" 
new damage_crowbar,crowbar_speed,crowbar_trail;
new glassGibs, smokeSpr, exploSpr, powerSpr;
new isFrozen[33], novaDisplay[33];
new freeze_duration;
new blood_drop;
new blood_spray;
new trail;

// General variables
new g_maxplayers;
new const m_flNextSecondaryAttack = 36;
const m_iClip = 40;
new const XTRA_OFS_WEAPON = 4;
new Float:old_clip[33];
new const m_pPlayer = 28;
#define IsPlayer(%1) (1 <= %1 <= g_maxplayers)
#define refill_weapon(%1,%2) set_pdata_int(%1, m_iClip, %2, XTRA_OFS_WEAPON)
#define GAME_DESCRIPTION "Cold Ice Remastered"


// ===== Cvars defines   =======
new cvar_Wcrowbar;
new cvar_W9mmhandgun;
new cvar_Wgauss;
new cvar_Wegon;
new cvar_Wcrossbow;
new cvar_Wrpg;
new cvar_Wsatchel;
new cvar_Whornetgun;
new cvar_W357;
new cvar_Wshotgun;
new cvar_W9mmAR;
new cvar_Whandgrenade;
new cvar_Wsnark;
new cvar_Wtripmine;
new cvar_ammo_crossbow;
new cvar_ammo_buckshot;
new cvar_ammo_gaussclip;
new cvar_ammo_rpgclip;
new cvar_ammo_9mmAR;
new cvar_ammo_ARgrenades;
new cvar_ammo_357;
new cvar_ammo_glock;
new cvar_ammo_satchel;
new cvar_ammo_tripmine;
new cvar_ammo_hgrenade;
new cvar_ammo_snark;
new cvar_ammo_hornetgun;
new cvar_start_ammo_crossbow;
new cvar_start_ammo_buckshot;
new cvar_start_ammo_rpgclip;
new cvar_start_ammo_9mmAR;
new cvar_start_ammo_357;
new cvar_start_ammo_glock;
new cvar_ihealth;
new cvar_iarmour;
new cvar_ilongjump;
new cvar_wings;

// =========== WEAPON OFFSET CLASS ============ //
static const _HLW_to_rgAmmoIdx[] =
{
	0, 	// bos
	0,	// crowbar
	2, 	// 9mmhandgun
	4, 	// 357
	2, 	// 9mmAR
	3, 	// m203
	7, 	// crossbow
	1, 	// shotgun
	6, 	// rpg
	5, 	// gauss
	5, 	// egon
	12,	// hornetgun
	10, 	// handgrenade
	8, 	// tripmine
	9, 	// satchel
	11  	// snark
};

// parachute entity
new para_ent[33];

// light cvar
new gCvarLight;


// ===== variables ini file ====
#define MAX_WORDS 250
new g_mapData[MAX_WORDS][25];
new g_mapNum;


public plugin_init()
{
	register_plugin( 
		PLUGIN,		//: Cold Ice Remastered Mod
		VERSION,	//: 1.0
		AUTHOR		//: teylo
	);

	mapFile();
	register_forward(FM_GetGameDescription	, "fwd_GetGameDescription");

	// Spawn forward
	RegisterHam(Ham_Spawn, "player", "CBasePlayer_Spawn", 1);

	// Sound and model change area
	register_forward(FM_EmitSound,"Sound_Hook")
	register_event("CurWeapon","Changeweapon_Hook","be","1=1")

	// Weapon effects
	for(new i = 0; i < sizeof(HalfLifeWeaponsEntities); i++)
	{
		register_touch(HalfLifeWeaponsEntities[i],"worldspawn","WeaponsTouchTheGround")
	}


	// Flying crowbar area
	g_maxplayers = get_maxplayers();
	
	register_message(get_user_msgid("DeathMsg"),"DeathMsg");
	
	// Weapon shooting speed
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_rpg", "rpg_primary_attack_pre", 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_rpg", "rpg_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_shotgun", "shotgun_primary_attack_pre" , 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_shotgun", "shotgun_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_shotgun", "shotgun_secondary_attack_pre" , 0)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_shotgun", "shotgun_secondary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_snark", "snark_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_9mmAR", "grenades_secondary_attack_post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack,"weapon_crowbar","fw_CrowbarSecondaryAttack");
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmAR", "mp5_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmhandgun", "glock_primary_attack_pre" , 0)
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_9mmhandgun", "glock_primary_attack_post", 1)
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_9mmhandgun", "glock_secondary_attack")

	// Set ammo on weapon touch
	RegisterHam(Ham_Touch, "weapon_crossbow", "touch_crossbow", 1);
	RegisterHam(Ham_Touch, "weapon_shotgun", "touch_shotgun", 1);
	RegisterHam(Ham_Touch, "weapon_gauss", "touch_gauss", 1);
	RegisterHam(Ham_Touch, "weapon_rpg", "touch_rpg", 1);
	RegisterHam(Ham_Touch, "weapon_9mmAR", "touch_9mmAR", 1);
	RegisterHam(Ham_Touch, "weapon_handgrenade", "touch_handgrenade", 1);
	RegisterHam(Ham_Touch, "weapon_357", "touch_357", 1);
	RegisterHam(Ham_Touch, "weapon_9mmhandgun", "touch_9mmhandgun", 1);
	RegisterHam(Ham_Touch, "weapon_satchel", "touch_satchel", 1);
	RegisterHam(Ham_Touch, "weapon_tripmine", "touch_tripmine", 1);
	RegisterHam(Ham_Touch, "weapon_egon", "touch_egon", 1);
	RegisterHam(Ham_Touch, "weapon_hornetgun", "touch_hgun", 1);
	RegisterHam(Ham_Touch, "weapon_snark", "touch_snark", 1);
	RegisterHam(Ham_Touch, "ammo_ARgrenades", "touch_ARgrenades", 1);

	// Flying crowbar power setting
	register_think(CROW,"FlyCrowbar_Think");
	register_touch(CROW,"*","FlyCrowbar_Touch");
	RegisterHam(Ham_Item_AddToPlayer,"weapon_crowbar","fw_CrowbarItemAdd");
	RegisterHam(Ham_Item_AddDuplicate,"weapon_crowbar","fw_CrowbarItemAdd");
	

	///////////////////////////////////////////////////////////////////////////////
	// CVARS
	///////////////////////////////////////////////////////////////////////////////

	// ===== cvars crowbar power =======
	crowbar_speed 		 = register_cvar("cir_crowbar_speed","1300");
	crowbar_trail 		 = register_cvar("cir_crowbar_trail","1");
	damage_crowbar 		 = register_cvar("cir_crowbar_damage","240.0");
	freeze_duration 	 = register_cvar("freeze_duration","2.0");

	// ===== cvars weapons ======= (1-on 0-off)
	cvar_Wcrowbar        = create_cvar("sv_cir_crowbar", "1");
	cvar_W9mmhandgun     = create_cvar("sv_cir_9mmhandgun", "1");
	cvar_Wgauss          = create_cvar("sv_cir_gauss", "1");
	cvar_Wegon           = create_cvar("sv_cir_egon", "1");
	cvar_Wcrossbow       = create_cvar("sv_cir_crossbow", "1");
	cvar_Wrpg            = create_cvar("sv_cir_rpg", "1");
	cvar_Wsatchel        = create_cvar("sv_cir_satchel", "1");
	cvar_Whornetgun      = create_cvar("sv_cir_hornetgun", "1");
	cvar_W357            = create_cvar("sv_cir_357", "1");
	cvar_Wshotgun        = create_cvar("sv_cir_shotgun", "1");
	cvar_W9mmAR          = create_cvar("sv_cir_9mmAR", "1");
	cvar_Whandgrenade    = create_cvar("sv_cir_handgrenade", "1");
	cvar_Wsnark          = create_cvar("sv_cir_snark", "1");
	cvar_Wtripmine       = create_cvar("sv_cir_tripmine", "1");
	
	// ===== cvars ammo ======= (add ammo value)
	cvar_ammo_crossbow   = create_cvar("sv_cir_ammo_crossbow", "250");
	cvar_ammo_buckshot   = create_cvar("sv_cir_ammo_buckshot", "200");
	cvar_ammo_gaussclip  = create_cvar("sv_cir_ammo_gaussclip", "9999");
	cvar_ammo_rpgclip    = create_cvar("sv_cir_ammo_rpgclip", "50");
	cvar_ammo_9mmAR      = create_cvar("sv_cir_ammo_9mmAR", "250");
	cvar_ammo_ARgrenades = create_cvar("sv_cir_ammo_ARgrenades", "20");
	cvar_ammo_357        = create_cvar("sv_cir_ammo_357", "250");
	cvar_ammo_glock      = create_cvar("sv_cir_ammo_glock", "250");	
	cvar_ammo_satchel    = create_cvar("sv_cir_ammo_satchel", "10");
	cvar_ammo_tripmine   = create_cvar("sv_cir_ammo_tripmine", "5");
	cvar_ammo_hgrenade   = create_cvar("sv_cir_ammo_hgrenade", "20");
	cvar_ammo_snark      = create_cvar("sv_cir_ammo_snark", "15");	
	cvar_ammo_hornetgun  = create_cvar("sv_cir_ammo_hornetgun", "100");	

	// ====== cvars start ammo ===== (add weapon ammo value)
	cvar_start_ammo_crossbow   = create_cvar("sv_cir_start_ammo_crossbow", "50");
	cvar_start_ammo_buckshot   = create_cvar("sv_cir_start_ammo_buckshot", "100");
	cvar_start_ammo_rpgclip    = create_cvar("sv_cir_start_ammo_rpgclip", "5");
	cvar_start_ammo_9mmAR      = create_cvar("sv_cir_start_ammo_9mmAR", "100");
	cvar_start_ammo_357        = create_cvar("sv_cir_start_ammo_357", "50");
	cvar_start_ammo_glock      = create_cvar("sv_cir_start_ammo_glock", "100");
				
	// ===== cvars items ======= (add armour and health start value)
	cvar_ihealth               = create_cvar("sv_cir_health", "100");
	cvar_iarmour               = create_cvar("sv_cir_armour", "0");
	cvar_ilongjump             = create_cvar("sv_cir_longjump", "1"); // (1-on 0-off)

	// ===== cvar activate wings ==========
	cvar_wings       	       = create_cvar("sv_cir_wings", "1"); // (1-on 0-off)	

	// ====== cvar lighting ==================
	gCvarLight 				   = create_cvar("sv_cir_light", "h");

	// ====== Item effects ==================
	set_task(0.25,"Item_Task")

	weapons_spin_on_off = register_cvar("weapons_spin_on_off","1")
	weapons_spin_speed = register_cvar("weapons_spin_speed","150.0")
	weapons_effects_on_off = register_cvar("weapons_effects_on_off","1")
	weapons_effects_mode = register_cvar("weapons_effects_mode","4")
	weapons_glows_color = register_cvar("weapons_glows_color","0 255 255")
	weapons_glows_thickness = register_cvar("weapons_glows_thickness","128")

	/////////////////////////////////////////////////////////////////////////////////

	// Parachute area
	register_event("ResetHUD", "newSpawn", "be")
	register_event("DeathMsg", "death_event", "a")

	// Set map lightning level
	new light[32];
	get_pcvar_string(gCvarLight, light, charsmax(light));
	set_lights(light);

	// Snark penguin
	register_forward(FM_SetModel			, "fwd_SetModel");
	register_forward(FM_EmitSound			, "fwd_EmitSound");

}

public mapFile()
{
	new DataFile[128];
	new map_file[128];
	get_configsdir( DataFile, 127 );
	format(map_file, 127, "%s/cir_maps.ini", DataFile );

	if ( !file_exists(map_file) )
	{
		server_print ( "================================================" );
		server_print ( "[CIR List] cir_maps.ini file not found!");
		server_print ( "================================================" );
		return;
	}
	
	new len, i=0;
	while( i < MAX_WORDS && read_file( map_file, i , g_mapData[g_mapNum], 19, len ) )
	{
		i++;
		if( g_mapData[g_mapNum][0] == ';' || len == 0 )
			continue;
		g_mapNum++;
	}

	server_print ( "===================================================" );
	server_print ( "[CIR List] %i Maps Loaded.", g_mapNum );
	server_print ( "===================================================" );
	
	mapControl();
	
}

public mapControl()
{
	static map_name[33];
	get_mapname(map_name, charsmax(map_name));

	new i = 0;
	while ( i < g_mapNum )
	{
		if ( equali ( map_name, g_mapData[i++] ) )
		{
			client_print ( 0 , print_chat , "[HL.LaLeagane.Ro] Cold Ice Remastered Fun mod!");
			
			return PLUGIN_HANDLED;	
		}
	}
	
	StopPlugin();
	return PLUGIN_HANDLED;	
}

// ===== PLUGIN STOP ==============
stock StopPlugin() 
{
	new pluginName[32];
	get_plugin(-1, pluginName, sizeof(pluginName));
	pause("d", pluginName);
	return;
}


public fwd_GetGameDescription()
{ 
	forward_return(FMV_STRING, GAME_DESCRIPTION);
	return FMRES_SUPERCEDE;
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

	// Flying crowbar area

	blood_drop = precache_model("sprites/blood.spr");
	blood_spray = precache_model("sprites/bloodspray.spr");
	trail = precache_model("sprites/hl_xmas/ice_beam.spr");

	// grenade
	precache_model(W_NEW_GRENADE);

	// Freeze power area


	precache_model(MODEL_FROZEN);
	glassGibs = precache_model(MODEL_GLASSGIBS);

	precache_sound(SOUND_EXPLODE); // grenade explodes
	precache_sound(SOUND_FROZEN); // player is frozen
	precache_sound(SOUND_UNFROZEN); // frozen wears off

	smokeSpr = precache_model(SPRITE_SMOKE);
	exploSpr = precache_model(SPRITE_EXPLO);
	powerSpr = precache_model(MODELPOWER);

	precache_model("models/cir/cir_wings.mdl");

	// penguin sounds
	precache_sound("cir/penguin1.wav");
	precache_sound("cir/penguin2.wav");
	precache_sound("cir/penguin3.wav");

}

stock hl_get_ammo(client, weapon)
{
	return get_ent_data(client, "CBasePlayer", "m_rgAmmo", _HLW_to_rgAmmoIdx[weapon]);
}

stock hl_set_ammo(client, weapon, ammo)
{
	if (weapon <= HLW_CROWBAR)
		return;

	set_ent_data(client, "CBasePlayer", "m_rgAmmo", ammo, _HLW_to_rgAmmoIdx[weapon]);
}

public client_putinserver(id)
{
	isFrozen[id] = 0;
	novaDisplay[id] = 0;
	
}

public client_connect(id)
{
	parachute_reset(id)
}

public client_disconnected(id)
{
	if(isFrozen[id]) task_remove_freeze(TASK_REMOVE_FREEZE+id);
	parachute_reset(id);
}


public CBasePlayer_Spawn(id)
{
	if ( !is_user_alive(id) )
	{
			return;
	}

	if(isFrozen[id]) task_remove_freeze(TASK_REMOVE_FREEZE+id);
	give_weapons(id);

	const UNIT_SECOND = (1<<12) 
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), {0,0,0}, id)
	write_short(UNIT_SECOND * 4)
	write_short(UNIT_SECOND * 1)
	write_short(0x0000)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	write_byte(55)
	message_end()
}


// Crossbow
public touch_crossbow(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	if(hl_user_has_weapon(id, HLW_CROSSBOW) != 0)
	{
		hl_set_ammo(id, HLW_CROSSBOW, get_pcvar_num(cvar_ammo_crossbow));	
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_CROSSBOW)),get_pcvar_num(cvar_start_ammo_crossbow));	
	}
	return PLUGIN_HANDLED;	
}
// Shotgun
public touch_shotgun(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	if(hl_user_has_weapon(id, HLW_SHOTGUN) != 0)
   	{
		hl_set_ammo(id, HLW_SHOTGUN, get_pcvar_num(cvar_ammo_buckshot));
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),get_pcvar_num(cvar_start_ammo_buckshot));	
	}
	return PLUGIN_HANDLED;	
}
// Gauss Gun
public touch_gauss(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	if(hl_user_has_weapon(id, HLW_GAUSS) != 0)
	{
		hl_set_ammo(id, HLW_GAUSS, get_pcvar_num(cvar_ammo_gaussclip));
	}
	return PLUGIN_HANDLED;	
}
// egon
public touch_egon(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	if(hl_user_has_weapon(id, HLW_GAUSS) != 0)
	{
		hl_set_ammo(id, HLW_GAUSS, get_pcvar_num(cvar_ammo_gaussclip));
	}
	return PLUGIN_HANDLED;	
}
// RPG
public touch_rpg(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;

	if(hl_user_has_weapon(id, HLW_RPG) != 0)
	{
		hl_set_ammo(id, HLW_RPG, get_pcvar_num(cvar_ammo_rpgclip));
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),get_pcvar_num(cvar_start_ammo_rpgclip));
	}
	return PLUGIN_HANDLED;	
}
// 9mmAR
public touch_9mmAR(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	if(hl_user_has_weapon(id, HLW_MP5) != 0)
	{
		hl_set_ammo(id, HLW_MP5, get_pcvar_num(cvar_ammo_9mmAR));
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_MP5)),get_pcvar_num(cvar_start_ammo_9mmAR));
	}
	return PLUGIN_HANDLED;	
}		
// .357
public touch_357(ent,id)
{	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;	
	if(hl_user_has_weapon(id, HLW_PYTHON) != 0)
	{
		hl_set_ammo(id, HLW_PYTHON, get_pcvar_num(cvar_ammo_357));
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_PYTHON)),get_pcvar_num(cvar_start_ammo_357));		
	}
	return PLUGIN_HANDLED;	
}
// Glock
public touch_9mmhandgun(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;		
	if(hl_user_has_weapon(id, HLW_GLOCK) != 0)
	{
		hl_set_ammo(id, HLW_GLOCK, get_pcvar_num(cvar_ammo_glock));
		hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),get_pcvar_num(cvar_start_ammo_glock));
	}
	return PLUGIN_HANDLED;	
}
// Satchel
public touch_satchel(ent,id)
{	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;	
	if(hl_user_has_weapon(id, HLW_SATCHEL) != 0)
	{
		hl_set_ammo(id, HLW_SATCHEL, get_pcvar_num(cvar_ammo_satchel));
	}
	return PLUGIN_HANDLED;	
}
// Tripmine
public touch_tripmine(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;	
	if(hl_user_has_weapon(id, HLW_TRIPMINE) != 0)
	{
		hl_set_ammo(id, HLW_TRIPMINE, get_pcvar_num(cvar_ammo_tripmine));
	}
	return PLUGIN_HANDLED;	
}
// Handgrenade
public touch_handgrenade(ent,id)
{	
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;	
	if(hl_user_has_weapon(id, HLW_HANDGRENADE) != 0)
	{
		hl_set_ammo(id,HLW_HANDGRENADE,get_pcvar_num(cvar_ammo_hgrenade)); 
	}
	return PLUGIN_HANDLED;	
}
// snark
public touch_snark(ent,id)
{		
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	if(hl_user_has_weapon(id, HLW_SNARK) != 0)
	{
		hl_set_ammo(id,HLW_SNARK,get_pcvar_num(cvar_ammo_snark)); 	
	}
	return PLUGIN_HANDLED;	
}
// hornetgun
public touch_hgun(ent,id)
{		
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	if(hl_user_has_weapon(id, HLW_HORNETGUN) != 0)
	{
		hl_set_ammo(id, HLW_HORNETGUN, get_pcvar_num(cvar_ammo_hornetgun));
	}
	return PLUGIN_HANDLED;	
}
public touch_ARgrenades(ent,id)
{
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	hl_set_ammo(id,HLW_CHAINGUN,get_pcvar_num(cvar_ammo_ARgrenades));
	return PLUGIN_HANDLED;	
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


// ====== SPAWN EQUIP WEAPONS =========
public give_weapons(id) 
{
	// Buffer to write the file
	new buffer[128];
	format(buffer, 128, "[Cold Ice Remastered] You received: crowbar, glock ");

	if(is_user_alive(id))
	{
		if(get_pcvar_num(cvar_ilongjump))
		{
			hl_set_user_longjump(id,true);
		}
		if(get_pcvar_num(cvar_ihealth) > 0)
		{
			hl_set_user_health(id,get_pcvar_num(cvar_ihealth));
		}
		if(get_pcvar_num(cvar_iarmour) > 0 )
		{
			hl_set_user_armor(id,get_pcvar_num(cvar_iarmour));
		}
		if(random_num(-3,get_pcvar_num(cvar_Wcrowbar)))
		{
			give_item( id, "weapon_crowbar" );
		}
		if(random_num(-3,get_pcvar_num(cvar_W9mmhandgun)) == 1)
		{		
			give_item( id, "weapon_9mmhandgun" );
			hl_set_ammo(id,HLW_GLOCK,get_pcvar_num(cvar_ammo_glock)); 		
			hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),get_pcvar_num(cvar_start_ammo_glock));
		}
		if(random_num(-3,get_pcvar_num(cvar_Wgauss)) == 1)
		{
			strcat(buffer,", gauss", charsmax(buffer));
			give_item( id, "weapon_gauss" );
			hl_set_ammo(id,HLW_GAUSS,get_pcvar_num(cvar_ammo_gaussclip));  	
		}
		if(random_num(-3,get_pcvar_num(cvar_Wegon)) == 1)
		{
			strcat(buffer,", egon", charsmax(buffer));
			give_item( id, "weapon_egon" );
			hl_set_ammo(id,HLW_GAUSS,get_pcvar_num(cvar_ammo_gaussclip));  	
		}
		if(random_num(-3,get_pcvar_num(cvar_Wcrossbow)) == 1)
		{
			strcat(buffer,", crossbow", charsmax(buffer));
			give_item( id, "weapon_crossbow" );
			hl_set_ammo(id,HLW_CROSSBOW,get_pcvar_num(cvar_ammo_crossbow)); 	
			hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_CROSSBOW)),get_pcvar_num(cvar_start_ammo_crossbow));		
		}
		if(random_num(-3,get_pcvar_num(cvar_Wrpg)) == 1)
		{
			strcat(buffer,", RPG", charsmax(buffer));
			give_item( id, "weapon_rpg" );
			hl_set_ammo(id,HLW_RPG,get_pcvar_num(cvar_ammo_rpgclip)); 	
			hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),get_pcvar_num(cvar_start_ammo_rpgclip));	
		}
		if(random_num(-3,get_pcvar_num(cvar_Wsatchel)) == 1)
		{
			strcat(buffer,", satchel", charsmax(buffer));
			give_item( id, "weapon_satchel" );
			hl_set_ammo(id,HLW_SATCHEL,get_pcvar_num(cvar_ammo_satchel)); 	
		}
		if(random_num(-3,get_pcvar_num(cvar_Wsnark)) == 1)
		{
			strcat(buffer,", penguins", charsmax(buffer));
			give_item( id, "weapon_snark" );
			hl_set_ammo(id,HLW_SNARK,get_pcvar_num(cvar_ammo_snark)); 	
		}
		if(random_num(-3,get_pcvar_num(cvar_Whandgrenade)) == 1)
		{
			strcat(buffer,", grenades", charsmax(buffer));
			give_item( id, "weapon_handgrenade" );	
			hl_set_ammo(id,HLW_HANDGRENADE,get_pcvar_num(cvar_ammo_hgrenade)); 	
		}	
		if(random_num(-3,get_pcvar_num(cvar_Whornetgun)) == 1)
		{
			strcat(buffer,", hornetgun", charsmax(buffer));
			give_item( id, "weapon_hornetgun" );
			hl_set_ammo(id,HLW_HORNETGUN,get_pcvar_num(cvar_ammo_hornetgun));	
			
		}	
		if(random_num(-3,get_pcvar_num(cvar_Wtripmine)) == 1)
		{
			strcat(buffer,", tripmines", charsmax(buffer));
			give_item( id, "weapon_tripmine" );
			hl_set_ammo(id,HLW_TRIPMINE,get_pcvar_num(cvar_ammo_tripmine));
		}		
		if(random_num(-3,get_pcvar_num(cvar_W357)) == 1)
		{
			strcat(buffer,", 357", charsmax(buffer));
			give_item( id, "weapon_357" );
			hl_set_ammo(id,HLW_PYTHON,get_pcvar_num(cvar_ammo_357)); 	
			hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_PYTHON)),get_pcvar_num(cvar_start_ammo_357));		
		}
		if(random_num(-3,get_pcvar_num(cvar_W9mmAR)) == 1)
		{
			strcat(buffer,", mp5", charsmax(buffer));
			give_item( id, "weapon_9mmAR" );
			hl_set_ammo(id,HLW_MP5,get_pcvar_num(cvar_ammo_9mmAR));  	
			hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_MP5)),get_pcvar_num(cvar_start_ammo_9mmAR));
		}		
		if(random_num(-3,get_pcvar_num(cvar_Wshotgun)) == 1)
		{
			strcat(buffer,", shotgun", charsmax(buffer));
			give_item( id, "weapon_shotgun" );
			hl_set_ammo(id,HLW_SHOTGUN,get_pcvar_num(cvar_ammo_buckshot)); 	
			hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),get_pcvar_num(cvar_start_ammo_buckshot));	
		}
		client_print(id,print_chat,buffer);	
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

/* 
		Flying crowbar area
*/


//Replacing the kill message with a crowbar
public DeathMsg()					
{	
	static sWeapon[20];
	get_msg_arg_string(3,sWeapon,19);
	if(equal(sWeapon,CROW)) 
		set_msg_arg_string(3,"dmg_cold");
}

//Secondary attack 
public fw_CrowbarSecondaryAttack(ent)
{
	new id = get_pdata_cbase(ent,m_pPlayer,XTRA_OFS_WEAPON);
	
	if(!FlyCrowbar_Spawn(id))
		return HAM_IGNORED;
	
	set_pdata_float(ent,m_flNextSecondaryAttack,2.5,XTRA_OFS_WEAPON);
	
	return HAM_IGNORED;
}

// Catching collisions of flying crowbar with other objects
public FlyCrowbar_Touch(toucher,touched)
{
	new Float:origin[3],Float:angles[3];
	pev(toucher,pev_origin,origin);
	pev(toucher,pev_angles,angles);

		// a frost power explodes
	
	// make the smoke
	message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_SPRITE);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_short(smokeSpr); // sprite
	write_byte(30); // scale
	write_byte(100); // brightness
	message_end();
	
	// explosion
	create_blast(origin);
	emit_sound(toucher,CHAN_WEAPON,SOUND_EXPLODE,VOL_NORM,ATTN_NORM,0,PITCH_HIGH);
	
	if(!IsPlayer(touched)){
				// touch wall
		//emit_sound(toucher,CHAN_WEAPON,"weapons/cbar_hit1.wav",0.9,ATTN_NORM,0,PITCH_NORM); // sound to repalce
		
		engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0);
		write_byte(TE_SPARKS);
		engfunc(EngFunc_WriteCoord,origin[0]);
		engfunc(EngFunc_WriteCoord,origin[1]);
		engfunc(EngFunc_WriteCoord,origin[2]);
		message_end();
	}else{
				// touch player - to do for freeze explosion
		ExecuteHamB(Ham_TakeDamage,touched,toucher,pev(toucher,pev_owner),get_pcvar_float(damage_crowbar),DMG_CLUB)	;
		//emit_sound(toucher,CHAN_WEAPON,"weapons/cbar_hitbod1.wav",0.9,ATTN_NORM,0,PITCH_NORM);
		
		engfunc(EngFunc_MessageBegin,MSG_PVS,SVC_TEMPENTITY,origin,0);
		write_byte(TE_BLOODSPRITE);
		engfunc(EngFunc_WriteCoord,origin[0]+random_num(-20,20));
		engfunc(EngFunc_WriteCoord,origin[1]+random_num(-20,20));
		engfunc(EngFunc_WriteCoord,origin[2]+random_num(-20,20));
		write_short(blood_spray);
		write_short(blood_drop);
		write_byte(248); // color index
		write_byte(15); // size
		message_end();
	}
	
	engfunc(EngFunc_RemoveEntity,toucher); // Destroy
	
}

// make the explosion effects
public create_blast(Float:origin[3])
{

		// Ice blue
	new rgb[3] = {0 , 255, 255};

	// smallest ring
	message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_coord_fl(origin[0]); // x axis
	write_coord_fl(origin[1]); // y axis
	write_coord_fl(origin[2] + 385.0); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// medium ring
	message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_coord_fl(origin[0]); // x axis
	write_coord_fl(origin[1]); // y axis
	write_coord_fl(origin[2] + 470.0); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// largest ring
	message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_BEAMCYLINDER);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_coord_fl(origin[0]); // x axis
	write_coord_fl(origin[1]); // y axis
	write_coord_fl(origin[2] + 555.0); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// light effect
	message_begin_fl(MSG_PAS,SVC_TEMPENTITY,origin,0);
	write_byte(TE_DLIGHT);
	write_coord_fl(origin[0]); // x
	write_coord_fl(origin[1]); // y
	write_coord_fl(origin[2]); // z
	write_byte(floatround(FROST_RADIUS/5.0)); // radius
	write_byte(rgb[0]); // r
	write_byte(rgb[1]); // g
	write_byte(rgb[2]); // b
	write_byte(8); // life
	write_byte(60); // decay rate
	message_end();

	// check players nearby the explosion 
	frostnade_explode(origin);
}

// Check if players are in range of blast
public frostnade_explode (Float:powerOrigin[3])
{
	new maxPlayers = get_maxplayers();
	new Float:targetOrigin[3];
	new Float:distance;

	for(new target=1;target<=maxPlayers;target++)
	{
		// dead or spectate
		if(!is_user_alive(target) )
			continue;
		
		pev(target,pev_origin,targetOrigin);
		distance = vector_distance(powerOrigin,targetOrigin);

		// too far
		if(distance > FROST_RADIUS) 
						continue;

		// freeze
		if((distance <= FROST_RADIUS) && isFrozen[target] == 0)
		{
			emit_sound(target,CHAN_ITEM,SOUND_FROZEN,1.0,ATTN_NONE,0,PITCH_LOW);
			create_nova(target);
		}
		
		}
	
}

// make a frost nova at a player's feet
public create_nova(id)
{

	new nova = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"));
		
	new Float:novaOrigin[3];
	pev(id,pev_origin,novaOrigin);
	if(pev( id, pev_flags ) & FL_DUCKING) 
	{
		novaOrigin[2] -= 15.0;
	}
	else 
	{
		novaOrigin[2] -= 35.0;
	}

	entity_set_model(nova, MODEL_FROZEN);
	dllfunc(DLLFunc_Spawn, nova);
	set_pev(nova, pev_solid, SOLID_BBOX);
	set_pev(nova, pev_movetype, MOVETYPE_FLY);
	entity_set_origin(nova, novaOrigin);
	entity_set_size(nova, Float:{ -3.0, -3.0, -3.0 }, Float:{ 3.0, 3.0, 3.0 });
	set_rendering(nova, kRenderFxNone, 255, 255, 255, kRenderTransAdd, 255);

	isFrozen[id] = 1;
	novaDisplay[id] = nova;

	// freeze player 
	set_user_maxspeed(id, 1.0);
	set_user_gravity(id,10.0);
		
	remove_task(TASK_REMOVE_FREEZE+id);
	set_task(get_pcvar_float(freeze_duration),"task_remove_freeze",TASK_REMOVE_FREEZE+id);
}


public task_remove_freeze(taskid)
{
	new id = taskid-TASK_REMOVE_FREEZE;
	
	if(pev_valid(novaDisplay[id]))
	{
		new Float:origin[3];
		pev(novaDisplay[id],pev_origin,origin);

		// add some tracers
		message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
		write_byte(TE_IMPLOSION);
		write_coord_fl(origin[0]); // x
		write_coord_fl(origin[1]); // y
		write_coord_fl(origin[2] + 8.0); // z
		write_byte(64); // radius
		write_byte(10); // count
		write_byte(3); // duration
		message_end();

		// add some sparks
		message_begin_fl(MSG_PVS,SVC_TEMPENTITY,origin,0);
		write_byte(TE_SPARKS);
		write_coord_fl(origin[0]); // x
		write_coord_fl(origin[1]); // y
		write_coord_fl(origin[2]); // z
		message_end();

		// add the shatter
		message_begin_fl(MSG_PAS,SVC_TEMPENTITY,origin,0);
		write_byte(TE_BREAKMODEL);
		write_coord_fl(origin[0]); // x
		write_coord_fl(origin[1]); // y
		write_coord_fl(origin[2] + 24.0); // z
		write_coord_fl(16.0); // size x
		write_coord_fl(16.0); // size y
		write_coord_fl(16.0); // size z
		write_coord(random_num(-50,50)); // velocity x
		write_coord(random_num(-50,50)); // velocity y
		write_coord_fl(25.0); // velocity z
		write_byte(10); // random velocity
		write_short(glassGibs); // model
		write_byte(10); // count
		write_byte(25); // life
		write_byte(BREAK_GLASS); // flags
		message_end();

		emit_sound(novaDisplay[id],CHAN_ITEM,SOUND_UNFROZEN,VOL_NORM,ATTN_NORM,0,PITCH_LOW);
		set_pev(novaDisplay[id],pev_flags,pev(novaDisplay[id],pev_flags)|FL_KILLME);
	}

	isFrozen[id] = 0;
	novaDisplay[id] = 0;
	

	if(!is_user_connected(id)) return;
	
	// restore speed, but then check for chilled
	set_user_maxspeed(id, get_cvar_float("sv_maxspeed"));
	set_user_gravity(id,1.0);
}

public Crowbar_Think(ent)

{
	if(pev_valid(ent))
		engfunc(EngFunc_RemoveEntity,ent);	// release
}

public fw_CrowbarItemAdd(ent,id)
{
	remove_task(ent);
}

// Spawn flying crowbar and set speed
public FlyCrowbar_Spawn(id)
{
	new crowbar = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"env_sprite"));
	
	if(!pev_valid(crowbar))
		return 0;
	
	set_pev(crowbar,pev_classname,CROW);
	engfunc(EngFunc_SetModel,crowbar,MODELPOWER);
	//engfunc(EngFunc_SetSize,crowbar,Float:{-0.5, -0.5, -0.5} , Float:{0.5, 0.5, 0.5});
	
	new Float:vec[3];
	get_projective_pos(id,vec);
	engfunc(EngFunc_SetOrigin,crowbar,vec);

	
	pev(id,pev_v_angle,vec);
	vec[0] = 90.0;
	vec[2] = floatadd(vec[2],-90.0);
	
	set_pev(crowbar,pev_owner,id);
	set_pev(crowbar,pev_angles,vec);

	
	velocity_by_aim(id,get_pcvar_num(crowbar_speed)+get_speed(id),vec);
	set_pev(crowbar,pev_velocity,vec);
	set_pev(crowbar,pev_nextthink,get_gametime()+0.1);
	
	DispatchSpawn(crowbar);
	
	if(get_pcvar_num(crowbar_trail)){
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_BEAMFOLLOW);
		write_short(crowbar);
		write_short(trail);
		write_byte(15);
		write_byte(20);
		write_byte(255);
		write_byte(255);
		write_byte(255);
		write_byte(255);
		message_end();
	}
	
	set_pev(crowbar,pev_movetype,MOVETYPE_FLY);
	set_pev(crowbar,pev_solid,SOLID_BBOX);

	// Set proper rendering
	set_pev( crowbar, pev_rendermode, kRenderTransAdd );
	set_pev( crowbar, pev_renderamt, 200.0 );
	
	// Set the animation's framerate
	set_pev( crowbar, pev_framerate, 1.0 ); 
	set_pev( crowbar, pev_animtime, 1.0);
	//dllfunc( DLLFunc_Spawn, crowbar );

	// size
	set_pev(crowbar, pev_mins, {-0.5, -0.5, -0.5});
	set_pev(crowbar, pev_maxs, {0.5, 0.5, 0.5});
	
	emit_sound(id,CHAN_WEAPON,"weapons/cbar_miss1.wav",0.9,ATTN_NORM,0,PITCH_NORM);
	set_task(0.1,"FlyCrowbar_Whizz",crowbar);
	
	return crowbar;
}

// Crowbar spin on flying
public FlyCrowbar_Think(ent){
	new Float:vec[3];
	pev(ent,pev_angles,vec);
	vec[0] = floatadd(vec[0],-15.0);
	set_pev(ent,pev_angles,vec);
	
	set_pev(ent,pev_nextthink,get_gametime()+0.01);
}

// Sounds from flying crowbar
public FlyCrowbar_Whizz(crowbar)
{
	if(pev_valid(crowbar)){
		emit_sound(crowbar,CHAN_WEAPON,"weapons/cbar_miss1.wav",0.9,ATTN_NORM,0,PITCH_NORM);
		
		set_task(0.2,"FlyCrowbar_Whizz",crowbar);
	}
}

// Calculate the position of the crowbar
public get_projective_pos(player,Float:oridjin[3])
{
	new Float:v_forward[3];
	new Float:v_right[3];
	new Float:v_up[3];
	
	GetGunPosition(player,oridjin);
	
	global_get(glb_v_forward,v_forward);
	global_get(glb_v_right,v_right);
	global_get(glb_v_up,v_up);
	
	xs_vec_mul_scalar(v_forward,6.0,v_forward);
	xs_vec_mul_scalar(v_right,2.0,v_right);
	xs_vec_mul_scalar(v_up,-2.0,v_up);
	
	xs_vec_add(oridjin,v_forward,oridjin);
	xs_vec_add(oridjin,v_right,oridjin);
	xs_vec_add(oridjin,v_up,oridjin);
}

//Get weapon position
stock GetGunPosition(const player,Float:origin[3])
{
	new Float:viewOfs[3];
	
	pev(player,pev_origin,origin);
	pev(player,pev_view_ofs,viewOfs);
	
	xs_vec_add(origin,viewOfs,origin);
}


// rpg ammo verification when rockets = 1 + call restore ammo
public rpg_primary_attack_pre(this)
{
	new id = get_pdata_cbase(this, m_pPlayer, XTRA_OFS_WEAPON)
	// restore rpg ammo when 1 rocket left - couldnt be done in reload function because it loops several times.
	if (hl_get_weapon_ammo((hl_user_has_weapon(id,HLW_RPG))) == 1) 
	 set_task(4.5, "restore_rpg_ammo", id)
}

public restore_rpg_ammo(id){
	// rpg 
	if(hl_get_ammo(id,HLW_RPG) <= get_pcvar_num(cvar_ammo_rpgclip) && hl_get_ammo(id,HLW_RPG) != 0 )
		{
			if (hl_get_ammo(id,HLW_RPG) <= get_pcvar_num(cvar_start_ammo_rpgclip))
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),hl_get_ammo(id,HLW_RPG)+1); // +1 rocket cuz its wasted when reload
				hl_set_ammo(id,HLW_RPG,0); 	
			}
			else 
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_RPG)),get_pcvar_num(cvar_start_ammo_rpgclip));
				hl_set_ammo(id,HLW_RPG,hl_get_ammo(id,HLW_RPG)-get_pcvar_num(cvar_start_ammo_rpgclip)+1); // +1 rocket cuz its wasted when reload	
			}
		}
}

// rpg firing speed (MOUSE1) -1
public rpg_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.2)
}

// 9mmAR grenade firing speed (MOUSE2) 
public grenades_secondary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.15)
}

// Shotgun firing speed (MOUSE1) -1
public shotgun_primary_attack_pre(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, XTRA_OFS_WEAPON)
	old_clip[player] = get_pdata_int(this, m_iClip, XTRA_OFS_WEAPON)
	
	//restore shotgun ammo - only 1 bullet left is need to verify
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 1) 
	 set_task(1.0, "restore_shotgun_ammo", player)
}
// Shotgun firing speed (MOUSE1) -2
public shotgun_primary_attack_post(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, XTRA_OFS_WEAPON)

	if(old_clip[player] <= 0)
		return

	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.3)

	if(get_pdata_int(this, m_iClip, XTRA_OFS_WEAPON) != 0)
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 2.0)
	else
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.3)
}

// Shotgun firing speed (MOUSE2) -1
public shotgun_secondary_attack_pre(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, XTRA_OFS_WEAPON)
	old_clip[player] = get_pdata_int(this, m_iClip, XTRA_OFS_WEAPON)
		//restore shotgun ammo - they can have 1 or 2 bullets left before reloading
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 1 || hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_SHOTGUN))) == 2 )
	 set_task(1.0, "restore_shotgun_ammo", player)
}
// Shotgun firing speed (MOUSE2) -2
public shotgun_secondary_attack_post(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, XTRA_OFS_WEAPON)

	if(old_clip[player] <= 0)
		return

	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 0.3)

	if(get_pdata_int(this, m_iClip, XTRA_OFS_WEAPON) != 0)
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 3.0)
	else
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.85)
}


public restore_shotgun_ammo(id)
{
	// shotgun 
	if(hl_get_ammo(id,HLW_SHOTGUN) <= get_pcvar_num(cvar_ammo_buckshot) && hl_get_ammo(id,HLW_SHOTGUN) != 0 )
		{
			if (hl_get_ammo(id,HLW_SHOTGUN) <= get_pcvar_num(cvar_start_ammo_buckshot))
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),hl_get_ammo(id,HLW_SHOTGUN)+1); // +1 bullet cuz its wasted when reloading
				hl_set_ammo(id,HLW_SHOTGUN,0);
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_SHOTGUN)),get_pcvar_num(cvar_start_ammo_buckshot));
				hl_set_ammo(id,HLW_SHOTGUN,hl_get_ammo(id,HLW_SHOTGUN)-get_pcvar_num(cvar_start_ammo_buckshot)+1); // +1 bullet cuz its wasted when reloading 	
			}
		}
}

// 9mmAR firing speed (MOUSE1) -2
public mp5_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.06)
}

// 9mmhandgun firing speed (MOUSE1) -1 + verify ammo
public glock_primary_attack_pre(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, XTRA_OFS_WEAPON)
	
    //restore 9mmhandgun ammo 
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_GLOCK))) == 1)
	 set_task(2.0, "restore_glock_ammo", player)
	old_clip[player] = get_pdata_int(this, m_iClip, XTRA_OFS_WEAPON)
}

// 9mmhandgun firing speed (MOUSE1) -2
public glock_primary_attack_post(this)
{

	new player = get_pdata_cbase(this, m_pPlayer, XTRA_OFS_WEAPON)

	if(old_clip[player] <= 0)
		return

	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.3)

	if(get_pdata_int(this, m_iClip, XTRA_OFS_WEAPON) != 0)
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 2.0)
	else
		set_ent_data_float(this, "CBasePlayerWeapon", "m_flTimeWeaponIdle", 0.3)
}

// 9mmhandgun secondary attack

public glock_secondary_attack(this)
{
	new player = get_pdata_cbase(this, m_pPlayer, XTRA_OFS_WEAPON)
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextSecondaryAttack", 3.0)
		//restore 9mmhandgun ammo 
	if (hl_get_weapon_ammo((hl_user_has_weapon(player,HLW_GLOCK))) == 1)
	 set_task(3.5, "restore_glock_ammo", player)
	old_clip[player] = get_pdata_int(this, m_iClip, XTRA_OFS_WEAPON)
} 

 //restore 9mmhandgun ammo 
public restore_glock_ammo(id){
		
			if(hl_get_ammo(id,HLW_GLOCK) <= get_pcvar_num(cvar_ammo_glock) && hl_get_ammo(id,HLW_GLOCK) != 0 )
		{
			if (hl_get_ammo(id,HLW_GLOCK) <= get_pcvar_num(cvar_start_ammo_glock))
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),hl_get_ammo(id,HLW_GLOCK)+17); // + 17 cuz wasted on reloading
				hl_set_ammo(id,HLW_GLOCK,0); 
			}
			else
			{
				hl_set_weapon_ammo((hl_user_has_weapon(id,HLW_GLOCK)),get_pcvar_num(cvar_start_ammo_glock));
				hl_set_ammo(id,HLW_GLOCK,hl_get_ammo(id,HLW_GLOCK)-get_pcvar_num(cvar_start_ammo_glock)+17); // + 17 cuz wasted on reloading	
			}
		}
}


public  fwd_EmitSound(ent, channel, sample[], Float:volume, Float:attn, flags, pitch) 
{
	
	new classname[32]
	pev(ent, pev_classname, classname, 31)

	
	if(!equal(classname, "monster_snark"))
		return FMRES_IGNORED
	
	replace (sample, 64, "squeek/sqk_hunt", "cir/penguin") 
	
	emit_sound(ent, channel, sample, volume, attn, 0, pitch)
	return FMRES_SUPERCEDE
}


public fwd_SetModel(ent, model[])
{	
	if(equal(model, W_GRENADE))
	{
		engfunc(EngFunc_SetModel, ent, W_NEW_GRENADE)
		return FMRES_SUPERCEDE
	}

	if(equal(model, "models/w_squeak.mdl"))
	{
		engfunc(EngFunc_SetModel, ent, "models/cir/w_squeak.mdl")
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}


// Snark firing speed (MOUSE1) 
public snark_primary_attack_post(this)
{
	set_ent_data_float(this, "CBasePlayerWeapon", "m_flNextPrimaryAttack", 0.11)
}

// Parachute area


public client_PreThink(id)
{
	if(!is_user_alive(id)) return
	
	new Float:fallspeed = 100 * -1.0
	new Float:frame
	new button = get_user_button(id)
	new oldbutton = get_user_oldbutton(id)
	new flags = get_entity_flags(id)
	if(para_ent[id] > 0 && (flags & FL_ONGROUND)) 
	{
		if(get_user_gravity(id) == 0.1) set_user_gravity(id, 1.0)
		{
			if(entity_get_int(para_ent[id],EV_INT_sequence) != 2) 
			{
				entity_set_int(para_ent[id], EV_INT_sequence, 2)
				entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
				entity_set_float(para_ent[id], EV_FL_frame, 0.0)
				entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
				entity_set_float(para_ent[id], EV_FL_framerate, 0.0)
				return
			}
			frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 2.0
			entity_set_float(para_ent[id],EV_FL_fuser1,frame)
			entity_set_float(para_ent[id],EV_FL_frame,frame)
			if(frame > 254.0) 
			{
				remove_entity(para_ent[id])
				para_ent[id] = 0
			}
			else 
			{
				remove_entity(para_ent[id])
				set_user_gravity(id, 1.0)
				para_ent[id] = 0
			}
			return
		}
	}
	if (button & IN_USE)  
	{
		if (get_pcvar_num(cvar_wings) == 1)
		{
		new Float:velocity[3]
		entity_get_vector(id, EV_VEC_velocity, velocity)
		if(velocity[2] < 0.0) 
		{
			if(para_ent[id] <= 0) 
			{
				para_ent[id] = create_entity("info_target")
				if(para_ent[id] > 0) 
				{
					entity_set_string(para_ent[id],EV_SZ_classname,"parachute")
					entity_set_edict(para_ent[id], EV_ENT_aiment, id)
					entity_set_edict(para_ent[id], EV_ENT_owner, id)
					entity_set_int(para_ent[id], EV_INT_movetype, MOVETYPE_FOLLOW)
					entity_set_model(para_ent[id], "models/cir/cir_wings.mdl")
					entity_set_int(para_ent[id], EV_INT_sequence, 0)
					entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
					entity_set_float(para_ent[id], EV_FL_frame, 0.0)
					entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
				}
			}
			if(para_ent[id] > 0) 
			{
				entity_set_int(id, EV_INT_sequence, 3)
				entity_set_int(id, EV_INT_gaitsequence, 1)
				entity_set_float(id, EV_FL_frame, 1.0)
				entity_set_float(id, EV_FL_framerate, 1.0)
				set_user_gravity(id, 0.1)
				velocity[2] = (velocity[2] + 40.0 < fallspeed) ? velocity[2] + 40.0 : fallspeed
				entity_set_vector(id, EV_VEC_velocity, velocity)
				if(entity_get_int(para_ent[id],EV_INT_sequence) == 0) 
				{
					frame = entity_get_float(para_ent[id],EV_FL_fuser1) + 1.0
					entity_set_float(para_ent[id],EV_FL_fuser1,frame)
					entity_set_float(para_ent[id],EV_FL_frame,frame)
					if (frame > 100.0) 
					{
						entity_set_float(para_ent[id], EV_FL_animtime, 0.0)
						entity_set_float(para_ent[id], EV_FL_framerate, 0.4)
						entity_set_int(para_ent[id], EV_INT_sequence, 1)
						entity_set_int(para_ent[id], EV_INT_gaitsequence, 1)
						entity_set_float(para_ent[id], EV_FL_frame, 0.0)
						entity_set_float(para_ent[id], EV_FL_fuser1, 0.0)
					}
				}
			}
		}
		else if(para_ent[id] > 0) 
		{
			remove_entity(para_ent[id])
			set_user_gravity(id, 1.0)
			para_ent[id] = 0
		}
	}
	}
	else if((oldbutton & IN_USE) && para_ent[id] > 0 ) 
	{
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
}

public plugin_natives()
{
	set_native_filter("native_filter")
}

public native_filter(const name[], index, trap)
{
	if (!trap) return PLUGIN_HANDLED
	return PLUGIN_CONTINUE
}

public death_event()
{
	new id = read_data(2)
	parachute_reset(id)
}

public parachute_reset(id)
{
	if(para_ent[id] > 0) 
	{
		if (is_valid_ent(para_ent[id])) 
		{
			remove_entity(para_ent[id])
		}
	}

	if(is_user_alive(id)) set_user_gravity(id, 1.0)
	para_ent[id] = 0
}


public newSpawn(id)
{
	if(para_ent[id] > 0) 
	{
		remove_entity(para_ent[id])
		set_user_gravity(id, 1.0)
		para_ent[id] = 0
	}
}