// ========================================
// CIVILIAN AI SYSTEM - PATHFINDING MODULE
// ========================================
// Version: 2.0.0
// Author: SA-MP Civilian AI System
// Description: Pathfinding and movement system for civilians
// ========================================

#if !defined _civilian_pathfinding_included
#define _civilian_pathfinding_included

// ========================================
// PATHFINDING CORE FUNCTIONS
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
// CIVILIAN MOVEMENT FUNCTIONS
// ========================================

stock MoveCivilianToPlayer(civilian, playerid) 
{
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
		LogCivilianAction(civilian, "Moving to player");
		return 1;
	}
	else
	{
		FCNPC_Stop(civilian);
		LogCivilianAction(civilian, "Movement blocked");
	}

	return 0;
}

stock MoveCivilianToPosition(civilian, Float:targetX, Float:targetY, Float:targetZ, maxnodes = 10)
{
    static Float:x, Float:y, Float:z;
    FCNPC_GetPosition(civilian, x, y, z);
    
    if(CA_TraceLineEx(civilian, x, y, z, targetX, targetY, targetZ, .stepsize = 1.5, .maxnodes = maxnodes)) {
        FCNPC_CreateMovement(civilian);
        
        for(new nodes; nodes < CivilianNodeIndex[civilian]; nodes++) {
            FCNPC_AddMovement(civilian, PlayerNodesX[civilian][nodes], PlayerNodesY[civilian][nodes], PlayerNodesZ[civilian][nodes]);
        }
        
        // Determine movement type based on civilian class and distance
        new moveType = DetermineMovementType(civilian, targetX, targetY, targetZ);
        new Float:speed = DetermineMovementSpeed(civilian, moveType);
        
        FCNPC_PlayMovement(civilian, moveType, .speed = speed, .delaystop = 0);
        ApplyMovementAnimation(civilian, moveType);
        
        LogCivilianAction(civilian, "Moving to position");
        return 1;
    }
    
    LogCivilianAction(civilian, "Failed to find path to position");
    return 0;
}

// ========================================
// MOVEMENT BEHAVIOR FUNCTIONS
// ========================================

forward UpdateCivilianMovements(civilian);
public UpdateCivilianMovements(civilian)
{
	if(!ValidateCivilianData(civilian)) return 0;
	
	new Float:x, Float:y, Float:z, Float:tox, Float:toy, Float:toz;
	FCNPC_GetPosition(civilian, x, y, z);

	// Determine movement pattern based on civilian class
	switch(CivilianInfo[civilian][civilian_class]) {
	    case civilian_class_normal, civilian_class_pedestrian: {
	        // Random movement in small area
	        tox = x + frandom(8.0) - frandom(8.0);
	        toy = y + frandom(8.0) - frandom(8.0);
	    }
	    case civilian_class_worker: {
	        // Workers move in larger areas (work sites)
	        tox = x + frandom(15.0) - frandom(15.0);
	        toy = y + frandom(15.0) - frandom(15.0);
	    }
	    case civilian_class_security: {
	        // Security guards patrol in patterns
	        PatrolMovement(civilian);
	        return 1;
	    }
	    case civilian_class_shopkeeper: {
	        // Shopkeepers stay near their spawn area
	        new Float:spawnDist = GetPointDistanceToPoint(x, y, z, 
	            CivilianInfo[civilian][civilian_spawnx], 
	            CivilianInfo[civilian][civilian_spawny], 
	            CivilianInfo[civilian][civilian_spawnz]);
	        
	        if(spawnDist > 10.0) {
	            // Return to spawn area if too far
	            tox = CivilianInfo[civilian][civilian_spawnx] + frandom(5.0) - frandom(5.0);
	            toy = CivilianInfo[civilian][civilian_spawny] + frandom(5.0) - frandom(5.0);
	        } else {
	            // Small movements around shop
	            tox = x + frandom(3.0) - frandom(3.0);
	            toy = y + frandom(3.0) - frandom(3.0);
	        }
	    }
	    default: {
	        tox = x + frandom(6.0) - frandom(6.0);
	        toy = y + frandom(6.0) - frandom(6.0);
	    }
	}
	
	toz = z;

	if (CA_TraceLine(civilian, -1, x, y, z, tox, toy, toz, .stepsize = 1.5, .maxnodes = 2)) {
		FCNPC_CreateMovement(civilian);

	    for(new nodes; nodes < CivilianNodeIndex[civilian]; nodes++) {
	        FCNPC_AddMovement(civilian, PlayerNodesX[civilian][nodes], PlayerNodesY[civilian][nodes], PlayerNodesZ[civilian][nodes]);
	    }

	    new moveType = DetermineMovementType(civilian, tox, toy, toz);
	    new Float:speed = DetermineMovementSpeed(civilian, moveType);
	    
	    FCNPC_PlayMovement(civilian, moveType, .speed = speed, .delaystop = 0);
	    ApplyMovementAnimation(civilian, moveType);
	    
	    LogCivilianAction(civilian, "Random movement executed");
	}

	return 1;
}

stock PatrolMovement(civilian)
{
    static Float:patrolPoints[4][3];
    static patrolIndex[MAX_PLAYERS];
    
    // Initialize patrol points around spawn if not set
    if(patrolIndex[civilian] == 0) {
        new Float:spawnX = CivilianInfo[civilian][civilian_spawnx];
        new Float:spawnY = CivilianInfo[civilian][civilian_spawny];
        new Float:spawnZ = CivilianInfo[civilian][civilian_spawnz];
        
        // Create 4 patrol points in a square pattern
        patrolPoints[0][0] = spawnX + 20.0; patrolPoints[0][1] = spawnY; patrolPoints[0][2] = spawnZ;
        patrolPoints[1][0] = spawnX; patrolPoints[1][1] = spawnY + 20.0; patrolPoints[1][2] = spawnZ;
        patrolPoints[2][0] = spawnX - 20.0; patrolPoints[2][1] = spawnY; patrolPoints[2][2] = spawnZ;
        patrolPoints[3][0] = spawnX; patrolPoints[3][1] = spawnY - 20.0; patrolPoints[3][2] = spawnZ;
        
        patrolIndex[civilian] = 1;
    }
    
    new currentPoint = (patrolIndex[civilian] - 1) % 4;
    MoveCivilianToPosition(civilian, patrolPoints[currentPoint][0], patrolPoints[currentPoint][1], patrolPoints[currentPoint][2]);
    patrolIndex[civilian]++;
}

stock DetermineMovementType(civilian, Float:targetX, Float:targetY, Float:targetZ)
{
    new Float:distance = GetPointDistanceToPoint(
        CivilianInfo[civilian][civilian_spawnx], CivilianInfo[civilian][civilian_spawny], CivilianInfo[civilian][civilian_spawnz],
        targetX, targetY, targetZ
    );
    
    // Determine if civilian should run or walk based on various factors
    new bool:shouldRun = false;
    
    switch(CivilianInfo[civilian][civilian_class]) {
        case civilian_class_worker: {
            if(IsRushHour()) shouldRun = true; // Workers hurry during rush hour
        }
        case civilian_class_security: {
            if(CivilianInfo[civilian][civilian_investigating_sound]) shouldRun = true; // Security runs to investigate
        }
        case civilian_class_normal, civilian_class_pedestrian: {
            if(distance > 50.0) shouldRun = true; // Run if far from spawn
            if(IsNightTime() && random(3) == 0) shouldRun = true; // Sometimes run at night
        }
    }
    
    return shouldRun ? FCNPC_MOVE_TYPE_RUN : FCNPC_MOVE_TYPE_WALK;
}

stock Float:DetermineMovementSpeed(civilian, moveType)
{
    new Float:baseSpeed = CivilianInfo[civilian][civilian_movspeed];
    
    if(moveType == FCNPC_MOVE_TYPE_RUN) {
        baseSpeed *= 1.8; // Running is faster
    }
    
    // Adjust speed based on class
    switch(CivilianInfo[civilian][civilian_class]) {
        case civilian_class_worker: baseSpeed *= 1.1;      // Workers are slightly faster
        case civilian_class_security: baseSpeed *= 1.2;   // Security guards are faster
        case civilian_class_shopkeeper: baseSpeed *= 0.8; // Shopkeepers are slower
    }
    
    // Adjust for time of day
    if(IsNightTime()) {
        baseSpeed *= 0.9; // Slower at night
    }
    
    // Random variation
    baseSpeed += frandom(0.05) - frandom(0.05);
    
    // Ensure minimum speed
    if(baseSpeed < 0.1) baseSpeed = 0.1;
    
    return baseSpeed;
}

stock ApplyMovementAnimation(civilian, moveType)
{
    switch(moveType) {
        case FCNPC_MOVE_TYPE_WALK: {
            ApplyRandomCivilianAnimation(civilian, 1); // Walking animation
        }
        case FCNPC_MOVE_TYPE_RUN: {
            switch(CivilianInfo[civilian][civilian_class]) {
                case civilian_class_security: {
                    ApplyCivilianAnimation(civilian, "PED", "run_civi");
                }
                case civilian_class_worker: {
                    ApplyCivilianAnimation(civilian, "PED", "run_fatman");
                }
                default: {
                    ApplyCivilianAnimation(civilian, "PED", "run_player");
                }
            }
        }
        default: {
            ApplyCivilianAnimation(civilian, "PED", "WALK_player");
        }
    }
}

// ========================================
// OBSTACLE AVOIDANCE
// ========================================

stock bool:IsPathClear(Float:startX, Float:startY, Float:startZ, Float:endX, Float:endY, Float:endZ)
{
    new Float:hitX, Float:hitY, Float:hitZ;
    return !CA_RayCastLine(startX, startY, startZ, endX, endY, endZ, hitX, hitY, hitZ);
}

stock AvoidObstacle(civilian, Float:targetX, Float:targetY, Float:targetZ)
{
    new Float:x, Float:y, Float:z;
    FCNPC_GetPosition(civilian, x, y, z);
    
    // Try alternative paths
    new Float:alternatives[4][3];
    alternatives[0][0] = targetX + 5.0; alternatives[0][1] = targetY; alternatives[0][2] = targetZ;
    alternatives[1][0] = targetX - 5.0; alternatives[1][1] = targetY; alternatives[1][2] = targetZ;
    alternatives[2][0] = targetX; alternatives[2][1] = targetY + 5.0; alternatives[2][2] = targetZ;
    alternatives[3][0] = targetX; alternatives[3][1] = targetY - 5.0; alternatives[3][2] = targetZ;
    
    for(new i = 0; i < 4; i++) {
        if(IsPathClear(x, y, z, alternatives[i][0], alternatives[i][1], alternatives[i][2])) {
            MoveCivilianToPosition(civilian, alternatives[i][0], alternatives[i][1], alternatives[i][2]);
            return 1;
        }
    }
    
    LogCivilianAction(civilian, "No clear path found");
    return 0;
}

// ========================================
// SPECIAL MOVEMENT BEHAVIORS
// ========================================

stock FleeFromPosition(civilian, Float:fleeFromX, Float:fleeFromY, Float:fleeFromZ, Float:fleeDistance = 20.0)
{
    new Float:x, Float:y, Float:z;
    FCNPC_GetPosition(civilian, x, y, z);
    
    // Calculate flee direction
    new Float:angle = GetPointAngleToPoint(fleeFromX, fleeFromY, x, y);
    new Float:fleeX = x + (fleeDistance * floatsin(-angle, degrees));
    new Float:fleeY = y + (fleeDistance * floatcos(-angle, degrees));
    
    // Ensure flee position is safe
    if(IsPositionSafe(fleeX, fleeY, z)) {
        MoveCivilianToPosition(civilian, fleeX, fleeY, z, 5);
        ApplyCivilianAnimation(civilian, "PED", "run_player");
        LogCivilianAction(civilian, "Fleeing from danger");
        return 1;
    }
    
    return 0;
}

stock InvestigatePosition(civilian, Float:investigateX, Float:investigateY, Float:investigateZ)
{
    if(MoveCivilianToPosition(civilian, investigateX, investigateY, investigateZ, 8)) {
        CivilianInfo[civilian][civilian_investigating_sound] = 1;
        CivilianInfo[civilian][civilian_target_player] = INVALID_PLAYER_ID;
        
        // Set investigation timeout
        CivilianInfo[civilian][civilian_walktime] = gettime() + (10 + random(15));
        
        LogCivilianAction(civilian, "Investigating sound location");
        return 1;
    }
    
    return 0;
}

stock ReturnToSpawn(civilian)
{
    new Float:spawnX = CivilianInfo[civilian][civilian_spawnx];
    new Float:spawnY = CivilianInfo[civilian][civilian_spawny];
    new Float:spawnZ = CivilianInfo[civilian][civilian_spawnz];
    
    if(MoveCivilianToPosition(civilian, spawnX, spawnY, spawnZ, 10)) {
        LogCivilianAction(civilian, "Returning to spawn location");
        return 1;
    }
    
    return 0;
}

// ========================================
// MOVEMENT VALIDATION
// ========================================

stock bool:ValidateMovement(civilian, Float:targetX, Float:targetY, Float:targetZ)
{
    // Check if target position is valid
    if(!IsPositionSafe(targetX, targetY, targetZ)) {
        return false;
    }
    
    // Check distance from spawn (prevent civilians from wandering too far)
    new Float:maxDistance = 100.0;
    switch(CivilianInfo[civilian][civilian_class]) {
        case civilian_class_shopkeeper: maxDistance = 20.0;
        case civilian_class_worker: maxDistance = 50.0;
        case civilian_class_security: maxDistance = 80.0;
        case civilian_class_normal, civilian_class_pedestrian: maxDistance = 100.0;
    }
    
    new Float:distanceFromSpawn = GetPointDistanceToPoint(
        targetX, targetY, targetZ,
        CivilianInfo[civilian][civilian_spawnx],
        CivilianInfo[civilian][civilian_spawny],
        CivilianInfo[civilian][civilian_spawnz]
    );
    
    if(distanceFromSpawn > maxDistance) {
        return false;
    }
    
    return true;
}

stock StopCivilianMovement(civilian)
{
    if(!FCNPC_IsValid(civilian)) return 0;
    
    FCNPC_Stop(civilian);
    FCNPC_ClearAnimations(civilian);
    
    // Apply idle animation
    ApplyRandomCivilianAnimation(civilian, 0);
    
    LogCivilianAction(civilian, "Movement stopped");
    return 1;
}

// ========================================
// PATHFINDING UTILITIES
// ========================================

stock Float:frandom(Float:max, Float:min = 0.0)
{
    return float(random(floatround((max - min) * 1000.0))) / 1000.0 + min;
}

stock GetOptimalPathStepSize(civilian, Float:distance)
{
    new Float:stepSize = 1.5;
    
    // Adjust step size based on distance and civilian class
    if(distance < 10.0) {
        stepSize = 1.0; // Smaller steps for short distances
    } else if(distance > 50.0) {
        stepSize = 2.0; // Larger steps for long distances
    }
    
    // Security guards use more precise pathfinding
    if(CivilianInfo[civilian][civilian_class] == civilian_class_security) {
        stepSize *= 0.8;
    }
    
    return stepSize;
}

stock GetMaxPathNodes(civilian, Float:distance)
{
    new maxNodes = 10;
    
    // Adjust max nodes based on distance and performance requirements
    if(distance > 100.0) {
        maxNodes = 20;
    } else if(distance < 20.0) {
        maxNodes = 5;
    }
    
    // Limit nodes for performance on crowded servers
    new activeCivilians = GetActiveCiviliansCount();
    if(activeCivilians > 200) {
        maxNodes = floatround(maxNodes * 0.7);
    }
    
    return maxNodes;
}

#endif // _civilian_pathfinding_included