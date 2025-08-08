#if defined _HOUSE_CORE_INC_
    #endinput
#endif
#define _HOUSE_CORE_INC_

#include <a_samp>
#include "HouseConfig.inc"
#include "HouseTypes.inc"
#include "HouseCSV.inc"
#include "HouseUtil.inc"
#include "HousePersistence.inc"

forward UpdateHouseVisuals(houseId);
forward DestroyHouseVisuals(houseId);
forward GetNearestHouse(playerid);
forward GetFreeHouseId();
forward HousePayday();
forward bool:IsHouseOwner(playerid, houseId);
forward bool:IsHouseKeyHolder(playerid, houseId);
forward bool:IsHouseRenter(playerid, houseId);
forward bool:PlayerOwnsAnyHouse(playerid);
forward CanPlayerEnterHouse(playerid, houseId);

public UpdateHouseVisuals(houseId)
{
    if (houseId < 0 || houseId >= MAX_HOUSES) return 0;

    DestroyHouseVisuals(houseId);
    if (!House[houseId][houseExists]) return 1;

    new model = (House[houseId][ownerName][0] == '\0') ? HOUSE_PICKUP_FORSALE : HOUSE_PICKUP_OWNED;
    House[houseId][housePickup] = CreatePickup(model, 1, House[houseId][entranceX], House[houseId][entranceY], House[houseId][entranceZ], HOUSE_PICKUP_VW);

    new text[196];
    if (House[houseId][ownerName][0] == '\0')
        format(text, sizeof text, "%s\nID: %d | Preco: $%d\n/hbuy para comprar", (House[houseId][houseName][0] ? House[houseId][houseName] : ("Casa")), houseId, House[houseId][housePrice]);
    else
        format(text, sizeof text, "%s\nDono: %s | %s\nAluguel: $%d | Vagas: %d/%d\n/henter",
            (House[houseId][houseName][0] ? House[houseId][houseName] : ("Casa")),
            House[houseId][ownerName],
            (House[houseId][isLocked] ? ("Trancada") : ("Aberta")),
            House[houseId][rentPrice],
            CsvCount(House[houseId][rentersCsv]),
            House[houseId][maxRenters]
        );

    House[houseId][houseLabel] = Create3DTextLabel(text, 0xFFFFFFFF, House[houseId][entranceX], House[houseId][entranceY], House[houseId][entranceZ] + 0.5, HOUSE_LABEL_DRAWDIST, 0, 1);

    return 1;
}

public DestroyHouseVisuals(houseId)
{
    if (houseId < 0 || houseId >= MAX_HOUSES) return 0;
    if (House[houseId][housePickup] != 0)
    {
        DestroyPickup(House[houseId][housePickup]);
        House[houseId][housePickup] = 0;
    }
    if (House[houseId][houseLabel] != Text3D:0)
    {
        Delete3DTextLabel(House[houseId][houseLabel]);
        House[houseId][houseLabel] = Text3D:0;
    }
    return 1;
}

public GetFreeHouseId()
{
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!House[i][houseExists])
            return i;
    }
    return -1;
}

public GetNearestHouse(playerid)
{
    new nearest = -1;
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!House[i][houseExists]) continue;
        if (IsPlayerInRangeOfPoint(playerid, HOUSE_ENTER_RANGE, House[i][entranceX], House[i][entranceY], House[i][entranceZ]))
        {
            nearest = i;
            break;
        }
    }
    return nearest;
}

public HousePayday()
{
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!House[i][houseExists]) continue;

        // Rent collection to safe
        if (House[i][rentPrice] > 0 && House[i][rentersCsv][0])
        {
            new tmp[MAX_CSV_LEN]; strmid(tmp, House[i][rentersCsv], 0, MAX_CSV_LEN);
            new token[MAX_NAME_LEN]; new start = 0, len = strlen(tmp);
            for (new j = 0; j <= len; j++) if (tmp[j] == ',' || tmp[j] == '\0')
            {
                if (j - start > 0)
                {
                    strmid(token, tmp, start, j);
                    new tl = j - start; if (tl > (MAX_NAME_LEN - 1)) tl = (MAX_NAME_LEN - 1); if (tl < 0) tl = 0;
                    token[tl] = '\0';
                    new renterId = GetPlayerIdByNameExact(token);
                    if (renterId != INVALID_PLAYER_ID)
                    {
                        if (GetPlayerMoney(renterId) >= House[i][rentPrice])
                        {
                            GivePlayerMoney(renterId, -House[i][rentPrice]);
                            House[i][safeBalance] += House[i][rentPrice];
                            new msg[96]; format(msg, sizeof msg, "[Aluguel] Voce pagou $%d na casa %d.", House[i][rentPrice], i);
                            SendClientMessage(renterId, 0x33CCFFFF, msg);
                        }
                        else
                        {
                            CsvRemoveName(House[i][rentersCsv], MAX_CSV_LEN, token);
                            UpdateHouseVisuals(i);
                        }
                    }
                }
                start = j + 1;
            }
        }

        // Maintenance tax
        if (House[i][ownerName][0])
        {
            new tax = MAINTENANCE_TAX_PER_PAYDAY;
            if (House[i][safeBalance] >= tax) { House[i][safeBalance] -= tax; House[i][missedTaxCount] = 0; }
            else
            {
                new ownerId = GetPlayerIdByNameExact(House[i][ownerName]);
                if (ownerId != INVALID_PLAYER_ID && GetPlayerMoney(ownerId) >= tax)
                { GivePlayerMoney(ownerId, -tax); House[i][missedTaxCount] = 0; }
                else
                {
                    House[i][missedTaxCount]++;
                    if (House[i][missedTaxCount] >= MAX_MISSED_TAXES)
                    {
                        House[i][ownerName][0] = '\0';
                        House[i][isLocked] = false;
                        House[i][keysCsv][0] = '\0';
                        House[i][rentersCsv][0] = '\0';
                        House[i][rentPrice] = 0;
                        House[i][safeBalance] = 0;
                        House[i][missedTaxCount] = 0;
                        UpdateHouseVisuals(i);
                        if (ownerId != INVALID_PLAYER_ID)
                            SendClientMessage(ownerId, 0xFF0000FF, "[Casa] Sua propriedade foi penhorada por inadimplencia.");
                    }
                }
            }
        }
    }
    SaveAllHouses();
    return 1;
}

public bool:IsHouseOwner(playerid, houseId)
{
    if (houseId < 0 || !House[houseId][houseExists]) return false;
    new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
    return (House[houseId][ownerName][0] && strcmp(name, House[houseId][ownerName], true) == 0);
}

public bool:IsHouseKeyHolder(playerid, houseId)
{
    new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
    return CsvContainsName(House[houseId][keysCsv], name);
}

public bool:IsHouseRenter(playerid, houseId)
{
    new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
    return CsvContainsName(House[houseId][rentersCsv], name);
}

public bool:PlayerOwnsAnyHouse(playerid)
{
    new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!House[i][houseExists]) continue;
        if (House[i][ownerName][0] && strcmp(name, House[i][ownerName], true) == 0) return true;
    }
    return false;
}

public CanPlayerEnterHouse(playerid, houseId)
{
    if (!House[houseId][isLocked]) return 1;
    if (IsHouseOwner(playerid, houseId)) return 1;
    if (IsHouseKeyHolder(playerid, houseId)) return 1;
    if (IsHouseRenter(playerid, houseId)) return 1;

    if (House[houseId][inviteExpiresAt] > 0 && GetTickCount() <= House[houseId][inviteExpiresAt])
    {
        new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
        if (CsvContainsName(House[houseId][inviteesCsv], name)) return 1;
    }
    return 0;
}