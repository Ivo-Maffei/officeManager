module Utility;
/*
	Some common use functions
*/

//get path of the executable file
const(string) getCurrentPath(){
	import std.file: thisExePath;
	import std.path: dirName;
	
	return (dirName(thisExePath)~"/Resources/");
	
}

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

//takes a string containning a json and returns an array containing all the entries of the json
//json syntax is not checked; to avoid undefined behaviour make sure json syntax is  correct
const(string[]) jsonEntries(const string s) {
	string[] result;
	
	bool key = true; //indicates if the next json piece of data is a key or a value
	bool escapeChar = false; //indicates if we saw \ and so we do not interpret the next "
	bool insideString = false; //indicates if we opened a strig "  and we still need to close it
	string entry = "";
	uint depth =0; //indicates depth of nested JSON, we want only depth 1
	foreach( ref c ; s) {
	
		if( c == '{') ++depth;
		if( c == '}') --depth;
		if (c == ':') key = false;
		else if(c == ',') key = true;
		if( !key ) continue;//we don't care about the values
	
		if( c == '\"') { //this can be open, close or \"
			if( escapeChar && depth == 1) entry ~= c;
			else insideString = !insideString; //we are opening/closing a string
		} else if( insideString && depth == 1) entry ~= c;
		
		
		if(!insideString && entry != "") { //we have closed an entry
			result ~= entry;
			entry ="";
		}
		
		if( c =='\\' && !escapeChar) escapeChar = true; //if there was no escapeChar, now there is one
		else if (escapeChar) escapeChar = false;  //if there was an escapeChar, now is no more valid

	}
	
	return result;

}