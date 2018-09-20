module MenuBar;

import std.stdio;
import std.json;
import dlangui;
import Local: Local;
import UIActionHandlers: error;

class MenuBarInteraction {
	//all messages must be of the form:
	// commmand@arg1__arg2__arg3 ...
	// if no argument is required then @ can be omitted
	
	import std.socket;
	import std.concurrency;
	import std.stdio;
	import Utility: getCurrentPath;
	
	static:
	
	private {
	__gshared{
		string message = null; 
		bool received = false;
		bool menuBarRunning = false;
		bool listening = false;
	}
		Tid receiveTid, swiftTid;
		Window window = null;
		ushort menuBarPort = 2121;
		ushort myPort = 2122;
		bool ignoreNextInput = false;
		Address myPosition;
	}
	
	
	static this() {
		myPosition = new UnknownAddress; 
	}
	void setWindow (Window win) {
		window = win;	
	}
	
	bool isMenuBarRunning() {
		return menuBarRunning;
	}
	
	void start() {
		getSettings();
		receiveTid = spawn(&listen, myPort);
		swiftTid = spawn(&launchMenuBar);
		//writeln("################### listening is : ", listening);
	}
	
	void update() {
		if( received) {
			writeln(receive);
		}
	}
	
	void quit() {

		if(menuBarRunning) {
			send("quit"); //sends quit to menuBar
			//return; //menu bar will reply with a quit as well
		}
		
		//if(!listening) return;
		
		writeln("############################ sending quit to self");
		Socket socket;
		socket = new Socket(myPosition.addressFamily, SocketType.STREAM, ProtocolType.TCP);
		socket.blocking = true;
		try {
			socket.connect(myPosition);
		} catch (SocketOSException ex) {
			writeln("############################## exception port for this program: ", ex.msg);
			return;
		}
		socket.send("quit");//sends quit to listen process
		
	}
	
	void changeProjects() {
		//to call when there is some changes with the projects
		if(ignoreNextInput) {
			ignoreNextInput = false;
			return;
		}
		if(menuBarRunning) send("update");
	}
	
	void startSession(string projName ) {
		//to call when a new session is started
		if(ignoreNextInput) {
			ignoreNextInput = false;
			return;
		}
		if(menuBarRunning) send("start@"~projName);
	}
	
	void startSession(ulong projID) {
		startSession( Local.getProject(projID).name);
	} 
	
	void stopSession(string projName) {
		//to call when a session is stopped
		if(ignoreNextInput) {
			ignoreNextInput = false;
			return;
		}
		if(menuBarRunning) send("stop@"~projName);
	}
	
	void stopSession(ulong projID) {
		stopSession( Local.getProject(projID).name);
	}
	
	private void getSettings() {
		
		import Utility: getCurrentPath;
		import std.file: readText;
		import std.json;
		
		auto file =  getCurrentPath ~ "settings";
		auto json = parseJSON(readText(file));
	
		myPort = to!ushort(json["OMPort"].integer);
		menuBarPort = to!ushort(json["menuBarPort"].integer);
	
		myPosition = getAddress("localhost", myPort)[0];	
	}
	
	private void launchMenuBar() {
		import Utility: getCurrentPath;
		import std.process: executeShell; 
		import std.algorithm.searching: canFind;
		
		string program = getCurrentPath()~"MenuBarOfficeManager.app/Contents/MacOS/MenuBarOfficeManager";
		menuBarRunning = true;
		auto output = executeShell(program);
		if( canFind(output.output, "error") || output.status != 0) {
			throw new Exception("Cannot execute properly the menu bar program");
		}
		menuBarRunning = false;
	}
	
	private void listen(ushort port) { //listen on port myPort
		Socket socket =  new Socket(myPosition.addressFamily, SocketType.STREAM, ProtocolType.TCP);
		writeln("############################# socket created");
		socket.blocking = true;
		try {
			socket.bind(myPosition);
		} catch (Exception e) {
			writeln("######################## exception when binding address ", e.msg);
			throw e;
		}
		writeln("################################ server on port: ", port);
		writeln("################################ server on address: ", myPosition.toString);
		socket.listen(0);
		writeln("########################## listen ok");
		listening = true;
		while(true) {
			auto client = socket.accept();
			//writeln("############################# local address ", client.localAddress);
			//writeln("############################# remote address ", client.remoteAddress);
			auto buffer = new char[1024]; //max message is 1024 long
			long bytes = client.receive(buffer);
			message = to!string(buffer[ 0 .. bytes]);
			writeln("########################## message ", message);
			if(message == "quit" ) break;
			received = true;	
		}
		
		scope(exit) {
			writeln("################################ stop listening");
			listening = false;
		}
		scope(failure) {
			writeln("######################################## failed to listen");
			listening = false;
		}
	}
	
	private string receive() {
		writeln("######################## received message ");
		if(!received) return "nothing";
		else {
			received = false;
			handleMessage();
			return message;
		}
	}
	
	private void send(string msg) { //sends message on port for menu bar
		writeln("########################### seding ", msg);
		auto address = getAddress("localhost", menuBarPort)[0];
		Socket send;
		send = new Socket(AddressFamily.INET6, SocketType.STREAM, ProtocolType.TCP);
		send.blocking = true;
		int i =0;
		try {
			send.connect(address);
		} catch (SocketOSException ex) {
			writeln("################################# exception connecting to menu bar: ", ex.msg);
			writeln("################################# now trying ipv4");
			send = new Socket(AddressFamily.INET, SocketType.STREAM, ProtocolType.TCP);
			
			try{
				send.connect(address);
			} catch (SocketOSException e) {
				writeln("################################# exception connecting to menu bar with ipv4: ", e.msg);
				return;
			}
			
		}
		
		for(; i< 20; ++i) {
			auto result = send.send(msg);
			if(result != Socket.ERROR && result == msg.length) {
				break;
			}
		}
		
		if(i == 20) {
			error("MenuBar is not responding properly: cannot send them a message", window);
			return;
		}
	}
	
	private void handleMessage() {
		//do something according to what you receive
		import std.string : indexOf;
		import std.algorithm.searching: canFind;
		
		string command = message.indexOf("@") == -1 ? message : message[ 0 .. message.indexOf("@")];
		
		Widget main = window.mainWidget;
		
		switch (command) {
			case "quitAll" : 
				window.close();
				break;
			case "start" :
				string projName = message[message.indexOf("@")+1 .. $];
				Button btn = main.childById!Button("playbtn");
				if( btn !is null){ //this is normalUI
					auto projBox = main.childById!ComboBox("projdd");
					auto catBox = main.childById!ComboBox("catdd");
					catBox.selectedItemIndex = 0;
					for(int i =0; i<projBox.items.length; ++i) {
						string title = to!string(projBox.items[i].value);
						if(title.canFind(projName)) {
							projBox.selectedItemIndex = i;
							break;
						}
					}
					ignoreNextInput = true;
				 	btn.simulateClick();
				}
				else Local.startSession(Local.getProjectId(projName));
				break;
			case "stop" :
				string projName = message[message.indexOf("@")+1 .. $];
				Button btn = main.childById!Button("playbtn");
				if( btn !is null && btn.text == "Stop Session"d){ //this is normalUI and button will stop the session
					ignoreNextInput = true;
				 	btn.simulateClick();
				}
				else Local.stopSessionByProject(Local.getProjectId(projName));
				break;
			default:
				writeln("######################### unknown message ", message);
		}
		
	}


}
