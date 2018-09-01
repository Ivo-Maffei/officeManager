module ServerProgram;

import std.concurrency: spawn;
import std.socket;
import Utility;
import std.string;
import MongoInteraction;
import std.json: JSONValue, parseJSON;

class Server {

	import std.conv: to;	
	
	private {
		ushort port;
		string mongoHost;
	}

	this(ushort newPort, string host) {
		port = newPort;
		mongoHost = host;
	}
	
	void start() {
		log("#### server started");
		this.listen();
	}

	private void listen() { //listen on port myPort
		auto socket = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
		socket.blocking = true;
		socket.bind(getAddress("localhost", port)[0]);//listen on this port
		socket.listen(0);
		log("#### server is listening on port "~ to!string(port));
		
		while(true) {
			//immutable(Socket) client = to!(immutable(Socket))(socket.accept());
			auto client = socket.accept();
			log("#### server received connection from " ~ to!string(client.remoteAddress));
			spawn(&handleConnection ,cast(shared) client , mongoHost);
		}
		
		/*scope(exit) {
			log("################################ stop listening");
		}*/
	}
	
	static private void handleConnection(shared Socket socket, const string host) {
		Socket client = cast() socket;
		
		auto buffer = new char[1024]; //max message is 1024 long
		long bytes = client.receive(buffer);
		string message = to!string(buffer[ 0 .. bytes]);
		log(to!string(client.remoteAddress) ~ " sent message: " ~ message);
		
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
					client.send("fail");
					break;
				}
				try{
					mongo.connect(user, password);
				} catch (Exception e) {
					log(user~" failed to connect to MongoDB error: "~to!string(e.msg));
					client.send("fail");
					break;
				}
				log(user ~ " connected to mongo");
				
				JSONValue[] list = [];
				if(args == "projects") list = mongo.getProjects();
				else if (args == "categories")  list = mongo.getCategories();
				log(user ~ " obtained "~ args ~ " from database");
				
				string result = "";
				foreach( ref j ; list) {
					result ~= j.toPrettyString~ "\n";
				}
					
				client.send(result);
				log("server sent "~ args~ " to "~ user);
				break;
			case "newSession":
				string args = message[at2+1 .. $]; //jsons of sessions
				
				string user = message[0 .. message.indexOf(":")];
				string password = null;
				try { password = getPassword(message ); }
				catch (Exception e) {
					log(user~ " failed to get password; error: "~to!string(e.msg));
					client.send("fail");
					break;
				}
				
				try{
					mongo.connect(user, password);
				} catch (Exception e) {
					log(user~" failed to connect to MongoDB error: "~to!string(e.msg));
					client.send("fail");
					break;
				}
				log(user ~ " connected to mongo");
				
				mongo.syncSessions(args);
				log(user ~ "'s' sessions synced");
				client.send("\n");
				break;
			case "registerDevice":
				string user = message[0 .. message.indexOf(":")];
				string password = message[message.indexOf(":")+1.. at1];
				string id = message[at2+1..$]; 
				//connect to MongoDB and update the user devices list
				try{
					mongo.connect(user, password);
				} catch (Exception e) {
					log(user~" failed to connect to MongoDB error: "~to!string(e.msg));
					client.send("fail");
					break;
				}
				//get local file of devices and update this one as well if update of MongoDB goes well
				try {
					auto device = newDevice(user, password, id);
					mongo.registerDevice(device);
				} catch (Exception e) {
					log(user ~" failed to add new device; error : " ~ to!string(e.msg));
					client.send("fail");
					break;
				}
				log(user ~ " device registered");
				client.send("OK");
				break;
			default: 
				log("#### unknown command received; It will be ignored. command: "~command );
		}
		
		mongo.disconnect();
		log("#### connection with "~to!string(client.remoteAddress)~" terminated");
		
	}
	
	static private const(string) newDevice(const string user, const string pass, const string device) { //return string to put on database
		import std.file: readText, write, thisExePath;
		import std.path: dirName;
		import crypto.aes: AES256, AESUtils;
		import std.base64: Base64;
		
		//log("#### crypting " ~ pass ~ "OK");
		//log("#### device is "~ device);
		//crypt password using device as key
		ubyte[] secret = cast(ubyte[]) (pass~"OK");
		ubyte[] crypted = AESUtils.encrypt!AES256(secret, device);
		const string stored = Base64.encode(crypted); //this is what should be stored
		//log("#### result is " ~ stored);
		auto file = dirName(thisExePath) ~ "/devices.db";
		auto json = parseJSON(readText(file));
		
		if((user in json.object) is null ) { //user is not in json
			string[] empty = [];
			json.object[user] = empty;
		}
	
		auto arr = json[user].array;
		arr ~= JSONValue(stored);
		json[user] = arr;
		
		write(file, json.toPrettyString);
		
		return stored;
	}
	
	static private string getPasswordFromId(const string user, const string device) {
		import std.file: readText, thisExePath;
		import std.path: dirName;
		import crypto.aes: AES256, AESUtils;
		import std.base64: Base64;
		
		auto file = dirName(thisExePath) ~ "/devices.db";
		auto json = parseJSON(readText(file));
		//log("#### devices json "~json.toString);
		foreach(ref j ; json[user].array ) {
			auto str = j.str;
			//log("#### crypted string : " ~ str);
			ubyte[] crypted = Base64.decode(str);
			//log("#### crypted bytes received");
			ubyte[] decrypted;
			try {
				AES256 aes = new AES256(cast(ubyte[])(device));
				//log("#### aes object initialised");
				decrypted = aes.decrypt(crypted);
			} catch(Exception e) {
				log("#### problem decrypting; " ~ to!string(e.msg));
			}
			//log("#### decryption done");
			string pass = cast (string) (decrypted);
			//log("#### decrypted string: " ~ pass);
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
}