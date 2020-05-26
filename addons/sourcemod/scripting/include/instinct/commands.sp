public Action Command_Admin(int client, int args) {
    Admin_Menu(client);
    return Plugin_Handled;
}

public Action Command_Restart(int client, int args) {
    if (IsPlayerAlive(client)) Zone_TeleportToStart(client, g_Players[client].Record.Group);
    else CS_RespawnPlayer(client);
    
    return Plugin_Handled;
}

public Action Command_Style(int client, int args) {
    char[] arg = new char[64]; 
    char[][] splitArg = new char[2][64];
    char[][] explodedString = new char[64][512];
    GetCmdArg(0, arg, 64);
    ExplodeString(arg, "_", splitArg, 2, 64);

    TrimString(splitArg[1]);
    int styleIndex = -1;

    for (int i = 0; i < g_Styles.Length; i++) {
        int explode = 0;
        Style style; g_Styles.GetArray(i, style);
        ExplodeString(style.Aliases, ", ", explodedString, 64, 512);
        while(strlen(explodedString[explode]) > 0) {
            TrimString(explodedString[explode]);

            if (StrEqual(splitArg[1], explodedString[explode], false)) styleIndex = i;
            explode++;
        }
    }

    if (styleIndex != -1) {
        g_Styles.GetArray(styleIndex, g_Players[client].Style);
        Timer_PrintToChat(client, "%t", true, "chat_style_found", g_Players[client].Style.Name, g_Players[client].Style.Prefix);
        Zone_TeleportToStart(client, 0);
    }

    return Plugin_Handled;
}

public Action Command_Settings(int client, int args) {
    Menu_Settings(client);
    return Plugin_Handled;
}

void Menu_Settings(int client) {
    char[] buffer = new char[512];
    Menu menu = new Menu(Menu_SettingsCallback);

    FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, "menu_settings", client);
    menu.SetTitle(buffer);

    for (int i = 0; i < sizeof(gC_Settings); i++) {
        FormatEx(buffer, 512, "%T", gC_Settings[i], client);
        menu.AddItem("", buffer);
    }

    menu.Display(client, 0);
}

void Menu_SettingsSelected(int client, int setting) {
    char[] buffer = new char[512];
    char[] settingChar = new char[8];
    Menu menu = new Menu(Menu_SettingsSelectedCallback);

    FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, gC_Settings[setting], client);
    menu.SetTitle(buffer);

    switch (setting) {
        case Setting_Checkpoint: {
            for (int i = 0; i < sizeof(gC_CheckpointSettings); i++) {
                FormatEx(buffer, 512, "%T", gC_CheckpointSettings[i][0], client);
                IntToString(setting, settingChar, 8);
                menu.AddItem(settingChar, buffer);
            }
        }
    }
    
    menu.ExitBackButton = true;
    menu.Display(client, 0);
}

void Menu_SettingsChangeCheckpoint(int client, int option) {
    char[] buffer = new char[512];
    char[] optionChar = new char[8];
    Menu menu = new Menu(Menu_SettingsChangeCheckpointCallback);

    FormatEx(buffer, 512, "%s%T\n \n%T\n ", MENU_PREFIX, gC_CheckpointSettings[option][0], client, gC_CheckpointSettings[option][2], client);
    menu.SetTitle(buffer);

    IntToString(option, optionChar, 8);

    FormatEx(buffer, 512, "%T", "menu_enabled", client);

    switch (option) {
        case 0: menu.AddItem(optionChar, buffer, g_Players[client].Settings.Checkpoints.NoRank ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        case 1: menu.AddItem(optionChar, buffer, g_Players[client].Settings.Checkpoints.NoDiff ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        case 2: menu.AddItem(optionChar, buffer, g_Players[client].Settings.Checkpoints.NoPb ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        case 3: menu.AddItem(optionChar, buffer, g_Players[client].Settings.Checkpoints.NoGb ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    }

    FormatEx(buffer, 512, "%T", "menu_disabled", client);

    switch (option) {
        case 0: menu.AddItem(optionChar, buffer, !g_Players[client].Settings.Checkpoints.NoRank ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        case 1: menu.AddItem(optionChar, buffer, !g_Players[client].Settings.Checkpoints.NoDiff ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        case 2: menu.AddItem(optionChar, buffer, !g_Players[client].Settings.Checkpoints.NoPb ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        case 3: menu.AddItem(optionChar, buffer, !g_Players[client].Settings.Checkpoints.NoGb ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
    }

    menu.ExitBackButton = true;
    menu.Display(client, 0);
}

int Menu_SettingsCallback(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;
    if (action == MenuAction_Select) Menu_SettingsSelected(param1, param2);
}

int Menu_SettingsSelectedCallback(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;
    if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) Menu_Settings(param1);
    if (action == MenuAction_Select) {
        char[] settingChar = new char[8];
        menu.GetItem(param2, settingChar, 8);

        switch (StringToInt(settingChar)) {
            case Setting_Checkpoint: Menu_SettingsChangeCheckpoint(param1, param2);
        }
    }
}

int Menu_SettingsChangeCheckpointCallback(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;
    if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) Menu_SettingsSelected(param1, Setting_Checkpoint);
    if (action == MenuAction_Select) {
        char[] optionChar = new char[8];
        menu.GetItem(param2, optionChar, 8);
        int option = StringToInt(optionChar);

        switch (option) {
            case 0: g_Players[param1].Settings.Checkpoints.NoRank = !g_Players[param1].Settings.Checkpoints.NoRank;
            case 1: g_Players[param1].Settings.Checkpoints.NoDiff = !g_Players[param1].Settings.Checkpoints.NoDiff;
            case 2: g_Players[param1].Settings.Checkpoints.NoPb = !g_Players[param1].Settings.Checkpoints.NoPb;
            case 3: g_Players[param1].Settings.Checkpoints.NoGb = !g_Players[param1].Settings.Checkpoints.NoGb;
        }

        Menu_SettingsChangeCheckpoint(param1, option);
    }
}