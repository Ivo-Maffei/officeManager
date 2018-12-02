//import dlangui;
import main; //here are UI function
import Local: Local;
import std.conv: to;
import std.stdio;

public import MenuBar;
/*
	Here we build the classes to handle actions and clicks
	THis allow the creation of UI to be separated from the Signal handlers
*/

//handle menu actions
class MyMenuActionHandler : MenuItemActionHandler {
	private Window* _window;
		
   	this ( Window * window) {
   		_window = window;
	}
    	
    override bool onMenuItemAction (const(Action) action) {
    	try {
    	switch( action.id) {
    			
    		case 11: //Logout
    			Local.logout();
				loginUI(*_window);
    			break;
    			
    		case 12: //user options
    			UserOptionsUI(*_window);
    			break;
    			
    		case 21:
    			Local.syncDatabase();
    			MenuBarInteraction.changeProjects();
    			break;
    			
    		case 22:
    			Local.syncProjects();
    			MenuBarInteraction.changeProjects();
    			break;
    			
    		case 23:
    			Local.syncCategories();
    			break;
    			
    		case 24:
    			Local.syncSessions();
    			break;
    			
    		case 25:
    			Local.syncUsers();
    			break;
    		
    		case 31: //database options
    			DBOptionsUI(*_window);
    			break;
    			
    		case 34: //menu bar options
    			menuBarUI(*_window);
    			break;
    			
    		default:
    		//nothing
    	} } catch (Exception e) {
    		error(e.msg, *_window);
    		return false;
    	}
    		
    	return true;
    }
    
}

//handle the attempt to login
class LoginClick : OnClickHandler {

	private {
		Window* _win;
		EditLine user, pass;
		CheckBox offline;
	}

	this (ref Window win, TableLayout t) {
		_win = &win;
		user = t.childById!EditLine("userLine");
		pass = t.childById!EditLine("passLine");
		offline = t.childById!CheckBox("offline");
		assert(user !is null && pass !is null && offline !is null);
	}

	override bool onClick( Widget src) {
		
		Local.offline = offline.checked;
		auto tuple = Local.login(to!string(user.text),to!string(pass.text));
		writeln("############# local login done");
		writeln("############## tuple : ", tuple);
		if(tuple[0] == false) {
			error(tuple[1], *_win);
			return false;
		}
		Local.initialise();
		
		normalUI(*_win);
		
		return true;
	}
	
}

//go back to normalUI
class BackClick : OnClickHandler {

	private Window  _win;
	
	this ( Window window) {
		_win = window;
	}
	
	override bool onClick(Widget src) {
		normalUI(_win);
		return true;
	}
}

//general UI creation
class NewUI(string s) : OnClickHandler {
	private Window* _win;
	
	this (ref Window win) {
		_win = &win;
	}
	override bool onClick( Widget src) {
		mixin(s~"(*_win);");
		return true;
	}
}

class StartStopSession : OnClickHandler {
	
	private {
		ulong sessionID = 0;
		ComboBox proj, cat;
		EditLine desc;
		StringGridWidget grid;
	}
	
	this (ComboBox p, ComboBox c, EditLine d,  ref StringGridWidget g) {	
		proj = p; //selected project 
		cat = c;
		grid = g;
		desc = d;
		
		string projName = to!string(proj.selectedItem);
		if( projName == "Any") return;
		
		auto ses = Local.getActiveSession(Local.getProjectId(projName));
		if(ses !is null) {
			sessionID = ses.ID;
		}
	}
	
	override bool onClick(Widget src) {	
		
		if(sessionID == 0 ) { //no active Session
			int row = grid.rows;
			grid.rows = grid.rows +1;
			grid.setRowTitle(row, to!dstring(row+1));
			auto projID = Local.getProjectId(to!string(proj.selectedItem));
			sessionID = Local.startSession(projID, to!string(desc.text), Local.getCategory(to!string(cat.selectedItem)));
			
			MenuBarInteraction.startSession(projID);
			
			auto description = Local.sessionDescription(sessionID);
			//aggiorna la tabella;
			grid.setCellText(0,row, to!dstring(description["dateTime"]));
			grid.setCellText(1,row, "contando"d);
			grid.setCellText(2,row,to!dstring(Local.getProject(projID).name));
			grid.setCellText(3,row,to!dstring(description["category"]));
			grid.setCellText(4,row,to!dstring(description["user"]));
			grid.setCellText(5,row,to!dstring(description["description"]));
			grid.setCellText(6,row,to!dstring(description["ID"]));
			
			(to!InactivityWidget(src.window.inactivity)).startTimer(sessionID);
			to!Button(src).text = "Stop Session"d;
		} else {
		
			Local.stopSession(sessionID);	
			scope (exit) {
				sessionID = 0;
			}		
			auto s = Local.sessionDescription(sessionID);
			MenuBarInteraction.stopSession(to!ulong(s["projectID"]));
			for(int row = 0; row < grid.rows; ++row) {
				if(to!ulong(grid.cellText(6,row)) == sessionID) {
					grid.setCellText(1,row, to!dstring(s["duration"]));
					break;
				}
			}
			to!Button(src).text = "Start Session"d;
			
		}
		
		grid.autoFit;

		return true;
	}	

}

class CreateProjectUI : NewUI!("newProjectUI") {
	this(ref Window win) {
		super(win);
	}
}

class CreateProject : OnClickHandler {
	
	private{
		EditLine _name, _job, _note;
		CheckBox _sync;
		Window* _win;
	}
	
	this (ref Window win, TableLayout t, const string nameId, const string jobId , const string syncId, const string noteId) {
		_name = (t.childById!EditLine(nameId));
		_job = (t.childById!EditLine(jobId));
		_sync = (t.childById!CheckBox(syncId));
		_note = (t.childById!EditLine(noteId));
		_win = &win;
	}
	override bool onClick( Widget src) {
		try{
		 	auto projID = Local.createProject(to!string(_name.text), to!ushort(_job.text),_sync.checked, to!string(_note.text));
		} catch (Exception e)  {
			string message = "error creating a project: " ~ e.msg;
			error(message, *_win);
			return false;
		}
	 	MenuBarInteraction.changeProjects();
	 	auto b = new BackClick(*_win);
	 	return b.onClick(src);
	}
}

class CreateSessionUI : OnClickHandler {
	private {
		Window* _win;
		string date, duration; //default date and duration
	}
	
	this (ref Window win, string dt = null, string dur = null) {
		_win = &win;
		date = dt;
		duration = dur;
	}
	override bool onClick( Widget src) {
		newSessionUI(*_win, date, duration);
		return true;
	}
}

class CreateSession : OnClickHandler {
	
	private {
		ComboBox proj, user, cat, day, month, year, hour, min, durataH, durataM;
		CheckBox tantum, tassabile;
		EditLine desc, costo;
		Window* _win;
	}
		
	this (ref Window win, TableLayout t) {
		_win = &win;
		proj = t.childById!ComboBox("projSelect");
		user = t.childById!ComboBox("users");
		cat = t.childById!ComboBox("categories");
		day = t.childById!ComboBox("day");
		month = t.childById!ComboBox("month");
		year = t.childById!ComboBox("year");
		hour = t.childById!ComboBox("hour");
		min = t.childById!ComboBox("min");
		durataH = t.childById!ComboBox("hour2");
		durataM = t.childById!ComboBox("min2");
		tantum = t.childById!CheckBox("tantum");
		tassabile = t.childById!CheckBox("tassabile");
		desc = t.childById!EditLine("desc");
		costo = t.childById!EditLine("costo");
	}
	override bool onClick( Widget src) {
		string date = to!string(year.selectedItem);
		date ~= "-"~to!string(month.selectedItem);
		date ~= "-"~to!string(day.selectedItem);
		date ~= "T"~to!string(hour.selectedItem);
		date ~= ":"~to!string(min.selectedItem)~":00";
		
	 	if(! tantum.checked) { //create Session
	 		ulong sessionID = Local.createSession(Local.getProjectId(to!string(proj.selectedItem)), date,to!string(user.selectedItem ), to!string(desc.text), Local.getCategory(to!string(cat.selectedItem)));
	 		string durata = to!string(durataH.selectedItem)~":"~to!string(durataM.selectedItem);
	 		Local.editSession(sessionID,to!string(user.selectedItem), 0, null, null, durata );
	 	} else  { //create Tantum
	 		Local.createTantum (Local.getProjectId(to!string(proj.selectedItem)), date,to!string(user.selectedItem ), to!ushort(costo.text), tassabile.checked, to!string(desc.text), Local.getCategory(to!string(cat.selectedItem)));
	 	}
	 	//after doing this go to previous page
	 	auto b = new BackClick(*_win);
	 	return b.onClick(src);
	}
}

class CreateCategoryUI: NewUI!("newCategoryUI")  {
	this(ref Window win) {
		super(win);
	}
}

class CreateCategory : OnClickHandler {
	
	private {
		EditLine name;
		ComboBox color;
		Window* _win;
	}
		
	this (ref Window win, TableLayout t) {
		_win = &win;
		name = t.childById!EditLine("nome");
		color = t.childById!ComboBox("color");
	}
	override bool onClick( Widget src) {
		
		Local.createCategory(to!string(name.text),0,0,to!string(color.selectedItem));
	 	auto b = new BackClick(*_win);
	 	return b.onClick(src);
	}
}

class UpdateGrid : OnClickHandler {
	import Sessions;
	
	private {
		ComboBox cat, proj, user;
		StringGridWidget grid;
		void updateGrid(const Session[] sessions ) {
			grid.rows = to!int(sessions.length);
			
			for(int i =0; i<sessions.length; ++i) {
				grid.setRowTitle(i, to!dstring(i+1));
				grid.setCellText(0,i, to!dstring(sessions[i].dateTime));
				grid.setCellText(1,i, to!dstring(sessions[i].duration));
				grid.setCellText(2,i, to!dstring(Local.getProject(sessions[i].projectID).name));
				grid.setCellText(3,i, to!dstring(sessions[i].category));
				grid.setCellText(4,i, to!dstring(sessions[i].user));
				grid.setCellText(5,i, to!dstring(sessions[i].description));
				grid.setCellText(6,i, to!dstring(sessions[i].ID));
			}
			
			grid.autoFit;
		}
	}
	
	this (  ComboBox p,  ComboBox c,  ComboBox u,  StringGridWidget g ) {
		cat = c;
		proj = p;
		user = u;
		grid = g;
	}
	
	override bool onClick( Widget src) {
		auto sessions = to!string(user.selectedItem) == Local.getCurrentUser ? Local.getUserSessions : Local.getSessions(to!string(user.selectedItem));
		const(Session)[] selected;
		ulong projID = proj.selectedItem == "Any" ? 0 : Local.getProjectId(to!string(proj.selectedItem));
		string catID = to!string(cat.selectedItem);
		foreach (ref s ; sessions) {
			if((projID == 0 || s.projectID == projID) && (catID == "Any" || s.category == catID) ) selected = selected ~ s;
		}
		
		updateGrid(selected);
		
		return true;
	}

}

//actions for gestione utenti screen
class UpdateUserInfo : OnItemSelectedHandler {

	private{
		TextWidget name,role;
	}
	
	this( TextWidget n, TextWidget r) {
		name = n;
		role = r;
	}

	override bool onItemSelected( Widget src, int itemIndex) {
	
		name.text = to!ComboBox(src).selectedItem;
		role.text = to!dstring(Local.getRole(to!string(name.text)));
	
		return true;
	}
}

class DeleteUser: OnClickHandler {
	
	private{
		TextWidget userName;
		Window win;
	}
	
	this( Window w, TextWidget u) {
		userName = u;
		win = w;
	}

	override bool onClick( Widget src) {
	
		win.showMessageBox("Eliminazione Utente"d, "Sei sicuro di voler cancellare l'utente: "d~userName.text~" e tutte le sue sessioni?"d, 
			[ACTION_OK, ACTION_NO], 0, delegate (const(Action) result) {
				if(result.id == 1){
					auto outcome = Local.deleteUser(to!string(userName.text));
					if(!outcome[0]) {
						error(outcome[1], win);
						return false;
					}
				}
				
				auto back = new BackClick(win);
				return back.onClick(src);
			});
		
		return true;
	}
	
}

class ChangePassword: OnClickHandler {

	private {
		EditLine pass;
		TextWidget user;
	}
	
	this( EditLine p, TextWidget u) {
		pass = p;
		user = u;
	}

	override bool onClick( Widget src) {
		if( to!string(user.text) == Local.getCurrentUser) {
			auto outcome = Local.changeOwnPassword(to!string(pass.text));
			if(!outcome[0]) {
				error(outcome[1], src.window);
				return false;
			}
		} else {
			auto outcome = Local.forgotPassword(to!string(user.text), to!string(pass.text));
			if(!outcome[0]) {
				error(outcome[1], src.window);
				return false;
			}
		}
		
		pass.text = "nuova password";
		return true;
	}
}

class ChangeRole : OnClickHandler {

	private {
		TextWidget user;
		ComboBox role;
		ComboBox userBox;
		UpdateUserInfo handler;
	}
	
	this( TextWidget u, ComboBox r, ComboBox ub, UpdateUserInfo h) {
		user = u;
		role = r;
		userBox = ub;
		handler = h;
	}
	
	override bool onClick(Widget src) {
		
		auto outcome = Local.changeRole(to!string(user.text), to!string(role.selectedItem));
		
		if(!outcome[0]) {
			error(outcome[1], src.window);
			return false;
		}
	
		return handler.onItemSelected(userBox,userBox.selectedItemIndex); //this will update info on screen
	}

}

class CreateUserUI: NewUI!("newUserUI")  {
	this(ref Window win) {
		super(win);
	}
}

class NewUser: OnClickHandler {

	private{
		EditLine user, password;
		ComboBox role;
		Window win;
	}
	
	this(Window w, EditLine u, EditLine p, ComboBox r) {
		user = u;
		password = p;
		role = r;
		win = w;
	}
	
	override bool onClick(Widget src) {
		auto outcome = Local.createUser(to!string(user.text), to!string(password.text), to!string(role.selectedItem));
		if(!outcome[0]) {
			error("failed to create user: " ~ outcome[1], src.window);
			return false;
		}
		
		auto back = new BackClick(win);
		return back.onClick(src);
	}
}

class DoneSettings : OnClickHandler {
	
	private {
		EditLine host;
	}

	this( EditLine h) {
		host = h;
	}
	
	override bool onClick (Widget src) {
		
		Local.setHost(to!string(host.text));
		
		return true;
	}
}

class EditSessionPopup : CellPopupMenuHandler {

	private Window* win;
	
	this( ref Window w) {
		win = &w;
	}

	override MenuItem getCellPopupMenu (GridWidgetBase g, int col, int row) {
		StringGridWidget grid = to!StringGridWidget(g);
	
		auto pop = new MenuItem( new Action(1,"Modifica Sessione"d));
		pop.menuItemClick = delegate (MenuItem item) {
			editSessionUI(*win, to!ulong(grid.cellText(6,row)));
			return true;
		};
		
		auto del = new MenuItem(new Action(2, "Elimina Sessione"d));
		del.menuItemClick = delegate( MenuItem item) {
			
			Local.deleteSession(to!ulong(grid.cellText(6,row)));
			//now remove row from grid
			for(int y = row+1; y<grid.rows; ++y) {
				for(int x = 0; x<7; ++x) {
					grid.setCellText(x,y-1, grid.cellText(x,y));
				}
			}
			grid.rows = grid.rows -1;
			return true;
		};
		
		auto container = new MenuItem();
		container.add(pop);
		container.add(del);
		
		if( Local.isActiveSession(to!ulong(grid.cellText(6,row)))) { //this is an active session
			pop.enabled = false;
			del.enabled = false;
		}
		return container;
	}
}

class EditSession : OnClickHandler {

	private {
		TableLayout t;
		Window* win;
		bool tantum;
		string oldUser;
	}
	
	this(ref Window w, TableLayout table, bool tan) {
		win = &w;
		t = table;
		tantum = tan;
		oldUser = to!string(t.childById!ComboBox("user").selectedItem);
	}
	
	override bool onClick(Widget src) {
		string date = to!string(t.childById!ComboBox("year").selectedItem);
		date ~= "-"~ to!string(t.childById!ComboBox("month").selectedItem);
		date ~= "-"~ to!string(t.childById!ComboBox("day").selectedItem);
		date ~= "T"~ to!string(t.childById!ComboBox("hour").selectedItem);
		date ~= ":"~ to!string(t.childById!ComboBox("min").selectedItem);
		date ~= ":01";
		
		if(!tantum) {
			string duration = to!string(t.childById!ComboBox("hour2").selectedItem);
			duration ~= ":"~ to!string(t.childById!ComboBox("min2").selectedItem);
			Local.editSession(to!ulong(t.childById!TextWidget("sessionID").text), oldUser, Local.getProjectId(to!string(t.childById!ComboBox("proj").selectedItem)) , to!string(t.childById!ComboBox("user").selectedItem), date, duration, to!string(t.childById!EditLine("desc").text), Local.getCategory(to!string(t.childById!ComboBox("cat").selectedItem)));
			Local.changeSessionPlace(to!ulong(t.childById!TextWidget("sessionID").text), oldUser, to!string(t.childById!EditLine("pos").text));
		} else {
			Local.editTantum(to!ulong(t.childById!TextWidget("sessionID").text), oldUser, t.childById!CheckBox("tax").checked, to!ushort(t.childById!EditLine("cost").text),Local.getProjectId(to!string(t.childById!ComboBox("proj").selectedItem)), to!string(t.childById!ComboBox("user").selectedItem),date, to!string(t.childById!EditLine("desc").text), Local.getCategory(to!string(t.childById!ComboBox("cat").selectedItem)));
		}
		
		auto back = new BackClick(*win);
		return back.onClick(src);
	}
}

class EditCategoryUI : NewUI!("editCategoryUI") {
	this(ref Window win) {
		super (win);
	}
}

class UpdateCategoryInfo : OnItemSelectedHandler {

	private{
		EditLine name;
		ComboBox color;
	}
	
	this( EditLine n, ComboBox c) {
		name = n;
		color = c;
	}

	override bool onItemSelected( Widget src, int itemIndex) {
	
		name.text = to!ComboBox(src).selectedItem;
		name.enabled = name.text != "None"d;
		auto items = color.items;
		for(int i =0; i< items.length; ++i) {
			if(to!string(items[i].value) == Local.getCategory(to!string(name.text)).color) {
				color.selectedItemIndex = i;
				break;
			}
		}
	
		return true;
	}
}

class EditCategory : OnClickHandler {

	private {
		Window win;
		EditLine nome;
		ComboBox color,cat;
	}
	
	this( ref Window w, EditLine n, ComboBox c, ComboBox col) {
		win = w;
		nome = n;
		color = col;
		cat = c;
	}
	
	override bool onClick(Widget src) {
	
		string name = cat.selectedItem == nome.text ? null : to!string(nome.text);
		Local.editCategory(to!string(cat.selectedItem), name, to!string(color.selectedItem));
	
		auto back = new BackClick(win);
		return back.onClick(src);
	}
}

class DeleteCategory : OnClickHandler {
	
	private {
		ComboBox cat;
		Window win;
	}
	
	this(ref Window w, ComboBox c) {
		win = w;
		cat = c;
	}
	
	override bool onClick(Widget src) {
		
		Local.deleteCategory(to!string(cat.selectedItem));
		
		auto back = new BackClick(win);
		return back.onClick(src);
	}

}

class EditProjectUI : NewUI!("editProjectUI") {
	this(ref Window win) {
		super (win);
	}
}

class UpdateProjectInfo : OnItemSelectedHandler{

	private {
		TableLayout t;
	}
	
	this(TableLayout tab) {
		t = tab;
	}

	override bool onItemSelected( Widget src, int itemIndex) {
	
		auto p =  Local.getProject(Local.getProjectId(to!string((to!ComboBox(src)).selectedItem)));
	
		t.childById!TextWidget("fullName").text = to!dstring(p.name());
		t.childById!EditLine("shortName").text = to!dstring(p.shortName());
		t.childById!EditLine("jobNumber").text = to!dstring(p.jobNumber());
		t.childById!CheckBox("sync").checked = p.sync();
		t.childById!EditLine("notes").text = to!dstring(p.note);
		
		return true;
	}
}

class UpdateProjectName : EditableContentChangeListener {

	private {
		TextWidget fullName;
		EditLine name, job; 
	}
	this(TextWidget fn, EditLine n, EditLine j) {
		fullName = fn;
		name = n;
		job = j;
	}
	override void onEditableContentChanged( EditableContent source ) {
		dstring s;
		switch(job.text.length) {
			case 0: 
				s = "[00000] - "d;
				break;
			case 1:
				s = "[0000"d ~ job.text ~"] - "d;
				break;
			case 2:
				s = "[000"d ~ job.text ~"] - "d;
				break;
			case 3:
				s = "[00"d ~ job.text ~"] - "d;
				break;
			case 4:
				s = "[0"d ~ job.text ~"] - "d;
				break;
			case 5:
				s = "["d ~ job.text ~"] - "d;
				break;
			default:
				s ="[errore] - "d;
		}
		s ~= name.text;
		
		fullName.text = s;
	}
}

class DeleteProject : OnClickHandler {
	
	private {
		ComboBox proj;
		Window win;
	}
	
	this(Window w, ComboBox p) {
		win = w;
		proj = p;
	}
	
	override bool onClick (Widget src) {
		
		win.showMessageBox("Eliminazione progetto"d, "Sei sicuro di voler eliminare il progetto "d ~ proj.selectedItem ~ " e tutte le sue sessioni?"d,
			[ACTION_OK, ACTION_NO ], 0, delegate (const(Action) result ) {
					if( result.id == 1 ) {
						Local.deleteProject(Local.getProjectId(to!string(proj.selectedItem)));
					}
					auto back = new BackClick(win);
					return back.onClick(src);
				});
		
		return true;
	}
}

class EditProject : OnClickHandler {

	private {
		TableLayout t;
		Window win;
	}
	
	this(ref Window w, TableLayout tab) {
		win = w;
		t = tab;
	}
	
	override bool onClick(Widget src) {
		
		Local.editProject(Local.getProjectId(to!string(t.childById!ComboBox("proj").selectedItem)), to!ushort(t.childById!EditLine("jobNumber").text), t.childById!CheckBox("sync").checked, to!string(t.childById!EditLine("shortName").text), to!string(t.childById!EditLine("notes").text));
		MenuBarInteraction.changeProjects();
		auto back = new BackClick(win);
		return back.onClick(src);
	}
	
}

class UpdateNormalUISelection : OnItemSelectedHandler {

	private{
		ComboBox proj, cat, user;
	}
	
	this( ComboBox p, ComboBox c, ComboBox u) {
		proj = p;
		cat = c;
		user = u;
	}

	override bool onItemSelected( Widget src, int itemIndex) {
		
		saveState(proj, cat, user);
		
		return true;
	}
}

class MenuBarSettings : OnClickHandler {

	private {
		CheckBox menuBar;
		EditLine myPort, port;
	
	}
	
	this( EditLine p1, EditLine p2, CheckBox cb) {
		myPort = p1;
		port = p2;
		menuBar = cb;
	}
	
	override bool onClick(Widget src) {
	
		import Utility: getCurrentPath;
		import std.file: readText, write;
		import std.json;
		
		if(menuBar.checked != MenuBarInteraction.isMenuBarRunning) {
			if(menuBar.checked) {
				MenuBarInteraction.start();
			} else {
				MenuBarInteraction.quit();
			}
		}
		
		
		//get settings file
		auto file =  getCurrentPath ~ "settings";
		auto json = parseJSON(readText(file));
		
		auto save = delegate() {
			json["menuBar"] = menuBar.checked;
			json["OMPort"] = to!ushort(myPort.text);
			json["menuBarPort"] = to!ushort(port.text);
			write(file, json.toPrettyString);
		};
		
		if(json["OMPort"].integer != to!long(myPort.text) || json["menuBarPort"].integer != to!long(port.text)) {//need to change ports
			MenuBarInteraction.quit();
			save();
			MenuBarInteraction.start();
		}
		
		save();
		
		auto back = new BackClick(src.window);
		return back.onClick(src);
	}

}

class ReportUI: NewUI!("reportUI")  {
	this(ref Window win) {
		super(win);
	}
	
}

class UpdateGroupSelection : OnItemSelectedHandler {

	private{
		ComboBox b;
		HorizontalLayout h;
	}
	
	this( ComboBox combo, HorizontalLayout hor) {
		b = combo;
		h = hor;
	}

	override bool onItemSelected( Widget src, int itemIndex) {
		ComboBox combo;
		if(h.childById("select") is null) {
			combo = new ComboBox("select");
			h.addChild(combo);
		} else combo = h.childById!ComboBox("select");
		
		switch(to!ComboBox(src).selectedItem) {
			case "Tutto"d:
				b.items = ["progetto"d, "utente"d, "categoria"d];
				h.removeChild("select");
				break;
			case "utente"d:
				b.items = ["progetto"d, "categoria"d];
				dstring[] items = [];
				for(int i=0; i< Local.getAllUsers().length; ++i) {
					items ~= to!dstring(Local.getAllUsers()[i]);
					if( Local.getCurrentUser == Local.getAllUsers()[i]) {
						combo.items = items;
						combo.selectedItemIndex = i;
					}
				}
				combo.items = items;
				break;
			case "progetto"d:
				b.items = [ "utente"d, "categoria"d];
				dstring[] items = [];
				foreach( ref p; Local.getProjects) {
					items ~= to!dstring(p.name);
				}
				combo.items = items;
				break;
			case "categoria"d:
				b.items = ["progetto"d, "utente"d];
				dstring[] items = [];
				foreach( ref c ; Local.getCategories) {
					items ~= to!dstring(c.name);
				}
				combo.items = items;
				break;
			default:
				error("ComboBox of UpdateGroupSelection has unexpected items", src.window);
				return false;
		}
	
		return true;
	}
}

class GraphGenerator : OnClickHandler {

	private {
		VerticalLayout v;
	}
	
	this(VerticalLayout ver) {
		 v = ver;
	}
	
	override bool onClick(Widget src) {
		import Sessions;
		const(Session)[] sessioni = [];
		
		bool cost = v.childById!CheckBox("cost").checked;
		
		switch(v.childById!ComboBox("what").selectedItem) {
			case "Tutto"d: 
				sessioni = Local.getAllSessions();
				break;
			case "utente"d:
				sessioni = Local.getSessions(to!string(v.childById!ComboBox("select").selectedItem));
				break;
			case "progetto"d:
				auto all = Local.getAllSessions();
				ulong p = Local.getProjectId(to!string(v.childById!ComboBox("select").selectedItem));
				foreach(ref s; all) {
					if( s.projectID == p ) sessioni ~= s;
				}
				break;
			case "categoria"d:
				auto all = Local.getAllSessions();
				foreach(ref s; all) {
					if(s.category == to!string(v.childById!ComboBox("select").selectedItem)) sessioni ~= s;
				}
				break;
			default:
				error("ComboBox `what` of GraphGenerator has unexpected items", src.window);
				return false;
		}
		
		
		uint[string] bars; //in minuti
		uint[string] costs; //in centesimi
		bool tantum = false;
		foreach(ref s ; sessioni) {
			
			Tantum t = cast(Tantum)(s);
			if( t !is null) {
				if(!cost) continue; //we don't care about these
			}
			string key = null;
			switch(v.childById!ComboBox("group").selectedItem) {
				case "progetto"d:
					key = Local.getProject(s.projectID).name;
					break;
				case "utente"d:
					key = s.user;
					break;
				case "categoria"d:
					key = s.category;
					break;
				default:
					error("ComboBox `group` of GraphGenerator has unexpected items", src.window);
					return false;
			}
			
			auto check = key in bars;
			if(!check) {
				bars[key] = 0;
				if(tantum && cost) costs[key] = 0;
			}
			if(t is null) {
				int min = to!uint(s.duration[0..2]) *60 + to!uint(s.duration[3..5]);
				bars[key] += min;
			} else { //then add costs
				costs[key] += t.cost();
			}
		
		}//end foreach
		
		//writeln("############################## bars: ", bars);
		//writeln("############################## costs: ", costs);
		//now the 2 associative array represents the bars
		auto h1 = v.childById!HorizontalLayout("timeL");
		SimpleBarChart time = null;
		StringGridWidget timeGrid = null;
		if(h1 is null) {
			h1 = new HorizontalLayout("timeL");
			h1.layoutWidth(FILL_PARENT);
			v.addChild(h1);
			time = new SimpleBarChart("time", "Conteggio Ore"d);
			h1.addChild(time);
			timeGrid = new StringGridWidget("timeGrid");
			h1.addChild(timeGrid);
		} else {
			time = h1.childById!SimpleBarChart("time");
			time.removeAllBars();
			timeGrid = h1.childById!StringGridWidget("timeGrid");
		}
		timeGrid.rows = 0;
		timeGrid.cols = 2;	
		timeGrid.setColTitle(1, "tempo"d);
		timeGrid.setColTitle(0,v.childById!ComboBox("group").selectedItem);
		
		auto h2 = v.childById!HorizontalLayout("costL");
		SimpleBarChart costo  = null;
		StringGridWidget costoGrid= null;
		if(cost) {
			if( h2 is null) {
				h2 = new HorizontalLayout("costL");
				h2.layoutWidth(FILL_PARENT);
				costo = new SimpleBarChart("costi", "Conteggio Costi"d);
				v.addChild(h2);
				h2.addChild(costo);
				costoGrid = new StringGridWidget("costoGrid");
				h2.addChild(costoGrid);
			} else {
				costo = h2.childById!SimpleBarChart("costi");
				costo.removeAllBars();
				costoGrid = h2.childById!StringGridWidget("costoGrid");
			}
			costoGrid.rows = 0;
			costoGrid.cols = 2;
			costoGrid.setColTitle(1,"costo"d);
			costoGrid.setColTitle(0,v.childById!ComboBox("group").selectedItem);
		} else {
			if(h2 !is null) v.removeChild(h2);
		}
		
		
		
		uint color = 10;
		foreach( key, value; bars) {
			time.addBar(value, color, to!dstring(key));
			timeGrid.rows = timeGrid.rows +1;
			timeGrid.setRowTitle(timeGrid.rows-1, to!dstring(timeGrid.rows));
			timeGrid.setCellText(0,timeGrid.rows-1, to!dstring(key));
			timeGrid.setCellText(1,timeGrid.rows-1, to!dstring(value/60)~"h"d ~ " " ~ to!dstring(value%60)~"min"d);
			color += 100;
		}
		timeGrid.autoFit;
		
		if(cost) {
			color = 10;
			foreach(key, value; costs) {
				costo.addBar(value, color, to!dstring(key));
				costoGrid.rows = costoGrid.rows +1;
				costoGrid.setRowTitle(costoGrid.rows-1, to!dstring(costoGrid.rows));
				costoGrid.setCellText(0,costoGrid.rows-1, to!dstring(key));
				costoGrid.setCellText(1,costoGrid.rows-1, to!dstring(value/100.0) ~"€"d);
				color += 100;
			}
			costoGrid.autoFit;
		}
	
		return true;
	}

}

class EnterLogin : OnKeyHandler {
	
	private{
		LoginClick login;
	}
	
	this (LoginClick l) {
		login = l;
	}

	override bool onKey( Widget src, KeyEvent ev) {
		
		if( ev.action == KeyAction.KeyUp && ev.keyCode == KeyCode.RETURN) {
			writeln("################ now pressing login");
			return login.onClick(src);
		}
		return false;
	}
}

//to use in order to display error messages
void error(const string message, Window win) {
	win.showMessageBox("Errore"d,"Il programma ha ricevuto un errore col sequente messaggio:\n"d~ to!dstring(message) );
}

//to use in normal UI to save the selection of the 3 dropdown menu;
void saveState( ComboBox proj,  ComboBox cat,  ComboBox user) {
	
	import std.file: write;
	import Utility: getCurrentPath;
	
	string file = getCurrentPath() ~ "state";
	
	string buffer = "{ \"project\" : \"" ~ to!string(proj.selectedItem) ~ "\",\n \"category\" : \""~ to!string(cat.selectedItem) ~"\",\n \"user\" : \"" ~ to!string(user.selectedItem) ~"\" }";
	
	write(file, buffer);
	
}

//to use inorder to load the selection of the 3 dropdown menus present in  normalUI
void loadState (ComboBox proj, ComboBox cat, ComboBox user) {

	import std.file: readText;
	import std.json;
	import Utility: getCurrentPath;

	string file = getCurrentPath() ~ "state";
	
	auto json = parseJSON(readText(file));
	int index;
	if(proj !is null ) {
		index = proj.items.indexOf(to!dstring(json["project"].str));
		proj.selectedItemIndex = index == -1 ? 0 : index;
	}
	if(cat !is null) {
		index = cat.items.indexOf(to!dstring(json["category"].str));
		cat.selectedItemIndex =  index == -1 ? 0 : index;
	}
	if(user !is null) {
		index = user.items.indexOf(to!dstring(json["user"].str));
		user.selectedItemIndex = index == -1 ? 0 : index;
	}
}

class InactivityWidget {
	import std.datetime.stopwatch: StopWatch, AutoStart;
	import std.stdio;
	import dlangui.dialogs.msgbox;
	
	private {
		uint timerLimit = 30000; //time in milliseconds
		Window win;
		StopWatch watch, timer;
		ulong sessionID;
		bool first = true;
		MessageBox msg = null;
		uint updateFactor = 2; //this will be used to update messageBox
		StringGridWidget grid = null;
		Button stopBtn;
	}
	
	this(Window w) {
		win = w;
		timer.stop();
		timer.reset();
		watch.stop();
		watch.reset();
		sessionID =0;
	}
	
	void onTimer( ushort time) {
		//writeln("#################################### onTimer");
		if(first)  {
			first = false;
			Local.pauseSession(sessionID);
			//Local.stopSession(sessionID);
			msg = new MessageBox(UIString.fromRaw("Inattività"d), UIString.fromRaw("Sei stato inattivo per 1 minuto. Cosa vuoi fare con questo tempo?"d), win,
				[new Action(1,"Crea nuova sessione"d), new Action(2,"Tieni questo tempo nella sessione ora attiva"d), new Action(3,"Ignora questo tempo"d)], 0,
				delegate(const(Action) result) {
					scope(exit) {
						msg = null; //destroy the messageBox
						first = true;
						updateFactor = 2;
						sessionID =0;
						//writeln("######################### resetting sessionID to 0");
						watch.stop();
						watch.reset();
					}
					
					switch(result.id) {
					
						case 1:
							stopBtn.simulateClick();
							
							import std.datetime.systime : SysTime, Clock;
							import core.time: dur;
							SysTime currentTime = Clock.currTime() - dur!"minutes"(time);
	
							ushort hours, minutes;
							minutes = time;
							hours = minutes /60;
							minutes %= 60;
							string duration = "";
							if(hours < 10) duration = "0";
							duration ~= to!string(hours)~ ":";
							if(minutes < 10) duration ~="0";
							duration ~= to!string(minutes);
							
							(new CreateSessionUI(win, currentTime.toISOExtString, duration)).onClick(new Widget());
							break;
						case 2:
							auto desc = Local.sessionDescription(sessionID);
							auto duration = desc["duration"];
							ushort minutes = to!ushort(time -1);//take away the minute before stopping the session
							ushort hours = minutes / 60;
							minutes = minutes % 60;
							
							hours += to!ushort(duration[0 .. 2]);
							minutes += to!ushort(duration[3 .. 5]);
							if(minutes >= 60) {
								minutes -= 60;
								++hours;
							}
							
							string newDuration;
							if(hours < 10) newDuration = "0"~ to!string(hours);
							else newDuration = to!string(hours); 
							newDuration ~= ":";
							if(minutes < 10) newDuration ~= "0" ~ to!string(minutes);
							else newDuration ~= to!string(minutes);
							Local.editSession(sessionID, Local.getCurrentUser,0, null,null, newDuration );
							
							/*//now update the grid
							if( grid !is null) {
								//writeln("################################ updating grid");
								//writeln("################################ grid.rows : ", grid.rows);
								grid.setCellText(1,grid.rows-1, to!dstring(newDuration));
							}*/
							
							//fall to case 3					
						case 3:
							Local.resumeSession(sessionID); //start the watch again
							break;
						default:
							throw new Exception("unknown action in reply to message box");
					}
					
					return true;
				});
			msg.show();
		} else {
			//writeln("################################### updating message");
			//writeln("################################# time elapsed : ", watch.peek.total!"minutes");
			msg.message = "Sei stato inattivo per "d ~ to!dstring(time)~ " minuti. Cosa vuoi fare con questo tempo?"d;
			//msg.show();
		}
		
		
	}
	
	
	void startTimer(ulong ses) {
		timer.stop();
		timer.reset();
		timer.start();
		sessionID = ses;
	}
	
	void update() {
		if(timer.peek.total!"msecs" >= timerLimit) { //if enough time elapsed;
			timer.stop();
			timer.reset();
			
			//now check idle time
			import Utility: getCurrentPath;
			import std.process: executeShell;
			import std.algorithm.searching: canFind;
			import std.file: readText;
			
			
			string program = getCurrentPath ~ "SystemIdleTime";
			string file = getCurrentPath ~ "SystemPause";
			
			for (ushort i =0; i < 10; ++i) {
				auto output = executeShell(program);
				if( !( canFind( output.output, "error") || output.status != 0 || canFind(readText(file), "nil")  )) {
					break;
				}
			}
			
			float time = 0.0;
			if(readText(file) != "nil")
				time = to!float(readText(file));
			
			if(time > 60) {
				onTimer(to!ushort(time / 60.0));
				watch.start();
			} else {
				timer.start();
			}
			
			writeln("############################### idle time : ", time);
		}
		
		if( watch.running && watch.peek.total!"msecs" >= updateFactor * timerLimit) {
			++updateFactor;
			onTimer(to!ushort(watch.peek.total!"minutes"));
		}
	}
	
	void setGrid ( StringGridWidget g) {
		grid = g;
	}
	
	void setButton( Button st) {
		stopBtn = st;
	}
	
}