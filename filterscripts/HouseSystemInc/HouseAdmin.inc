#if defined _HOUSE_ADMIN_INC_
    #endinput
#endif
#define _HOUSE_ADMIN_INC_

#include <a_samp>
#include "HouseConfig.inc"
#include "HouseTypes.inc"
#include "HouseCore.inc"
#include "HousePersistence.inc"

forward HandleAdminCommand(playerid, cmdtext[]);

public HandleAdminCommand(playerid, cmdtext[])
{
    if (!IsPlayerAdminAllowed(playerid)) return 0;

    if (strcmp(cmdtext, "/hlist", true) == 0)
    {
        SendClientMessage(playerid, 0x33CCFFFF, "Lista de casas:");
        for (new i = 0; i < MAX_HOUSES; i++) if (House[i][houseExists])
        {
            new msg[180];
            format(msg, sizeof msg, "ID %d | Nome: %s | Dono: %s | Preco: $%d | Aluguel: $%d | Cofre: $%d",
                i,
                (House[i][houseName][0] ? House[i][houseName] : ("Casa")),
                (House[i][ownerName][0] ? House[i][ownerName] : ("Nenhum")),
                House[i][housePrice],
                House[i][rentPrice],
                House[i][safeBalance]
            );
            SendClientMessage(playerid, 0x99FFFFFF, msg);
        }
        return 1;
    }

    if (!strncmp(cmdtext, "/hgoto", 6, true))
    {
        new tmp[8];
        if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof tmp)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hgoto [id]"), 1;
        new id = strval(tmp);
        if (id < 0 || id >= MAX_HOUSES || !House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "ID invalido."), 1;
        SetPlayerPos(playerid, House[id][entranceX], House[id][entranceY], House[id][entranceZ]);
        SetPlayerInterior(playerid, 0); SetPlayerVirtualWorld(playerid, 0);
        SendClientMessage(playerid, 0x33CC33FF, "Teleportado para a casa.");
        return 1;
    }

    if (!strncmp(cmdtext, "/hsetprice", 10, true))
    {
        new tmpId[8], tmpPrice[16];
        if (!ParseToken(cmdtext, ' ', 1, tmpId, sizeof tmpId) || !ParseToken(cmdtext, ' ', 2, tmpPrice, sizeof tmpPrice))
            return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hsetprice [id] [preco]"), 1;
        new id = strval(tmpId), price = strval(tmpPrice);
        if (id < 0 || id >= MAX_HOUSES || !House[id][houseExists] || price < 0) return SendClientMessage(playerid, 0xFF0000FF, "Parametros invalidos."), 1;
        House[id][housePrice] = price; UpdateHouseVisuals(id); SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Preco atualizado.");
        return 1;
    }

    if (!strncmp(cmdtext, "/hfind", 6, true))
    {
        new query[32];
        if (!ParseToken(cmdtext, ' ', 1, query, sizeof query)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hfind [nome|dono]"), 1;
        SendClientMessage(playerid, 0x33CCFFFF, "Resultados:");
        for (new i = 0; i < MAX_HOUSES; i++) if (House[i][houseExists])
        {
            if (strfind(House[i][houseName], query, true) != -1 || strfind(House[i][ownerName], query, true) != -1)
            {
                new msg[164];
                format(msg, sizeof msg, "ID %d | %s | Dono: %s | $%d", i, House[i][houseName], (House[i][ownerName][0] ? House[i][ownerName] : ("Nenhum")), House[i][housePrice]);
                SendClientMessage(playerid, 0x99FFFFFF, msg);
            }
        }
        return 1;
    }

    return 0;
}