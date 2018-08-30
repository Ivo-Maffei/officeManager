module ServerSide;

/*
	This module handle the connection with the MondoDB
	It relies heavily on the existence of a local database, handled by LocalSide
*/


import vibe.db.mongo.mongo;
import vibe.db.mongo.client;
import vibe.data.json;
import std.json; //nicer than vibe.data.json and to use when interfacing with Local


class SyncServer {

static:

	private JSONValue[] cursorToJSONValue(T) ( MongoCursor!T cursor ) {
	
		import std.array: byPair;
		
		JSONValue[] list;
		
		foreach (i, doc; cursor.byPair){ //i is a number(size_t); doc is the MongoDB document which we get get to JSON
			JSONValue p = parseJSON(doc.toJson().toString());
			list ~= p;
		}
		
		return list;
	}
	private const(JSONValue[]) readFile(const string file) {
		import std.file: readText, exists, isFile;
		import Utility: splitJson;
		//check on the local file; Local should ensure that the file is there: download from server
		if(!exists(file)) {
			throw new Exception("Reading a file which does not exists!");
		}
		if(!file.isFile) {
			throw new Exception("A file seems to be corrupted.");
		}
		auto fileContent = readText(file); //read local file
		
		JSONValue[] result;
		foreach (json; splitJson(fileContent)){
			result ~= parseJSON(json);
		}
		return result;
	}
	private void writeFile(const string file, const string buffer) {
		import std.file: write, exists, isFile;
		//checks on the local file; 
		if(!exists(file)) {
			throw new Exception("Writing to a file which does not exists.");
		}
		if(!file.isFile) {
			throw new Exception("Write to a file seems to be corrupted.");
		}
		file.write(buffer);
	}
	private void syncFile(idType)(const string collection, const string path) {
	
		import std.conv: to;
		
		auto file = readFile(path);
		
		foreach( ref json; file) { //for each JSONValue in the file
		
			Bson command = Bson.emptyObject;
			JSONValue j = json.toString.parseJSON; //duplicate json so j is mutable
			j.object.remove("status"); //this entry is not to be in the DB
			
			final switch(json["status"].str) {
			
				case "new":
					command["insert"] = collection;
					command["documents"] = [Bson.fromJson(Json(j))]; //converts JSONValue to vibe.Json to vibe.Bson
					break;
				case "update":
					command["update"] = collection;
					idType oldId;
					static if(is(idType : ulong)) {
						if(json["oldId"].type == JSON_TYPE.UINTEGER) oldId = json["oldId"].uinteger; //uinteger can represent unsigned integral which cannot be long
						else oldId = to!ulong(json["oldId"].integer); //integer catches all integral that can be long
					} 
					else if(is (idType : string)) oldId = json["oldId"].str;		//this static if is resolved at compile time
					else throw new SyncException(parseJSON("{}"), "undefined type for oldId");
					
					j.object.remove("oldId");
					command["updates"] = [Bson([
						"q" : Bson(["_id": Bson(oldId)]),
						"u" : Bson.fromJson(Json(j)) //this replace entirely the old document with this one
					])];
					break;
				case "remove":
					command["delete"] = collection;
					idType id;
					static if( is (idType : ulong)) {
						if(json["_id"].type == JSON_TYPE.UINTEGER) id = json["_id"].uinteger; 	//uinteger can represent unsigned integral which cannot be long
						else id = to!ulong(json["_id"].integer);
					}
					else if(is (idType : string)) id = json["_id"].str;			//this static if is resolved at compile time
					else throw new SyncException(parseJSON("{}"), "undefined type for id");
					command["deletes"] = [Bson([
						"q" : Bson(["_id" : Bson(id)]),
						"limit": Bson(0)
					])];
					break;
			}
			
			auto response = _mongoClient.getDatabase("officeManager").runCommand(command).toString.parseJSON;
			
			if(response["ok"].integer != 1) {
				throw new SyncException(response, "error syncing "~collection);
			}
		}
		
		writeFile(path, "");
	
	}
	
	private MongoClient _mongoClient = null;
	private MongoClient systemClient = null;
	private string _host = null;
	private immutable {
 		string projectsDB;
 		string categoriesDB;
 		string sessionsDB;
 	}
 	
 	static this() {
 		import LocalSide;
 		
 		projectsDB = SyncLocal.projectsSyncDB;
 		categoriesDB = SyncLocal.categoriesSyncDB;
 		sessionsDB = SyncLocal.sessionsSyncDB;

 	}
	
	void connect (const string host, const string user , const string password ) {
		//Local should call login to ensure user-password is correct
		_mongoClient = connectMongoDB("mongodb://"~ user ~":"~ password~ "@" ~host ~ "/officeManager?authMechanism=SCRAM-SHA-1");
		if( systemClient is null) systemClient = connectMongoDB("mongodb://officeManagerApp:askd.-23.asdIjfv@" ~host ~ "/officeManagerSystem?authMechanism=SCRAM-SHA-1");
		_host = host;
	}
	
	void disconnect() {
		
		if(_mongoClient !is null) _mongoClient.disconnect();
		_mongoClient = null;
		_host = null;
		if(systemClient !is null) systemClient.disconnect();
		systemClient = null;
	}
	
	bool isConnected() {
		return !(_mongoClient is null);
	}
	
	
//PROJECTS HANDLING-----------------------------------------------------------------------

	const(JSONValue[]) getProjects() {
		auto collection = _mongoClient.getCollection("officeManager.projects");
		auto cursor = collection.find(["archived": false]); //return a cursor; something strange see below how to handle it

		return cursorToJSONValue(cursor);
	}
	
	void syncProjects() {
		syncFile!ulong("projects", projectsDB);
	}

//----------------------------------------------------------------------------------------

//CATEGORIES HANDLING---------------------------------------------------------------------
	const(JSONValue[]) getCategories() {
		auto collection = _mongoClient.getCollection("officeManager.categories");
		auto cursor = collection.find(); //return a cursor; something strange see below how to handle it
	
		return cursorToJSONValue(cursor);
	}
	
	void syncCategories() {
		syncFile!string("categories", categoriesDB);
	}
	
//----------------------------------------------------------------------------------------

//SESSIONS HANDLING-----------------------------------------------------------------------
	const(JSONValue[]) getUserSessions(const string user) {
		auto collection = _mongoClient.getCollection("officeManager.sessions");
		auto cursor = collection.find(["user": Bson(user), "archived" : Bson(false)]); //return a cursor; something strange see below how to handle it
	
		return cursorToJSONValue(cursor);
	}
	
	const(JSONValue[]) getAllSessions() {
		//Local should ensure that this is called only by admin
		auto collection = _mongoClient.getCollection("officeManager.sessions");
		auto cursor = collection.find(["archived" : false]); //return a cursor; something strange see below how to handle it
	
		return cursorToJSONValue(cursor);
	}
	
	void syncSessions() {
		syncFile!ulong("sessions", sessionsDB);
	}

//----------------------------------------------------------------------------------------

//USER HANDLING---------------------------------------------------------------------------
	
	private string roleToDBrole(const string role) {
		//convert roles used by the app to the roles used in the MongoDB
		switch (role){
			case "Admin":
				return "officeManagerAdmin";
			case "User":
				return "officeManagerUser";
			default:
				throw new Exception("unkwon role");
		}
	}
	
	const(JSONValue) getPasswords(const string host = null) {
		//returns a JSON with entries user : { password: hashedpassword, role: hashedRole}
		//this is the remote version of the password file that LogIn uses
		if( systemClient is null ) {
			if( host is null)
				throw new Exception("no host to retrive passwords from; please specify one by connecting");
			systemClient = connectMongoDB("mongodb://officeManagerApp:askd.-23.asdIjfv@" ~host ~ "/officeManagerSystem?authMechanism=SCRAM-SHA-1");
		}
		
		auto collection = systemClient.getCollection("officeManagerSystem.passwords");
		auto cursor = collection.find();
		return cursorToJSONValue(cursor)[0];
	}
	
	const(JSONValue) changePassword(const string user, const string newPassword, const string newHash) {
		
		if(_mongoClient is null) {
			throw new Exception("please; connect and log in first");
		}
		
		auto bson = _mongoClient.getDatabase("officeManager").runCommand(["updateUser" : user, "pwd" : newPassword]);
		//bson is the server response as a Bson
		JSONValue response = parseJSON(bson.toString);
		
		if(response["ok"].integer != 1) { //not good
			return response;
		}
		//if response is ok need to update the passwords server; Local should handle the Local part
		Bson updateCommand = Bson(["update" : Bson("passwords")]);
		updateCommand["updates"] = [Bson( [ "q" : Bson.emptyObject , "u" : Bson( [ "$set": Bson([ (user~".pwd"): Bson(newHash)  ])  ])    ]  )]; //this is the wierd syntax required

		bson = systemClient.getDatabase("officeManagerSystem").runCommand(updateCommand);
		
		//otherwise all good
		return parseJSON(bson.toString);
		
	}
	
	const(JSONValue) createUser(const string userName, const string role, const string roleHash, const string password, const string passHash) {
		
		import std.stdio;
		
		if(_mongoClient is null) {
			throw new Exception("please; connect and log in first");
		}
		
		string dbrole = roleToDBrole(role);
		
		Bson command = Bson.emptyObject;
		command["createUser"] = Bson(userName);
		command["pwd"] = Bson(password);
		command["roles"] = [Bson(["role" : Bson(dbrole), "db" : Bson("officeManager")])];
			
		auto bson = _mongoClient.getDatabase("officeManager").runCommand(command);
		//bson is the server response as a Bson
		JSONValue response = parseJSON(bson.toString);
		
		if(response["ok"].integer != 1) { //not good
			writeln("######################## database did not created user");
			return response;
		}
		
		//if response is ok need to update the passwords server; Local should handle the Local part
		//this function update (or add) a pair user-hashedPassword in officeManagerSystem.passwords
		Bson updateCommand = Bson(["update" : Bson("passwords")]);
		updateCommand["updates"] = [Bson( [ "q" : Bson.emptyObject , "u" : Bson([ "$set": 
			Bson([ userName : 
				Bson(["role" : Bson(roleHash) , "pwd": Bson(passHash)  ]) 
				])
			])])]; //this is the wierd syntax required

		bson = systemClient.getDatabase("officeManagerSystem").runCommand(updateCommand);
		
		//otherwise all good
		return parseJSON(bson.toString);
		
	}
	
	const(JSONValue) deleteUser(const string user) {
		
		if(_mongoClient is null) {
			throw new Exception("please; connect and log in first");
		}
	
		Bson command = Bson([ "dropUser" : Bson(user)]);
		
		auto response = _mongoClient.getDatabase("officeManager").runCommand(command).toString.parseJSON;
		
		if(response["ok"].integer != 1) {//something didn't work
			return response;
		}
		
		//now update the password database
		command = Bson.emptyObject; //clear old command
		command = Bson(["update" : Bson("passwords")]);
		command["updates"] = [ Bson(["q" : Bson.emptyObject , "u" : Bson( [ "$unset" : Bson([user : Bson("")])])])];  //delete a field
		
		return systemClient.getDatabase("officeManagerSystem").runCommand(command).toString.parseJSON;		
	}
	
	const(JSONValue) changeRole(const string user, const string role, const string roleHash) {
	
		string dbrole = roleToDBrole(role);
		
		if(_mongoClient is null) {
			throw new Exception("please; connect and log in first");
		}
		
		Bson command = Bson(["updateUser" : Bson(user)]);
		command["roles"] = [ Bson( [ "role" : Bson(dbrole), "db" : Bson("officeManager") ] )  ];
		
		auto response = _mongoClient.getDatabase("officeManager").runCommand(command).toString.parseJSON;
		
		if(response["ok"].integer != 1 ) {
			return response;
		}
		
		//update password database
		
		command = Bson(["update" : Bson("passwords")]);
		command["updates"] = [ Bson( [ "q" : Bson.emptyObject, "u" : Bson([ "$set" : 
			Bson([ (user~".role") : Bson(roleHash) ])
		])])];
	
		return systemClient.getDatabase("officeManagerSystem").runCommand(command).toString.parseJSON;
	}
	
//----------------------------------------------------------------------------------------

}

class SyncException : Exception {
	const(string) message;
	const(JSONValue) error;
	this(JSONValue json ,string msg, string file = __FILE__, size_t line = __LINE__ ) { //constructor needs a message, and possible where the error is 
		error = json;
		message = msg;
		super(msg,file, line); //call constructor of Exception class
	}
}
