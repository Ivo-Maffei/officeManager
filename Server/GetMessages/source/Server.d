module ServerProgram;

import std.concurrency: spawn;
import std.socket;
import Utility;
import std.string;
import std.file;
import std.datetime.systime : SysTime, Clock;

class Server {

	import std.conv: to;	
	
	private {
		ushort port;
		string path; //must end with /
		__gshared immutable {
			string thisProg = "1"; //other program is 2; none is 0
			string otherProg = "2";
		}
	}

	this(ushort newPort, string p) {
		port = newPort;
		path = p; //path where files to write are located
	}
	
	void start() {
		log("#### server started");
		this.listen();
		scope(exit) {
			log("#### server is stopping");
		}
	}

	private void listen() { //listen on port myPort
		auto address = getAddress("localhost", port)[0];
		auto socket = new Socket(address.addressFamily, SocketType.STREAM, ProtocolType.TCP);
		socket.blocking = true;
		socket.bind(address);//listen on this port
		socket.listen(0);
		log("#### server is listening on port "~ to!string(port));
		
		while(true) {
			//immutable(Socket) client = to!(immutable(Socket))(socket.accept());
			auto client = socket.accept();
			log("#### server received connection from " ~ to!string(client.remoteAddress));
			spawn(&handleConnection,cast(shared) client, path);
		}
		
		scope(failure) {
			log("################################ stop listening because of an error");
		}
	}
	
	static private void handleConnection(shared Socket sock, const string path) {
		Socket client = cast() sock;
		
		auto buffer = new char[1024]; //max message is 1024 long
		long bytes = client.receive(buffer);
		string message = to!string(buffer[ 0 .. bytes]);
		log(to!string(client.remoteAddress) ~ " sent message: " ~ message);
		
		//now connect to other LXC via file
		ulong currentTime = Clock.currTime().stdTime;
		string connection = path~"connection"~to!string(currentTime); //connection file
		string lock = connection~"lock"; //lock for connection
		
		lock.write(thisProg); //create lock and acquire it
		connection.write(message); //create connection file and write message
		log("#### message written to "~connection);
		lock.write(otherProg); //set lock to other program
		
		while(true) {
			if(lock.readText == thisProg) break; //wait for a reply
		}
		log("### received a reply on "~connection);
		
		client.send(connection.readText);
		log("#### response sent to "~to!string(client.remoteAddress)~": "~connection.readText);
		
		connection.remove(); //delete connection
		lock.remove(); //delete lock
		log("#### deleted "~connection~" and "~lock);
	
		log("#### connection with "~to!string(client.remoteAddress)~" terminated");
		
	}
	
}