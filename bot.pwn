#pragma dynamic 28000

// disable warnings from ZeeX compiler
#pragma warning disable 239
#pragma warning disable 214

// Includes

// Local versão
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

#define NAME_VERSION "v1.2.4"

// Outras includes
#include <sscanf2>          			//   http://forum.sa-mp.com/showthread.php?t=570927
#include "../include/streamer"
#include <FCNPC>
#include <FCNPC_Add>
#include <zcmd>
#include <YSF>
#include <YSI_Data\y_iterate>
#include <colandreas>

#define ZOMBIE_UPDATE_TIME          (1050)
#define ZOMBIE_RESPAWN      		(3 * 60000)
#define NODES_MIN_DISTANCE 			(1.000) // Aprimora a precisão do movimento, más gasta mais slots de nodes
#define MAX_ZOMBIES 				(380)
#define MAX_ZOMBIES_FOLLOW_PLAYER   (25)
#define RNPC_SPEED_ZOMBIE			(0.0048)
#define ZOMBIE_DISTANCE     		(45.00)
#define ZOMBIE_DAMAGE_DISTANCE      (1.500)
#define ZOMBIE_DAMAGE      			(4.0)
#define NODE_MAX_DISTANCE   		(160.0)
#define ZOMBIE_LIMIT_NODES  		(350)
#define MAX_VEHICLE_FUEL            (35)
#define ZOMBIE_Z_DIFFERENCE_ATTACK 	(3.5)
#define SERVER_RESTART_TIME         (3 * (60 * 60))// em horas
#define SERVER_AUTO_MSG_TIME        (2 * 80)

// alturas de barulho
#define ALTURA_ANDAR 		(20.0)
#define ALTURA_CORRER 		(45.0)
#define ALTURA_TIRO 		(80.0)
#define ALTURA_ASSOBIO 		(55.0)
#define ALTURA_RADIO 		(30.0)
#define ALTURA_CARRO 		(75.0)

#define MAX_ALTURA_ANDAR 	(7.0)
#define MAX_ALTURA_CORRER 	(11.0)
#define MAX_ALTURA_TIRO 	(14.0)
#define MAX_ALTURA_ASSOBIO 	(13.0)
#define MAX_ALTURA_RADIO 	(8.0)
#define MAX_ALTURA_CARRO	(14.0)

// Total de nodes por player
#define MAX_PLAYER_NODES 			(60)

// Tipos de armas
#define WEAPON_TYPE_PRIMARY    		(1)
#define WEAPON_TYPE_SECONDARY  		(2)
#define WEAPON_TYPE_TERTIARY   		(3)

// Tempo para desaparecer o corpo
#define TIMER_BODY                  (5 * 60000)

stock const Float:Zombies_Spawns[][3] =
{
    {452.15240, -1671.57471, 26.23418},
    {2519.17920, 2748.62646, 9.75808},
    {2539.03223, 2690.40161, 9.75808}
};
new Iterator:ZombieSpawnsIter<sizeof(Zombies_Spawns)>;

enum zombie_Enum {
	zombie_id,
	zombie_attack,
	zombie_pause,
	zombie_pause_init,
	zombie_dead,
	zombie_grito,
	zombie_indobarulho,
	zombie_observando,
	zombie_walktime,
	zombie_class,
	zombie_class_defalt,
	zombie_lastupdate,
	zombie_shootdelay,
	Float:zombie_health,
	Float:zombie_velocity,
	Float:zombie_detection,
	Float:zombie_alcance,
	Float:zombie_spawnx,
	Float:zombie_spawny,
	Float:zombie_spawnz,
	Float:zombie_lastx,
	Float:zombie_lasty,
	Float:zombie_lastz,
	zombie_movtype,
	Float:zombie_movspeed,
}
new ZombieInfo[MAX_PLAYERS][zombie_Enum];

enum {
	zombie_class_normal,
	zombie_class_shovel,
	zombie_class_knifer,
	zombie_class_serra,
	zombie_class_bomber,
	zombie_class_bandido,
}

#define max_classes 75
new index_class = 0;
new index_bandidos = 0;

enum zombieClassEnumInfo {

	// Class id
	zombie_class_id,

	// Skin da class
	zombie_class_skin,

	// Resistencia do zombie
	Float:zombie_class_resistence,

	// Visão do zombie
	Float:zombie_class_detection,

	// Alcance do zombie/bandido
	Float:zombie_class_rangeattack,

	// Delay tiro
	zombie_class_shootdelay,

	// Arma do zombie
	zombie_class_weapon,

	// type movement
	zombie_class_movtype,

	// Velocidade movimento
	Float:zombie_class_movspeed,
}
new ZombieClassInfo[max_classes][zombieClassEnumInfo];

new tickBarulho;
new zombiecount;

// Total de nodes por player
#define MAX_PLAYER_NODES 			(60)

new ZombieNodeIndex[MAX_PLAYERS];

new Float:PlayerNodesX[MAX_PLAYERS][MAX_PLAYER_NODES];
new Float:PlayerNodesY[MAX_PLAYERS][MAX_PLAYER_NODES];
new Float:PlayerNodesZ[MAX_PLAYERS][MAX_PLAYER_NODES];

static const stock s_WeaponsPoints[] = {
	6, // 0 - Fist
	12, // 1 - Brass knuckles
	15, // 2 - Golf club
	12, // 3 - Nitestick
	22, // 4 - Knife
	19, // 5 - Bat
	12, // 6 - Shovel
	11, // 7 - Pool cue
	19, // 8 - Katana
	5, // 9 - Chainsaw
	1, // 10 - Dildo
	1, // 11 - Taser
	1, // 12 - Vibrator
	1, // 13 - Vibrator 2
	1, // 14 - Flowers
	9, // 15 - Cane
	82, // 16 - Grenade
	9, // 17 - Teargas
	1, // 18 - Molotov
	10, // 19 - Vehicle M4 (custom)
	20, // 20 - Vehicle minigun (custom)
	1, // 21
	25, // 22 - Colt 45
	21, // 23 - Silenced
	39, // 24 - Deagle
	29, // 25 - Shotgun
	19, // 26 - Sawed-off
	38, // 27 - Spas
	23, // 28 - UZI
	20, // 29 - MP5
	29, // 30 - AK47
	29, // 31 - M4
	17, // 32 - Tec9
	49, // 33 - Cuntgun
	63, // 34 - Sniper
	82, // 35 - Rocket launcher
	82, // 36 - Heatseeker
	1, // 37 - Flamethrower
	0, // 38 - Minigun
	82, // 39 - Satchel
	6, // 40 - Detonator
	6, // 41 - Spraycan
	0, // 42 - Fire extinguisher
	6, // 43 - Camera
	6, // 44 - Night vision
	6, // 45 - Infrared
	6, // 46 - Parachute
	6, // 47 - Fake pistol
	2, // 48 - Pistol whip (custom)
	10, // 49 - Vehicle
	330, // 50 - Helicopter blades
	82, // 51 - Explosion
	1, // 52 - Car park (custom)
	1, // 53 - Drowning
	165  // 54 - Splat
};

//IA inteligente
public OnGameModeInit()
{
	// Zombies Class
	SetupZombiesClasses();

	// Remover barreiras
	CA_RemoveBarriers();

	// Iniciar colandreas
	CA_Init();

	// Zombies
	print( "[Z Zation] Iniciando zombies..." );
	z_Init();

// npc updates
	FCNPC_SetUpdateRate(70);
	FCNPC_SetTickRate(10);
	return 1;
}
// Módulos
Float:GetPointDistanceToPoint(Float:x1,Float:y1,Float:z1,Float:x2,Float:y2,Float:z2)
{
	new Float:x, Float:y, Float:z;
 	x = x1-x2;
  	y = y1-y2;
  	z = z1-z2;
  	return floatsqroot(x*x+y*y+z*z);
}

stock connectZombieToServer(world=0) {

	new z_name[MAX_PLAYER_NAME];

	format(z_name, sizeof (z_name), "zombie_%d_%d", zombiecount++, gettime());

	new zo_id = FCNPC_Create(z_name);

    if (zo_id != INVALID_PLAYER_ID) {

	    // Vida do Zombie
	    ZombieInfo[zo_id][zombie_health] 	  = 100.0;
	    ZombieInfo[zo_id][zombie_id]     	  = zo_id;
	    ZombieInfo[zo_id][zombie_attack]      = INVALID_PLAYER_ID;
	    ZombieInfo[zo_id][zombie_pause_init]  = GetTickCount() + 10000;
	    ZombieInfo[zo_id][zombie_indobarulho] = 0;
	    ZombieInfo[zo_id][zombie_observando]  = 0;
	    ZombieInfo[zo_id][zombie_lastupdate]  = GetTickCount() + 10000;

	    new random_spawn = Iter_Random(ZombieSpawnsIter);

	    if (random_spawn != -1)
	    {
	    	Iter_Remove(ZombieSpawnsIter, random_spawn);
		}
		else
		{
            random_spawn = random(sizeof(Zombies_Spawns));
		}

	    ZombieInfo[zo_id][zombie_spawnx]      = Zombies_Spawns[random_spawn][0];
	    ZombieInfo[zo_id][zombie_spawny]      = Zombies_Spawns[random_spawn][1];
	    ZombieInfo[zo_id][zombie_spawnz]      = Zombies_Spawns[random_spawn][2];

	    CA_RayCastLine(ZombieInfo[zo_id][zombie_spawnx], ZombieInfo[zo_id][zombie_spawny], ZombieInfo[zo_id][zombie_spawnz], ZombieInfo[zo_id][zombie_spawnx], ZombieInfo[zo_id][zombie_spawny], ZombieInfo[zo_id][zombie_spawnz] - 100.0,
	    ZombieInfo[zo_id][zombie_spawnx], ZombieInfo[zo_id][zombie_spawny], ZombieInfo[zo_id][zombie_spawnz]);

	    ZombieInfo[zo_id][zombie_spawnz] += 1.0;

		ZombieInfo[zo_id][zombie_velocity]    = FCNPC_MOVE_SPEED_RUN;

	    FCNPC_Spawn(zo_id, 136, ZombieInfo[zo_id][zombie_spawnx], ZombieInfo[zo_id][zombie_spawny], ZombieInfo[zo_id][zombie_spawnz]);
	    FCNPC_SetVirtualWorld(zo_id, world);
	    respawnZombie(zo_id);
	}
	return zo_id;
}

stock z_Init()
{
	for(new index; index < sizeof (Zombies_Spawns); index++) {
	    Iter_Add(ZombieSpawnsIter, index);
	}
	for(new z; z != MAX_ZOMBIES; z++) {
	    connectZombieToServer();
	}
}

public FCNPC_OnMovementEnd(npcid) {

	if (ZombieInfo[npcid][zombie_dead]) return 0;

	if (ZombieInfo[npcid][zombie_attack] == INVALID_PLAYER_ID) {

		FCNPC_ClearAnimations(npcid);

		FCNPC_ApplyAnimation(npcid, "PAULNMAC","PnM_Loop_B", 4.1, 1, 1, 1, 1, 0);

		if(ZombieInfo[npcid][zombie_indobarulho]) {

			FCNPC_Stop(npcid);

			// Quando chegar ao local do barulho
	   		ZombieInfo[npcid][zombie_observando] = 1;

	   		ZombieInfo[npcid][zombie_walktime] = gettime() + (5 + random(12));
		}
	}
	return 1;
}
stock SetupZombiesClasses() {
	//                    classid           skin    vida   weap  detection
	// Zombies Normais
    AddZombieClass(zombie_class_normal, 	197, 	100.0, 	0,   35.0);
    AddZombieClass(zombie_class_normal, 	200, 	100.0, 	0,   35.0);
}
stock AddZombieClass(classid, skinid, Float:resistence, weaponid, Float:detection, Float:rangeattack = 0.6, shootdelay = 100, movtype = FCNPC_MOVE_TYPE_RUN, Float:movspeed = 0.36444) {

    ZombieClassInfo[index_class][zombie_class_id] = classid;
    ZombieClassInfo[index_class][zombie_class_resistence] = resistence;
    ZombieClassInfo[index_class][zombie_class_skin] = skinid;
    ZombieClassInfo[index_class][zombie_class_weapon] = weaponid;
    ZombieClassInfo[index_class][zombie_class_detection] = detection;
    ZombieClassInfo[index_class][zombie_class_rangeattack] = rangeattack;
    ZombieClassInfo[index_class][zombie_class_shootdelay] = shootdelay;
    ZombieClassInfo[index_class][zombie_class_movtype] = movtype;
    ZombieClassInfo[index_class][zombie_class_movspeed] = movspeed;

	index_class ++;

	if (classid == zombie_class_bandido) {
	    index_bandidos ++;
	}
}

forward respawnZombieWorld(npcid);
public respawnZombieWorld(npcid) {

	if (npcid < 0 || npcid >= MAX_PLAYERS) return 0;

	// Respawnar o zombie
	FCNPC_Respawn(npcid);
	return 1;
}
forward respawnZombie(npcid);
public respawnZombie(npcid)
{
	if (npcid < 0 || npcid >= MAX_PLAYERS) return 0;

	printf("spawned: %d", npcid);

	new randClass   = random(index_class - index_bandidos);

	if (ZombieInfo[npcid][zombie_class] == zombie_class_bandido) {
	    randClass = ZombieInfo[npcid][zombie_class_defalt];
	}

	// Respawnar o zombie
	if (ZombieInfo[npcid][zombie_dead]) {
		FCNPC_SetWeapon(npcid, 0);
	}

	// Skin e vida do zombie
	FCNPC_SetSkin(npcid, ZombieClassInfo[randClass][zombie_class_skin]);
	FCNPC_SetHealth(npcid, ZombieClassInfo[randClass][zombie_class_resistence]);

	// Remover armas
	FCNPC_SetWeapon(npcid, 0);

	// Posição do zombie
	FCNPC_SetPosition(npcid, ZombieInfo[npcid][zombie_spawnx], ZombieInfo[npcid][zombie_spawny], ZombieInfo[npcid][zombie_spawnz]);

	// Informações do zombie
  	ZombieInfo[npcid][zombie_health]    = ZombieClassInfo[randClass][zombie_class_resistence];
  	ZombieInfo[npcid][zombie_detection] = ZombieClassInfo[randClass][zombie_class_detection];
  	ZombieInfo[npcid][zombie_alcance]   = ZombieClassInfo[randClass][zombie_class_rangeattack];
  	ZombieInfo[npcid][zombie_shootdelay]= ZombieClassInfo[randClass][zombie_class_shootdelay];
  	ZombieInfo[npcid][zombie_movtype]   = ZombieClassInfo[randClass][zombie_class_movtype];
  	ZombieInfo[npcid][zombie_movspeed]  = ZombieClassInfo[randClass][zombie_class_movspeed];
  	ZombieInfo[npcid][zombie_class]     = ZombieClassInfo[randClass][zombie_class_id];
  	ZombieInfo[npcid][zombie_class_defalt]= randClass;
  	ZombieInfo[npcid][zombie_dead]      = 0;
  	ZombieInfo[npcid][zombie_walktime]  = gettime() + (5 + random(12));
	return 1;
}
public FCNPC_OnUpdate(npcid)
{
	new
	    currentTick = GetTickCount();
	if (ZombieInfo[npcid][zombie_lastupdate] < currentTick)
	{
        ZombieInfo[npcid][zombie_lastupdate] = currentTick + (190 + random(70));

		if ( ZombieInfo[npcid][zombie_dead] )
	 	    return 1;

		if ( FCNPC_IsDead(npcid) )
		    return 1;

	 	if ( ZombieInfo[npcid][zombie_pause] > currentTick )
	 	    return 1;

		if ( ZombieInfo[npcid][zombie_pause_init] > currentTick )
	 	    return 1;

		if (!FCNPC_IsStreamedInForAnyone(npcid))
		    return 1;

		// update zombie follow player
		if (ZombieInfo[npcid][zombie_attack] != INVALID_PLAYER_ID) {
        	UpdateZombieFolowPlayer(npcid, ZombieInfo[npcid][zombie_attack]);
		// update iddle zombie
		} else {
		    UpdateZombieIddleMovements(npcid);
		}

        // sound effect in zombie
		if(ZombieInfo[npcid][zombie_grito] < GetTickCount() && ZombieInfo[npcid][zombie_class] != zombie_class_bandido) {
		    // get a position
	 	    static Float:pos[3];
	 	    FCNPC_GetPosition(npcid, pos[0], pos[1], pos[2]);
		    ZombieInfo[npcid][zombie_grito] = GetTickCount() + (8000 + random(9500));
		}
	}
	return 1;
}

public FCNPC_OnRespawn(npcid) {
    respawnZombie(npcid);
	return 1;
}
stock Float:GetPointAngleToPoint(Float:x1, Float:y1, Float:x2, Float:y2) {
    return 180.0 - atan2(x1 - x2, y1 - y2);
}
stock UpdateZombieFolowPlayer(zombie, playerid)
{
	// get a current zombie clossest player
	new Float:currentDistanceBetween;
	new currentClossestPlayer = z_GetClosestPlayer(zombie, currentDistanceBetween);
	new zombieFollowPlayer = ZombieInfo[zombie][zombie_attack];

	if (currentClossestPlayer != playerid && IsZombieViewPlayer(zombie, currentClossestPlayer))
    {
	    ZombieInfo[zombie][zombie_attack] = currentClossestPlayer;
	    zombieFollowPlayer = currentClossestPlayer;
	}

	if (currentDistanceBetween < ZombieInfo[zombie][zombie_detection])
    {
	    // count zombies follow player
        new countPlayerCurrentFollow = CountZombiesFollowPlayer(zombieFollowPlayer);
		// check if zombies amount if much
		if (countPlayerCurrentFollow >= MAX_ZOMBIES_FOLLOW_PLAYER && ZombieInfo[zombie][zombie_attack] != zombieFollowPlayer)
		    return 0;

 	    new Float:pos[6];
 	    // get a player position
 	    GetPlayerPos(zombieFollowPlayer, pos[0], pos[1], pos[2]);

 	    FCNPC_GetPosition(zombie, pos[3], pos[4], pos[5]);

		// check if distance is better than zombie radius attack
		if ( currentDistanceBetween < ZombieInfo[zombie][zombie_alcance] ) {
			// check if is a bandido
			if (ZombieInfo[zombie][zombie_class] == zombie_class_bandido) {

				if (IsZombieViewPlayer(zombie, currentClossestPlayer)) {
					// stop zombie
					if (FCNPC_IsMoving(zombie))
                    	FCNPC_Stop(zombie);

                    if (!FCNPC_IsAiming(zombie))
                    	FCNPC_ClearAnimations(zombie);
					// aim at player
					if (!FCNPC_IsAiming(zombie))
						FCNPC_AimAtPlayer(zombie, zombieFollowPlayer, true);
					return 1;
				} else {
				    // move zombie to player
				    MoveZombieToPlayer(zombie, zombieFollowPlayer);

				    FCNPC_StopAim(zombie);
				}
			} else {
			    // check if explosive zombie
				if (ZombieInfo[zombie][zombie_class] == zombie_class_bomber) {
					#if defined onZombieDeath
				    	onZombieDeath(zombie, INVALID_PLAYER_ID, 255);
					#endif
				   	FCNPC_Kill(zombie);
				    return 1;
				}

			    // stop zombie
			    FCNPC_Stop(zombie);

                if (!FCNPC_IsAttacking(zombie))
                   	FCNPC_ClearAnimations(zombie);

				// attack melee player
				FCNPC_AimAtPlayer(zombie, playerid, false, -1, false);

				ZombieInfo[zombie][zombie_pause] = GetTickCount() + ZOMBIE_UPDATE_TIME;

				FCNPC_MeleeAttack(zombie);
				// set a zombie angle
				setZombieAngleToPlayer(zombie, zombieFollowPlayer);
			}
			return 1;
		// stop aim and attack
 	    } else {
 	        FCNPC_StopAttack(zombie);
 	        FCNPC_StopAim(zombie);
 	    }

		if (!FCNPC_IsAttacking(zombie)) {
		    // move zombie to player
        	if (MoveZombieToPlayer(zombie, zombieFollowPlayer))
        	{
        	    FCNPC_ApplyAnimation(zombie, "PED","run_old", 4.1, 1, 1, 1, 1, 0);
        	}
        	else
        	{
        	    if (FCNPC_IsMoving(zombie))
        	        FCNPC_Stop(zombie);
				// apply anim
        	    FCNPC_ApplyAnimation(zombie, "HAIRCUTS","BRB_Buy", 4.1, 1, 1, 1, 1, 0);
        	}
		}
	// stop following
	} else {
        StopZombieFollow(zombie);
	}
	return 1;
}
stock UpdateZombieIddleMovements(zombie) {

	// Verificar o tempo da ultima movimentada
	if (gettime() > ZombieInfo[zombie][zombie_walktime] && !ZombieInfo[zombie][zombie_indobarulho]) {
	    // Fazer ele se mover
	    updateZombiesMovements(zombie);
	    // Setar o tempo do ultimo movimento
	    ZombieInfo[zombie][zombie_walktime] = gettime() + (10 + random(15));
	}

	// check if pursuir a invalid player
	new Float:currentDistanceBetween;
	new currentClossestPlayer = z_GetClosestPlayer(zombie, currentDistanceBetween);
	// check if zombie view player
	if (currentClossestPlayer != INVALID_PLAYER_ID && currentDistanceBetween < ZombieInfo[zombie][zombie_detection] && IsZombieViewPlayer(zombie, currentClossestPlayer)) {

	    ZombieInfo[zombie][zombie_attack] = currentClossestPlayer;
	    ZombieInfo[zombie][zombie_indobarulho] = 0;
	    ZombieInfo[zombie][zombie_observando]  = 0;
	}
}
stock z_GetClosestPlayer(npcid, &Float:distance = 0.0) {

	new player = INVALID_PLAYER_ID;
	new Float:dist = 99999.00;
	new Float:x, Float:y, Float:z, Float:pos;
	FCNPC_GetPosition(npcid, x, y, z);

	foreach(new playerid : Player) {

		if (GetPlayerVirtualWorld(playerid) != 0 || GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
		    continue;

		if (IsPlayerInAnyVehicle(playerid))
		    continue;

	    if ( (pos = GetPlayerDistanceFromPoint(playerid, x, y, z) ) < dist)
		{
	        player = playerid;
	        dist = pos;
	    }
	}
	distance = dist;

	return player;
}
stock IsZombieViewPlayer(zombie, playerid) {

	static
	    // player
		Float:x,
		Float:y,
		Float:z,
		// zombie
		Float:zox,
		Float:zoy,
		Float:zoz;

	FCNPC_GetPosition(zombie, zox, zoy, zoz);

	GetPlayerPos(playerid, x, y, z);

	if (!IsZombieFacingPlayer(zombie, x, y, zox, zoy, 80.0) && getPlayerOnfootSpeed(playerid) < 12)
	    return 0;

	if (CA_RayCastLine(x, y, z, zox, zoy, zoz, x, x, x))
	    return 0;

	return 1;
}
stock CountZombiesFollowPlayer(playerid) {

	new count;

	for (new z = GetPlayerPoolSize(), zombie; zombie <= z; zombie++) {

		if (!FCNPC_IsValid(zombie))
		    continue;

		if (ZombieInfo[zombie][zombie_attack] == playerid) {

			//ZombieInfo[zombie][zombie_velocity] = (0.51000) - (count * 0.025);
			ZombieInfo[zombie][zombie_velocity] = (ZombieInfo[zombie][zombie_movspeed]) - (count * 0.025);

			if (ZombieInfo[zombie][zombie_velocity] < 0.20000)
			    ZombieInfo[zombie][zombie_velocity] = 0.20000;

			count ++;
	 	}
	}
	return count;
}
stock MoveZombieToPlayer(zombie, playerid) {

	static sucess, nodeid, Float:x, Float:y, Float:z, Float:px, Float:py, Float:pz;

    nodeid = -1;

    sucess = false;

	FCNPC_GetPosition(zombie, x, y, z);

	GetPlayerPos(playerid, px, py, pz);

    sucess = CA_TraceLine(zombie, playerid, x, y, z, px, py, pz, .maxnodes = 1);

	if (!sucess)
	{
		for (new node; node != MAX_PLAYER_NODES; node++)
		{
		    new result = CA_TraceLine(zombie,playerid,x, y, z,PlayerNodesX[playerid][node],PlayerNodesY[playerid][node],PlayerNodesZ[playerid][node], .nodeid = node, .maxnodes = 1);

			if(result == -2)
			    break;

			if (result)
			{
				nodeid = node;

				ZombieInfo[zombie][zombie_lastx] = PlayerNodesX[playerid][node];
				ZombieInfo[zombie][zombie_lasty] = PlayerNodesY[playerid][node];
				ZombieInfo[zombie][zombie_lastz] = PlayerNodesZ[playerid][node];

				break;
		    }
		}
	}

	if ( nodeid != -1 || sucess )
	{
	    FCNPC_CreateMovement(zombie);

	    for(new nodes; nodes < ZombieNodeIndex[zombie]; nodes++)
		{
	        // Add movimentos
            FCNPC_AddMovement(zombie, PlayerNodesX[zombie][nodes], PlayerNodesY[zombie][nodes], PlayerNodesZ[zombie][nodes]);
		}

		// Aplicar o movimento
		FCNPC_PlayMovement(zombie, ZombieInfo[zombie][zombie_movtype], ZombieInfo[zombie][zombie_velocity]);

		return 1;
	}
	else
	{
		FCNPC_Stop(zombie);
	}

	return 0;
}
stock setZombieAngleToPlayer(npcid, playerid) {

	static
	    Float:zx, Float:zy, Float:zz,
	    Float:px, Float:py, Float:pz,
		Float:ang,
		Float:angz
		;

	FCNPC_GetPosition(npcid, zx, zy, zz);

	GetPlayerPos(playerid, px, py, pz);

	angz = FCNPC_GetAngle(npcid);

	zx -= (5.0 * floatsin(-angz, degrees));
	zy -= (5.0 * floatcos(-angz, degrees));

	ang = GetPointAngleToPoint(zx, zy, px, py);

	zx += (10.0 * floatsin(-ang, degrees));
	zy += (10.0 * floatcos(-ang, degrees));

	FCNPC_SetAngleToPos(npcid, zx, zy);
}
stock StopZombieFollow(zombie) {

	if (ZombieInfo[zombie][zombie_attack] != INVALID_PLAYER_ID) {

	    ZombieInfo[zombie][zombie_attack] = INVALID_PLAYER_ID;

		// Parar o zombie
		FCNPC_Stop(zombie);

		// Limpar as animações
		ClearAnimations(zombie);

 	    // Fazer parar de bater
	    FCNPC_StopAttack(zombie);

	    // Parar de mirar
	    FCNPC_StopAim(zombie);

	    FCNPC_ApplyAnimation(zombie, "PAULNMAC","PnM_Loop_B", 3.1, 1, 1, 1, 1, 0);

	    ZombieInfo[zombie][zombie_walktime] = gettime() + (5 + random(15));
	}
}
forward updateZombiesMovements(zombie);
public updateZombiesMovements(zombie)
{

	new
		Float:x,
		Float:y,
		Float:z,
		Float:tox,
		Float:toy,
		Float:toz
		;

	FCNPC_GetPosition(zombie, x, y, z);

	tox = x + frandom(5.0) - frandom(5.0);
	toy = y + frandom(5.0) - frandom(5.0);
	toz = z;

	if (CA_TraceLine(zombie, -1, x, y, z, tox, toy, toz, .stepsize = 1.5, .maxnodes = 2)) {

		FCNPC_CreateMovement(zombie);

	    for(new nodes; nodes < ZombieNodeIndex[zombie]; nodes++) {
	        FCNPC_AddMovement(zombie, PlayerNodesX[zombie][nodes], PlayerNodesY[zombie][nodes], PlayerNodesZ[zombie][nodes]);
	    }

	    FCNPC_PlayMovement(zombie, FCNPC_MOVE_TYPE_WALK, .speed = 0.1252086, .delaystop = 0);

	    FCNPC_ApplyAnimation(zombie, "PED","WALK_old", 3.1, 1, 1, 1, 1, 0);
	}

	return 1;
}
stock IsZombieFacingPlayer(zombieid, Float:pX, Float:pY, Float:X, Float:Y, Float:dOffset)
{
	static
		Float:pA,
		Float:ang
		;

	pA = FCNPC_GetAngle(zombieid);

	if( Y > pY )
		ang = (-acos((X - pX) / floatsqroot((X - pX) * (X - pX) + (Y - pY) * (Y - pY))) - 90.0);

	else if( Y < pY && X < pX )
		ang = (acos((X - pX) / floatsqroot((X - pX) * (X - pX) + (Y - pY) * (Y - pY))) - 450.0);

	else if( Y < pY )
		ang = (acos((X - pX) / floatsqroot((X - pX) * (X - pX) + (Y - pY) * (Y - pY))) - 90.0);

	if(AngleInRangeOfAngleEx(-ang, pA, dOffset))
		return 1;

	return 0;

}
stock CA_TraceLine(zombie, playerid, Float:x, Float:y, Float:z, Float:endx, Float:endy, Float:endz, Float:stepsize=1.45, nodeid = 999, maxnodes = 1)
{
	if (nodeid == 0) {

		static Float:px;
		static Float:py;
		static Float:pz;
		GetPlayerPos(playerid, px, py, pz);

		endx = px;
		endy = py;
		endz = pz;
	}

	static Float:tx;
	static Float:ty;
	static Float:tz;

	if (CA_RayCastLine(x, y, z, endx, endy, endz, tx, ty, tz))
		return 0;

    CA_RayCastLine(endx, endy, endz, endx, endy, endz - 50.0, tx, ty, tz);
    tz += 1.0;

	// Resetar o caminho
    ZombieNodeIndex[zombie] = 0;

	static Float:lastx;
	static Float:lasty;
	static Float:lastz;
	new Float:point_distance = GetPointDistanceToPoint(x, y, z, endx, endy, tz);
	new Float:point_angle    = GetPointAngleToPoint(x, y, endx, endy);

	lastx = x;
	lasty = y;
   	lastz = z;

	if (nodeid != 999)
	{
		if (PlayerNodesX[playerid][nodeid] == ZombieInfo[zombie][zombie_lastx] && point_distance < 1.0)
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

		lastx = x;
		lasty = y;
	   	lastz = z;

   		PlayerNodesX[zombie][ZombieNodeIndex[zombie]] = x;
   		PlayerNodesY[zombie][ZombieNodeIndex[zombie]] = y;
   		PlayerNodesZ[zombie][ZombieNodeIndex[zombie]] = z;

   		ZombieNodeIndex[zombie] ++;

		if (ZombieNodeIndex[zombie] >= maxnodes) return 1;
	}

	return 1;
}
stock Float:convertDamage(Float:damage, bodypart) {

	new Float:newdamage;

	switch(bodypart) {

	    // Barriga
	    case 3: {newdamage = damage + 0.0;}

	    // Peito
	    case 4: {newdamage = damage * 1.40;}

	    // Braços
	    case 5: {newdamage = damage / 1.10;}
	    case 6: {newdamage = damage / 1.10;}

	    // Pernas
	    case 7: {newdamage = damage / 1.85;}
	    case 8: {newdamage = damage / 1.85;}

	    // Cabeça
	    case 9: {newdamage = damage * 1.90;}
	}

	return newdamage;
}
stock Float:getWeaponZDamage(weaponid) {

	if (weaponid < 0 || weaponid >= sizeof (s_WeaponsPoints)) {
	    return 0.0;
	}

	return float(s_WeaponsPoints[weaponid]);
}

stock CA_TraceLineEx(zombie, Float:x, Float:y, Float:z, Float:endx, Float:endy, Float:endz, Float:stepsize=1.45, maxnodes = 1)
{
	static Float:a;

	// Resetar o caminho
    ZombieNodeIndex[zombie] = 0;

	static Float:lastx;
	static Float:lasty;
	static Float:lastz;
	new Float:point_distance = GetPointDistanceToPoint(x, y, z, endx, endy, endz);
	new Float:point_angle    = GetPointAngleToPoint(x, y, endx, endy);

	lastx = x;
	lasty = y;
   	lastz = z;

	for (new Float:point; point < point_distance; point += stepsize)
	{
		x += (stepsize * floatsin(-point_angle, degrees));
		y += (stepsize * floatcos(-point_angle, degrees));

		if (CA_RayCastLine(x, y, z, x, y, z - 70.0, x, y, z))
			z += 1.1;

		if (!IsPointZValid(z, lastz) || CA_RayCastLine(lastx, lasty, lastz, x, y, z, a, a, a))
			return 0;

		lastx = x;
		lasty = y;
	   	lastz = z;

   		PlayerNodesX[zombie][ZombieNodeIndex[zombie]] = x;
   		PlayerNodesY[zombie][ZombieNodeIndex[zombie]] = y;
   		PlayerNodesZ[zombie][ZombieNodeIndex[zombie]] = z;

   		ZombieNodeIndex[zombie] ++;

		if (ZombieNodeIndex[zombie] >= maxnodes) return 1;
	}

	return 1;
}

stock getPlayerOnfootSpeed(playerid) {

	static
		Float:velx,
		Float:vely,
		Float:velz;

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

	if ( (z2 < z1 - 1.3) || (z2 > z1 + 1.3) ) return 0;

	return 1;
}
public OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if (tickBarulho < GetTickCount()) {

		static Float:x, Float:y, Float:z, Float:w;
		GetPlayerPos(playerid, x, y, z);

		if(!CA_RayCastLine(x, y, z, x, y, z + 100.0, w, w, w)) {
		    FazerBarulho(x, y, z);
		}
	}

	#if defined z_OnPlayerWeaponShot
	    return z_OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, fX, fY, fZ);
	#else
    	return 1;
	#endif
}
#if defined _ALS_OnPlayerWeaponShot
	#undef OnPlayerWeaponShot
#else
	#define _ALS_OnPlayerWeaponShot
#endif
#define OnPlayerWeaponShot z_OnPlayerWeaponShot
#if defined z_OnPlayerWeaponShot
	forward z_OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ);
#endif

public FCNPC_OnTakeDamage(npcid, issuerid, Float:amount, weaponid, bodypart) {

	if (ZombieInfo[npcid][zombie_dead])
	    return 0;

	// Matar o zombie

	// Retirar a vida do zombie
	amount = convertDamage(getWeaponZDamage(weaponid), bodypart) * 1.14524;

	// Head Shot de Sniper
	if ( weaponid == 34 && bodypart == 9) {
 		amount = 255.0;
	}

	// Retirar a vida do zombie
	ZombieInfo[npcid][zombie_health] -= amount;

	if (ZombieInfo[npcid][zombie_attack] == INVALID_PLAYER_ID) {
	    // stop a zombie
	    FCNPC_Stop(npcid);
	   	// set a zombie angle
		setZombieAngleToPlayer(npcid, issuerid);
	}

	// Dar os pontos
	static Float:pos[4];
	if (fireWeapons(weaponid)) {

		// Pegar a posição do ultimo tiro
       	GetPlayerLastShotVectors(issuerid, pos[3], pos[3], pos[3], pos[0], pos[1], pos[2]);

	} else {

	    // Pegar a posição do zombie
	    FCNPC_GetPosition(npcid, pos[0], pos[1], pos[2]);

	}

	if ( ZombieInfo[npcid][zombie_health] <= 0.0) {

		// Pegar a posição do player
	   	FCNPC_GetPosition(npcid, pos[0], pos[1], pos[2]);


		#if defined onZombieDeath
	    	onZombieDeath(npcid, issuerid, weaponid);
		#endif

	    ZombieInfo[npcid][zombie_dead] = 1;

	   	FCNPC_Kill(npcid);
	}
	return 1;
}
public FCNPC_OnDeath(npcid, killerid, reason) {

	if (!ZombieInfo[npcid][zombie_dead]) {
        onZombieDeath(npcid, killerid, reason);
	}
	printf("death: %d", npcid);

	return 1;
}
public FCNPC_OnSpawn(npcid) {

	respawnZombie(npcid);

	return 1;
}
     public OnPlayerStreamIn(playerid, forplayerid) {
	if (IsPlayerNPC(playerid) && FCNPC_IsDead(playerid)) {
	    FCNPC_Kill(playerid);
	}
	return 1;
}
public OnPlayerUpdate(playerid)
{
	// Add o node para zombies
	addPlayerNode(playerid);
	return 1;
}

    stock addPlayerNode(playerid) {

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
forward onZombieDeath(zombieid, killerid, weaponid);
public onZombieDeath(zombieid, killerid, weaponid) {

	print("zombie death");
	if (ZombieInfo[zombieid][zombie_attack] != INVALID_PLAYER_ID) {
	    #if defined OnZombieAttackChange
			OnZombieAttackChange(zombieid, INVALID_PLAYER_ID, ZombieInfo[zombieid][zombie_attack]);
		#endif
		ZombieInfo[zombieid][zombie_attack] = INVALID_PLAYER_ID;
	}


	static
		Float:x,
		Float:y,
		Float:z;

	FCNPC_GetPosition(zombieid, x, y, z);

	if (ZombieInfo[zombieid][zombie_class] != zombie_class_bandido)
	{
		SetTimerEx("respawnZombieWorld", ZOMBIE_RESPAWN, false, "i", zombieid);
	} else {
	    SetTimerEx("respawnZombieWorld", ZOMBIE_RESPAWN * 3, false, "i", zombieid);
	}

	ZombieInfo[zombieid][zombie_dead] = 1;

	return 1;
}
stock FazerBarulho(Float:x, Float:y, Float:z, Float:distancia=100.0)
{
	if (tickBarulho > GetTickCount())
	{
		return 0;
	}
    tickBarulho = GetTickCount() + 5000;

    new
        countAttractZombies = 0;

	for (new zz = GetPlayerPoolSize(), zombie; zombie <= zz; zombie++)
	{
		if (!FCNPC_IsValid(zombie))
		    continue;

	    if (ZombieInfo[zombie][zombie_dead])
			continue;

	    if (ZombieInfo[zombie][zombie_attack] != INVALID_PLAYER_ID)
	        continue;

	    if (IsPlayerInRangeOfPoint(zombie, distancia, x, y, z))
		{
		    countAttractZombies++;
			// Fazer o zombie se mover até o local do barulho
			static Float:zPos[3];

			FCNPC_GetPosition(zombie, zPos[0], zPos[1], zPos[2]);

			CA_TraceLineEx(zombie, zPos[0], zPos[1], zPos[2], x, y, z, .stepsize=2.0, .maxnodes = 30);

			if (ZombieNodeIndex[zombie] > 0)
			{
			    FCNPC_CreateMovement(zombie);

			    for(new nodes; nodes < ZombieNodeIndex[zombie]; nodes++)
				{
			        // Add movimentos
		            FCNPC_AddMovement(zombie, PlayerNodesX[zombie][nodes], PlayerNodesY[zombie][nodes], PlayerNodesZ[zombie][nodes]);
				}

				// Aplicar o movimento
			    FCNPC_PlayMovement(zombie, FCNPC_MOVE_TYPE_WALK, .speed = 0.1252086, .delaystop = 0);

			    FCNPC_ApplyAnimation(zombie, "PED","WALK_old", 4.1, 1, 1, 1, 1, 0);
			}

			ZombieInfo[zombie][zombie_indobarulho] = 1;
			ZombieInfo[zombie][zombie_observando]  = 0;
		}
		if (countAttractZombies > 4)
		{
		    return 1;
		}
	}
	return 1;
}
stock fireWeapons(weaponid) {

	switch(weaponid) {
	    case 22..34, 38: return 1;
	}
	return 0;
}

