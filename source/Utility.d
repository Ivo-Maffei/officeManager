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