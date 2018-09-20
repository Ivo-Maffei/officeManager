import std.stdio;
import std.conv: to;
import ServerProgram;
import Utility;

void main(string[] args){

	string host = ""; //address of the mongo database
	string logFile = ""; //path of the file where to print the log
	string path = "";
	
	/*auto info = getopt(args, "folder|f", &path, "db|d", &host, "log|l", &logFile);
	
	if(info.helpWanted) {
		foreach(ref op; info.options) {
			//writeln(op.optLong);
			final switch(op.optLong) {
				case "--db":
					op.help = "address of the MongoDB to use";
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
	}
	*/
	
	import std.file: thisExePath, readText;
	import std.path: dirName;
	
	string here = dirName(thisExePath);
	string config = here~"/settings.conf";
	
	import std.json;
	
	auto settings = config.readText.parseJSON;
	host = settings["databaseIP"].str;
	logFile = settings["log"].str;
	path = settings["sharedFolder"].str;
	
	writeln( "folder: ", path, " db: ", host, " log: ", logFile);

	log("########################### Application is started", logFile);
	log("########################### arguments:");
	log("########################### db: " ~ host ~", log: "~ logFile ~", folder: "~path);
	
	auto server = new Server(path, host);
	server.start();
	
	scope (exit) {
		log("#### program shutting down");
	}
}

