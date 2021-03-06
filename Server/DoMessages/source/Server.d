module ServerProgram;

import std.concurrency: spawn;
import core.thread: Thread;
import std.datetime: dur;
import std.file;
import std.regex;
import Utility;
import std.string;
import MongoInteraction;
import std.json: JSONValue, parseJSON;

class Server {

	import std.conv: to;	
	
	private {
		string path;
		string mongoHost;
		__gshared immutable {
			string otherProg = "1";
			string thisProg = "2"; //other program is 1; none is 0
		}
	}

	this(string p, string host) {
		path = p;
		mongoHost = host;
	}
	
	void start() {
		log("#### server started");
		this.listen();
		scope(exit) {
			log("#### server is stopping");
		}
	}

	private void listen() { //listen on port myPort
		log("#### program is watching files in "~ path);
		//ushort sleepCount = 0;
		auto exp = regex(r"connection([0-9])+\b");
		while(true) {
			Thread.getThis.sleep(dur!"seconds"(1));
			//look for new files
			auto entries = dirEntries(path,"connection*", SpanMode.shallow, false); //get all files starting with connection in the current directory (no subdirectories)
			foreach( DirEntry file; entries) { //check if there the connections are already open
				if( matchFirst(file.name, exp).empty) continue; //if it doesn't match; then it's not a socket
				string flag = file.name~"accepted";
				if( !flag.exists) {
					flag.write("1"); //accept connection
					spawn(&handleConnection, file, mongoHost, flag);
				}
			}
		}
		
		scope(failure) {
			log("################################ stop watching because of an error");
		}
	}	
	
	static private void handleConnection(const string file, const string host, const string accepted) {
	
		string lock = file~"lock"; //lock path
	
		while(true) {
			if(lock.readText == thisProg) break; //my turn
		}
		
		string message = file.readText;
		
		//now handle message
		//messages are of the form :
		// user:password@command@args [password and ":" are not required to get passwords]
		// user:id:deviceId@command@args [deviceId is a substitute for password when using mobiles]
		
		auto at1 = message.indexOf("@");
		auto at2 = message.indexOf("@", at1+1); 
		if(at2 == -1) at2 = message.length; //if no arguments, then go to end of string
		
		string command = message[at1+1 .. at2];
		auto mongo = new MongoTalk;
		mongo.initialise(host);
		
		switch(command) {
			case "get":
				string args = message[at2+1 .. $]; //there must be arguments
				string user = message[0 .. message.indexOf(":")];
				string password = null;
				try { password = getPassword(message ); }
				catch (Exception e) {
					log(user~ " failed to get password; error: "~to!string(e.msg));
					file.write("fail");
					break;
				}
				try{
					mongo.connect(user, password);
				} catch (Exception e) {
					log(user~" failed to connect to MongoDB error: "~to!string(e.msg));
					file.write("fail");
					break;
				}
				log(user ~ " connected to mongo");
				
				JSONValue[] list = [];
				if(args == "projects") list = mongo.getProjects();
				else if (args == "categories")  list = mongo.getCategories();
				else {
					log(user ~" asked for unknown argument "~args);
					file.write("fail");
				}
				log(user ~ " obtained "~ args ~ " from database");
				
				string result = "";
				foreach( ref j ; list) {
					result ~= j.toPrettyString~ "\n";
				}
					
				file.write(result);
				log("server sent "~ args~ " to "~ user);
				break;
			case "newSession": 
				string args = message[at2+1 .. $]; //jsons of sessions
				
				string user = message[0 .. message.indexOf(":")];
				string password = null;
				try { password = getPassword(message ); }
				catch (Exception e) {
					log(user~ " failed to get password; error: "~to!string(e.msg));
					file.write("fail");
					break;
				}
				
				try{
					mongo.connect(user, password);
				} catch (Exception e) {
					log(user~" failed to connect to MongoDB error: "~to!string(e.msg));
					file.write("fail");
					break;
				}
				log(user ~ " connected to mongo");
				
				mongo.syncSessions(args);
				log(user ~ "'s sessions synced");
				file.write("\n");
				break;
			case "registerDevice": //user:password@registerDevice@deviceName@deviceID
				string user = message[0 .. message.indexOf(":")];
				string password = message[message.indexOf(":")+1.. at1];
				auto at3 = message.indexOf("@", at2+1);
				string name = message[at2+1.. at3]; 
				string id = message[at3+1 .. $];
				//connect to MongoDB and update the user devices list
				try{
					mongo.connect(user, password);
				} catch (Exception e) {
					log(user~" failed to connect to MongoDB error: "~to!string(e.msg));
					file.write("fail");
					break;
				}
				log(user~" connected to MongoDB");
				try {
					auto dev = mongo.getDevices();
					updateDevices(dev);
				} catch (Exception e){
					log(user ~ " server tried to sync devices and failed; error : " ~ to!string(e.msg));
					file.write("fail");
					break;
				}
				log("#### updated devices list");
				
				//get local file of devices and update this one as well if update of MongoDB goes well
				try {
					auto device = newDevice(user, password, id);
					mongo.registerDevice(device, name);
				} catch (Exception e) {
					log(user ~" failed to add new device; error : " ~ to!string(e.msg));
					file.write("fail");
					break;
				}
				log(user ~ " device registered");
				file.write("OK");
				break;
			default: 
				log("#### unknown command received; It will be ignored. command: "~command );
		}
		
		mongo.disconnect();
		
		accepted.remove(); //we close this conncetion
		log("#### connection with "~file~" terminated");
		
		lock.write(otherProg); //other program turn
		
	}
	
	static private const(string) newDevice(const string user, const string pass, const string device) { //return string to put on database
		import std.file: readText, write, thisExePath;
		import std.path: dirName;
		import Crypt;
		
		log(user~" crypting new device");
		
		//log("#### crypting " ~ pass ~ "OK");
		//log("#### device is "~ device);
		//crypt password~"OK" using device as key
		string crypted = AESencrypt(device,pass~"OK");
		//log("#### result is " ~ stored);
		auto file = dirName(thisExePath) ~ "/devices.db";
		auto json = parseJSON(readText(file));
		
		if((user in json.object) is null ) { //user is not in json
			string[] empty = [];
			json.object[user] = empty;
		}
	
		auto arr = json[user].array;
		foreach (ref j ; arr) {
			if( crypted == j.str) return crypted; //no need to add to local file
		}
		arr ~= JSONValue(crypted);
		json[user] = arr;
		
		write(file, json.toPrettyString);
		
		log(user~" crypting done");
		return crypted;
	}
	
	static private string getPasswordFromId(const string user, const string device) {
		import std.file: readText, thisExePath;
		import std.path: dirName;
		import Crypt;
		
		auto file = dirName(thisExePath) ~ "/devices.db";
		auto json = parseJSON(readText(file));
		
		//log("#### devices json "~json.toString);
		foreach(ref j ; json[user].array ) {
			auto str = j.str;
			string pass = "fail"; //anything that does not end with "OK"
			try{
				pass = AESdecrypt(device, str);
			} catch (Exception e) {
				log(user ~" problem decrypting: "~e.msg); //likely that pad is wrong because password is wrong
				continue;
			}
			if(pass[$-2 .. $] == "OK") { //then we are good
				return pass[0 .. $-2];
			}
		}
		
		throw new Exception("device seems not to be registered for the specified user");
	}
	
	static private string getPassword(const string message) {
		import std.algorithm.searching: canFind;
		
		bool id = message.canFind(":id:"); //using device id or password
		string user = message[0 .. message.indexOf(":")];
				
		string password = "";
		if(id) {
			auto index = message.indexOf(":");
			string device = message[message.indexOf(":",index+1) +1 .. message.indexOf("@")];
			log(user ~ " retrieving password from device id: " ~ device);
			try {
				password = getPasswordFromId(user, device ); 
			} catch (Exception e) {
				throw e;
			}
		} else password = message[message.indexOf(":")+1 .. message.indexOf("@")];
		
		return password;
	}
	
	static private void updateDevices(JSONValue[] jsons) {
		import std.file: write, thisExePath;
		import std.path: dirName;
		
		JSONValue my = parseJSON("{}");
		string[] empty = [];		
		foreach(ref json; jsons) {
			string user = "";
			string[] arr = [];
			foreach(string key , ref value; json) {
				if(key == "_id") { //add the key with user to my
					user = value.str;
					my.object[user] = empty;
					continue;
				}
				arr ~= value.str;
			}
			my[user] = arr;
		}
		
		auto file = dirName(thisExePath) ~ "/devices.db";
		write(file, my.toPrettyString);
		
	}
}
