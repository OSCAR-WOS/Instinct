#define SQL_TIMEOUT 100
#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <instinct>
#include <sdktools>

Database gD_Main = null;
Database gD_Slave = null;

float g_Pos[2][3];

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
    ServerCommand("mp_restartgame 1");

    RegConsoleCmd("sm_test", Command_Test);
}

public Action Command_Test(int client, int args) {
    if (g_Pos[0][0] == 0.0) GetClientAbsOrigin(client, g_Pos[0]);
    else {
        GetClientAbsOrigin(client, g_Pos[1]);

        TE_SetupBeamPoints(g_Pos[0], g_Pos[1], g_Models.Start, g_Models.Glow, 0, 30, 1.0, 5.0, 5.0, 2, 1.0, {255, 0, 0, 255}, 5);
        TE_SendToAll();
    }
}

public void OnMapStart() {
    if (gD_Slave != null) Sql_LoadZones();

    g_Models.Start = PrecacheModel("materials/s/s_instinct_start.vmt");
    g_Models.Glow = PrecacheModel("materials/sprites/glow01.vmt");
}

public void OnClientAuthorized(int client, const char[] auth) {
    Sql_LoadClient(client);
}

Action Timer_Precise(Handle timer, any data) {
    if (g_Queries.Length == 0) return;

    char[] queryString = new char[512];
    Transaction txMain = new Transaction();
    Transaction txSlave = new Transaction();
    ArrayList queriesClone = g_Queries.Clone();
    g_Queries.Clear();

    for (int i = 0; i < queriesClone.Length; i++) {
        Query query = queriesClone.Get(i);
        query.GetQueryString(queryString, 512);

        if (query.Main) {
            if (gD_Main != null) txMain.AddQuery(queryString, query);
            else {
                if (query.Attempt++ < SQL_TIMEOUT) g_Queries.Push(query);
                else LogError("SQL MAIN ATTEMPT FAILED: %s", queryString);
            }
        } else {
            if (gD_Slave != null) txSlave.AddQuery(queryString, query);
            else {
                if (query.Attempt++ < SQL_TIMEOUT) g_Queries.Push(query);
                else LogError("SQL SLAVE ATTEMPT FAILED: %s", queryString);
            }
        }
    }   

    if (gD_Main != null) gD_Main.Execute(txMain, Sql_ExecuteMainTransactionSuccess, Sql_ExecuteMainTransactionError);
    if (gD_Slave != null) gD_Slave.Execute(txSlave, Sql_ExecuteSlaveTransactionSuccess, Sql_ExecuteSlaveTransactionError);
    delete queriesClone;
}

#include "instinct\hook.sp"
#include "instinct\sql.sp"
#include "instinct\zone.sp"