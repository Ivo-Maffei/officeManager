module ServerSide;

import vibe.db.mongo.mongo;
import vibe.db.mongo.client;
import vibe.data.json;
import std.json; //nicer than vibe.data.json and to use when interfacing with Local

import std.array: byPair;

class SyncServer {

static:

	private JSONValue[] cursorToJSONValue(T) ( MongoCursor!T cursor ) {
		JSONValue[] list;
		
		foreach (i, doc; cursor.byPair){ //i is a number(size_t); doc is the MongoDB document which we get get to JSON
			JSONValue p = parseJSON(doc.toJson().toString());
			list ~= p;
		}
		
		return list;
	}
	
	private MongoClient _mongoClient = null;
	private MongoClient systemClient = null;
	
	private string _host = null;
	
	void connect (const string host, const string user , const string password ) {
		//Local should call login to ensure user-password is correct
		_mongoClient = connectMongoDB("mongodb://"~ user ~":"~ password~ "@" ~host ~ "/officeManager?authMechanism=SCRAM-SHA-1");
		if( systemClient is null) systemClient = connectMongoDB("mongodb://officeManagerApp:askd.-23.asdIjfv@" ~host ~ "/officeManagerSystem?authMechanism=SCRAM-SHA-1");
		_host = host;
	}
	
	void disconnect() {
		_mongoClient = null;
		_host = null;
		systemClient = null;
	}
	
	
//PROJECTS HANDLING-----------------------------------------------------------------------

	const(JSONValue[]) getProjects() {
		auto collection = _mongoClient.getCollection("officeManager.projects");
		auto cursor = collection.find(["archived": false]); //return a cursor; something strange see below how to handle it

		return cursorToJSONValue(cursor);
	}

//----------------------------------------------------------------------------------------

//CATEGORIES HANDLING---------------------------------------------------------------------
	const(JSONValue[]) getCategories() {
		auto collection = _mongoClient.getCollection("officeManager.categories");
		auto cursor = collection.find(); //return a cursor; something strange see below how to handle it
	
		return cursorToJSONValue(cursor);
	}
	
//----------------------------------------------------------------------------------------

//SESSIONS HANDLING-----------------------------------------------------------------------
	const(JSONValue[]) getUserSessions(const string user) {
		auto collection = _mongoClient.getCollection("officeManager.sessions");
		auto cursor = collection.find(["user": user]); //return a cursor; something strange see below how to handle it
	
		return cursorToJSONValue(cursor);
	}
	

	const(JSONValue[]) getAllSessions() {
		//Local should ensure that this is called only by admin
		auto collection = _mongoClient.getCollection("officeManager.sessions");
		auto cursor = collection.find(); //return a cursor; something strange see below how to handle it
	
		return cursorToJSONValue(cursor);
	}

//----------------------------------------------------------------------------------------

//USER HANDLING---------------------------------------------------------------------------

	private const(JSONValue) changeHashedPassword( const string user, const string newHash) {
		//this function update (or add) a pair user-hashedPassword in officeManagerSystem.passwords
		Bson updateCommand = Bson(["update" : Bson("passwords")]);
		updateCommand["updates"] = [Bson( [ "q" : Bson.emptyObject , "u" : Bson( [ "$set": Bson([ user: Bson(newHash)  ])  ])    ]  )]; //this is the wierd syntax required

		Bson bson = systemClient.getDatabase("officeManagerSystem").runCommand(updateCommand);
		
		//otherwise all good
		return parseJSON(bson.toString);
	}
	
	const(JSONValue) getPasswords(const string host = null) {
		//returns a JSON with entries user : hashedpassword
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
		return changeHashedPassword(user,newHash);
		
	}
	
	const(JSONValue) createUser(const string userName, const string role, const string newPassword, const string newHash) {
		
		if(_mongoClient is null) {
			throw new Exception("please; connect and log in first");
		}
		
		string dbrole;
		switch (role){
			case "Admin":
				dbrole = "officeManagerAdmin";
				break;
			case "User":
				dbrole = "officeManagerUser";
				break;
			default:
				throw new Exception("unkwon role");
		}
		
		Bson command = Bson.emptyObject;
		command["createUser"] = Bson(userName);
		command["pwd"] = Bson(newPassword);
		command["roles"] = [Bson(["role" : Bson(dbrole), "db" : Bson("officeManager")])];
			
		auto bson = _mongoClient.getDatabase("officeManager").runCommand(command);
		//bson is the server response as a Bson
		JSONValue response = parseJSON(bson.toString);
		
		if(response["ok"].integer != 1) { //not good
			return response;
		}
		
		//if response is ok need to update the passwords server; Local should handle the Local part
		return changeHashedPassword(userName,newHash);
		
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

	
//----------------------------------------------------------------------------------------

}