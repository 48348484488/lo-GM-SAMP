// ========================================
// CIVILIAN AI SYSTEM - CLASSES MODULE
// ========================================
// Version: 2.0.0
// Author: SA-MP Civilian AI System
// Description: Civilian classes and spawning system
// ========================================

#if !defined _civilian_classes_included
#define _civilian_classes_included

// ========================================
// CIVILIAN CLASS MANAGEMENT
// ========================================

stock SetupCivilianClasses() 
{
	print("[Civilian Classes] Setting up civilian classes...");
	
	// Normal civilians (80% of spawns)
    AddCivilianClass(civilian_class_normal, 0, 100.0, 0, 20.0, 1.5, 2000, FCNPC_MOVE_TYPE_WALK, 0.25);      // Random male/female
    AddCivilianClass(civilian_class_normal, 0, 100.0, 0, 20.0, 1.5, 2000, FCNPC_MOVE_TYPE_WALK, 0.25);      // Random male/female
    AddCivilianClass(civilian_class_normal, 0, 100.0, 0, 20.0, 1.5, 2000, FCNPC_MOVE_TYPE_WALK, 0.25);      // Random male/female
    AddCivilianClass(civilian_class_normal, 0, 100.0, 0, 20.0, 1.5, 2000, FCNPC_MOVE_TYPE_WALK, 0.25);      // Random male/female
    
    // Pedestrians (casual walkers - 10% of spawns)
    AddCivilianClass(civilian_class_pedestrian, 0, 100.0, 0, 15.0, 1.2, 3000, FCNPC_MOVE_TYPE_WALK, 0.20);
    
    // Workers (construction, mechanics - 7% of spawns)
    AddCivilianClass(civilian_class_worker, 27, 100.0, 0, 15.0, 1.8, 1500, FCNPC_MOVE_TYPE_WALK, 0.30);      // Construction worker
    AddCivilianClass(civilian_class_worker, 50, 100.0, 0, 15.0, 1.8, 1500, FCNPC_MOVE_TYPE_WALK, 0.30);      // Mechanic
    AddCivilianClass(civilian_class_worker, 260, 100.0, 0, 15.0, 1.8, 1500, FCNPC_MOVE_TYPE_WALK, 0.30);     // Worker
    
    // Shopkeepers (business people - 2% of spawns)
    AddCivilianClass(civilian_class_shopkeeper, 147, 120.0, 0, 18.0, 2.0, 2500, FCNPC_MOVE_TYPE_WALK, 0.22); // Business man
    AddCivilianClass(civilian_class_shopkeeper, 148, 120.0, 0, 18.0, 2.0, 2500, FCNPC_MOVE_TYPE_WALK, 0.22); // Business woman
    
    // Security guards (armed - 1% of spawns)
    AddCivilianClass(civilian_class_security, 71, 150.0, 24, 25.0, 2.5, 1000, FCNPC_MOVE_TYPE_WALK, 0.28);   // Security with Deagle
    AddCivilianClass(civilian_class_security, 280, 150.0, 23, 25.0, 2.5, 1000, FCNPC_MOVE_TYPE_WALK, 0.28);  // Police with pistol
    
    printf("[Civilian Classes] Configured %d civilian classes successfully!", index_class);
}

stock AddCivilianClass(classid, skinid, Float:health, weaponid, Float:detection, Float:interaction_range = 1.5, interaction_delay = 2000, movtype = FCNPC_MOVE_TYPE_WALK, Float:movspeed = 0.25) 
{
    if(index_class >= MAX_CIVILIAN_CLASSES) {
        printf("[Civilian Classes] ERROR: Maximum classes limit reached (%d)", MAX_CIVILIAN_CLASSES);
        return 0;
    }
    
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
	
	return 1;
}

// ========================================
// CIVILIAN SPAWNING SYSTEM
// ========================================

stock ConnectCivilianToServer(world = 0) 
{
	new c_name[MAX_PLAYER_NAME];
	format(c_name, sizeof(c_name), "Civilian_%d_%d", civiliancount++, gettime());
	
	new civilian_id = FCNPC_Create(c_name);
	
    if (civilian_id != INVALID_PLAYER_ID) {
	    // Initialize civilian data
	    InitializeCivilianData(civilian_id);
	    
	    // Select spawn location
	    SelectCivilianSpawnLocation(civilian_id);
	    
	    // Spawn civilian with default skin (will be changed in RespawnCivilian)
	    FCNPC_Spawn(civilian_id, 23, CivilianInfo[civilian_id][civilian_spawnx], CivilianInfo[civilian_id][civilian_spawny], CivilianInfo[civilian_id][civilian_spawnz]);
	    FCNPC_SetVirtualWorld(civilian_id, world);
	    
	    // Setup civilian with class data
	    RespawnCivilian(civilian_id);
	    
	    TotalCiviliansSpawned++;
	    LogCivilianAction(civilian_id, "Spawned successfully");
	}
	return civilian_id;
}

stock InitializeCivilianData(civilian_id)
{
    CivilianInfo[civilian_id][civilian_health] 	  		= 100.0;
    CivilianInfo[civilian_id][civilian_id]     	  		= civilian_id;
    CivilianInfo[civilian_id][civilian_target_player]      = INVALID_PLAYER_ID;
    CivilianInfo[civilian_id][civilian_pause_init]  		= GetTickCount() + 5000 + random(10000);
    CivilianInfo[civilian_id][civilian_investigating_sound] = 0;
    CivilianInfo[civilian_id][civilian_observing]  		= 0;
    CivilianInfo[civilian_id][civilian_lastupdate]  		= GetTickCount() + random(5000);
    CivilianInfo[civilian_id][civilian_velocity] 			= FCNPC_MOVE_SPEED_WALK;
    CivilianInfo[civilian_id][civilian_inactive]			= 0;
    CivilianInfo[civilian_id][civilian_speaking]			= 0;
    CivilianInfo[civilian_id][civilian_pause]				= 0;
    CivilianInfo[civilian_id][civilian_walktime]			= gettime() + (5 + random(15));
}

stock SelectCivilianSpawnLocation(civilian_id)
{
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
	
	printf("[Civilian Classes] Spawned %d civilians successfully!", MAX_CIVILIANS);
}

// ========================================
// CIVILIAN RESPAWN SYSTEM
// ========================================

forward RespawnCivilianWorld(npcid);
public RespawnCivilianWorld(npcid) 
{
	if (npcid < 0 || npcid >= MAX_PLAYERS) return 0;
	if (!FCNPC_IsValid(npcid)) return 0;
	
	FCNPC_Respawn(npcid);
	return 1;
}

forward RespawnCivilian(npcid);
public RespawnCivilian(npcid)
{
	if (npcid < 0 || npcid >= MAX_PLAYERS) return 0;
	if (!FCNPC_IsValid(npcid)) return 0;

	// Select class based on weighted probabilities
	new randClass = SelectRandomCivilianClass();

	// If it was a security guard, keep it as security
	if (CivilianInfo[npcid][civilian_class] == civilian_class_security) {
	    randClass = CivilianInfo[npcid][civilian_class_default];
	}

	// Reset civilian if inactive
	if (CivilianInfo[npcid][civilian_inactive]) {
		FCNPC_SetWeapon(npcid, 0);
	}

	// Set skin based on class
	new skin = DetermineCivilianSkin(randClass);
	FCNPC_SetSkin(npcid, skin);
	FCNPC_SetHealth(npcid, CivilianClassInfo[randClass][civilian_class_health]);

	// Set weapons (only for security)
	if (CivilianClassInfo[randClass][civilian_class_id] == civilian_class_security) {
		FCNPC_SetWeapon(npcid, CivilianClassInfo[randClass][civilian_class_weapon]);
	} else {
		FCNPC_SetWeapon(npcid, 0);
	}

	// Set position
	FCNPC_SetPosition(npcid, CivilianInfo[npcid][civilian_spawnx], CivilianInfo[npcid][civilian_spawny], CivilianInfo[npcid][civilian_spawnz]);

	// Initialize civilian properties from class
	ApplyCivilianClassProperties(npcid, randClass);
	
	// Apply appropriate starting animation
	ApplySpawnAnimation(npcid, CivilianClassInfo[randClass][civilian_class_id]);
	
	LogCivilianAction(npcid, "Respawned with new class");
	return 1;
}

stock SelectRandomCivilianClass()
{
    // Weighted class selection (excluding security for random spawns)
    new weights[] = {80, 10, 7, 2}; // Normal, Pedestrian, Worker, Shopkeeper percentages
    new totalWeight = 0;
    for(new i = 0; i < sizeof(weights); i++) {
        totalWeight += weights[i];
    }
    
    new randomNum = random(totalWeight);
    new currentWeight = 0;
    
    for(new i = 0; i < sizeof(weights); i++) {
        currentWeight += weights[i];
        if(randomNum < currentWeight) {
            // Find a class of this type
            for(new c = 0; c < index_class; c++) {
                switch(i) {
                    case 0: if(CivilianClassInfo[c][civilian_class_id] == civilian_class_normal) return c;
                    case 1: if(CivilianClassInfo[c][civilian_class_id] == civilian_class_pedestrian) return c;
                    case 2: if(CivilianClassInfo[c][civilian_class_id] == civilian_class_worker) return c;
                    case 3: if(CivilianClassInfo[c][civilian_class_id] == civilian_class_shopkeeper) return c;
                }
            }
        }
    }
    
    // Fallback to first class
    return 0;
}

stock DetermineCivilianSkin(classIndex)
{
    new skin = CivilianClassInfo[classIndex][civilian_class_skin];
    
    // If skin is 0, use random skin based on class type
    if(skin == 0) {
        switch(CivilianClassInfo[classIndex][civilian_class_id]) {
            case civilian_class_normal, civilian_class_pedestrian: {
                skin = GetRandomCivilianSkin(civilian_class_normal);
            }
            case civilian_class_worker: {
                skin = GetRandomCivilianSkin(civilian_class_worker);
            }
            case civilian_class_security: {
                skin = GetRandomCivilianSkin(civilian_class_security);
            }
            case civilian_class_shopkeeper: {
                // Business skins
                new businessSkins[] = {147, 148, 164, 211, 179};
                skin = businessSkins[random(sizeof(businessSkins))];
            }
            default: {
                skin = GetRandomCivilianSkin(civilian_class_normal);
            }
        }
    }
    
    return skin;
}

stock ApplyCivilianClassProperties(npcid, classIndex)
{
    CivilianInfo[npcid][civilian_health]    			= CivilianClassInfo[classIndex][civilian_class_health];
    CivilianInfo[npcid][civilian_detection] 			= CivilianClassInfo[classIndex][civilian_class_detection];
    CivilianInfo[npcid][civilian_interaction_range]   	= CivilianClassInfo[classIndex][civilian_class_interaction_range];
    CivilianInfo[npcid][civilian_interaction_delay]	= CivilianClassInfo[classIndex][civilian_class_interaction_delay];
    CivilianInfo[npcid][civilian_movtype]   			= CivilianClassInfo[classIndex][civilian_class_movtype];
    CivilianInfo[npcid][civilian_movspeed]  			= CivilianClassInfo[classIndex][civilian_class_movspeed];
    CivilianInfo[npcid][civilian_class]     			= CivilianClassInfo[classIndex][civilian_class_id];
    CivilianInfo[npcid][civilian_class_default]			= classIndex;
    CivilianInfo[npcid][civilian_inactive]      		= 0;
    CivilianInfo[npcid][civilian_walktime]  			= gettime() + (5 + random(15));
    
    // Adjust properties based on time of day
    if(IsNightTime()) {
        CivilianInfo[npcid][civilian_detection] *= 0.8; // Reduced detection at night
        CivilianInfo[npcid][civilian_movspeed] *= 0.9;  // Slower movement at night
    }
    
    // Adjust properties based on class-specific behavior
    switch(CivilianInfo[npcid][civilian_class]) {
        case civilian_class_security: {
            CivilianInfo[npcid][civilian_detection] *= 1.3; // Security guards are more alert
            CivilianInfo[npcid][civilian_walktime] = gettime() + (8 + random(10)); // Patrol more regularly
        }
        case civilian_class_worker: {
            CivilianInfo[npcid][civilian_movspeed] *= 1.1; // Workers move slightly faster
            CivilianInfo[npcid][civilian_walktime] = gettime() + (3 + random(8)); // More active
        }
        case civilian_class_shopkeeper: {
            CivilianInfo[npcid][civilian_movspeed] *= 0.8; // Shopkeepers move slower
            CivilianInfo[npcid][civilian_walktime] = gettime() + (15 + random(20)); // Less mobile
        }
    }
}

stock ApplySpawnAnimation(npcid, classType)
{
    switch(classType) {
        case civilian_class_normal, civilian_class_pedestrian: {
            ApplyRandomCivilianAnimation(npcid, 0); // Idle animation
        }
        case civilian_class_worker: {
            // Worker-specific animations
            new workerAnims[][2][32] = {
                {"CARRY", "crry_prtial"},
                {"CAR", "Fixn_car_loop"},
                {"SWEET", "sweet_ass_slap"}
            };
            new idx = random(sizeof(workerAnims));
            ApplyCivilianAnimation(npcid, workerAnims[idx][0], workerAnims[idx][1]);
        }
        case civilian_class_security: {
            ApplyCivilianAnimation(npcid, "COP_AMBIENT", "Coplook_loop");
        }
        case civilian_class_shopkeeper: {
            ApplyCivilianAnimation(npcid, "DEALER", "DEALER_IDLE");
        }
        default: {
            ApplyCivilianAnimation(npcid, "PED", "IDLE_stance");
        }
    }
}

// ========================================
// CIVILIAN DEATH AND RESPAWN HANDLING
// ========================================

forward OnCivilianDeath(civilianid, killerid, weaponid);
public OnCivilianDeath(civilianid, killerid, weaponid) 
{
	LogCivilianAction(civilianid, "Death event triggered");
	
	if (CivilianInfo[civilianid][civilian_target_player] != INVALID_PLAYER_ID) {
		CivilianInfo[civilianid][civilian_target_player] = INVALID_PLAYER_ID;
	}

	// Get death position for potential investigation by other civilians
	static Float:x, Float:y, Float:z;
	FCNPC_GetPosition(civilianid, x, y, z);

	// Different respawn times based on class
	new respawnTime = CIVILIAN_RESPAWN;
	switch(CivilianInfo[civilianid][civilian_class]) {
	    case civilian_class_security: respawnTime *= 2;        // Security takes longer to respawn
	    case civilian_class_worker: respawnTime = respawnTime; // Normal respawn time
	    case civilian_class_shopkeeper: respawnTime *= 3;      // Shopkeepers take longest to respawn
	}

	SetTimerEx("RespawnCivilianWorld", respawnTime, false, "i", civilianid);
	CivilianInfo[civilianid][civilian_inactive] = 1;
	
	// Notify nearby civilians about the death (they might investigate)
	NotifyNearbyCiviliansOfDeath(x, y, z, civilianid, killerid);
	
	return 1;
}

stock NotifyNearbyCiviliansOfDeath(Float:x, Float:y, Float:z, deadCivilianId, killerId)
{
    new count = 0;
    for(new c = 0; c <= GetPlayerPoolSize(); c++) {
        if(!FCNPC_IsValid(c) || c == deadCivilianId) continue;
        if(CivilianInfo[c][civilian_inactive]) continue;
        if(count >= 3) break; // Limit to 3 investigating civilians
        
        new Float:dist = GetPlayerDistanceFromPoint(c, x, y, z);
        if(dist <= 30.0) {
            // Civilian notices the death
            CivilianInfo[c][civilian_investigating_sound] = 1;
            CivilianInfo[c][civilian_target_player] = INVALID_PLAYER_ID;
            CivilianInfo[c][civilian_walktime] = gettime() + (2 + random(5));
            
            LogCivilianAction(c, "Investigating nearby death");
            count++;
        }
    }
}

// ========================================
// CIVILIAN SYSTEM INITIALIZATION
// ========================================

stock Civilian_Init()
{
    print("[Civilian Classes] Initializing civilian system...");
    
    // Initialize configuration
    InitializeCivilianConfig();
    
    // Setup classes
    SetupCivilianClasses();
    
    // Initialize civilians
    InitializeCivilians();
    
    print("[Civilian Classes] Civilian system initialized successfully!");
    return 1;
}

stock Civilian_Exit()
{
    print("[Civilian Classes] Shutting down civilian system...");
    
    // Kill all civilians
    KillAllCivilians();
    
    // Reset system variables
    CivilianSystemActive = false;
    civiliancount = 0;
    TotalCiviliansSpawned = 0;
    
    print("[Civilian Classes] Civilian system shut down completed!");
    return 1;
}

// ========================================
// CIVILIAN CALLBACKS FOR MAIN FILE
// ========================================

stock Civilian_OnPlayerConnect(playerid)
{
    // Initialize player nodes when they connect
    CivilianNodeIndex[playerid] = 0;
    for(new node = 0; node < MAX_PLAYER_NODES; node++) {
        PlayerNodesX[playerid][node] = 0.0;
        PlayerNodesY[playerid][node] = 0.0;
        PlayerNodesZ[playerid][node] = 0.0;
    }
    return 1;
}

stock Civilian_OnPlayerDisconnect(playerid, reason)
{
    // Stop any civilians following this player
    for(new c = 0; c <= GetPlayerPoolSize(); c++) {
        if(FCNPC_IsValid(c) && CivilianInfo[c][civilian_target_player] == playerid) {
            CivilianInfo[c][civilian_target_player] = INVALID_PLAYER_ID;
            CivilianInfo[c][civilian_investigating_sound] = 0;
            CivilianInfo[c][civilian_observing] = 0;
        }
    }
    return 1;
}

stock Civilian_OnPlayerStreamIn(playerid, forplayerid)
{
	if (IsPlayerNPC(playerid) && FCNPC_IsDead(playerid)) {
	    FCNPC_Kill(playerid);
	}
	return 1;
}

#endif // _civilian_classes_included