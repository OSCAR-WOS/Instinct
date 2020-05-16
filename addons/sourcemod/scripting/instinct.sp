#define MENU_PREFIX "Instinct (1.00)"
#define CHAT_PREFIX "{magenta}Instinct {white}| "

#define SQL_TIMEOUT 100
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <instinct>
#include <sdktools>

Database gD_Main = null;
Database gD_Slave = null;

Zones g_Zones;
Models g_Models;
Queries g_Queries;
Player g_Players[MAXPLAYERS + 1];

public void OnPluginStart() {
    g_Queries = new Queries();
    g_Zones = new Zones();

    Database.Connect(Sql_ConnectMain, "InstinctMain");
    Database.Connect(Sql_ConnectSlave, "InstinctSlave");

    CreateTimer(0.01, Timer_Precise, _, TIMER_REPEAT);

    HookEvent("round_start", Hook_RoundStart);
    ServerCommand("sm_reload_translations");
    ServerCommand("mp_restartgame 1");

    RegConsoleCmd("sm_test", Command_Test);
    LoadTranslations("instinct.phrases");

    for (int i = 1; i <= MaxClients; i++) {
        if (!CheckPlayer(i, PLAYERCHECK_INGAME)) continue;
        OnClientPutInServer(i);
    }
}

public void OnConfigsExecuted() {
    UserMsg SayText2 = GetUserMessageId("SayText2");
    HookUserMessage(SayText2, Hook_SayText2, true);
}

public Action Command_Test(int client, int args) {
    return Plugin_Handled;
}

public void OnMapStart() {
    if (gD_Slave != null) Sql_LoadZones();

    g_Models.Start = PrecacheModel("materials/s/s_instinct_start.vmt");
    g_Models.Glow = PrecacheModel("materials/sprites/glow01.vmt");
}

public void OnClientAuthorized(int client, const char[] auth) {
    Sql_LoadClient(client);
}

public void OnClientPutInServer(int client) {

}

Action Timer_Precise(Handle timer, any data) {
    Sql_Precise();
}

#include "instinct/admin.sp"
#include "instinct/hook.sp"
#include "instinct/sql.sp"
#include "instinct/zone.sp"