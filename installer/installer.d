//simple installer to set important settings right before launching 
//officeManager

import std.stdio: writeln, readln;
import std.getopt;
import core.thread: Thread;
import std.datetime: dur;
import std.json;
import std.conv: to;

void main(string[] args) {

	bool quick = false;
	auto info = getopt(args, "qick|q", &quick);

	writeln("This is a quick setup to help you get the correct start with officeManager");
	if(!quick){
	writeln("First of all we will configure a few functionalities");
	writeln("Checking computer environment...");
	Thread.getThis().sleep(dur!"seconds"(2));
	writeln("There is something wrong... This may take a while");
	Thread.getThis().sleep(dur!"seconds"(1));
	writeln("Repairing environment... ");
	Thread.getThis().sleep(dur!"seconds"(2));
	writeln("Expected time left: 10h 23min");
	Thread.getThis().sleep(dur!"seconds"(10));
	writeln("Ahahah :-D you fool!");
	writeln("This setup is gonna be much quicker!");
	}
	
	writeln("Fist of all I need to know where is the MongoDB");
	writeln("Write an IP address like: 127.0.0.1; If the database port is not the default one (27017) add the port at the end like this: 127.0.0.1:27017");
	string response = readln();
	handleResponse!"IP"(response);
	
	writeln("Now you need to tell me 2 IP ports that nobody is using on this machine");
	writeln("officeManager will use those ports to comunicate within its components");
	writeln("now write the first port");
	response = readln();
	handleResponse!"port1"(response);

	writeln("now write the second port");
	response = readln();
	handleResponse!"port2"(response);
	
	writeln("Great the setup is done!");
	writeln("Now you can start officeManger and all settings should be correct!");
}

void handleResponse(string type) (string response){
	import std.file: thisExePath, readText, write;
	import std.path: dirName;

	writeln("this is your response : ", response[0..$-1]);
	writeln("if you are not happy with that, then just close me and start again using the flag -q");
	
	string file= dirName(thisExePath)~"/Resources/settings";
	auto json= parseJSON(readText(file));
	final switch(type) {
		case "IP":
			json["host"] = response[0..$-1];//drop the last character which is \n
			break;
		case "port1":
			json["menuBarPort"] = to!ushort(response[0..$-1]);
			break;
		case "port2":
			json["OMPort"] = to!ushort(response[0..$-1]);
			break;
	}
	write(file, json.toPrettyString);
}
