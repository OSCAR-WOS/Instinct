public void Hook_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    Zone_Reload();
}

public void Hook_PlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (!CheckPlayer(client, PLAYERCHECK_INGAME)) return;

    SetEntData(client, g_offsCollisionGroup, 2, 4, true);
    Zone_TeleportToStart(client, 0);
    if (strlen(g_Players[client].Style.Name) == 0) g_Styles.GetArray(0, g_Players[client].Style);

    RequestFrame(Frame_PlayerSpawn, client);
}

void Frame_PlayerSpawn(int client) {
    SetEntProp(client, Prop_Send, "m_iHideHUD", 4105);
}

public Action Hook_StartTouch(int caller, int activator) {
    if (!CheckPlayer(activator, PLAYERCHECK_VALID | PLAYERCHECK_INGAME)) return;
    char[] entityName = new char[512];
    char[] entityIndex = new char[64];

    GetEntPropString(caller, Prop_Send, "m_iName", entityName, 512);
    SplitString(entityName, ":" , entityIndex, 64);

    int index = StringToInt(entityIndex);
    if (index == -1) return;

    Zone zone; g_Zones.GetArray(index, zone);
    g_Players[activator].CurrentZone = index;

    switch (zone.Type) {
        case ZoneType_Start: {
            g_Players[activator].Record.Group = zone.Group;

            Zone_ResetTimer(activator);
        } case ZoneType_End: {
            if (!g_Players[activator].Running) return;
            if (g_Players[activator].Record.Group != zone.Group) return;

            g_Players[activator].Running = false;
            g_Players[activator].Record.Timestamp = GetTime();

            Sql_AddRecord(activator, g_Players[activator].Record, g_Players[activator].Checkpoints.Clone());
            Zone_AddRecord(activator, g_Players[activator].Record, g_Players[activator].Checkpoints.Clone());
            Misc_EndMessage(activator, g_Players[activator].Record);
        } case ZoneType_Checkpoint: {
            if (!g_Players[activator].Running) return;
            if (g_Players[activator].Record.Group != zone.Group) return;

            CheckpointData checkpoint;
            checkpoint.ZoneId = zone.Id;
            checkpoint.FrameTime = g_Players[activator].Record.FrameTime;
            checkpoint.Timestamp = GetTime();
            checkpoint.ZoneIndex = index;

            bool newCheckpoint = true;
            ArrayList checkpoints = g_Players[activator].Checkpoints.Clone();

            for (int i = 0; i < checkpoints.Length; i++) {
                CheckpointData checkCheckpoint; checkpoints.GetArray(i, checkCheckpoint);
                if (checkCheckpoint.ZoneId == zone.Id) {
                    newCheckpoint = false; break;
                }
            }

            delete checkpoints;
            if (!newCheckpoint) return;

            int globalCheckpointLength, checkpointLength;
            int globalTime, personalTime;

            zone.Checkpoints.Initilize(0, g_Players[activator].Style.Id);
            ArrayList globalCheckpoints = zone.Checkpoints.Get(0, g_Players[activator].Style.Id);
            globalCheckpointLength = globalCheckpoints.Length;

            for (int i = 0; i < globalCheckpoints.Length; i++) {
                CheckpointData checkCheckpoint; globalCheckpoints.GetArray(i, checkCheckpoint);

                if (i == 0) globalTime = checkCheckpoint.FrameTime;
                if (checkpoint.FrameTime >= checkCheckpoint.FrameTime) checkpoint.GlobalIndex++;
                else break;
            }

            zone.Checkpoints.Initilize(activator, g_Players[activator].Style.Id);
            ArrayList personalCheckpoints = zone.Checkpoints.Get(activator, g_Players[activator].Style.Id);
            checkpointLength = personalCheckpoints.Length;

            for (int i = 0; i < personalCheckpoints.Length; i++) {
                CheckpointData checkCheckpoint; personalCheckpoints.GetArray(i, checkCheckpoint);

                if (i == 0) personalTime = checkCheckpoint.FrameTime;
                if (checkpoint.FrameTime >= checkCheckpoint.FrameTime) checkpoint.Index++;
                else break;
            }

            g_Players[activator].Checkpoints.PushArray(checkpoint);
            Misc_CheckpointMessage(activator, checkpoint, globalCheckpointLength, checkpointLength, globalTime, personalTime);
        }
    }
}

public Action Hook_EndTouch(int caller, int activator) {
    if (!CheckPlayer(activator, PLAYERCHECK_VALID | PLAYERCHECK_INGAME)) return;
    if (g_Players[activator].RecentlyTeleported) return;
    char[] entityName = new char[512];
    char[] entityIndex = new char[4];

    GetEntPropString(caller, Prop_Send, "m_iName", entityName, 512);
    SplitString(entityName, ":" , entityIndex, 4);

    int index = StringToInt(entityIndex);
    if (index == -1) return;

    Zone zone; g_Zones.GetArray(index, zone);
    g_Players[activator].CurrentZone = ZoneType_Undefined;

    switch (zone.Type) {
        case ZoneType_Start: {
            if (!g_Players[activator].ReadyToRun) return;
            Zone_StartTimer(activator);

            if (g_Players[activator].Style.Auto) gC_Bunny.ReplicateToClient(activator, "1");
        }
    }
}

public Action Hook_SayText2(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init) {
    char[] message = new char[512];
    int client = msg.ReadInt("ent_idx");
    msg.ReadString("params", message, 512, 1);

    DataPack pack = new DataPack();
    pack.WriteCell(client);
    pack.WriteString(message);
    RequestFrame(Frame_Hook_SayText2, pack);

    return Plugin_Stop;
}

void Frame_Hook_SayText2(DataPack pack) {
    char[] message = new char[512];
    char[] formattedMessage = new char[512];
    pack.Reset();

    int client = pack.ReadCell();
    pack.ReadString(message, 512);
    delete pack;

    switch (g_Players[client].Vip) {
        case Vip_None: FormatEx(formattedMessage, 512, "{grey}%N: %s", client, message);
        case Vip_Standard: FormatEx(formattedMessage, 512, "{white}%N: %s", client, message);
        case Vip_Dev: {
            char[] clientName = new char[MAX_NAME_LENGTH];
            GetClientName(client, clientName, MAX_NAME_LENGTH);

            for (int i = 0; clientName[i] != '\0'; i++) {
                int color = (i + g_Players[client].ChatNameColorOffset) % (sizeof(gC_ChatColors) - 1);
                Format(formattedMessage, 512, "%s%s%c", formattedMessage, gC_ChatColorCodes[color], clientName[i]);
            }

            if (g_Players[client].ChatNameColorOffset++ == sizeof(gC_ChatColors)) g_Players[client].ChatNameColorOffset = 0;
            Format(formattedMessage, 512, "%s{white}: %s", formattedMessage, message);
        }
    }

    Timer_PrintToChat(client, formattedMessage, false);
}