#if defined _HOUSE_TYPES_INC_
    #endinput
#endif
#define _HOUSE_TYPES_INC_

#include <a_samp>
#include "HouseConfig.inc"

enum HouseData {
    bool:houseExists,
    housePrice,
    Float:entranceX,
    Float:entranceY,
    Float:entranceZ,
    Float:exitX,
    Float:exitY,
    Float:exitZ,
    entranceInterior,
    houseWorld,
    housePickup,
    Text3D:houseLabel,
    ownerName[MAX_NAME_LEN],
    bool:isLocked,
    houseName[MAX_HOUSE_NAME],
    rentPrice,
    maxRenters,
    keysCsv[MAX_CSV_LEN],
    rentersCsv[MAX_CSV_LEN],
    bool:ownerSpawnAtHouse,
    interiorId,
    safeBalance,
    inviteesCsv[MAX_CSV_LEN],
    inviteExpiresAt,
    missedTaxCount
};

new House[MAX_HOUSES][HouseData];
new totalHouses;