#if defined _HOUSE_PERSISTENCE_INC_
    #endinput
#endif
#define _HOUSE_PERSISTENCE_INC_

#include <a_samp>
#include "HouseConfig.inc"
#include "HouseTypes.inc"

forward SaveAllHouses();
forward LoadHouses();
forward ParseToken(const input[], delimiter, index, output[], outputSize);

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

        count++;
    }

    fclose(fh);

    totalHouses = count;
    return 1;
}

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