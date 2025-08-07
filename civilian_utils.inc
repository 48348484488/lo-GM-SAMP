// ========================================
// CIVILIAN AI SYSTEM - UTILITY FUNCTIONS
// ========================================
// Version: 2.0.0
// Author: SA-MP Civilian AI System
// Description: Utility functions for civilian AI system
// ========================================

#if !defined _civilian_utils_included
#define _civilian_utils_included

// ========================================
// MATH AND DISTANCE UTILITIES
// ========================================

stock Float:GetPointDistanceToPoint(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2)
{
	new Float:x, Float:y, Float:z;
 	x = x1 - x2;
  	y = y1 - y2;
  	z = z1 - z2;
  	return floatsqroot(x*x + y*y + z*z);
}

stock Float:GetPointAngleToPoint(Float:x1, Float:y1, Float:x2, Float:y2) 
{
    return 180.0 - atan2(x1 - x2, y1 - y2);
}

stock Float:GetDistance2D(Float:x1, Float:y1, Float:x2, Float:y2)
{
    new Float:x, Float:y;
    x = x1 - x2;
    y = y1 - y2;
    return floatsqroot(x*x + y*y);
}

stock Float:NormalizeAngle(Float:angle)
{
    while(angle < 0.0) angle += 360.0;
    while(angle >= 360.0) angle -= 360.0;
    return angle;
}

stock AngleInRangeOfAngleEx(Float:a1, Float:a2, Float:range)
{
	a1 -= a2;
	if((a1 < range) && (a1 > -range)) return true;
	return false;
}

// ========================================
// PLAYER UTILITIES
// ========================================

stock GetPlayerOnfootSpeed(playerid) 
{
	static Float:velx, Float:vely, Float:velz;
	GetPlayerVelocity(playerid, velx, vely, velz);
	return floatround(floatsqroot(velx*velx + vely*vely + velz*velz) * 135.00);
}

stock bool:IsPlayerInSafeZone(playerid)
{
    // Define safe zones where civilians behave differently
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);
    
    // Hospital areas
    if(IsPointInRangeOfPoint(1612.8, -1894.4, 13.5, x, y, z, 50.0)) return true;  // LS Hospital
    if(IsPointInRangeOfPoint(-2654.0, 640.0, 14.4, x, y, z, 50.0)) return true;   // SF Hospital
    
    // Police stations
    if(IsPointInRangeOfPoint(1544.6, -1675.6, 13.5, x, y, z, 30.0)) return true;  // LS Police
    if(IsPointInRangeOfPoint(-1605.7, 711.1, 13.8, x, y, z, 30.0)) return true;   // SF Police
    
    return false;
}

stock bool:IsPointInRangeOfPoint(Float:x1, Float:y1, Float:z1, Float:x2, Float:y2, Float:z2, Float:range)
{
    return (GetPointDistanceToPoint(x1, y1, z1, x2, y2, z2) <= range);
}

stock AddPlayerNode(playerid) 
{
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
// CIVILIAN UTILITIES
// ========================================

stock GetClosestPlayerToCivilian(npcid, &Float:distance = 0.0) 
{
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

stock CountCiviliansNearPlayer(playerid) 
{
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

stock SetCivilianAngleToPlayer(npcid, playerid) 
{
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

stock IsCivilianViewingPlayer(civilian, playerid) 
{
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

stock bool:IsPointZValid(Float:z1, Float:z2) 
{
	if ((z2 < z1 - 1.3) || (z2 > z1 + 1.3)) return false;
	return true;
}

// ========================================
// ANIMATION UTILITIES
// ========================================

stock ApplyCivilianAnimation(npcid, const animlib[], const animname[], Float:delta = 4.1, loop = 1, lockx = 1, locky = 1, freeze = 1, time = 0)
{
    if(!FCNPC_IsValid(npcid)) return 0;
    
    FCNPC_ClearAnimations(npcid);
    return FCNPC_ApplyAnimation(npcid, animlib, animname, delta, loop, lockx, locky, freeze, time);
}

stock ApplyRandomCivilianAnimation(npcid, type = 0)
{
    new animData[64];
    format(animData, sizeof(animData), "%s", GetRandomCivilianAnimation(type));
    
    new animLib[32], animName[32];
    new pos = strfind(animData, "|", true);
    if(pos != -1) {
        strmid(animLib, animData, 0, pos);
        strmid(animName, animData, pos + 1, strlen(animData));
        return ApplyCivilianAnimation(npcid, animLib, animName);
    }
    return 0;
}

// ========================================
// WEAPON AND DAMAGE UTILITIES
// ========================================

stock Float:ConvertDamage(Float:damage, bodypart) 
{
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

stock Float:GetWeaponDamage(weaponid) 
{
	if (weaponid < 0 || weaponid >= sizeof(s_WeaponsPoints)) {
	    return 0.0;
	}
	return float(s_WeaponsPoints[weaponid]);
}

stock bool:IsFireWeapon(weaponid) 
{
	switch(weaponid) {
	    case 22..34, 38: return true;
	}
	return false;
}

// ========================================
// SYSTEM MANAGEMENT UTILITIES
// ========================================

stock RespawnAllCivilians()
{
    new count = 0;
    for(new npcid = 0; npcid <= GetPlayerPoolSize(); npcid++) {
        if(FCNPC_IsValid(npcid)) {
            FCNPC_Respawn(npcid);
            count++;
        }
    }
    printf("[Civilian Utils] Respawned %d civilians", count);
    return count;
}

stock KillAllCivilians()
{
    new count = 0;
    for(new npcid = 0; npcid <= GetPlayerPoolSize(); npcid++) {
        if(FCNPC_IsValid(npcid)) {
            FCNPC_Kill(npcid);
            count++;
        }
    }
    printf("[Civilian Utils] Killed %d civilians", count);
    return count;
}

stock ResetCivilianData(npcid)
{
    if(npcid < 0 || npcid >= MAX_PLAYERS) return 0;
    
    CivilianInfo[npcid][civilian_id] = INVALID_PLAYER_ID;
    CivilianInfo[npcid][civilian_target_player] = INVALID_PLAYER_ID;
    CivilianInfo[npcid][civilian_pause] = 0;
    CivilianInfo[npcid][civilian_pause_init] = 0;
    CivilianInfo[npcid][civilian_inactive] = 1;
    CivilianInfo[npcid][civilian_speaking] = 0;
    CivilianInfo[npcid][civilian_investigating_sound] = 0;
    CivilianInfo[npcid][civilian_observing] = 0;
    CivilianInfo[npcid][civilian_walktime] = 0;
    CivilianInfo[npcid][civilian_class] = 0;
    CivilianInfo[npcid][civilian_class_default] = 0;
    CivilianInfo[npcid][civilian_lastupdate] = 0;
    CivilianInfo[npcid][civilian_interaction_delay] = 0;
    CivilianInfo[npcid][civilian_health] = 0.0;
    CivilianInfo[npcid][civilian_velocity] = 0.0;
    CivilianInfo[npcid][civilian_detection] = 0.0;
    CivilianInfo[npcid][civilian_interaction_range] = 0.0;
    CivilianInfo[npcid][civilian_spawnx] = 0.0;
    CivilianInfo[npcid][civilian_spawny] = 0.0;
    CivilianInfo[npcid][civilian_spawnz] = 0.0;
    CivilianInfo[npcid][civilian_lastx] = 0.0;
    CivilianInfo[npcid][civilian_lasty] = 0.0;
    CivilianInfo[npcid][civilian_lastz] = 0.0;
    CivilianInfo[npcid][civilian_movtype] = 0;
    CivilianInfo[npcid][civilian_movspeed] = 0.0;
    
    CivilianNodeIndex[npcid] = 0;
    
    return 1;
}

// ========================================
// POSITION AND AREA UTILITIES
// ========================================

stock GetSafeSpawnPosition(Float:&x, Float:&y, Float:&z)
{
    // Get a random spawn position
    new spawnIndex = random(sizeof(Civilian_Spawns));
    x = Civilian_Spawns[spawnIndex][0];
    y = Civilian_Spawns[spawnIndex][1];
    z = Civilian_Spawns[spawnIndex][2];
    
    // Adjust Z coordinate to ground level using ColAndreas
    new Float:groundZ;
    if(CA_RayCastLine(x, y, z + 5.0, x, y, z - 100.0, x, y, groundZ)) {
        z = groundZ + 1.0;
    }
    
    return 1;
}

stock bool:IsPositionSafe(Float:x, Float:y, Float:z)
{
    // Check if position is in water
    if(z < -50.0) return false;
    
    // Check if position is too high
    if(z > 200.0) return false;
    
    // Check for obstacles using ColAndreas
    new Float:hitX, Float:hitY, Float:hitZ;
    if(CA_RayCastLine(x, y, z + 1.0, x, y, z - 2.0, hitX, hitY, hitZ)) {
        return false;
    }
    
    return true;
}

stock GetNearbyPlayers(Float:x, Float:y, Float:z, Float:range, players[], maxplayers = 10)
{
    new count = 0;
    foreach(new playerid : Player) {
        if(count >= maxplayers) break;
        if(GetPlayerDistanceFromPoint(playerid, x, y, z) <= range) {
            players[count] = playerid;
            count++;
        }
    }
    return count;
}

// ========================================
// TIME AND SCHEDULING UTILITIES
// ========================================

stock GetServerUptime()
{
    return gettime() - CivilianSystemStartTime;
}

stock bool:IsNightTime()
{
    new hour, minute, second;
    gettime(hour, minute, second);
    return (hour >= 20 || hour <= 6);
}

stock bool:IsRushHour()
{
    new hour, minute, second;
    gettime(hour, minute, second);
    return ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19));
}

// ========================================
// DEBUG AND LOGGING UTILITIES
// ========================================

stock LogCivilianAction(npcid, const action[])
{
    #if defined CIVILIAN_DEBUG_MODE
    new Float:x, Float:y, Float:z;
    FCNPC_GetPosition(npcid, x, y, z);
    printf("[Civilian Debug] ID: %d | Action: %s | Pos: %.2f, %.2f, %.2f", npcid, action, x, y, z);
    #endif
}

stock ValidateCivilianData(npcid)
{
    if(npcid < 0 || npcid >= MAX_PLAYERS) return 0;
    if(!FCNPC_IsValid(npcid)) return 0;
    if(CivilianInfo[npcid][civilian_inactive]) return 0;
    return 1;
}

// ========================================
// STRING AND TEXT UTILITIES
// ========================================

stock FormatTime(seconds, output[], maxlen = sizeof(output))
{
    new hours = seconds / 3600;
    new minutes = (seconds % 3600) / 60;
    new secs = seconds % 60;
    
    if(hours > 0) {
        format(output, maxlen, "%02d:%02d:%02d", hours, minutes, secs);
    } else {
        format(output, maxlen, "%02d:%02d", minutes, secs);
    }
    return 1;
}

stock GetCivilianClassName(classid, output[], maxlen = sizeof(output))
{
    switch(classid) {
        case civilian_class_normal: format(output, maxlen, "Normal");
        case civilian_class_worker: format(output, maxlen, "Worker");
        case civilian_class_security: format(output, maxlen, "Security");
        case civilian_class_shopkeeper: format(output, maxlen, "Shopkeeper");
        case civilian_class_pedestrian: format(output, maxlen, "Pedestrian");
        case civilian_class_tourist: format(output, maxlen, "Tourist");
        default: format(output, maxlen, "Unknown");
    }
    return 1;
}

// ========================================
// PERFORMANCE UTILITIES
// ========================================

stock OptimizeCivilianPerformance()
{
    new active = 0, inactive = 0;
    
    for(new npcid = 0; npcid <= GetPlayerPoolSize(); npcid++) {
        if(!FCNPC_IsValid(npcid)) continue;
        
        if(CivilianInfo[npcid][civilian_inactive]) {
            inactive++;
        } else {
            active++;
            
            // Optimize update rates based on distance to players
            new Float:minDist = 999999.0;
            foreach(new playerid : Player) {
                new Float:dist = GetPlayerDistanceFromPoint(playerid, 
                    CivilianInfo[npcid][civilian_spawnx], 
                    CivilianInfo[npcid][civilian_spawny], 
                    CivilianInfo[npcid][civilian_spawnz]);
                if(dist < minDist) minDist = dist;
            }
            
            // Adjust update frequency based on distance
            if(minDist > 100.0) {
                CivilianInfo[npcid][civilian_lastupdate] += 500; // Slower updates
            }
        }
    }
    
    printf("[Civilian Utils] Performance optimization: %d active, %d inactive", active, inactive);
    return 1;
}

#endif // _civilian_utils_included