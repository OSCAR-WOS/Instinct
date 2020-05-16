public void Hook_RoundStart(Event event, const char[] name, bool dontBroadcast) {
    Zone_Reload();
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

    switch (g_Players[client].Vip) {
        case Vip_None: FormatEx(formattedMessage, 512, "{grey}%N{white}: {grey}%s", client, message);
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
    delete pack;
}