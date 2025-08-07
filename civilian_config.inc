// ========================================
// CIVILIAN AI SYSTEM - CONFIGURATION FILE
// ========================================
// Version: 2.0.0
// Author: SA-MP Civilian AI System
// Description: Configuration file for civilian AI system
// ========================================

#if !defined _civilian_config_included
#define _civilian_config_included

// ========================================
// SYSTEM CONFIGURATION
// ========================================

// Update and timing settings
#define CIVILIAN_UPDATE_TIME          (1050)
#define CIVILIAN_RESPAWN      		  (3 * 60000)    // 3 minutes
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

// Player nodes configuration
#define MAX_PLAYER_NODES 			  (60)

// Civilian types
#define CIVILIAN_TYPE_NORMAL    	  (1)
#define CIVILIAN_TYPE_WORKER    	  (2)
#define CIVILIAN_TYPE_SECURITY   	  (3)

// Body disappear timer
#define TIMER_BODY                    (5 * 60000)

// ========================================
// SOUND DETECTION CONFIGURATION
// ========================================

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

// Sound investigation settings
#define SOUND_INVESTIGATION_DISTANCE (60.0)
#define MAX_INVESTIGATING_CIVILIANS  (6)
#define SOUND_COOLDOWN_TIME         (3000)

// ========================================
// CIVILIAN SPAWN LOCATIONS
// ========================================

stock const Float:Civilian_Spawns[][3] =
{
    // Los Santos spawns
    {452.15240, -1671.57471, 26.23418},   // Grove Street area
    {1684.9236, -2244.5581, 13.5469},    // Los Santos Airport
    {1199.3997, -918.1548, 43.1239},     // Downtown LS
    {2169.4102, -1741.6207, 13.3828},    // East Los Santos
    {828.0823, -1361.4166, 13.5391},     // City Hall area
    {1481.0208, -1772.3303, 18.7958},    // Market area
    
    // San Fierro spawns
    {2519.17920, 2748.62646, 9.75808},   // San Fierro Airport
    {2539.03223, 2690.40161, 9.75808},   // SF Airport area 2
    {-1988.8572, 142.7852, 27.6875},     // SF Downtown
    {-2441.2102, 500.8842, 30.0625},     // SF Residential
    {-1820.6311, 618.2634, 35.0156},     // SF Hills
    
    // Las Venturas spawns
    {1699.2617, 1435.1519, 10.7617},     // LV Strip
    {2094.7844, 1235.4707, 10.8203},     // LV Casino area
    {2503.0576, 1240.2736, 10.8203},     // LV East
    {1590.1270, 1021.5208, 10.8203},     // LV North
    
    // Rural areas
    {-318.4862, 1774.8268, 43.6406},     // Angel Pine
    {-227.4022, 2594.4568, 62.8582},     // Palomino Creek
    {2328.8999, -168.0309, 26.1953},     // Tierra Robada
    {692.1465, -605.8536, 16.3359},      // Dillimore
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
	civilian_class_tourist,
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

// System status variables
new bool:CivilianSystemActive = false;
new CivilianSystemStartTime;
new TotalCiviliansSpawned = 0;

// ========================================
// WEAPON DAMAGE CONFIGURATION
// ========================================

// Weapon damage points (kept for security guards)
static const stock s_WeaponsPoints[] = {
	6, 12, 15, 12, 22, 19, 12, 11, 19, 5, 1, 1, 1, 1, 1, 9, 82, 9, 1, 10, 
	20, 1, 25, 21, 39, 29, 19, 38, 23, 20, 29, 29, 17, 49, 63, 82, 82, 1, 
	0, 82, 6, 6, 0, 6, 6, 6, 6, 6, 2, 10, 330, 82, 1, 1, 165
};

// ========================================
// CIVILIAN SKINS CONFIGURATION
// ========================================

// Normal civilian skins (male)
static const CivilianSkins_Male[] = {
	23, 24, 25, 26, 27, 28, 29, 30, 32, 33, 34, 35, 36, 37, 43, 44, 45, 46, 
	47, 48, 50, 51, 52, 57, 58, 59, 60, 61, 62, 66, 67, 68, 70, 72, 73, 78, 
	79, 80, 81, 82, 83, 84, 94, 95, 96, 97, 98, 99, 100, 101, 108, 109, 110, 
	111, 112, 113, 114, 115, 116, 117, 118, 120, 121, 122, 123, 124, 125, 
	126, 127, 128, 132, 133, 134, 135, 136, 137, 142, 143, 144, 146, 147, 
	153, 154, 155, 156, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 
	168, 169, 170, 171, 172, 173, 174, 175, 176, 177, 179, 180, 181, 182, 
	183, 184, 185, 186, 187, 188, 189, 200, 202, 203, 204, 206, 209, 210, 
	212, 213, 217, 220, 221, 222, 223, 227, 228, 229, 230, 234, 235, 236, 
	240, 241, 242, 247, 248, 250, 252, 254, 255, 258, 259, 260, 261, 262
};

// Normal civilian skins (female)
static const CivilianSkins_Female[] = {
	9, 10, 11, 12, 13, 31, 38, 39, 40, 41, 53, 54, 55, 56, 63, 64, 69, 75, 
	76, 77, 85, 87, 88, 89, 90, 91, 92, 93, 129, 130, 131, 138, 140, 141, 
	145, 148, 150, 151, 152, 157, 178, 190, 191, 192, 193, 194, 195, 196, 
	197, 198, 199, 201, 205, 207, 211, 214, 215, 216, 218, 219, 224, 225, 
	226, 231, 232, 233, 237, 238, 243, 244, 245, 246, 251, 256, 257, 263
};

// Worker skins
static const WorkerSkins[] = {
	27, 50, 260, 261, 16, 17, 49, 260, 261
};

// Security/Police skins
static const SecuritySkins[] = {
	71, 280, 281, 282, 283, 284, 285, 286, 287, 288
};

// ========================================
// CIVILIAN ANIMATIONS
// ========================================

// Idle animations
stock const CivilianIdleAnims[][2][32] = {
	{"PED", "IDLE_stance"},
	{"PED", "IDLE_chat"},
	{"PARK", "Tai_Chi_Loop"},
	{"BEACH", "bather"},
	{"DEALER", "DEALER_IDLE"},
	{"SHOP", "SHP_rob_react"},
};

// Walking animations  
stock const CivilianWalkAnims[][2][32] = {
	{"PED", "WALK_player"},
	{"PED", "WALK_old"},
	{"PED", "WALK_shuffle"},
	{"PED", "WALK_gang1"},
	{"PED", "WALK_gang2"},
};

// Greeting animations
stock const CivilianGreetAnims[][2][32] = {
	{"GANGS", "hndshkfa"},
	{"GANGS", "hndshkfb"},
	{"ON_LOOKERS", "wave_loop"},
	{"KISSING", "Playa_Kiss_01"},
	{"KISSING", "Playa_Kiss_02"},
};

// ========================================
// CONFIGURATION FUNCTIONS
// ========================================

stock InitializeCivilianConfig()
{
	// Initialize spawn iterator
	for(new index; index < sizeof(Civilian_Spawns); index++) {
	    Iter_Add(CivilianSpawnsIter, index);
	}
	
	// Reset system variables
	CivilianSystemActive = true;
	CivilianSystemStartTime = gettime();
	TotalCiviliansSpawned = 0;
	civiliancount = 0;
	
	// Initialize player nodes
	for(new playerid = 0; playerid < MAX_PLAYERS; playerid++) {
		CivilianNodeIndex[playerid] = 0;
		for(new node = 0; node < MAX_PLAYER_NODES; node++) {
			PlayerNodesX[playerid][node] = 0.0;
			PlayerNodesY[playerid][node] = 0.0;
			PlayerNodesZ[playerid][node] = 0.0;
		}
	}
	
	print("[Civilian Config] Configuration initialized successfully!");
}

stock GetRandomCivilianSkin(type = civilian_class_normal)
{
	new skin;
	switch(type) {
		case civilian_class_normal: {
			if(random(2)) {
				skin = CivilianSkins_Male[random(sizeof(CivilianSkins_Male))];
			} else {
				skin = CivilianSkins_Female[random(sizeof(CivilianSkins_Female))];
			}
		}
		case civilian_class_worker: {
			skin = WorkerSkins[random(sizeof(WorkerSkins))];
		}
		case civilian_class_security: {
			skin = SecuritySkins[random(sizeof(SecuritySkins))];
		}
		default: {
			skin = CivilianSkins_Male[random(sizeof(CivilianSkins_Male))];
		}
	}
	return skin;
}

stock GetRandomCivilianAnimation(type = 0)
{
	new animLib[32], animName[32];
	switch(type) {
		case 0: { // Idle
			new idx = random(sizeof(CivilianIdleAnims));
			format(animLib, sizeof(animLib), "%s", CivilianIdleAnims[idx][0]);
			format(animName, sizeof(animName), "%s", CivilianIdleAnims[idx][1]);
		}
		case 1: { // Walking
			new idx = random(sizeof(CivilianWalkAnims));
			format(animLib, sizeof(animLib), "%s", CivilianWalkAnims[idx][0]);
			format(animName, sizeof(animName), "%s", CivilianWalkAnims[idx][1]);
		}
		case 2: { // Greeting
			new idx = random(sizeof(CivilianGreetAnims));
			format(animLib, sizeof(animLib), "%s", CivilianGreetAnims[idx][0]);
			format(animName, sizeof(animName), "%s", CivilianGreetAnims[idx][1]);
		}
	}
	
	new result[64];
	format(result, sizeof(result), "%s|%s", animLib, animName);
	return result;
}

// ========================================
// DEBUG AND MONITORING
// ========================================

stock GetActiveCiviliansCount()
{
	new count = 0;
	for(new npcid = 0; npcid <= GetPlayerPoolSize(); npcid++) {
		if(FCNPC_IsValid(npcid) && !CivilianInfo[npcid][civilian_inactive]) {
			count++;
		}
	}
	return count;
}

stock ShowCivilianStats(playerid)
{
	new stats[512];
	new active = GetActiveCiviliansCount();
	new uptime = gettime() - CivilianSystemStartTime;
	
	format(stats, sizeof(stats), 
		"=== CIVILIAN AI STATISTICS ===\n\
		Sistema Ativo: %s\n\
		Civis Ativos: %d/%d\n\
		Total Spawnados: %d\n\
		Uptime: %d segundos\n\
		Classes Registradas: %d\n\
		Security Guards: %d",
		CivilianSystemActive ? "Sim" : "Não",
		active, MAX_CIVILIANS,
		TotalCiviliansSpawned,
		uptime,
		index_class,
		index_security
	);
	
	ShowPlayerDialog(playerid, 9999, DIALOG_STYLE_MSGBOX, "Civilian AI Stats", stats, "OK", "");
}

#endif // _civilian_config_included