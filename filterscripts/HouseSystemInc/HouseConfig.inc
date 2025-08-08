#if defined _HOUSE_CONFIG_INC_
    #endinput
#endif
#define _HOUSE_CONFIG_INC_

#define MAX_HOUSES                  (500)
#define HOUSE_DATA_FILE             "HouseSystem/houses.db" // under scriptfiles/

#define HOUSE_PICKUP_FORSALE        (1273)
#define HOUSE_PICKUP_OWNED          (1272)
#define HOUSE_PICKUP_VW             (0)
#define HOUSE_LABEL_DRAWDIST        (25.0)

#define HOUSE_ENTER_RANGE           (2.5)
#define HOUSE_ADMIN_RCON_ONLY       (true)

#define DEFAULT_INTERIOR_ID         (3)
#define DEFAULT_INT_X               (235.3050)
#define DEFAULT_INT_Y               (1189.3950)
#define DEFAULT_INT_Z               (1080.2578)

#define PAYDAY_INTERVAL_MS          (1800000) // 30 minutes
#define MAX_NAME_LEN                (24)
#define MAX_HOUSE_NAME              (32)
#define MAX_CSV_LEN                 (128)
#define MAX_RENTERS_DEFAULT         (2)
#define ALLOW_MULTIPLE_HOUSES       (false)

#define INVITE_DURATION_MS          (120000) // 2 minutes
#define MAINTENANCE_TAX_PER_PAYDAY  (100)
#define MAX_MISSED_TAXES            (3)