module Sync;

/*
	This module groups together All the operations
	which requires the interaction between local and remote database;
	The interface Local should use this and not Serverside, Localside or LogIns
*/

import LogIn;
import ServerSide;
import LocalSide;
import Projects;
import Categories;
import Sessions;
import std.json;
import std.container.array: empty;
class DB {

static:

	private ushort sessionLimit = 30; //this set the limit of how many sessions changes before syncing with the server
	private ushort sessionCount =0;

	private void syncNewObj(T) (const T obj, bool syncRemote) {
		if(offline) syncRemote = false;
		static if (is(T : Project)) {
			SyncLocal.newProject(obj);
			if(syncRemote) SyncServer.syncProjects();
		} else static if (is (T : Category)) {
			SyncLocal.newCategory(obj);
			if(syncRemote) SyncServer.syncCategories();
		} else static if (is (T: Tantum)) {
			SyncLocal.newTantum(obj);
			if(syncRemote) SyncServer.syncSessions();
		} else static if (is (T : Session) ) {
			SyncLocal.newSession(obj);
			if(syncRemote) SyncServer.syncSessions();
		} else {
			throw new Exception("unknown type");
		}
	}
	private void syncUpdateObj(T, S) (const T obj, const S oldId,  bool syncRemote) {
		if(offline) syncRemote = false;
		static if (is(T : Project)) {
			SyncLocal.updateProject(obj, oldId);
			if(syncRemote) SyncServer.syncProjects();
		} else static if (is (T : Category)) {
			SyncLocal.updateCategory(obj, oldId);
			if(syncRemote) SyncServer.syncCategories();
		} else static if (is (T: Tantum)) {
			SyncLocal.updateTantum(obj,oldId);
			if(syncRemote) SyncServer.syncSessions();
		} else static if (is (T : Session) ) {
			SyncLocal.updateSession(obj, oldId);
			if(syncRemote) SyncServer.syncSessions();
		} else {
			throw new Exception("unknown type");
		}
	}
	private void syncDeleteObj(T) (const T obj,  bool syncRemote) {
		if(offline) syncRemote = false;
		static if (is(T : Project)) {
			SyncLocal.deleteProject(obj.ID);
			if(syncRemote) {
				SyncServer.syncProjects();
				SyncServer.syncSessions();//we also delete all sessions associated with this project
			}
			
		} else static if (is (T : Category)) {
			SyncLocal.deleteCategory(obj.name);
			if(syncRemote) SyncServer.syncCategories();
		} else static if (is (T: Tantum)) {
			SyncLocal.deleteTantum(obj.ID);
			if(syncRemote) SyncServer.syncSessions();
		} else static if (is (T : Session) ) {
			SyncLocal.deleteSession(obj.ID);
			if(syncRemote) SyncServer.syncSessions();
		} else {
			throw new Exception("unknown type");
		}
	
	}
	private void JsonListToFile (  inout const JSONValue[] jsonList, const string file) {
		import std.file: exists, isFile, write, append;
		
		if( !file.exists || !file.isFile) throw new CorruptedFileException("Projects local database seems to be corrupted");
		
		if( jsonList.empty) {
			write(file, "");
			return;
		}
		
		file.write(jsonList[0].toPrettyString);
		
		size_t i =1;
		
		for( ; i< jsonList.length; ++i) {
			file.append("\n"~jsonList[i].toPrettyString~"\n");
		}
	}

	bool offline = true; //need to change this

//PROJECTS HANDLING-----------------------------------------------------------------------

	void newProject(const Project pr) {
		syncNewObj(pr,true);
	}
	
	void updateProject(const Project pr, const ulong oldId) {
		syncUpdateObj(pr,oldId, true);
	}
	
	void deleteProject(const Project pr) {
		syncDeleteObj(pr, true);
	}
	
	void getProjects() {
		if( offline) {
			throw new Exception("cannot sync because we're offline");
		}
		//this override any changes not synced with the remote
		import std.file:readText;

		if( readText(SyncLocal.projectsSyncDB) != "") throw new Exception("local changes are will be lost if you sync");

		JsonListToFile(SyncServer.getProjects(),SyncLocal.projectsDB);
		
	}
	
	void syncProjects(const bool applyChanges = true) {
		if(applyChanges) SyncServer.syncProjects(); //apply local changes to remote
		getProjects(); //get remote stuff to local
	}

//----------------------------------------------------------------------------------------

//CATEGORIES HANDLING---------------------------------------------------------------------

	void newCategory(const Category cat) {
		syncNewObj(cat, true);
	}
	
	void updateCategory(const Category cat, const string oldId) {
		syncUpdateObj(cat, oldId, true);
	}
	
	void deleteCategory(const Category cat) {
		syncDeleteObj(cat, true);
	}
	
	void getCategories(){
		if( offline) {
			throw new Exception("cannot sync because we're offline");
		}
		//this override any changes not synced with the remote
		import std.file:readText;

		if( readText(SyncLocal.categoriesSyncDB) != "") throw new Exception("local changes are will be lost if you sync");

		JsonListToFile(SyncServer.getCategories(),SyncLocal.categoriesDB);
	}
	
	void syncCategories(const bool applyChanges = true) {
		if(applyChanges) SyncServer.syncCategories(); //apply local changes to remote
		getCategories(); //get remote stuff to local
	}
	
//----------------------------------------------------------------------------------------

//SESSIONS HANDLING-----------------------------------------------------------------------

	void newSession(const Session obj) {
		++sessionCount;
		//we sync the remote only sessionLimit times
		if (sessionCount < sessionLimit) syncNewObj(obj,false);
		else {
			syncNewObj(obj,true);
			sessionCount =0;
		}
	}
	
	void updateSession(const Session obj, const ulong oldId) {
		++sessionCount;
		//we sync the remote only sessionLimit times
		if (sessionCount < sessionLimit) syncUpdateObj(obj,oldId,false);
		else {
			syncUpdateObj(obj, oldId,true);
			sessionCount =0;
		}
	}
	
	void deleteSession(const Session obj) {
		++sessionCount;
		//we sync the remote only sessionLimit times
		if (sessionCount < sessionLimit) syncDeleteObj(obj,false);
		else {
			syncDeleteObj(obj,true);
			sessionCount =0;
		}
	}
	
	void getUserSessions(){
		getSessions(Login.getUser);
	}
	
	void getSessions(const string user) {
		if( offline) {
			throw new Exception("cannot sync because we're offline");
		}
		//this override any changes not synced with the remote
		import std.file:readText;

		if( readText(SyncLocal.sessionsSyncDB) != "") throw new Exception("local changes are will be lost if you sync");

		JsonListToFile(SyncServer.getUserSessions(user),SyncLocal.sessionsDB);
	}
	
	void getAllSessions() {
		if( offline) {
			throw new Exception("cannot sync because we're offline");
		}
		//this override any changes not synced with the remote
		import std.file:readText;

		if( readText(SyncLocal.sessionsSyncDB) != "") throw new Exception("local changes are will be lost if you sync");

		JsonListToFile(SyncServer.getAllSessions(),SyncLocal.sessionsDB);
	}
	
	void syncSessions(const string user = Login.getUser, const bool applyChanges = true) {
		if(applyChanges) SyncServer.syncSessions(); //apply local changes to remote
		getSessions(user); //get remote stuff to local
	}

//----------------------------------------------------------------------------------------

//TATUM HANDLING--------------------------------------------------------------------------

	void newTantum(const Tantum obj) {
		++sessionCount;
		//we sync the remote only sessionLimit times
		if (sessionCount < sessionLimit) syncNewObj!Tantum(obj,false);
		else syncNewObj!Tantum(obj,true);
	}
	
	void updateTantum(const Tantum obj, const ulong oldId) {
		++sessionCount;
		//we sync the remote only sessionLimit times
		if (sessionCount < sessionLimit) syncUpdateObj(obj,oldId,false);
		else syncUpdateObj(obj,oldId,true);
	}
	
	void deleteTantum(const Tantum obj) {
		++sessionCount;
		//we sync the remote only sessionLimit times
		if (sessionCount < sessionLimit) syncDeleteObj(obj,false);
		else syncDeleteObj(obj,true);
	}
	

//----------------------------------------------------------------------------------------

//USER HANDLING---------------------------------------------------------------------------

	void logout() {
	
		Login.logout();
		SyncServer.disconnect();
	
	}
	
	void login(const string user, const string password, const string host) {
	
		if( SyncServer.isConnected) {
			throw new Exception("Please disconnect before connecting");
		}
		
		if(!offline) {
			SyncServer.connect(host, user, password);
			getPasswords(); //sync local password db
		}
		
		Login.login(user, password);
	
	}
	
	void changeOwnPassword ( const string newPassword) {
		
		getPasswords();
		
		Login.changePassword(newPassword);
		SyncServer.changePassword(Login.getUser, newPassword, Login.hashPassword(Login.getUser,newPassword));
	}
	
	void forgotPassword (const string user, const string newPassword){
	
		getPasswords();
		
		if(!Login.isAdmin) throw new PermissionException("need to be admin to change passwords");
		
		Login.forgotPassword(user, newPassword);
		
		SyncServer.changePassword(user,newPassword, Login.hashPassword(user,newPassword));
	}
	
	void createUser( const string user , const string password, const string role = "User") {

		getPasswords();
		if(!Login.isAdmin) throw new PermissionException("need to be admin to create user");
		Login.createUser(user,password, role);
		
		SyncServer.createUser(user,role, Login.hashRole(user, role), password, Login.hashPassword(user,password));
	}
	
	void deleteUser (const string user) {
		getPasswords();
		if(! Login.isAdmin() ) throw new PermissionException("need to be admin in order to delete a user");
		
		Login.deleteUser(user);
		
		SyncServer.deleteUser(user);
	}
	
	void changeRole(const string user, const string newRole) {
		getPasswords();
		if(!Login.isAdmin) throw new PermissionException("need to be admin to change role");
		Login.changeRole(user, newRole);
		
		SyncServer.changeRole(user, newRole, Login.hashRole(user, newRole));
	}

	void getPasswords(){
		if( offline) {
			throw new Exception("cannot sync because we're offline");
		}
		auto json = SyncServer.getPasswords();
		
		import std.file: exists, isFile, write, append;
		import Utility;
		
		string passFile = getCurrentPath()~"pass"; //same as in Login
		
		if( !passFile.exists || !passFile.isFile) throw new PassFileException("local passwords database seems to be corrupted or missing");
		
		passFile.write(json.toPrettyString);
	
		
	}
	
	const(string[]) getUsers() {
		if( offline) {
			throw new Exception("cannot sync because we're offline");
		}
		getPasswords(); //sync users
		return Login.getUsers();
	}
	
	
//----------------------------------------------------------------------------------------

	//sync all projects, categories, sessions and users
	void syncAll(const bool user=true){
		if(!offline) {
			SyncServer.syncProjects();
			SyncServer.syncCategories();
			SyncServer.syncSessions();
			getPasswords();
			if( user) getUserSessions();
			else getAllSessions();
			getCategories();
			getProjects();
		}
	}

}
