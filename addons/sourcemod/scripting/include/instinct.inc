#define PLAYERCHECK_AUTHORIZED (1<<0)
#define PLAYERCHECK_VALID (1<<1)
#define PLAYERCHECK_INGAME (1<<2)
#define PLAYERCHECK_ALIVE (1<<3)

enum {
    ZoneType_Start = 0,
    ZoneType_End,
    ZoneType_Checkpoint,
    ZoneType_Pvp,
    ZoneType_Admin,
    ZoneType_Admin2,
    ZoneType_Undefined = -1,
}

enum {
    AdminStage_None = 0,
    AdminStage_Drawing,
    AdminStage_Edit1,
    AdminStage_Edit2,
    AdminStage_EditType,
    AdminStage_Saving,
    AdminStage_Editing,
    AdminStage_Deleting
}

enum {
    QueryType_CreateTable = 0,
    QueryType_SelectClient,
    QueryType_InsertClient,
    QueryType_SelectZones,
    QueryType_InsertZone,
    QueryType_InsertRecord,
    QueryType_InsertCheckpoint,
    QueryType_SelectRecords,
    QueryType_SelectCheckpoints
}

enum {
    Setting_Checkpoint,
}

enum {
    Vip_None = 0,
    Vip_Standard,
    Vip_Boosted,
    Vip_Dev = -1
}

enum struct CheckpointSettings {
    bool NoRank;
    bool NoDiff;
    bool NoPb;
    bool NoGb;
}

enum struct RecordSettings {
    bool NoRank;
    bool NoDiff;
    bool NoPb;
    bool NoGb;
}

enum struct Settings {
    CheckpointSettings Checkpoints;
    RecordSettings Records;
}

enum struct Models {
    int Start;
    int End;
    int Checkpoint;
    int Admin;
    int Pvp;

    int Zone;
    int Laser;
    
    int Glow;
    int RedGlow;
    int BlueGlow;
}

enum struct Style {
    int Id;
    char Name[16];
    char Prefix[4];
    char Aliases[64];

    bool Ranked;
    bool Auto;
}

enum struct CheckpointData {
    int Id;
    int RecordId;
    int ZoneId;
    int FrameTime;
    int Timestamp;

    int ZoneIndex;
    int Index;
    int GlobalIndex;
}

enum struct Record {
    int Id;
    int User;
    int FrameTime;
    int Timestamp;

    int Group;
    int Style;
    int Server;
}

enum struct Zone {
    Checkpoints Checkpoints;

    int Id;
    int Zoner;
    int Timestamp;
    int Type;
    int Group;
    int Server;

    float xPos[3];
    float yPos[3];
    float Pos[3];
    bool Hide;
}

enum struct Admin {
    int Stage;
    int Option;
    Zone Zone;
}

enum struct Player {
    Admin Admin;
    Record Record;
    Style Style;

    Records Records;
    ArrayList Checkpoints;

    int RecordIndex;
    int GlobalRecordIndex;

    int Id;
    int Vip;
    int ChatNameColorOffset;
    
    int CurrentZone;
    bool Running;
    bool ReadyToRun;
    bool RecentlyTeleported;

    Settings Settings;
}

int gI_Colors[][4] = {
    {0, 127, 0, 255},
    {127, 0, 0, 255},
    {255, 127, 80, 255},
    {128, 0, 0, 255},
    {255, 218, 185, 255},
    {255, 255, 0, 255},
    {0, 191, 255, 255},
    {75, 0, 130, 255},
    {128, 128, 128, 255}
};

char gC_ZoneType[][][] = {
    {"menu_zonetype_start", "zonetype_start"},
    {"menu_zonetype_end", "zonetype_end"},
    {"menu_zonetype_checkpoint", "zonetype_checkpoint"},
    {"menu_zonetype_pvp", "zonetype_pvp"}
};

char gC_Settings[][] = {
    "menu_settings_checkpoints",
    "menu_settings_records"
};

char gC_CheckpointSettings[][][] = {
    {"menu_settings_checkpoints_rank", "settings_checkpoints_rank", "menu_settings_checkpoints_rank_info"},
    {"menu_settings_checkpoints_diff", "settings_checkpoints_diff",
    "menu_settings_checkpoints_diff_info"},
    {"menu_settings_checkpoints_pb", "settings_checkpoints_pb",
    "menu_settings_checkpoints_pb_info"},
    {"menu_settings_checkpoints_gb", "settings_checkpoints_gb","menu_settings_checkpoints_gb_info"}
};

char gC_ChatColors[][] = {
    "{white}",
    "{darkred}",
    "{purple}",
    "{green}",
    "{olive}",
    "{lime}",
    "{red}",
    "{grey}",
    "{yellow}",
    "{orange}",
    "{blue}",
    "{darkblue}",
    "{magenta}",
    "{lightred}"
};

char gC_ChatColorCodes[][] = {
    "\x01",
    "\x02",
    "\x03",
    "\x04",
    "\x05",
    "\x06",
    "\x07",
    "\x08",
    "\x09",
    "\x10",
    "\x0B",
    "\x0C",
    "\x0E",
    "\x0F"
};

stock bool CheckPlayer(int client, int flags) {
    if (client <= 0 || client > MaxClients) return false;

    if (flags & PLAYERCHECK_AUTHORIZED) {
        if (!IsClientAuthorized(client)) return false;
    }

    if (flags & PLAYERCHECK_VALID) {
        if (IsFakeClient(client)) return false;
    }

    if (flags & PLAYERCHECK_INGAME) {
        if (!IsClientInGame(client)) return false;
    }

    if (flags & PLAYERCHECK_ALIVE) {
        if (!IsPlayerAlive(client)) return false;
    }

    return true;
}

stock void Timer_PrintToChat(int client, const char[] message, bool tag = true, any ...) {
    SetGlobalTransTarget(client);

    char[] formattedMessage = new char[512];
    VFormat(formattedMessage, 512, message, 4);

    if (tag) Format(formattedMessage, 512, " %s%s", CHAT_PREFIX, formattedMessage);
    else Format(formattedMessage, 512, " %s", formattedMessage);

    for (int i = 0; i < sizeof(gC_ChatColorCodes); i++) {
        ReplaceString(formattedMessage, 512, gC_ChatColors[i], gC_ChatColorCodes[i]);
    }

    PrintToChat(client, formattedMessage);
}

stock bool Timer_IsPointInsideBox(float pos[3], float xPos[3], float yPos[3]) {
    for (int i = 0; i < 2; i++) {
        if (xPos[i] >= pos[i] == yPos[i] >= pos[i]) return false;
    }

    return true;
}

stock void Timer_PrintHudText(int client, const char[] message, any ...) {
    char[] buffer = new char[512];
    VFormat(buffer, 512, message, 3);
    Format(buffer, 512, "</font>%s ", buffer);
    
    for(int i = strlen(buffer); i < 512; i++) buffer[i] = '\n';
    
    Protobuf pb = view_as<Protobuf>(StartMessageOne("TextMsg", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS));
    pb.SetInt("msg_dst", 4);
    pb.AddString("params", "#SFUI_ContractKillStart");
    pb.AddString("params", buffer);
    pb.AddString("params", NULL_STRING);
    pb.AddString("params", NULL_STRING);
    pb.AddString("params", NULL_STRING);
    pb.AddString("params", NULL_STRING);
    
    EndMessage();
}

methodmap Query < StringMap {
    public Query(char[] query) {
        StringMap smQuery = new StringMap();
        smQuery.SetString("query", query);
        smQuery.SetValue("checkpoints", INVALID_HANDLE);
        return view_as<Query>(smQuery);
    }

    public void GetQueryString(char[] query, int length) {
        this.GetString("query", query, length);
    }

    property bool Main {
        public get() {
            bool main; this.GetValue("main", main);
            return main;
        }

        public set(bool main) {
            this.SetValue("main", main);
        }
    }

    property int Attempt {
        public get() {
            int attempt; this.GetValue("attempt", attempt);
            return attempt;
        }

        public set(int attempt) {
            this.SetValue("attempt", attempt);
        }
    }

    property int Type {
        public get() {
            int type; this.GetValue("type", type);
            return type;
        }

        public set(int type) {
            this.SetValue("type", type);
        }
    }

    property int Style {
        public get() {
            int styleid; this.GetValue("styleid", styleid);
            return styleid;
        }

        public set(int styleid) {
            this.SetValue("styleid", styleid);
        }
    }

    property int Client {
        public get() {
            int userid; this.GetValue("userid", userid);
            return userid != 0 ? GetClientOfUserId(userid) : 0;
        }

        public set(int client) {
            this.SetValue("userid", client != 0 ? GetClientUserId(client) : 0);
        }
    }

    property int ZoneIndex {
        public get() {
            int zoneIndex; this.GetValue("zoneIndex", zoneIndex);
            return zoneIndex;
        }

        public set(int zoneIndex) {
            this.SetValue("zoneIndex", zoneIndex);
        }
    }

    property ArrayList Checkpoints {
        public get() {
            ArrayList checkpoints; this.GetValue("checkpoints", checkpoints);
            return checkpoints;
        }

        public set(ArrayList checkpoints) {
            this.SetValue("checkpoints", checkpoints);
        }
    }
}

methodmap Queries < ArrayList {
    public Queries() {
        return view_as<Queries>(new ArrayList());
    }

    public int GetQueryType(int index) {
        Query query = this.Get(index);
        return query.Type;
    }
}

methodmap Zones < ArrayList {
    public Zones() {
        return view_as<Zones>(new ArrayList(sizeof(Zone)));
    }

    public int GetTotalZoneGroups() {
        int totalZoneGroups;

        for (int i = 0; i < this.Length; i++) {
            Zone zone; this.GetArray(i, zone);
            if (zone.Group > totalZoneGroups) totalZoneGroups = zone.Group;
        }

        return totalZoneGroups;
    }

    public int FindByZoneId(int zoneId) {
        for (int i = 0; i < this.Length; i++) {
            Zone zone; this.GetArray(i, zone);
            if (zone.Id == zoneId) return i;
        }

        return -1;
    }

    public int FindSingleZone(int type, int group) {
        for (int i = 0; i < this.Length; i++) {
            Zone zone; this.GetArray(i, zone);
            if ((zone.Type == type) && (zone.Group == group)) return i;
        }

        return -1;
    }
}

methodmap Checkpoints < StringMap {
    public Checkpoints() {
        return view_as<Checkpoints>(new StringMap());
    }

    public void Initilize(int client, int style) {
        char[] clientChar = new char[8];
        char[] styleChar = new char[8];

        IntToString(client, clientChar, 8);
        IntToString(style, styleChar, 8);

        StringMap clients;
        if (!this.GetValue(clientChar, clients)) {
            clients = new StringMap();
            this.SetValue(clientChar, clients);
        }

        ArrayList styles;
        if (!clients.GetValue(styleChar, styles)) {
            styles = new ArrayList(sizeof(CheckpointData));
            clients.SetValue(styleChar, styles);
        }
    }

    public bool Exists(int client, int style) {
        char[] clientChar = new char[8];
        char[] styleChar = new char[8];

        IntToString(client, clientChar, 8);
        IntToString(style, styleChar, 8);

        StringMap clients;
        if (!this.GetValue(clientChar, clients)) return false;

        ArrayList styles;
        if (!this.GetValue(styleChar, styles)) return false;

        return true;
    }

    public void Trash() {
        char[] clientChar = new char[8];
        char[] styleChar = new char[8];
        StringMapSnapshot clientsSnapshot = this.Snapshot();

        for (int i = 0; i < clientsSnapshot.Length; i++) {
            clientsSnapshot.GetKey(i, clientChar, 8);

            StringMap clients; this.GetValue(clientChar, clients);
            StringMapSnapshot stylesSnapshot = clients.Snapshot();

            for (int x = 0; x < stylesSnapshot.Length; x++) {
                stylesSnapshot.GetKey(x, styleChar, 8);

                ArrayList styles; clients.GetValue(styleChar, styles);
                delete styles;
            }

            delete clients;
            delete stylesSnapshot;
        }

        delete clientsSnapshot;
        this.Clear();
    }

    public ArrayList Get(int client, int style) {
        char[] clientChar = new char[8];
        char[] styleChar = new char[8];

        IntToString(client, clientChar, 8);
        IntToString(style, styleChar, 8);

        StringMap clients; this.GetValue(clientChar, clients);
        ArrayList styles; clients.GetValue(styleChar, styles);
        return styles;
    }
}

methodmap Records < StringMap {
    public Records() {
        return view_as<Records>(new StringMap());
    }

    public void Initilize(int style, int group) {
        char[] styleChar = new char[8];
        char[] groupChar = new char[8];

        IntToString(style, styleChar, 8);
        IntToString(group, groupChar, 8);

        StringMap styles;
        if (!this.GetValue(styleChar, styles)) {
            styles = new StringMap();
            this.SetValue(styleChar, styles);
        }

        ArrayList groups;
        if (!styles.GetValue(groupChar, groups)) {
            groups = new ArrayList(sizeof(Record));
            styles.SetValue(groupChar, groups);
        }
    }

    public bool Exists(int style, int group) {
        char[] styleChar = new char[8];
        char[] groupChar = new char[8];

        IntToString(style, styleChar, 8);
        IntToString(group, groupChar, 8);

        StringMap styles;
        if (!this.GetValue(styleChar, styles)) return false;

        ArrayList groups;
        if (!styles.GetValue(groupChar, groups)) return false;

        return true;
    }

    public void Trash() {
        char[] styleChar = new char[8];
        char[] groupChar = new char[8];
        StringMapSnapshot stylesSnapshot = this.Snapshot();

        for (int i = 0; i < stylesSnapshot.Length; i++) {
            stylesSnapshot.GetKey(i, styleChar, 8);

            StringMap styles; this.GetValue(styleChar, styles);
            StringMapSnapshot groupsSnapshot = styles.Snapshot();

            for (int x = 0; x < groupsSnapshot.Length; x++) {
                groupsSnapshot.GetKey(x, groupChar, 8);

                ArrayList groups; styles.GetValue(groupChar, groups);
                delete groups;
            }
            
            delete styles;
            delete groupsSnapshot;
        }

        delete stylesSnapshot;
        this.Clear();
    }

    public ArrayList Get(int style, int group) {
        char[] styleChar = new char[8];
        char[] groupChar = new char[8];

        IntToString(style, styleChar, 8);
        IntToString(group, groupChar, 8);

        StringMap styles; this.GetValue(styleChar, styles);
        ArrayList groups; styles.GetValue(groupChar, groups);
        return groups;
    }
}