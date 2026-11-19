
#include <a_samp>
#include <a_mysql>

#define SERVER_NAME "LIVE PH ROLEPLAY"
#define MYSQL_HOST "127.0.0.1"
#define MYSQL_USER "server_813"
#define MYSQL_DATABASE "server_813_livephrp"
#define MYSQL_PASSWORD "REPLACE_WITH_DATABASE_PASSWORD"

#define COLOR_WHITE 0xFFFFFFFF
#define COLOR_GREEN 0x33CC33FF
#define COLOR_RED 0xFF3333FF
#define COLOR_BLUE 0x3399FFFF
#define COLOR_YELLOW 0xFFFF00FF

#define DIALOG_REGISTER 1000
#define DIALOG_LOGIN 1001

#define ADMIN_NONE 0
#define ADMIN_JUNIOR 1
#define ADMIN_SENIOR 2
#define ADMIN_ADVISOR 3
#define ADMIN_DEPUTY_CHIEF 4
#define ADMIN_CHIEF 5
#define ADMIN_PROJECT_TEAM 6
#define ADMIN_DEPUTY_FOUNDER 7
#define ADMIN_FOUNDER 8

new MySQL:g_SQL;

enum E_PLAYER_DATA
{
    pID,
    pName[MAX_PLAYER_NAME],
    pPassword[129],
    pAdmin,
    pLevel,
    pMoney,
    pBankMoney,
    pGang,
    pOrganization,
    pLoggedIn
};

new PlayerData[MAX_PLAYERS][E_PLAYER_DATA];

forward OnAccountCheck(playerid);
forward OnAccountRegister(playerid);
forward OnAccountLogin(playerid);

main()
{
    print("LIVE PH RP - Starting...");
}

public OnGameModeInit()
{
    SetGameModeText("LIVE PH ROLEPLAY");
    ShowPlayerMarkers(PLAYER_MARKERS_MODE_GLOBAL);
    ShowNameTags(1);
    UsePlayerPedAnims();

    AddPlayerClass(
        0,
        1481.0, -1771.0, 18.8,
        90.0,
        0, 0, 0, 0, 0, 0
    );

    g_SQL = mysql_connect(
        MYSQL_HOST,
        MYSQL_USER,
        MYSQL_DATABASE,
        MYSQL_PASSWORD
    );

    if (mysql_errno(g_SQL) != 0)
    {
        print("[LIVE PH RP] MySQL connection failed!");
    }
    else
    {
        print("[LIVE PH RP] MySQL connected successfully!");
    }

    print("[LIVE PH RP] Gamemode loaded.");
    return 1;
}

public OnGameModeExit()
{
    mysql_close(g_SQL);
    return 1;
}

public OnPlayerConnect(playerid)
{
    GetPlayerName(playerid, PlayerData[playerid][pName], MAX_PLAYER_NAME);

    PlayerData[playerid][pLoggedIn] = 0;
    PlayerData[playerid][pID] = 0;
    PlayerData[playerid][pAdmin] = 0;
    PlayerData[playerid][pGang] = 0;
    PlayerData[playerid][pOrganization] = 0;

    TogglePlayerSpectating(playerid, true);

    new query[256];
    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "SELECT * FROM players WHERE username='%e' LIMIT 1",
        PlayerData[playerid][pName]
    );

    mysql_tquery(g_SQL, query, "OnAccountCheck", "i", playerid);

    return 1;
}

public OnAccountCheck(playerid)
{
    if (!IsPlayerConnected(playerid)) return 1;

    new rows;
    cache_get_row_count(rows);

    if (rows > 0)
    {
        ShowPlayerDialog(
            playerid,
            DIALOG_LOGIN,
            DIALOG_STYLE_PASSWORD,
            "LIVE PH RP - Login",
            "Welcome back!\nEnter your account password:",
            "Login",
            "Quit"
        );
    }
    else
    {
        ShowPlayerDialog(
            playerid,
            DIALOG_REGISTER,
            DIALOG_STYLE_PASSWORD,
            "LIVE PH RP - Registration",
            "Welcome to LIVE PH RP!\nCreate your account password:",
            "Register",
            "Quit"
        );
    }

    return 1;
}

public OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    if (!response)
    {
        Kick(playerid);
        return 1;
    }

    if (dialogid == DIALOG_REGISTER)
    {
        if (strlen(inputtext) < 6 || strlen(inputtext) > 64)
        {
            ShowPlayerDialog(
                playerid,
                DIALOG_REGISTER,
                DIALOG_STYLE_PASSWORD,
                "LIVE PH RP - Registration",
                "Password must be 6 to 64 characters.\nCreate your password:",
                "Register",
                "Quit"
            );
            return 1;
        }

        new hashedPassword[129];
        SHA256_PassHash(inputtext, PlayerData[playerid][pName], hashedPassword, sizeof(hashedPassword));

        new query[512];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "INSERT INTO players (username,password,level,money,bank_money) VALUES ('%e','%e',1,5000,0)",
            PlayerData[playerid][pName],
            hashedPassword
        );

        mysql_tquery(g_SQL, query, "OnAccountRegister", "i", playerid);
        return 1;
    }

    if (dialogid == DIALOG_LOGIN)
    {
        if (strlen(inputtext) < 1)
        {
            Kick(playerid);
            return 1;
        }

        new hashedPassword[129];
        SHA256_PassHash(inputtext, PlayerData[playerid][pName], hashedPassword, sizeof(hashedPassword));

        new query[256];
        mysql_format(
            g_SQL,
            query,
            sizeof(query),
            "SELECT * FROM players WHERE username='%e' AND password='%e' LIMIT 1",
            PlayerData[playerid][pName],
            hashedPassword
        );

        mysql_tquery(g_SQL, query, "OnAccountLogin", "i", playerid);
        return 1;
    }

    return 0;
}

public OnAccountRegister(playerid)
{
    if (!IsPlayerConnected(playerid)) return 1;

    SendClientMessage(
        playerid,
        COLOR_GREEN,
        "LIVE PH RP: Account created successfully. Please login."
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_LOGIN,
        DIALOG_STYLE_PASSWORD,
        "LIVE PH RP - Login",
        "Your account has been created.\nEnter your password:",
        "Login",
        "Quit"
    );

    return 1;
}

public OnAccountLogin(playerid)
{
    if (!IsPlayerConnected(playerid)) return 1;

    new rows;
    cache_get_row_count(rows);

    if (rows == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Incorrect password.");
        ShowPlayerDialog(
            playerid,
            DIALOG_LOGIN,
            DIALOG_STYLE_PASSWORD,
            "LIVE PH RP - Login",
            "Incorrect password.\nTry again:",
            "Login",
            "Quit"
        );
        return 1;
    }

    cache_get_value_name_int(0, "id", PlayerData[playerid][pID]);
    cache_get_value_name_int(0, "admin", PlayerData[playerid][pAdmin]);
    cache_get_value_name_int(0, "level", PlayerData[playerid][pLevel]);
    cache_get_value_name_int(0, "money", PlayerData[playerid][pMoney]);
    cache_get_value_name_int(0, "bank_money", PlayerData[playerid][pBankMoney]);
    cache_get_value_name_int(0, "gang_id", PlayerData[playerid][pGang]);
    cache_get_value_name_int(0, "org_id", PlayerData[playerid][pOrganization]);

    PlayerData[playerid][pLoggedIn] = 1;

    ResetPlayerMoney(playerid);
    GivePlayerMoney(playerid, PlayerData[playerid][pMoney]);

    TogglePlayerSpectating(playerid, false);
    SpawnPlayer(playerid);

    SendClientMessage(playerid, COLOR_BLUE, "Welcome to LIVE PH ROLEPLAY!");
    SendClientMessage(playerid, COLOR_GREEN, "You have successfully logged in.");

    return 1;
}

stock SavePlayerData(playerid)
{
    if (!PlayerData[playerid][pLoggedIn]) return 1;

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new query[512];
    mysql_format(
        g_SQL,
        query,
        sizeof(query),
        "UPDATE players SET level=%d,money=%d,bank_money=%d,gang_id=%d,org_id=%d,pos_x=%f,pos_y=%f,pos_z=%f,pos_a=%f,interior=%d,virtual_world=%d WHERE id=%d",
        PlayerData[playerid][pLevel],
        GetPlayerMoney(playerid),
        PlayerData[playerid][pBankMoney],
        PlayerData[playerid][pGang],
        PlayerData[playerid][pOrganization],
        x, y, z, a,
        GetPlayerInterior(playerid),
        GetPlayerVirtualWorld(playerid),
        PlayerData[playerid][pID]
    );

    mysql_tquery(g_SQL, query);
    return 1;
}

public OnPlayerDisconnect(playerid, reason)
{
    SavePlayerData(playerid);
    return 1;
}

public OnPlayerSpawn(playerid)
{
    if (!PlayerData[playerid][pLoggedIn])
    {
        Kick(playerid);
        return 1;
    }

    return 1;
}

public OnPlayerCommandText(playerid, cmdtext[])
{
    if (!PlayerData[playerid][pLoggedIn])
    {
        SendClientMessage(playerid, COLOR_RED, "You must login first.");
        return 1;
    }

    if (!strcmp(cmdtext, "/apanel", true))
    {
        if (PlayerData[playerid][pAdmin] != ADMIN_FOUNDER)
        {
            SendClientMessage(playerid, COLOR_RED, "Founder access only.");
            return 1;
        }

        ShowPlayerDialog(
            playerid,
            1100,
            DIALOG_STYLE_LIST,
            "LIVE PH RP - FOUNDER PANEL",
            "Player Management\nWorld Editor\nCreate Entrance\nInterior Management\nGang Management\nOrganization Management\nVehicle Management\nBusiness Management\nServer Management",
            "Select",
            "Close"
        );

        return 1;
    }

    return 0;
}
