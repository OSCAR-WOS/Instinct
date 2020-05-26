char gC_CreateTables[][] = {
	"CREATE TABLE IF NOT EXISTS `users` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `steamid` BIGINT NOT NULL, `vip` TINYINT NOT NULL) ENGINE = InnoDB;",
	"CREATE TABLE IF NOT EXISTS `records` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `map` VARCHAR(128) NOT NULL, `user` INT NOT NULL, `frametime` INT NOT NULL, `timestamp` INT NOT NULL, `group` TINYINT NOT NULL, `style` INT NOT NULL, `server` TINYINT NOT NULL) ENGINE = InnoDB;",
	"CREATE TABLE IF NOT EXISTS `checkpoints` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `recordid` INT NOT NULL, `zoneid` INT NOT NULL, `frametime` INT NOT NULL, `timestamp` INT NOT NULL) ENGINE = InnoDB;",
	"CREATE TABLE IF NOT EXISTS `zones` (`id` INT NOT NULL PRIMARY KEY AUTO_INCREMENT, `map` VARCHAR(128) NOT NULL, `zoner` INT NOT NULL, `timestamp` INT NOT NULL, `type` INT NOT NULL, `group` INT NOT NULL, `server` INT NOT NULL, `x1` FLOAT NOT NULL, `x2` FLOAT NOT NULL, `x3` FLOAT NOT NULL, `y1` FLOAT NOT NULL, `y2` FLOAT NOT NULL, `y3` FLOAT NOT NULL, `p1` FLOAT NOT NULL, `p2` FLOAT NOT NULL, `p3` FLOAT NOT NULL, `hide` BOOL NOT NULL) ENGINE = InnoDB;"
};


void Sql_Start() {
    Database.Connect(Sql_ConnectMain, "InstinctMain");
    Database.Connect(Sql_ConnectSlave, "InstinctSlave");

    for (int i = 0; i < sizeof(gC_CreateTables); i++) {
        Query query = new Query(gC_CreateTables[i]);
        query.Type = QueryType_CreateTable;
        query.Main = true;

        g_Queries.Push(query);
    }
}

void Sql_ConnectMain(Database db, const char[] error, any data) {
    if (db == null) SetFailState("Connect Main Error");
    gD_Main = db;
}

void Sql_ConnectSlave(Database db, const char[] error, any data) {
    if (db == null) SetFailState("Connect Slave Error");
    gD_Slave = db;
}

public void Sql_ExecuteMainTransactionSuccess(Database db, any data, int numQueries, DBResultSet[] results, Query[] queryData) {
    for (int i = 0; i < numQueries; i++) HandleQuery(queryData[i], results[i]);
}

public void Sql_ExecuteSlaveTransactionSuccess(Database db, any data, int numQueries, DBResultSet[] results, Query[] queryData) {
    for (int i = 0; i < numQueries; i++) HandleQuery(queryData[i], results[i]);
}

public void Sql_ExecuteMainTransactionError(Database db, any data, int numQueries, const char[] error, int failIndex, Query[] queryData) {
    for (int i = 0; i < failIndex; i++) g_Queries.Push(queryData[i]);
    for (int i = failIndex + 1; i < numQueries; i++) g_Queries.Push(queryData[i]);

    char[] queryString = new char[512];
    queryData[failIndex].GetQueryString(queryString, 512);
    DeleteQuery(queryData[failIndex]);

    LogError("SQL MAIN FAILED: %s ERROR: %s", queryString, error);
}

public void Sql_ExecuteSlaveTransactionError(Database db, any data, int numQueries, const char[] error, int failIndex, Query[] queryData) {
    for (int i = 0; i < failIndex; i++) g_Queries.Push(queryData[i]);
    for (int i = failIndex + 1; i < numQueries; i++) g_Queries.Push(queryData[i]);

    char[] queryString = new char[512];
    queryData[failIndex].GetQueryString(queryString, 512);
    DeleteQuery(queryData[failIndex]);

    LogError("SQL SLAVE FAILED: %s ERROR: %s", queryString, error);
}

void Sql_LoadClient(int client) {
    char[] auth = new char[64];
    char[] queryString = new char[512];

    if (!GetClientAuthId(client, AuthId_SteamID64, auth, 64)) return;
    FormatEx(queryString, 512, "SELECT `id`, `vip` FROM `users` WHERE `steamid` = %s;", auth);

    Query query = new Query(queryString);
    query.Type = QueryType_SelectClient;
    query.Client = client;

    g_Queries.Push(query);
}

void Sql_LoadZones() {
    char[] mapName = new char[64];
    char[] queryString = new char[512];

    GetCurrentMap(mapName, 64);
    FormatEx(queryString, 512, "SELECT `id`, `zoner`, `timestamp`, `type`, `group`, `server`, `x1`, `x2`, `x3`, `y1`, `y2`, `y3`, `p1`, `p2`, `p3`, `hide` FROM `zones` WHERE `map` = '%s';", mapName);

    Query query = new Query(queryString);
    query.Type = QueryType_SelectZones;

    g_Queries.Push(query);
}

void Sql_InsertZone(int zoneIndex, Zone zone) {
    char[] mapName = new char[64];
    char[] queryString = new char[512];

    GetCurrentMap(mapName, 64);
    FormatEx(queryString, 512, "INSERT INTO `zones` (`map`, `zoner`, `timestamp`, `type`, `group`, `server`, `x1`, `x2`, `x3`, `y1`, `y2`, `y3`, `p1`, `p2`, `p3`, `hide`) VALUES ('%s', %i, %i, %i, %i, %i, %f, %f, %f, %f, %f, %f, %f, %f, %f, %i);", mapName, zone.Zoner, zone.Timestamp, zone.Type, zone.Group, zone.Server, zone.xPos[0], zone.xPos[1], zone.xPos[2], zone.yPos[0], zone.yPos[1], zone.yPos[2], zone.Pos[0], zone.Pos[1], zone.Pos[2], view_as<int>(zone.Hide));

    Query query = new Query(queryString);
    query.Type = QueryType_InsertZone;
    query.Main = true;

    query.ZoneIndex = zoneIndex;
    g_Queries.Push(query);
}

void Sql_UpdateZone(Zone zone) {
    char[] queryString = new char[512];
    FormatEx(queryString, 512, "UPDATE `zones` SET `zoner` = %i, `timestamp` = %i, `type` = %i, `group` = %i, `server` = %i, `x1` = %f, `x2` = %f, `x3` = %f, `y1` = %f, `y2` = %f, `y3` = %f, `p1` = %f, `p2` = %f, `p3` = %f, `hide` = %i WHERE `id` = %i;", zone.Zoner, zone.Timestamp, zone.Type, zone.Group, zone.Server, zone.xPos[0], zone.xPos[1], zone.xPos[2], zone.yPos[0], zone.yPos[1], zone.yPos[2], zone.Pos[0], zone.Pos[1], zone.Pos[2], view_as<int>(zone.Hide), zone.Id);

    Query query = new Query(queryString);
    query.Main = true;
    g_Queries.Push(query);
}

void Sql_DeleteZone(int zoneId) {
    char[] queryString = new char[512];
    FormatEx(queryString, 512, "DELETE FROM `zones` WHERE `id` = %i;", zoneId);

    Query query = new Query(queryString);
    query.Main = true;
    g_Queries.Push(query);
}

void Sql_AddRecord(int client, Record record, ArrayList checkpoints = null) {
    char[] mapName = new char[64];
    char[] queryString = new char[512];

    GetCurrentMap(mapName, 64);
    FormatEx(queryString, 512, "INSERT INTO `records` (`map`, `user`, `frametime`, `timestamp`, `group`, `style`, `server`) VALUES ('%s', %i, %i, %i, %i, %i, %i);", mapName, g_Players[client].Id, record.FrameTime, record.Timestamp, record.Group, record.Style, 0);

    Query query = new Query(queryString);
    query.Type = QueryType_InsertRecord;
    query.Main = true;
    query.Checkpoints = checkpoints;

    g_Queries.Push(query);
}

void Sql_AddCheckpoint(CheckpointData checkpoint) {
    char[] queryString = new char[512];
    FormatEx(queryString, 512, "INSERT INTO `checkpoints` (`recordid`, `zoneid`, `frametime`, `timestamp`) VALUES (%i, %i, %i, %i);", checkpoint.RecordId, checkpoint.ZoneId, checkpoint.FrameTime, checkpoint.Timestamp);

    Query query = new Query(queryString);
    query.Type = QueryType_InsertCheckpoint;
    query.Main = true;

    g_Queries.Push(query);
}

void Sql_LoadRecords(int client) {
    char[] mapName = new char[64];
    char[] queryString = new char[512];
    char[] queryString2 = new char[512];

    GetCurrentMap(mapName, 64);
    FormatEx(queryString, 512, "SELECT `id`, `user`, `frametime`, `timestamp`, `group`, `style`, `server` FROM `records` WHERE `map` = '%s'", mapName);
    FormatEx(queryString2, 512, "SELECT c.id, c.recordid, c.zoneid, c.frametime, c.timestamp, r.style FROM checkpoints c, records r WHERE r.id = c.recordid AND r.map = '%s'", mapName);

    if (client != 0) {
        Format(queryString, 512, "%s AND `user` = %i", queryString, g_Players[client].Id);
        Format(queryString2, 512, "%s AND r.user = %i", queryString2, g_Players[client].Id);
    }

    Format(queryString, 512, "%s ORDER BY `frametime` ASC", queryString);
    Format(queryString2, 512, "%s ORDER BY `frametime` ASC", queryString2);

    Query query = new Query(queryString);
    query.Type = QueryType_SelectRecords;
    query.Client = client;
    g_Queries.Push(query);

    Query query2 = new Query(queryString2);
    query2.Type = QueryType_SelectCheckpoints;
    query2.Client = client;
    g_Queries.Push(query2);
}

void HandleQuery(Query query, DBResultSet result) {
    switch (query.Type) {
        case QueryType_SelectClient: Sql_SelectClientPost(query.Client, result);
        case QueryType_InsertClient: Sql_InsertClientPost(query.Client, result);
        case QueryType_SelectZones: Sql_SelectZonesPost(result);
        case QueryType_InsertZone: Sql_InsertZonePost(query.ZoneIndex, result);
        case QueryType_InsertRecord: Sql_InsertRecordPost(query.Checkpoints, result);
        case QueryType_SelectRecords: Sql_SelectRecordsPost(query.Client, result);
        case QueryType_SelectCheckpoints: Sql_SelectCheckpointsPost(query.Client, result);
    }

    DeleteQuery(query);
}

void Sql_SelectCheckpointsPost(int client, DBResultSet result) {
    if (client != 0 && !CheckPlayer(client, PLAYERCHECK_AUTHORIZED)) return;
    char[] zoneChar = new char[8];

    for (int i = 0; i < result.RowCount; i++) {
        result.FetchRow();

        CheckpointData checkpoint;
        checkpoint.Id = result.FetchInt(0);
        checkpoint.RecordId = result.FetchInt(1);
        checkpoint.ZoneId = result.FetchInt(2);
        checkpoint.FrameTime = result.FetchInt(3);
        checkpoint.Timestamp = result.FetchInt(4);

        int style = result.FetchInt(5);

        IntToString(checkpoint.ZoneId, zoneChar, 8);
        if (!gS_Zones.GetValue(zoneChar, checkpoint.ZoneIndex)) continue;
        Zone zone; g_Zones.GetArray(checkpoint.ZoneIndex, zone);

        if (client == 0) {
            zone.Checkpoints.Initilize(0, style);
            ArrayList globalCheckpoints = zone.Checkpoints.Get(0, style);
            globalCheckpoints.PushArray(checkpoint);
        } else {
            zone.Checkpoints.Initilize(client, style);
            ArrayList checkpoints = zone.Checkpoints.Get(client, style);
            checkpoints.PushArray(checkpoint);
        }
    }
}

void Sql_SelectRecordsPost(int client, DBResultSet result) {
    if (client != 0 && !CheckPlayer(client, PLAYERCHECK_AUTHORIZED)) return;

    for (int i = 0; i < result.RowCount; i++) {
        result.FetchRow();

        Record record;
        record.Id = result.FetchInt(0);
        record.User = result.FetchInt(1);
        record.FrameTime = result.FetchInt(2);
        record.Timestamp = result.FetchInt(3);
        record.Group = result.FetchInt(4);
        record.Style = result.FetchInt(5);
        record.Server = result.FetchInt(6);

        if (client == 0) {
            g_Records.Initilize(record.Style, record.Group);
            ArrayList records = g_Records.Get(record.Style, record.Group);
            records.PushArray(record);
        } else {
            g_Players[client].Records.Initilize(record.Style, record.Group);
            ArrayList records = g_Players[client].Records.Get(record.Style, record.Group);
            records.PushArray(record);
        }
    }
}

void Sql_SelectClientPost(int client, DBResultSet result) {
    if (!CheckPlayer(client, PLAYERCHECK_AUTHORIZED)) return;

    if (result.RowCount != 0) {
        result.FetchRow();
        g_Players[client].Id = result.FetchInt(0);
        g_Players[client].Vip = result.FetchInt(1);

        Sql_LoadRecords(client);
    } else {
        char[] auth = new char[64];
        char[] queryString = new char[512];

        if (!GetClientAuthId(client, AuthId_SteamID64, auth, 64)) return;
        FormatEx(queryString, 512, "INSERT INTO `users` (`steamid`, `vip`) VALUES (%s, 0);", auth);

        Query query = new Query(queryString);
        query.Type = QueryType_InsertClient;
        query.Client = client;
        query.Main = true;

        g_Queries.Push(query);
    }
}

void Sql_InsertClientPost(int client, DBResultSet result) {
    if (!CheckPlayer(client, PLAYERCHECK_AUTHORIZED)) return;
    g_Players[client].Id = result.InsertId;
}

void Sql_SelectZonesPost(DBResultSet result) {
    char[] zoneChar = new char[8];

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

        zone.Hide = view_as<bool>(result.FetchInt(15));

        zone.Checkpoints = new Checkpoints();
        int zoneIndex = g_Zones.PushArray(zone);

        IntToString(zone.Id, zoneChar, 8);
        gS_Zones.SetValue(zoneChar, zoneIndex);
    }

    Zone_Reload();
}

void Sql_InsertZonePost(int zoneIndex, DBResultSet result) {
    Zone zone; g_Zones.GetArray(zoneIndex, zone);
    zone.Id = result.InsertId;

    g_Zones.SetArray(zoneIndex, zone);
}

void Sql_InsertRecordPost(ArrayList checkpoints, DBResultSet result) {
    if (checkpoints == null) return;

    for (int i = 0; i < checkpoints.Length; i++) {
        CheckpointData checkpoint; checkpoints.GetArray(i, checkpoint);
        checkpoint.RecordId = result.InsertId;
        Sql_AddCheckpoint(checkpoint);
    }
}

void Sql_Precise() {
    if (g_Queries.Length == 0) return;
    
    char[] queryString = new char[512];
    Transaction txMain = new Transaction();
    Transaction txSlave = new Transaction();
    ArrayList queriesClone = g_Queries.Clone();
    int ranQueries = 0;
    g_Queries.Clear();
    
    for (int i = 0; i < queriesClone.Length; i++) {
        Query query = queriesClone.Get(i);
        ranQueries++;

        if (ranQueries > SQL_QUEUE) g_Queries.Push(query);
        else {
            query.GetQueryString(queryString, 512);

            if (query.Main) {
                if (gD_Main != null) txMain.AddQuery(queryString, query);
                else {
                    if (query.Attempt++ < SQL_TIMEOUT) g_Queries.Push(query);
                    else {
                        LogError("SQL MAIN ATTEMPT FAILED: %s", queryString);
                        DeleteQuery(query);
                    }
                }
            } else {
                if (gD_Slave != null) txSlave.AddQuery(queryString, query);
                else {
                    if (query.Attempt++ < SQL_TIMEOUT) g_Queries.Push(query);
                    else {
                        LogError("SQL SLAVE ATTEMPT FAILED: %s", queryString);
                        DeleteQuery(query);
                    }
                }
            }
        }
    }

    if (gD_Main != null) gD_Main.Execute(txMain, Sql_ExecuteMainTransactionSuccess, Sql_ExecuteMainTransactionError);
    if (gD_Slave != null) gD_Slave.Execute(txSlave, Sql_ExecuteSlaveTransactionSuccess, Sql_ExecuteSlaveTransactionError);
    delete queriesClone;
}

void DeleteQuery(Query query) {
    if (query.Checkpoints != INVALID_HANDLE) delete query.Checkpoints;
    delete query;
}