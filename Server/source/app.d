import std.stdio;
import std.getopt;
import std.conv: to;
import ServerProgram;
import Utility;

void main(string[] args){

	ushort port = 27017; //port to make the server listen to
	string host = null; //address of the mongo database
	string logFile = null; //path of the file where to print the log
	
	auto info = getopt(args, "port|p", &port, "db|d", &host, "log|l", &logFile);
	
	if(info.helpWanted) {
		foreach(ref op; info.options) {
			//writeln(op.optLong);
			final switch(op.optLong) {
				
				case "--port":
					op.help ="port this server will listen to";
					break;
				case "--db":
					op.help = "address of the MongoDB to use";
					break;
				case "--log":
					op.help = "path of the log file";
					break;
				case "--help":
					op.help = "shows this message";
					break;
			}
		}
		defaultGetoptPrinter("options: ", info.options);
		return;
	}
	
	writeln("port: ", port, " db: ", host, " log: ", logFile);

	log("########################### Application is started", logFile);
	log("########################### arguments:");
	log("########################### port: "~ to!string(port) ~ ", db: " ~ host ~", log: "~ logFile);
	
	auto server = new Server(port, host);
	server.start();
	
}
