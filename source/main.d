import std.stdio;
import Local: Local; //everything should be done via Local or GUI

void main()
{
	/*writeln("Hello World");
	
	auto obj = Local.createProject("Proj1"); //createProject returns the unique project id
	auto obj2 = Local.createProject("Proj2");
	auto obj3 = Local.createProject("Proj3");
	
	import std.algorithm;
	
	auto sessionID = Local.startSession(obj);
	auto tantumID = Local.createTantum(obj2, "2018-07-08T11:58:36");
	auto session2ID = Local.createSession(obj3,"2018-07-08T11:58:36");
	writeln("sessions ID: ",Local.getUserSessions.map!(x => x.ID));
	
	writeln("projects ID: ",Local.getUserSessions.map!(x => x.projectID));
	Local.editSession(sessionID,obj2);
	Local.editTantum(tantumID,obj);
	writeln("projects ID: ",Local.getUserSessions.map!(x => x.projectID));
	
	Local.deleteTantum(tantumID);
	writeln("sessions ID: ", Local.getUserSessions.map!(x => x.ID));
	
	writeln("stopping session: ", sessionID);
	Local.stopSession(sessionID);
	Local.deleteSession(sessionID);
	writeln("sessions ID: ", Local.getUserSessions.map!(x => x.ID));
	
	writeln(Local.login("me", "abd"));
	//writeln(Local.login("me", "abc"));
	//writeln(Local.login("ma", "abd"));
	writeln(Local.changePassword("abd","abc"));
	Local.logout;
	writeln(Local.login("me","abd"));
	writeln(Local.login("me","abc"));
	import LogIn;
	writeln(Login.isAdmin);
	writeln(Local.forgotPassword("me","aaa"));
	writeln(Local.login("me","abc"));
	writeln(Local.login("me","aaa"));
	writeln(Local.createUser("te","bbb"));
	writeln(Local.login("te","cbc"));
	writeln(Local.login("te","bbb"));
	writeln(Local.deleteUser("me"));
	writeln(Local.login("me","aaa"));
	writeln(Local.changeUserName("te","tu"));
	//writeln(Local.deleteUser("te"));
	writeln(Local.deleteUser("tu"));
	writeln(Local.login("tu","bbb"));*/
	
	Local.createProject("asd",0,true);
	Local.createProject("Natale", 0, true);
	
	import std.algorithm: map;
	
	writeln(Local.syncAppleCalendar);
	writeln(Local.getUserSessions.map!( x => x.description));


}
