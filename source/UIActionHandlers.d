import dlangui;
import main; //here are UI function
import Local: Local;
import std.conv: to;

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
    			break;
    			
    		case 22:
    			Local.syncProjects();
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
    		default:
				//nothing
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
		import std.stdio;
		auto tuple = Local.login(to!string(user.text),to!string(pass.text));
		if(tuple[0] == false) {
			writeln(tuple);
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
		StringGridWidget grid;
		int row;
	}
	
	this (ComboBox p, ComboBox c,  ref StringGridWidget g) {	
		proj = p; //selected project 
		cat = c;
		grid = g;
	}
	
	override bool onClick(Widget src) {	
		
		if(sessionID == 0 ) { //no active Session
			row = grid.rows;
			grid.rows = grid.rows +1;
			grid.setRowTitle(row, to!dstring(row+1));
			auto projID = Local.getProjectId(to!string(proj.selectedItem));
			sessionID = Local.startSession(projID, "", Local.getCategory(to!string(cat.selectedItem)));
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
			auto s = Local.sessionDescription(sessionID);
			sessionID = 0;
			grid.setCellText(1,row, to!dstring(s["duration"]));
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
	 	auto projID = Local.createProject(to!string(_name.text), to!ushort(_job.text),_sync.checked, to!string(_note.text));
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
	 		Local.editSession(sessionID, 0, null, null, durata );
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
						throw new Exception(outcome[1]);
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
				throw new Exception( outcome[1]);
			}
		} else {
			auto outcome = Local.forgotPassword(to!string(user.text), to!string(pass.text));
			if(!outcome[0]) {
				throw new Exception( outcome[1]);
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
			throw new Exception(outcome[1]);
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
			throw new Exception(" failed to create user " ~ outcome[1]);
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
	}
	
	this(ref Window w, TableLayout table, bool tan) {
		win = &w;
		t = table;
		tantum = tan;
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
			Local.editSession(to!ulong(t.childById!TextWidget("sessionID").text), Local.getProjectId(to!string(t.childById!ComboBox("proj").selectedItem)) , to!string(t.childById!ComboBox("user").selectedItem), date, duration, to!string(t.childById!EditLine("desc").text), Local.getCategory(to!string(t.childById!ComboBox("cat").selectedItem)));
		} else {
			Local.editTantum(to!ulong(t.childById!TextWidget("sessionID").text), t.childById!CheckBox("tax").checked, to!ushort(t.childById!EditLine("cost").text),Local.getProjectId(to!string(t.childById!ComboBox("proj").selectedItem)), to!string(t.childById!ComboBox("user").selectedItem),date, to!string(t.childById!EditLine("desc").text), Local.getCategory(to!string(t.childById!ComboBox("cat").selectedItem)));
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
		
		auto back = new BackClick(win);
		return back.onClick(src);
	}
	
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

class InactivityWidget {
	import std.datetime.stopwatch: StopWatch, AutoStart;
	import std.stdio;
	import dlangui.dialogs.msgbox;
	
	private {
		uint timerLimit = 60000; //time in milliseconds
		Window win;
		StopWatch watch, timer;
		ulong sessionID;
		bool first = true;
		MessageBox msg = null;
		uint updateFactor = 2; //this will be used to update messageBox
		StringGridWidget grid = null;
	}
	
	this(Window w) {
		win = w;
		watch.stop();
		watch.reset();
		timer.stop();
		timer.reset();
		sessionID =0;
	}
	
	void onTimer() {
		//writeln("#################################### onTimer");
		if(first)  {
			first = false;
			Local.stopSession(sessionID);
			msg = new MessageBox(UIString.fromRaw("Inattività"d), UIString.fromRaw("Sei stato inattivo per 1 minuto. Cosa vuoi fare con questo tempo?"d), win,
				[new Action(1,"Crea nuova sessione"d), new Action(2,"Tieni questo tempo nella sessione ora attiva"d), new Action(3,"Butta via questo tempo"d)], 0,
				delegate(const(Action) result) {
					scope(exit) {
						msg = null; //destroy the messageBox
						first = true;
						updateFactor = 2;
						sessionID =0;
						//writeln("######################### resetting sessionID to 0");
					}
					
					switch(result.id) {
					
						case 1:
							import std.datetime.systime : SysTime, Clock;
							import core.time: dur;
							SysTime currentTime = Clock.currTime() - dur!"minutes"(watch.peek.total!"minutes");
							
							ushort hours, minutes;
							minutes = to!ushort(watch.peek.total!"minutes");
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
							ushort minutes = to!ushort(watch.peek.total!"minutes" -1);//take away the minute before stopping the session
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
							Local.editSession(sessionID,0, null,null, newDuration );
							
							//now update the grid
							if( grid !is null) {
								//writeln("################################ updating grid");
								//writeln("################################ grid.rows : ", grid.rows);
								grid.setCellText(1,grid.rows-1, to!dstring(newDuration));
							}
							
							break;
					
						case 3:
							//fai niente
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
			msg.message = "Sei stato inattivo per "d ~ to!dstring(watch.peek.total!"minutes")~ " minuti. Cosa vuoi fare con questo tempo?"d;
			//msg.show();
		}
		
		
	}
	
	void resetTimer() {
		if(timer.running && msg is null) startTimer(sessionID); //reset timer if it's running and no message box is being displayed
	}
	
	void startTimer(ulong ses) {
		timer.stop();
		timer.reset();
		timer.start();
		watch.stop();
		watch.reset();
		watch.start();
		sessionID = ses;
	}
	
	void update() {
		if(timer.peek.total!"msecs" >= timerLimit) { //if enough time elapsed;
			timer.stop();
			timer.reset();
			onTimer();
		}
		if(!first && watch.peek.total!"msecs" >= updateFactor * timerLimit) {
			++updateFactor;
			onTimer();
		}
	}
	
	void setGrid ( StringGridWidget g) {
		grid = g;
	}
	
}