module Utility;

//get path of the executable file
const(string) getCurrentPath(){
	import std.file: thisExePath;
	import std.path: dirName;
	
	return (dirName(thisExePath)~"/");
	
}