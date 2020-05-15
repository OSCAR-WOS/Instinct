#include <sourcemod>

void Zone_Reload() {
    Zone_ClearEntities();
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

void Zone_New(Zone zone) {
    
}