module Utility;

//split a string into a list of its json components;
//it is not checked that the json have correct internal syntax
const(string[]) splitJson(const string s) {
	string[] result;
	uint depth =0;
		
	string json =""; //comulative json
		
	foreach( c ; s ) {//go through characters
		
		if( c == '{') ++depth;
		if(depth != 0) json ~= c;
		if( c == '}') --depth;
		if(depth == 0 && json != "") {
			result ~= json;
			json = "";
		}
	}
	return result;
}

void log(const string message, const string logFile = null) {

	import std.file: append;
	import std.datetime.systime: Clock;

	static string file = null; //we always use this file; 
	
	if( logFile !is null) { //set logFile
		file = logFile; 
	}
	
	append(file, Clock.currTime.toISOExtString ~ " @ " ~ message~"\n");

}