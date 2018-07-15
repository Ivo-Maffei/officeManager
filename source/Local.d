module Local;

import Sessions;
import Categories;
import Projects;
import LogIn;

import std.datetime.stopwatch : StopWatch, AutoStart;
import std.typecons: Tuple, tuple;

import std.stdio;

alias Outcome = const(Tuple!(bool,string));

class Local {
static: //this makes the all the member static

	private string[] users; //slice containing all possible users [only admin can access this]
	private Session[] userSessions; //slice of user sessions
	private Tuple!(Session, StopWatch)[] activeSessions; //list of all active sessions and their watches
	//SyncObject to synchronize
	//settings object
	//object to make reports and fatture
	
	//find session/tantum/project/category via its ID
	private Session findSession(const ulong sessionID, const string user = Login.getUser()) {
		Session session = null;
		
		if(user == Login.getUser()) {//look locally
			foreach (ref ses; userSessions) {
				if(ses.ID == sessionID) return ses; //note that ses may actually be a Tantum
			}
		}
		
		/*if( not Admin ) {
			throw new Exception("can't find the session; Does the session belong to another user? If so, please log-in as admin");
		}
		*/
		
		//do sql search
		
		if(session is null) {
			throw new Exception("can't find the session; Are you sure such session exists?");
		}
		
		return session;
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

	static this() {
		//sync and fetch users list, projects and categories
		//look at local files for settings
		users ~="me";
	
	}
	
//GET  METHODS ---------------------------------------------------------------------------

	//current users
	const(string) getCurrentUser()  {
		return Login.getUser();
	}
	
	//all users
	const(string[]) getAllUsers()  {
		return users;
	}
	
	//get userSessions
	const(Session[]) getUserSessions()  {
		return userSessions;
	}
	
	//get active sessions
	const(Tuple!(Session,StopWatch)[]) getActiveSession()  {
		return activeSessions;
	}
	
	//get projects
	const(Project[]) getProjects() {
		return Project.getProjects();
	}
	
	//get categories
	const(Category[]) getCategories() {
		return Category.getCategories();
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
	
	//get Category from id
	const(Category) getCategory(const string nameID) {
		return findCategory(nameID);
	}

//----------------------------------------------------------------------------------------

//SESSION HANDLING------------------------------------------------------------------------

	//create a Session, a stopwatch and start the watch; returns the session ID
	const(ulong) startSession(const ulong projID, const string description = "", Category category = Category.NoneCategory) {
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
	}
	void stopSession(const ulong sessionID, const string user = Login.getUser()) {
		auto session = findSession(sessionID, user);
		stopSessionByProject(session.projectID);
	}
	void stopSession(Session session) {
		stopSessionByProject(session.projectID);
	}
	
	//create a Session to add manually; returns the session ID
	const(ulong) createSession (const ulong projID, const string date,const string user = Login.getUser(), const string description = "", Category category = Category.NoneCategory, const ulong id = 0) {
		import std.algorithm: filter;
		
		Session session = null;
		
		if(user == Login.getUser()) {
			if(! userSessions.filter!( ses => ses.ID == id).empty) {  //check uniqueness of ID
				throw new Exception("There's already a session with the given id");
			}	
			session = new Session(projID, user, description, category, date, id);
			userSessions ~= session;
			
		} else { //must be admin
			//check with SQL if session is unique and add it to the according list
		}
		assert(session !is null); //if we reach this point a session should have been created
		
		return session.ID;
		
	}
	
	//delete session
	void deleteSession (Session session) {
		
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
			
			
		} else { //must be admin
			//do sql stuff
		}
	}
	//delete session with sessionID
	void deleteSession (const ulong sessionID, const string user = Login.getUser()) {
	
		Session session = findSession(sessionID, user);
		deleteSession(session);
	}
	
	//edit sessions properties
	void editSession (Session session, const ulong projID = 0 ,const string user = null ,const string date = null, const string duration = null, const string description = null, Category category = null) {
		import std.algorithm: filter, remove;
		
		if(projID != 0) session.changeProjectID(projID); 
		
		if(user != null && Login.isAdmin) {
			
			if( users.filter!( us => us == user).empty) { //there is no such user
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
	}
	//edit session with sessionID and session's user
	void editSession (const ulong sessionID, const string sessionUser ,const ulong projID = 0 ,const string user = null ,const string date = null, const string duration = null, const string description = null, Category category = null) {
		auto session = findSession(sessionID, user);
		editSession( session, projID, user, date, duration, description, category);
	}
	//edit session with sessionID only
	void editSession (const ulong sessionID, const ulong projID = 0 ,const string user = null ,const string date = null, const string duration = null, const string description = null, Category category = null) {
		auto session = findSession(sessionID);
		editSession( session, projID, user, date, duration, description, category);
	}
	
//----------------------------------------------------------------------------------------

//TANTUM HANDLING-------------------------------------------------------------------------

	//create tantum; returns tantum id
	const(ulong) createTantum (const ulong projID, const string date,const string user = Login.getUser(), const ushort cost =0, bool tax = false, const string description ="", Category category = Category.NoneCategory, const ulong id=0) {
		import std.algorithm : filter;
		Tantum tantum = null;
		if(user == Login.getUser() ) {
			if(! userSessions.filter!( ses => ses.ID == id).empty) {
				throw new Exception("There's already a session with the given id");
			}
			tantum = new Tantum(projID, user,cost, tax, description, category, date, id);
			userSessions ~= tantum;
		}
		
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
	void editTantum (Tantum tantum, const bool tax, const ushort cost , const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, Category category = null) {
		tantum.changeCost(cost);
		tantum.changeTaxable(tax);
		editSession(tantum, projID,user, date, null, description, category);
	}
	//edit tantum with sessionID
	void editTantum (const ulong tantumID, const bool tax , const ushort cost, const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, Category category = null) {
		auto tantum = findTantum(tantumID);
		editTantum(tantum, tax,cost, projID,user, date, description, category);
	}
	void editTantum (const ulong tantumID, const ushort cost, const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, Category category = null) {
		auto tantum = findTantum(tantumID);
		editTantum(tantum, tantum.taxable,cost, projID,user, date, description, category);
	}
	void editTantum (const ulong tantumID, const bool tax , const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, Category category = null) {
		auto tantum = findTantum(tantumID);
		editTantum(tantum, tax,tantum.cost, projID,user, date, description, category);
	}
	void editTantum (const ulong tantumID, const ulong projID = 0 ,const string user = null ,const string date = null, const string description = null, Category category = null) {
		auto tantum = findTantum(tantumID);
		editTantum(tantum, tantum.taxable, tantum.cost, projID,user, date, description, category);
	}
	
//----------------------------------------------------------------------------------------

//PROJECT HANDLING------------------------------------------------------------------------

	//create project
	const(ulong) createProject(const string name, const ushort jobNumber=0, const bool sync = false, const string notes="", const ulong id=0){
		auto proj = new Project(name, jobNumber, sync, notes, id);
		return proj.ID;
	}
	
	//delete project
	void deleteProject(const ulong projID) {
		Project.deleteProject(projID);
	}
	void deleteProject(const Project pro){
		Project.deleteProject(pro.ID);
	}
	
	//edit project
	void editProject(Project proj, const ushort number, const bool sync ,const string name = null, const string notes =null) {
		proj.changeJobNumber(number);
		if(name != null) proj.changeName(name);
		if(notes != null) proj.note = notes;
		proj.changeSync(sync);
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
		return cat.name();
	}
	
	//delete category
	void deleteCategory(const Category cat) {
		Category.deleteCategory(cat.name);
	}
	void deleteCategory(const string nameID) {
		Category.deleteCategory(nameID);
	}
	
	//edit category
	void editCategory(Category cat,  const ushort feriale , const ushort  festivo ,const string  name = null, const string  color=null) {
		if (name != null) cat.changeName(name);
		if (color != null) cat.changeColor(color);
		cat.changeCostoFeriale(feriale);
		cat.changeCostoFestivo(festivo);	
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

	//logout
	void logout() {
		writeln("logging out...");
		//stop all active sessions
		writeln("stopping active sessions...");
		foreach( ref tup; activeSessions) {
			stopSession(tup[0]);
		}
		
		//sync and sava stuff
		
		//reset fields
		activeSessions = null;
		userSessions = null;
		
		Login.logout;//logout
	}
	
	//login
	Outcome login(const string user, const string password) { //return tuple, if first is false, second is a message why login failed
	
		//first let's logout if necessary
		if( Login.getUser() != null) logout();
		
		//then log in
		import std.algorithm: filter;
		
		//this if statement should be removed when sync is implemented
		if(users.filter!(x => x == user).empty) {
			return tuple(false,"user does not exists locally; sync if necessary");
		}
		
		//check that local copy  of password database contains user [sync with server]
		
		try {
			Login.login(user, password); //if this throws exception, catch it and return false
		} catch (PasswordException e) {
			return tuple(false,"password is wrong; if you don't think so, sync with server");
		} catch (PassFileException e) {
			return tuple(false,"password database seems corrupted; please try again");
		}
		
		//sync to get userSessions;
		
		return tuple(true,"login completed");
	}
	
	//change password
	Outcome changePassword( const string oldPassword, const string newPassword, const string user = Login.getUser()) {
		
		if(newPassword.length >= 44) { //this because otherwise the password is longer than its hash [not great]
			throw new Warning("To improve security the password should be less or equal to 44 characters");
		}
		
		import std.algorithm: filter;
		//this if statement should be removed when sync is implemented
		if(users.filter!(x => x == user).empty) {
			return tuple(false,"user does not exists locally; sync if necessary");
		}
		
		//sync with server to get user into passFile
		
		try {
			Login.changePassword(oldPassword,newPassword, user);
		} catch (PasswordException e) {
			return tuple(false,e.message);
		} catch (PassFileException e) {
			return tuple(false,e.message);
		} catch (PermissionException e) {
			return tuple(false,e.message);
		}
	
		//sync again
		
		return tuple(true,"password changed");
	}
	
	//reset a forgotten password.
	Outcome forgotPassword(const string user, const string newPassword) {
		
		import std.algorithm: filter;
		//this if statement should be removed when sync is implemented
		if(users.filter!(x => x == user).empty) {
			return tuple(false,"user does not exists locally; sync if necessary");
		}
		
		//sync to ensure local file is ok
		
		try {
			Login.forgotPassword(user,newPassword);
		} catch (PassFileException e) {
			return tuple(false,e.message);
		} catch (PermissionException e) {
			return tuple(false,e.message);
		}
		
		//sync again
		
		return tuple(true,"password reset successful");
	}
	
	//create new user 
	Outcome createUser(const string user, const string password) {
		
		//the below needs to be removed when sync is implemented
		import std.algorithm: filter;
		if(!users.filter!(x => x == user).empty) {
			throw new Exception(user~" is not a user");
		}
		//check user is unique via sync
		
		try {
			Login.createUser(user,password);
		} catch (PermissionException e) {
			return tuple(false,e.message);
		} catch (PassFileException e) {
			return tuple(false,e.message);
		}
		
		//sync 
		//add new user to array of users. the code is to delete after implementing sync
		users ~= user;
		return tuple(true,"new user created");
	}
	
	//delete a user
	Outcome deleteUser(const string user) {
		//the below needs to be removed when sync is implemented
		import std.algorithm: filter;
		if(users.filter!(x => x == user).empty) {
			throw new Exception(user~" does not exists");
		}
		
		//check user exists on server
		try {
			Login.deleteUser(user);
		} catch (PermissionException e) {
			return tuple(false,e.message);
		} catch (PassFileException e) {
			return tuple(false, e.message);
		}
		
		//delete user from server; sync
		
		size_t index;
		for(index=0; index<users.length; ++index) {
			if(users[index]== user) {
				import std.algorithm: remove;
				users = users.remove(index);
				break;
			}
		}
		return tuple(true, user ~" deleted");
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
		
		import std.stdio;
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

//----------------------------------------------------------------------------------------

//REPORTS-FATTURE MAKING------------------------------------------------------------------

//----------------------------------------------------------------------------------------
	
//SYNC with SERVER------------------------------------------------------------------------

//----------------------------------------------------------------------------------------
	
}

class Warning : Exception {
	this(string msg, string file = __FILE__, size_t line = __LINE__ ) { //constructor needs a message, and possible where the error is 
		super("Warning: "~msg,file, line); //call constructor of Exception class
	}
}
