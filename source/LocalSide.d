module LocalSide;

/*
	This handles the local database, where all info
	about projects, categories and sessions are stored.

	The info about users are handled by the LogIn module
*/

import std.json;
import Projects;
import Categories;
import Sessions;

class SyncLocal {

static:

	/*
		All info about users, roles and passwords 
		are handled by the LogIn module
	*/
	
	immutable {
 		string systemDB;
 		string projectsDB;
 		string categoriesDB;
 		string sessionsDB;
 		string systemSyncDB;
 		string projectsSyncDB;
 		string categoriesSyncDB;
 		string sessionsSyncDB;
 	}
 	
 	static this() {
		import Utility;
		
		auto localDB = getCurrentPath();
		systemSyncDB = localDB ~"SystemSync.db";
		projectsSyncDB = localDB ~"ProjectsSync.db";
		categoriesSyncDB = localDB~"CategoriesSync.db";
		sessionsSyncDB = localDB~"SessionsSync.db";
		systemDB = localDB ~"System.db";
		projectsDB = localDB ~"Projects.db";
		categoriesDB = localDB~"Categories.db";
		sessionsDB = localDB~"Sessions.db";
		
	}
	
	//convert an object (proj/cate/sess/tantum) to a JSONValue
	private JSONValue createJson(Type) (const Type obj) {
		JSONValue json;
		
		
		static if( is (Type : Project)) {
			json.object["_id"] = obj.ID();
			json.object["name"] = obj.shortName();
			json.object["number"] = obj.jobNumber();
			json.object["sync"] = obj.sync();
			json.object["archived"] = false;
		} else {}
		
		static if ( is (Type : Category)){
			json.object["_id"] = obj.name();
			json.object["color"] = obj.color();
		} else  { }
		
		static if( is( Type : Tantum)) {
			json.object["tantum"] = true;
			json.object["cost"]  = obj.cost();
			json.object["taxable"] = obj.taxable();
			//the rest will be matched by the following if
		} else { }
		
		static if ( is (Type: Session)) {
			json.object["_id"] = obj.ID();
			json.object["dateTime"] = obj.dateTime();
			json.object["duration"] = obj.duration();
			json.object["category"] = obj.category();
			json.object["user"] = obj.user();
			json.object["project"] = obj.projectID();
		} else { }
		
		return json;
	}
	//append buffer to file path
	private void appendToFile(const string path, const string buffer) {
		import std.file: append, exists, isFile;
		
		if( !path.exists || !path.isFile) {
			throw new CorruptedFileException("There is an error with the local database.");
		}
		
		append(path, "\n"~buffer~"\n");
		
	}
	//remove json with given id from a file
	private void removeJson(T) (const string path, const T id) {
		import std.file: readText, exists, isFile, write;
		import Utility;
		
		if( !path.exists || !path.isFile) {
			throw new CorruptedFileException("There is an error with the local database.");
		}
		
		auto fileContent = readText(path);
		
		string newFileContent;
		
		foreach (s ; splitJson(fileContent)){ //go through each json and look for the one to replace
			auto j = parseJSON(s);
			static if ( is (T : ulong)) { //static if is resolved at compile time
				if( j["_id"].uinteger == id) {
					continue;
				}
			} else if ( is (T: string)) {
				if( j["_id"].str == id) {
					continue;
				}
			} else {
				throw new Exception("unknown type");
			}
			
			newFileContent ~= s;
		}
		
		write(path, newFileContent);
		
	}
	
//PROJECTS HANDLING-----------------------------------------------------------------------

	void newProject(const Project pr) {
		auto proj = createJson(pr);
		appendToFile(projectsDB, proj.toPrettyString);
		proj.object["status"] = "new";
		appendToFile(projectsSyncDB, proj.toPrettyString);
	}
	
	void updateProject(const Project pr, const ulong oldId) {
		auto proj = createJson(pr);
		removeJson(projectsDB, oldId);
		appendToFile(projectsDB, proj.toPrettyString);
		proj.object["status"] = "update";
		proj.object["oldId"] = oldId;
		appendToFile(projectsSyncDB,proj.toPrettyString);
	}
	
	void deleteProject(const ulong projectID) {
		import std.conv: to;
		
		removeJson(projectsDB, projectID);
		appendToFile(projectsSyncDB,`{ "_id" : `~to!string(projectID)~`, "status" : "remove"}` );
	}

//----------------------------------------------------------------------------------------

//CATEGORIES HANDLING---------------------------------------------------------------------

	void newCategory(const Category cat) {
		auto c = createJson(cat);
		appendToFile(categoriesDB, c.toPrettyString);
		c.object["status"] = "new";
		appendToFile(categoriesSyncDB,c.toPrettyString);
	}
	
	void updateCategory(const Category cat, const string oldId) {
		auto c = createJson(cat);
		removeJson(categoriesDB,oldId);
		appendToFile(categoriesDB,c.toPrettyString);
		c.object["oldId"] = oldId;
		c.object["status"] = "update";
		appendToFile(categoriesSyncDB,c.toPrettyString);
	}
	
	void deleteCategory(const string name) {
		removeJson(categoriesDB, name);
		appendToFile(categoriesSyncDB, `{"_id" : `~name~`, "status" : "remove"}`);
	
	}
	
//----------------------------------------------------------------------------------------

//SESSIONS HANDLING-----------------------------------------------------------------------

	void newSession(const Session obj) {
		auto c = createJson(obj);
		appendToFile(sessionsDB, c.toPrettyString);
		c.object["status"] = "new";
		c.object["tantum"] = false;
		appendToFile(sessionsSyncDB, c.toPrettyString);
	}
	
	void updateSession(const Session obj, const ulong oldId) {
		auto c = createJson(obj);
		removeJson(sessionsDB,oldId);
		appendToFile(sessionsDB,c.toPrettyString);
		c.object["oldId"] = oldId;
		c.object["status"] = "update";
		c.object["tantum"] = false;
		appendToFile(sessionsSyncDB,c.toPrettyString);
	}
	
	void deleteSession(const ulong sessionID) {
		import std.conv: to;
		
		removeJson(sessionsDB, sessionID);
		appendToFile(sessionsSyncDB,`{ "_id" : `~to!string(sessionID)~`, "status" : "remove"}` );
	}

	
//----------------------------------------------------------------------------------------

//TATUM HANDLING--------------------------------------------------------------------------

	void newTantum(const Tantum obj) {
		auto c = createJson(obj);
		appendToFile(sessionsDB, c.toPrettyString);
		c.object["status"] = "new";
		c.object["tantum"] = true;
		appendToFile(sessionsSyncDB, c.toPrettyString);
	}
	
	void updateTantum(const Session obj, const ulong oldId) {
		auto c = createJson(obj);
		removeJson(sessionsDB,oldId);
		appendToFile(sessionsDB,c.toPrettyString);
		c.object["oldId"] = oldId;
		c.object["status"] = "update";
		c.object["tantum"] = true;
		appendToFile(sessionsSyncDB,c.toPrettyString);
	}
	
	void deleteTantum(const ulong sessionID) {
		import std.conv: to;
		
		removeJson(sessionsDB, sessionID);
		appendToFile(sessionsSyncDB,`{ "_id" : `~to!string(sessionID)~`, "status" : "remove"}` );
	}
	
//----------------------------------------------------------------------------------------

}

class CorruptedFileException : Exception {
	const(string) message;
	this(string msg, string file = __FILE__, size_t line = __LINE__ ) { //constructor needs a message, and possible where the error is 
		message = msg;
		super(msg,file, line); //call constructor of Exception class
	}
}
