void Admin_Menu(int client) {
    char[] buffer = new char[512];
    Menu menu = new Menu(Menu_Admin);

    FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, "menu_admin", client);
    menu.SetTitle(buffer);

    FormatEx(buffer, 512, "%T", "menu_zone", client);
    menu.AddItem("", buffer);

    menu.Display(client, 0);
}

public int Menu_Admin(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;

    if (action == MenuAction_Select) {
        switch (param2) {
            case 0: Admin_Zone(param1);
        }
    }
}

void Admin_Zone(int client) {
    Admin_ClearZone(client);

    char[] buffer = new char[512];
    Menu menu = new Menu(Menu_Zone);

    FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, "menu_zone", client);
    menu.SetTitle(buffer);

    FormatEx(buffer, 512, "%T", "menu_zoning_add", client);
    menu.AddItem("", buffer);

    FormatEx(buffer, 512, "%T", "menu_zoning_edit", client);
    menu.AddItem("", buffer, g_Zones.Length != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    FormatEx(buffer, 512, "%T", "menu_zoning_delete", client);
    menu.AddItem("", buffer, g_Zones.Length != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

    menu.ExitBackButton = true;
    menu.Display(client, 0);
}

public int Menu_Zone(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;
    if (action == MenuAction_Cancel && param2 == MenuCancel_ExitBack) Admin_Menu(param1);

    if (action == MenuAction_Select) {
        switch (param2) {
            case 0: Admin_Zoning(param1, AdminStage_Drawing);
            case 1: Admin_Editing(param1, AdminStage_Editing);
            case 2: Admin_Editing(param1, AdminStage_Deleting);
        }
    }
}

void Admin_Zoning(int client, int type) {
    g_Players[client].Admin.Stage = type;

    char[] buffer = new char[512];
    Menu menu = new Menu(Menu_Zoning);

    switch (g_Players[client].Admin.Stage) {
        case AdminStage_Drawing: {
            FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, g_Players[client].Admin.Zone.Id == 0 ? "menu_zoning_add" : "menu_zoning_edit", client);
            menu.SetTitle(buffer);

            FormatEx(buffer, 512, "%T", "menu_zoning_edit1", client);
            menu.AddItem("", buffer, g_Players[client].Admin.Zone.xPos[0] != 0.0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

            FormatEx(buffer, 512, "%T", "menu_zoning_edit2", client);
            menu.AddItem("", buffer, g_Players[client].Admin.Zone.yPos[0] != 0.0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

            menu.AddItem("", "", ITEMDRAW_SPACER);

            FormatEx(buffer, 512, "%T", g_Players[client].Admin.Zone.Id == 0 ? "menu_zoning_save" : "menu_zoning_update", client);
            menu.AddItem("", buffer, g_Players[client].Admin.Zone.xPos[0] != 0.0 && g_Players[client].Admin.Zone.yPos[0] != 0.0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        } case AdminStage_Edit1, AdminStage_Edit2: {
            FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, g_Players[client].Admin.Stage == AdminStage_Edit1 ? "menu_zoning_edit1" : "menu_zoning_edit2", client);
            menu.SetTitle(buffer);

            FormatEx(buffer, 512, "%T", "menu_zoning_editx", client);
            menu.AddItem("", buffer, g_Players[client].Admin.Option != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

            FormatEx(buffer, 512, "%T", "menu_zoning_edity", client);
            menu.AddItem("", buffer, g_Players[client].Admin.Option != 1 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

            FormatEx(buffer, 512, "%T", "menu_zoning_editz", client);
            menu.AddItem("", buffer, g_Players[client].Admin.Option != 2 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
        } case AdminStage_Saving: {
            FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, g_Players[client].Admin.Zone.Id == 0 ? "menu_zoning_save" : "menu_zoning_update", client);
            menu.SetTitle(buffer);

            FormatEx(buffer, 512, "%T", gC_ZoneType[g_Players[client].Admin.Zone.Type][0], client);
            menu.AddItem("", buffer);

            if (g_Players[client].Admin.Zone.Group == 0) FormatEx(buffer, 512, "%T", "menu_zonegroup_normal", client);
            else if (g_Players[client].Admin.Zone.Group > g_Zones.GetTotalZoneGroups()) FormatEx(buffer, 512, "%T", "menu_zonegroup_newbonus", client);
            else FormatEx(buffer, 512, "%T", "menu_zonegroup_bonus", client, g_Players[client].Admin.Zone.Group);
            menu.AddItem("", buffer);

            FormatEx(buffer, 512, "%T", g_Players[client].Admin.Zone.Hide ? "menu_zonehide_enabled" : "menu_zonehide_disabled", client);
            menu.AddItem("", buffer, g_Players[client].Admin.Zone.Type > ZoneType_End ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);

            menu.AddItem("", "", ITEMDRAW_SPACER);

            FormatEx(buffer, 512, "%T", "menu_zoning_updatespawn", client);
            menu.AddItem("", buffer);

            FormatEx(buffer, 512, "%T", g_Players[client].Admin.Zone.Id == 0 ? "menu_zoning_save" : "menu_zoning_update", client);
            menu.AddItem("", buffer);
        } case AdminStage_EditType: {
            FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, "menu_zonetype", client);
            menu.SetTitle(buffer);

            for (int i = 0; i < sizeof(gC_ZoneType); i++) {
                FormatEx(buffer, 512, "%T", gC_ZoneType[i][1], client);
                menu.AddItem("", buffer, i != g_Players[client].Admin.Zone.Type ? ITEMDRAW_DEFAULT: ITEMDRAW_DISABLED);
            }
        }
    }

    menu.ExitBackButton = true;
    menu.Display(client, 0);
}

public int Menu_Zoning(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;
    if (action == MenuAction_Cancel) {
        if (param2 == MenuCancel_ExitBack) {
            switch (g_Players[param1].Admin.Stage) {
                case AdminStage_Edit1, AdminStage_Edit2, AdminStage_Saving: Admin_Zoning(param1, AdminStage_Drawing);
                case AdminStage_EditType: Admin_Zoning(param1, AdminStage_Saving);
                case AdminStage_Drawing: {
                    g_Players[param1].Admin.Stage = AdminStage_None;

                    if (g_Players[param1].Admin.Zone.Id == 0) Admin_Zone(param1);
                    else Admin_Editing(param1, AdminStage_Editing);
                }
            }
        } else if (param2 != MenuCancel_Interrupted) g_Players[param1].Admin.Stage = AdminStage_None;
    }

    if (action == MenuAction_Select) {
        switch (g_Players[param1].Admin.Stage) {
            case AdminStage_Edit1, AdminStage_Edit2: g_Players[param1].Admin.Option = param2;
            case AdminStage_EditType: {
                g_Players[param1].Admin.Zone.Type = param2;
                g_Players[param1].Admin.Zone.Hide = false;
                g_Players[param1].Admin.Stage = AdminStage_Saving;
            } case AdminStage_Drawing: {
                switch (param2) {
                    case 0: g_Players[param1].Admin.Stage = AdminStage_Edit1;
                    case 1: g_Players[param1].Admin.Stage = AdminStage_Edit2;
                    case 3: g_Players[param1].Admin.Stage = AdminStage_Saving;
                }
            } case AdminStage_Saving: {
                switch (param2) {
                    case 0: g_Players[param1].Admin.Stage = AdminStage_EditType;
                    case 1: g_Players[param1].Admin.Zone.Group = (g_Players[param1].Admin.Zone.Group + 1) % (g_Zones.GetTotalZoneGroups() + 2);
                    case 2: g_Players[param1].Admin.Zone.Hide = !g_Players[param1].Admin.Zone.Hide;
                    case 4: {
                        float pos[3];
                        GetClientAbsOrigin(param1, pos);
                        
                        if (Timer_IsPointInsideBox(pos, g_Players[param1].Admin.Zone.xPos, g_Players[param1].Admin.Zone.yPos)) g_Players[param1].Admin.Zone.Pos = pos;
                        else Timer_PrintToChat(param1, "%t", true, "chat_point_not_in_box");
                    } case 5: {
                        //g_Players[param1].Admin.Zone.Server = Server;
                        g_Players[param1].Admin.Zone.Timestamp = GetTime();
                        g_Players[param1].Admin.Zone.Zoner = g_Players[param1].Id;
                        Zone_New(g_Players[param1].Admin.Zone);
                        Admin_ClearZone(param1); return;
                    }
                }
            }
        }

        Admin_Zoning(param1, g_Players[param1].Admin.Stage);
    }
}

void Admin_Editing(int client, int type, int display = 0) {
    g_Players[client].Admin.Stage = type;

    char[] buffer = new char[512];
    Menu menu = new Menu(Menu_Editing);

    FormatEx(buffer, 512, "%s%T\n ", MENU_PREFIX, g_Players[client].Admin.Stage == AdminStage_Editing ? "menu_zoning_edit" : "menu_zoning_delete", client);
    menu.SetTitle(buffer);

    for (int i = 0; i < g_Zones.Length; i++) {
        if ((i % 4) == 0) {
            FormatEx(buffer, 512, "%T", g_Players[client].Admin.Stage == AdminStage_Editing ? "menu_zoning_editzone" : "menu_zoning_deletezone", client);
            menu.AddItem("", buffer, g_Players[client].Admin.Zone.Id != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
            menu.AddItem("", "", ITEMDRAW_SPACER);
        }

        Zone zone; g_Zones.GetArray(i, zone);

        if (zone.Group == 0) FormatEx(buffer, 512, "%T", "zonegroup_normal", client);
        else FormatEx(buffer, 512, "%T", "zonegroup_bonus", client, zone.Group);

        Format(buffer, 512, "(#%i) %s - %T", zone.Id, buffer, gC_ZoneType[zone.Type][1], client);
        menu.AddItem("", buffer);
    }

    menu.ExitBackButton = true;
    menu.DisplayAt(client, (display / 6) * 6, 0);
}

public int Menu_Editing(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;
    if (action == MenuAction_Cancel) { 
        if (param2 == MenuCancel_ExitBack) Admin_Zone(param1);
    }

    if (action == MenuAction_Select) {
        if (param2 % 6 == 0) {
            if (g_Players[param1].Admin.Stage == AdminStage_Deleting) Admin_DeleteZone(param1);
            else Admin_Zoning(param1, AdminStage_Drawing);
        } else {
            int index = ((param2 / 6) * 4) + ((param2 % 6) - 2);
            g_Zones.GetArray(index, g_Players[param1].Admin.Zone);
            Zone_TeleportPlayer(param1, g_Players[param1].Admin.Zone.Pos);
            Admin_Editing(param1, g_Players[param1].Admin.Stage, param2);
        }
    }
}

void Admin_DeleteZone(int client) {
    char[] buffer = new char[512];
    Menu menu = new Menu(Menu_Delete);

    FormatEx(buffer, 512, "%s%T\n \n%T\n%T\n ", MENU_PREFIX, "menu_zoning_delete", client, "menu_zoning_delete_confirm1", client, "menu_zoning_delete_confirm2", client);
    menu.SetTitle(buffer);

    FormatEx(buffer, 512, "%T", "menu_yes", client);
    menu.AddItem("", buffer);

    menu.Display(client, 0);
}

public int Menu_Delete(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;

    if (action == MenuAction_Select) {
        Zone_DeleteZone(g_Players[param1].Admin.Zone.Id);
        Sql_DeleteZone(g_Players[param1].Admin.Zone.Id);
        Admin_ClearZone(param1);
        Zone_Reload();
    }
}

void Admin_Precise() {
    for (int i = 1; i <= MaxClients; i++) {
        if (!CheckPlayer(i, PLAYERCHECK_INGAME)) continue;
        if (g_Players[i].Admin.Stage == AdminStage_None) continue;

        if (g_Players[i].Admin.Zone.xPos[0] != 0.0 && g_Players[i].Admin.Zone.yPos[0] != 0.0) {
            if (g_Players[i].Admin.Zone.xPos[2] == g_Players[i].Admin.Zone.yPos[2]) g_Players[i].Admin.Zone.yPos[2] += BOX_BOUNDARY;
            Zone_DrawSprite(g_Players[i].Admin.Zone.xPos, 0, 0.5, false, i);
            Zone_DrawSprite(g_Players[i].Admin.Zone.yPos, 1, 0.5, false, i);
            Zone_DrawSprite(g_Players[i].Admin.Zone.Pos, 2, 1.0, false, i);
        }

        switch (g_Players[i].Admin.Stage) {
            case AdminStage_Edit1: Zone_DrawAdmin(i, g_Players[i].Admin.Zone.xPos);
            case AdminStage_Edit2: Zone_DrawAdmin(i, g_Players[i].Admin.Zone.yPos);
            case AdminStage_Drawing: {
                float pos[3];
                Zone_RayTrace(i, pos);
                Zone_DrawSprite(pos, 2, 0.1, false, i);

                if (g_Players[i].Admin.Zone.xPos[0] != 0.0 && g_Players[i].Admin.Zone.yPos[0] != 0.0) Zone_Draw(g_Players[i].Admin.Zone.xPos, g_Players[i].Admin.Zone.yPos, ZoneType_Admin2, TIMER_INTERVAL, false, i);
                else if (g_Players[i].Admin.Zone.xPos[0] != 0.0) {
                    if (pos[2] == g_Players[i].Admin.Zone.xPos[2]) pos[2] += BOX_BOUNDARY;
                    Zone_Draw(g_Players[i].Admin.Zone.xPos, pos, ZoneType_Admin, TIMER_INTERVAL, false, i);
                } else if (g_Players[i].Admin.Zone.yPos[0] != 0.0) {
                    if (pos[2] == g_Players[i].Admin.Zone.yPos[2]) pos[2] += BOX_BOUNDARY;
                    Zone_Draw(pos, g_Players[i].Admin.Zone.yPos, ZoneType_Admin, TIMER_INTERVAL, false, i);
                }
            } 
        }
    }
}

void Admin_Second() {
    for (int i = 1; i <= MaxClients; i++) {
        if (!CheckPlayer(i, PLAYERCHECK_INGAME)) continue;
        if (g_Players[i].Admin.Stage == AdminStage_None) continue;

        switch (g_Players[i].Admin.Stage) {
            case AdminStage_Saving, AdminStage_EditType: {
                if (g_Players[i].Admin.Zone.Hide) continue;
                int type = g_Players[i].Admin.Zone.Type;

                if (g_Players[i].Admin.Zone.Group > 0 && type <= ZoneType_Checkpoint) type = g_Players[i].Admin.Zone.Type + sizeof(gI_Colors) - 3;
                Zone_Draw(g_Players[i].Admin.Zone.xPos, g_Players[i].Admin.Zone.yPos, type, 1.0, false, i);
            }
        }
    }
}

void Admin_Run(int client, int buttons) {
    if (g_Players[client].Admin.Stage == AdminStage_None) return;
    if (!(buttons & IN_ATTACK || buttons & IN_ATTACK2)) return;

    switch (g_Players[client].Admin.Stage) {
        case AdminStage_Edit1: g_Players[client].Admin.Zone.xPos[g_Players[client].Admin.Option] += buttons & IN_ATTACK ? 0.1 : -0.1;
        case AdminStage_Edit2: g_Players[client].Admin.Zone.yPos[g_Players[client].Admin.Option] += buttons & IN_ATTACK ? 0.1 : -0.1;
        case AdminStage_Drawing: {
            if (buttons & IN_ATTACK) Zone_RayTrace(client, g_Players[client].Admin.Zone.xPos);
            else Zone_RayTrace(client, g_Players[client].Admin.Zone.yPos);

            if (g_Players[client].Admin.Zone.xPos[0] != 0.0 && g_Players[client].Admin.Zone.yPos[0] != 0.0) {
                for (int i = 0; i < 2; i++) g_Players[client].Admin.Zone.Pos[i] = (g_Players[client].Admin.Zone.xPos[i] + g_Players[client].Admin.Zone.yPos[i]) / 2;

                if (g_Players[client].Admin.Zone.xPos[2] < g_Players[client].Admin.Zone.yPos[2]) g_Players[client].Admin.Zone.Pos[2] = g_Players[client].Admin.Zone.xPos[2];
                else g_Players[client].Admin.Zone.Pos[2] = g_Players[client].Admin.Zone.yPos[2];
            }

            Admin_Zoning(client, g_Players[client].Admin.Stage);
        }
    }
}

void Admin_ClearZone(int client) {
    g_Players[client].Admin.Stage = AdminStage_None;
    g_Players[client].Admin.Zone.Id = 0;

    for (int i = 0; i < 3; i++) {
        g_Players[client].Admin.Zone.xPos[i] = 0.0;
        g_Players[client].Admin.Zone.yPos[i] = 0.0;
        g_Players[client].Admin.Zone.Pos[i] = 0.0;
    }
}