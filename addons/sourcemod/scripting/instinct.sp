#define MENU_PREFIX "Instinct (1.00) | "
#define CHAT_PREFIX "{magenta}Instinct {white}| "

#define SQL_TIMEOUT 100
#define SQL_QUEUE 128
#define TIMER_ZONES 32
#define TIMER_INTERVAL 0.1
#define BOX_BOUNDARY 120.0

#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 131072

#include <sourcemod>
#include <instinct>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

int gI_Render;
float gF_TickRate;
Database gD_Main = null;
Database gD_Slave = null;

Zones g_Zones;
StringMap gS_Zones;

Models g_Models;
Queries g_Queries;
Records g_Records;
ArrayList g_Styles;
Player g_Players[MAXPLAYERS + 1];

ConVar gC_Bunny;
int g_offsCollisionGroup;

public void OnPluginStart() {
    g_Zones = new Zones();
    gS_Zones = new StringMap();

    g_Queries = new Queries();
    g_Records = new Records();
    g_Styles = new ArrayList(sizeof(Style));
   
    Misc_Start();
    Sql_Start();

    CreateTimer(1.0, Timer_Second, _, TIMER_REPEAT);
    CreateTimer(TIMER_INTERVAL, Timer_Precise, _, TIMER_REPEAT);

    HookEvent("round_start", Hook_RoundStart);
    HookEvent("player_spawn", Hook_PlayerSpawn);
    RegConsoleCmd("sm_test", Command_Test);

    ServerCommand("mp_restartgame 1");
    ServerCommand("sm_reload_translations");
    LoadTranslations("instinct.phrases");

    for (int i = 1; i <= MaxClients; i++) {
        if (!CheckPlayer(i, PLAYERCHECK_INGAME)) continue;
        OnClientPutInServer(i);
    }
}

public void OnConfigsExecuted() {
    UserMsg SayText2 = GetUserMessageId("SayText2");
    HookUserMessage(SayText2, Hook_SayText2, true);

    gC_Bunny = FindConVar("sv_autobunnyhopping");
    g_offsCollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
}

public Action Command_Test(int client, int args) {
    Admin_Zone(client);
    return Plugin_Handled;
}

public void OnMapStart() {
    Zone_PrecacheModels();

    for (int i = 0; i < g_Zones.Length; i++) {
        Zone zone; g_Zones.GetArray(i, zone);
        zone.Checkpoints.Trash();
    }

    g_Zones.Clear();
    Sql_LoadZones();

    g_Records.Trash();
    Sql_LoadRecords(0);

    for (int i = 1; i <= MaxClients; i++) {
        if (!CheckPlayer(i, PLAYERCHECK_INGAME)) continue;
        Sql_LoadRecords(i);
    }
}

public void OnClientPutInServer(int client) {
    Player newPlayer; g_Players[client] = newPlayer;
    g_Players[client].Checkpoints = new ArrayList(sizeof(CheckpointData));
    g_Players[client].Records = new Records();
    Sql_LoadClient(client);
}

public void OnClientDisconnected(int client) {
    delete g_Players[client].Checkpoints;

    g_Players[client].Records.Trash();
    delete g_Players[client].Records;
}

Action Timer_Second(Handle timer, any data) {
    Admin_Second();
    Zone_Second();
}

Action Timer_Precise(Handle timer, any data) {
    Admin_Precise();
    Sql_Precise();
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
    Admin_Run(client, buttons);
    Zone_Run(client, buttons);
}

public void OnGameFrame() {
    Zone_Frame();
}

#include "instinct/admin.sp"
#include "instinct/commands.sp"
#include "instinct/hook.sp"
#include "instinct/misc.sp"
#include "instinct/sql.sp"
#include "instinct/zone.sp"