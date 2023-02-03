#if defined _rog_included
#endinput
#endif
#define _rog_included

#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <fun>

new const PrimaryDefaultMapEntities[][] =
{
	"func_bomb_target",
	"func_hostage_rescue",
	"info_player_start",
	"info_player_deathmatch",
	"func_escapezone",
	"func_vip_safetyzone",
	"info_vip_start"
}

new const SecondaryDefaultMapEntities[][] =
{	
	"info_bomb_target",
	"info_hostage_rescue"
}

new Array:DefaultMapEntitiesArray
new Array:FoundOriginsArray

new CurrentPositionInArray
new NumberOfOrigins

stock ROGInitialize(Float:MinDistance, const CheckFunction[] = "")
{
	new i
	if(DefaultMapEntitiesArray == Invalid_Array)
	{
		//We find the origin of default map entities and search around this places
		DefaultMapEntitiesArray = ArrayCreate()
		for(i = 0; i < sizeof PrimaryDefaultMapEntities; i++)
		{
			if(!AddEntityIfFound(PrimaryDefaultMapEntities[i]))
			{
				if(i < 2)
				{
					AddEntityIfFound(SecondaryDefaultMapEntities[i])
				}
			}
		}
	}
	
	new Size = ArraySize(DefaultMapEntitiesArray)
	if(Size)
	{
		new Float:EntityOrigin[3], EntityIndex
		if(FoundOriginsArray == Invalid_Array)
		{
			FoundOriginsArray = ArrayCreate(3)
		}
		else 
		{
			//Support for multiple calls for ROGInitialize
			ArrayClear(FoundOriginsArray)
		}
		
		for(i = 0; i < Size; i++)
		{
			EntityIndex = ArrayGetCell(DefaultMapEntitiesArray, i)
			new class[32]
			pev(EntityIndex, pev_classname, class, 31)
			
			if(class[0] == 'i')
			{
				pev(EntityIndex, pev_origin, EntityOrigin)
			}
			else 
			{
				get_brush_entity_origin(EntityIndex, EntityOrigin)
			}
			
			SearchForOrigins(EntityOrigin, 5000.0, CheckFunction, Float:MinDistance)
		}
	}
}

stock ROGGetOrigin(Float:Origin[3])
{
	if(CurrentPositionInArray >= ArraySize(FoundOriginsArray))
	{
		CurrentPositionInArray = 0
	}
	
	ArrayGetArray(FoundOriginsArray, CurrentPositionInArray, Origin)
	CurrentPositionInArray = CurrentPositionInArray + 1
}

stock ROGShuffleOrigins()
{
	new Size = ArraySize(FoundOriginsArray), j, Float:FirstOrigin[3], Float:SecondOrigin[3]
	for (new i = Size - 1; i > 0; i--)
	{
		j = random_num(0, i)
		ArrayGetArray(FoundOriginsArray, i, FirstOrigin)
		ArrayGetArray(FoundOriginsArray, j, SecondOrigin)
		ArraySetArray(FoundOriginsArray, i, SecondOrigin)
		ArraySetArray(FoundOriginsArray, j, FirstOrigin)
	}
}

stock ROGDumpOriginData()
{
	new Float:EntityOrigin[3], i
	new Size = ArraySize(FoundOriginsArray)
	
	for(i = 0; i < Size; i++)
	{
		ArrayGetArray(FoundOriginsArray, i, EntityOrigin)
		server_print("[%d] %f %f %f", i, EntityOrigin[0], EntityOrigin[1], EntityOrigin[2])
	}
	
	server_print("Generated %d random origins", i)
	NumberOfOrigins = i
}

stock AddEntityIfFound(const ClassName[])
{
	new Entity = find_ent_by_class(-1, ClassName)
	if(pev_valid(Entity))
	{
		ArrayPushCell(DefaultMapEntitiesArray, Entity)
		return 1
	}
	
	return 0
}

stock SearchForOrigins(Float:ReferenceOrigin[3], Float:Radius, const CheckFunction[], Float:MinDistance)
{
	new Float:RandomOrigin[3], Float:SkyOrigin[3], Float:FloorOrigin[3], Float:PlaneNormal[3], Float:BackupOrigin[3], j
	new CallState, CallReturnValue
	
	new Array:test = ArrayCreate(3)
	
	for(new i = 1; i <= 10000; i++)
	{
		RandomOrigin = ReferenceOrigin
		for(j = 0; j < 3; j++)
		{
			//Get a random origin starting from a reference point
			RandomOrigin[j] += random_float((-1) * Radius, Radius)
		}
		
		//Detect the floor, so we don't spawn the player in air
		FloorOrigin[0] = RandomOrigin[0]
		FloorOrigin[1] = RandomOrigin[1]
		FloorOrigin[2] = -8192.0
		
		BackupOrigin = RandomOrigin
		
		engfunc(EngFunc_TraceLine, RandomOrigin, FloorOrigin, DONT_IGNORE_MONSTERS, 0, 0)
		get_tr2(0, TR_vecEndPos, RandomOrigin)

		get_tr2(0, TR_vecPlaneNormal, PlaneNormal) 
		if(PlaneNormal[2] < 0.7) 
		{
			//ground is too steep, player will start sliding down most likely
			//also if it's that steep players shouldn't be able to climb it, could be an unreachable spot
			//0.7 seems to be used in the bot navigation code from regamedll
			continue
		}
		
		engfunc(EngFunc_TraceHull, BackupOrigin, RandomOrigin, IGNORE_MONSTERS, HULL_HUMAN, 0, 0)    
		new HitEntity = get_tr2(0, TR_pHit)
		if(pev_valid(HitEntity))
		{
			continue
		}
		
		RandomOrigin[2] += 38.0 //make sure we don't spawn in ground
		
		if(PointContents(RandomOrigin) == CONTENTS_EMPTY)
		{
			if(ValidSpotFound(RandomOrigin))
			{
				//Find where the sky/roof is
				SkyOrigin[0] = RandomOrigin[0]
				SkyOrigin[1] = RandomOrigin[1]
				SkyOrigin[2] = 8192.0
				
				engfunc(EngFunc_TraceLine, RandomOrigin, SkyOrigin, DONT_IGNORE_MONSTERS, 0, 0)
				get_tr2(0, TR_vecEndPos, SkyOrigin)
				
				if(PointContents(SkyOrigin) == CONTENTS_SKY)
				{
					if(get_distance_f(RandomOrigin, SkyOrigin) < 250)
					{
						//On maps like de_dust2 players could spawn on the map texture
						//All this points are less than 249 units from the sky
						//By detecting where the sky is and checking the distance we avoid this scenario
						continue
					}
				}
				
				if(CheckFunction[0] != EOS)
				{
					CallState = callfunc_begin(CheckFunction)
					if(CallState == 1)
					{
						callfunc_push_array(_:RandomOrigin, sizeof(RandomOrigin))
						CallReturnValue = callfunc_end()
						if(!CallReturnValue)
						{
							continue
						}
					}
				}
				
				//Don't add the origin if it's too close to another origin
				new OriginsCount = ArraySize(FoundOriginsArray)
				new Float:OriginToCompare[3]
				new bool:IsTooClose, bool:IsVisible
				new Float:ClosestOrigin[3], Float:MinimumDistance = 9999.9
				
				for(new j  = 0; j < OriginsCount; j++)
				{
					ArrayGetArray(FoundOriginsArray, j, OriginToCompare)
					
					new Float:Distance = get_distance_f(RandomOrigin, OriginToCompare)
					if(Distance < MinDistance)
					{
						IsTooClose = true
						break
					}
					
					if(Distance < MinimumDistance)
					{
						MinimumDistance = Distance;
						ClosestOrigin = OriginToCompare
					}
					
				}
				
				if(!IsTooClose)
				{
					if(MinimumDistance == 9999.9)
					{
						ClosestOrigin = ReferenceOrigin
					}
					
					if(CheckPointsForVisibility(RandomOrigin, ClosestOrigin))
					{
						IsVisible = true
					}
					
					if(IsVisible)
					{
						ArrayPushArray(test, RandomOrigin)
						ArrayPushArray(FoundOriginsArray, RandomOrigin)
					}
				}
			}
		}
	}
	
	ArrayDestroy(test)
}

stock bool:ValidSpotFound(Float:Origin[3])
{
	new HandleTraceHull 
	engfunc(EngFunc_TraceHull, Origin, Origin, DONT_IGNORE_MONSTERS, HULL_HUMAN, 0, HandleTraceHull)    
	if(get_tr2(HandleTraceHull, TR_InOpen) && !(get_tr2(HandleTraceHull, TR_StartSolid) || get_tr2(HandleTraceHull, TR_AllSolid))) 
	{
		return true
	}    
	
	return false
}

CheckPointsForVisibility(Float:RandomOrigin[3], Float:ReferenceOrigin[3])
{	
	new Float:CopyReferenceOrigin[3]; CopyReferenceOrigin = ReferenceOrigin
	new Float:CopyRandomOrigin[3]; CopyRandomOrigin = RandomOrigin
	new Float:InitialRandomOrigin[3], Float:InitialReferenceOrigin[3]
	InitialRandomOrigin = CopyRandomOrigin
	InitialReferenceOrigin = CopyReferenceOrigin
	
	new Float:Fraction, Float:TraceEndOrigin[3]
	for(new i = 0; i < 7; i++)
	{		
		CopyRandomOrigin[2] = CopyRandomOrigin[2] + 100.0
		CopyReferenceOrigin[2] = CopyReferenceOrigin[2] + 100.0
		
		engfunc(EngFunc_TraceLine, InitialRandomOrigin, CopyRandomOrigin, IGNORE_GLASS, -1, 0)
		get_tr2(0, TR_vecEndPos, TraceEndOrigin)
		if(PointContents(TraceEndOrigin) == CONTENTS_SKY)
		{
			break
		}
		
		
		engfunc(EngFunc_TraceLine, InitialReferenceOrigin, CopyReferenceOrigin, IGNORE_GLASS, -1, 0)
		get_tr2(0, TR_vecEndPos, TraceEndOrigin)
		if(PointContents(TraceEndOrigin) == CONTENTS_SKY)
		{
			break
		}
		
		engfunc(EngFunc_TraceLine, CopyRandomOrigin, CopyReferenceOrigin, IGNORE_GLASS, -1, 0)
		get_tr2(0, TR_flFraction, Fraction)
		
		if(Fraction == 1.0)
		{
			return true
		}
	}

	return false
}