#include <a_samp>
#include "HouseSystemInc/HouseConfig.inc"
#include "HouseSystemInc/HouseTypes.inc"
#include "HouseSystemInc/HouseCSV.inc"
#include "HouseSystemInc/HouseUtil.inc"
#include "HouseSystemInc/HousePersistence.inc"
#include "HouseSystemInc/HouseCore.inc"
#include "HouseSystemInc/HouseAdmin.inc"

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

public OnPlayerSpawn(playerid)
{
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

public OnPlayerCommandText(playerid, cmdtext[])
{
    // Admin module first
    if (HandleAdminCommand(playerid, cmdtext)) return 1;

    if (strcmp(cmdtext, "/hhelp", true) == 0)
    {
        SendClientMessage(playerid, 0x33CCFFFF, "HouseSystem: /hcreate [preco], /hremove, /hbuy, /hsell, /hlock, /henter, /hexit, /hinfo");
        SendClientMessage(playerid, 0x33CCFFFF, "RP: /hname [nome], /hkey add/del [nick], /hkeys, /hrentprice [valor], /hmaxrenters [n], /rentroom, /unrent, /hbell, /hsetentrance, /hsetexit, /hsetspawn");
        SendClientMessage(playerid, 0x33CCFFFF, "Mais RP: /hsafe [deposit|withdraw|balance] [valor], /hinvite [nick], /hevict [nick], /hevictall, /htransfer [nick], /hintlist, /hinterior [id]");
        return 1;
    }

    // Creation/removal
    if (!strncmp(cmdtext, "/hcreate", 8, true))
    {
        if (!IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Somente admin RCON pode criar casas."), 1;
        new tmp[64]; if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof tmp)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hcreate [preco]"), 1;
        new price = strval(tmp); if (price <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Preco invalido."), 1;
        new id = GetFreeHouseId(); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Limite de casas atingido."), 1;
        new Float:x, Float:y, Float:z; GetPlayerPos(playerid, x, y, z);
        House[id][houseExists] = true; House[id][housePrice] = price; House[id][entranceX] = x; House[id][entranceY] = y; House[id][entranceZ] = z;
        House[id][exitX] = DEFAULT_INT_X; House[id][exitY] = DEFAULT_INT_Y; House[id][exitZ] = DEFAULT_INT_Z; House[id][entranceInterior] = 0;
        House[id][houseWorld] = id + 1; House[id][ownerName][0] = '\0'; House[id][isLocked] = false; format(House[id][houseName], MAX_HOUSE_NAME, "Casa %d", id);
        House[id][rentPrice] = 0; House[id][maxRenters] = MAX_RENTERS_DEFAULT; House[id][keysCsv][0] = '\0'; House[id][rentersCsv][0] = '\0'; House[id][ownerSpawnAtHouse] = false;
        House[id][interiorId] = DEFAULT_INTERIOR_ID; House[id][safeBalance] = 0; House[id][inviteesCsv][0] = '\0'; House[id][inviteExpiresAt] = 0; House[id][missedTaxCount] = 0;
        UpdateHouseVisuals(id); SaveAllHouses();
        totalHouses++;
        new msg[144]; format(msg, sizeof msg, "Casa %d criada! Preco: $%d", id, price); SendClientMessage(playerid, 0x33CC33FF, msg);
        return 1;
    }
    if (strcmp(cmdtext, "/hremove", true) == 0)
    {
        if (!IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Somente admin RCON pode remover casas."), 1;
        new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        House[id][houseExists] = false; DestroyHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Casa removida."); return 1;
    }

    // Ownership
    if (strcmp(cmdtext, "/hbuy", true) == 0)
    {
        new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists] || House[id][ownerName][0] != '\0') return SendClientMessage(playerid, 0xFF0000FF, "Nao disponivel."), 1;
        if (!ALLOW_MULTIPLE_HOUSES && PlayerOwnsAnyHouse(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Voce ja possui uma casa."), 1;
        if (GetPlayerMoney(playerid) < House[id][housePrice]) return SendClientMessage(playerid, 0xFF0000FF, "Dinheiro insuficiente."), 1;
        GivePlayerMoney(playerid, -House[id][housePrice]); GetPlayerName(playerid, House[id][ownerName], MAX_NAME_LEN); UpdateHouseVisuals(id); SaveAllHouses();
        SendClientMessage(playerid, 0x33CC33FF, "Parabens! Voce comprou esta casa."); return 1;
    }
    if (strcmp(cmdtext, "/hsell", true) == 0)
    {
        new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists] || !IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Sem permissao."), 1;
        GivePlayerMoney(playerid, House[id][housePrice]); House[id][ownerName][0] = '\0'; House[id][isLocked] = false; House[id][keysCsv][0] = '\0'; House[id][rentersCsv][0] = '\0'; House[id][rentPrice] = 0; House[id][safeBalance] = 0; House[id][missedTaxCount] = 0;
        UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Casa vendida de volta pela quantia paga."); return 1;
    }

    // Access and info
    if (strcmp(cmdtext, "/hlock", true) == 0)
    {
        new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists] || !IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Sem permissao."), 1;
        House[id][isLocked] = !House[id][isLocked]; UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, House[id][isLocked] ? ("Casa trancada.") : ("Casa destrancada.")); return 1;
    }
    if (strcmp(cmdtext, "/henter", true) == 0)
    {
        new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        if (!House[id][houseExists] || !CanPlayerEnterHouse(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "A porta esta trancada."), 1;
        SetPlayerVirtualWorld(playerid, House[id][houseWorld]); SetPlayerInterior(playerid, House[id][interiorId]); SetPlayerPos(playerid, House[id][exitX], House[id][exitY], House[id][exitZ]); GameTextForPlayer(playerid, "~w~Bem-vindo", 3000, 4); return 1;
    }
    if (strcmp(cmdtext, "/hexit", true) == 0)
    {
        new id = -1, vw = GetPlayerVirtualWorld(playerid); if (vw > 0) { id = vw - 1; if (id < 0 || id >= MAX_HOUSES || !House[id][houseExists]) id = -1; }
        if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Voce nao esta dentro de uma casa."), 1;
        SetPlayerVirtualWorld(playerid, 0); SetPlayerInterior(playerid, House[id][entranceInterior]); SetPlayerPos(playerid, House[id][entranceX], House[id][entranceY], House[id][entranceZ]); GameTextForPlayer(playerid, "~w~Voce saiu da casa", 3000, 4); return 1;
    }
    if (strcmp(cmdtext, "/hinfo", true) == 0)
    {
        new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1;
        new msg[220]; format(msg, sizeof msg, "%s (ID %d) | Preco: $%d | Dono: %s | Trancada: %s | Aluguel: $%d | Vagas: %d/%d | Cofre: $%d", (House[id][houseName][0] ? House[id][houseName] : ("Casa")), id, House[id][housePrice], (House[id][ownerName][0] ? House[id][ownerName] : ("Nenhum")), (House[id][isLocked] ? ("Sim") : ("Nao")), House[id][rentPrice], CsvCount(House[id][rentersCsv]), House[id][maxRenters], House[id][safeBalance]);
        SendClientMessage(playerid, 0x33CCFFFF, msg); return 1;
    }

    // RP
    if (!strncmp(cmdtext, "/hname", 6, true)) { new pos = strfind(cmdtext, " "); if (pos == -1) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hname [nome]"), 1; new newName[MAX_HOUSE_NAME]; strmid(newName, cmdtext, pos + 1, pos + 1 + (MAX_HOUSE_NAME - 1)); newName[MAX_HOUSE_NAME - 1] = '\0'; new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode renomear."), 1; strmid(House[id][houseName], newName, 0, strlen(newName)); House[id][houseName][strlen(newName)] = '\0'; UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Nome da casa atualizado."); return 1; }
    if (!strncmp(cmdtext, "/hkey", 5, true)) { new sub[16], name[MAX_NAME_LEN]; if (!ParseToken(cmdtext, ' ', 1, sub, sizeof sub) || !ParseToken(cmdtext, ' ', 2, name, sizeof name)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hkey add/del [nick]"), 1; new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode gerenciar chaves."), 1; if (!strcmp(sub, "add", true)) { if (CsvContainsName(House[id][keysCsv], name)) return SendClientMessage(playerid, 0xFF0000FF, "Jogador ja possui chave."), 1; if (!CsvAddName(House[id][keysCsv], MAX_CSV_LEN, name)) return SendClientMessage(playerid, 0xFF0000FF, "Limite de chaves atingido."), 1; SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Chave concedida."); return 1; } else if (!strcmp(sub, "del", true)) { if (!CsvContainsName(House[id][keysCsv], name)) return SendClientMessage(playerid, 0xFF0000FF, "Jogador nao possui chave."), 1; CsvRemoveName(House[id][keysCsv], MAX_CSV_LEN, name); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Chave revogada."); return 1; } else return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hkey add/del [nick]"), 1; }
    if (strcmp(cmdtext, "/hkeys", true) == 0) { new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode ver as chaves."), 1; new msg[164]; format(msg, sizeof msg, "Chaves: %s", (House[id][keysCsv][0] ? House[id][keysCsv] : ("(nenhuma)"))); SendClientMessage(playerid, 0x33CCFFFF, msg); return 1; }
    if (!strncmp(cmdtext, "/hrentprice", 11, true)) { new tmp[16]; if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof tmp)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hrentprice [valor]"), 1; new price = strval(tmp); if (price < 0) return SendClientMessage(playerid, 0xFF0000FF, "Valor invalido."), 1; new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode definir aluguel."), 1; House[id][rentPrice] = price; UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Aluguel atualizado."); return 1; }
    if (!strncmp(cmdtext, "/hmaxrenters", 12, true)) { new tmp[16]; if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof tmp)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hmaxrenters [n]"), 1; new n = strval(tmp); if (n < 0) n = 0; if (n > 10) n = 10; new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode definir vagas."), 1; House[id][maxRenters] = n; if (CsvCount(House[id][rentersCsv]) > n) { House[id][rentersCsv][0] = '\0'; } UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Vagas atualizadas."); return 1; }
    if (strcmp(cmdtext, "/rentroom", true) == 0) { new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!House[id][houseExists] || IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Nao disponivel."), 1; if (House[id][rentPrice] <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Nao aluga quartos."), 1; if (CsvCount(House[id][rentersCsv]) >= House[id][maxRenters]) return SendClientMessage(playerid, 0xFF0000FF, "Sem vagas."), 1; new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name); if (CsvContainsName(House[id][rentersCsv], name)) return SendClientMessage(playerid, 0xFF0000FF, "Voce ja aluga aqui."), 1; if (!CsvAddName(House[id][rentersCsv], MAX_CSV_LEN, name)) return SendClientMessage(playerid, 0xFF0000FF, "Lista cheia."), 1; UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Agora voce aluga um quarto. O aluguel e cobrado no payday."); return 1; }
    if (strcmp(cmdtext, "/unrent", true) == 0) { new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name); if (!CsvContainsName(House[id][rentersCsv], name)) return SendClientMessage(playerid, 0xFF0000FF, "Voce nao aluga aqui."), 1; CsvRemoveName(House[id][rentersCsv], MAX_CSV_LEN, name); UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Voce cancelou o aluguel."); return 1; }
    if (strcmp(cmdtext, "/hbell", true) == 0) { new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1; new ownerId = GetPlayerIdByNameExact(House[id][ownerName]); if (ownerId != INVALID_PLAYER_ID) { new name[MAX_NAME_LEN]; GetPlayerName(playerid, name, sizeof name); new msg[128]; format(msg, sizeof msg, "%s tocou a campainha da sua casa (%s / ID %d).", name, House[id][houseName], id); SendClientMessage(ownerId, 0xFFFF00FF, msg); PlayerPlaySound(ownerId, 1056, 0.0, 0.0, 0.0);} SendClientMessage(playerid, 0x33CC33FF, "Voce tocou a campainha."); return 1; }
    if (strcmp(cmdtext, "/hsetentrance", true) == 0) { new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id) && !IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Sem permissao."), 1; GetPlayerPos(playerid, House[id][entranceX], House[id][entranceY], House[id][entranceZ]); UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Entrada ajustada."); return 1; }
    if (strcmp(cmdtext, "/hsetexit", true) == 0) { new vw = GetPlayerVirtualWorld(playerid); if (vw <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Use dentro da casa."), 1; new id = vw - 1; if (id < 0 || id >= MAX_HOUSES || !House[id][houseExists]) return SendClientMessage(playerid, 0xFF0000FF, "Casa invalida."), 1; if (!IsHouseOwner(playerid, id) && !IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Sem permissao."), 1; GetPlayerPos(playerid, House[id][exitX], House[id][exitY], House[id][exitZ]); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Saida ajustada."); return 1; }
    if (strcmp(cmdtext, "/hsetspawn", true) == 0) { new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono."), 1; House[id][ownerSpawnAtHouse] = !House[id][ownerSpawnAtHouse]; SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, House[id][ownerSpawnAtHouse] ? ("Spawn definido na casa.") : ("Spawn removido da casa.")); return 1; }

    // New RP
    if (!strncmp(cmdtext, "/hsafe", 6, true)) { new sub[16], tmp[16]; ParseToken(cmdtext, ' ', 1, sub, sizeof sub); ParseToken(cmdtext, ' ', 2, tmp, sizeof tmp); new amount = strval(tmp); new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono tem acesso ao cofre."), 1; if (!sub[0] || !strcmp(sub, "balance", true)) { new msg[96]; format(msg, sizeof msg, "Cofre: $%d", House[id][safeBalance]); SendClientMessage(playerid, 0x33CCFFFF, msg); return 1; } if (!strcmp(sub, "deposit", true)) { if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hsafe deposit [valor]"), 1; if (GetPlayerMoney(playerid) < amount) return SendClientMessage(playerid, 0xFF0000FF, "Dinheiro insuficiente."), 1; GivePlayerMoney(playerid, -amount); House[id][safeBalance] += amount; SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Deposito efetuado."); return 1; } if (!strcmp(sub, "withdraw", true)) { if (amount <= 0) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hsafe withdraw [valor]"), 1; if (House[id][safeBalance] < amount) return SendClientMessage(playerid, 0xFF0000FF, "Cofre insuficiente."), 1; House[id][safeBalance] -= amount; GivePlayerMoney(playerid, amount); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Saque efetuado."); return 1; } return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hsafe [deposit|withdraw|balance] [valor]"), 1; }
    if (!strncmp(cmdtext, "/hinvite", 8, true)) { new target[MAX_NAME_LEN]; if (!ParseToken(cmdtext, ' ', 1, target, sizeof target)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hinvite [nick]"), 1; new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id) && !IsHouseKeyHolder(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas dono/chaveiro pode convidar."), 1; if (!CsvAddName(House[id][inviteesCsv], MAX_CSV_LEN, target)) return SendClientMessage(playerid, 0xFF0000FF, "Lista cheia ou ja convidado."), 1; House[id][inviteExpiresAt] = GetTickCount() + INVITE_DURATION_MS; new tId = GetPlayerIdByNameExact(target); if (tId != INVALID_PLAYER_ID) { new host[MAX_NAME_LEN]; GetPlayerName(playerid, host, sizeof host); new msg[144]; format(msg, sizeof msg, "%s convidou voce para entrar na casa %d. (2 min)", host, id); SendClientMessage(tId, 0x33CCFFFF, msg);} SendClientMessage(playerid, 0x33CC33FF, "Convite enviado."); return 1; }
    if (!strncmp(cmdtext, "/hevict", 7, true)) { new subName[MAX_NAME_LEN]; if (!ParseToken(cmdtext, ' ', 1, subName, sizeof subName)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hevict [nick]"), 1; new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode despejar."), 1; if (!CsvContainsName(House[id][rentersCsv], subName)) return SendClientMessage(playerid, 0xFF0000FF, "Jogador nao e inquilino."), 1; CsvRemoveName(House[id][rentersCsv], MAX_CSV_LEN, subName); UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Inquilino despejado."); return 1; }
    if (strcmp(cmdtext, "/hevictall", true) == 0) { new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode despejar."), 1; House[id][rentersCsv][0] = '\0'; UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Todos os inquilinos foram despejados."); return 1; }
    if (!strncmp(cmdtext, "/htransfer", 10, true)) { new target[MAX_NAME_LEN]; if (!ParseToken(cmdtext, ' ', 1, target, sizeof target)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /htransfer [nick]"), 1; new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id)) return SendClientMessage(playerid, 0xFF0000FF, "Apenas o dono pode transferir."), 1; strmid(House[id][ownerName], target, 0, strlen(target)); House[id][ownerName][strlen(target)] = '\0'; House[id][keysCsv][0] = '\0'; House[id][rentersCsv][0] = '\0'; House[id][inviteesCsv][0] = '\0'; House[id][inviteExpiresAt] = 0; House[id][isLocked] = true; UpdateHouseVisuals(id); SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Propriedade transferida."); return 1; }
    if (strcmp(cmdtext, "/hintlist", true) == 0) { SendClientMessage(playerid, 0x33CCFFFF, "Interiores comuns: 1..15 (varia por gamemode). Use /hinterior [id] e /hsetexit para ajustar posicao interna."); return 1; }
    if (!strncmp(cmdtext, "/hinterior", 10, true)) { new tmp[8]; if (!ParseToken(cmdtext, ' ', 1, tmp, sizeof tmp)) return SendClientMessage(playerid, 0xFF0000FF, "Uso: /hinterior [id]"), 1; new iid = strval(tmp); if (iid < 0 || iid > 255) return SendClientMessage(playerid, 0xFF0000FF, "Interior invalido."), 1; new id = GetNearestHouse(playerid); if (id == -1) return SendClientMessage(playerid, 0xFF0000FF, "Nenhuma casa proxima."), 1; if (!IsHouseOwner(playerid, id) && !IsPlayerAdminAllowed(playerid)) return SendClientMessage(playerid, 0xFF0000FF, "Sem permissao."), 1; House[id][interiorId] = iid; SaveAllHouses(); SendClientMessage(playerid, 0x33CC33FF, "Interior atualizado. Use /hsetexit dentro do interior."); return 1; }

    return 0;
}

public HousePayday();