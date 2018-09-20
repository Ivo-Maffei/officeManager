module Utility;

void log(const string message, const string logFile = null) {

	import std.file: append;
	import std.datetime.systime: Clock;
	
	
	static __gshared string file = null; //we always use this file; 

	if( logFile !is null) { //set logFile
		file = logFile; 
	}
	
	append(file, Clock.currTime.toISOExtString ~ " @ " ~ message~"\n");

}