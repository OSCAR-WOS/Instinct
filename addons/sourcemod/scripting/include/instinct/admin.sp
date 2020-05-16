public Action Command_Admin(int client, int args) {
    Admin_MainMenu(client);
    return Plugin_Handled;
}

void Admin_MainMenu(int client) {
    Menu menu = new Menu(Menu_AdminMain);
    menu.Display(client, 0);
}

public int Menu_AdminMain(Menu menu, MenuAction action, int param1, int param2) {
    if (action == MenuAction_End) delete menu;
}