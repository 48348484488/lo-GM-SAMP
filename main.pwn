#pragma dynamic 28000

// Disable warnings from ZeeX compiler
#pragma warning disable 239
#pragma warning disable 214

// ========================================
// SCRIPT INFORMATION
// ========================================
#define NAME_VERSION "v2.0.0"
#define SCRIPT_NAME "Civilian AI System"

// ========================================
// CORE INCLUDES
// ========================================

// SA-MP includes
#include "		../include/a_samp     	"
#include "		../include/core       	"
#include "		../include/float      	"
#include "		../include/string     	"
#include "		../include/file       	"
#include "		../include/time       	"
#include "		../include/datagram   	"
#include "		../include/a_players  	"
#include "		../include/a_vehicles 	"
#include "		../include/a_objects  	"
#include "		../include/a_actor    	"
#include "		../include/a_sampdb   	"
#include "		../include/easynick   	"
#include "      ../include/sql_easy     "
#include "      ../include/cuff     	"

// External libraries
#include <sscanf2>
#include "../include/streamer"
#include <FCNPC>
#include <FCNPC_Add>
#include <zcmd>
#include <YSF>
#include <YSI_Data\y_iterate>
#include <colandreas>

// ========================================
// CIVILIAN SYSTEM INCLUDES
// ========================================
#include "civilian_config.inc"
#include "civilian_utils.inc"
#include "civilian_classes.inc"
#include "civilian_pathfinding.inc"
#include "civilian_ai.inc"

// ========================================
// MAIN SYSTEM INITIALIZATION
// ========================================

public OnGameModeInit()
{
	print("========================================");
	print("  " SCRIPT_NAME " " NAME_VERSION);
	print("  Initializing civilian AI system...");
	print("========================================");
	
	// Initialize ColAndreas for pathfinding
	CA_RemoveBarriers();
	CA_Init();
	
	// Setup civilian system
	Civilian_Init();
	
	// NPC update settings
	FCNPC_SetUpdateRate(70);
	FCNPC_SetTickRate(10);
	
	print("[Civilian AI] System initialized successfully!");
	print("========================================");
	return 1;
}

public OnGameModeExit()
{
	print("[Civilian AI] System shutting down...");
	Civilian_Exit();
	return 1;
}

// ========================================
// PLAYER CALLBACKS
// ========================================

public OnPlayerConnect(playerid)
{
	Civilian_OnPlayerConnect(playerid);
	return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
	Civilian_OnPlayerDisconnect(playerid, reason);
	return 1;
}

public OnPlayerUpdate(playerid)
{
	Civilian_OnPlayerUpdate(playerid);
	return 1;
}

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	Civilian_OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, fX, fY, fZ);
	
	#if defined Civilian_OnPlayerWeaponShot_Custom
	    return Civilian_OnPlayerWeaponShot_Custom(playerid, weaponid, hittype, hitid, fX, fY, fZ);
	#else
    	return 1;
	#endif
}

#if defined _ALS_OnPlayerWeaponShot
	#undef OnPlayerWeaponShot
#else
	#define _ALS_OnPlayerWeaponShot
#endif
#define OnPlayerWeaponShot Civilian_OnPlayerWeaponShot_Custom
#if defined Civilian_OnPlayerWeaponShot_Custom
	forward Civilian_OnPlayerWeaponShot_Custom(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ);
#endif

public OnPlayerStreamIn(playerid, forplayerid)
{
	Civilian_OnPlayerStreamIn(playerid, forplayerid);
	return 1;
}

// ========================================
// NPC CALLBACKS
// ========================================

public FCNPC_OnUpdate(npcid)
{
	return Civilian_FCNPC_OnUpdate(npcid);
}

public FCNPC_OnMovementEnd(npcid)
{
	return Civilian_FCNPC_OnMovementEnd(npcid);
}

public FCNPC_OnRespawn(npcid)
{
	return Civilian_FCNPC_OnRespawn(npcid);
}

public FCNPC_OnSpawn(npcid)
{
	return Civilian_FCNPC_OnSpawn(npcid);
}

public FCNPC_OnDeath(npcid, killerid, reason)
{
	return Civilian_FCNPC_OnDeath(npcid, killerid, reason);
}

public FCNPC_OnTakeDamage(npcid, issuerid, Float:amount, weaponid, bodypart)
{
	return Civilian_FCNPC_OnTakeDamage(npcid, issuerid, amount, weaponid, bodypart);
}

// ========================================
// ADMIN COMMANDS (Optional)
// ========================================

CMD:civilianinfo(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Você não tem permissão!");
	
	new info[256];
	format(info, sizeof(info), "[Civilian AI] Versão: %s | Civis ativos: %d/%d", 
		NAME_VERSION, GetActiveCiviliansCount(), MAX_CIVILIANS);
	SendClientMessage(playerid, 0x00FF00FF, info);
	return 1;
}

CMD:respawncivilians(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Você não tem permissão!");
	
	RespawnAllCivilians();
	SendClientMessage(playerid, 0x00FF00FF, "[Civilian AI] Todos os civis foram respawnados!");
	return 1;
}

CMD:civilianstats(playerid, params[])
{
	if(!IsPlayerAdmin(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Você não tem permissão!");
	
	ShowCivilianStats(playerid);
	return 1;
}

// ========================================
// END OF MAIN FILE
// ========================================