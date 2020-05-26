void Zone_PrecacheModels() {
    g_Models.Start = PrecacheModel("materials/s/s_instinct_start.vmt");
    g_Models.End = PrecacheModel("materials/s/s_instinct_end.vmt");
    g_Models.Admin = PrecacheModel("materials/s/s_instinct_admin.vmt");
    g_Models.Laser = PrecacheModel("materials/sprites/laserbeam.vmt");
    
    g_Models.Zone = PrecacheModel("models/error.mdl");
    g_Models.Glow = PrecacheModel("sprites/glow01.vmt");
    g_Models.RedGlow = PrecacheModel("sprites/purpleglow1.vmt");
    g_Models.BlueGlow = PrecacheModel("sprites/blueglow1.vmt");
}

void Zone_Reload() {
    char[] buffer = new char[512];
    Zone_ClearEntities();

    for (int i = 0; i < g_Zones.Length; i++) {
        Zone zone; g_Zones.GetArray(i, zone);
        int entity = CreateEntityByName("trigger_multiple");

        FormatEx(buffer, 512, "%i: timer_zone", i);
        DispatchKeyValue(entity, "targetname", buffer);

        SetEntityModel(entity, "models/error.mdl");
        DispatchKeyValue(entity, "spawnflags", "1088");
        DispatchKeyValue(entity, "StartDisabled", "0");

        if (!DispatchSpawn(entity)) continue;
        ActivateEntity(entity);

        float pos[3], vecMin[3], vecMax[3];
        for (int x = 0; x < 3; x++) pos[x] = (zone.xPos[x] + zone.yPos[x]) / 2;
        MakeVectorFromPoints(pos, zone.xPos, vecMin);
        MakeVectorFromPoints(zone.yPos, pos, vecMax);

        for (int x = 0; x < 3; x++) {
            if (vecMin[x] > 0.0) vecMin[x] *= -1;
            else if (vecMax[x] < 0.0) vecMax[x] *= -1;
        }

        for (int x = 0; x < 2; x++) {
            vecMin[x] += 16.0;
            vecMax[x] -= 16.0;
        }

        SetEntPropVector(entity, Prop_Send, "m_vecMins", vecMin);
        SetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMax);

        SetEntProp(entity, Prop_Send, "m_nSolidType", 2);
        TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);

        SDKHook(entity, SDKHook_StartTouch, Hook_StartTouch);
        SDKHook(entity, SDKHook_EndTouch, Hook_EndTouch);
    }
}

void Zone_ClearEntities() {
    char[] entityName = new char[MAX_NAME_LENGTH];

    for (int i = 0; i <= GetMaxEntities(); i++) {
        if (!IsValidEdict(i) || !IsValidEntity(i)) continue;
        if (!HasEntProp(i, Prop_Send, "m_iName")) continue;
        GetEntPropString(i, Prop_Send, "m_iName", entityName, MAX_NAME_LENGTH);

        if (StrContains(entityName, "timer_zone") == -1) continue;
        AcceptEntityInput(i, "Kill");
    }
}

void Zone_RayTrace(int client, float pos[3]) {
    float eye[3], angle[3];
    GetClientEyePosition(client, eye);
    GetClientEyeAngles(client, angle);

    TR_TraceRayFilter(eye, angle, MASK_SOLID, RayType_Infinite, Filter_HitSelf, client);
    if (TR_DidHit()) TR_GetEndPosition(pos);
}

void Zone_DrawSprite(float pos[3], int model, float size, bool all, int client = 0) {
    if (model == 0) TE_SetupGlowSprite(pos, g_Models.BlueGlow, TIMER_INTERVAL, size, 255);
    else if (model == 1) TE_SetupGlowSprite(pos, g_Models.RedGlow, TIMER_INTERVAL, size, 255);
    else TE_SetupGlowSprite(pos, g_Models.Glow, TIMER_INTERVAL, size, 255);

    if (all) TE_SendToAll();
    else TE_SendToClient(client);
}

void Zone_DrawLine(float xPos[3], float yPos[3], int type, float display, bool all, int client = 0) {
    switch (type % (sizeof(gI_Colors) - 3)) {
        case ZoneType_Start: TE_SetupBeamPoints(xPos, yPos, g_Models.Start, 0, 0, 0, display, 7.0, 7.0, 0, 0.0, gI_Colors[type], 10);
        case ZoneType_End: TE_SetupBeamPoints(xPos, yPos, g_Models.End, 0, 0, 0, display, 7.0, 7.0, 0, 0.0, gI_Colors[type], 10);
        case ZoneType_Admin2: TE_SetupBeamPoints(xPos, yPos, g_Models.Admin, 0, 0, 0, display, 7.0, 7.0, 0, 0.0, gI_Colors[type], 0);
        default: TE_SetupBeamPoints(xPos, yPos, g_Models.Laser, 0, 0, 0, display, 1.0, 1.0, 0, 0.0, gI_Colors[type], 0);
    }

    if (all) TE_SendToAll();
    else TE_SendToClient(client);
}

void Zone_Draw(float xPos[3], float yPos[3], int type, float display, bool all, int client = 0) {
    float points[8][3];
    points[0] = xPos;
    points[7] = xPos;

    if (xPos[2] < yPos[2]) points[7] = yPos;
    else points[0] = yPos;

    points[1][0] = points[7][0];
    points[1][1] = points[0][1];
    points[1][2] = points[0][2];

    points[2][0] = points[7][0];
    points[2][1] = points[7][1];
    points[2][2] = points[0][2];

    points[3][0] = points[0][0];
    points[3][1] = points[7][1];
    points[3][2] = points[0][2];

    points[4][0] = points[0][0];
    points[4][1] = points[7][1];
    points[4][2] = points[7][2];

    points[5][0] = points[0][0];
    points[5][1] = points[0][1];
    points[5][2] = points[7][2];

    points[6][0] = points[7][0];
    points[6][1] = points[0][1];
    points[6][2] = points[7][2];

    for (int i = 0; i < 4; i++) Zone_DrawLine(points[i], points[(i + 1) % 4], type, display, all, client);

    if (type % (sizeof(gI_Colors) - 3) > ZoneType_Checkpoint) {
        if (type == ZoneType_Admin2) type = ZoneType_Admin;
        for (int i = 0; i < 4; i++) Zone_DrawLine(points[i + 4], points[((i + 5) % 4) + 4], type, display, all, client);
        for (int i = 0; i < 4; i++) Zone_DrawLine(points[(i + 3) % 4], points[i + 4], type, display, all, client);
    }
}

void Zone_DrawAdmin(int client, float xPos[3]) {
    static int adminColors[][4] = {
        {255, 0, 0, 255},
        {0, 255, 0, 255},
        {0, 0, 255, 255}
    };

    float yPos[3];
    
    for (int i = 0; i < 3; i++) {
        for (int k = 0; k < 3; k++) yPos[k] = xPos[k];
        yPos[i] += 50.0;

        TE_SetupBeamPoints(xPos, yPos, g_Models.Laser, 0, 0, 30, TIMER_INTERVAL, 1.0, 1.0, 2, 1.0, adminColors[i], 0);
        TE_SendToClient(client);
    }
}

void Zone_New(Zone zone) {
    if (zone.Type == ZoneType_Start || zone.Type == ZoneType_End) {
        int index = g_Zones.FindSingleZone(zone.Type, zone.Group);

        if (index != -1) {
            Zone findZone; g_Zones.GetArray(index, findZone);

            if (zone.Id != findZone.Id) {
                Zone_DeleteZone(findZone.Id);
                Sql_DeleteZone(findZone.Id);
            }
        }
    }

    if (zone.Id != 0) {
        Zone_UpdateZone(zone);
        Sql_UpdateZone(zone);
    } else {
        zone.Checkpoints = new Checkpoints();

        int zoneIndex = g_Zones.PushArray(zone);
        Sql_InsertZone(zoneIndex, zone);
    }

    Zone_Reload();
}

void Zone_UpdateZone(Zone zone) {
    int index = g_Zones.FindByZoneId(zone.Id);
    if (index == -1) return;

    g_Zones.SetArray(index, zone);
}

void Zone_DeleteZone(int zoneId) {
    int index = g_Zones.FindByZoneId(zoneId);
    if (index == -1) return;

    g_Zones.Erase(index);
}

void Zone_Second() {
    for (int i = 0; i < TIMER_ZONES && gI_Render < g_Zones.Length; i++) {
        Zone zone; g_Zones.GetArray(gI_Render, zone);
        gI_Render++;

        if (zone.Hide) continue;
        int type = zone.Type;

        if (zone.Group > 0 && type <= ZoneType_Checkpoint) type = zone.Type + sizeof(gI_Colors) - 3;
        Zone_Draw(zone.xPos, zone.yPos, type, 1.0 + (g_Zones.Length / TIMER_ZONES) * 1.0, true);
    }

    if (gI_Render >= g_Zones.Length) gI_Render = 0;
}

Action Zone_Run(int client, int& buttons) {
    Zone zone;
    bool allowBhop = true;

    if (g_Players[client].CurrentZone != ZoneType_Undefined && g_Players[client].CurrentZone < g_Zones.Length) {
        g_Zones.GetArray(g_Players[client].CurrentZone, zone);

        if (zone.Type == ZoneType_Start) {
            if (g_Players[client].Running && GetEntityFlags(client) & FL_ONGROUND) Zone_ResetTimer(client);
            if (!g_Players[client].ReadyToRun && GetEntityFlags(client) & FL_ONGROUND) g_Players[client].ReadyToRun = true;
            if (!g_Players[client].Running && g_Players[client].ReadyToRun && !(GetEntityFlags(client) & FL_ONGROUND) && (buttons & IN_JUMP)) Zone_StartTimer(client);
            allowBhop = false;
        }
    }

    if (!g_Players[client].Style.Auto) allowBhop = false;

    if (allowBhop && !(GetEntityFlags(client) & FL_ONGROUND) && !(GetEntityFlags(client) & FL_ONGROUND) && GetEntProp(client, Prop_Data, "m_nWaterLevel") < 2) buttons &= ~IN_JUMP;

    return Plugin_Changed;
}

void Zone_Frame() {
    for (int i = 1; i <= MaxClients; i++) {
        if (!CheckPlayer(i, PLAYERCHECK_INGAME)) continue;
        if (g_Players[i].Running) g_Players[i].Record.FrameTime++;

        int totalRecords;
        g_Records.Initilize(g_Players[i].Style.Id, g_Players[i].Record.Group);
        ArrayList globalRecords = g_Records.Get(g_Players[i].Style.Id, g_Players[i].Record.Group);
        g_Players[i].GlobalRecordIndex = Zone_RecordList(g_Players[i].GlobalRecordIndex, globalRecords, g_Players[i].Record.FrameTime);

        g_Players[i].Records.Initilize(g_Players[i].Style.Id, g_Players[i].Record.Group);
        ArrayList records = g_Players[i].Records.Get(g_Players[i].Style.Id, g_Players[i].Record.Group);
        g_Players[i].RecordIndex = Zone_RecordList(g_Players[i].RecordIndex, records, g_Players[i].Record.FrameTime);

        totalRecords = globalRecords.Length;

        if (g_Players[i].Running) Timer_PrintHudText(i, "Frames: %f - %s - %i\n(%i / %i)", Misc_FramesToTime(g_Players[i].Record.FrameTime), g_Players[i].Style.Name, g_Players[i].Record.Group, g_Players[i].GlobalRecordIndex + 1, totalRecords);
    }
}

int Zone_RecordList(int index, ArrayList list, int frameTime) {
    Record record;

    for (int i = 16; i >= 0; i--) {
        int math = index + RoundToFloor(Pow(2.0, float(i)));

        if (math <= list.Length) {
            if (math == list.Length) list.GetArray(list.Length - 1, record);
            else list.GetArray(math - 1, record);

            if (frameTime >= record.FrameTime) return math;
        }
    }

    return index;
}

void Zone_TeleportPlayer(int client, float pos[3]) {
    if (g_Players[client].Running) Zone_ResetTimer(client);
    
    g_Players[client].RecentlyTeleported = true;
    TeleportEntity(client, pos, NULL_VECTOR, NULL_VECTOR);
    CreateTimer(0.1, Timer_TeleportPlayer, client);
}

Action Timer_TeleportPlayer(Handle timer, int client) {
    g_Players[client].RecentlyTeleported = false;
}

void Zone_StartTimer(int client) {
    g_Players[client].Running = true;
    g_Players[client].Record.User = g_Players[client].Id;
    g_Players[client].Record.Style = g_Players[client].Style.Id;
}

void Zone_ResetTimer(int client) {
    g_Players[client].Running = false;
    g_Players[client].ReadyToRun = false;
    g_Players[client].RecordIndex = 0;
    g_Players[client].GlobalRecordIndex = 0;
    g_Players[client].Record.FrameTime = 0;
    g_Players[client].Checkpoints.Clear();

    gC_Bunny.ReplicateToClient(client, "0");
}

void Zone_TeleportToStart(int client, int group) {
    int zoneIndex = g_Zones.FindSingleZone(ZoneType_Start, group);
    if (zoneIndex == -1) return;

    g_Players[client].Record.Group = group;
    Zone zone; g_Zones.GetArray(zoneIndex, zone);
    Zone_TeleportPlayer(client, zone.Pos);
}

void Zone_AddRecord(int client, Record record, ArrayList checkpoints) {
    g_Records.Initilize(record.Style, record.Group);
    g_Players[client].Records.Initilize(record.Style, record.Group);

    ArrayList globalRecords = g_Records.Get(record.Style, record.Group);
    ArrayList records = g_Players[client].Records.Get(record.Style, record.Group);
    int recordIndex = g_Players[client].GlobalRecordIndex;

    for (int i = recordIndex; i < globalRecords.Length; i++) {
        Record checkRecord; globalRecords.GetArray(i, checkRecord);

        if (record.FrameTime >= checkRecord.FrameTime) recordIndex++;
        else break;
    }

    if (recordIndex < globalRecords.Length) globalRecords.ShiftUp(recordIndex);
    else globalRecords.Resize(globalRecords.Length + 1);
    globalRecords.SetArray(recordIndex, record);

    recordIndex = g_Players[client].RecordIndex;

    for (int i = recordIndex; i < records.Length; i++) {
        Record checkRecord; records.GetArray(i, checkRecord);

        if (record.FrameTime >= checkRecord.FrameTime) recordIndex++;
        else break;
    }

    if (recordIndex < records.Length) records.ShiftUp(recordIndex);
    else records.Resize(records.Length + 1);
    records.SetArray(recordIndex, record);

    for (int i = 0; i < checkpoints.Length; i++) {
        CheckpointData checkpoint; checkpoints.GetArray(i, checkpoint);
        Zone_AddCheckpoint(client, g_Players[client].Style.Id, checkpoint);
    }

    delete checkpoints;
}

void Zone_AddCheckpoint(int client, int style, CheckpointData checkpoint) {
    Zone zone; g_Zones.GetArray(checkpoint.ZoneIndex, zone);
    zone.Checkpoints.Initilize(0, style);
    zone.Checkpoints.Initilize(client, style);

    ArrayList globalCheckpoints = zone.Checkpoints.Get(0, style);
    ArrayList checkpoints = zone.Checkpoints.Get(client, style);
    
    for (int i = checkpoint.GlobalIndex; i < globalCheckpoints.Length; i++) {
        CheckpointData checkCheckpoint; globalCheckpoints.GetArray(i, checkCheckpoint);

        if (checkpoint.FrameTime >= checkCheckpoint.FrameTime) checkpoint.GlobalIndex++;
        else break;
    }

    if (checkpoint.GlobalIndex < globalCheckpoints.Length) globalCheckpoints.ShiftUp(checkpoint.GlobalIndex);
    else globalCheckpoints.Resize(checkpoint.GlobalIndex + 1);
    globalCheckpoints.SetArray(checkpoint.GlobalIndex, checkpoint);

    for (int i = checkpoint.Index; i < checkpoints.Length; i++) {
        CheckpointData checkCheckpoint; checkpoints.GetArray(i, checkCheckpoint);

        if (checkpoint.FrameTime >= checkCheckpoint.FrameTime) checkpoint.Index++;
        else break;
    }

    if (checkpoint.Index < checkpoints.Length) checkpoints.ShiftUp(checkpoint.Index);
    else checkpoints.Resize(checkpoint.Index + 1);
    checkpoints.SetArray(checkpoint.Index, checkpoint);
}

bool Filter_HitSelf(int entity, int mask, any data) {
    if (entity == data) return false;
    return true;
}