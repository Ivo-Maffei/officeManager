module ServerProgram;

import std.concurrency: spawn;
import std.socket;
import Utility;
import std.string;
import MongoInteraction;
import std.json: JSONValue;

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
		log(to!string(client.remoteAddress) ~ " sent message: ", message);
		
		//now handle message
		//messages are of the form :
		// user:password@command@args [password is not required to get passwords]
		auto at1 = message.indexOf("@");
		auto at2 = message.indexOf("@", at1+1); 
		if(at2 == -1) at2 = message.length; //if no arguments, then go to end of string
		
		string command = message[at1+1 .. at2];
		auto mongo = new MongoTalk;
		mongo.initialise(host);
		
		final switch(command) {
			case "get":
				string args = message[at2+1 .. $]; //there must be arguments
				if(args != "passwords") {
					string user = message[0 .. message.indexOf(":")];
					string password = message[message.indexOf(":")+1 .. at1];
					mongo.connect(user, password);
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
					
				} else  { //arg == passwords
					string user = message[0.. at1];
					log(user ~": trying to get passwords");
					string response = mongo.getPasswords().toPrettyString;
					client.send(response);
					log("server sent passwords to "~ user);
				}
				break;
			case "newSession":
				string args = message[at2+1 .. $]; //jsons of sessions
				
				string user = message[0 .. message.indexOf(":")];
				string password = message[message.indexOf(":")+1 .. at1];
				mongo.connect(user,password); //login
				log(user ~ " connected to mongo");
				
				mongo.syncSessions(args);
				log(user ~ "'s' sessions synced");
				break;
		}
		
		mongo.disconnect();
		
	}
}