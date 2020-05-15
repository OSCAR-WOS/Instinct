#include <sourcemod>

char gC_CreateTables[][] = {
	"CREATE TABLE IF NOT EXISTS `users` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `steamid` BIGINT NOT NULL) ENGINE = InnoDB;",
	"CREATE TABLE IF NOT EXISTS `records` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `map` VARCHAR(128) NOT NULL, `user` INT NOT NULL, `time` INT NOT NULL, `timestamp` INT NOT NULL, `group` INT NOT NULL, `style` INT NOT NULL, `server` INT NOT NULL) ENGINE = InnoDB;",
	"CREATE TABLE IF NOT EXISTS `checkpoints` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `recordid` INT NOT NULL, `checkpointid` INT NOT NULL, `time` INT NOT NULL, `timestamp` INT NOT NULL) ENGINE = InnoDB;",
	"CREATE TABLE IF NOT EXISTS `zones` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `map` VARCHAR(128) NOT NULL, `zoner` INT NOT NULL, `timestamp` INT NOT NULL, `type` INT NOT NULL, `group` INT NOT NULL, `server` INT NOT NULL, `x1` FLOAT NOT NULL, `x2` FLOAT NOT NULL, `x3` FLOAT NOT NULL, `y1` FLOAT NOT NULL, `y2` FLOAT NOT NULL, `y3` FLOAT NOT NULL, `p1` FLOAT NOT NULL, `p2` FLOAT NOT NULL, `p3` FLOAT NOT NULL) ENGINE = InnoDB;"
};

void Sql_ConnectMain(Database db, const char[] error, any data) {
    if (db == null) SetFailState("Connect Main Error");
    gD_Main = db;

    for (int i = 0; i < sizeof(gC_CreateTables); i++) {
        Query query = new Query(gC_CreateTables[i]);
        query.Type = QueryType_CreateTable;
        query.Main = true;

        g_Queries.Push(query);
    }
}

void Sql_ConnectSlave(Database db, const char[] error, any data) {
    if (db == null) SetFailState("Connect Slave Error");
    gD_Slave = db;

    for (int i = 1; i <= MaxClients; i++) {
        if (!CheckPlayer(i, PLAYERCHECK_AUTHORIZED)) continue;
        Sql_LoadClient(i);
    }

    Sql_LoadZones();
}

void Sql_ExecuteMainTransactionSuccess(Database db, any data, int numQueries, DBResultSet[] results, Query[] queryData) {
    for (int i = 0; i < numQueries; i++) HandleQuery(queryData[i], results[i]);
}

void Sql_ExecuteSlaveTransactionSuccess(Database db, any data, int numQueries, DBResultSet[] results, Query[] queryData) {
    for (int i = 0; i < numQueries; i++) HandleQuery(queryData[i], results[i]);
}

void Sql_ExecuteMainTransactionError(Database db, any data, int numQueries, const char[] error, int failIndex, Query[] queryData) {
    for (int i = 0; i < failIndex; i++) {
        g_Queries.Push(queryData[i]);
    }

    for (int i = failIndex + 1; i < numQueries; i++) {
        g_Queries.Push(queryData[i]);
    }

    char[] queryString = new char[512];
    queryData[failIndex].GetQueryString(queryString, 512);
    delete queryData[failIndex];

    LogError("SQL MAIN FAILED: %s ERROR: %s", queryString, error);
}

void Sql_ExecuteSlaveTransactionError(Database db, any data, int numQueries, const char[] error, int failIndex, Query[] queryData) {
    for (int i = 0; i < failIndex; i++) {
        g_Queries.Push(queryData[i]);
    }

    for (int i = failIndex + 1; i < numQueries; i++) {
        g_Queries.Push(queryData[i]);
    }

    char[] queryString = new char[512];
    queryData[failIndex].GetQueryString(queryString, 512);
    delete queryData[failIndex];

    LogError("SQL SLAVE FAILED: %s ERROR: %s", queryString, error);
}

void Sql_LoadClient(int client) {
    char[] auth = new char[64];
    char[] queryString = new char[512];

    if (!GetClientAuthId(client, AuthId_SteamID64, auth, 64)) return;
    FormatEx(queryString, 512, "SELECT `id` FROM `users` WHERE `steamid` = %s;", auth);

    Query query = new Query(queryString);
    query.Type = QueryType_SelectClient;
    query.Client = client;

    g_Queries.Push(query);
}

void Sql_LoadZones() {
    char[] mapName = new char[64];
    char[] queryString = new char[512];

    GetCurrentMap(mapName, 64);
    gD_Slave.Escape(mapName, mapName, 64);

    FormatEx(queryString, 512, "SELECT `id`, `zoner`, `timestamp`, `type`, `group`, `server`, `x1`, `x2`, `x3`, `y1`, `y2`, `y3`, `p1`, `p2`, `p3` FROM `zones` WHERE `map` = '%s';", mapName);

    Query query = new Query(queryString);
    query.Type = QueryType_SelectZones;

    g_Zones.Clear();
    g_Queries.Push(query);
}

void Sql_InsertZone(int zoneIndex, Zone zone) {
    char[] mapName = new char[64];
    char[] queryString = new char[512];

    GetCurrentMap(mapName, 64);
    gD_Slave.Escape(mapName, mapName, 64);

    FormatEx(queryString, 512, "INSERT INTO `zones` (`map`, `zoner`, `timestamp`, `type`, `group`, `server`, `x1`, `x2`, `x3`, `y1`, `y2`, `y3`, `p1`, `p2`, `p3`) VALUES ('%s', %i, %i, %i, %i, %i, %f, %f, %f, %f, %f, %f, %f, %f, %f);", mapName, zone.Zoner, zone.Timestamp, zone.Type, zone.Group, zone.Server, zone.xPos[0], zone.xPos[1], zone.xPos[2], zone.yPos[0], zone.yPos[1], zone.yPos[2], zone.Pos[0], zone.Pos[1], zone.Pos[2]);

    Query query = new Query(queryString);
    query.Type = QueryType_InsertZone;
    query.Main = true;

    query.Zone = zoneIndex;
    g_Queries.Push(query);
}

void HandleQuery(Query query, DBResultSet result) {
    switch (query.Type) {
        case QueryType_SelectClient: Sql_SelectClientPost(query.Client, result);
        case QueryType_InsertClient: Sql_InsertClientPost(query.Client, result);
        case QueryType_SelectZones: Sql_SelectZonesPost(result);
        case QueryType_InsertZone: Sql_InsertZonePost(query.Zone, result);
    }

    delete query;
}

void Sql_SelectClientPost(int client, DBResultSet result) {
    if (!CheckPlayer(client, PLAYERCHECK_AUTHORIZED)) return;

    if (result.RowCount != 0) {
        result.FetchRow();
        g_Players[client].Id = result.FetchInt(0);
    } else {
        char[] auth = new char[64];
        char[] queryString = new char[512];

        if (!GetClientAuthId(client, AuthId_SteamID64, auth, 64)) return;
        FormatEx(queryString, 512, "INSERT INTO `users` (`steamid`) VALUES (%s);", auth);

        Query query = new Query(queryString);
        query.Type = QueryType_InsertClient;
        query.Client = client;

        g_Queries.Push(query);
    }
}

void Sql_InsertClientPost(int client, DBResultSet result) {
    if (!CheckPlayer(client, PLAYERCHECK_AUTHORIZED)) return;

    g_Players[client].Id = result.InsertId;
}

void Sql_SelectZonesPost(DBResultSet result) {
    for (int i = 0; i < result.RowCount; i++) {
        result.FetchRow();

        Zone zone;
        zone.Id = result.FetchInt(0);
        zone.Zoner = result.FetchInt(1);
        zone.Timestamp = result.FetchInt(2);
        zone.Type = result.FetchInt(3);
        zone.Group = result.FetchInt(4);
        zone.Server = result.FetchInt(5);

        for (int x = 0; x < 3; x++) {
            zone.xPos[x] = result.FetchFloat(6 + x);
            zone.yPos[x] = result.FetchFloat(9 + x);
            zone.Pos[x] = result.FetchFloat(12 + x);
        }

        g_Zones.PushArray(zone);
    }
}

void Sql_InsertZonePost(int zoneIndex, DBResultSet result) {
    Zone zone; g_Zones.GetArray(zoneIndex, zone);
    zone.Id = result.InsertId;

    g_Zones.SetArray(zoneIndex, zone);
}