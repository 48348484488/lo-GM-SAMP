#pragma dynamic 28000

// Disable warnings from ZeeX compiler
#pragma warning disable 239
#pragma warning disable 214

// ========================================
// INCLUDES
// ========================================

// Local version includes
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

// External includes
#include <sscanf2>          			//   http://forum.sa-mp.com/showthread.php?t=570927
#include "../include/streamer"
#include <FCNPC>
#include <FCNPC_Add>
#include <zcmd>
#include <YSF>
#include <YSI_Data\y_iterate>
#include <colandreas>

// ========================================
// SCRIPT INFORMATION
// ========================================
#define NAME_VERSION "v2.0.0"
#define SCRIPT_NAME "Civilian AI System"

// ========================================
// CIVILIAN SYSTEM CONFIGURATION
// ========================================

// Update and timing settings
#define CIVILIAN_UPDATE_TIME          (1050)
#define CIVILIAN_RESPAWN      		  (3 * 60000)
#define NODES_MIN_DISTANCE 			  (1.000)
#define MAX_CIVILIANS 				  (380)
#define MAX_CIVILIANS_NEAR_PLAYER     (15)
#define CIVILIAN_SPEED				  (0.0048)
#define CIVILIAN_DETECTION_DISTANCE   (25.00)
#define CIVILIAN_INTERACTION_DISTANCE (3.500)
#define NODE_MAX_DISTANCE   		  (160.0)
#define CIVILIAN_LIMIT_NODES  		  (350)
#define MAX_VEHICLE_FUEL              (35)
#define SERVER_RESTART_TIME           (3 * (60 * 60))
#define SERVER_AUTO_MSG_TIME          (2 * 80)

// Sound detection heights
#define SOUND_WALK_HEIGHT 		(20.0)
#define SOUND_RUN_HEIGHT 		(45.0)
#define SOUND_GUNSHOT_HEIGHT 	(80.0)
#define SOUND_WHISTLE_HEIGHT 	(55.0)
#define SOUND_RADIO_HEIGHT 		(30.0)
#define SOUND_VEHICLE_HEIGHT 	(75.0)

// Maximum sound heights
#define MAX_SOUND_WALK_HEIGHT 	(7.0)
#define MAX_SOUND_RUN_HEIGHT 	(11.0)
#define MAX_SOUND_GUNSHOT_HEIGHT (14.0)
#define MAX_SOUND_WHISTLE_HEIGHT (13.0)
#define MAX_SOUND_RADIO_HEIGHT 	(8.0)
#define MAX_SOUND_VEHICLE_HEIGHT (14.0)

// Player nodes configuration
#define MAX_PLAYER_NODES 			(60)

// Civilian types
#define CIVILIAN_TYPE_NORMAL    	(1)
#define CIVILIAN_TYPE_WORKER    	(2)
#define CIVILIAN_TYPE_SECURITY   	(3)

// Body disappear timer
#define TIMER_BODY                  (5 * 60000)

// ========================================
// CIVILIAN SPAWN LOCATIONS
// ========================================
stock const Float:Civilian_Spawns[][3] =
{
    {452.15240, -1671.57471, 26.23418},
    {2519.17920, 2748.62646, 9.75808},
    {2539.03223, 2690.40161, 9.75808}
};
new Iterator:CivilianSpawnsIter<sizeof(Civilian_Spawns)>;

// ========================================
// CIVILIAN DATA STRUCTURES
// ========================================

enum civilian_Enum {
	civilian_id,
	civilian_target_player,
	civilian_pause,
	civilian_pause_init,
	civilian_inactive,
	civilian_speaking,
	civilian_investigating_sound,
	civilian_observing,
	civilian_walktime,
	civilian_class,
	civilian_class_default,
	civilian_lastupdate,
	civilian_interaction_delay,
	Float:civilian_health,
	Float:civilian_velocity,
	Float:civilian_detection,
	Float:civilian_interaction_range,
	Float:civilian_spawnx,
	Float:civilian_spawny,
	Float:civilian_spawnz,
	Float:civilian_lastx,
	Float:civilian_lasty,
	Float:civilian_lastz,
	civilian_movtype,
	Float:civilian_movspeed,
}
new CivilianInfo[MAX_PLAYERS][civilian_Enum];

// Civilian class types
enum {
	civilian_class_normal,
	civilian_class_worker,
	civilian_class_security,
	civilian_class_shopkeeper,
	civilian_class_pedestrian,
}

#define MAX_CIVILIAN_CLASSES 75
new index_class = 0;
new index_security = 0;

enum civilianClassEnumInfo {
	// Class ID
	civilian_class_id,
	
	// Skin for this class
	civilian_class_skin,
	
	// Health/resistance
	Float:civilian_class_health,
	
	// Detection range
	Float:civilian_class_detection,
	
	// Interaction range
	Float:civilian_class_interaction_range,
	
	// Interaction delay
	civilian_class_interaction_delay,
	
	// Weapon (for security only)
	civilian_class_weapon,
	
	// Movement type
	civilian_class_movtype,
	
	// Movement speed
	Float:civilian_class_movspeed,
}
new CivilianClassInfo[MAX_CIVILIAN_CLASSES][civilianClassEnumInfo];

// ========================================
// GLOBAL VARIABLES
// ========================================
new tickSound;
new civiliancount;
new CivilianNodeIndex[MAX_PLAYERS];
new Float:PlayerNodesX[MAX_PLAYERS][MAX_PLAYER_NODES];
new Float:PlayerNodesY[MAX_PLAYERS][MAX_PLAYER_NODES];
new Float:PlayerNodesZ[MAX_PLAYERS][MAX_PLAYER_NODES];

// Weapon damage points (kept for security guards)
static const stock s_WeaponsPoints[] = {
	6, 12, 15, 12, 22, 19, 12, 11, 19, 5, 1, 1, 1, 1, 1, 9, 82, 9, 1, 10, 20, 1, 25, 21, 39, 29, 19, 38, 23, 20, 29, 29, 17, 49, 63, 82, 82, 1, 0, 82, 6, 6, 0, 6, 6, 6, 6, 6, 2, 10, 330, 82, 1, 1, 165
};

// ========================================
// MAIN SYSTEM INITIALIZATION
// ========================================

public OnGameModeInit()
{
	print("========================================");
	print("  " SCRIPT_NAME " " NAME_VERSION);
	print("  Initializing civilian AI system...");
	print("========================================");
	
	// Setup civilian classes
	SetupCivilianClasses();
	
	// Remove barriers for pathfinding
	CA_RemoveBarriers();
	
	// Initialize ColAndreas
	CA_Init();
	
	// Initialize civilians
	print("[Civilian AI] Starting civilian spawning...");
	InitializeCivilians();
	
	// NPC update settings
	FCNPC_SetUpdateRate(70);
	FCNPC_SetTickRate(10);
	
	print("[Civilian AI] System initialized successfully!");
	return 1;
}

// ========================================
// UTILITY FUNCTIONS
// ========================================

Float:GetPointDistanceToPoint(Float:x1,Float:y1,Float:z1,Float:x2,Float:y2,Float:z2)
{
	new Float:x, Float:y, Float:z;
 	x = x1-x2;
  	y = y1-y2;
  	z = z1-z2;
  	return floatsqroot(x*x+y*y+z*z);
}

Float:GetPointAngleToPoint(Float:x1, Float:y1, Float:x2, Float:y2) {
    return 180.0 - atan2(x1 - x2, y1 - y2);
}

// ========================================
// CIVILIAN MANAGEMENT FUNCTIONS
// ========================================

stock ConnectCivilianToServer(world=0) {
	new c_name[MAX_PLAYER_NAME];
	format(c_name, sizeof(c_name), "civilian_%d_%d", civiliancount++, gettime());
	
	new civilian_id = FCNPC_Create(c_name);
	
    if (civilian_id != INVALID_PLAYER_ID) {
	    // Initialize civilian data
	    CivilianInfo[civilian_id][civilian_health] 	  		= 100.0;
	    CivilianInfo[civilian_id][civilian_id]     	  		= civilian_id;
	    CivilianInfo[civilian_id][civilian_target_player]      = INVALID_PLAYER_ID;
	    CivilianInfo[civilian_id][civilian_pause_init]  		= GetTickCount() + 10000;
	    CivilianInfo[civilian_id][civilian_investigating_sound] = 0;
	    CivilianInfo[civilian_id][civilian_observing]  		= 0;
	    CivilianInfo[civilian_id][civilian_lastupdate]  		= GetTickCount() + 10000;
	    
	    // Select random spawn location
	    new random_spawn = Iter_Random(CivilianSpawnsIter);
	    if (random_spawn != -1) {
	    	Iter_Remove(CivilianSpawnsIter, random_spawn);
		} else {
            random_spawn = random(sizeof(Civilian_Spawns));
		}
		
	    CivilianInfo[civilian_id][civilian_spawnx] = Civilian_Spawns[random_spawn][0];
	    CivilianInfo[civilian_id][civilian_spawny] = Civilian_Spawns[random_spawn][1];
	    CivilianInfo[civilian_id][civilian_spawnz] = Civilian_Spawns[random_spawn][2];
	    
	    // Adjust Z coordinate to ground level
	    CA_RayCastLine(CivilianInfo[civilian_id][civilian_spawnx], CivilianInfo[civilian_id][civilian_spawny], CivilianInfo[civilian_id][civilian_spawnz], 
	    			   CivilianInfo[civilian_id][civilian_spawnx], CivilianInfo[civilian_id][civilian_spawny], CivilianInfo[civilian_id][civilian_spawnz] - 100.0,
	    			   CivilianInfo[civilian_id][civilian_spawnx], CivilianInfo[civilian_id][civilian_spawny], CivilianInfo[civilian_id][civilian_spawnz]);
	    
	    CivilianInfo[civilian_id][civilian_spawnz] += 1.0;
		CivilianInfo[civilian_id][civilian_velocity] = FCNPC_MOVE_SPEED_WALK;
		
	    // Spawn civilian with default skin
	    FCNPC_Spawn(civilian_id, 23, CivilianInfo[civilian_id][civilian_spawnx], CivilianInfo[civilian_id][civilian_spawny], CivilianInfo[civilian_id][civilian_spawnz]);
	    FCNPC_SetVirtualWorld(civilian_id, world);
	    RespawnCivilian(civilian_id);
	}
	return civilian_id;
}

stock InitializeCivilians()
{
	// Initialize spawn iterator
	for(new index; index < sizeof(Civilian_Spawns); index++) {
	    Iter_Add(CivilianSpawnsIter, index);
	}
	
	// Create all civilians
	for(new c; c != MAX_CIVILIANS; c++) {
	    ConnectCivilianToServer();
	}
}

// ========================================
// CIVILIAN CLASS SYSTEM
// ========================================

stock SetupCivilianClasses() {
	print("[Civilian AI] Setting up civilian classes...");
	
	// Normal civilians
    AddCivilianClass(civilian_class_normal, 23, 100.0, 0, 20.0);      // Regular male
    AddCivilianClass(civilian_class_normal, 93, 100.0, 0, 20.0);      // Regular female
    AddCivilianClass(civilian_class_normal, 169, 100.0, 0, 20.0);     // Casual male
    AddCivilianClass(civilian_class_normal, 191, 100.0, 0, 20.0);     // Business man
    
    // Workers
    AddCivilianClass(civilian_class_worker, 27, 100.0, 0, 15.0);      // Construction worker
    AddCivilianClass(civilian_class_worker, 50, 100.0, 0, 15.0);      // Mechanic
    
    // Security (can have weapons)
    AddCivilianClass(civilian_class_security, 71, 150.0, 24, 25.0, 2.0, 1000); // Security guard with Deagle
    
    print("[Civilian AI] Civilian classes configured successfully!");
}

stock AddCivilianClass(classid, skinid, Float:health, weaponid, Float:detection, Float:interaction_range = 1.5, interaction_delay = 2000, movtype = FCNPC_MOVE_TYPE_WALK, Float:movspeed = 0.25) {
    CivilianClassInfo[index_class][civilian_class_id] = classid;
    CivilianClassInfo[index_class][civilian_class_health] = health;
    CivilianClassInfo[index_class][civilian_class_skin] = skinid;
    CivilianClassInfo[index_class][civilian_class_weapon] = weaponid;
    CivilianClassInfo[index_class][civilian_class_detection] = detection;
    CivilianClassInfo[index_class][civilian_class_interaction_range] = interaction_range;
    CivilianClassInfo[index_class][civilian_class_interaction_delay] = interaction_delay;
    CivilianClassInfo[index_class][civilian_class_movtype] = movtype;
    CivilianClassInfo[index_class][civilian_class_movspeed] = movspeed;

	index_class++;

	if (classid == civilian_class_security) {
	    index_security++;
	}
}

// ========================================
// CIVILIAN RESPAWN SYSTEM
// ========================================

forward RespawnCivilianWorld(npcid);
public RespawnCivilianWorld(npcid) {
	if (npcid < 0 || npcid >= MAX_PLAYERS) return 0;
	FCNPC_Respawn(npcid);
	return 1;
}

forward RespawnCivilian(npcid);
public RespawnCivilian(npcid)
{
	if (npcid < 0 || npcid >= MAX_PLAYERS) return 0;

	printf("[Civilian AI] Spawned civilian ID: %d", npcid);

	// Select random class (excluding security for normal spawns)
	new randClass = random(index_class - index_security);

	if (CivilianInfo[npcid][civilian_class] == civilian_class_security) {
	    randClass = CivilianInfo[npcid][civilian_class_default];
	}

	// Reset civilian if inactive
	if (CivilianInfo[npcid][civilian_inactive]) {
		FCNPC_SetWeapon(npcid, 0);
	}

	// Set skin and health
	FCNPC_SetSkin(npcid, CivilianClassInfo[randClass][civilian_class_skin]);
	FCNPC_SetHealth(npcid, CivilianClassInfo[randClass][civilian_class_health]);

	// Remove weapons (except for security)
	if (CivilianClassInfo[randClass][civilian_class_id] != civilian_class_security) {
		FCNPC_SetWeapon(npcid, 0);
	} else {
		FCNPC_SetWeapon(npcid, CivilianClassInfo[randClass][civilian_class_weapon]);
	}

	// Set position
	FCNPC_SetPosition(npcid, CivilianInfo[npcid][civilian_spawnx], CivilianInfo[npcid][civilian_spawny], CivilianInfo[npcid][civilian_spawnz]);

	// Initialize civilian properties
  	CivilianInfo[npcid][civilian_health]    			= CivilianClassInfo[randClass][civilian_class_health];
  	CivilianInfo[npcid][civilian_detection] 			= CivilianClassInfo[randClass][civilian_class_detection];
  	CivilianInfo[npcid][civilian_interaction_range]   	= CivilianClassInfo[randClass][civilian_class_interaction_range];
  	CivilianInfo[npcid][civilian_interaction_delay]	= CivilianClassInfo[randClass][civilian_class_interaction_delay];
  	CivilianInfo[npcid][civilian_movtype]   			= CivilianClassInfo[randClass][civilian_class_movtype];
  	CivilianInfo[npcid][civilian_movspeed]  			= CivilianClassInfo[randClass][civilian_class_movspeed];
  	CivilianInfo[npcid][civilian_class]     			= CivilianClassInfo[randClass][civilian_class_id];
  	CivilianInfo[npcid][civilian_class_default]			= randClass;
  	CivilianInfo[npcid][civilian_inactive]      		= 0;
  	CivilianInfo[npcid][civilian_walktime]  			= gettime() + (5 + random(12));
	return 1;
}

// ========================================
// CIVILIAN AI UPDATE SYSTEM
// ========================================

public FCNPC_OnUpdate(npcid)
{
	new currentTick = GetTickCount();
	if (CivilianInfo[npcid][civilian_lastupdate] < currentTick)
	{
        CivilianInfo[npcid][civilian_lastupdate] = currentTick + (190 + random(70));

		// Skip if civilian is inactive or dead
		if (CivilianInfo[npcid][civilian_inactive]) return 1;
		if (FCNPC_IsDead(npcid)) return 1;
	 	if (CivilianInfo[npcid][civilian_pause] > currentTick) return 1;
		if (CivilianInfo[npcid][civilian_pause_init] > currentTick) return 1;
		if (!FCNPC_IsStreamedInForAnyone(npcid)) return 1;

		// Update civilian behavior based on current state
		if (CivilianInfo[npcid][civilian_target_player] != INVALID_PLAYER_ID) {
        	UpdateCivilianInteraction(npcid, CivilianInfo[npcid][civilian_target_player]);
		} else {
		    UpdateCivilianIdleMovements(npcid);
		}

        // Civilian speaking/greeting sounds
		if(CivilianInfo[npcid][civilian_speaking] < GetTickCount() && CivilianInfo[npcid][civilian_class] != civilian_class_security) {
		    static Float:pos[3];
		    FCNPC_GetPosition(npcid, pos[0], pos[1], pos[2]);
		    CivilianInfo[npcid][civilian_speaking] = GetTickCount() + (15000 + random(20000));
		    // Could add greeting sounds here
		}
	}
	return 1;
}

// Movement end callback
public FCNPC_OnMovementEnd(npcid) {
	if (CivilianInfo[npcid][civilian_inactive]) return 0;

	if (CivilianInfo[npcid][civilian_target_player] == INVALID_PLAYER_ID) {
		FCNPC_ClearAnimations(npcid);
		FCNPC_ApplyAnimation(npcid, "PED", "IDLE_stance", 4.1, 1, 1, 1, 1, 0);

		if(CivilianInfo[npcid][civilian_investigating_sound]) {
			FCNPC_Stop(npcid);
			// When reaching sound location, look around
	   		CivilianInfo[npcid][civilian_observing] = 1;
	   		CivilianInfo[npcid][civilian_walktime] = gettime() + (5 + random(12));
		}
	}
	return 1;
}

// Respawn callback
public FCNPC_OnRespawn(npcid) {
    RespawnCivilian(npcid);
	return 1;
}

// ========================================
// CIVILIAN BEHAVIOR FUNCTIONS
// ========================================

stock UpdateCivilianInteraction(civilian, playerid)
{
	// Get closest player to civilian
	new Float:currentDistanceBetween;
	new currentClosestPlayer = GetClosestPlayerToCivilian(civilian, currentDistanceBetween);
	new civilianTargetPlayer = CivilianInfo[civilian][civilian_target_player];

	// Switch to closer player if in detection range
	if (currentClosestPlayer != playerid && IsCivilianViewingPlayer(civilian, currentClosestPlayer))
    {
	    CivilianInfo[civilian][civilian_target_player] = currentClosestPlayer;
	    civilianTargetPlayer = currentClosestPlayer;
	}

	// If player is within detection range
	if (currentDistanceBetween < CivilianInfo[civilian][civilian_detection])
    {
        // Count civilians already interacting with this player (prevent overcrowding)
        new countCiviliansNearPlayer = CountCiviliansNearPlayer(civilianTargetPlayer);
		if (countCiviliansNearPlayer >= MAX_CIVILIANS_NEAR_PLAYER && CivilianInfo[civilian][civilian_target_player] != civilianTargetPlayer)
		    return 0;

 	    new Float:pos[6];
 	    GetPlayerPos(civilianTargetPlayer, pos[0], pos[1], pos[2]);
 	    FCNPC_GetPosition(civilian, pos[3], pos[4], pos[5]);

		// If within interaction range
		if (currentDistanceBetween < CivilianInfo[civilian][civilian_interaction_range]) {
			// Security guards might be more alert but still peaceful
			if (CivilianInfo[civilian][civilian_class] == civilian_class_security) {
				if (IsCivilianViewingPlayer(civilian, currentClosestPlayer)) {
					if (FCNPC_IsMoving(civilian))
                    	FCNPC_Stop(civilian);
                    	
                    // Face the player but don't aim weapons
					SetCivilianAngleToPlayer(civilian, civilianTargetPlayer);
					return 1;
				} else {
				    MoveCivilianToPlayer(civilian, civilianTargetPlayer);
				}
			} else {
			    // Regular civilian interaction (friendly greeting)
			    FCNPC_Stop(civilian);
                if (!FCNPC_IsAttacking(civilian))
                   	FCNPC_ClearAnimations(civilian);

				// Friendly gesture animation
				FCNPC_ApplyAnimation(civilian, "GANGS", "hndshkfa", 4.1, 0, 1, 1, 0, 1000);
				SetCivilianAngleToPlayer(civilian, civilianTargetPlayer);
				
				CivilianInfo[civilian][civilian_pause] = GetTickCount() + CIVILIAN_UPDATE_TIME;
			}
			return 1;
 	    }

		// Move towards player if not attacking
		if (!FCNPC_IsAttacking(civilian)) {
		    if (MoveCivilianToPlayer(civilian, civilianTargetPlayer))
        	{
        	    FCNPC_ApplyAnimation(civilian, "PED","WALK_player", 4.1, 1, 1, 1, 1, 0);
        	}
        	else
        	{
        	    if (FCNPC_IsMoving(civilian))
        	        FCNPC_Stop(civilian);
        	    FCNPC_ApplyAnimation(civilian, "PED", "IDLE_stance", 4.1, 1, 1, 1, 1, 0);
        	}
		}
	} else {
        // Stop following player
        StopCivilianInteraction(civilian);
	}
	return 1;
}

stock UpdateCivilianIdleMovements(civilian) {
	// Check if it's time to move
	if (gettime() > CivilianInfo[civilian][civilian_walktime] && !CivilianInfo[civilian][civilian_investigating_sound]) {
	    UpdateCivilianMovements(civilian);
	    CivilianInfo[civilian][civilian_walktime] = gettime() + (15 + random(25)); // Longer idle time
	}

	// Check for nearby players to potentially interact with
	new Float:currentDistanceBetween;
	new currentClosestPlayer = GetClosestPlayerToCivilian(civilian, currentDistanceBetween);
	
	if (currentClosestPlayer != INVALID_PLAYER_ID && currentDistanceBetween < CivilianInfo[civilian][civilian_detection] && IsCivilianViewingPlayer(civilian, currentClosestPlayer)) {
	    CivilianInfo[civilian][civilian_target_player] = currentClosestPlayer;
	    CivilianInfo[civilian][civilian_investigating_sound] = 0;
	    CivilianInfo[civilian][civilian_observing] = 0;
	}
}

// ========================================
// CIVILIAN UTILITY FUNCTIONS  
// ========================================

stock GetClosestPlayerToCivilian(npcid, &Float:distance = 0.0) {
	new player = INVALID_PLAYER_ID;
	new Float:dist = 99999.00;
	new Float:x, Float:y, Float:z, Float:pos;
	FCNPC_GetPosition(npcid, x, y, z);

	foreach(new playerid : Player) {
		if (GetPlayerVirtualWorld(playerid) != 0 || GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
		    continue;

		if (IsPlayerInAnyVehicle(playerid))
		    continue;

	    if ((pos = GetPlayerDistanceFromPoint(playerid, x, y, z)) < dist)
		{
	        player = playerid;
	        dist = pos;
	    }
	}
	distance = dist;
	return player;
}

stock IsCivilianViewingPlayer(civilian, playerid) {
	static Float:x, Float:y, Float:z, Float:cx, Float:cy, Float:cz;

	FCNPC_GetPosition(civilian, cx, cy, cz);
	GetPlayerPos(playerid, x, y, z);

	// Less strict viewing angle for civilians (they're more aware)
	if (!IsCivilianFacingPlayer(civilian, x, y, cx, cy, 120.0) && GetPlayerOnfootSpeed(playerid) < 8)
	    return 0;

	// Check for obstacles
	if (CA_RayCastLine(x, y, z, cx, cy, cz, x, x, x))
	    return 0;

	return 1;
}

stock CountCiviliansNearPlayer(playerid) {
	new count;

	for (new c = GetPlayerPoolSize(), civilian; civilian <= c; civilian++) {
		if (!FCNPC_IsValid(civilian))
		    continue;

		if (CivilianInfo[civilian][civilian_target_player] == playerid) {
			// Adjust civilian speed based on crowd
			CivilianInfo[civilian][civilian_velocity] = (CivilianInfo[civilian][civilian_movspeed]) - (count * 0.015);

			if (CivilianInfo[civilian][civilian_velocity] < 0.15000)
			    CivilianInfo[civilian][civilian_velocity] = 0.15000;

			count++;
	 	}
	}
	return count;
}

stock MoveCivilianToPlayer(civilian, playerid) {
	static success, nodeid, Float:x, Float:y, Float:z, Float:px, Float:py, Float:pz;

    nodeid = -1;
    success = false;

	FCNPC_GetPosition(civilian, x, y, z);
	GetPlayerPos(playerid, px, py, pz);

    success = CA_TraceLine(civilian, playerid, x, y, z, px, py, pz, .maxnodes = 1);

	if (!success)
	{
		for (new node; node != MAX_PLAYER_NODES; node++)
		{
		    new result = CA_TraceLine(civilian, playerid, x, y, z, PlayerNodesX[playerid][node], PlayerNodesY[playerid][node], PlayerNodesZ[playerid][node], .nodeid = node, .maxnodes = 1);

			if(result == -2) break;

			if (result)
			{
				nodeid = node;
				CivilianInfo[civilian][civilian_lastx] = PlayerNodesX[playerid][node];
				CivilianInfo[civilian][civilian_lasty] = PlayerNodesY[playerid][node];
				CivilianInfo[civilian][civilian_lastz] = PlayerNodesZ[playerid][node];
				break;
		    }
		}
	}

	if (nodeid != -1 || success)
	{
	    FCNPC_CreateMovement(civilian);

	    for(new nodes; nodes < CivilianNodeIndex[civilian]; nodes++)
		{
            FCNPC_AddMovement(civilian, PlayerNodesX[civilian][nodes], PlayerNodesY[civilian][nodes], PlayerNodesZ[civilian][nodes]);
		}

		FCNPC_PlayMovement(civilian, CivilianInfo[civilian][civilian_movtype], CivilianInfo[civilian][civilian_velocity]);
		return 1;
	}
	else
	{
		FCNPC_Stop(civilian);
	}

	return 0;
}

stock SetCivilianAngleToPlayer(npcid, playerid) {
	static Float:cx, Float:cy, Float:cz, Float:px, Float:py, Float:pz, Float:ang, Float:angc;

	FCNPC_GetPosition(npcid, cx, cy, cz);
	GetPlayerPos(playerid, px, py, pz);

	angc = FCNPC_GetAngle(npcid);

	cx -= (5.0 * floatsin(-angc, degrees));
	cy -= (5.0 * floatcos(-angc, degrees));

	ang = GetPointAngleToPoint(cx, cy, px, py);

	cx += (10.0 * floatsin(-ang, degrees));
	cy += (10.0 * floatcos(-ang, degrees));

	FCNPC_SetAngleToPos(npcid, cx, cy);
}

stock StopCivilianInteraction(civilian) {
	if (CivilianInfo[civilian][civilian_target_player] != INVALID_PLAYER_ID) {
	    CivilianInfo[civilian][civilian_target_player] = INVALID_PLAYER_ID;

		FCNPC_Stop(civilian);
		FCNPC_ClearAnimations(civilian);
	    FCNPC_StopAttack(civilian);
	    FCNPC_StopAim(civilian);

	    FCNPC_ApplyAnimation(civilian, "PED", "IDLE_stance", 3.1, 1, 1, 1, 1, 0);
	    CivilianInfo[civilian][civilian_walktime] = gettime() + (8 + random(15));
	}
}

// ========================================
// CIVILIAN MOVEMENT SYSTEM
// ========================================

forward UpdateCivilianMovements(civilian);
public UpdateCivilianMovements(civilian)
{
	new Float:x, Float:y, Float:z, Float:tox, Float:toy, Float:toz;

	FCNPC_GetPosition(civilian, x, y, z);

	// Random movement in area
	tox = x + frandom(8.0) - frandom(8.0);
	toy = y + frandom(8.0) - frandom(8.0);
	toz = z;

	if (CA_TraceLine(civilian, -1, x, y, z, tox, toy, toz, .stepsize = 1.5, .maxnodes = 2)) {
		FCNPC_CreateMovement(civilian);

	    for(new nodes; nodes < CivilianNodeIndex[civilian]; nodes++) {
	        FCNPC_AddMovement(civilian, PlayerNodesX[civilian][nodes], PlayerNodesY[civilian][nodes], PlayerNodesZ[civilian][nodes]);
	    }

	    FCNPC_PlayMovement(civilian, FCNPC_MOVE_TYPE_WALK, .speed = 0.1252086, .delaystop = 0);
	    FCNPC_ApplyAnimation(civilian, "PED","WALK_player", 3.1, 1, 1, 1, 1, 0);
	}

	return 1;
}

stock IsCivilianFacingPlayer(civilianid, Float:pX, Float:pY, Float:X, Float:Y, Float:dOffset)
{
	static Float:pA, Float:ang;

	pA = FCNPC_GetAngle(civilianid);

	if(Y > pY)
		ang = (-acos((X - pX) / floatsqroot((X - pX) * (X - pX) + (Y - pY) * (Y - pY))) - 90.0);
	else if(Y < pY && X < pX)
		ang = (acos((X - pX) / floatsqroot((X - pX) * (X - pX) + (Y - pY) * (Y - pY))) - 450.0);
	else if(Y < pY)
		ang = (acos((X - pX) / floatsqroot((X - pX) * (X - pX) + (Y - pY) * (Y - pY))) - 90.0);

	if(AngleInRangeOfAngleEx(-ang, pA, dOffset))
		return 1;

	return 0;
}

// ========================================
// PATHFINDING SYSTEM
// ========================================

stock CA_TraceLine(civilian, playerid, Float:x, Float:y, Float:z, Float:endx, Float:endy, Float:endz, Float:stepsize=1.45, nodeid = 999, maxnodes = 1)
{
	if (nodeid == 0) {
		static Float:px, Float:py, Float:pz;
		GetPlayerPos(playerid, px, py, pz);
		endx = px; endy = py; endz = pz;
	}

	static Float:tx, Float:ty, Float:tz;

	if (CA_RayCastLine(x, y, z, endx, endy, endz, tx, ty, tz))
		return 0;

    CA_RayCastLine(endx, endy, endz, endx, endy, endz - 50.0, tx, ty, tz);
    tz += 1.0;

    CivilianNodeIndex[civilian] = 0;

	static Float:lastx, Float:lasty, Float:lastz;
	new Float:point_distance = GetPointDistanceToPoint(x, y, z, endx, endy, tz);
	new Float:point_angle = GetPointAngleToPoint(x, y, endx, endy);

	lastx = x; lasty = y; lastz = z;

	if (nodeid != 999)
	{
		if (PlayerNodesX[playerid][nodeid] == CivilianInfo[civilian][civilian_lastx] && point_distance < 1.0)
		{
        	return -2;
		}
	}

	for (new Float:point; point < point_distance; point += stepsize)
	{
		x += (stepsize * floatsin(-point_angle, degrees));
		y += (stepsize * floatcos(-point_angle, degrees));

		if (CA_RayCastLine(x, y, z, x, y, z - 70.0, x, y, z))
			z += 1.1;

		if (!IsPointZValid(z, lastz) || CA_RayCastLine(lastx, lasty, lastz, x, y, z, tz, tz, tz))
			return 0;

		lastx = x; lasty = y; lastz = z;

   		PlayerNodesX[civilian][CivilianNodeIndex[civilian]] = x;
   		PlayerNodesY[civilian][CivilianNodeIndex[civilian]] = y;
   		PlayerNodesZ[civilian][CivilianNodeIndex[civilian]] = z;

   		CivilianNodeIndex[civilian]++;

		if (CivilianNodeIndex[civilian] >= maxnodes) return 1;
	}

	return 1;
}

stock CA_TraceLineEx(civilian, Float:x, Float:y, Float:z, Float:endx, Float:endy, Float:endz, Float:stepsize=1.45, maxnodes = 1)
{
	static Float:a;
    CivilianNodeIndex[civilian] = 0;

	static Float:lastx, Float:lasty, Float:lastz;
	new Float:point_distance = GetPointDistanceToPoint(x, y, z, endx, endy, endz);
	new Float:point_angle = GetPointAngleToPoint(x, y, endx, endy);

	lastx = x; lasty = y; lastz = z;

	for (new Float:point; point < point_distance; point += stepsize)
	{
		x += (stepsize * floatsin(-point_angle, degrees));
		y += (stepsize * floatcos(-point_angle, degrees));

		if (CA_RayCastLine(x, y, z, x, y, z - 70.0, x, y, z))
			z += 1.1;

		if (!IsPointZValid(z, lastz) || CA_RayCastLine(lastx, lasty, lastz, x, y, z, a, a, a))
			return 0;

		lastx = x; lasty = y; lastz = z;

   		PlayerNodesX[civilian][CivilianNodeIndex[civilian]] = x;
   		PlayerNodesY[civilian][CivilianNodeIndex[civilian]] = y;
   		PlayerNodesZ[civilian][CivilianNodeIndex[civilian]] = z;

   		CivilianNodeIndex[civilian]++;

		if (CivilianNodeIndex[civilian] >= maxnodes) return 1;
	}

	return 1;
}

// ========================================
// PLAYER INTERACTION SYSTEM
// ========================================

public OnPlayerUpdate(playerid)
{
	AddPlayerNode(playerid);
	return 1;
}

stock AddPlayerNode(playerid) {
	static Float:x, Float:y, Float:z;
	GetPlayerPos(playerid, x, y, z);

	for(new player_node = MAX_PLAYER_NODES - 1; player_node > 0; player_node--) {
	    PlayerNodesX[playerid][player_node] = PlayerNodesX[playerid][player_node - 1];
	    PlayerNodesY[playerid][player_node] = PlayerNodesY[playerid][player_node - 1];
	    PlayerNodesZ[playerid][player_node] = PlayerNodesZ[playerid][player_node - 1];
	}
	PlayerNodesX[playerid][0] = x;
    PlayerNodesY[playerid][0] = y;
    PlayerNodesZ[playerid][0] = z;

    return 1;
}

// ========================================
// SOUND SYSTEM (for civilian reactions)
// ========================================

public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if (tickSound < GetTickCount()) {
		static Float:x, Float:y, Float:z, Float:w;
		GetPlayerPos(playerid, x, y, z);

		if(!CA_RayCastLine(x, y, z, x, y, z + 100.0, w, w, w)) {
		    CreateSoundDisturbance(x, y, z);
		}
	}

	#if defined c_OnPlayerWeaponShot
	    return c_OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, fX, fY, fZ);
	#else
    	return 1;
	#endif
}

#if defined _ALS_OnPlayerWeaponShot
	#undef OnPlayerWeaponShot
#else
	#define _ALS_OnPlayerWeaponShot
#endif
#define OnPlayerWeaponShot c_OnPlayerWeaponShot
#if defined c_OnPlayerWeaponShot
	forward c_OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ);
#endif

stock CreateSoundDisturbance(Float:x, Float:y, Float:z, Float:distance=60.0)
{
	if (tickSound > GetTickCount()) return 0;
    tickSound = GetTickCount() + 3000;

    new countInvestigatingCivilians = 0;

	for (new cc = GetPlayerPoolSize(), civilian; civilian <= cc; civilian++)
	{
		if (!FCNPC_IsValid(civilian)) continue;
	    if (CivilianInfo[civilian][civilian_inactive]) continue;
	    if (CivilianInfo[civilian][civilian_target_player] != INVALID_PLAYER_ID) continue;

	    if (IsPlayerInRangeOfPoint(civilian, distance, x, y, z))
		{
		    countInvestigatingCivilians++;
		    
			static Float:cPos[3];
			FCNPC_GetPosition(civilian, cPos[0], cPos[1], cPos[2]);

			CA_TraceLineEx(civilian, cPos[0], cPos[1], cPos[2], x, y, z, .stepsize=2.0, .maxnodes = 20);

			if (CivilianNodeIndex[civilian] > 0)
			{
			    FCNPC_CreateMovement(civilian);

			    for(new nodes; nodes < CivilianNodeIndex[civilian]; nodes++)
				{
		            FCNPC_AddMovement(civilian, PlayerNodesX[civilian][nodes], PlayerNodesY[civilian][nodes], PlayerNodesZ[civilian][nodes]);
				}

			    FCNPC_PlayMovement(civilian, FCNPC_MOVE_TYPE_WALK, .speed = 0.15, .delaystop = 0);
			    FCNPC_ApplyAnimation(civilian, "PED","WALK_player", 4.1, 1, 1, 1, 1, 0);
			}

			CivilianInfo[civilian][civilian_investigating_sound] = 1;
			CivilianInfo[civilian][civilian_observing] = 0;
		}
		
		// Limit investigating civilians to prevent performance issues
		if (countInvestigatingCivilians > 6) return 1;
	}
	return 1;
}

// ========================================
// CIVILIAN DAMAGE SYSTEM (minimal, for security guards only)
// ========================================

public FCNPC_OnTakeDamage(npcid, issuerid, Float:amount, weaponid, bodypart) {
	if (CivilianInfo[npcid][civilian_inactive]) return 0;

	// Only security guards can take combat damage, others just flee
	if (CivilianInfo[npcid][civilian_class] != civilian_class_security) {
		// Regular civilians flee when shot at
		if (issuerid != INVALID_PLAYER_ID) {
			CivilianInfo[npcid][civilian_target_player] = INVALID_PLAYER_ID;
			FCNPC_Stop(npcid);
			FCNPC_ApplyAnimation(npcid, "PED", "run_player", 4.1, 1, 1, 1, 1, 0);
			
			// Run away from shooter
			static Float:px, Float:py, Float:pz, Float:cx, Float:cy, Float:cz;
			GetPlayerPos(issuerid, px, py, pz);
			FCNPC_GetPosition(npcid, cx, cy, cz);
			
			new Float:angle = GetPointAngleToPoint(px, py, cx, cy);
			new Float:flee_x = cx + (15.0 * floatsin(-angle, degrees));
			new Float:flee_y = cy + (15.0 * floatcos(-angle, degrees));
			
			FCNPC_GoTo(npcid, flee_x, flee_y, cz, FCNPC_MOVE_TYPE_RUN, 0.36);
		}
		return 0;
	}

	// Security guard damage handling
	amount = ConvertDamage(GetWeaponDamage(weaponid), bodypart) * 1.14524;

	if (weaponid == 34 && bodypart == 9) { // Sniper headshot
 		amount = 255.0;
	}

	CivilianInfo[npcid][civilian_health] -= amount;

	if (CivilianInfo[npcid][civilian_target_player] == INVALID_PLAYER_ID) {
	    FCNPC_Stop(npcid);
		SetCivilianAngleToPlayer(npcid, issuerid);
	}

	if (CivilianInfo[npcid][civilian_health] <= 0.0) {
		static Float:pos[3];
	   	FCNPC_GetPosition(npcid, pos[0], pos[1], pos[2]);

		#if defined OnCivilianDeath
	    	OnCivilianDeath(npcid, issuerid, weaponid);
		#endif

	    CivilianInfo[npcid][civilian_inactive] = 1;
	   	FCNPC_Kill(npcid);
	}
	return 1;
}

public FCNPC_OnDeath(npcid, killerid, reason) {
	if (!CivilianInfo[npcid][civilian_inactive]) {
        OnCivilianDeath(npcid, killerid, reason);
	}
	printf("[Civilian AI] Civilian death: %d", npcid);
	return 1;
}

public FCNPC_OnSpawn(npcid) {
	RespawnCivilian(npcid);
	return 1;
}

public OnPlayerStreamIn(playerid, forplayerid) {
	if (IsPlayerNPC(playerid) && FCNPC_IsDead(playerid)) {
	    FCNPC_Kill(playerid);
	}
	return 1;
}

// ========================================
// CIVILIAN DEATH HANDLING
// ========================================

forward OnCivilianDeath(civilianid, killerid, weaponid);
public OnCivilianDeath(civilianid, killerid, weaponid) {
	print("[Civilian AI] Civilian death event");
	
	if (CivilianInfo[civilianid][civilian_target_player] != INVALID_PLAYER_ID) {
		CivilianInfo[civilianid][civilian_target_player] = INVALID_PLAYER_ID;
	}

	static Float:x, Float:y, Float:z;
	FCNPC_GetPosition(civilianid, x, y, z);

	// Different respawn times based on class
	if (CivilianInfo[civilianid][civilian_class] != civilian_class_security)
	{
		SetTimerEx("RespawnCivilianWorld", CIVILIAN_RESPAWN, false, "i", civilianid);
	} else {
	    SetTimerEx("RespawnCivilianWorld", CIVILIAN_RESPAWN * 2, false, "i", civilianid);
	}

	CivilianInfo[civilianid][civilian_inactive] = 1;
	return 1;
}

// ========================================
// UTILITY FUNCTIONS
// ========================================

stock Float:ConvertDamage(Float:damage, bodypart) {
	new Float:newdamage;

	switch(bodypart) {
	    case 3: {newdamage = damage + 0.0;}         // Torso
	    case 4: {newdamage = damage * 1.40;}        // Chest
	    case 5: {newdamage = damage / 1.10;}        // Left arm
	    case 6: {newdamage = damage / 1.10;}        // Right arm
	    case 7: {newdamage = damage / 1.85;}        // Left leg
	    case 8: {newdamage = damage / 1.85;}        // Right leg
	    case 9: {newdamage = damage * 1.90;}        // Head
	}

	return newdamage;
}

stock Float:GetWeaponDamage(weaponid) {
	if (weaponid < 0 || weaponid >= sizeof(s_WeaponsPoints)) {
	    return 0.0;
	}
	return float(s_WeaponsPoints[weaponid]);
}

stock GetPlayerOnfootSpeed(playerid) {
	static Float:velx, Float:vely, Float:velz;
	GetPlayerVelocity(playerid, velx, vely, velz);
	return floatround(floatsqroot(velx*velx+vely*vely+velz*velz) * 135.00);
}

stock AngleInRangeOfAngleEx(Float:a1, Float:a2, Float:range)
{
	a1 -= a2;
	if((a1 < range) && (a1 > -range)) return true;
	return false;
}

stock IsPointZValid(Float:z1, Float:z2) {
	if ((z2 < z1 - 1.3) || (z2 > z1 + 1.3)) return 0;
	return 1;
}

stock IsFireWeapon(weaponid) {
	switch(weaponid) {
	    case 22..34, 38: return 1;
	}
	return 0;
}

// ========================================
// END OF CIVILIAN AI SYSTEM
// ========================================

