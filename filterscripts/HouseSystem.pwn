#include <a_samp>

#define MAX_HOUSES            (500)
#define HOUSE_DATA_FILE       "HouseSystem/houses.db" // saved under scriptfiles/

#define HOUSE_PICKUP_FORSALE  (1273)
#define HOUSE_PICKUP_OWNED    (1272)
#define HOUSE_PICKUP_VW       (0)
#define HOUSE_LABEL_DRAWDIST  (25.0)

#define HOUSE_ENTER_RANGE     (2.5)
#define HOUSE_ADMIN_RCON_ONLY (true)

#define DEFAULT_INTERIOR_ID   (3)
#define DEFAULT_INT_X         (235.3050)
#define DEFAULT_INT_Y         (1189.3950)
#define DEFAULT_INT_Z         (1080.2578)

// House virtual worlds will be (houseId + 1) to avoid world 0

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
    ownerName[24],
    bool:isLocked
};

static House[MAX_HOUSES];
static totalHouses;

// Utility forward declarations
forward SaveAllHouses();
forward LoadHouses();
forward UpdateHouseVisuals(houseId);
forward DestroyHouseVisuals(houseId);
forward GetNearestHouse(playerid);
forward GetFreeHouseId();
forward bool:IsPlayerAdminAllowed(playerid);
forward ParseToken(const input[], delimiter, index, output[], outputSize);

public OnFilterScriptInit()
{
    print("[HouseSystem] Loading houses...");
    totalHouses = 0;
    LoadHouses();
    printf("[HouseSystem] Loaded %d houses.", totalHouses);
    return 1;
}

public OnFilterScriptExit()
{
    print("[HouseSystem] Saving houses...");
    SaveAllHouses();
    return 1;
}

public OnPlayerConnect(playerid)
{
    // No per-player state needed
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (strcmp(cmdtext, "/hhelp", true) == 0)
    {
        SendClientMessage(playerid, 0x33CCFFFF, "HouseSystem: /hcreate [price], /hremove, /hbuy, /hsell, /henter, /hexit, /hlock, /hinfo");
        return 1;
    }

    if (!strncmp(cmdtext, "/hcreate", 8, true))
    {
        if (!IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Somente admin RCON pode criar casas."), 1;

        new tmp[64];
        if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof(tmp))) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hcreate [preco]"), 1;
        new price = strval(tmp);
        if (price <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Preco invalido."), 1;

        new id = GetFreeHouseId();
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Limite de casas atingido."), 1;

        new Float:x, Float:y, Float:z;
        GetPlayerPos(playerid, x, y, z);

        House[id][houseExists] = true;
        House[id][housePrice] = price;
        House[id][entranceX] = x;
        House[id][entranceY] = y;
        House[id][entranceZ] = z;
        House[id][exitX] = DEFAULT_INT_X;
        House[id][exitY] = DEFAULT_INT_Y;
        House[id][exitZ] = DEFAULT_INT_Z;
        House[id][entranceInterior] = 0;
        House[id][houseWorld] = id + 1;
        House[id][ownerName][0] = '\0';
        House[id][isLocked] = false;

        UpdateHouseVisuals(id);
        SaveAllHouses();

        totalHouses++;
        new msg[144];
        format(msg, sizeof msg, "Casa %d criada! Preco: $%d", id, price);
        SendClientMessage(playerid, 0x33CC33FF, msg);
        return 1;
    }

    if (strcmp(cmdtext, "/hremove", true) == 0)
    {
        if (!IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Somente admin RCON pode remover casas."), 1;
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        House[id][houseExists] = false;
        DestroyHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Casa removida.");
        return 1;
    }

    if (strcmp(cmdtext, "/hbuy", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1;
        if (House[id][ownerName][0] != '\0') return SendClientMessage(playerid, 0xFF0000FF, "Esta casa ja tem dono."), 1;

        new money = GetPlayerMoney(playerid);
        if (money < House[id][housePrice]) return SendClientMessage(playerid, 0xFF0000FF, "Dinheiro insuficiente."), 1;

        GivePlayerMoney(playerid, -House[id][housePrice]);
        GetPlayerName(playerid, House[id][ownerName], 24);
        UpdateHouseVisuals(id);
        SaveAllHouses();

        SendClientMessage(playerid, 0x33CC33FF, "Parabens! Voce comprou esta casa.");
        return 1;
    }

    if (strcmp(cmdtext, "/hsell", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1;

        new name[24]; GetPlayerName(playerid, name, sizeof name);
        if (strcmp(name, House[id][ownerName], true) != 0) return SendClientMessage(playerid, 0xFF0000FF, "Voce nao e o dono desta casa."), 1;

        GivePlayerMoney(playerid, House[id][housePrice]);
        House[id][ownerName][0] = '\0';
        House[id][isLocked] = false;
        UpdateHouseVisuals(id);
        SaveAllHouses();

        SendClientMessage(playerid, 0x33CC33FF, "Casa vendida de volta pela quantia paga.");
        return 1;
    }

    if (strcmp(cmdtext, "/hlock", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1;

        new name[24]; GetPlayerName(playerid, name, sizeof name);
        if (strcmp(name, House[id][ownerName], true) != 0) return SendClientMessage(playerid, 0xFF0000FF, "Voce nao e o dono desta casa."), 1;

        House[id][isLocked] = !House[id][isLocked];
        UpdateHouseVisuals(id);
        SaveAllHouses();

        SendClientMessage(playerid, 0x33CC33FF, House[id][isLocked] ? ("Casa trancada.") : ("Casa destrancada."));
        return 1;
    }

    if (strcmp(cmdtext, "/henter", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1;
        if (House[id][isLocked] && House[id][ownerName][0] != '\0')
        {
            new name[24]; GetPlayerName(playerid, name, sizeof name);
            if (strcmp(name, House[id][ownerName], true) != 0)
                return SendClientMessage(playerid, 0xFF0000FF, "Esta casa esta trancada."), 1;
        }

        SetPlayerVirtualWorld(playerid, House[id][houseWorld]);
        SetPlayerInterior(playerid, DEFAULT_INTERIOR_ID);
        SetPlayerPos(playerid, House[id][exitX], House[id][exitY], House[id][exitZ]);
        GameTextForPlayer(playerid, "~w~Bem-vindo a sua casa", 3000, 4);
        return 1;
    }

    if (strcmp(cmdtext, "/hexit", true) == 0)
    {
        // Find by player's current VW
        new id = -1;
        new vw = GetPlayerVirtualWorld(playerid);
        if (vw > 0)
        {
            id = vw - 1;
            if (id < 0 || id >= MAX_HOUSES || !House[id][houseExists]) id = -1;
        }
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Voce nao esta dentro de uma casa."), 1;

        SetPlayerVirtualWorld(playerid, 0);
        SetPlayerInterior(playerid, House[id][entranceInterior]);
        SetPlayerPos(playerid, House[id][entranceX], House[id][entranceY], House[id][entranceZ]);
        GameTextForPlayer(playerid, "~w~Voce saiu da casa", 3000, 4);
        return 1;
    }

    if (strcmp(cmdtext, "/hinfo", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1;

        new msg[144];
        format(msg, sizeof msg, "Casa %d | Preco: $%d | Dono: %s | Trancada: %s", id, House[id][housePrice], (House[id][ownerName][0] ? House[id][ownerName] : ("Nenhum")), (House[id][isLocked] ? ("Sim") : ("Nao")));
        SendClientMessage(playerid, 0x33CCFFFF, msg);
        return 1;
    }

    return 0;
}

// ===== Helpers =====
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
    new Float:px, Float:py, Float:pz;
    GetPlayerPos(playerid, px, py, pz);

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

public UpdateHouseVisuals(houseId)
{
    if (houseId < 0 || houseId >= MAX_HOUSES) return 0;

    // Destroy old visual elements if exist
    DestroyHouseVisuals(houseId);

    if (!House[houseId][houseExists]) return 1;

    // Create pickup
    new model = (House[houseId][ownerName][0] == '\0') ? HOUSE_PICKUP_FORSALE : HOUSE_PICKUP_OWNED;
    House[houseId][housePickup] = CreatePickup(model, 1, House[houseId][entranceX], House[houseId][entranceY], House[houseId][entranceZ], HOUSE_PICKUP_VW);

    // Create 3D text label
    new text[144];
    if (House[houseId][ownerName][0] == '\0')
        format(text, sizeof text, "Casa %d\nPreco: $%d\n/hbuy para comprar", houseId, House[houseId][housePrice]);
    else
        format(text, sizeof text, "Casa %d\nDono: %s\n%s | /henter", houseId, House[houseId][ownerName], (House[houseId][isLocked] ? ("Trancada") : ("Aberta")));

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

public bool:IsPlayerAdminAllowed(playerid)
{
    #if HOUSE_ADMIN_RCON_ONLY
        return IsPlayerAdmin(playerid);
    #else
        return true;
    #endif
}

// ===== File persistence =====
public SaveAllHouses()
{
    // Ensure directory exists (server will create under scriptfiles). We'll overwrite the file
    new File:fh = fopen(HOUSE_DATA_FILE, io_write);
    if (!fh)
    {
        print("[HouseSystem] ERRO ao salvar arquivo de casas.");
        return 0;
    }

    new line[256];
    new saved = 0;
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!House[i][houseExists]) continue;
        format(line, sizeof line, "%d|%d|%f|%f|%f|%f|%f|%f|%d|%d|%s|%d\n",
            i,
            House[i][housePrice],
            House[i][entranceX], House[i][entranceY], House[i][entranceZ],
            House[i][exitX], House[i][exitY], House[i][exitZ],
            House[i][entranceInterior],
            House[i][houseWorld],
            (House[i][ownerName][0] ? House[i][ownerName] : ("")),
            House[i][isLocked]
        );
        fwrite(fh, line);
        saved++;
    }

    fclose(fh);
    printf("[HouseSystem] Salvou %d casas.", saved);
    return 1;
}

public LoadHouses()
{
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        House[i][houseExists] = false;
        House[i][housePickup] = 0;
        House[i][houseLabel] = Text3D:0;
        House[i][ownerName][0] = '\0';
        House[i][isLocked] = false;
    }

    if (!fexist(HOUSE_DATA_FILE))
    {
        print("[HouseSystem] Nenhum arquivo de casas encontrado. (primeira execucao?)");
        return 1;
    }

    new File:fh = fopen(HOUSE_DATA_FILE, io_read);
    if (!fh)
    {
        print("[HouseSystem] ERRO ao abrir arquivo de casas.");
        return 0;
    }

    new line[256];
    new count = 0;

    while (fgets(fh, line))
    {
        // Expected: id|price|ex|ey|ez|ix|iy|iz|entrInt|world|owner|locked
        new tmp[64];
        new id;

        if (!ParseToken(line, '|', 0, tmp, sizeof tmp)) continue;
        id = strval(tmp);
        if (id < 0 || id >= MAX_HOUSES) continue;

        House[id][houseExists] = true;

        if (ParseToken(line, '|', 1, tmp, sizeof tmp)) House[id][housePrice] = strval(tmp);
        if (ParseToken(line, '|', 2, tmp, sizeof tmp)) House[id][entranceX] = floatstr(tmp);
        if (ParseToken(line, '|', 3, tmp, sizeof tmp)) House[id][entranceY] = floatstr(tmp);
        if (ParseToken(line, '|', 4, tmp, sizeof tmp)) House[id][entranceZ] = floatstr(tmp);
        if (ParseToken(line, '|', 5, tmp, sizeof tmp)) House[id][exitX] = floatstr(tmp);
        if (ParseToken(line, '|', 6, tmp, sizeof tmp)) House[id][exitY] = floatstr(tmp);
        if (ParseToken(line, '|', 7, tmp, sizeof tmp)) House[id][exitZ] = floatstr(tmp);
        if (ParseToken(line, '|', 8, tmp, sizeof tmp)) House[id][entranceInterior] = strval(tmp);
        if (ParseToken(line, '|', 9, tmp, sizeof tmp)) House[id][houseWorld] = strval(tmp);
        if (ParseToken(line, '|', 10, tmp, sizeof tmp)) {
            // Owner name may be empty
            new ownerLen = strlen(tmp);
            if (ownerLen > 23) ownerLen = 23;
            strmid(House[id][ownerName], tmp, 0, ownerLen);
            House[id][ownerName][ownerLen] = '\0';
        }
        if (ParseToken(line, '|', 11, tmp, sizeof tmp)) House[id][isLocked] = (strval(tmp) != 0);

        UpdateHouseVisuals(id);
        count++;
    }

    fclose(fh);

    totalHouses = count;
    return 1;
}

// Tokenize: extracts token at index from input (delimiter-separated) into output
public ParseToken(const input[], delimiter, index, output[], outputSize)
{
    new len = strlen(input);
    new start = 0;
    new currentIndex = 0;

    for (new i = 0; i <= len; i++)
    {
        if (input[i] == delimiter || input[i] == '\n' || input[i] == '\r' || input[i] == '\0')
        {
            if (currentIndex == index)
            {
                new tokLen = i - start;
                if (tokLen >= outputSize) tokLen = outputSize - 1;
                if (tokLen < 0) tokLen = 0;
                strmid(output, input, start, start + tokLen);
                output[tokLen] = '\0';
                return 1;
            }
            currentIndex++;
            start = i + 1;
        }
    }

    return 0;
}