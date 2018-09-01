module MongoInteraction;

import vibe.db.mongo.mongo;
import vibe.db.mongo.client;
import vibe.data.json;
import std.json;
import Utility;

class MongoTalk {

	private {
		MongoClient _mongoClient = null;
		MongoClient systemClient = null;
		string host = null;
		string myUser = "none";
	}

	private JSONValue[] cursorToJSONValue(T) ( MongoCursor!T cursor ) {
	
		import std.array: byPair;
		
		JSONValue[] list;
		
		foreach (i, doc; cursor.byPair){ //i is a number(size_t); doc is the MongoDB document which we get get to JSON
			JSONValue p = parseJSON(doc.toJson().toString());
			list ~= p;
		}
		
		return list;
	}
	
	//settings and connections
	void initialise(const string _host) {
		host = _host;
	}
	
	void connect (const string user , const string password ) {
		//Local should call login to ensure user-password is correct
		_mongoClient = connectMongoDB("mongodb://"~ user ~":"~ password~ "@" ~host ~ "/officeManager?authMechanism=SCRAM-SHA-1");
		myUser = user;
		log("connected to MongoDB using user " ~ user);
		
	}

	void disconnect() {
		if(_mongoClient !is null) _mongoClient.disconnect();
		_mongoClient = null;
		host = null;
		log(myUser ~ ": disconnected from MongoDB");
	}
	
	//get info from database (only the ones that app requires)
	JSONValue[] getProjects() {
		auto collection = _mongoClient.getCollection("officeManager.projects");
		auto cursor = collection.find(["archived": false]); //return a cursor; something strange see below how to handle it
		log(myUser ~ ": retrieved projects info");
		return cursorToJSONValue(cursor);
	}
	
	JSONValue[] getCategories() {
		auto collection = _mongoClient.getCollection("officeManager.categories");
		auto cursor = collection.find(); //return a cursor; something strange see below how to handle it
		log(myUser ~ ": retrieved categories info");
		return cursorToJSONValue(cursor);
	}
	
	/*const(JSONValue) getPasswords() {
		//returns a JSON with entries user : { password: hashedpassword, role: hashedRole}
		//this is the remote version of the password file that LogIn uses
		if( systemClient is null ) {
			if( host is null) throw new Exception("no host to retrive passwords from; please specify one by connecting");
			systemClient = connectMongoDB("mongodb://officeManagerApp:askd.-23.asdIjfv@" ~host ~ "/officeManagerSystem?authMechanism=SCRAM-SHA-1");
		}
		
		auto collection = systemClient.getCollection("officeManagerSystem.passwords");
		auto cursor = collection.find();
		log(myUser ~ ": retrieved passwords info");
		return cursorToJSONValue(cursor)[0];
	}*/
	
	//sync sessions
	void syncSessions(const string content) {
		
		log(myUser ~ ": syncing sessions");
		
		auto jsonStrings = splitJson(content);
		
		Bson command = Bson.emptyObject;
		command["insert"] = "sessions";
		Bson[] documents = [];
		
		foreach( ref json; jsonStrings) { //for each JSONValue in the file
			
			JSONValue j = parseJSON(json); 
			j.object.remove("status"); //this entry is not to be in the DB and is always "new" for mobile
			
			documents ~= Bson.fromJson(Json(j)); //converts JSONValue to vibe.Json to vibe.Bson
			
		}
		
		command["documents"] = documents;
		
		auto response = _mongoClient.getDatabase("officeManager").runCommand(command).toString.parseJSON;
			
		log(myUser ~ ": serverResponse: " ~ response.toString);
		
		if(response["ok"].integer != 1) {
			throw new Exception(response.toString ~ " error syncing sessions");
		}
		
	}
	
	void registerDevice( const string device) { //device is the encryption of password with key the device UUID
		
		log(myUser ~ " is registering a device with cryped id : " ~ device);
		
		Bson command = Bson.emptyObject;
		command["update"] = "passwords";
		command["updates"] = [Bson( [
			"q" : Bson.emptyObject,
			"u" : Bson( [ "$addToSet" : Bson([ (myUser~".devices") : Bson(device) ])])
		])];
		
		if( systemClient is null ) {
			if( host is null) throw new Exception("no host to retrive passwords from; please specify one by connecting");
			systemClient = connectMongoDB("mongodb://officeManagerApp:askd.-23.asdIjfv@" ~host ~ "/officeManagerSystem?authMechanism=SCRAM-SHA-1");
		}
		
		auto response = systemClient.getDatabase("officeManagerSystem").runCommand(command).toString.parseJSON;
	
		if( response["ok"].integer != 1) {
			throw new Exception(response.toString);
		}
	}
	
}