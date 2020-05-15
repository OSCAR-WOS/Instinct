#define PLAYERCHECK_AUTHORIZED (1<<0)
#define PLAYERCHECK_VALID (1<<1)
#define PLAYERCHECK_INGAME (1<<2)
#define PLAYERCHECK_ALIVE (1<<3)

enum {
    ZoneType_Start,
    ZoneType_End,
    ZoneType_Checkpoint,
    ZoneType_Pvp
}

enum {
    QueryType_CreateTable = 0,
    QueryType_SelectClient,
    QueryType_InsertClient,
    QueryType_SelectZones,
    QueryType_InsertZone,
    QueryType_UpdateZone,
    QueryType_DeleteZone
}

enum struct Models {
    int Start;
    int End;
    int Checkpoint;
    int Pvp;
    int Laser;
    int Glow;
}

enum struct Zone {
    int Id;
    int Zoner;
    int Timestamp;
    int Type;
    int Group;
    int Server;

    float xPos[3];
    float yPos[3];
    float Pos[3];
}

enum struct Player {
    int Id;
}

methodmap Query < StringMap {
    public Query(char[] query) {
        StringMap smQuery = new StringMap();
        smQuery.SetString("query", query);
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

    property int Client {
        public get() {
            int userid; this.GetValue("userid", userid);
            return GetClientOfUserId(userid);
        }

        public set(int client) {
            this.SetValue("userid", GetClientUserId(client));
        }
    }

    property int Zone {
        public get() {
            int zoneIndex; this.GetValue("zoneIndex", zoneIndex);
            return zoneIndex;
        }

        public set(int zoneIndex) {
            this.SetValue("zoneIndex", zoneIndex);
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
}

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