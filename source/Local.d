module Local;
/*

	Program Interface;
	
	The GUI should only should only use this class to perform operations.
	
	The Local class puts together all other modules
*/

import Sessions;
import Categories;
import Projects;
import Sync;
import LogIn;
import Utility;

import std.datetime.stopwatch : StopWatch, AutoStart;
import std.typecons: Tuple, tuple;
import std.json;
//import std.stdio;

alias Outcome = const(Tuple!(bool,string));

class Local {
static: //this makes the all the member static

	private Session[] userSessions; //slice of user sessions
	private Tuple!(Session, StopWatch)[] activeSessions; //list of all active sessions and their watches
	private string _host; //string containing the host specified in the settings
	private string settingsFile;
	//settings object
	//object to make reports and fatture
	
	//find session/tantum/project/category via its ID
	private Session findSession(const ulong sessionID, const string user = Login.getUser()) {
		
		if(user != Login.getUser) {
			import std.file: readText;
			import LocalSide;
			import Utility;
			
			if(!offline) {
				if(user != null) DB.getSessions(user);
				else DB.getAllSessions();
			}
			if(user == null) {//unknown user; then look through userSessions as well
				foreach (ref ses; userSessions) {
					if(ses.ID == sessionID) return ses; //note that ses may actually be a Tantum
				}
			}
			foreach (ref json ; splitJson(readText(SyncLocal.sessionsDB)) ) {
				auto ses = createSessionFromJson(parseJSON(json));
				if(ses.ID == sessionID) return  ses;
			}
			
		}
		
		foreach (ref ses; userSessions) {
			if(ses.ID == sessionID) return ses; //note that ses may actually be a Tantum
		}
		
		throw new Exception("can't find the session; Are you sure such session exists?");
		
		assert(0); //always something wrong here
		
	}
	private Tantum findTantum (const ulong sessionID, const string user = Login.getUser()) {
		auto session = findSession(sessionID,user);
		auto tantum = (cast(Tantum)session); //if session is not of type Tantum; then null is returned.
		if(tantum is null) throw new Exception("I found a Session instead of a tantum");
		return tantum;
	}
	private Project findProject (const ulong projID) {
		auto projects =Project.getProjects();
		foreach (ref proj;  projects) {
			if(proj.ID == projID) {
				return proj;
			}
		}
		throw new Exception("Cannot find project with the given id");
	}
	private Category findCategory(const string nameID) {
		auto categories = Category.getCategories();
		foreach(ref cat; categories ) {
			if(cat.name == nameID) return cat;
		}
		throw new Exception("can't find the category with the given name");
	}
	private void createObjectsFromJson(T) (const string[] jsons) {
		import std.json;
		import std.conv: to;
		import std.stdio;
		
		foreach (ref s ; jsons ) {
			JSONValue json = parseJSON(s);
			static if ( is ( T: Project)) {
				ulong _id; //json["_id"] will be interpreted as signed integer is less than long.max
				if(json["_id"].type == JSON_TYPE.UINTEGER) {
					_id = json["_id"].uinteger;
				} else {
					_id = to!ulong(json["_id"].integer);
				}
				new Project( json["name"].str, to!ushort(json["number"].integer), json["sync"].type == JSON_TYPE.TRUE, json["notes"].str,_id);
			} else static if( is (T: Category)) {
				new Category(json["_id"].str, 0,0, json["color"].str);
			} else static if( is (T: Session)) {
				if(json["user"].str != Login.getUser) continue;
				userSessions ~= createSessionFromJson(json);
			} else {
				throw new Exception("unknown type");
			}
		}
	}
	private Session createSessionFromJson( const JSONValue json) {
		import std.conv: to;
		
		ulong proj; //json["project"] will be interpreted as signed integer is less than long.max
		if(json["project"].type == JSON_TYPE.UINTEGER) {
			proj = json["project"].uinteger;
		} else {
			proj = to!ulong(json["project"].integer);
		}
		
		ulong _id; //json["_id"] will be interpreted as signed integer is less than long.max
		if(json["_id"].type == JSON_TYPE.UINTEGER) {
			_id = json["_id"].uinteger;
		} else {
			_id = to!ulong(json["_id"].integer);
		}
		
		if(json["tantum"].type == JSON_TYPE.TRUE) {
			return new Tantum(proj, json["user"].str, to!ushort(json["cost"].integer) ,json["taxable"].type == JSON_TYPE.TRUE, json["description"].str, findCategory(json["category"].str), json["dateTime"].str, _id);
		} else {
			auto s =  new Session(proj, json["user"].str, json["description"].str, findCategory(json["category"].str), json["dateTime"].str, _id);
			s.changeDuration(json["duration"].str);
			s.changePlace(json["place"].str);
			return s;
		}
		
	}
	private bool _offline = true;
	
	@property bool offline() { return _offline; }
	@property bool offline(bool value) { 
		DB.offline = value;
		_offline = value;
		return _offline;
	}

	static this() {
	
		import std.file: readText;
		import Utility;
		
		//get _host and all settings
		settingsFile = getCurrentPath() ~ "settings";
		auto json = parseJSON(readText(settingsFile));
		_host = json["host"].str;
	}

	void initialise(){
		DB.offline = _offline;
		DB.syncAll; //need to have logged in before this
		//now local database is synced; so we need to create the objects
		import std.file: readText;
		import LocalSide;
		import Utility;
		//create projects
		createObjectsFromJson!Project(splitJson(readText(SyncLocal.projectsDB)));
		
		//create categories
		createObjectsFromJson!Category(splitJson(readText(SyncLocal.categoriesDB)));
		
		//create sessions and tantums
		createObjectsFromJson!Session(splitJson(readText(SyncLocal.sessionsDB)));
		
	}
	
//GET  METHODS ---------------------------------------------------------------------------

	//current users
	const(string) getCurrentUser()  {
		return Login.getUser();
	}
	
	//current role
	const(string) getCurrentRole() { 
		return Login.getUserRole();
	}
	
	//get role of a given user
	const(string) getRole(const string user) {
		return Login.getUserRole(user);
	}
	
	//all users
	const(string[]) getAllUsers()  {
		return Login.getUsers;
	}
	
	//get implemented roles
	const(string[]) getRoles() {
		return Login.getRoles();
	}
	
	//get userSessions
	const(Session[]) getUserSessions()  {
		return userSessions;
	}
	
	//get session of specific user 
	const(Session[]) getSessions(const string user) {
		if(!offline) DB.getSessions(user);
		
		Session[] result;
		
		//now get from file
		import LocalSide;
		import std.file: readText;
		import Utility: splitJson;
		
		auto jsons = splitJson(readText(SyncLocal.sessionsDB));
		foreach( ref s ; jsons) {
			auto json = parseJSON(s);
			if(json["user"].str == user) {
				result ~= createSessionFromJson(json);
			}
		}
		
		return result;
		
	}
	
	const(Session[]) getAllSessions() {
		if(!offline) DB.getAllSessions();
		
		Session[] result;
		
		import LocalSide;
		import std.file: readText;
		import Utility: splitJson;
		
		foreach (ref json ; splitJson(readText(SyncLocal.sessionsDB)) ) {
			result ~= createSessionFromJson(parseJSON(json));
		}
		
		return result;
	}
	
	//get active sessions
	const(Tuple!(Session,StopWatch)[]) getActiveSession()  {
		return activeSessions;
	}
	
	//tells us if there is an active session for this project
	const(Session) getActiveSession(ulong projID) {
		import std.algorithm: filter;
		
		auto list = activeSessions.filter!( t => t[0].projectID == projID);
		if(list.empty) return null;
		return list.front[0];
	}
	
	//get projects
	const(Project[]) getProjects() {
		return Project.getProjects();
	}
	
	//get categories
	const(Category[]) getCategories() {
		return Category.getCategories();
	}
	
	//get colors that can be assigned to categories
	const(string[]) getCategoriesColors() {
		return Category.getColors();
	}
	
	//get session from id
	const(Session) getSession(const ulong sessionID, const string user = Login.getUser()) {
		return findSession(sessionID, user);
	}
	
	//get Tantum from id
	const(Tantum) getTantum(const ulong sessionID, const string user = Login.getUser()){
		return findTantum(sessionID,user);
	}
	
	//get Project from id
	const(Project) getProject(const ulong projID) {
		return findProject(projID);
	}
	
	//get projId from project name
	const(ulong) getProjectId(const string name) {
		auto projects = Project.getProjects();
		foreach( ref proj; projects) {
			if( proj.name == name) return proj.ID;
		}
		throw new Exception("Cannot find project with the given name");
	}
	
	//get Category from id
	const(Category) getCategory(const string nameID) {
		return findCategory(nameID);
	}
	
	//return if session is an active session
	const(bool) isActiveSession(const ulong sesID) {
		import std.algorithm: filter;
		
		return !(activeSessions.filter!(t => t[0].ID == sesID).empty);
	}

//----------------------------------------------------------------------------------------

//SESSION HANDLING------------------------------------------------------------------------

	//create a Session, a stopwatch and start the watch; returns the session ID
	const(ulong) startSession(const ulong projID, const string description = "", const Category category = Category.NoneCategory) {
		import std.algorithm : filter;
	
		if ( ! activeSessions.filter!(tup => tup[0].projectID ==projID).empty) { //if there is another session for the same project
			throw new Exception("starting a new session for a project with an active session; terminate that first");
		}
		
		auto watch = StopWatch(AutoStart.yes); //this is a struct, not a class; so there is no new keyword
		auto session = new Session(projID,Login.getUser(), description, category); //no date is passed; so the object will get current date and time
		userSessions ~= session;
		activeSessions ~= tuple(session,watch);
		
		return session.ID;
	}
	
	//stop a Session and update its duration
	void stopSessionByProject(const ulong projID) { //only 1 active session for project
		
		//find tuple and its position
		Tuple!(Session, StopWatch) myTuple;
		size_t index =0;
		foreach( ref tup; activeSessions) {
			if(tup[0].projectID == projID) {
				myTuple = tup;
				break;
			}
			++index;
		}
		if (index == activeSessions.length) { //if we found nothing
			throw new Exception("trying to stop a non existing session (or not active)");
		}
		
		myTuple[1].stop(); //stop the time
		auto watch = myTuple[1];
		
		import std.conv: to;
		auto hours = to!string(watch.peek.total!"hours");
		auto min = watch.peek.total!"minutes";
		if (watch.peek.total!"seconds" % 60 >= 30) ++min; //round up
		auto minutes = to!string(min % 60); //minutes as string [removing hours]
		import std.range: take;
		auto duration = to!string("00".take(2-hours.length)) ~ hours ~ ":" ~ to!string("00".take(2-minutes.length)) ~ minutes; //format duration as hh:mm
		myTuple[0].changeDuration(duration); //change duration of session
		
		//remove from active session
		import std.algorithm: remove;
		activeSessions = activeSessions.remove(index);
		
		//update database
		DB.newSession(myTuple[0]);
	}
	void stopSession(const ulong sessionID, const string user = Login.getUser()) {
		auto session = findSession(sessionID, user);
		stopSessionByProject(session.projectID);
	}
	void stopSession(Session session) {
		stopSessionByProject(session.projectID);
	}
	
	//create a Session to add manually; returns the session ID
	const(ulong) createSession (const ulong projID, const string date, const string user = Login.getUser(), const string description = "", const(Category) category = Category.NoneCategory, const ulong id = 0) {
		import std.algorithm: filter;
		
		Session session = null;
		
		if(user == Login.getUser()) {
			if(! userSessions.filter!( ses => ses.ID == id).empty) {  //check uniqueness of ID
				throw new Exception("There's already a session with the given id");
			}	
			session = new Session(projID, user, description, category, date, id);
			userSessions ~= session;
			
		} else { //must be admin
			if(!Login.isAdmin) throw new Exception("Need admin role to create other users sessions");
			
		}
		assert(session !is null); //if we reach this point a session should have been created
		
		//update db
		DB.newSession(session);		
		
		return session.ID;
		
	}
	
	//delete session
	void deleteSession (const(Session) session) {
		
		if (session.user == Login.getUser()) {
			size_t index =0;
			for (; index < userSessions.length; ++index) {
				if(userSessions[index].ID == session.ID) {
					break;
				}
			}
			assert(index < userSessions.length); //the session must be in that array
			
			import std.algorithm: remove;
			userSessions = userSessions.remove(index);
						
			//remove from active session is necessary
			index =0;
			for( ; index <activeSessions.length; ++index) {
				if(activeSessions[index][0].ID == session.ID) {
					activeSessions = activeSessions.remove(index);
					break;
				}
			}
			
			
		} 
		
		//thi function is called with tantums as arguments so:
		Tantum tan = cast(Tantum) session;
		if( tan !is null) DB.deleteTantum(tan);
		else DB.deleteSession(session);
	}
	//delete session with sessionID
	void deleteSession (const ulong sessionID, const string user = Login.getUser()) {
	
		Session session = findSession(sessionID, user);
		deleteSession(session);
	}
	
	//edit sessions properties
	void editSession (Session session, const ulong projID = 0 ,const string user = null ,const string date = null, const string duration = null, const string description = null, const Category category = null) {
		import std.algorithm: filter, remove;
		
		if(projID != 0) session.changeProjectID(projID); 
		
		if(user != null && Login.isAdmin) {
			
			if( Login.getUsers.filter!( us => us == user).empty) { //there is no such user
				throw new Exception("setting a session to a non-existing user");
			}
			if(session.user == Login.getUser() && user != Login.getUser()){ //this session will no loger belong to the current user
				size_t index=0;
				for( ; index < userSessions.length; ++index) {
					if (userSessions[index].ID == session.ID ) break;
				}
				assert(index <userSessions.length); //we must have found it
				userSessions = userSessions.remove(index);
			}
			
			session.changeUser(user);
			
		}
		
		if(date != null) session.changeDateTime(date);
		
		if(duration!= null) session.changeDuration(duration);
		
		if(description != null) session.description = description;
		
		if(category !is null) session.changeCategory(category);
		
		if( cast(Tantum)(session) !is null ) DB.updateTantum(cast(Tantum)(session), session.ID);
		else DB.updateSession(session,session.ID);
	}
	//edit session with sessionID and session's user
	void editSession (const ulong sessionID, const string sessionUser ,const ulong projID = 0 ,const string user = null ,const string date = null, const string duration = null, const string description = null, const Category category = null) {
		auto session = findSession(sessionID, sessionUser);
		editSession( session, projID, user, date,duration, description, category);
	}
	//edit session with sessionID only
	void editSession (const ulong sessionID, const ulong projID = 0 ,const string user = null ,const string date = null, const string duration = null, const string description = null, const Category category = null) {
		auto session = findSession(sessionID, null);
		editSession( session, projID, user, date, duration, description, category);
	}
	
	void changeSessionPlace(const ulong sessionID, const string sessionUser, const string place) {
		auto session = findSession(sessionID, sessionUser);
		session.changePlace(place);
	}
	
	const(string[string]) sessionDescription( const ulong sessionID, const string user = Login.getUser) {
		auto session = getSession(sessionID);
		
		string[string] result;
		import std.conv: to;
		
		result["description"] = session.description;
		result["dateTime"] = session.dateTime;
		result["duration"] = session.duration;
		result["category"] = session.category;
		result["user"] = session.user;
		result["projectID"] = to!string(session.projectID);
		result["ID"] = to!string(session.ID);
		result["place"] = session.place;
		
		if( cast(Tantum)(session) !is null) {
			auto tantum = cast(Tantum)(session);
			assert(tantum !is null);
			result["tantum"] = "true";
			result["cost"] = to!string(tantum.cost);
			result["taxable"] = tantum.taxable ? "true" : "false";
		} else {
			result["tantum"] = "false";
		}
		
		return result;
	}
	
//----------------------------------------------------------------------------------------

//TANTUM HANDLING-------------------------------------------------------------------------

	//create tantum; returns tantum id
	const(ulong) createTantum (const ulong projID, const string date,const string user = Login.getUser(), const ushort cost =0, bool tax = false, const string description ="", const Category category = Category.NoneCategory, const ulong id=0) {
		import std.algorithm : filter;
		Tantum tantum = null;
		if(user == Login.getUser() ) {
			if(! userSessions.filter!( ses => ses.ID == id).empty) {
				throw new Exception("There's already a session with the given id");
			}
			tantum = new Tantum(projID, user,cost, tax, description, category, date, id);
			userSessions ~= tantum;
		}
		
		DB.newTantum(tantum);
		
		return tantum.ID;
	}
	
	//delete tantum
	void deleteTantum (Tantum tantum) {
		deleteSession(tantum);
	}
	//delete tantum through ID
	void deleteTantum (const ulong sessionID, const string user = Login.getUser()) {
		Tantum tantum = findTantum(sessionID, user);
		deleteTantum(tantum);
	}
	
	//edit tantum
	void editTantum (Tantum tantum, const bool tax, const ushort cost , const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, const Category category = null) {
		tantum.changeCost(cost);
		tantum.changeTaxable(tax);
		editSession(tantum, projID,user, date, null, description, category);
	}
	//edit tantum with sessionID
	void editTantum (const ulong tantumID, const string owner, const bool tax , const ushort cost, const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, const Category category = null) {
		auto tantum = findTantum(tantumID, owner);
		editTantum(tantum, tax,cost, projID,user, date, description, category);
	}
	void editTantum (const ulong tantumID, const string owner, const ushort cost, const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, const Category category = null) {
		auto tantum = findTantum(tantumID, owner);
		editTantum(tantum, tantum.taxable,cost, projID,user, date, description, category);
	}
	void editTantum (const ulong tantumID, const string owner, const bool tax , const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, const Category category = null) {
		auto tantum = findTantum(tantumID, owner);
		editTantum(tantum, tax,tantum.cost, projID,user, date, description, category);
	}
	void editTantum (const ulong tantumID, const string owner, const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, const Category category = null) {
		auto tantum = findTantum(tantumID, owner);
		editTantum(tantum, tantum.taxable, tantum.cost, projID,user, date, description, category);
	}
	 
//----------------------------------------------------------------------------------------

//PROJECT HANDLING------------------------------------------------------------------------

	//create project
	const(ulong) createProject(const string name, const ushort jobNumber=0, const bool sync = false, const string notes="", const ulong id=0){
		
		auto proj = new Project(name, jobNumber, sync, notes, id);
		
		DB.newProject(proj);
		return proj.ID;
	}
	
	//delete project
	void deleteProject(const ulong projID) {
		deleteProject(findProject(projID));
		
	}
	void deleteProject(const Project pro){
		
		Project.deleteProject(pro.ID);
		foreach(ref ses; userSessions) {
			if(ses.projectID == pro.ID) deleteSession(ses);		
		}
		DB.deleteProject(pro);
	}
	
	//edit project
	void editProject(Project proj, const ushort number, const bool sync ,const string name = null, const string notes =null) {
		proj.changeJobNumber(number);
		if(name != null) proj.changeName(name);
		if(notes != null) proj.note = notes;
		proj.changeSync(sync);
		DB.updateProject(proj, proj.ID);
	}
	void editProject(const ulong projID, const string name = null, const string notes =null) {
		auto proj = findProject(projID);
		editProject(proj,proj.jobNumber, proj.sync, name, notes);
	}
	void editProject(const ulong projID,const ushort number,const string name = null, const string notes =null) {
		auto proj = findProject(projID);
		editProject(proj,number, proj.sync, name, notes);
	}
	void editProject(const ulong projID,const bool sync,const string name = null, const string notes =null) {
		auto proj = findProject(projID);
		editProject(proj,proj.jobNumber,sync, name, notes);
	}
	void editProject(const ulong projID,const ushort number,const bool sync, const string name = null, const string notes =null) {
		auto proj = findProject(projID);
		editProject(proj,number,sync, name, notes);
	}
	
//----------------------------------------------------------------------------------------

//CATEGORY HANDLING-----------------------------------------------------------------------

	//create category
	const(string) createCategory(const string  name, const ushort feriale =0, const ushort  festivo =0, const string  color="black") {
		auto cat = new Category(name, feriale, festivo, color);
		DB.newCategory(cat);
		return cat.name();
	}
	
	//delete category
	void deleteCategory(const Category cat) {
		Category.deleteCategory(cat.name);
		DB.deleteCategory(cat);
	}
	void deleteCategory(const string nameID) {
		DB.deleteCategory(findCategory(nameID));
		Category.deleteCategory(nameID);
	}
	//edit category
	void editCategory(Category cat,  const ushort feriale , const ushort  festivo ,const string  name = null, const string  color=null) {
		string oldName = cat.name();
		if (name != null) cat.changeName(name);
		if (color != null) cat.changeColor(color);
		cat.changeCostoFeriale(feriale);
		cat.changeCostoFestivo(festivo);	
		DB.updateCategory( cat, oldName);
	}
	void editCategory(const string nameID, const string  name = null, const string color = null) {
		auto cat = findCategory(nameID);
		editCategory(cat,cat.costoFeriale,cat.costoFestivo,name,color);
	}
	void editCategory(const string nameID, const ushort costo, const bool feriale, const string  name = null,const string color= null){
		auto cat = findCategory(nameID);
		if(feriale) editCategory(cat,costo, cat.costoFestivo, name, color);
		else editCategory(cat, cat.costoFeriale, costo, name, color);
	}
	
//----------------------------------------------------------------------------------------

//LOGIN-LOGOUT USER HANDLING--------------------------------------------------------------

	private string doTryCommand (const string command, const string okMessage) {
		return "try{\n
			"~command~";\n
		} catch (Exception e) {\n
			return tuple(false, cast(string)e.message); //e.message is const(char)[] and string is immutable(char)[]\n
		}\n
		\n
		return tuple(true,\""~okMessage~"\");";
	}

	Outcome login(const string user , const string password) {
		mixin( doTryCommand("DB.login(user, password, _host)", "login successful"));
	}
	
	void logout() {
		DB.logout();
		userSessions = [];
		foreach( ref t ; activeSessions) {
			stopSession(t[0]);
		}
		activeSessions = [];
		Project.resetProjects();
		Category.resetCategories();
	}
	
	Outcome createUser( const string userName, const string password, const string role) {
		import std.string;
		if(offline) return tuple(false, "need to be online to handle users");
		if(userName.indexOf(":") != -1 || userName.indexOf("@") != -1) return tuple(false,"Username cannot contain : or @");
		mixin( doTryCommand("DB.createUser(userName, password, role)","User created") );
	}
	
	Outcome deleteUser( const string userName) {
		if(offline) return tuple(false, "need to be online to handle users");
		
		//delete all sessions associated with that user
		auto sessions = Local.getSessions(userName);
		
		foreach( ref s ; sessions){
			if(cast(Tantum) s !is null) deleteTantum(cast(Tantum)s);
			else deleteSession(s);
		}
	
		mixin(doTryCommand("DB.deleteUser(userName)", "User deleted"));
	}
	
	Outcome changeOwnPassword(const string newPassword) {
		if(offline) return tuple(false, "need to be online to handle users");
		mixin(doTryCommand("DB.changeOwnPassword(newPassword)", "Password changed"));
	}
	
	Outcome forgotPassword(const string user, const string newPassword) {
		if(offline) return tuple(false, "need to be online to handle users");
		mixin(doTryCommand("DB.forgotPassword(user, newPassword)", "Password changed"));
	}
	
	Outcome changeRole(const string user, const string newRole) {
		if(offline) return tuple(false, "need to be online to handle users");
		mixin(doTryCommand("DB.changeRole(user,newRole)", "Role changed"));
	}
	
//----------------------------------------------------------------------------------------

//SYNC CALENDAR---------------------------------------------------------------------------

	//check when was last time we synced
	//according to that call the correct sync
	//read the JSON produced and check the timestamp changed
	//go through the events and updates the projects [job number, or short name]
	Outcome syncAppleCalendar() {
		//read the calendarSyncFile
		import std.file: readText;
		import std.json; //file is a JSON
		import Utility; //getCyrrentPath
		import std.datetime.date: DateTime;
		import std.datetime.systime: Clock;
		import core.time: Duration, dur;
		import std.conv: to;
		import std.range: take;
		
		string filePath = getCurrentPath() ~ "calendarFile";
		JSONValue file = parseJSON(readText(filePath));
		DateTime oldTimestamp = DateTime.fromISOExtString(file["timestamp"].str);
		DateTime now = DateTime.fromISOExtString(to!string(Clock.currTime.toISOExtString.take(19))); //currTime.toISOExtString returns yyyy-mm-ddThh:mm:ss and we want only yyyy-mm-dd
		
		import Utility;
		string program = "./CalendarSync";
		
		if(now.diffMonths(oldTimestamp) > 1) {
			program ~= "-1year";
		} else {
			Duration timeDiff = now - oldTimestamp;
			
			if( timeDiff <= dur!"days"(1)) {
				program ~= "-2day";
			} else if (timeDiff < dur!"weeks"(1)) {
				program ~= "-1week";
			} else {
				program ~= "-1month";
			}
		}
		//now program has the correct name
		import std.process: executeShell;
		
		//writeln(executeShell("pwd"));
		//writeln(executeShell("ls"));
		auto sync = executeShell(program);
		
		//import std.stdio;
		//writeln(sync);
		
		//return with error if there is an error
		import std.algorithm.searching: canFind;
		if(canFind( sync.output, "error") || sync.status != 0) {
			return tuple(false,"swift error: "~ sync.output);
		}
		
		//now read the new calendarFile and update the projects.
		file = parseJSON(readText(filePath));
		if( oldTimestamp == DateTime.fromISOExtString(file["timestamp"].str) ) { //file calendarFile didn't change
			return tuple(false, "error with the file. Likely bug in swift");
		}
		
		//for each project if project is sync go through events and sync
		
		JSONValue[] events = file["eventi"].array;
		
		import std.regex: regex, matchFirst;
		
		foreach( ref proj; Project.getProjects ) {
			if( ! proj.sync ) continue;
			
			foreach(ref json; events) {
				string evTitle = json.str;
				//to find whether the event title represent our project we match to regex of project name or project job-number
				//we use regex so we can specify that they must match at word boundaries
				auto name = regex(r"\b"~proj.shortName~r"\b");
				auto number = regex(r"\b"~(to!string("00000".take(5-to!string(proj.jobNumber).length)) ~ to!string(proj.jobNumber))~r"\b"); //jobNumber padded to length 5
				if(!matchFirst(evTitle, name).empty || !matchFirst(evTitle,number).empty) { //this event goes with this project
					auto sessionID = createSession (proj.ID, file[evTitle].array[0].str , Login.getUser(), evTitle); //create session 
					Duration sessionLength = DateTime.fromISOExtString(file[evTitle].array[1].str) - DateTime.fromISOExtString(file[evTitle].array[0].str);
					string duration = to!string(sessionLength.total!"hours") ~":"~ to!string(sessionLength.total!"minutes" %60);
					editSession (sessionID,0 , null ,null, duration ) ; //edit duration of session
				}
			
			}
		
		}
		
		
		return tuple(true, "apple calendar synced");
	}

//----------------------------------------------------------------------------------------

//SETTINGS HANDLING-----------------------------------------------------------------------

	void setHost(const string host ) {
		_host = host;
		
		import std.file: readText, write;
		
		auto content = readText(settingsFile);
		auto json = parseJSON(content);
		
		json["host"] = _host;
		
		write(settingsFile, json.toPrettyString);
	}
	
	const(string) getHost() {
		return _host;
	}

//----------------------------------------------------------------------------------------

//REPORTS-FATTURE MAKING------------------------------------------------------------------

//----------------------------------------------------------------------------------------
	
//DIRECT SYNC DATABASE--------------------------------------------------------------------

	void syncDatabase(const bool flag = true) {
		if(offline) throw new Exception("Cannot sync Database when offline");
		DB.syncAll(flag);
	}
	
	void syncProjects(const bool changes = true) {
		if(offline) throw new Exception("Cannot sync Database when offline");
		DB.syncProjects(changes);
	}
	
	void syncCategories(const bool changes = true) {
		if(offline) throw new Exception("Cannot sync Database when offline");
		DB.syncCategories(changes);
	}
	
	void syncSessions(const string user = Login.getUser, const bool changes = true) {
		if( user != Login.getUser && !Login.isAdmin) {
			throw new Exception("Need to be admin to sync someone else sessions");
		}
		if(offline) throw new Exception("Cannot sync Database when offline");
		DB.syncSessions(user, changes);
	}
	
	void syncUsers() {
		if(offline) throw new Exception("Cannot sync Database when offline");
		DB.getPasswords();
	}
	
//----------------------------------------------------------------------------------------
}

class Warning : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__ ) { //constructor needs a message, and possible where the error is 
		super("Warning: "~msg,file, line); //call constructor of Exception class
	}
}
