import Local: Local; //everything should be done via Local or GUI
import dlangui;
import UIActionHandlers;

mixin APP_ENTRY_POINT;

/// entry point for dlangui based application
extern (C) int UIAppMain(string[] args) {


    // create window
    Window window = Platform.instance.createWindow("Office Manager", null, WindowFlag.Resizable, 1000,1000);
    window.onClose(delegate () { //sync before closing
    	MenuBarInteraction.quit();
    	try Local.syncDatabase();
    	catch {}
    });
    
    loginUI(window); //create Login UI
    
    window.show();
    auto inactivity = new InactivityWidget(window);
    scope(exit) {
    	destroy(inactivity);
    	MenuBarInteraction.quit();
    }
    
    window.inactivity = inactivity;

 	MenuBarInteraction.setWindow(window);  
    
    //MenuBarInteraction.start();
    
    Platform.instance.onLoop = delegate () {
    	inactivity.update();
    	MenuBarInteraction.update();
    };
    
    
    // run message loop
    return Platform.instance.enterMessageLoop();
 
}

void loginUI(ref Window loginWindow) { //creates UI for login
	
	loginWindow.resizeWindow(Point(300,500));
	
	//main Layout
	auto tLayout = new TableLayout();
    tLayout.layoutWidth(FILL_PARENT);
    tLayout.colCount = 2;
    
    auto user = new EditLine("userLine");
    user.fontSize = 25;
    
    auto hLayout = new HorizontalLayout();
    auto password = new EditLine("passLine");
    password.passwordChar = '*'; //this will hide the content and show * instead of actual characters
    password.fontSize = 25;
    password.minWidth = 200;
    
    auto showBtn = new Button("showBtn", "Show/Hide"d);
    showBtn.click = delegate(Widget s) { //this is here because it's too small to be moved to UIActionHandlers
    	static bool hidden = true;
    	if( hidden)  password.passwordChar = 0;
    	else  password.passwordChar = '*';
    	hidden = !hidden;
    	return true;
    };
    showBtn.fontSize = 25;
    
    hLayout.addChildren([password,showBtn]);
	
    tLayout.addChild(new TextWidget(null,"Utente"d));
    tLayout.addChild(user);
    tLayout.addChild(new TextWidget(null,"password"d));
    tLayout.addChild(hLayout);
    tLayout.addChild(new TextWidget("d","Lavora Offline"d).fontSize(25));
    tLayout.addChild(new CheckBox("offline"));
    
    auto btn = new Button("loginbtn", "login"d);
    btn.click = new LoginClick(loginWindow, tLayout);
	btn.fontSize = 25;
    
    tLayout.addChild(btn);
    
    loginWindow.mainWidget(tLayout);
   
}

void normalUI(ref Window window) { //create UI for normal use

	window.resizeWindow(Point(1000,700));
	
	auto vLayout = new VerticalLayout("outside");
    vLayout.layoutHeight(FILL_PARENT);
    vLayout.layoutWidth(FILL_PARENT);
    
    //create menu on top------------------------------------------------------------------
    //create main buttons
    auto userItem = new MenuItem(new Action(1,"Users"d)); // a menu button
    auto DBItem = new MenuItem(new Action(2,"Database"d));
    auto SettingsItem = new MenuItem(new Action(3,"Settings"d));
    
    //add submenus to main buttons
    userItem.add(new MenuItem(new Action(11,"Logout"d)));
    userItem.add(new MenuItem(new Action(12,"Gestione utenti"d)));
    
	DBItem.add(new MenuItem(new Action(21,"Force sync All"d)));
	DBItem.add(new MenuItem(new Action(22,"Force sync Projects"d)));
	DBItem.add(new MenuItem(new Action(23,"Force sync Categories"d)));
	DBItem.add(new MenuItem(new Action(24,"Force sync Sessions"d)));
	DBItem.add(new MenuItem(new Action(25,"Force sync User/Roles Database"d)));
	
	SettingsItem.add(new MenuItem(new Action(31,"Database settings"d)));
	SettingsItem.add(new MenuItem(new Action(32,"Reports settings"d)));
	SettingsItem.add(new MenuItem(new Action(33,"User Interface settings"d)));
	SettingsItem.add(new MenuItem(new Action(34,"Menu Bar settings"d)));
	
    auto itemsContainer = new MenuItem();//item which will contain the menu buttons
    itemsContainer.add(userItem);
    itemsContainer.add(DBItem);
    itemsContainer.add(SettingsItem);
    auto mbar = new MainMenu(itemsContainer); //the menu bar which contains the mitem
    mbar.id="mbar";
    
    //------------------------------------------------------------------------------------
    
    
    //create status bar-------------------------------------------------------------------
    auto sbar = new StatusLine();
    sbar.id ="sbar";
    sbar.minHeight = 25;
  	auto sbarText = new TextWidget("sbarText", "status line prova"d);
  	sbarText.fontSize = 21;
  	sbar.addChild(sbarText);
  	//------------------------------------------------------------------------------------
  	
    //create btnlayout
    auto btnLayout = new HorizontalLayout("btnLayout");
    btnLayout.layoutHeight(WRAP_CONTENT);
    btnLayout.layoutWidth(FILL_PARENT);

    
    //create buttons----------------------------------------------------------------------
    auto playbtn = new Button("playbtn", "Start Session"d);
    playbtn.fontSize = 30;
    auto sessionbtn = new Button("sessionbtn", "New Session"d);
    sessionbtn.fontSize = 30;
    auto projbtn = new Button("projbtn", "New Project"d);
    projbtn.fontSize = 30;
    auto catbtn = new Button("catbtn", "New Category"d);
    catbtn.fontSize = 30;
    auto repobtn = new Button("repobtn", "Create Report"d);
    repobtn.fontSize = 30;
    //------------------------------------------------------------------------------------
    
    
    //add buttons to button layout
    btnLayout.addChildren([playbtn,sessionbtn,projbtn,catbtn,repobtn]);
    
    //create gridLayout
    auto gridLayout = new HorizontalLayout("gridLayout");
    gridLayout.layoutHeight(FILL_PARENT);
    gridLayout.layoutWidth(FILL_PARENT);
    
    //create vertical layout for dropdown menu
    auto dropLayout = new VerticalLayout("dropLayout");
    dropLayout.layoutHeight(FILL_PARENT);
    dropLayout.layoutWidth(WRAP_CONTENT);
   	dropLayout.padding = Rect(0,100,0,0);
    
    //create dropdown selection-----------------------------------------------------------
   	auto projbox = new ComboBox("projdd");
   	projbox.minHeight = 50;
   	projbox.minWidth= 200;
   	projbox.text ="select project";
   	dstring[] projList;
   	foreach(ref pr ; Local.getProjects()) {
   		projList ~= to!dstring(pr.name);
   	}
   	projbox.items = projList ~"Any"d;
   	
   	auto catbox = new ComboBox("catdd");
   	catbox.minHeight = 50;
   	catbox.minWidth= 200;
   	catbox.text = "select category";
   	dstring[] catList;
   	foreach(ref cat ; Local.getCategories()) {
   		catList ~= to!dstring(cat.name);
   	}
   	catbox.items = catList ~ "Any"d;
   	
   	auto userbox = new ComboBox("userdd");
   	userbox.minHeight = 50;
   	userbox.minWidth= 200;
   	userbox.text = "select user";
   	dstring[] userList;
   	 foreach(ref u ; Local.getAllUsers()) {
   		userList ~= to!dstring(u);
   	}
   	userbox.items = userList;// ~ "Any"d;
   	
   	//Set old selection
   	loadState(projbox,catbox,userbox);
   	
   	auto filterbtn = new Button("filterbtn", "Aggiorna tabella"d);
   	filterbtn.fontSize = 20;
   	
   	auto editProj = new Button("editProj", "Modifica progetto"d);
   	auto editCat = new Button("editCat", "Modifica categoria"d);
   	
   	//------------------------------------------------------------------------------------
   	
   	//add dropdown to layout
   	dropLayout.addChild(projbox);
   	dropLayout.addChild(catbox);
   	dropLayout.addChild(userbox);
   	dropLayout.addChild(filterbtn);
   	dropLayout.addChild(new VSpacer);
   	dropLayout.addChild(editProj);
   	dropLayout.addChild(editCat);
   	
   	//create grid-------------------------------------------------------------------------
   	auto grid = new StringGridWidget("grid");
   	grid.showRowHeaders = true;
   	grid.showColHeaders = true;
   	grid.resize(7,0);
   	grid.setColTitle(0,"data"d);
   	grid.setColTitle(1,"durata"d);
   	grid.setColTitle(2,"Progetto"d);
   	grid.setColTitle(3,"Categoria"d);
   	grid.setColTitle(4,"Utente"d);
   	grid.setColTitle(5,"descrizione"d);
   	grid.setColTitle(6,"ID");
   	
   	for(int i =0; i< grid.rows; ++i) {
   		grid.setRowTitle(i,to!dstring(i+1));
   	}
   	grid.fontSize = 30;
   	grid.autoFitColumnWidths();
   	grid.autoFitRowHeights();
   	//------------------------------------------------------------------------------------
   	
   	//CONNECT SIGNALS---------------------------------------------------------------------
   	playbtn.click =  new StartStopSession(projbox, catbox, grid);
   	projbtn.click = new CreateProjectUI(window);
   	sessionbtn.click = new CreateSessionUI(window);
   	catbtn.click = new CreateCategoryUI(window);
   	filterbtn.click = new UpdateGrid(projbox, catbox, userbox, grid);
   	editCat.click = new EditCategoryUI(window);
   	editProj.click = new EditProjectUI(window);
   	repobtn.click = new ReportUI(window);
   	
   	grid.cellPopupMenu = new EditSessionPopup(window);
   	
   	itemsContainer.menuItemAction = new MyMenuActionHandler(&window);
   	
   	auto saveStateHandler = new UpdateNormalUISelection(projbox, catbox, userbox);
   	projbox.itemClick = saveStateHandler;
   	catbox.itemClick = saveStateHandler;
   	userbox.itemClick = saveStateHandler;
   	
   	to!InactivityWidget(window.inactivity).setGrid(grid);
   	to!InactivityWidget(window.inactivity).setButton(playbtn);
   	//------------------------------------------------------------------------------------
   	
   	//add to gridLayout
   	gridLayout.addChild(dropLayout);
   	gridLayout.addChild(grid);
   	
   	//check active sessions
   	auto projName = to!string(projbox.selectedItem);
   	if(projName != "Any" && Local.getActiveSession(Local.getProjectId(projName)) !is null) { //there is an active session with this project
   		playbtn.text = "Stop Session"d;
   	}
    
    //add everything to external Layout
    vLayout.addChild(mbar);
    vLayout.addChild(sbar);
    vLayout.addChild(btnLayout);
    vLayout.addChild(gridLayout);
    
    //add layout to window
    window.mainWidget = (vLayout);
    
    //start menubar if needed
    import Utility: getCurrentPath;
	import std.file: readText;
	import std.json;
	
    auto file =  getCurrentPath ~ "settings";
	auto json = parseJSON(readText(file));
	if(json["menuBar"].type == JSON_TYPE.TRUE && !MenuBarInteraction.isMenuBarRunning) {
		MenuBarInteraction.start();
	}
}

void UserOptionsUI (ref Window window){

	window.resizeWindow(Point(500,500));

	auto table = new TableLayout("table");
	table.colCount = 2;
	table.layoutWidth(FILL_PARENT);
	
	auto comboUsers = new ComboBox("users");
	dstring[] items;
	foreach( ref s; Local.getAllUsers) {
		items ~= to!dstring(s);
	}
	comboUsers.items = items;
	comboUsers.text = "select user";
	
	table.addChild(comboUsers);
	
	loadState(null, null, comboUsers);
	
	auto newBtn = new Button("newUser", "Nuovo Utente"d);
	table.addChild(newBtn);
	
	auto userText = new TextWidget("userText", "nome utente"d);
	table.addChild(userText);
	
	auto hlayout = new HorizontalLayout();
	
	auto userName = new TextWidget("userName");
	userName.text = "utente di prova";
	
	auto deleteBtn = new Button("delteUser", "elimina utente"d);
	
	hlayout.addChildren([userName, deleteBtn ]);
	
	table.addChild(hlayout);
	
	auto roleText = new TextWidget("roleText", "ruolo"d);
	table.addChild(roleText);
	
	auto role = new TextWidget("role");
	role.text = "nessun ruolo";
	table.addChild(role);
	
	auto changePass = new Button("changePass", "cambia password"d);
	
	table.addChild(changePass);
	
	auto newPass = new EditLine("newPass");
	newPass.text ="nuova password";
	table.addChild(newPass);
	
	auto changeRole = new Button("changeRole", "cambia ruolo"d);
	table.addChild(changeRole);
	
	auto roleSelection = new ComboBox("roleSelection");
	items = [];
	foreach( ref s ; Local.getRoles()) {
		items ~= to!dstring(s);
	}
	roleSelection.items = items;
	roleSelection.text = "select role";
	table.addChild(roleSelection);
	
	auto done = new Button("done", "Fatto"d);
	table.addChild(done);
	done.click = new BackClick(window);
	
	//Connect all signals
	auto handler = new UpdateUserInfo(userName, role);
	comboUsers.itemClick = handler;
	deleteBtn.click = new DeleteUser(window, userName);
	changePass.click = new ChangePassword (newPass, userName);
	changeRole.click = new ChangeRole(userName, roleSelection, comboUsers, handler);
	newBtn.click = new CreateUserUI(window);
	
	//update ui fields to match selected user
	handler.onItemSelected(comboUsers, comboUsers.selectedItemIndex);
	
	window.mainWidget = table;
	
}

void newUserUI(ref Window window) {

	window.resizeWindow(Point(300,400));

	auto t = new TableLayout();
	t.colCount = 2;
	t.layoutWidth(FILL_PARENT);
	
	t.addChild(new TextWidget(null, "Nome utente"d));
	auto userName = new EditLine;
	userName.text = "user_name"d;
	t.addChild(userName);
	
	t.addChild(new TextWidget(null, "Password"d));
	auto password = new EditLine;
	password.text = "";
	t.addChild(password);
	
	t.addChild(new TextWidget(null, "Ruolo"d));
	auto role = new ComboBox;
	dstring[] items ;
	foreach( ref s ; Local.getRoles) {
		items ~= to!dstring(s);
	}
	role.items = items;
	
	t.addChild(role);
	
	auto done = new Button(null, "OK"d);
	t.addChild(done);
	
	auto annulla = new Button(null, "Annulla"d);
	t.addChild(annulla);
	
	annulla.click = new BackClick(window);
	done.click = new NewUser(window, userName, password, role);
	
	window.mainWidget = t;

}

void DBOptionsUI( ref Window window) {

	window.resizeWindow(Point(300,400));
	
	auto v = new VerticalLayout();
	v.layoutWidth(FILL_PARENT);
	
	auto h = new HorizontalLayout();
	h.layoutWidth(FILL_PARENT);
	h.layoutHeight(FILL_PARENT);
	v.addChild(h);
	
	h.addChild(new TextWidget("host", "host URL"d));
	h.addChild(new EditLine("hostEdit", to!dstring(Local.getHost)).minWidth(150));
	
	auto done = new Button("done", "OK"d);
	done.click = new DoneSettings(h.childById!EditLine("hostEdit"));
	
	auto back = new Button("annulla", "Annulla"d);
	back.click = new BackClick(window);
	
	v.addChild(new HorizontalLayout().addChildren([done, back]));
	
	window.mainWidget= v;

}

void newProjectUI ( ref Window window) {

	window.resizeWindow(Point(300,400));
	
	auto v = new VerticalLayout();
	
	v.layoutWidth(FILL_PARENT);
	
	auto title = new TextWidget("title", "Creazione nuovo progetto"d);
	v.addChild(title);
	
	auto t = new TableLayout();
	t.colCount = 2;
	t.layoutWidth(FILL_PARENT);
	v.addChild(t);
	
	t.addChild(new TextWidget("nT", "Nome"d));
	auto nameLine = new EditLine("name");
	nameLine.text ="Nome";
	nameLine.minWidth(150);
	t.addChild(nameLine);
	
	t.addChild(new TextWidget("jT", "Numero Lavoro"d));
	auto jobLine = new EditLine("job");
	jobLine.text="0";
	jobLine.minWidth(nameLine.width);
	t.addChild(jobLine);
	
	t.addChild(new TextWidget("sT", "sincronizza con Apple Calendar"d));
	auto comboSync = new CheckBox("sync");
	t.addChild(comboSync);
	
	t.addChild(new TextWidget("description", "Note"d));
	auto note = new EditLine("note");
	note.text="";
	t.addChild(note);
	
	auto done = new Button("done", "OK"d);
	t.addChild(done);
	done.click.connect( new CreateProject(window, t, "name", "job", "sync", "note"));
	
	auto annulla = new Button("annulla", "Annulla"d);
	annulla.click = new BackClick(window);
	t.addChild(annulla);
	
	window.mainWidget = v;

}

void newSessionUI ( ref Window window, string dateTime, string duration) {

	window.resizeWindow(Point(300,400));
	
	auto v = new VerticalLayout();
	
	v.layoutWidth(FILL_PARENT);
	
	auto title = new TextWidget("title", "Creazione nuova sessione"d);
	v.addChild(title);
	
	auto t = new TableLayout();
	t.colCount = 2;
	t.layoutWidth(FILL_PARENT);
	v.addChild(t);
	
	t.addChild(new TextWidget(null, "progetto"d));
	
	auto projSelect = new ComboBox("projSelect");
	dstring[] projects;
	auto projs = Local.getProjects;
	foreach(ref proj; projs) {
		projects ~= to!dstring(proj.name);
	}
	projSelect.items = projects;
	
	t.addChild(projSelect);
	
	t.addChild(new TextWidget(null, "data"d));
	
	auto h = new HorizontalLayout();
	auto day = new ComboBox("day");
	dstring[] days;
	for(int i =1; i< 32; ++i) {
		dstring s = to!dstring(i);
		if( s.length == 1) { //if too short pad
			s = "0"~s;
		}
		days ~= s;
	}
	day.items = days;
	h.addChild(day);
	
	auto month = new ComboBox("month");
	dstring[] months;
	for(int i=1; i<13 ; ++i) {
		dstring s = to!dstring(i);
		if( s.length == 1) { //if too short pad
			s = "0"~s;
		}
		months ~= s;
	}
	month.items = months;
	h.addChild(month);
	
	auto year = new ComboBox("year", ["2018"d,"2019"d, "2020"d, "2021"d]);
	year.selectedItemIndex =0;
	
	h.addChild(year);
	
	t.addChild(h);
	
	t.addChild(new TextWidget(null, "ora"d));
	auto h2 = new HorizontalLayout();
	auto hour = new ComboBox("hour");
	for (int i =13; i <24; ++i){
		months ~= to!dstring(i); 
	} //now months is 1 to 23
	hour.items = ["00"d] ~ months;
	h2.addChild(hour);
	
	auto min = new ComboBox("min");
	dstring[] minutes;
	for(int i=0; i<61; ++i) {
		dstring s = to!dstring(i);
		if( s.length == 1) { //if too short pad
			s = "0"~s;
		}
		minutes ~= s;
	}
	min.items = minutes;
	h2.addChild(min);
	
	t.addChild(h2);
	
	t.addChild(new TextWidget(null, "durata"d));
	
	auto h3 = new HorizontalLayout();
	auto hour2 = new ComboBox("hour2");
	hour2.items = ["00"d] ~ months;
	h3.addChild(hour2);
	
	auto min2 = new ComboBox("min2");
	min2.items = minutes;
	h3.addChild(min2);
	
	t.addChild(h3);
	
	t.addChild(new TextWidget(null, "utente"d));
	auto users = new ComboBox("users");
	auto usersList = Local.getAllUsers();
	dstring[] items;
	for(int i =0; i< usersList.length; ++i) {
		items ~= to!dstring(usersList[i]);
		if(usersList[i] == Local.getCurrentUser) {
			users.items = items;
			users.selectedItemIndex =i;
		}
	}
	users.items = items;
	t.addChild(users);
	
	t.addChild(new TextWidget(null,"descrizione"d));
	t.addChild(new EditLine("desc",""d));
	
	t.addChild(new TextWidget(null, "categoria"d));
	auto categories = new ComboBox("categories");
	auto cats = Local.getCategories;
	dstring[] category;
	foreach( ref cat; cats) {
		category ~= to!dstring(cat.name);
	}
	categories.items = category;
	
	t.addChild(categories);
	
	t.addChild(new TextWidget(null, "tantum"d));
	t.addChild(new CheckBox("tantum"));
	
	t.addChild(new TextWidget(null, "costo (in centesimi)"d));
	t.addChild(new EditLine("costo", "0"d));
	
	t.addChild(new TextWidget(null, "tassabile"d));
	t.addChild(new CheckBox("tassabile"));
	
	auto done = new Button("done", "OK"d);
	done.click = new CreateSession(window,t);
	t.addChild(done);
	
	auto annulla = new Button("annulla", "Annulla"d);
	annulla.click = new BackClick(window);
	t.addChild(annulla);
	
	loadState( projSelect, categories, users);
	
	if(dateTime !is null) {
		year.selectedItemIndex = to!int(dateTime[0 .. 4]) -2018;
		month.selectedItemIndex = to!int(dateTime[5 .. 7]) -1;
		day.selectedItemIndex = to!int(dateTime[8 .. 10]) -1;
		hour.selectedItemIndex = to!int(dateTime[11 .. 13]);
		min.selectedItemIndex = to!int(dateTime[14 .. 16]);
	}
	if(duration !is null) {
		hour2.selectedItemIndex = to!int(duration[0 .. 2]);
		min2.selectedItemIndex = to!int(duration[3 .. 5]);
	}
	
	
	window.mainWidget = v;

}

void newCategoryUI(ref Window window) {
	window.resizeWindow(Point(300,400));
	
	auto v = new VerticalLayout();
	v.layoutWidth (FILL_PARENT);
	
	v.addChild(new TextWidget(null, "Creazione nuova categoria"d));
	
	auto t = new TableLayout();
	t.colCount = 2;
	t.layoutWidth(FILL_PARENT);
	
	v.addChild(t);
	
	t.addChild(new TextWidget(null, "Nome"d));
	t.addChild(new EditLine("nome", "nuova categoria"));
	
	t.addChild(new TextWidget(null, "Colore"d));
	dstring[] colors;
	foreach( ref col; Local.getCategoriesColors()) {
		colors ~= to!dstring(col);
	}
	t.addChild(new ComboBox("color", colors));
	t.childById!ComboBox("color").selectedItemIndex = 0;
	
	auto done = new Button("done", "OK"d);
	t.addChild(done);
	done.click = new CreateCategory(window,t);
	
	auto annulla = new Button("annulla", "Annulla"d);
	annulla.click = new BackClick(window);
	t.addChild(annulla);

	window.mainWidget = v;
}

void editSessionUI (ref Window window, const ulong sessionID) {
	window.resizeWindow(Point(510,300));
	
	auto t = new TableLayout();
	t.colCount = 2;
	t.layoutWidth(FILL_PARENT);
	t.fontSize = 25;
	
	t.addChild(new TextWidget(null, "ID"d));
	t.addChild(new TextWidget("sessionID", to!dstring(sessionID)));
	
	t.addChild(new TextWidget(null, "Data e ora"d));
	
	auto h = new HorizontalLayout();
	auto day = new ComboBox("day");
	auto month = new ComboBox("month");
	auto year = new ComboBox("year");
	auto hour = new ComboBox("hour");
	auto min = new ComboBox("min");
	auto hour2 = new ComboBox("hour2");
	auto min2 = new ComboBox("min2");
	
	dstring[] items;
	for(int i=1; i<13; ++i) {
		dstring s = to!dstring(i);
		if( s.length < 2) s = "0"~s;
		items ~= s;
	} //now items is [01 .. 12]
	month.items = items;
	
	for(int i = 13; i<24; ++i) {
		items ~= to!dstring(i);
	} //now items is [01 .. 23]
	hour.items = "00"d ~ items;
	hour2.items = "00"d ~ items;
	
	for(int i = 24; i<32; ++i) {
		items ~= to!dstring(i);
	} //now items is [01 .. 31]
	day.items = items;
	
	for(int i = 32; i<60; ++i) {
		items ~= to!dstring(i);
	} //now items is [01 .. 59]
	min.items = "00"d ~items;
	min2.items = "00"d ~ items;
	
	year.items = ["2018"d, "2019"d, "2020"d, "2021"d];
	
	h.addChildren([day, month, year , new HSpacer(), new HSpacer(), hour, min ]);
	t.addChild(h);
	
	auto info = Local.sessionDescription(sessionID);
	string dateTime = info["dateTime"];
	year.selectedItemIndex = 2018 - to!int(dateTime[0 .. 4]);
	month.selectedItemIndex = to!int(dateTime[5 .. 7]) -1; //index starts at 0
	day.selectedItemIndex = to!int(dateTime[8 .. 10]) -1 ; //index starts at 0
	hour.selectedItemIndex = to!int(dateTime[11 .. 13]);
	min.selectedItemIndex = to!int(dateTime[14 .. 16]);
	
	if(info["tantum"] == "false") { //se non è una tantim
		h = new HorizontalLayout();
		dateTime = info["duration"];
		hour2.selectedItemIndex = to!int(dateTime[0 .. 2]);
		min2.selectedItemIndex = to!int(dateTime[3 .. 5]);
		h.addChildren([hour2,min2]);
		t.addChild(new TextWidget(null, "Durata"d));
		t.addChild(h);
	}
	
	t.addChild(new TextWidget(null, "Progetto"d));
	auto proj = new ComboBox("proj");
	items = [];
	for(int i =0; i< Local.getProjects().length; ++i) {
		items ~= to!dstring(Local.getProjects()[i].name);
		if( info["projectID"] == to!string(Local.getProjects()[i].ID)) {
			proj.items = items;
			proj.selectedItemIndex = i;
		}
	}
	proj.items = items;
	t.addChild(proj);
	
	t.addChild(new TextWidget(null, "Categoria"d));
	auto cat = new ComboBox("cat");
	items = [];
	for(int i=0; i< Local.getCategories().length; ++i) {
		items ~= to!dstring(Local.getCategories()[i].name);
		if( info["category"] == Local.getCategories()[i].name) {
			cat.items = items;
			cat.selectedItemIndex = i;
		}
	}
	cat.items = items;
	t.addChild(cat);
	
	t.addChild(new TextWidget(null, "Utente"d));
	auto user = new ComboBox("user");
	items = [];
	for(int i=0; i< Local.getAllUsers().length; ++i) {
		items ~= to!dstring(Local.getAllUsers()[i]);
		if( info["user"] == Local.getAllUsers()[i]) {
			user.items = items;
			user.selectedItemIndex = i;
		}
	}
	user.items = items;
	t.addChild(user);
	
	if( info["tantum"] == "true") {
		t.addChild(new TextWidget(null, "Costo (in centesimi)"d));
		auto cost = new EditLine("cost");
		cost.text = to!dstring(info["cost"]);
		t.addChild(cost);
		t.addChild(new TextWidget(null, "Tassabile"d));
		auto tax = new CheckBox("tax");
		tax.checked = info["taxable"] == "true";
		t.addChild(tax);
	}
	
	t.addChild(new TextWidget(null, "Posizione"d));
	t.addChild(new EditLine("pos", to!dstring(info["place"])));
	
	t.addChild(new TextWidget(null, "Descrizione"d));
	t.addChild(new EditLine("desc", to!dstring(info[ "description"])));
	auto done = new Button(null,"Applica"d);
	t.addChild(done);
	bool tan = info["tantum"] == "true";
	done.click = new EditSession(window, t, tan );
	
	auto annulla = new Button(null, "Annulla"d);
	annulla.click = new BackClick(window);
	
	t.addChild(annulla);
	
	window.mainWidget = t;

}

void editCategoryUI (ref Window window) {
	
	window.resizeWindow(Point(300,500));
	
	auto v = new VerticalLayout();
	v.layoutWidth(FILL_PARENT);
	
	auto t = new TableLayout();
	t.colCount = 2;
	t.layoutWidth(FILL_PARENT);
	v.addChild(t);
	
	t.addChild(new TextWidget(null, "Categoria"d));
	auto cat = new ComboBox;
	dstring[] items ;
	foreach(ref c; Local.getCategories()) {
		items ~= to!dstring(c.name);
	}
	cat.items = items;
	t.addChild(cat);

	loadState(null, cat, null);
	
	t.addChild(new TextWidget(null, "Nome"d));
	auto nome = new EditLine(null, cat.selectedItem);
	if(nome.text == "None"d) nome.enabled = false;
	t.addChild(nome);
	
	t.addChild(new TextWidget(null, "Colore"d));
	auto col = new ComboBox;
	items = [];
	for(int i =0; i< Local.getCategoriesColors().length; ++i){
		items ~= to!dstring(Local.getCategoriesColors()[i]);
		if(Local.getCategory(to!string(nome.text) ).color == Local.getCategoriesColors()[i] ) {
			col.items = items;
			col.selectedItemIndex = i;
		}
	}
	col.items = items;
	t.addChild(col);
	
	auto h = new HorizontalLayout();
	h.layoutWidth(FILL_PARENT);
	
	auto done = new Button(null,"OK"d);
	done.click = new EditCategory(window, nome, cat, col);
	h.addChild(done);
	
	auto cancella = new Button(null, "Cancella Categoria"d);
	h.addChild(cancella);
	cancella.click = new DeleteCategory(window, cat);
	
	auto annulla = new Button(null, "Annulla"d);
	annulla.click = new BackClick(window);
	h.addChild(annulla);
	
	v.addChild(h);
	
	cat.itemClick = new UpdateCategoryInfo(nome,col);
	
	window.mainWidget = v;

}

void editProjectUI (ref Window window) {

	window.resizeWindow(Point(300,500));
	
	auto v = new VerticalLayout();
	v.layoutWidth(FILL_PARENT);
	
	auto t = new TableLayout();
	v.addChild(t);
	t.colCount = 2;
	t.layoutWidth(FILL_PARENT);
	
	t.addChild(new TextWidget(null, "Progetto"d));
	auto proj = new ComboBox("proj");
	dstring[] items;
	foreach(ref p; Local.getProjects()){
		items ~= to!dstring(p.name);
	}
	proj.items = items;
	t.addChild(proj);
	
	loadState(proj, null, null);
	
	auto p =  Local.getProject(Local.getProjectId(to!string(proj.selectedItem)));
	
	t.addChild(new TextWidget(null, "Nome completo"d));
	t.addChild(new TextWidget("fullName", proj.selectedItem));
	
	t.addChild(new TextWidget(null, "Nome"d));
	t.addChild(new EditLine("shortName", to!dstring(p.shortName()) )  );
	
	t.addChild(new TextWidget(null, "Codice di lavoro"d));
	t.addChild(new EditLine("jobNumber", to!dstring(p.jobNumber())  )  );
	
	t.addChild(new TextWidget(null,"Sincronizza con Apple Calendar"d));
	auto sync = new CheckBox("sync");
	sync.checked = p.sync;
	t.addChild(sync);
	
	t.addChild(new TextWidget(null, "Note"d));
	t.addChild(new EditLine("notes", to!dstring(p.note)));
	
	auto h = new HorizontalLayout();
	h.layoutWidth(FILL_PARENT);
	
	auto done = new Button(null, "OK"d);
	done.click = new EditProject(window, t);
	
	auto cancella = new Button(null, "Cancella Progetto"d);
	cancella.click = new DeleteProject(window, proj);
	
	auto back = new Button(null, "Annulla"d);
	back.click = new BackClick(window);
	
	proj.itemClick = new UpdateProjectInfo(t);
	auto updater = new UpdateProjectName(t.childById!TextWidget("fullName"), t.childById!EditLine("shortName"), t.childById!EditLine("jobNumber"));
	t.childById!EditLine("shortName").contentChange = updater;
	t.childById!EditLine("jobNumber").contentChange = updater;
	
	h.addChildren([done,cancella, back]);
	
	v.addChild(h);
	
	window.mainWidget = v;
	
}

void menuBarUI ( ref Window window){	
	
	window.resizeWindow(Point(300,500));

	auto t = new TableLayout();
	t.layoutWidth(FILL_PARENT);
	t.colCount = 2;
	
	t.addChild(new TextWidget(null, "Mostra Office Manager nella barra dei menu"d));
	auto menuBar = new CheckBox();
	menuBar.checked = MenuBarInteraction.isMenuBarRunning;
	t.addChild(menuBar);
	
	t.addChild(new TextWidget(null, "Porte IP che Office Manager può utilizzare"d));
	auto menuBarPort = new EditLine();
	menuBarPort.layoutWidth(FILL_PARENT);
	
	auto officeManagerPort = new EditLine();
	officeManagerPort.layoutWidth(FILL_PARENT);
	
	auto h = new HorizontalLayout();
	h.layoutWidth(FILL_PARENT);
	h.addChildren([menuBarPort, officeManagerPort]);
	t.addChild(h);
	
	auto done = new Button(null, "OK"d);
	done.click = new MenuBarSettings(officeManagerPort, menuBarPort, menuBar);
	t.addChild(done);
	
	auto annulla = new Button(null, "Annulla"d);
	annulla.click = new BackClick(window);
	t.addChild(annulla);
	
	t.fontSize = 25;
	
	import Utility: getCurrentPath;
	import std.json;
	import std.file: readText;
	
	auto file = getCurrentPath() ~ "settings";
	auto json = parseJSON(readText(file));
	menuBarPort.text = to!dstring(json["menuBarPort"].integer);
	officeManagerPort.text = to!dstring(json["OMPort"].integer);
	
	window.mainWidget = t;
}

void reportUI (ref Window window) {

	window.resizeWindow(Point(700,600));
	
	auto t = new TableLayout();
	t.colCount = 2;
	t.layoutWidth(FILL_PARENT);
	
	t.addChild(new TextWidget(null, "Analizza"d));
	auto h = new HorizontalLayout();
	h.layoutWidth(FILL_PARENT);
	
	auto combo = new ComboBox("what");
	combo.items = ["Tutto"d, "utente"d, "progetto"d, "categoria"d];
	h.addChild(combo);
	t.addChild(h);
	
	
	t.addChild(new TextWidget(null, "Dividi per"d));
	auto group = new ComboBox("group");
	group.items = ["progetto"d, "utente"d, "categoria"d];
	t.addChild(group);
	
	t.addChild(new TextWidget(null, "Calcola anche i costi"d));
	t.addChild(new CheckBox("cost"));
	
	auto v = new VerticalLayout();
	v.layoutWidth(FILL_PARENT);
	
	v.addChild(t);
	
	auto calcola = new Button(null, "Calcola"d);
	v.addChild(calcola);
	calcola.click = new GraphGenerator(v);
	
	auto annulla = new Button(null, "Annulla"d);
	v.addChild(annulla);
	annulla.click = new BackClick(window);
	
	combo.itemClick = new UpdateGroupSelection(group, h);
	
	window.mainWidget = v;

}

