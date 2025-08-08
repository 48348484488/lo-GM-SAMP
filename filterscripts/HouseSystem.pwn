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

#define PAYDAY_INTERVAL_MS    (1800000) // 30 minutes
#define MAX_NAME_LEN          (24)
#define MAX_HOUSE_NAME        (32)
#define MAX_CSV_LEN           (128)
#define MAX_RENTERS_DEFAULT   (2)
#define ALLOW_MULTIPLE_HOUSES (false)

#define INVITE_DURATION_MS    (120000) // 2 minutes
#define MAINTENANCE_TAX_PER_PAYDAY (100)
#define MAX_MISSED_TAXES      (3)

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
    ownerName[MAX_NAME_LEN],
    bool:isLocked,
    // RP extensions
    houseName[MAX_HOUSE_NAME],
    rentPrice,
    maxRenters,
    keysCsv[MAX_CSV_LEN],
    rentersCsv[MAX_CSV_LEN],
    bool:ownerSpawnAtHouse,
    // New RP features
    interiorId,
    safeBalance,
    inviteesCsv[MAX_CSV_LEN],
    inviteExpiresAt,
    missedTaxCount
};

new House[MAX_HOUSES][HouseData];
new totalHouses;

// Utility forward declarations
forward SaveAllHouses();
forward LoadHouses();
forward UpdateHouseVisuals(houseId);
forward DestroyHouseVisuals(houseId);
forward GetNearestHouse(playerid);
forward GetFreeHouseId();
forward bool:IsPlayerAdminAllowed(playerid);
forward ParseToken(const input[], delimiter, index, output[], outputSize);
forward HousePayday();

// CSV helpers
forward bool:CsvContainsName(const csv[], const name[]);
forward CsvAddName(csv[], csvSize, const name[]);
forward CsvRemoveName(csv[], csvSize, const name[]);
forward CsvCount(const csv[]);
forward bool:IsHouseOwner(playerid, houseId);
forward bool:IsHouseKeyHolder(playerid, houseId);
forward bool:IsHouseRenter(playerid, houseId);
forward bool:PlayerOwnsAnyHouse(playerid);
forward CanPlayerEnterHouse(playerid, houseId);
forward GetPlayerIdByNameExact(const name[]);

public OnFilterScriptInit()
{
    print("[HouseSystem] Loading houses...");
    totalHouses = 0;
    LoadHouses();
    printf("[HouseSystem] Loaded %d houses.", totalHouses);

    SetTimer("HousePayday", PAYDAY_INTERVAL_MS, 1);
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

public OnPlayerSpawn(playerid)
{
    // If the player owns a house and selected spawn at house, spawn inside it
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!House[i][houseExists]) continue;
        if (House[i][ownerSpawnAtHouse] && IsHouseOwner(playerid, i))
        {
            SetPlayerVirtualWorld(playerid, House[i][houseWorld]);
            SetPlayerInterior(playerid, House[i][interiorId]);
            SetPlayerPos(playerid, House[i][exitX], House[i][exitY], House[i][exitZ]);
            break;
        }
    }
    return 1;
}

public HousePayday()
{
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!House[i][houseExists]) continue;

        // Rent collection: goes to house safe
        if (House[i][rentPrice] > 0 && House[i][rentersCsv][0])
        {
            new tmp[MAX_CSV_LEN]; strmid(tmp, House[i][rentersCsv], 0, MAX_CSV_LEN);
            new token[MAX_NAME_LEN];
            new start = 0, len = strlen(tmp);

            for (new j = 0; j <= len; j++)
            {
                if (tmp[j] == ',' || tmp[j] == '\0')
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
                                new msg[96];
                                format(msg, sizeof msg, "[Aluguel] Voce pagou $%d na casa %d.", House[i][rentPrice], i);
                                SendClientMessage(renterId, 0x33CCFFFF, msg);
                            }
                            else
                            {
                                // Evict
                                CsvRemoveName(House[i][rentersCsv], MAX_CSV_LEN, token);
                                UpdateHouseVisuals(i);
                                SaveAllHouses();
                                SendClientMessage(renterId, 0xFF0000FF, "[Aluguel] Voce foi despejado por falta de pagamento.");
                            }
                        }
                    }
                    start = j + 1;
                }
            }
        }

        // Maintenance tax for owner
        if (House[i][ownerName][0])
        {
            new tax = MAINTENANCE_TAX_PER_PAYDAY;
            if (House[i][safeBalance] >= tax)
            {
                House[i][safeBalance] -= tax;
                House[i][missedTaxCount] = 0;
            }
            else
            {
                new ownerId = GetPlayerIdByNameExact(House[i][ownerName]);
                if (ownerId != INVALID_PLAYER_ID && GetPlayerMoney(ownerId) >= tax)
                {
                    GivePlayerMoney(ownerId, -tax);
                    House[i][missedTaxCount] = 0;
                }
                else
                {
                    House[i][missedTaxCount]++;
                    if (House[i][missedTaxCount] >= MAX_MISSED_TAXES)
                    {
                        // Foreclose
                        House[i][ownerName][0] = '\0';
                        House[i][isLocked] = false;
                        House[i][keysCsv][0] = '\0';
                        House[i][rentersCsv][0] = '\0';
                        House[i][rentPrice] = 0;
                        House[i][safeBalance] = 0;
                        House[i][missedTaxCount] = 0;
                        UpdateHouseVisuals(i);
                        SaveAllHouses();
                        if (ownerId != INVALID_PLAYER_ID)
                            SendClientMessage(ownerId, 0xFF0000FF, "[Casa] Sua propriedade foi penhorada por inadimplencia.");
                    }
                }
            }
        }
    }
    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (strcmp(cmdtext, "/hhelp", true) == 0)
    {
        SendClientMessage(playerid, 0x33CCFFFF, "HouseSystem: /hcreate [preco], /hremove, /hbuy, /hsell, /hlock, /henter, /hexit, /hinfo");
        SendClientMessage(playerid, 0x33CCFFFF, "RP: /hname [nome], /hkey add/del [nick], /hkeys, /hrentprice [valor], /hmaxrenters [n], /rentroom, /unrent, /hbell, /hsetentrance, /hsetexit, /hsetspawn");
        SendClientMessage(playerid, 0x33CCFFFF, "Mais RP: /hsafe [deposit|withdraw|balance] [valor], /hinvite [nick], /hevict [nick], /hevictall, /htransfer [nick], /hintlist, /hinterior [id]");
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
        format(House[id][houseName], MAX_HOUSE_NAME, "Casa %d", id);
        House[id][rentPrice] = 0;
        House[id][maxRenters] = MAX_RENTERS_DEFAULT;
        House[id][keysCsv][0] = '\0';
        House[id][rentersCsv][0] = '\0';
        House[id][ownerSpawnAtHouse] = false;
        House[id][interiorId] = DEFAULT_INTERIOR_ID;
        House[id][safeBalance] = 0;
        House[id][inviteesCsv][0] = '\0';
        House[id][inviteExpiresAt] = 0;
        House[id][missedTaxCount] = 0;

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
        if (!ALLOW_MULTIPLE_HOUSES && PlayerOwnsAnyHouse(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Voce ja possui uma casa."), 1;

        new money = GetPlayerMoney(playerid);
        if (money < House[id][housePrice]) return SendClientMessage(playerid, 0xFF0000FF, "Dinheiro insuficiente."), 1;

        GivePlayerMoney(playerid, -House[id][housePrice]);
        GetPlayerName(playerid, House[id][ownerName], MAX_NAME_LEN);
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
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Voce nao e o dono desta casa."), 1;

        GivePlayerMoney(playerid, House[id][housePrice]);
        House[id][ownerName][0] = '\0';
        House[id][isLocked] = false;
        House[id][keysCsv][0] = '\0';
        House[id][rentersCsv][0] = '\0';
        House[id][rentPrice] = 0;
        House[id][safeBalance] = 0;
        House[id][missedTaxCount] = 0;
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
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Voce nao e o dono desta casa."), 1;

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
        if (!CanPlayerEnterHouse(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "A porta esta trancada."), 1;

        SetPlayerVirtualWorld(playerid, House[id][houseWorld]);
        SetPlayerInterior(playerid, House[id][interiorId]);
        SetPlayerPos(playerid, House[id][exitX], House[id][exitY], House[id][exitZ]);
        GameTextForPlayer(playerid, "~w~Bem-vindo", 3000, 4);
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

        new msg[220];
        format(msg, sizeof msg, "%s (ID %d) | Preco: $%d | Dono: %s | Trancada: %s | Aluguel: $%d | Vagas: %d/%d | Cofre: $%d",
            (House[id][houseName][0] ? House[id][houseName] : ("Casa")),
            id,
            House[id][housePrice],
            (House[id][ownerName][0] ? House[id][ownerName] : ("Nenhum")),
            (House[id][isLocked] ? ("Sim") : ("Nao")),
            House[id][rentPrice],
            CsvCount(House[id][rentersCsv]),
            House[id][maxRenters],
            House[id][safeBalance]
        );
        SendClientMessage(playerid, 0x33CCFFFF, msg);
        return 1;
    }

    // ===== RP Commands =====
    if (!strncmp(cmdtext, "/hname", 6, true))
    {
        new pos = strfind(cmdtext, " ");
        if (pos == -1) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hname [nome]"), 1;
        new newName[MAX_HOUSE_NAME];
        strmid(newName, cmdtext, pos + 1, pos + 1 + (MAX_HOUSE_NAME - 1));
        newName[MAX_HOUSE_NAME - 1] = '\0';

        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode renomear."), 1;

        strmid(House[id][houseName], newName, 0, strlen(newName));
        House[id][houseName][strlen(newName)] = '\0';
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Nome da casa atualizado.");
        return 1;
    }

    if (!strncmp(cmdtext, "/hkey", 5, true))
    {
        new sub[16], name[MAX_NAME_LEN];
        if (!ParseToken(cmdtext, ' ', 1, sub, sizeof sub)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hkey add/del [nick]"), 1;
        if (!ParseToken(cmdtext, ' ', 2, name, sizeof name)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hkey add/del [nick]"), 1;

        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode gerenciar chaves."), 1;

        if (!strcmp(sub, "add", true))
        {
            if (CsvContainsName(House[id][keysCsv], name)) return SendClientMessage(playerid, 0xFF0000FF, "Jogador ja possui chave."), 1;
            if (!CsvAddName(House[id][keysCsv], MAX_CSV_LEN, name)) return SendClientMessage(playerid, 0xFF0000FF, "Limite de chaves atingido."), 1;
            SaveAllHouses();
            SendClientMessage(playerid, 0x33CC33FF, "Chave concedida.");
            return 1;
        }
        else if (!strcmp(sub, "del", true))
        {
            if (!CsvContainsName(House[id][keysCsv], name)) return SendClientMessage(playerid, 0xFF0000FF, "Jogador nao possui chave."), 1;
            CsvRemoveName(House[id][keysCsv], MAX_CSV_LEN, name);
            SaveAllHouses();
            SendClientMessage(playerid, 0x33CC33FF, "Chave revogada.");
            return 1;
        }
        else return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hkey add/del [nick]"), 1;
    }

    if (strcmp(cmdtext, "/hkeys", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode ver as chaves."), 1;

        new msg[164];
        format(msg, sizeof msg, "Chaves: %s", (House[id][keysCsv][0] ? House[id][keysCsv] : ("(nenhuma)")));
        SendClientMessage(playerid, 0x33CCFFFF, msg);
        return 1;
    }

    if (!strncmp(cmdtext, "/hrentprice", 11, true))
    {
        new tmp[16];
        if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof tmp)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hrentprice [valor]"), 1;
        new price = strval(tmp);
        if (price < 0) return SendClientMessage(playerid, 0xFF0000FF, "Valor invalido."), 1;

        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode definir aluguel."), 1;

        House[id][rentPrice] = price;
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Aluguel atualizado.");
        return 1;
    }

    if (!strncmp(cmdtext, "/hmaxrenters", 12, true))
    {
        new tmp[16];
        if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof tmp)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hmaxrenters [n]"), 1;
        new n = strval(tmp);
        if (n < 0) n = 0; if (n > 10) n = 10;

        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode definir vagas."), 1;

        House[id][maxRenters] = n;
        if (CsvCount(House[id][rentersCsv]) > n)
        {
            // Evict extras silently
            House[id][rentersCsv][0] = '\0';
        }
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Vagas atualizadas.");
        return 1;
    }

    if (strcmp(cmdtext, "/rentroom", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1;
        if (IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Voce ja e o dono."), 1;
        if (House[id][rentPrice] <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Esta casa nao esta alugando quartos."), 1;
        if (CsvCount(House[id][rentersCsv]) >= House[id][maxRenters]) return SendClientMessage(playerid, 0xFF0000FF, "Nao ha vagas disponiveis."), 1;

        new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
        if (CsvContainsName(House[id][rentersCsv], name)) return SendClientMessage(playerid, 0xFF0000FF, "Voce ja aluga aqui."), 1;

        if (!CsvAddName(House[id][rentersCsv], MAX_CSV_LEN, name)) return SendClientMessage(playerid, 0xFF0000FF, "Lista de inquilinos cheia."), 1;
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Agora voce aluga um quarto nesta casa. O aluguel e cobrado a cada payday.");
        return 1;
    }

    if (strcmp(cmdtext, "/unrent", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
        if (!CsvContainsName(House[id][rentersCsv], name)) return SendClientMessage(playerid, 0xFF0000FF, "Voce nao aluga aqui."), 1;
        CsvRemoveName(House[id][rentersCsv], MAX_CSV_LEN, name);
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Voce cancelou o aluguel.");
        return 1;
    }

    if (strcmp(cmdtext, "/hbell", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1;

        new ownerId = GetPlayerIdByNameExact(House[id][ownerName]);
        if (ownerId != INVALID_PLAYER_ID)
        {
            new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
            new msg[96];
            format(msg, sizeof msg, "%s tocou a campainha da sua casa (%s / ID %d).", name, House[id][houseName], id);
            SendClientMessage(ownerId, 0xFFFF00FF, msg);
            PlayerPlaySound(ownerId, 1056, 0.0, 0.0, 0.0);
        }
        SendClientMessage(playerid, 0x33CC33FF, "Voce tocou a campainha.");
        return 1;
    }

    if (strcmp(cmdtext, "/hsetentrance", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id) && !IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Sem permissao."), 1;

        GetPlayerPos(playerid, House[id][entranceX], House[id][entranceY], House[id][entranceZ]);
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Entrada ajustada.");
        return 1;
    }

    if (strcmp(cmdtext, "/hsetexit", true) == 0)
    {
        // Only when inside
        new vw = GetPlayerVirtualWorld(playerid);
        if (vw <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Use dentro da casa."), 1;
        new id = vw - 1;
        if (id < 0 || id >= MAX_HOUSES || !House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1;
        if (!IsHouseOwner(playerid, id) && !IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Sem permissao."), 1;

        GetPlayerPos(playerid, House[id][exitX], House[id][exitY], House[id][exitZ]);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Saida ajustada.");
        return 1;
    }

    if (strcmp(cmdtext, "/hsetspawn", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono."), 1;
        House[id][ownerSpawnAtHouse] = !House[id][ownerSpawnAtHouse];
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, House[id][ownerSpawnAtHouse] ? ("Spawn definido na casa.") : ("Spawn removido da casa."));
        return 1;
    }

    // ===== New RP Commands =====
    if (!strncmp(cmdtext, "/hsafe", 6, true))
    {
        new sub[16], tmp[16];
        ParseToken(cmdtext, ' ', 1, sub, sizeof sub);
        ParseToken(cmdtext, ' ', 2, tmp, sizeof tmp);
        new amount = strval(tmp);

        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono tem acesso ao cofre."), 1;

        if (!sub[0] || !strcmp(sub, "balance", true))
        {
            new msg[96]; format(msg, sizeof msg, "Cofre: $%d", House[id][safeBalance]);
            SendClientMessage(playerid, 0x33CCFFFF, msg);
            return 1;
        }
        if (!strcmp(sub, "deposit", true))
        {
            if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hsafe deposit [valor]"), 1;
            if (GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, 0xFF0000FF, "Dinheiro insuficiente."), 1;
            GivePlayerMoney(playerid, -amount);
            House[id][safeBalance] += amount;
            SaveAllHouses();
            SendClientMessage(playerid, 0x33CC33FF, "Deposito efetuado.");
            return 1;
        }
        if (!strcmp(sub, "withdraw", true))
        {
            if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hsafe withdraw [valor]"), 1;
            if (House[id][safeBalance] < amount) return SendClientMessage(playerid, 0xFF0000FF, "Cofre insuficiente."), 1;
            House[id][safeBalance] -= amount;
            GivePlayerMoney(playerid, amount);
            SaveAllHouses();
            SendClientMessage(playerid, 0x33CC33FF, "Saque efetuado.");
            return 1;
        }
        return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hsafe [deposit|withdraw|balance] [valor]"), 1;
    }

    if (!strncmp(cmdtext, "/hinvite", 8, true))
    {
        new target[MAX_NAME_LEN];
        if (!ParseToken(cmdtext, ' ', 1, target, sizeof target)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hinvite [nick]"), 1;

        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id) && !IsHouseKeyHolder(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas dono/chaveiro pode convidar."), 1;

        if (!CsvAddName(House[id][inviteesCsv], MAX_CSV_LEN, target)) return SendClientMessage(playerid, 0xFF0000FF, "Lista de convites cheia ou ja convidado."), 1;
        House[id][inviteExpiresAt] = GetTickCount() + INVITE_DURATION_MS;

        new tId = GetPlayerIdByNameExact(target);
        if (tId != INVALID_PLAYER_ID)
        {
            new host[MAX_NAME_LEN]; GetPlayerName(playerid, host, sizeof host);
            new msg[144];
            format(msg, sizeof msg, "%s convidou voce para entrar na casa %d. (2 min)", host, id);
            SendClientMessage(tId, 0x33CCFFFF, msg);
        }
        SendClientMessage(playerid, 0x33CC33FF, "Convite enviado.");
        return 1;
    }

    if (!strncmp(cmdtext, "/hevict", 7, true))
    {
        new subName[MAX_NAME_LEN];
        if (!ParseToken(cmdtext, ' ', 1, subName, sizeof subName)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hevict [nick]"), 1;
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode despejar."), 1;
        if (!CsvContainsName(House[id][rentersCsv], subName)) return SendClientMessage(playerid, 0xFF0000FF, "Jogador nao e inquilino."), 1;
        CsvRemoveName(House[id][rentersCsv], MAX_CSV_LEN, subName);
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Inquilino despejado.");
        return 1;
    }

    if (strcmp(cmdtext, "/hevictall", true) == 0)
    {
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode despejar."), 1;
        House[id][rentersCsv][0] = '\0';
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Todos os inquilinos foram despejados.");
        return 1;
    }

    if (!strncmp(cmdtext, "/htransfer", 10, true))
    {
        new target[MAX_NAME_LEN];
        if (!ParseToken(cmdtext, ' ', 1, target, sizeof target)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /htransfer [nick]"), 1;
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode transferir."), 1;
        strmid(House[id][ownerName], target, 0, strlen(target));
        House[id][ownerName][strlen(target)] = '\0';
        House[id][keysCsv][0] = '\0';
        House[id][rentersCsv][0] = '\0';
        House[id][inviteesCsv][0] = '\0';
        House[id][inviteExpiresAt] = 0;
        House[id][isLocked] = true; // default lock after transfer
        UpdateHouseVisuals(id);
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Propriedade transferida.");
        return 1;
    }

    if (strcmp(cmdtext, "/hintlist", true) == 0)
    {
        SendClientMessage(playerid, 0x33CCFFFF, "Interiores comuns: 1..15 (varia por gamemode). Use /hinterior [id] e /hsetexit para ajustar posicao interna.");
        return 1;
    }

    if (!strncmp(cmdtext, "/hinterior", 10, true))
    {
        new tmp[8];
        if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof tmp)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hinterior [id]"), 1;
        new iid = strval(tmp);
        if (iid < 0 || iid > 255) return SendClientMessage(playerid, 0xFF0000FF, "Interior invalido."), 1;
        new id = GetNearestHouse(playerid);
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!IsHouseOwner(playerid, id) && !IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Sem permissao."), 1;
        House[id][interiorId] = iid;
        SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Interior atualizado. Use /hsetexit dentro do interior." );
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

public bool:IsPlayerAdminAllowed(playerid)
{
    #if HOUSE_ADMIN_RCON_ONLY
        return IsPlayerAdmin(playerid);
    #else
        return true;
    #endif
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

    // Invite check
    if (House[houseId][inviteExpiresAt] > 0 && GetTickCount() <= House[houseId][inviteExpiresAt])
    {
        new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name);
        if (CsvContainsName(House[houseId][inviteesCsv], name)) return 1;
    }

    return 0;
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

// ===== File persistence =====
public SaveAllHouses()
{
    new File:fh = fopen(HOUSE_DATA_FILE, io_write);
    if (!fh)
    {
        print("[HouseSystem] ERRO ao salvar arquivo de casas.");
        return 0;
    }

    new line[640];
    new saved = 0;
    for (new i = 0; i < MAX_HOUSES; i++)
    {
        if (!House[i][houseExists]) continue;
        format(line, sizeof line, "%d|%d|%f|%f|%f|%f|%f|%f|%d|%d|%s|%d|%s|%d|%d|%s|%s|%d|%d|%d|%s|%d|%d\n",
            i,
            House[i][housePrice],
            House[i][entranceX], House[i][entranceY], House[i][entranceZ],
            House[i][exitX], House[i][exitY], House[i][exitZ],
            House[i][entranceInterior],
            House[i][houseWorld],
            (House[i][ownerName][0] ? House[i][ownerName] : ("")),
            House[i][isLocked],
            (House[i][houseName][0] ? House[i][houseName] : ("")),
            House[i][rentPrice],
            House[i][maxRenters],
            (House[i][keysCsv][0] ? House[i][keysCsv] : ("")),
            (House[i][rentersCsv][0] ? House[i][rentersCsv] : ("")),
            House[i][ownerSpawnAtHouse],
            House[i][interiorId],
            House[i][safeBalance],
            (House[i][inviteesCsv][0] ? House[i][inviteesCsv] : ("")),
            House[i][inviteExpiresAt],
            House[i][missedTaxCount]
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
        House[i][houseName][0] = '\0';
        House[i][rentPrice] = 0;
        House[i][maxRenters] = MAX_RENTERS_DEFAULT;
        House[i][keysCsv][0] = '\0';
        House[i][rentersCsv][0] = '\0';
        House[i][ownerSpawnAtHouse] = false;
        House[i][interiorId] = DEFAULT_INTERIOR_ID;
        House[i][safeBalance] = 0;
        House[i][inviteesCsv][0] = '\0';
        House[i][inviteExpiresAt] = 0;
        House[i][missedTaxCount] = 0;
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

    new line[640];
    new count = 0;

    while (fgets(fh, line))
    {
        // id|price|ex|ey|ez|ix|iy|iz|entrInt|world|owner|locked|name|rent|maxRenters|keysCsv|rentersCsv|ownerSpawn|interiorId|safe|invitees|inviteExpire|missedTax
        new tmp[256];
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
        if (ParseToken(line, '|', 10, tmp, sizeof tmp)) { new l = strlen(tmp); if (l > (MAX_NAME_LEN - 1)) l = (MAX_NAME_LEN - 1); strmid(House[id][ownerName], tmp, 0, l); House[id][ownerName][l] = '\0'; }
        if (ParseToken(line, '|', 11, tmp, sizeof tmp)) House[id][isLocked] = (strval(tmp) != 0);
        if (ParseToken(line, '|', 12, tmp, sizeof tmp)) { new l = strlen(tmp); if (l > (MAX_HOUSE_NAME - 1)) l = (MAX_HOUSE_NAME - 1); strmid(House[id][houseName], tmp, 0, l); House[id][houseName][l] = '\0'; }
        if (ParseToken(line, '|', 13, tmp, sizeof tmp)) House[id][rentPrice] = strval(tmp);
        if (ParseToken(line, '|', 14, tmp, sizeof tmp)) House[id][maxRenters] = strval(tmp);
        if (ParseToken(line, '|', 15, tmp, sizeof tmp)) { new l = strlen(tmp); if (l > (MAX_CSV_LEN - 1)) l = (MAX_CSV_LEN - 1); strmid(House[id][keysCsv], tmp, 0, l); House[id][keysCsv][l] = '\0'; }
        if (ParseToken(line, '|', 16, tmp, sizeof tmp)) { new l = strlen(tmp); if (l > (MAX_CSV_LEN - 1)) l = (MAX_CSV_LEN - 1); strmid(House[id][rentersCsv], tmp, 0, l); House[id][rentersCsv][l] = '\0'; }
        if (ParseToken(line, '|', 17, tmp, sizeof tmp)) House[id][ownerSpawnAtHouse] = (strval(tmp) != 0);
        if (ParseToken(line, '|', 18, tmp, sizeof tmp)) House[id][interiorId] = strval(tmp);
        if (ParseToken(line, '|', 19, tmp, sizeof tmp)) House[id][safeBalance] = strval(tmp);
        if (ParseToken(line, '|', 20, tmp, sizeof tmp)) { new l = strlen(tmp); if (l > (MAX_CSV_LEN - 1)) l = (MAX_CSV_LEN - 1); strmid(House[id][inviteesCsv], tmp, 0, l); House[id][inviteesCsv][l] = '\0'; }
        if (ParseToken(line, '|', 21, tmp, sizeof tmp)) House[id][inviteExpiresAt] = strval(tmp);
        if (ParseToken(line, '|', 22, tmp, sizeof tmp)) House[id][missedTaxCount] = strval(tmp);

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

// ===== CSV helpers =====
public bool:CsvContainsName(const csv[], const name[])
{
    if (!csv[0] || !name[0]) return false;
    new pattern[ MAX_NAME_LEN + 2 ];
    format(pattern, sizeof pattern, ",%s,", name);
    new normalized[MAX_CSV_LEN + 2];
    format(normalized, sizeof normalized, ",%s,", csv);
    return (strfind(normalized, pattern, true) != -1);
}

public CsvAddName(csv[], csvSize, const name[])
{
    if (!name[0]) return 0;
    if (CsvContainsName(csv, name)) return 0;
    new curLen = strlen(csv);
    new nameLen = strlen(name);
    new need = nameLen + (curLen > 0 ? 1 : 0) + 1; // +comma +nul
    if (curLen + need > csvSize) return 0;
    if (curLen > 0) strcat(csv, ",");
    strcat(csv, name);
    return 1;
}

public CsvRemoveName(csv[], csvSize, const name[])
{
    if (!csv[0] || !name[0]) return 0;
    new out[MAX_CSV_LEN]; out[0] = '\0';
    new token[MAX_NAME_LEN];
    new start = 0, len = strlen(csv);
    for (new j = 0; j <= len; j++)
    {
        if (csv[j] == ',' || csv[j] == '\0')
        {
            if (j - start > 0)
            {
                strmid(token, csv, start, j);
                new tl = j - start; if (tl > (MAX_NAME_LEN - 1)) tl = (MAX_NAME_LEN - 1); if (tl < 0) tl = 0;
                token[tl] = '\0';
                if (strcmp(token, name, true) != 0)
                {
                    if (out[0]) strcat(out, ",");
                    strcat(out, token);
                }
            }
            start = j + 1;
        }
    }
    // copy back
    strmid(csv, out, 0, strlen(out));
    csv[strlen(out)] = '\0';
    return 1;
}

public CsvCount(const csv[])
{
    if (!csv[0]) return 0;
    new cnt = 1;
    for (new i = 0; csv[i] != '\0'; i++) if (csv[i] == ',') cnt++;
    return cnt;
}