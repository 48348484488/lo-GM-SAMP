#if defined _HOUSE_UTIL_INC_
    #endinput
#endif
#define _HOUSE_UTIL_INC_

#include <a_samp>
#include "HouseConfig.inc"

forward bool:IsPlayerAdminAllowed(playerid);
forward GetPlayerIdByNameExact(const name[]);

public bool:IsPlayerAdminAllowed(playerid)
{
    #if HOUSE_ADMIN_RCON_ONLY
        return IsPlayerAdmin(playerid);
    #else
        return true;
    #endif
}

public GetPlayerIdByNameExact(const name[])
{
    if (!name[0]) return INVALID_PLAYER_ID;
    new pName[MAX_NAME_LEN];
    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        if (!IsPlayerConnected(i)) continue;
        GetPlayerName(i, pName, sizeof pName);
        if (strcmp(name, pName, true) == 0) return i;
    }
    return INVALID_PLAYER_ID;
}