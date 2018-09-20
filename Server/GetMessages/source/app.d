import std.stdio;
import std.getopt;
import std.conv: to;
import std.file: isDir, exists;
import Utility;
import ServerProgram;

void main(string[] args){

	ushort port = 27017; //port to make the server listen to
	string logFile = ""; //path of the file where to print the log
	string path = "";
	
	/*auto info = getopt(args, "port|p", &port ,"folder|f", &path , "log|l", &logFile);
	
	if(info.helpWanted) {
		foreach(ref op; info.options) {
			//writeln(op.optLong);
			final switch(op.optLong) {
				
				case "--port":
					op.help ="port this server will listen to";
					break;
				case "--log":
					op.help = "path of the log file";
					break;
				case "--folder":
					op.help = "path of the folder where the shared files are";
					break;
				case "--help":
					op.help = "shows this message";
					break;
			}
		}
		defaultGetoptPrinter("options: ", info.options);
		return;
	}*/
	
	import std.file: thisExePath, readText;
	import std.path: dirName;
	
	string here = dirName(thisExePath);
	string config = here~"/settings.conf";
	
	import std.json;
	
	auto settings = config.readText.parseJSON;
	port = to!ushort(settings["port"].integer);
	logFile = settings["log"].str;
	path = settings["sharedFolder"].str;
	
	
	
	writeln("port: ", port, " folder: ", path, " log: ", logFile);
	if(path[0] != '/' || path[$] != '/' || !path.exists || !path.isDir) {
		throw new Exception("invalid path format");
	}
	log("########################### Application is started", logFile);
	log("########################### arguments:");
	log("########################### port: "~ to!string(port) ~", folder: "~path ~ ", log: "~ logFile);
	
	
	auto server = new Server(port, path);
	server.start();
	
	scope (exit) {
		log("#### program shutting down");
	}
}
