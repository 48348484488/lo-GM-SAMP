#if defined _HOUSE_CSV_INC_
    #endinput
#endif
#define _HOUSE_CSV_INC_

#include "HouseConfig.inc"

forward bool:CsvContainsName(const csv[], const name[]);
forward CsvAddName(csv[], csvSize, const name[]);
forward CsvRemoveName(csv[], csvSize, const name[]);
forward CsvCount(const csv[]);

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