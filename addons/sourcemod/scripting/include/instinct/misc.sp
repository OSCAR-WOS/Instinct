void Misc_Start() {
    Misc_Load();

    gF_TickRate = GetGameFrameTime();
    RegConsoleCmd("sm_settings", Command_Settings);
    RegConsoleCmd("sm_r", Command_Restart);
}

void Misc_Load() {
    char[] buffer = new char[512];
    char[][] explodedString = new char[64][512];
    BuildPath(Path_SM, buffer, 512, "configs/instinct.cfg");

    KeyValues instinct = new KeyValues("instinct");
    instinct.ImportFromFile(buffer);

    instinct.JumpToKey("styles");
    instinct.GotoFirstSubKey();

    do {
        Style style;
        int explode = 0;

        instinct.GetString("name", style.Name, 16);
        instinct.GetString("prefix", style.Prefix, 4);
        instinct.GetString("aliases", style.Aliases, 64);

        style.Ranked = view_as<bool>(instinct.GetNum("ranked"));
        style.Auto = view_as<bool>(instinct.GetNum("autobhop"));
        ExplodeString(style.Aliases, ", ", explodedString, 64, 512);

        instinct.GetSectionName(buffer, 512);
        style.Id = StringToInt(buffer);

        while(strlen(explodedString[explode]) > 0) {
            TrimString(explodedString[explode]);

            FormatEx(buffer, 512, "sm_%s", explodedString[explode]);
            RegConsoleCmd(buffer, Command_Style);
            explode++;
        }

        g_Styles.PushArray(style);
    } while (instinct.GotoNextKey());
    delete instinct;
}

float Misc_FramesToTime(int frameTime) {
    return frameTime * gF_TickRate;
}

void Misc_CheckpointMessage(int client, CheckpointData checkpoint, int globalLength, int personalLength, int globalTime, int personalTime) {
    char[] buffer = new char[512];
    char[] buffer2 = new char[512];

    char[] timeString = new char[64];
    Misc_FormatTime(checkpoint.FrameTime, timeString, 64);
    FormatEx(buffer, 512, "%T", "chat_checkpoint", client, timeString);

    if (!g_Players[client].Settings.Checkpoints.NoRank) Format(buffer, 512, "%s ({blue}#%i/%i{white}) ({lightred}#%i/%i{white})", buffer, checkpoint.Index + 1, personalLength + 1, checkpoint.GlobalIndex + 1, globalLength + 1);
    Timer_PrintToChat(client, buffer, true);

    if (!g_Players[client].Settings.Checkpoints.NoPb) {
        char[] pbString = new char[64];
        Misc_FormatTime(personalTime, pbString, 64);

        if (!g_Players[client].Settings.Checkpoints.NoDiff) {
            char[] pbDiff = new char[128];
            Misc_FormatTime(personalTime - checkpoint.FrameTime, pbDiff, 128);
            Misc_FormatChatPrefix(personalTime, personalTime - checkpoint.FrameTime, pbDiff, 128);
            Format(buffer2, 512, "%s %s", buffer2, pbDiff);
        }

        Format(buffer2, 512, "%s ({blue}PB: {yellow}%s{white})", buffer2, pbString);
    }    

    if (!g_Players[client].Settings.Checkpoints.NoGb) {
        if (strlen(buffer2) > 0) Format(buffer2, 512, "%s | ", buffer2);
        char[] gbString = new char[64];
        Misc_FormatTime(globalTime, gbString, 64);

        if (!g_Players[client].Settings.Checkpoints.NoDiff) {
            char[] gbDiff = new char[128];
            Misc_FormatTime(globalTime - checkpoint.FrameTime, gbDiff, 128);
            Misc_FormatChatPrefix(globalTime, globalTime - checkpoint.FrameTime, gbDiff, 128);
            Format(buffer2, 512, "%s %s", buffer2, gbDiff);
        }

        Format(buffer2, 512, "%s ({lightred}GB: {yellow}%s{white})", buffer2, gbString);
    }
    
    if (strlen(buffer2) > 0) Timer_PrintToChat(client, buffer2, false);
}

void Misc_EndMessage(int client, Record record) {
    ArrayList globalRecords = g_Records.Get(record.Style, record.Group);
    ArrayList records = g_Players[client].Records.Get(record.Style, record.Group);

    char[] buffer = new char[512];

    char[] timeString = new char[64];
    Misc_FormatTime(record.FrameTime, timeString, 64);
    FormatEx(buffer, 512, "%T", "chat_finish", client, timeString);

    if (!g_Players[client].Settings.Records.NoRank) Format(buffer, 512, "%s ({blue}#%i/%i{white}) ({lightred}#%i/%i{white})", buffer, g_Players[client].RecordIndex + 1, records.Length, g_Players[client].GlobalRecordIndex + 1, globalRecords.Length);
    Timer_PrintToChat(client, buffer, true);
}

void Misc_FormatTime(int frameTime, char[] buffer, int maxLength) {
    int time = RoundToFloor(frameTime * gF_TickRate * 1000);

    if (time < 0) time *= -1;
    if (time >= 3600000) { Format(buffer, maxLength, "%02d:", RoundToFloor(float(time) / 3600000)); time = time % 3600000; }
    Format(buffer, maxLength, "%s%02d:", buffer, RoundToFloor(float(time) / 60000)); time = time % 60000;
    Format(buffer, maxLength, "%s%02d.", buffer, RoundToFloor(float(time) / 1000)); time = time % 1000;
    Format(buffer, maxLength, "%s%03d", buffer, time);
}

void Misc_FormatChatPrefix(int frameTime, int frameDiff, char[] buffer, int maxLength) {
    if (frameTime == 0) Format(buffer, maxLength, "{grey}%s{white}", buffer);
    else if (frameDiff == 0) Format(buffer, maxLength, "{orange}%s{white}", buffer);
    else if (frameDiff < 0) Format(buffer, maxLength, "{lightred}+%s{white}", buffer);
    else Format(buffer, maxLength, "{lime}-%s{white}", buffer);
}