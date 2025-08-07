// ========================================
// CIVILIAN AI SYSTEM - AI MODULE
// ========================================
// Version: 2.0.0
// Author: SA-MP Civilian AI System
// Description: AI behavior and interaction system for civilians
// ========================================

#if !defined _civilian_ai_included
#define _civilian_ai_included

// ========================================
// MAIN AI UPDATE SYSTEM
// ========================================

stock Civilian_FCNPC_OnUpdate(npcid)
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

        // Civilian speaking/greeting sounds (occasional)
		if(CivilianInfo[npcid][civilian_speaking] < GetTickCount() && CivilianInfo[npcid][civilian_class] != civilian_class_security) {
		    static Float:pos[3];
		    FCNPC_GetPosition(npcid, pos[0], pos[1], pos[2]);
		    CivilianInfo[npcid][civilian_speaking] = GetTickCount() + (20000 + random(30000));
		    // Could add greeting sounds here
		    LogCivilianAction(npcid, "Speaking/greeting");
		}
	}
	return 1;
}

// ========================================
// CIVILIAN INTERACTION BEHAVIORS
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
	    LogCivilianAction(civilian, "Switched target player");
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
			HandleCloseProximityInteraction(civilian, civilianTargetPlayer, currentClosestPlayer);
			return 1;
 	    }

		// Move towards player if not in interaction
		if (!FCNPC_IsAttacking(civilian)) {
		    if (MoveCivilianToPlayer(civilian, civilianTargetPlayer))
        	{
        	    ApplyMovementAnimation(civilian, FCNPC_MOVE_TYPE_WALK);
        	}
        	else
        	{
        	    if (FCNPC_IsMoving(civilian))
        	        FCNPC_Stop(civilian);
        	    ApplyRandomCivilianAnimation(civilian, 0); // Idle
        	}
		}
	} else {
        // Stop following player
        StopCivilianInteraction(civilian);
	}
	return 1;
}

stock HandleCloseProximityInteraction(civilian, civilianTargetPlayer, currentClosestPlayer)
{
    switch(CivilianInfo[civilian][civilian_class]) {
        case civilian_class_security: {
            HandleSecurityInteraction(civilian, civilianTargetPlayer, currentClosestPlayer);
        }
        case civilian_class_worker: {
            HandleWorkerInteraction(civilian, civilianTargetPlayer);
        }
        case civilian_class_shopkeeper: {
            HandleShopkeeperInteraction(civilian, civilianTargetPlayer);
        }
        case civilian_class_normal, civilian_class_pedestrian: {
            HandleNormalCivilianInteraction(civilian, civilianTargetPlayer);
        }
        default: {
            HandleNormalCivilianInteraction(civilian, civilianTargetPlayer);
        }
    }
}

stock HandleSecurityInteraction(civilian, playerid, currentClosestPlayer)
{
    if (IsCivilianViewingPlayer(civilian, currentClosestPlayer)) {
        if (FCNPC_IsMoving(civilian))
            FCNPC_Stop(civilian);
            
        // Security guards watch players but don't aim weapons unless threatened
        SetCivilianAngleToPlayer(civilian, playerid);
        
        // Alert posture
        ApplyCivilianAnimation(civilian, "COP_AMBIENT", "Coplook_loop");
        
        CivilianInfo[civilian][civilian_pause] = GetTickCount() + CIVILIAN_UPDATE_TIME;
        LogCivilianAction(civilian, "Security watching player");
    } else {
        MoveCivilianToPlayer(civilian, playerid);
    }
}

stock HandleWorkerInteraction(civilian, playerid)
{
    FCNPC_Stop(civilian);
    SetCivilianAngleToPlayer(civilian, playerid);
    
    // Workers give a casual wave or nod
    new workerGreets[][2][32] = {
        {"GANGS", "hndshkfa"},
        {"ON_LOOKERS", "wave_loop"},
        {"PED", "IDLE_chat"}
    };
    
    new idx = random(sizeof(workerGreets));
    ApplyCivilianAnimation(civilian, workerGreets[idx][0], workerGreets[idx][1]);
    
    CivilianInfo[civilian][civilian_pause] = GetTickCount() + CIVILIAN_UPDATE_TIME;
    LogCivilianAction(civilian, "Worker greeting player");
}

stock HandleShopkeeperInteraction(civilian, playerid)
{
    FCNPC_Stop(civilian);
    SetCivilianAngleToPlayer(civilian, playerid);
    
    // Shopkeepers are welcoming
    ApplyCivilianAnimation(civilian, "DEALER", "DEALER_IDLE");
    
    CivilianInfo[civilian][civilian_pause] = GetTickCount() + (CIVILIAN_UPDATE_TIME * 2);
    LogCivilianAction(civilian, "Shopkeeper welcoming player");
}

stock HandleNormalCivilianInteraction(civilian, playerid)
{
    FCNPC_Stop(civilian);
    if (!FCNPC_IsAttacking(civilian))
        FCNPC_ClearAnimations(civilian);

    SetCivilianAngleToPlayer(civilian, playerid);
    
    // Friendly gesture animation
    ApplyRandomCivilianAnimation(civilian, 2); // Greeting animations
    
    CivilianInfo[civilian][civilian_pause] = GetTickCount() + CIVILIAN_UPDATE_TIME;
    LogCivilianAction(civilian, "Normal civilian greeting");
}

// ========================================
// IDLE BEHAVIOR SYSTEM
// ========================================

stock UpdateCivilianIdleMovements(civilian) 
{
	// Check if it's time to move
	if (gettime() > CivilianInfo[civilian][civilian_walktime] && !CivilianInfo[civilian][civilian_investigating_sound]) {
	    
	    // Different movement patterns based on class
	    switch(CivilianInfo[civilian][civilian_class]) {
	        case civilian_class_security: {
	            if(random(3) == 0) { // 33% chance to patrol
	                PatrolMovement(civilian);
	            } else {
	                UpdateCivilianMovements(civilian);
	            }
	        }
	        case civilian_class_worker: {
	            if(IsRushHour()) {
	                // Workers are more active during rush hour
	                CivilianInfo[civilian][civilian_walktime] = gettime() + (5 + random(10));
	            } else {
	                CivilianInfo[civilian][civilian_walktime] = gettime() + (20 + random(30));
	            }
	            UpdateCivilianMovements(civilian);
	        }
	        case civilian_class_shopkeeper: {
	            // Shopkeepers move less frequently
	            CivilianInfo[civilian][civilian_walktime] = gettime() + (30 + random(45));
	            UpdateCivilianMovements(civilian);
	        }
	        default: {
	            CivilianInfo[civilian][civilian_walktime] = gettime() + (15 + random(25));
	            UpdateCivilianMovements(civilian);
	        }
	    }
	}

	// Check for nearby players to potentially interact with
	new Float:currentDistanceBetween;
	new currentClosestPlayer = GetClosestPlayerToCivilian(civilian, currentDistanceBetween);
	
	if (currentClosestPlayer != INVALID_PLAYER_ID && 
	    currentDistanceBetween < CivilianInfo[civilian][civilian_detection] && 
	    IsCivilianViewingPlayer(civilian, currentClosestPlayer)) {
	    
	    CivilianInfo[civilian][civilian_target_player] = currentClosestPlayer;
	    CivilianInfo[civilian][civilian_investigating_sound] = 0;
	    CivilianInfo[civilian][civilian_observing] = 0;
	    LogCivilianAction(civilian, "Detected nearby player");
	}
}

stock StopCivilianInteraction(civilian) 
{
	if (CivilianInfo[civilian][civilian_target_player] != INVALID_PLAYER_ID) {
	    CivilianInfo[civilian][civilian_target_player] = INVALID_PLAYER_ID;

		FCNPC_Stop(civilian);
		FCNPC_ClearAnimations(civilian);
	    FCNPC_StopAttack(civilian);
	    FCNPC_StopAim(civilian);

	    ApplyRandomCivilianAnimation(civilian, 0); // Idle animation
	    CivilianInfo[civilian][civilian_walktime] = gettime() + (8 + random(15));
	    LogCivilianAction(civilian, "Stopped player interaction");
	}
}

// ========================================
// SOUND INVESTIGATION SYSTEM
// ========================================

stock Civilian_OnPlayerWeaponShot(playerid, weaponid, hittype, hitid, Float:fX, Float:fY, Float:fZ)
{
	if (tickSound < GetTickCount()) {
		static Float:x, Float:y, Float:z, Float:w;
		GetPlayerPos(playerid, x, y, z);

		if(!CA_RayCastLine(x, y, z, x, y, z + 100.0, w, w, w)) {
		    CreateSoundDisturbance(x, y, z);
		}
	}
}

stock CreateSoundDisturbance(Float:x, Float:y, Float:z, Float:distance = SOUND_INVESTIGATION_DISTANCE)
{
	if (tickSound > GetTickCount()) return 0;
    tickSound = GetTickCount() + SOUND_COOLDOWN_TIME;

    new countInvestigatingCivilians = 0;

	for (new cc = GetPlayerPoolSize(), civilian; civilian <= cc; civilian++)
	{
		if (!FCNPC_IsValid(civilian)) continue;
	    if (CivilianInfo[civilian][civilian_inactive]) continue;
	    if (CivilianInfo[civilian][civilian_target_player] != INVALID_PLAYER_ID) continue;
	    if (countInvestigatingCivilians >= MAX_INVESTIGATING_CIVILIANS) break;

	    if (IsPlayerInRangeOfPoint(civilian, distance, x, y, z))
		{
		    // Different classes react differently to gunshots
		    if(!ShouldCivilianInvestigateSound(civilian, x, y, z)) continue;
		    
		    countInvestigatingCivilians++;
		    InvestigatePosition(civilian, x, y, z);
		}
	}
	
	printf("[Civilian AI] %d civilians investigating sound disturbance", countInvestigatingCivilians);
	return 1;
}

stock bool:ShouldCivilianInvestigateSound(civilian, Float:x, Float:y, Float:z)
{
    new Float:distance = GetPlayerDistanceFromPoint(civilian, x, y, z);
    
    switch(CivilianInfo[civilian][civilian_class]) {
        case civilian_class_security: {
            // Security always investigates within their range
            return (distance <= 80.0);
        }
        case civilian_class_worker: {
            // Workers are moderately curious
            return (distance <= 40.0 && random(2) == 0);
        }
        case civilian_class_shopkeeper: {
            // Shopkeepers are cautious and rarely investigate
            return (distance <= 20.0 && random(4) == 0);
        }
        case civilian_class_normal, civilian_class_pedestrian: {
            // Normal civilians are somewhat curious
            return (distance <= 50.0 && random(3) == 0);
        }
    }
    
    return false;
}

// ========================================
// DAMAGE AND COMBAT SYSTEM
// ========================================

stock Civilian_FCNPC_OnTakeDamage(npcid, issuerid, Float:amount, weaponid, bodypart) 
{
	if (CivilianInfo[npcid][civilian_inactive]) return 0;

	// Only security guards can take combat damage, others just flee
	if (CivilianInfo[npcid][civilian_class] != civilian_class_security) {
		HandleCivilianFlee(npcid, issuerid);
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
		LogCivilianAction(npcid, "Security guard killed");
	    CivilianInfo[npcid][civilian_inactive] = 1;
	   	FCNPC_Kill(npcid);
	}
	return 1;
}

stock HandleCivilianFlee(npcid, attackerId)
{
    if (attackerId != INVALID_PLAYER_ID) {
        CivilianInfo[npcid][civilian_target_player] = INVALID_PLAYER_ID;
        FCNPC_Stop(npcid);
        
        // Get attacker position for flee calculation
        static Float:px, Float:py, Float:pz, Float:cx, Float:cy, Float:cz;
        GetPlayerPos(attackerId, px, py, pz);
        FCNPC_GetPosition(npcid, cx, cy, cz);
        
        // Flee away from attacker
        FleeFromPosition(npcid, px, py, pz, 25.0);
        
        // Alert nearby civilians about danger
        AlertNearbyCiviliansOfDanger(cx, cy, cz, attackerId);
        
        LogCivilianAction(npcid, "Fleeing from attacker");
    }
}

stock AlertNearbyCiviliansOfDanger(Float:x, Float:y, Float:z, attackerId)
{
    for(new c = 0; c <= GetPlayerPoolSize(); c++) {
        if(!FCNPC_IsValid(c)) continue;
        if(CivilianInfo[c][civilian_inactive]) continue;
        
        new Float:dist = GetPlayerDistanceFromPoint(c, x, y, z);
        if(dist <= 30.0) {
            // Nearby civilians also flee or become alert
            switch(CivilianInfo[c][civilian_class]) {
                case civilian_class_security: {
                    // Security becomes alert and investigates
                    CivilianInfo[c][civilian_target_player] = attackerId;
                    LogCivilianAction(c, "Security alerted to danger");
                }
                case civilian_class_normal, civilian_class_pedestrian, civilian_class_shopkeeper: {
                    // Regular civilians flee if close enough
                    if(dist <= 15.0) {
                        FleeFromPosition(c, x, y, z, 20.0);
                        LogCivilianAction(c, "Fleeing from nearby danger");
                    }
                }
            }
        }
    }
}

// ========================================
// FCNPC CALLBACK HANDLERS
// ========================================

stock Civilian_FCNPC_OnMovementEnd(npcid) 
{
	if (CivilianInfo[npcid][civilian_inactive]) return 0;

	if (CivilianInfo[npcid][civilian_target_player] == INVALID_PLAYER_ID) {
		FCNPC_ClearAnimations(npcid);
		ApplyRandomCivilianAnimation(npcid, 0); // Idle animation

		if(CivilianInfo[npcid][civilian_investigating_sound]) {
			FCNPC_Stop(npcid);
			// When reaching sound location, look around
	   		CivilianInfo[npcid][civilian_observing] = 1;
	   		CivilianInfo[npcid][civilian_walktime] = gettime() + (5 + random(12));
	   		
	   		// Look around animation
	   		ApplyCivilianAnimation(npcid, "PED", "IDLE_lookd");
	   		LogCivilianAction(npcid, "Reached investigation point");
		}
	}
	return 1;
}

stock Civilian_FCNPC_OnRespawn(npcid) 
{
    RespawnCivilian(npcid);
	return 1;
}

stock Civilian_FCNPC_OnSpawn(npcid) 
{
	RespawnCivilian(npcid);
	return 1;
}

stock Civilian_FCNPC_OnDeath(npcid, killerid, reason) 
{
	if (!CivilianInfo[npcid][civilian_inactive]) {
        OnCivilianDeath(npcid, killerid, reason);
	}
	LogCivilianAction(npcid, "Death callback triggered");
	return 1;
}

// ========================================
// PLAYER INTERACTION CALLBACKS
// ========================================

stock Civilian_OnPlayerUpdate(playerid)
{
	AddPlayerNode(playerid);
	return 1;
}

// ========================================
// ADVANCED AI BEHAVIORS
// ========================================

stock UpdateCivilianEmotionalState(civilian)
{
    // Simple emotional state system based on recent events
    static lastEventTime[MAX_PLAYERS];
    static emotionalState[MAX_PLAYERS]; // 0=neutral, 1=happy, 2=scared, 3=angry
    
    new currentTime = gettime();
    
    // Decay emotional state over time
    if(currentTime - lastEventTime[civilian] > 60) { // 1 minute
        emotionalState[civilian] = 0; // Return to neutral
    }
    
    // Apply emotional state effects
    switch(emotionalState[civilian]) {
        case 1: { // Happy
            CivilianInfo[civilian][civilian_movspeed] *= 1.1;
            CivilianInfo[civilian][civilian_detection] *= 1.2; // More aware when happy
        }
        case 2: { // Scared
            CivilianInfo[civilian][civilian_movspeed] *= 0.8;
            CivilianInfo[civilian][civilian_detection] *= 0.7; // Less aware when scared
        }
        case 3: { // Angry (only for security)
            if(CivilianInfo[civilian][civilian_class] == civilian_class_security) {
                CivilianInfo[civilian][civilian_detection] *= 1.5;
                CivilianInfo[civilian][civilian_movspeed] *= 1.3;
            }
        }
    }
}

stock ProcessCivilianPersonality(civilian)
{
    // Give civilians slight personality variations
    static personalityInit[MAX_PLAYERS];
    static Float:personalityMod[MAX_PLAYERS];
    
    if(!personalityInit[civilian]) {
        personalityMod[civilian] = 0.8 + frandom(0.4); // 0.8 to 1.2 multiplier
        personalityInit[civilian] = 1;
    }
    
    // Apply personality to various attributes
    CivilianInfo[civilian][civilian_movspeed] *= personalityMod[civilian];
    CivilianInfo[civilian][civilian_detection] *= personalityMod[civilian];
    
    // Adjust walk time based on personality
    if(personalityMod[civilian] > 1.0) {
        // More active personality
        CivilianInfo[civilian][civilian_walktime] = gettime() + floatround((15 + random(20)) * (2.0 - personalityMod[civilian]));
    }
}

stock HandleCivilianContextualBehavior(civilian)
{
    // Adjust behavior based on time of day and context
    if(IsNightTime()) {
        // Civilians are more cautious at night
        CivilianInfo[civilian][civilian_detection] *= 0.8;
        CivilianInfo[civilian][civilian_movspeed] *= 0.9;
        
        // Security guards are more alert at night
        if(CivilianInfo[civilian][civilian_class] == civilian_class_security) {
            CivilianInfo[civilian][civilian_detection] *= 1.4;
        }
    }
    
    if(IsRushHour()) {
        // More activity during rush hours
        switch(CivilianInfo[civilian][civilian_class]) {
            case civilian_class_worker: {
                CivilianInfo[civilian][civilian_movspeed] *= 1.3;
                CivilianInfo[civilian][civilian_walktime] = gettime() + (5 + random(10));
            }
            case civilian_class_normal, civilian_class_pedestrian: {
                CivilianInfo[civilian][civilian_movspeed] *= 1.1;
            }
        }
    }
}

// ========================================
// PERFORMANCE OPTIMIZATION
// ========================================

stock OptimizeCivilianAI()
{
    new activeCivilians = GetActiveCiviliansCount();
    
    // Adjust update frequencies based on server load
    if(activeCivilians > 300) {
        // Reduce update frequency for distant civilians
        for(new c = 0; c <= GetPlayerPoolSize(); c++) {
            if(!ValidateCivilianData(c)) continue;
            
            new Float:minPlayerDist = 999999.0;
            foreach(new playerid : Player) {
                new Float:dist = GetPlayerDistanceFromPoint(playerid, 
                    CivilianInfo[c][civilian_spawnx], 
                    CivilianInfo[c][civilian_spawny], 
                    CivilianInfo[c][civilian_spawnz]);
                if(dist < minPlayerDist) minPlayerDist = dist;
            }
            
            // Slow down updates for distant civilians
            if(minPlayerDist > 100.0) {
                CivilianInfo[c][civilian_lastupdate] += 1000; // 1 second delay
            }
        }
    }
}

// ========================================
// DEBUG AND MONITORING
// ========================================

stock DebugCivilianAI(civilian)
{
    #if defined CIVILIAN_DEBUG_MODE
    new Float:x, Float:y, Float:z;
    FCNPC_GetPosition(civilian, x, y, z);
    
    new className[32];
    GetCivilianClassName(CivilianInfo[civilian][civilian_class], className);
    
    new targetInfo[64] = "None";
    if(CivilianInfo[civilian][civilian_target_player] != INVALID_PLAYER_ID) {
        new targetName[MAX_PLAYER_NAME];
        GetPlayerName(CivilianInfo[civilian][civilian_target_player], targetName, sizeof(targetName));
        format(targetInfo, sizeof(targetInfo), "Player %s", targetName);
    }
    
    printf("[AI Debug] Civilian %d | Class: %s | Pos: %.1f,%.1f,%.1f | Target: %s | Health: %.1f", 
        civilian, className, x, y, z, targetInfo, CivilianInfo[civilian][civilian_health]);
    #endif
}

#endif // _civilian_ai_included